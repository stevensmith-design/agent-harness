#!/usr/bin/env bash
# declare-harness-change.sh — declare intent before editing the harness.
#
# The failure this addresses is not malice. It is an agent midway through a
# task, blocked by a gate, editing the gate because that is the shortest path
# to green. A change that alters a rule and its enforcement in the same commit
# looks identical whether it tightens or loosens — NOTHING in the repo can tell
# the difference.
#
# The declaration command is operator-controlled by the runtime permission
# boundary. Its record is local, auditable and branch-bound; an agent cannot
# create the file directly and silently unlock its own harness edits.

. "$(dirname "$0")/lib.sh"
ROOT=$(harness_root "$(dirname "$0")") || exit 1

reason="${1-}"
if [ "${#reason}" -lt 12 ]; then
  printf 'usage: %s "why this session touches the harness"\n' "$0" >&2
  exit 2
fi

branch=$(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
[ -n "$branch" ] && [ "$branch" != HEAD ] || fail "harness change intent requires a named git branch"
main=$(cfg main_branch main)
[ "$branch" != "$main" ] || fail "harness changes are refused on the integration branch"

mkdir -p "$ROOT/runs/.state"
{
  printf 'branch=%s\n' "$branch"
  printf 'created=%s\n' "$(date +%s)"
  printf 'reason=%s\n' "$reason"
  printf 'trust=operator_prompt\n'
} > "$ROOT/runs/.state/harness-change-declared"

printf '%s✓%s harness change declared: %s\n' "$GRN" "$RST" "$reason"
printf '%s  Keep it out of the same change as content — scripts/gates/harness-content-split.sh checks that.%s\n' "$DIM" "$RST"
