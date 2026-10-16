#!/usr/bin/env bash
# checkpoint.sh — the point work has to pass before it counts as done.
#
# In a repository that point is the commit. In a shared drive or a plain folder
# there is no commit, so a guardrail written in the constitution is only a
# request: it holds when the agent remembers it. That is exactly the failure a
# harness exists to prevent, so a folder harness needs a checkpoint of its own.
#
# Two ways to reach this script:
#
#   1. As a git pre-commit hook (scripts/hooks/pre-commit), in a repository.
#   2. By the agent at an intentional checkpoint, or as the last step of a
#      procedure before handover:
#        bash scripts/checkpoint.sh
#      The result is recorded. It does not run after every edit or every attempt
#      to finish a conversation.
#
# What it runs depends on the harness's state. An unconfigured harness gets the
# guardrail that matters from the first minute — nothing personal or secret is
# stored where it should not be. A configured one gets the full check.
#
# Usage:
#   bash scripts/checkpoint.sh           run it now; exit status is the result

cd "$(dirname "$0")/.." || exit 1
[ -f harness.yaml ] || { printf 'no harness.yaml above %s\n' "$(pwd)" >&2; exit 1; }

MODE=$(sed -n 's/^mode:[[:space:]]*//p' harness.yaml 2>/dev/null | head -1 | tr -d '"'"'" | sed 's/[[:space:]]*#.*$//')
if [ "$MODE" = "instance" ]; then
  WHAT="work check"
  OUT=$(bash scripts/check.sh 2>&1); RC=$?
else
  WHAT="data-boundary guardrail (harness not yet configured)"
  OUT=$(bash scripts/gates/data-boundary.sh 2>&1); RC=$?
fi

# Record every result where a handover can cite it. A checkpoint nobody can
# show was run is indistinguishable from one that never ran.
mkdir -p runs/.state 2>/dev/null
if [ "$RC" -eq 0 ]; then VERDICT=pass; else VERDICT=fail; fi
printf '%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$VERDICT" "$WHAT" >> runs/.state/checkpoints 2>/dev/null

printf '%s\n' "$OUT"
printf '\ncheckpoint: %s — %s\n' "$VERDICT" "$WHAT"
exit "$RC"
