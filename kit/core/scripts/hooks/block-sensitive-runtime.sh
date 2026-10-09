#!/usr/bin/env bash
# PreToolUse for Read|Grep|Glob|Bash. Prevents sensitive values entering agent
# context and prevents the agent itself from installing third-party code.
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
input=""; [ -t 0 ] || input=$(cat)
[ -n "$input" ] || exit 0
tool=$(printf '%s' "$input" | tr -d '\n' | sed -n -E 's/.*"tool_name"[[:space:]]*:[[:space:]]*"([^"\\]*)".*/\1/p')
value=$(printf '%s' "$input" | tr -d '\n' \
  | sed -n -E 's/.*"(file_path|path|command)"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\2/p' \
  | sed -e 's/\\\//\//g' -e 's/\\\\/\\/g')

probe=$(printf '%s\n' "$value" | sed -E 's/\.env\.(sample|example)/PUBLIC_ENV_SHAPE/g; s/[^/[:space:]"'"'"']+\.pub/PUBLIC_KEY/g')
sensitive=0
printf '%s\n' "$probe" | grep -qiE '(^|[/[:space:]"'"'"'])(\.env($|\.|[/[:space:]"'"'"'])|\.npmrc($|[/[:space:]"'"'"'])|\.pypirc($|[/[:space:]"'"'"'])|\.netrc($|[/[:space:]"'"'"'])|[^/[:space:]]*(credential|service-account)[^/[:space:]]*|id_(rsa|dsa|ecdsa|ed25519)($|\.)|[^/[:space:]]+\.(pem|key|p12|pfx)($|[/[:space:]"'"'"'])|~?/?\.ssh(/|$)|~?/?\.aws(/|$)|~?/?\.config/gcloud(/|$))' && sensitive=1

case "$tool" in
  Read|Grep|Glob)
    [ "$sensitive" -eq 0 ] || {
      printf '%s\n' "Blocked: sensitive file contents may not enter agent context. Use sample/schema key names and masked formats." >&2
      exit 2
    } ;;
  Bash)
    if printf '%s\n' "$value" | grep -qE '(^|[;&|[:space:]])(env|printenv|set|export[[:space:]]+-p)([;&|[:space:]]|$)'; then
      printf '%s\n' "Blocked: dumping the process environment could disclose credentials or personal data." >&2
      exit 2
    fi
    if printf '%s\n' "$value" | grep -qE '(^|[;&|[:space:]])(rg|grep|find)([;&|[:space:]]).*(--hidden|--no-ignore|-uuu)([;&|[:space:]]|$)'; then
      printf '%s\n' "Blocked: bypassing ignore rules during a broad search can pull local secret files into output." >&2
      exit 2
    fi
    if [ "$sensitive" -eq 1 ]; then
      printf '%s\n' "Blocked: shell commands may not reference a sensitive file; even a harmless-looking command can surface it in agent-visible output." >&2
      exit 2
    fi
    if printf '%s\n' "$value" | grep -qiE '(curl|wget)[^|]*\|[[:space:]]*(sudo[[:space:]]+)?(ba|z|fi)?sh|(^|[;&|[:space:]])sudo[[:space:]]|(^|[;&|[:space:]])((brew|apt|apt-get|yum|dnf|pacman|winget|choco|scoop)[[:space:]]+install|npm[[:space:]]+(ci|i|install|add|update|exec)|pnpm[[:space:]]+(install|add|update|dlx)|yarn[[:space:]]+(install|add|up|dlx)|bun[[:space:]]+(install|add|x)|bunx|python[0-9]*[[:space:]]+-m[[:space:]]+pip[[:space:]]+install|pip3?[[:space:]]+install|uv[[:space:]]+(add|sync|tool[[:space:]]+install)|poetry[[:space:]]+add|cargo[[:space:]]+(add|install)|go[[:space:]]+(get|install)|gem[[:space:]]+install|(flutter|dart)[[:space:]]+pub[[:space:]]+(add|get)|npx|corepack[[:space:]]+(enable|prepare|use|install))([;&|[:space:]]|$)'; then
      printf '%s\n' "Blocked: this harness does not let an agent install or auto-execute third-party code. Run capability-intake; an authorised human performs the approved install." >&2
      exit 2
    fi ;;
esac
exit 0
