#!/usr/bin/env bash
# check-kit.sh — run the kit's own discipline over the kit.
#
# For eight versions every check ran over core/ — the harness the kit PRODUCES —
# while the kit's own skills, packs and theory sat outside all of them. That
# unchecked region is where an independent reader found five orphaned packs, and
# where the entry-point routing defect lived: the sentence almost every
# engagement opens with, "help me create a harness for X", matched only
# harness-build — the skill that requires an already-agreed architecture
# document and skips fitness entirely.
#
# The kit is NOT a harness, so it does not get doctor's organ list. It gets the
# domain-neutral checks: do references resolve, is anything orphaned, and does
# exactly one skill claim the front door.

. "$(dirname "$0")/core/scripts/lib.sh"
KIT="$(cd "$(dirname "$0")" && pwd)"
cd "$KIT" || exit 1
IFS=$(printf '\n\b'); IFS=${IFS%?}

DOCS=$(find . -name '*.md' -not -path './core/*' -not -path '*/.git/*' | sort)

# A filesystem loader may accept arbitrary frontmatter that a packaged skill
# host rejects. Validate the portable subset before doing kit-specific routing.
python3 core/scripts/validate-skills.py skills || fail "kit skill frontmatter is not portable"
python3 core/scripts/scan-skill-trust.py skills skill-trust-allow.tsv \
  || fail "kit skills contain unsafe instruction shapes"

# ── 1. References resolve ────────────────────────────────────────────────────
MISS=$(mktemp 2>/dev/null) || MISS=""
[ -n "$MISS" ] || fail "cannot create a temp file — refusing to report a result"
n_refs=0
for f in $DOCS; do
  d=$(dirname "$f")
  for r in $(grep -oe '](\.\{0,2\}/\{0,1\}[A-Za-z0-9_./-]*)' -- "$f" 2>/dev/null | sed 's/^](//;s/)$//'); do
    case "$r" in ""|http*|"#"*|*"{{"*|*"<"*|*"*"*) continue ;; esac
    n_refs=$((n_refs + 1))
    [ -e "$d/$r" ] || [ -e "./$r" ] || printf '%s -> %s\n' "$f" "$r" >> "$MISS"
  done
done
if [ "$(nlines "$MISS")" -gt 0 ]; then
  while IFS= read -r l || [ -n "$l" ]; do [ -n "$l" ] && fail "broken reference: $l"; done < "$MISS"
else
  pass "kit references resolve" "$n_refs refs in $(printf '%s\n' "$DOCS" | nlines) docs"
fi
rm -f "$MISS"

# ── 2. Nothing orphaned ──────────────────────────────────────────────────────
ENTRY='^\./\(README\|INSTALL\|ANATOMY\|PRINCIPLES\|LADDER\|SUBSTRATES\|KNOWN-GAPS\)\.md$'
n_docs=0; orph=""
for f in $DOCS; do
  printf '%s\n' "$f" | grep -qe "$ENTRY" -- && continue
  n_docs=$((n_docs + 1)); base=$(basename "$f")
  found=0
  for g in $DOCS; do
    [ "$g" = "$f" ] || ! grep -qle "$base" -- "$g" 2>/dev/null || { found=1; break; }
  done
  [ "$found" -eq 1 ] || orph="$orph
$f"
done
if [ -n "$orph" ]; then
  for o in $(printf '%s\n' "$orph" | grep -e . --); do
    fail "orphan: $o is referenced by no other kit document"
  done
else
  pass "kit citation graph" "$n_docs non-entry docs"
fi

# ── 3. Exactly one skill claims the front door ───────────────────────────────
n_skills=0; n_entry=0; n_over=0; entry_name=""
for d in skills/*/; do
  [ -d "$d" ] || continue
  s="${d}SKILL.md"
  # A skill directory with no SKILL.md was invisible to every check in this file:
  # the old loop iterated skills/*/SKILL.md and `continue`d past it, so an empty
  # directory counted as zero skills and every denominator below stayed green.
  # That is the defect class this script exists to catch, inside this script.
  if [ ! -f "$s" ]; then
    fail "${d%/} has no SKILL.md — an empty skill directory is invisible to every check below"
    continue
  fi
  n_skills=$((n_skills + 1))
  # Same budget and the same counting rule as the harness this kit produces
  # (scripts/gates/instruction-budget.sh): blank lines and HTML comments do not
  # count. The kit argues that a convention without a gate is a paragraph; it
  # had no size check of its own, so nothing would have noticed a 600-line skill.
  n_lines=$(grep -cvE '^[[:space:]]*(<!--|$)' -- "$s")
  if [ "$n_lines" -gt 200 ]; then
    n_over=$((n_over + 1))
    fail "$s is $n_lines lines (skill budget: 200) - move detail into references/"
  fi
  name=$(sed -n 's/^name:[[:space:]]*//p' "$s" | head -1)
  desc=$(sed -n 's/^description:[[:space:]]*//p' "$s" | head -1)
  ent=$(sed -n 's/^[[:space:]]*harness\.entry:[[:space:]]*["'"'"']*\([^"'"'"']*\)["'"'"']*[[:space:]]*$/\1/p' "$s" | head -1)
  [ -n "$name" ] || fail "$s has no name:"
  [ -n "$desc" ] || fail "$s has no description: — a host has nothing to match on"
  case "$ent" in
    true)  n_entry=$((n_entry + 1)); entry_name="$name" ;;
    false) ;;
    *)     fail "$s must declare metadata.harness.entry as true or false — routing ownership cannot be implicit" ;;
  esac
done
if [ "$n_entry" -eq 1 ]; then
  if [ "$n_over" -eq 0 ]; then
    pass "exactly one entry skill" "$entry_name, of $n_skills (all within the 200-line budget)"
  else
    pass "exactly one entry skill" "$entry_name, of $n_skills"
  fi
elif [ "$n_entry" -eq 0 ]; then
  fail "no skill declares entry: true — 'help me create a harness for X' reaches nothing on purpose"
else
  fail "$n_entry skills declare entry: true — the opening request would route by luck"
fi

# ── 4. The entry skill actually claims the opening phrases ───────────────────
if [ -n "$entry_name" ]; then
  d=$(sed -n 's/^description:[[:space:]]*//p' "skills/$entry_name/SKILL.md" | head -1)
  n_claim=0
  for phrase in "create a harness" "build" "set up"; do
    printf '%s\n' "$d" | grep -qie "$phrase" -- && n_claim=$((n_claim + 1))
  done
  if [ "$n_claim" -ge 2 ]; then
    pass "entry skill claims the opening phrasings" "$n_claim/3 in its description"
  else
    fail "$entry_name is the entry skill but its description does not carry the phrasings people actually use"
  fi
fi


# ── 5. Numeric claims match reality ──────────────────────────────────────────
# Documentation drifts silently: a count written once stays written while the
# thing it counts changes underneath. An external reviewer found three stale
# numbers here — the kit selftest case count, the config key count, and a
# config key that no longer exists — none of which any check could see.
#
# So the counts are computed, and the docs are checked against them.

claim_check() {
  local label="$1" actual="$2" pattern="$3" file="$4"
  local found
  found=$(grep -oEe "$pattern" -- "$file" 2>/dev/null | grep -oEe '[0-9]+' | head -1)
  if [ -z "$found" ]; then return 0; fi           # no claim made is fine
  if [ "$found" = "$actual" ]; then
    printf '%s    %-28s claims %s, actual %s%s\n' "$DIM" "$label" "$found" "$actual" "$RST"
  else
    fail "$file claims $found $label, actual is $actual — a count written once stays written"
  fi
}

N_KIT_CASES=$(grep -Ece '^expect_(fail|pass|mode) |^cases=\$\(\(cases \+ 1\)\)$' -- check-kit-selftest.sh 2>/dev/null)
case "${N_KIT_CASES:-}" in ''|*[!0-9]*) N_KIT_CASES=0 ;; esac
N_GATES=$(find core/scripts/gates -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')
N_KEYS=$(grep -ce '^[a-z_]*:' -- core/harness.yaml 2>/dev/null)
case "${N_KEYS:-}" in ''|*[!0-9]*) N_KEYS=0 ;; esac
VER=$(sed -n 's/^kit_version:[[:space:]]*//p' core/harness.yaml | tr -d '" ')

claim_check "config keys" "$N_KEYS" "Of the [0-9]+ shipped keys" KNOWN-GAPS.md

# Version must agree everywhere it is written.
n_ver=0; bad_ver=0
for f in README.md; do
  claimed=$(grep -oEe '\*\*v[0-9]+\.[0-9]+\.[0-9]+' -- "$f" | head -1 | tr -d '*v')
  [ -n "$claimed" ] || continue
  n_ver=$((n_ver + 1))
  [ "$claimed" = "$VER" ] || { fail "$f says v$claimed, harness.yaml says $VER"; bad_ver=$((bad_ver + 1)); }
done
[ "$bad_ver" -eq 0 ] && pass "version consistent" "$VER across $n_ver doc(s) + harness.yaml"

# A config key named in harness.yaml but absent from core/README's table is a
# key nobody documented; one in the table but not the file is a stale claim.
n_undoc=0
for k in $(sed -n 's/^\([a-z_]*\):.*/\1/p' core/harness.yaml); do
  grep -qe "\`$k\`" -- core/README.md || { fail "harness.yaml key '$k' is in no README table row"; n_undoc=$((n_undoc + 1)); }
done
for k in $(grep -oEe '^\| `[a-z_]+`' -- core/README.md | tr -d '| `'); do
  grep -qe "^$k:" -- core/harness.yaml || { fail "core/README documents '$k', which harness.yaml no longer has"; n_undoc=$((n_undoc + 1)); }
done
[ "$n_undoc" -eq 0 ] && pass "every config key is documented, and every documented key exists" "$N_KEYS keys"

# The kit designs harnesses; it does not stock domains. Any skill that tells an
# agent to read `packs/<domain>/PACK.md` must, in the same breath, say what to do
# when no pack exists — otherwise the front door names five domains and the
# universal architecture behind it is unreachable.
#
# This is the check behind the claim. Without it, one edit that drops the
# `_deriving.md` row silently returns the kit to a five-domain catalogue while
# every other gate stays green — and nothing about a green suite would look
# different.
n_route=0; n_unrouted=0
for sk in skills/*/SKILL.md; do
  [ -f "$sk" ] || continue
  grep -qe 'packs/<domain>' -- "$sk" || continue
  n_route=$((n_route + 1))
  grep -qe '_deriving' -- "$sk" || {
    fail "$sk sends the agent to packs/<domain>/PACK.md and never says what to do when there is no pack"
    fail "  A domain with no pack is the NORMAL case. Route it to packs/_deriving.md."
    n_unrouted=$((n_unrouted + 1))
  }
done
if [ "$n_route" -eq 0 ]; then
  fail "no skill references packs/<domain>/PACK.md — the pack step has moved and this check is now blind"
elif [ "$n_unrouted" -eq 0 ]; then
  pass "every skill that names a pack also routes an uncatalogued domain" "$n_route skill(s)"
fi

# Every file the template ships must land in exactly one surface. The kit's own
# gate-selftest cannot make this claim: by the time it runs it has written a
# dozen .bak fixtures into its throwaway copy, and in a configured instance the
# same assertion would fail on the user's own unclassified work. Here the
# subject is the pristine template, where the claim is exactly right.
#
# Shipping a template whose own gate scripts and constitution belong to no
# surface is how a user inherits 30 silent high-risk files on day one.
#
# COUNTED FROM --records ON STDOUT, never scraped from the prose summary. The
# first version grepped '[0-9]+ unclassified' out of combined output, and a file
# named "0 unclassified.md" — listed on stderr ABOVE the summary — was picked up
# by `head -1`, so check-kit reported "0 unclassified" and exited 0 while the
# resolver had just said 1. A check whose own input can be forged by a filename
# is not a check.
RS_REC=$(cd core && ./scripts/resolve-surface.sh --all --records 2>/dev/null); RS_RC=$?
N_RESOLVED=$(printf '%s\n' "$RS_REC" | nlines)
N_UNCL=$(printf '%s\n' "$RS_REC" | cut -f4 | grep -cxe '(unclassified)' --); case "${N_UNCL:-}" in ''|*[!0-9]*) N_UNCL=0 ;; esac
N_AMB=$(printf '%s\n' "$RS_REC" | cut -f2 | grep -cxe 'AMBIGUOUS' --);      case "${N_AMB:-}" in ''|*[!0-9]*) N_AMB=0 ;; esac
N_SURF=$(grep -cve '^#' -e '^[[:space:]]*$' -- core/config/surfaces.tsv 2>/dev/null); case "${N_SURF:-}" in ''|*[!0-9]*) N_SURF=0 ;; esac
if [ "$RS_RC" -ne 0 ]; then
  fail "core/ surfaces do not resolve cleanly (resolver exit $RS_RC):"
  (cd core && ./scripts/resolve-surface.sh --all 2>&1 >/dev/null) | sed 's/^/    /' >&2
elif [ "$N_AMB" -gt 0 ]; then
  fail "core/ has $N_AMB file(s) matching more than one surface"
elif [ "$N_UNCL" -gt 0 ]; then
  fail "core/ ships $N_UNCL file(s) matching no surface — the floor the template promises is not laid"
  printf '%s\n' "$RS_REC" | grep -e '(unclassified)$' -- | cut -f1 | sed 's/^/    /' >&2
elif [ "$N_RESOLVED" -eq 0 ]; then
  fail "the resolver classified 0 files in core/ — an empty denominator is not a pass"
else
  pass "every file core/ ships resolves to exactly one surface" \
       "$N_RESOLVED files, $N_SURF surfaces, 0 unclassified, 0 ambiguous"
fi

# ── 7. Nothing points at what a reader cannot see ─────────────────────────────
# The kit is standalone. What was learned from studying other harnesses belongs
# in the kit as principle, stated directly — never as a pointer to a harness,
# project or folder that exists only on the machine it was written on. Someone
# else's copy has no such thing, so the pointer is dead the moment it ships.
#
# Three kinds of leak, each a separate pattern:
#   1. personal machine paths — /Users/<name>, /home/<name>, Desktop/, C:\Users
#   2. evidence-by-citation language — the vocabulary of "derived from these"
#   3. private names — kept OUT of the repo in an untracked .private-terms file
#      (one term per line, # comments allowed), because a denylist of private
#      names committed to a public repo would publish the very names it guards.
LEAK_EXCL=(--exclude=check-kit.sh --exclude=check-kit-selftest.sh --exclude=LICENSE --exclude=.private-terms)
n_leak=0
LEAK_PATHS=$(grep -rnIE "${LEAK_EXCL[@]}" -e '/Users/[A-Za-z]' -e '/home/[a-z][a-z0-9_-]*/' -e 'Desktop/' -e 'C:\\Users' . 2>/dev/null | grep -v '/\.git/')
LEAK_CITE=$(grep -rnIiE "${LEAK_EXCL[@]}" -e '(^|[^A-Za-z])specimens?([^A-Za-z]|$)' -e 'studied harness' -e 'harnesses (we |I )?studied' . 2>/dev/null | grep -v '/\.git/')
LEAK_TERMS=""
if [ -f .private-terms ]; then
  TERMS=$(mktemp 2>/dev/null) || fail "cannot create a temp file — refusing to report a result"
  grep -ve '^[[:space:]]*#' -e '^[[:space:]]*$' -- .private-terms > "$TERMS"
  if [ "$(nlines "$TERMS")" -gt 0 ]; then
    LEAK_TERMS=$(grep -rnIiF "${LEAK_EXCL[@]}" -f "$TERMS" . 2>/dev/null | grep -v '/\.git/')
  fi
  rm -f "$TERMS"
fi
for l in $LEAK_PATHS; do fail "personal machine path: $l"; n_leak=$((n_leak + 1)); done
for l in $LEAK_CITE;  do fail "cites a harness the reader cannot see — state the principle instead: $l"; n_leak=$((n_leak + 1)); done
for l in $LEAK_TERMS; do fail "private term (from .private-terms): $l"; n_leak=$((n_leak + 1)); done
if [ "$n_leak" -eq 0 ]; then
  if [ -f .private-terms ]; then src="paths, citations and .private-terms"; else src="paths and citations; no .private-terms file"; fi
  pass "nothing points at what a reader cannot see" "$src"
fi

# ── 8. Every procedure says how it stops, escalates and re-enters ────────────
# A procedure that documents only the happy path leaves the agent to improvise
# the case that goes wrong — and an improvised stop is indistinguishable from
# finishing. Those three are exactly what a new workflow step owes: a stop, an
# escalation, and a re-entry.
#
# The fields are READ HERE, in the change that added them to the template. A
# required field nothing reads is the defect at the bottom of PRINCIPLES.md:
# worse than no field, because it looks like enforcement to anyone skimming.
#
# The template ships the headings with an EMPTY bullet — that is its job, so it
# is exempt from the content half and from nothing else. Every live procedure
# needs a filled bullet in each, because a heading over nothing is B4: a path
# that exists graded as a pass.
PROC_TMPL=core/procedures/_TEMPLATE.md
[ -f "$PROC_TMPL" ] || fail "$PROC_TMPL is missing — there is nothing to hold the procedures below to"
n_proc=0; n_field=0; n_badproc=0
for f in core/procedures/*.md; do
  [ -f "$f" ] || continue
  n_proc=$((n_proc + 1)); bad=0
  for h in "Stops when" "Escalates when" "Safe to re-run when"; do
    n_field=$((n_field + 1))
    if ! grep -qxe "## $h" -- "$f"; then
      fail "$f has no '## $h' section — a procedure that names no such condition still has one, and it is 'carry on'"
      bad=1; continue
    fi
    [ "$f" = "$PROC_TMPL" ] && continue
    filled=$(awk -v h="## $h" '$0==h{o=1;next} /^## /{o=0} o' "$f" | grep -ce '^- .')
    case "${filled:-}" in ''|*[!0-9]*) filled=0 ;; esac
    [ "$filled" -gt 0 ] || { fail "$f: '## $h' is a heading with nothing under it — an empty required field reads as a filled one"; bad=1; }
  done
  [ "$bad" -eq 0 ] || n_badproc=$((n_badproc + 1))
done
if [ "$n_proc" -eq 0 ]; then
  fail "no procedures under core/procedures/ — an empty denominator is not a pass"
elif [ "$n_badproc" -eq 0 ]; then
  pass "every procedure says how it stops, escalates and re-enters" "$n_proc procedures, $n_field fields"
fi

pass "computed facts" "$N_KIT_CASES kit cases, $N_GATES gates, $N_KEYS keys, v$VER"

finish
