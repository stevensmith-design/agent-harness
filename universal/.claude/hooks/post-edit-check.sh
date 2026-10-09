#!/usr/bin/env bash
# PostToolUse on Edit|Write. Format + typecheck the file that just changed.
# ci-parity: none — `make check` runs the same lint/format/typecheck fail-closed
#   through the adapter. This hook only moves that feedback to the moment of the
#   edit; it is not the only thing enforcing it.
#
# Success is silent; failure is verbose. That asymmetry is the whole design —
# a hook that chatters on every edit gets disabled within a day.
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
# Claude Code sends the tool call as JSON on STDIN. This used to read a
# CLAUDE_TOOL_INPUT environment variable, which Claude Code has never set: the
# path was always empty, the hook exited 0 on every edit, and it enforced nothing
# while looking installed. Parsed with sed so the hook needs no jq; the pattern
# skips escaped quotes, so a "file_path" inside a Write's content cannot match.
input=""; [ -t 0 ] || input=$(cat)
file=$(printf '%s' "$input" | tr -d '\n' \
  | sed -n -E 's/.*"file_path"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/p' \
  | sed -e 's/\\\//\//g' -e 's/\\\\/\\/g')
[ -n "$file" ] || exit 0
case "$file" in
  *.md|*.json|*.yaml|*.yml) exit 0 ;;
esac
out=$( { ./scripts/run.sh format >/dev/null 2>&1; ./scripts/run.sh typecheck; } 2>&1 ) || {
  # stderr, not stdout: on exit 2 Claude Code shows the agent stderr only, so
  # the typecheck output printed to stdout here was never seen.
  printf '%s\n' "$out" | tail -30 >&2
  echo "typecheck failed after editing $file — fix it before continuing." >&2
  exit 2
}
exit 0
