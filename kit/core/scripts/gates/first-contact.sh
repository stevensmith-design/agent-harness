#!/usr/bin/env bash
# first-contact.sh — work may not proceed inside an unconfigured harness.
#
# The session-start hook announces this state, but a hook is advisory and only
# fires in one tool. Someone working in Cursor, in Codex, or by hand never sees
# it. Instructions are advisory; gates are not — so the same fact is checked
# here, where it holds regardless of who or what is at the keyboard.
#
# The rule, stated so both directions are testable:
#
#   A harness in `mode: template` is fine while it is untouched. It becomes a
#   FAILURE the moment work has begun inside it — because from that point on
#   every gate is passing over placeholder patterns that match nothing, and the
#   green tick has become load-bearing while checking an empty set.
#
# "Work has begun" is deliberately not a judgement call:
#   - a foundation file exists beyond the shipped README, or
#   - a dated run directory exists.

# shellcheck source=../lib.sh
. "$(dirname "$0")/../lib.sh"
ROOT=$(harness_root "$(dirname "$0")") || exit 1
cd "$ROOT" || exit 1

MODE=$(cfg mode template)
FOUND=$(find foundations -type f -not -name 'README.md' 2>/dev/null | wc -l | tr -d ' ')
RUNS=$(find runs -maxdepth 1 -type d -name '20*' 2>/dev/null | wc -l | tr -d ' ')
WORK=$((FOUND + RUNS))

if [ "$MODE" != "instance" ] && [ "$WORK" -gt 0 ]; then
  fail "work has begun ($FOUND foundation file(s), $RUNS run(s)) but harness.yaml still says mode: $MODE."
  fail "  An unconfigured harness enforces nothing — its surface patterns match placeholders, so every"
  fail "  gate passes over an empty set. Finish the scoping pass and set mode: instance."
elif [ "$MODE" != "instance" ]; then
  pass "harness not yet configured, and no work has begun" "mode=$MODE, $WORK work artifact(s)"
else
  pass "harness configured" "mode=instance, $FOUND foundation file(s), $RUNS run(s)"
fi

# A configured harness that has still never carried work is reported, not
# failed: it is a legitimate state on day one. It stops being legitimate
# quietly, which is why it is said out loud every time rather than never.
if [ "$MODE" = "instance" ] && [ "$RUNS" -eq 0 ]; then
  warn "no run records yet — this harness has not carried real work. It is a rehearsal until it has."
fi

finish
