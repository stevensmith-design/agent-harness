#!/usr/bin/env bash
# PreToolUse for Read|Grep|Glob|Bash. Prevents sensitive values entering agent
# context and blocks privileged or download-to-execute installation shortcuts.
# Ordinary scoped installs go through settings.json's ask rules after intake.
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
input=""; [ -t 0 ] || input=$(cat)
[ -n "$input" ] || exit 0
blocked() {
  printf '%s\n' "Blocked: $1" >&2
  printf '%s\n' "If this looks wrong, stop after this attempt. Report what matched and why, then propose a safe fix; do not reword the command to evade the hook." >&2
  exit 2
}
tool=$(printf '%s' "$input" | tr -d '\n' | sed -n -E 's/.*"tool_name"[[:space:]]*:[[:space:]]*"([^"\\]*)".*/\1/p')
value=$(printf '%s' "$input" | tr -d '\n' \
  | sed -n -E 's/.*"(file_path|path|command)"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\2/p' \
  | sed -e 's/\\\//\//g' -e 's/\\\\/\\/g')

probe=$(printf '%s\n' "$value" | sed -E 's/\.env\.(sample|example)/PUBLIC_ENV_SHAPE/g; s/[^/[:space:]"'"'"']+\.pub/PUBLIC_KEY/g')
sensitive=0; sensitive_reason=""
BUILTIN_RE='(^|[^A-Za-z0-9_.-])(\.env($|\.|[^A-Za-z0-9_.-])|\.npmrc($|[^A-Za-z0-9_.-])|\.pypirc($|[^A-Za-z0-9_.-])|\.netrc($|[^A-Za-z0-9_.-])|[^/[:space:]]*(credential|service-account)[^/[:space:]]*\.(json|ya?ml|toml|ini|conf)($|[^A-Za-z0-9_.-])|id_(rsa|dsa|ecdsa|ed25519)($|\.)|~?/?\.ssh(/|$)|~?/?\.aws(/|$)|~?/?\.config/gcloud(/|$))'
if printf '%s\n' "$probe" | grep -qiE "$BUILTIN_RE"; then
  sensitive=1; sensitive_reason="a credential filename"
fi
if printf '%s\n' "$probe" | grep -qiE '(^|[/[:space:]])[^/[:space:]]+\.(pem|key|p12|pfx)($|[;&|[:space:]])'; then
  sensitive=1; sensitive_reason="a credential filename"
fi

case "$tool" in
  Read|Grep|Glob)
    [ "$sensitive" -eq 0 ] || {
      blocked "sensitive file contents may not enter agent context (${sensitive_reason:-sensitive path}). Use sample/schema key names and masked formats."
    } ;;
  Bash)
    if printf '%s\n' "$value" | grep -qE '(^|[;&|][[:space:]]*)(env|printenv|set|export[[:space:]]+-p)([;&|[:space:]]|$)'; then
      blocked "dumping the process environment could disclose credentials or personal data."
    fi
    if printf '%s\n' "$value" | grep -qE '(^|[;&|[:space:]])(rg|grep|find)([;&|[:space:]]).*(--hidden|--no-ignore|-uuu)([;&|[:space:]]|$)'; then
      blocked "bypassing ignore rules during a broad search can pull local secret files into output."
    fi
    if [ "$sensitive" -eq 1 ]; then
      blocked "shell command matched ${sensitive_reason:-a sensitive path}; even a harmless-looking command can surface it in agent-visible output."
    fi
    if printf '%s\n' "$value" | grep -qiE '(curl|wget)[^|]*\|[[:space:]]*(sudo[[:space:]]+)?(ba|z|fi)?sh|(^|[;&|[:space:]])sudo[[:space:]]|(^|[;&|[:space:]])((brew|apt|apt-get|yum|dnf|pacman|winget|choco|scoop)[[:space:]]+install|npm[[:space:]]+(exec|[^;&|]*[[:space:]]-g)|pnpm[[:space:]]+(dlx|[^;&|]*[[:space:]]-g)|yarn[[:space:]]+(dlx|global)|bunx|npx|uv[[:space:]]+tool[[:space:]]+install|cargo[[:space:]]+install|go[[:space:]]+install|gem[[:space:]]+install|corepack[[:space:]]+(enable|prepare|use|install))([;&|[:space:]]|$)'; then
      blocked "privileged, global, or download-to-execute installation is outside this harness boundary. Use capability-intake and a scoped package-manager install through the normal approval prompt."
    fi ;;
esac
exit 0
