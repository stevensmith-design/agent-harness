#!/usr/bin/env bash
# PreToolUse on Edit|Write. The agent may not rewrite its own constraints
# mid-task. Exit 2 blocks the call before permission evaluation.
#
# ci-parity: scripts/gates/protected-paths.sh
#
# Escape hatch: a DECLARED intent, not an env var. `HARNESS_ALLOW_SELF_EDIT=1`
# used to unlock this — one export and every edit for the rest of the session
# went through unremarked, on any branch, for no stated reason. A declaration is
# bound to the branch it was made on and carries a sentence:
#     ./scripts/declare-intent.sh harness-edit "policy.sh mis-ranks L4 as L3"
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

intent_ok() {
  local f=".harness-intent" b
  [ -f "$f" ] || return 1
  [ "$(sed -n 's/^scope=//p' "$f" | head -1)" = "harness-edit" ] || return 1
  [ -n "$(sed -n 's/^reason=//p' "$f" | head -1)" ] || return 1
  b=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || return 1
  [ -n "$b" ] && [ "$b" = "$(sed -n 's/^branch=//p' "$f" | head -1)" ]
}
intent_ok && exit 0

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
rel="${file#"${CLAUDE_PROJECT_DIR:-}"/}"
case "$rel" in
  AGENTS.md|harness.config.yaml|.agents/*|.github/workflows/*|docs/decisions/*|scripts/gates/*|scripts/lib.sh)
    cat >&2 <<MSG
Blocked: $rel is harness configuration. Changing it during product work is how
gates get quietly relaxed.

If this change is genuinely needed, say why on the record and it unlocks for
this branch only:
  ./scripts/declare-intent.sh harness-edit "<why, in a sentence>"
Or run /harness-retro, which does that for you.
MSG
    exit 2 ;;
esac
exit 0
