#!/usr/bin/env bash
# Sweep guard — may the fix start? The one place that decides it.
#
#   scripts/sweep-guard.sh <sweep.md>
#
# The bug lane's sweep (harness-defect steps 2–4) used to be told, in prose, to
# "stop" on a spec gap. Nothing read that, so the fix step ran anyway and fixed
# towards an answer nobody had given — which is inventing a rule. This script
# is what bug.workflow.yaml runs between `sweep` and `fix`, and what a person or
# an agent runs by hand when there is no orchestrator. One decision, one place.
#
# The sweep file starts with two lines:
#   gap: spec | test | render | judgement
#   status: clear | BLOCKED_ON_DECISION Q-NNN
#
# Exit 0  clear — the fix may run.
# Exit 2  BLOCKED_ON_DECISION — decide the Q- (questions.md → a DEC-, INV- or
#         REQ-), then re-run the sweep. That is the re-entry point.
# Exit 1  anything else: no sweep, a malformed header, a contradiction.
. "$(dirname "$0")/lib.sh"

f="${1:?usage: sweep-guard.sh <sweep.md>}"
[ -s "$f" ] || fail "no sweep at $f — the sweep did not run, so the fix may not"

field() { sed -n "s/^$1:[[:space:]]*//p" "$f" | head -1 | tr -d '\r'; }
gap=$(field gap); status=$(field status)

case "$gap" in
  spec|test|render|judgement) ;;
  *) fail "sweep header: 'gap:' is '${gap:-missing}' — use spec, test, render or judgement" ;;
esac

case "$status" in
  clear)
    # A spec gap means no rule says what should happen. "clear" over one is a
    # fix towards an invented answer.
    [ "$gap" != spec ] || fail "sweep says gap: spec but status: clear — a spec gap blocks until it is decided"
    ok "sweep clear (gap: $gap) — the fix may run"
    exit 0 ;;
  BLOCKED_ON_DECISION\ Q-[0-9]*)
    q=${status#BLOCKED_ON_DECISION }
    Qf="$HARNESS_ROOT/docs/product/questions.md"
    row=$(sgrep -E "^\|[[:space:]]*$q[[:space:]]*\|" "$Qf" | head -1 || true)
    [ -n "$row" ] || fail "BLOCKED_ON_DECISION $q, but $q is not raised in docs/product/questions.md — raise it, or nobody will decide it"
    st=$(printf '%s' "$row" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/,"",$6); print $6}')
    if [ "$st" = decided ]; then
      warn "BLOCKED_ON_DECISION $q — $q is now decided. Re-run the sweep against the new rule; this sweep predates it."
    else
      warn "BLOCKED_ON_DECISION $q ($st) — a person decides it in docs/product/questions.md, then the sweep re-runs."
    fi
    exit 2 ;;
  *) fail "sweep header: 'status:' is '${status:-missing}' — use 'clear' or 'BLOCKED_ON_DECISION Q-NNN'" ;;
esac
