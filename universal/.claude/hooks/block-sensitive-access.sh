#!/usr/bin/env bash
# PreToolUse on Read|Grep|Glob|Bash. Prevent secret-bearing files and process
# environments from becoming tool output, where an agent could quote them.
# ci-parity: none — runtime disclosure happens before output exists; secret-scan separately protects repository content
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
input=""; [ -t 0 ] || input=$(cat)
[ -n "$input" ] || exit 0

tool=$(printf '%s' "$input" | tr -d '\n' | sed -n -E 's/.*"tool_name"[[:space:]]*:[[:space:]]*"([^"\\]*)".*/\1/p')
value=$(printf '%s' "$input" | tr -d '\n' \
  | sed -n -E 's/.*"(file_path|path|command)"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\2/p' \
  | sed -e 's/\\\//\//g' -e 's/\\\\/\\/g')

# Remove known-public filenames before testing. A blanket "sample was present"
# exemption let `cat .env .env.sample` hide the sensitive half of a command.
probe=$(printf '%s\n' "$value" | sed -E 's/\.env\.(sample|example)/PUBLIC_ENV_SHAPE/g; s/[^/[:space:]"'"'"']+\.pub/PUBLIC_KEY/g')
sensitive=0
printf '%s\n' "$probe" | grep -qiE '(^|[/[:space:]"'"'"'])(\.env($|\.|[/[:space:]"'"'"'])|\.npmrc($|[/[:space:]"'"'"'])|\.pypirc($|[/[:space:]"'"'"'])|\.netrc($|[/[:space:]"'"'"'])|[^/[:space:]]*(credential|service-account)[^/[:space:]]*|id_(rsa|dsa|ecdsa|ed25519)($|\.)|[^/[:space:]]+\.(pem|key|p12|pfx)($|[/[:space:]"'"'"'])|~?/?\.ssh(/|$)|~?/?\.aws(/|$)|~?/?\.config/gcloud(/|$))' && sensitive=1

case "$tool" in
  Read|Grep|Glob)
    [ "$sensitive" -eq 0 ] || {
      printf '%s\n' "Blocked: sensitive file contents may not enter agent context. Read the variable or file name from a sample/template; ask the operator to use the real value." >&2
      exit 2
    } ;;
  Bash)
    if printf '%s\n' "$value" | grep -qE '(^|[;&|[:space:]])(env|printenv|set|export[[:space:]]+-p)([;&|[:space:]]|$)'; then
      printf '%s\n' "Blocked: dumping the process environment could expose credentials or personal data." >&2
      exit 2
    fi
    if printf '%s\n' "$value" | grep -qE '(^|[;&|[:space:]])(rg|grep|find)([;&|[:space:]]).*(--hidden|--no-ignore|-uuu)([;&|[:space:]]|$)'; then
      printf '%s\n' "Blocked: bypassing ignore rules during a broad search can pull local secret files into output." >&2
      exit 2
    fi
    if [ "$sensitive" -eq 1 ]; then
      printf '%s\n' "Blocked: shell commands may not reference a sensitive file; even a harmless-looking command can surface its path or contents in agent-visible output." >&2
      exit 2
    fi ;;
esac
exit 0
