#!/usr/bin/env bash
# Eval runner — read this before trusting a number it prints.
#
# WHAT THIS IS. A SCORER. It reads the repository as it finds it, runs each
# case's deterministic scorer commands against that tree, looks up a verdict for
# each judge scorer, and reports.
#
# WHAT IT IS NOT, despite evals/README.md having described the model as
# "Data, Task, Scorers" as though all three were implemented:
#
#   - It does not execute a case's `task`. Nothing here launches an agent, and
#     there is no runtime adapter. The task string is documentation of what a
#     person or agent was supposed to have done BEFORE this ran.
#   - It does not apply a case's `setup` block. Branch and fixture are read from
#     the JSON and ignored. A case that declares setup is therefore scored
#     against whatever tree happens to be checked out, which is not the tree the
#     case specifies — so the runner now says so per case instead of ignoring it
#     silently.
#   - It has no trials, no baselines beyond a note in the case file, and no
#     variance handling. One run, one number.
#
# So a green run means "the scorers this repository state satisfies, it
# satisfies". It does not mean an agent performed the task well. Building the
# missing half — fixtures, a runtime adapter, trials, variance — is a real piece
# of work and is deliberately not attempted here; it should be designed against
# a project that actually runs it, not guessed at.
#
# Two families of scorer, and the difference between them is the whole design:
#
#   deterministic — a command. It passed or it did not. Free, objective.
#   judge         — a rubric no script can decide. It needs a verdict from a
#                   model or a person.
#
# This runner used to count ungraded judge scorers and exit 0 anyway, so a case
# whose only real criterion was a rubric reported success having judged nothing.
# The criterion that matters most is usually the one no script can score, so
# that is exactly the wrong thing to wave through.
#
# The outcomes:
#   exit 0  everything graded, everything passed
#   exit 1  something FAILED — a scorer ran and said no
#   exit 2  INCOMPLETE — the run cannot be read as a pass: a judge scorer has no
#           live verdict, or a case declared a setup nothing applied
#   exit 3  INFRA_ERROR — the RUNNER broke. A case file that will not parse, a
#           scorer type it does not know, a command that could not be executed
#           at all (127/126). None of that is a statement about the work under
#           test, and folding it into exit 1 made "the harness is broken" and
#           "the change is bad" the same colour.
#
# `--judge-coverage` answers only the last question: does every judge scorer have
# a live verdict? It runs no commands, so a gate can ask it on any tree. A
# deterministic scorer usually needs the agent task to have been performed first,
# and a gate that executes those would fail for reasons that are nothing to do
# with what it is checking.
#
# A verdict lives in evals/grades.tsv and is bound to the bytes it judged: the
# row carries a checksum of the rubric text it was given. Reword the rubric and
# the old verdict stops counting, because it graded a different question.
. "$(dirname "$0")/../scripts/lib.sh"

COVERAGE_ONLY=0
[ "${1:-}" = "--judge-coverage" ] && COVERAGE_ONLY=1

[ "$(cfg evals.enabled false)" = "true" ] || { warn "evals disabled in harness.config.yaml (evals.enabled)"; exit 0; }

CASES_DIR="$HARNESS_ROOT/$(cfg evals.cases_dir evals/cases)"
GRADES="$HARNESS_ROOT/$(cfg evals.grades_file evals/grades.tsv)"
infra=0; infra_list=""
infra_error() {  # infra_error <message>
  printf '\033[31m✗ INFRA_ERROR\033[0m %s\n' "$1" >&2
  infra=$((infra+1)); infra_list="$infra_list      $1"$'\n'
}

if [ ! -d "$CASES_DIR" ]; then
  infra_error "$CASES_DIR does not exist — nowhere to read cases from"
  exit 3
fi

# rubric_key <text> — the identity a verdict is recorded against.
rubric_key() { printf '%s' "$1" | cksum | tr -d ' ' ; }

# graded <case> <scorer> <key> — prints pass|fail if a live verdict exists.
graded() {
  [ -f "$GRADES" ] || return 1
  awk -F'\t' -v c="$1" -v s="$2" -v k="$3" \
    '$1==c && $2==s && $3==k { print $4; found=1; exit } END { exit(found?0:1) }' "$GRADES"
}

pass=0; failed=0; ungraded=0; stale=0; unapplied=0
ungraded_list=""; unapplied_list=""

shopt -s nullglob
cases=("$CASES_DIR"/*.json)
shopt -u nullglob
if [ "${#cases[@]}" -eq 0 ]; then
  infra_error "$CASES_DIR holds no cases — evals switched on and empty is the same as off, but harder to see"
  exit 3
fi

for case_file in "${cases[@]}"; do
  # One python call reads the id AND whether a setup block is declared, so a
  # malformed case is one INFRA_ERROR rather than two cascading ones.
  if ! meta=$(python3 -c "
import json,sys
d=json.load(open(sys.argv[1]))
setup=d.get('setup') or {}
declared=[k for k,v in setup.items() if v not in (None,'',[],{})] if isinstance(setup,dict) else ['setup']
print(d['id'] + chr(9) + ','.join(sorted(declared)))" "$case_file" 2>&1); then
    infra_error "$(basename "$case_file"): could not read the case — ${meta}"
    continue
  fi
  # A TAB, not a newline: command substitution strips trailing newlines, so an
  # empty setup list collapsed the second line away and the id was read back as
  # the setup list. Found by running the runner, not by reading it.
  id=${meta%%$'\t'*}
  declared_setup=${meta#*$'\t'}
  [ "$COVERAGE_ONLY" = 1 ] || info "case $id"

  # A declared setup that nothing applies is not a detail. Every score printed
  # below it describes a different tree than the one the case asked for.
  if [ -n "$declared_setup" ] && [ "$COVERAGE_ONLY" != 1 ]; then
    printf '  \033[33m!\033[0m setup DECLARED BUT NOT APPLIED (%s) — this runner does not\n' "$declared_setup" >&2
    printf '      apply setup blocks. The scores below are measured against the tree as\n' >&2
    printf '      checked out, not the tree this case specifies.\n' >&2
    unapplied=$((unapplied+1))
    unapplied_list="$unapplied_list      $id: $declared_setup"$'\n'
  fi

  # One tab-separated row per scorer: type, name, payload (command or rubric).
  # Tabs and newlines inside a rubric would break the row, so the payload is
  # emitted with them collapsed.
  if ! rows=$(python3 -c "
import json,sys
d=json.load(open(sys.argv[1]))
for s in d['scorers']:
    p = s.get('command') if s['type']=='deterministic' else s.get('rubric','')
    p = ' '.join(str(p).split())
    print('\t'.join([s['type'], s['name'], p]))" "$case_file" 2>&1); then
    infra_error "$id: could not read scorers — ${rows}"
    continue
  fi

  while IFS=$'\t' read -r type name payload; do
    [ -n "${type:-}" ] || continue
    case "$type" in
      deterministic)
        [ "$COVERAGE_ONLY" = 1 ] && continue
        # `if`, not `cmd; rc=$?`: lib.sh runs with `set -e`, under which an
        # untested failing command ends the shell before the next line runs.
        if ( cd "$HARNESS_ROOT" && eval "$payload" ) >/dev/null 2>&1; then drc=0; else drc=$?; fi
        case "$drc" in
          0)   ok "  $name"; pass=$((pass+1)) ;;
          # 127 = command not found, 126 = found but not executable. Neither is
          # a verdict on the work; it means the scorer could not be run.
          126|127) infra_error "$id/$name: the scorer command could not be executed (exit $drc): $payload" ;;
          *)   warn "  $name — FAILED: $payload"; failed=$((failed+1)) ;;
        esac
        ;;
      judge)
        key=$(rubric_key "$payload")
        verdict=$(graded "$id" "$name" "$key") || verdict=""
        case "$verdict" in
          pass) [ "$COVERAGE_ONLY" = 1 ] || ok "  $name (judged)"; pass=$((pass+1)) ;;
          fail) warn "  $name — judged FAIL"; failed=$((failed+1)) ;;
          *)
            # Distinguish "never graded" from "graded against a different
            # rubric", because the second is a rubric change nobody re-judged.
            if [ -f "$GRADES" ] && awk -F'\t' -v c="$id" -v s="$name" \
                 '$1==c && $2==s {found=1} END{exit(found?0:1)}' "$GRADES"; then
              printf '  \033[35m?\033[0m %s (judge) — STALE: the rubric changed since it was graded\n' "$name"
              stale=$((stale+1))
            else
              printf '  \033[35m?\033[0m %s (judge) — UNGRADED\n' "$name"
            fi
            printf '      %s\n' "$payload"
            ungraded=$((ungraded+1))
            ungraded_list="$ungraded_list  ./evals/grade.sh $id '$name' pass|fail \"<who/why>\""$'\n'
            ;;
        esac
        ;;
      *) infra_error "$id: scorer '$name' has unknown type '$type' — use deterministic or judge" ;;
    esac
  done <<< "$rows"
done

if [ "$COVERAGE_ONLY" = 1 ]; then
  [ "$infra" -eq 0 ] || { warn "judge coverage is unknown — $infra INFRA_ERROR(s)"; exit 3; }
  [ "$ungraded" -eq 0 ] || exit 2
  ok "judge coverage: $pass judge scorer(s), all with a live verdict"
  exit 0
fi

echo
printf '%s passed · %s failed · %s ungraded' "$pass" "$failed" "$ungraded"
if [ "$stale" -gt 0 ];     then printf ' (%s of them stale)' "$stale"; fi
if [ "$unapplied" -gt 0 ]; then printf ' · %s case(s) with an unapplied setup' "$unapplied"; fi
if [ "$infra" -gt 0 ];     then printf ' · %s INFRA_ERROR' "$infra"; fi
echo

# INFRA_ERROR outranks everything: if the runner broke, the other counts are a
# partial view and reporting them as a verdict is the overclaim this file exists
# to stop making.
if [ "$infra" -gt 0 ]; then
  warn ""
  warn "$infra INFRA_ERROR(s) — the RUNNER failed, which is not a statement about the work:"
  printf '%s' "$infra_list" >&2
  warn "  The pass/fail counts above cover only the cases that did run."
  exit 3
fi

if [ "$failed" -gt 0 ]; then
  fail "evals: $failed scorer(s) failed"
fi

if [ "$unapplied" -gt 0 ]; then
  warn ""
  warn "$unapplied case(s) declare a setup block that this runner does not apply:"
  printf '%s' "$unapplied_list" >&2
  warn "  Those scores describe the tree as checked out, not the tree the case asks"
  warn "  for. Until a runner applies setup, remove the block or accept that the"
  warn "  case is measuring something else. This run is INCOMPLETE, not passing."
  exit 2
fi
if [ "$ungraded" -gt 0 ]; then
  warn ""
  warn "$ungraded judge scorer(s) have no live verdict. This run is INCOMPLETE, not passing."
  warn "  A rubric is in the case because no script can decide it. Skipping it and"
  warn "  printing a ✓ grades the easy half and calls it the whole."
  warn "  Record a verdict:"
  printf '%s' "$ungraded_list" >&2
  exit 2
fi
ok "evals: $pass scorer(s), all graded"
