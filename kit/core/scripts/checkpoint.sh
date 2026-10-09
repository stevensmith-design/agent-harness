#!/usr/bin/env bash
# checkpoint.sh — the point work has to pass before it counts as done.
#
# In a repository that point is the commit. In a shared drive or a plain folder
# there is no commit, so a guardrail written in the constitution is only a
# request: it holds when the agent remembers it. That is exactly the failure a
# harness exists to prevent, so a folder harness needs a checkpoint of its own.
#
# Three ways to reach this script, strongest first:
#
#   1. As a Stop hook (.claude/settings.json). When the agent tries to finish,
#      this runs; if a check fails it exits 2, which keeps the agent working and
#      hands it the failures. Hosts that run hooks get a checkpoint nobody has to
#      remember. Hosts that don't simply never call it.
#   2. As a git pre-commit hook (scripts/hooks/pre-commit), in a repository.
#   3. By hand, or as the last step of a procedure before handover:
#        bash scripts/checkpoint.sh
#      Where no host runs hooks, this step IS the checkpoint — so every
#      procedure's Human gate names it, and the result is recorded.
#
# What it runs depends on the harness's state. An unconfigured harness gets the
# guardrail that matters from the first minute — nothing personal or secret is
# stored where it should not be. A configured one gets the full check.
#
# Usage:
#   bash scripts/checkpoint.sh           run it now; exit status is the result
#   bash scripts/checkpoint.sh --hook    run as a Stop hook (reads hook JSON on stdin)

HOOK=0; [ "${1:-}" = "--hook" ] && HOOK=1

if [ "$HOOK" -eq 1 ]; then
  cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
  [ -f harness.yaml ] || exit 0        # not a kit harness; never block a stranger's session
  INPUT=$(cat 2>/dev/null || true)
else
  cd "$(dirname "$0")/.." || exit 1
  [ -f harness.yaml ] || { printf 'no harness.yaml above %s\n' "$(pwd)" >&2; exit 1; }
fi

MODE=$(sed -n 's/^mode:[[:space:]]*//p' harness.yaml 2>/dev/null | head -1 | tr -d '"'"'" | sed 's/[[:space:]]*#.*$//')
if [ "$MODE" = "instance" ]; then
  WHAT="full check"
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

if [ "$HOOK" -eq 0 ]; then
  printf '%s\n' "$OUT"
  printf '\ncheckpoint: %s — %s\n' "$VERDICT" "$WHAT"
  exit "$RC"
fi

# ── Stop-hook mode ───────────────────────────────────────────────────────────
# Loop breaker. A check the agent genuinely cannot fix must not trap the
# session forever — that is how a hook gets deleted. After three blocked stops
# in one session it lets the agent finish, and says loudly that it is finishing
# with failures, so the person sees it rather than a quiet green. "Loudly" means
# systemMessage on stdout: stderr from a hook that exits 0 goes to a debug log
# and reaches nobody, which is where this message used to go.
SID=$(printf '%s' "$INPUT" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 | tr -cd 'A-Za-z0-9_-')
[ -n "$SID" ] || SID=unknown
STATE=".harness/local/checkpoint-$SID"
mkdir -p .harness/local 2>/dev/null

if [ "$RC" -eq 0 ]; then
  rm -f "$STATE" 2>/dev/null
  exit 0
fi

N=$(cat "$STATE" 2>/dev/null || printf 0); case "$N" in ''|*[!0-9]*) N=0 ;; esac
N=$((N + 1)); printf '%s\n' "$N" > "$STATE" 2>/dev/null

FAILS=$(printf '%s\n' "$OUT" | grep -e '✗' -- | head -12)
if [ "$N" -gt 3 ]; then
  rm -f "$STATE" 2>/dev/null
  MSG=$(printf 'Finished without a passing checkpoint: %s still fails after 3 attempts. %s' "$WHAT" "$FAILS" \
        | tr '\n' ' ' | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')
  printf '{"systemMessage":"%s"}\n' "$MSG"
  exit 0
fi
printf 'Checkpoint failed (%s), attempt %s of 3. Do not finish yet. Fix these, or explain to the person why they cannot be fixed:\n%s\n' "$WHAT" "$N" "$FAILS" >&2
exit 2
