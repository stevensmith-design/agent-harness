#!/usr/bin/env bash
# SessionStart. Hands the agent the state it would otherwise have to guess at:
# ci-parity: none — informational. It reports state and enforces no rule, so
#   there is nothing for CI to enforce a second time.
#
# branch, active spec, and whether the harness itself is currently intact.
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '-')
spec=none
for d in specs/*/; do case "$d" in *000-template*) ;; *) spec="$d";; esac; done
tier=$(grep -o '"harnessTier"[^,]*' .claude/settings.json 2>/dev/null | cut -d'"' -f4 || echo unknown)
# Is a retro due? The script owns the thresholds and prints nothing when it is
# not, so a quiet week costs nothing. A missing or broken script costs the
# reminder, never the session. Quotes and backslashes are escaped for the JSON.
due=$(bash ./scripts/retro-evidence.sh --due 2>/dev/null || true)
due=$(printf '%s' "$due" | tr -d '\n' | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"branch=%s active-spec=%s permission-tier=%s. Read AGENTS.md before editing. Run `make check` before claiming done.%s"}}\n' \
  "$branch" "$spec" "$tier" "${due:+ $due}"
