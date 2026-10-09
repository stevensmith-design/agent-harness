#!/usr/bin/env bash
# session-start.sh — hand the agent the state it would otherwise guess at.
#
# The state that matters most is the one nothing else reports: **has this
# harness ever actually been configured, and has it ever carried real work?**
# A harness that ships blank and is never filled in looks installed from every
# angle — the files are there, the gates are green, the config parses — and
# enforces nothing, because every pattern in it matches a placeholder.
#
# Three design rules, each earned:
#
# 1. NEVER BLOCK. A SessionStart hook that can fail the session gets removed
#    within a day. Every path here exits 0.
# 2. SUCCESS IS QUIET. A configured harness in normal use gets one line. Only
#    the states that need action are verbose — a hook that shouts every session
#    gets tuned out, and then it is worse than absent.
# 3. NO NEW SENTINEL WHERE A FACT ALREADY EXISTS. "Unconfigured" is read from
#    the config's own mode and placeholders; "never used" from whether `runs/`
#    holds anything. A separate first-run marker is one more thing that can be
#    deleted, committed by accident, or simply lie.
#
# The one thing that genuinely needs a file is "first session in THIS working
# copy", because that is per-clone, not per-repo. It lives under a gitignored
# path — which is exactly what makes a fresh clone read as fresh.

cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
[ -f harness.yaml ] || exit 0          # not a kit harness; say nothing

emit() {
  # Claude Code reads additionalContext. Keep it one JSON line.
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' \
    "$(printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "%s\\n", $0}')"
  exit 0
}

MODE=$(sed -n 's/^mode:[[:space:]]*//p' harness.yaml 2>/dev/null | head -1 | tr -d '"' | sed 's/[[:space:]]*#.*$//')
NAME=$(sed -n 's/^name:[[:space:]]*//p' harness.yaml 2>/dev/null | head -1 | tr -d '"' | sed 's/[[:space:]]*#.*$//')
# `git rev-parse --abbrev-ref HEAD` on an unborn branch prints "HEAD" AND exits
# non-zero, so a `|| fallback` runs as well and both land in the variable. Same
# family as `grep -c` printing 0 and exiting 1. symbolic-ref is the honest one:
# it resolves an unborn branch to its name and stays silent when detached.
BRANCH=$(git symbolic-ref --short -q HEAD 2>/dev/null)
[ -n "$BRANCH" ] || BRANCH=$(git rev-parse --short HEAD 2>/dev/null)
[ -n "$BRANCH" ] || BRANCH='none (folder harness, no git)' 

# Unfilled placeholders, excluding files whose NAME marks them a template.
PH=0
for f in harness.yaml AGENTS.md GOVERNANCE.md; do
  [ -f "$f" ] && grep -qe '{{[^}]\{1,\}}}' -- "$f" 2>/dev/null && PH=$((PH + 1))
done

# Has any work run through this harness? A dated run directory is the evidence.
RUNS=$(find runs -maxdepth 1 -type d -name '20*' 2>/dev/null | wc -l | tr -d ' ')
# Do any foundations exist beyond the shipped README?
FOUND=$(find foundations -type f -not -name 'README.md' 2>/dev/null | wc -l | tr -d ' ')

# First session in THIS working copy. Gitignored, so a fresh clone has none.
FIRST_HERE=0
if [ ! -f .harness/local/seen ]; then
  FIRST_HERE=1
  mkdir -p .harness/local 2>/dev/null && date -u +%Y-%m-%dT%H:%M:%SZ > .harness/local/seen 2>/dev/null
fi

# ── State 1: never configured ────────────────────────────────────────────────
# Keyed on `mode` ALONE. An earlier version also tripped on any leftover
# placeholder, so a configured harness with one stray {{OWNER}} announced
# "never been configured" and "enforces nothing" — both false, and the kind of
# wrong-and-loud that gets a hook switched off in a week. `mode` is the
# explicit declaration; a stray placeholder is a lesser, separate state that
# doctor already fails on.
if [ "$MODE" != "instance" ]; then
  emit "FIRST CONTACT — this harness has never been configured.
mode=${MODE:-unset}, ${PH} core file(s) carry unfilled placeholders, ${FOUND} foundation file(s) written, ${RUNS} run(s) recorded.

It currently enforces nothing: every surface pattern matches a placeholder, so every gate passes over an empty set.

What to do depends entirely on why the user is here, so read their opening message first and follow procedures/first-contact.md. Do not open with a questionnaire, and do not invent foundations to fill the template."

fi

PH_NOTE=""
[ "$PH" -gt 0 ] && PH_NOTE="
${PH} core file(s) still carry unfilled placeholders — run bash scripts/doctor.sh, which fails on them in instance mode."

# ── State 2: configured, but has never carried work ──────────────────────────
if [ "$RUNS" -eq 0 ]; then
  emit "branch=${BRANCH} harness=${NAME:-unnamed} mode=${MODE}${PH_NOTE}
CONFIGURED BUT UNPROVEN — runs/ is empty. No work has been through this harness yet.

It is a rehearsal until something real passes through it. When you finish the first piece of work: save it under runs/YYYY-MM-DD-<procedure>/ with the procedure, the foundation files consumed, and the commit SHA (in a folder with no git, the date and the foundation files as they were) — and file the result in learning/corpus/ as accepted or rejected, with the reason in the judge's own words.

The corpus starting at zero is normal. The corpus staying at zero is the failure: nothing then calibrates the next run, and the spec never changes after contact with real output.

Read AGENTS.md before editing. Run bash scripts/checkpoint.sh before claiming anything works."
fi

# ── State 3: in use. One line, plus orientation on a fresh clone. ────────────
LINE="branch=${BRANCH} harness=${NAME} mode=${MODE} runs=${RUNS} foundations=${FOUND}. Read AGENTS.md before editing. Run bash scripts/checkpoint.sh before claiming anything works.${PH_NOTE}"
# Is a retro due? The script owns the thresholds and prints nothing when it is
# not, so a healthy harness stays at one line. `|| true` and the redirect keep
# rule 1: a broken or missing evidence script costs the reminder, not the session.
DUE=$(bash scripts/retro-evidence.sh --due 2>/dev/null || true)
[ -n "$DUE" ] && LINE="${LINE}
${DUE}"
if [ "$FIRST_HERE" -eq 1 ]; then
  LINE="${LINE}
First session in this working copy — read AGENTS.md, foundations/, and learning/corpus/rejected/ before generating anything. The rejected examples calibrate faster than the spec does."
fi
emit "$LINE"
