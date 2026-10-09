#!/usr/bin/env bash
# Record why this branch is allowed to run an install-capable command.
# This is intentionally local, branch-bound, and short-lived.
. "$(dirname "$0")/lib.sh"

case "${1:-}" in
  --clear) rm -f "$HARNESS_ROOT/.dependency-intent"; ok "dependency intent cleared"; exit 0 ;;
esac

reason="${*:-}"
[ ${#reason} -ge 12 ] || fail "usage: ./scripts/declare-dependency-change.sh '<approved package(s) and reason>'"
branch=$(git -C "$HARNESS_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
[ -n "$branch" ] && [ "$branch" != HEAD ] || fail "dependency intent requires a named git branch"
main=$(cfg git.main_branch main)
[ "$branch" != "$main" ] || fail "dependency changes are refused on the integration branch"

{
  printf 'branch=%s\n' "$branch"
  printf 'created=%s\n' "$(date +%s)"
  printf 'reason=%s\n' "$reason"
} > "$HARNESS_ROOT/.dependency-intent"
ok "dependency change declared for $branch: $reason"
