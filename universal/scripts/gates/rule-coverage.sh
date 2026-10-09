#!/usr/bin/env bash
# Rule-coverage gate. Proves every rule actually loads.
#
# A path-scoped rule is invisible unless its glob matches real files. A glob
# that matches nothing is indistinguishable from no rule at all — you believe
# the constraint is in force, and it silently is not. That failure mode is
# permanent and invisible, which is why this runs with no path filter: deleting
# or renaming the directory a rule guards must break the build.
#
# Checks each file in .agents/rules/:
#   1. it has frontmatter with name + description
#   2. it declares either `paths:` or `trigger: always` — never neither
#   3. at least one glob in `paths:` matches a tracked file. The globs are
#      alternatives, not a conjunction — `["src/**","lib/**"]` is "wherever the
#      source lives", and a Flutter repo has lib/ but no src/. A rule fails only
#      when NONE of its globs match, i.e. when it can never load. Individually
#      dead globs are reported so you can tidy, but do not fail the build.
#   4. its `name` matches its filename
#   5. COVERAGE DID NOT SHRINK. "Does this glob match anything?" is a much
#      weaker question than it looks. A refactor that moves src/components/ to
#      app/components/ leaves `src/**` still matching README.md, so the gate
#      stays green while the rule quietly stops covering the code it was
#      written for. See the note above the shrinkage check for what is compared
#      and why it is exact rather than a threshold.
. "$(dirname "$0")/../lib.sh"

BASE="${1:-$(cfg git.main_branch main)}"

RULES_DIR="$HARNESS_ROOT/.agents/rules"
[ -d "$RULES_DIR" ] || { ok "rule coverage (no rules directory)"; exit 0; }

# A freshly copied, uninitialised template legitimately has no src/ or tests/.
# Report, do not fail, until `harness-init` has run — otherwise the very first
# `make check` in a new repo fails for a reason the user cannot yet fix.
# "Has harness-init run yet?" must be answered from the VALUE of a key, not by
# grepping the whole file. The old substring search meant the literal string
# <product> anywhere — including inside a comment — permanently downgraded every
# dead-rule failure to a notice. One line, undetectable, and the gate was off.
INITIALISED=1
case "$(cfg project.name '<product>')" in *'<'*'>'*|'') INITIALISED=0 ;; esac
case "$(cfg project.src '<src>')"       in *'<'*'>'*|'') INITIALISED=0 ;; esac

# repo_files, not `git ls-files`: a rule's globs were reported dead simply
# because the harness had been installed and not yet committed, which is exactly
# the state you are in when you run `make check` for the first time.
tracked=$(repo_files)
if [ -z "$tracked" ]; then
  tracked=$(must "file listing" sh -c "cd '$HARNESS_ROOT' && find . -type f -not -path './.git/*' | sed 's|^\./||'")
fi

# glob → anchored POSIX ERE. Same conversion as the design-token gate.
glob_re() {
  printf '%s' "$1" \
    | sed 's/\./\\./g; s|\*\*/|<ANYDIR>|g; s/\*\*/<ANY>/g; s|\*|[^/]*|g; s|<ANYDIR>|(.*/)?|g; s/<ANY>/.*/g' \
    | sed 's/^/^/; s/$/$/'
}

fm() {  # fm <key> <file>
  awk -v k="$1" '
    /^---/ { n++; next }
    n==1 && $0 ~ "^"k":" { sub("^"k":[[:space:]]*",""); print; exit }
    n>1 { exit }
  ' "$2"
}

# --- coverage shrinkage -------------------------------------------------------
#
# The scar: a glob that still matches SOMETHING can cover far fewer files after
# a refactor moves them, and rule 3 above cannot see it. `src/**` matching one
# stray README is indistinguishable, to that check, from `src/**` matching the
# whole application.
#
# WHAT IS COMPARED, and why this shape. The obvious version — count the matched
# files now, compare with a committed baseline number — has two problems. The
# baseline needs a regeneration command, and a regeneration command on a gate is
# a one-keystroke way to make any failure go away; that is the escape hatch this
# harness keeps warning about. And a raw count DROPS legitimately every time
# somebody deletes code, so it would need a threshold, which is exactly the
# heuristic we were asked not to write.
#
# So this compares something exact instead: files that git can prove were RENAMED
# out from under a rule. For each rename between the merge-base and the working
# tree, if the OLD path matched one of a rule's globs and the NEW path does not,
# that file left the rule's coverage. A deleted file did not — it is gone, and a
# rule covering fewer files because there are fewer files is correct. A moved
# file is the defect, every time, with no threshold and nothing to waive.
#
# The limit, stated rather than hidden: git detects renames by similarity, so a
# move that also rewrites most of the file reads as delete+add and is invisible
# here. A raw shrinkage in the matched count is therefore still REPORTED (never
# failed) so a person can see it.
RENAMES=""
SHRINK_COMPARABLE=1
if git -C "$HARNESS_ROOT" rev-parse --verify -q "$BASE" >/dev/null 2>&1; then
  MB=$(git -C "$HARNESS_ROOT" merge-base HEAD "$BASE" 2>/dev/null || printf '')
  if [ -n "$MB" ]; then
    RENAMES=$(git -C "$HARNESS_ROOT" diff -M --diff-filter=R --name-status "$MB" 2>/dev/null || printf '')
    BASE_FILES=$(git -C "$HARNESS_ROOT" ls-tree -r --name-only "$MB" 2>/dev/null || printf '')
  else
    SHRINK_COMPARABLE=0
  fi
else
  SHRINK_COMPARABLE=0
fi
# A comparison that could not be made is never reported as one that passed.
[ "$SHRINK_COMPARABLE" = 1 ] || skipped "coverage shrinkage (no merge-base with '$BASE' — shallow clone, or the branch is absent)"

# matches_any <path> <globs> — is this path covered by any of a rule's globs?
matches_any() {
  local pth="$1" gl
  while IFS= read -r gl; do
    [ -n "$gl" ] || continue
    printf '%s\n' "$pth" | grep -qE "$(glob_re "$gl")" && return 0
  done <<MA
$2
MA
  return 1
}

rc=0
count=0
for f in "$RULES_DIR"/*.md; do
  [ -f "$f" ] || continue
  base=$(basename "$f" .md)
  [ "$base" = "README" ] && continue
  count=$((count + 1))
  rel=".agents/rules/$base.md"

  head -1 "$f" | grep -q '^---$' || { warn "$rel: no frontmatter"; rc=1; continue; }

  name=$(fm name "$f"); desc=$(fm description "$f")
  paths=$(fm paths "$f"); trigger=$(fm trigger "$f")

  [ -n "$name" ] || { warn "$rel: frontmatter has no 'name'"; rc=1; }
  [ -n "$desc" ] || { warn "$rel: frontmatter has no 'description' — nothing tells an agent when this applies"; rc=1; }
  [ -z "$name" ] || [ "$name" = "$base" ] || { warn "$rel: name '$name' does not match the filename"; rc=1; }

  if [ -z "$paths" ] && [ "$trigger" != "always" ]; then
    warn "$rel: declares neither 'paths:' nor 'trigger: always'. It will never load. Pick one deliberately."
    rc=1; continue
  fi
  [ -n "$paths" ] || continue

  globs=$(printf '%s' "$paths" | tr -d "[]\"'" | tr ',' '\n' | sed 's/^ *//; s/ *$//' | sgrep -v '^$')
  matched=0; dead=""
  while IFS= read -r g; do
    [ -n "$g" ] || continue
    re=$(glob_re "$g")
    if [ -n "$(printf '%s\n' "$tracked" | sgrep -E -e "$re" --)" ]; then
      matched=$((matched + 1))
    else
      dead="$dead $g"
    fi
  done <<EOF
$globs
EOF

  if [ "$matched" -eq 0 ]; then
    if [ "$INITIALISED" -eq 0 ]; then
      info "$rel: no glob matches yet (harness not initialised — run 'make harness-init')"
    else
      warn "$rel: NONE of its globs match a tracked file ($(printf '%s' "$paths")) — this rule can never load."
      warn "    Fix the paths, or delete the rule. An inert rule teaches agents that rules here are decorative."
      rc=1
    fi
  elif [ -n "$dead" ] && [ "$INITIALISED" -eq 1 ]; then
    info "$rel: unused glob(s) —$dead (rule still loads via its other paths; tidy when convenient)"
  fi

  # Files renamed out from under this rule since the merge-base.
  if [ "$SHRINK_COMPARABLE" = 1 ] && [ -n "$RENAMES" ]; then
    escaped=""
    while IFS=$'\t' read -r status old new; do
      case "$status" in R*) : ;; *) continue ;; esac
      [ -n "${old:-}" ] && [ -n "${new:-}" ] || continue
      if matches_any "$old" "$globs" && ! matches_any "$new" "$globs"; then
        escaped="$escaped
      $old  ->  $new"
      fi
    done <<REN
$RENAMES
REN
    if [ -n "$escaped" ]; then
      warn "$rel: files were MOVED OUT of this rule's coverage and nothing said so:$escaped"
      warn "    The rule still loads — its globs match other files — so the coverage check"
      warn "    above stays green while the rule no longer governs the code it was written"
      warn "    for. Extend 'paths:' to the new location, or move the rule."
      rc=1
    fi
  fi

  # Raw shrinkage: reported, never failed. Deleting code shrinks coverage
  # legitimately, and a gate that fails on it would need a waiver.
  if [ "$SHRINK_COMPARABLE" = 1 ] && [ -n "${BASE_FILES:-}" ] && [ "$INITIALISED" -eq 1 ]; then
    now_n=0; was_n=0
    while IFS= read -r g; do
      [ -n "$g" ] || continue
      re=$(glob_re "$g")
      now_n=$((now_n + $(printf '%s\n' "$tracked"    | scount -E -e "$re" --)))
      was_n=$((was_n + $(printf '%s\n' "$BASE_FILES" | scount -E -e "$re" --)))
    done <<EOF2
$globs
EOF2
    if [ "$was_n" -gt 0 ] && [ "$now_n" -lt "$was_n" ]; then
      info "$rel: matched files $was_n -> $now_n since the merge-base (not a failure — deleting code shrinks coverage legitimately; check it was deletion and not a move git could not see)"
    fi
  fi
done

[ "$rc" -eq 0 ] || fail "rule coverage — a rule that does not load is a rule that does not exist"
# Do not claim "every glob matches" in a run that just listed globs matching
# nothing. The out-of-the-box output said exactly that, and it was false.
if [ "$INITIALISED" -eq 0 ]; then
  ok "rule coverage ($count rules; glob checks deferred until 'make harness-init' has run)"
else
  ok "rule coverage ($count rules, every glob matches)"
fi
