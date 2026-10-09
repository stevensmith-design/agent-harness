#!/usr/bin/env bash
# declare-harness-change.sh — declare intent before editing the harness.
#
# The failure this addresses is not malice. It is an agent midway through a
# task, blocked by a gate, editing the gate because that is the shortest path
# to green. A change that alters a rule and its enforcement in the same commit
# looks identical whether it tightens or loosens — NOTHING in the repo can tell
# the difference.
#
# Declared intent, not a hard block: every maintenance session must edit the
# harness, and a hook that blocks its own maintenance path gets switched off
# within a day — at which point everyone still believes it is running.
#
# The declaration is PER SESSION. It does not persist, so it cannot silently
# unlock every future session.

. "$(dirname "$0")/lib.sh"
ROOT=$(harness_root "$(dirname "$0")") || exit 1

reason="${1-}"
if [ -z "$reason" ]; then
  printf 'usage: %s "why this session touches the harness"\n' "$0" >&2
  exit 2
fi

mkdir -p "$ROOT/runs/.state"
printf '%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${PPID:-unknown}" "$reason" \
  > "$ROOT/runs/.state/harness-change-declared"

printf '%s✓%s harness change declared: %s\n' "$GRN" "$RST" "$reason"
printf '%s  Keep it out of the same change as content — scripts/gates/harness-content-split.sh checks that.%s\n' "$DIM" "$RST"
