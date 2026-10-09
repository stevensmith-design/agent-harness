#!/usr/bin/env bash
# doctor.sh — is the HARNESS healthy?
#
# Not the same question as `check.sh`, which asks whether a piece of WORK
# complies. Conflating them produces a green tree that means nothing, because
# you cannot tell whether the checks passed or were never wired.
#
# Doctor green is the health floor: necessary, never sufficient.
#
# Everything here FAILS rather than warns. An earlier version printed
#   ✓ scripts executable (7 scripts, 2 not executable)
# — a denominator contradicted by the verdict beside it, which is worse than a
# bare tick, and exactly the false-green anti-pattern this kit names.

# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
ROOT=$(harness_root "$(dirname "$0")") || exit 1
cd "$ROOT" || exit 1

IFS=$(printf '\n\b'); IFS=${IFS%?}   # filenames with spaces must not split
MODE=$(cfg mode template)
case "$MODE" in
  template|instance) ;;
  *) fail "harness.yaml: mode must be 'template' or 'instance', got '$MODE'" ;;
esac

# ── 1. Organs ────────────────────────────────────────────────────────────────
# A harness missing one is not lighter — it has a hole where a failure gets
# through. Files must be NON-EMPTY: an organ truncated to zero bytes passed a
# `-e` test while carrying nothing.
# Newline-delimited, because IFS is newline above so that filenames containing
# spaces are not split. A space-delimited list here silently became one item.
REQUIRED_DIRS='config
contracts
capabilities
decisions
foundations
learning/corpus
memory
procedures
.claude/skills
rubrics/examples
runs
scripts/gates'
REQUIRED_FILES='harness.yaml
GOVERNANCE.md
config/surfaces.tsv
foundations/README.md
evidence/approvals.md
learning/candidates.md
learning/changelog.md
learning/retros.md
learning/findings.md
learning/corpus/README.md
memory/README.md
decisions/log.md
read-first.md
procedures/harness-retro.md
procedures/first-contact.md
procedures/session-wrapup.md
procedures/record-decision.md
procedures/learn-from-finding.md
procedures/capability-intake.md
capabilities-lock.json
scripts/gates/capability-safety.sh
scripts/gates/data-boundary.sh
scripts/validate-skills.py
scripts/scan-skill-trust.py
scripts/verify-capabilities.py
scripts/retro-evidence.sh
loading-order.md
learning/reviews/README.md
.pii-allow
rubrics/README.md
rubrics/_TEMPLATE.md
rubrics/examples/README.md
scripts/hooks/session-start.sh
scripts/hooks/block-sensitive-runtime.sh
.claude/settings.json' 

n_req=0
for p in $REQUIRED_DIRS; do
  n_req=$((n_req + 1))
  [ -d "$p" ] || fail "missing organ (directory): $p"
done
# Organs that must be POPULATED once configured, vs organs that are legitimately
# empty on day one. A log starts empty; a foundation that starts empty means the
# harness was unpacked, not configured — and nothing else distinguishes those.
MUST_BE_POPULATED='GOVERNANCE.md
config/surfaces.tsv
foundations/README.md
procedures/harness-retro.md
procedures/first-contact.md
procedures/session-wrapup.md
procedures/record-decision.md
procedures/capability-intake.md
read-first.md
loading-order.md
learning/reviews/README.md
rubrics/README.md
rubrics/_TEMPLATE.md'
n_stub=0
for p in $REQUIRED_FILES; do
  n_req=$((n_req + 1))
  st=$(content_status "$p")
  case "$st" in
    missing) fail "missing organ: $p" ;;
    stub)
      if printf '%s\n' "$MUST_BE_POPULATED" | grep -qxe "$p" --; then
        if [ "$MODE" = "instance" ]; then
          fail "organ is a stub: $p exists but carries no substantive content"
          n_stub=$((n_stub + 1))
        fi
      fi
      ;;
  esac
done
CS=$(content_status "$(cfg constitution AGENTS.md)")
[ "$CS" = "stub" ] && [ "$MODE" = "instance" ] && { fail "the constitution is a stub — it exists and says nothing"; n_stub=$((n_stub + 1)); }
# Foundations: the organ the whole thing rests on. A configured harness with no
# foundation beyond the shipped README has not actually been configured.
if [ "$MODE" = "instance" ]; then
  n_found=$(find foundations -type f -not -name 'README.md' 2>/dev/null | wc -l | tr -d ' ')
  [ "${n_found:-0}" -eq 0 ] && fail "mode is instance but foundations/ holds nothing beyond the shipped README"
fi
CONST=$(cfg constitution AGENTS.md)
n_req=$((n_req + 1))
[ -f "$CONST" ] || fail "missing organ: $CONST (the constitution)"
pass "organs present and populated" "$n_req checked, $n_stub stub(s)"

# ── 2. Placeholders ──────────────────────────────────────────────────────────
# Matches ANY {{...}}, not only {{UPPER_CASE}} — the prose placeholders were
# the important ones, and the prime directive was written as prose. Files whose
# NAME marks them a template are exempt: they are supposed to keep theirs.
# NOTE: -E. In basic regex `|` is a literal pipe, so this alternation silently
# matched nothing and every instance failed on the ADR template forever.
TEMPLATE_EXEMPT='(_TEMPLATE\.md|-template\.md|\.template\.md)$'
PH=""
for f in $(repo_files "." | grep -e '\.\(md\|yaml\|yml\|tsv\)$' -- || true); do
  printf '%s\n' "$f" | grep -Eqe "$TEMPLATE_EXEMPT" -- && continue
  grep -qe '{{[^}]\{1,\}}}' -- "$f" 2>/dev/null && PH="$PH $f"
done
n_ph=$(printf '%s' "$PH" | wc -w | tr -d ' ')
if [ "$MODE" = "instance" ] && [ "$n_ph" -gt 0 ]; then
  for f in $PH; do fail "unfilled placeholder in $f"; done
else
  pass "placeholders" "$n_ph unfilled in $MODE mode"
fi

# ── 3. Scripts runnable ──────────────────────────────────────────────────────
# A gate that cannot run is a gate that never fires. That is a failure.
#
# Runnable means: a bash script that parses. It deliberately does NOT mean the
# executable bit is set. Every script here is started with `bash`, because a
# harness may live in a shared drive, a synced folder or a downloaded zip, and
# all of those routinely strip that bit. Requiring it failed every harness
# outside git for a reason that stopped nothing from running.
n_sh=0; n_bad=0
for f in $(repo_files "." | grep -e '\.sh$' -- || true); do
  n_sh=$((n_sh + 1))
  head -1 -- "$f" 2>/dev/null | grep -qe '^#!.*\(bash\|sh\)' -- || { fail "not a bash script (no bash shebang): $f"; n_bad=$((n_bad + 1)); }
  bash -n "$f" 2>/dev/null || { fail "syntax error: $f"; n_bad=$((n_bad + 1)); }
done
[ "$n_bad" -eq 0 ] && pass "scripts runnable" "$n_sh scripts"

# ── 4. Surfaces, BOTH directions, from one reader ────────────────────────────
# This used to be two checks with two parsers. doctor read field 1 of the table
# and globbed with `find -path`; the resolver reads every field and globs with
# `case`. They disagreed about a pattern naming a directory — doctor scored it
# covered, the resolver could never match a file with it — which is precisely
# the "two readers of one table" failure the table's own header warns about.
#
# One question was also missing entirely. "Does every declared pattern match a
# file?" catches decorative globs. "Does every file match exactly one pattern?"
# catches unclassified work, and nothing asked it: this check was green while
# 30 of the 51 files here belonged to no surface, every gate script among them.
#
# The resolver's fail() cannot reach this shell — HARNESS_TOP_PID is
# deliberately not exported — so read its status and fail here.
if [ -f scripts/resolve-surface.sh ]; then
  bash scripts/resolve-surface.sh --all || fail "surfaces do not resolve cleanly — see above"
else
  fail "scripts/resolve-surface.sh is missing — nothing checks that a file lands in exactly one lane"
fi

# ── 5. Residue ───────────────────────────────────────────────────────────────
# An empty directory is the trace of something that was removed or never built.
n_dirs=0; n_emptydir=0
for d in $(find . -type d -not -path '*/.git/*' -not -path './runs/*' 2>/dev/null); do
  case "$d" in .|./learning/corpus/accepted|./learning/corpus/rejected|./.harness*) continue ;; esac
  n_dirs=$((n_dirs + 1))
  if [ -z "$(ls -A "$d" 2>/dev/null)" ]; then
    fail "empty directory: $d — residue, or an organ nothing filled"
    n_emptydir=$((n_emptydir + 1))
  fi
done
[ "$n_emptydir" -eq 0 ] && pass "no residue" "$n_dirs directories"

# ── 5b. Unmerged install collisions ──────────────────────────────────────────
# install.sh stages files it refused to overwrite. Left in place they are two
# truths for the same rule, with nothing saying which one is live.
if [ -d .harness-incoming ]; then
  fail "$(find .harness-incoming -type f 2>/dev/null | wc -l | tr -d ' ') staged file(s) in .harness-incoming/ are unmerged — merge them into the existing files, then delete the directory"
fi

# ── 5c. Sync conflict copies and cloud shortcuts ─────────────────────────────
# A harness in a shared drive gets edited by two people at once, and the sync
# tool keeps both versions: "AGENTS (1).md", "AGENTS 2.md", "AGENTS (Jo's
# conflicted copy).md". The agent then reads whichever it finds first, and the
# rule you edited is not the rule it follows. That is two truths for one rule —
# the same failure as an unmerged install collision, arriving by a different door.
#
# A numbered copy only counts when the original sits beside it, so a file that
# is genuinely called "Phase 2.md" is left alone.
#
# Cloud shortcuts are the second hazard. In a synced Google Drive folder a Google
# Doc is a small link file (.gdoc), not its text. Inside an organ the agent is
# meant to read, it is a rule nobody can read from here.
_ifs=$IFS; IFS=$(printf '\n\b'); IFS=${IFS%?}
n_conf=0; n_short=0
for f in $(find . -type f -not -path '*/.git/*' -not -path './runs/*' -not -path './node_modules/*' 2>/dev/null); do
  b=$(basename "$f"); dir=$(dirname "$f")
  case "$b" in
    *[Cc]onflicted\ copy*|*[Cc]onflict\ copy*|*.sync-conflict-*|*\(conflict*\)*)
      fail "sync conflict copy: $f — merge it into the original and delete it"; n_conf=$((n_conf + 1)); continue ;;
  esac
  ext=""; stem="$b"
  case "$b" in *.*) ext=".${b##*.}"; stem="${b%.*}" ;; esac
  orig=$(printf '%s\n' "$stem" | sed -n 's/^\(.*[^ ]\) (\{0,1\}[0-9]\{1,2\})\{0,1\}$/\1/p')
  if [ -n "$orig" ] && [ "$orig" != "$stem" ] && [ -e "$dir/$orig$ext" ]; then
    fail "sync conflict copy: $f — a numbered copy of $dir/$orig$ext; merge it into the original and delete it"
    n_conf=$((n_conf + 1))
  fi
  case "$f" in
    ./foundations/*|./procedures/*|./contracts/*|./rubrics/*|./learning/*|./memory/*|./decisions/*)
      case "$b" in
        *.gdoc|*.gsheet|*.gslides|*.gdraw|*.gform|*.gsite|*.gjam|*.gmap)
          fail "cloud shortcut, not content: $f — the agent cannot read a Google file from a synced folder. Export it as markdown, or read it through the Google Drive connector and name it as an external source in foundations/README.md"
          n_short=$((n_short + 1)) ;;
      esac ;;
  esac
done
IFS=$_ifs
[ "$n_conf" -eq 0 ] && [ "$n_short" -eq 0 ] && pass "no sync conflict copies or unreadable cloud shortcuts" "whole tree"

# ── 6. Stubs ─────────────────────────────────────────────────────────────────
if [ -s runs/.state/stubs ]; then
  fail "$(wc -l < runs/.state/stubs | tr -d ' ') stubbed check(s) recorded — a stub is not a pass"
fi

finish
