#!/usr/bin/env bash
# PreToolUse on Bash. Install-capable commands require a current branch-bound
# declaration; globally mutating and download-to-shell forms are always blocked.
# ci-parity: none — command execution has no CI artifact; dependency-safety checks the resulting tree
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
input=""; [ -t 0 ] || input=$(cat)
command=$(printf '%s' "$input" | tr -d '\n' \
  | sed -n -E 's/.*"command"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/p' \
  | sed -e 's/\\\//\//g' -e 's/\\\\/\\/g')
[ -n "$command" ] || exit 0

if printf '%s\n' "$command" | grep -qiE '(curl|wget)[^|]*\|[[:space:]]*(sudo[[:space:]]+)?(ba|z|fi)?sh|(^|[;&|[:space:]])sudo[[:space:]]|npm[[:space:]]+(i|install)[[:space:]]+(-g|--global)|npx[[:space:]]+(-y|--yes)'; then
  printf '%s\n' "Blocked: global installs, privilege escalation, auto-confirmed package execution, and downloads piped to a shell are outside the harness safety boundary." >&2
  exit 2
fi

if ! printf '%s\n' "$command" | grep -qE '(^|[;&|[:space:]])(make[[:space:]]+(deps|setup)|npm[[:space:]]+(ci|i|install|add|update|exec)|pnpm[[:space:]]+(install|add|update|dlx)|yarn[[:space:]]+(install|add|up|dlx)|bun[[:space:]]+(install|add|x)|bunx|python[0-9]*[[:space:]]+-m[[:space:]]+pip[[:space:]]+install|pip3?[[:space:]]+install|uv[[:space:]]+(add|sync|tool[[:space:]]+install)|poetry[[:space:]]+add|cargo[[:space:]]+(add|install)|go[[:space:]]+(get|install)|gem[[:space:]]+install|(flutter|dart)[[:space:]]+pub[[:space:]]+(add|get)|npx|corepack[[:space:]]+(enable|prepare|use|install))([;&|[:space:]]|$)'; then
  exit 0
fi

intent=.dependency-intent
[ -f "$intent" ] || {
  printf '%s\n' "Blocked: package installation was not declared. Run /harness-dependency-intake, obtain explicit operator approval, then record the approved package and reason with ./scripts/declare-dependency-change.sh." >&2
  exit 2
}
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)
saved=$(sed -n 's/^branch=//p' "$intent" | head -1)
created=$(sed -n 's/^created=//p' "$intent" | head -1)
reason=$(sed -n 's/^reason=//p' "$intent" | head -1)
now=$(date +%s)
case "$created" in ''|*[!0-9]*) created=0 ;; esac
if [ -z "$branch" ] || [ "$branch" != "$saved" ] || [ -z "$reason" ] || [ $((now - created)) -gt 28800 ]; then
  printf '%s\n' "Blocked: dependency declaration is missing, stale, or belongs to another branch. Re-run intake and declare the approved change again." >&2
  exit 2
fi
exit 0
