#!/usr/bin/env bash
# PreToolUse on Read|Grep|Glob|Bash. Prevent sensitive local files and process
# environments from becoming tool output, where an agent could quote them.
# ci-parity: none — runtime disclosure happens before output exists; secret-scan separately protects repository content
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

# Remove known-public filenames before testing. A blanket "sample was present"
# exemption let `cat .env .env.sample` hide the sensitive half of a command.
probe=$(printf '%s\n' "$value" | sed -E 's/\.env\.(sample|example)/PUBLIC_ENV_SHAPE/g; s/[^/[:space:]"]+\.pub/PUBLIC_KEY/g')
sensitive=0
sensitive_reason=""
BUILTIN_RE='(^|[^A-Za-z0-9_.-])(\.env($|\.|[^A-Za-z0-9_.-])|\.npmrc($|[^A-Za-z0-9_.-])|\.pypirc($|[^A-Za-z0-9_.-])|\.netrc($|[^A-Za-z0-9_.-])|[^/[:space:]]*(credential|service-account)[^/[:space:]]*\.(json|ya?ml|toml|ini|conf)($|[^A-Za-z0-9_.-])|id_(rsa|dsa|ecdsa|ed25519)($|\.)|~?/?\.ssh(/|$)|~?/?\.aws(/|$)|~?/?\.config/gcloud(/|$))'
if printf '%s\n' "$probe" | grep -qiE "$BUILTIN_RE"; then
  sensitive=1; sensitive_reason="a built-in credential filename"
fi

# Credential extensions are filenames only at a shell/path boundary. The old
# expression also matched program member access such as `event.key`, causing a
# retry whenever JavaScript containing keyboard handling appeared in a command.
if printf '%s\n' "$probe" | grep -qiE '(^|[/[:space:]])[^/[:space:]]+\.(pem|key|p12|pfx)($|[;&|[:space:]])'; then
  sensitive=1; sensitive_reason="a built-in credential filename"
fi

# Project-specific local data that does not look like a credential: databases,
# customer exports, recordings, and similar files. Keep the config as an inline
# list of globs so this runtime hook remains dependency-free.
if [ -f harness.config.yaml ]; then
  configured=$(awk '
    /^security:/ { inb=1; next }
    /^[^[:space:]#]/ { inb=0 }
    inb && /^[[:space:]]+sensitive_paths:/ { sub(/^[^:]*:[[:space:]]*/,""); sub(/[[:space:]]+#.*$/,""); print; exit }
  ' harness.config.yaml | tr -d '[]"' | tr ',' '\n')
  while IFS= read -r sp; do
    sp=$(printf '%s' "$sp" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    [ -n "$sp" ] || continue
    case "$value" in *$sp*) sensitive=1; sensitive_reason="security.sensitive_paths"; break ;; esac
  done <<< "$configured"
fi

# Naming an ignored file in a metadata-only Git query does not read it. Reject
# shell composition so `git status file; cat file` cannot use this exception.
safe_metadata=0
if printf '%s\n' "$value" | grep -qE '^[[:space:]]*git[[:space:]]+(status|check-ignore|ls-files)([[:space:]][^;&|<>]*)?[[:space:]]*$' \
   && ! printf '%s\n' "$value" | grep -qE '\$\(|`'; then
  safe_metadata=1
fi

case "$tool" in
  Read|Grep|Glob)
    [ "$sensitive" -eq 0 ] || {
      blocked "sensitive file contents may not enter agent context (${sensitive_reason:-sensitive path}). Read only a public sample/schema, or ask the operator to handle the real value."
    } ;;
  Bash)
    # Environment dumpers are dangerous when they are the command at the start
    # of a shell segment. Matching them as arbitrary words also blocked harmless
    # prose and quoted grep patterns such as `grep -E "env|token"`.
    if printf '%s\n' "$value" | grep -qE '(^|[;&|][[:space:]]*)(env|printenv|set|export[[:space:]]+-p)([;&|[:space:]]|$)'; then
      blocked "dumping the process environment could expose credentials or personal data."
    fi
    if printf '%s\n' "$value" | grep -qE '(^|[;&|[:space:]])(rg|grep|find)([;&|[:space:]]).*(--hidden|--no-ignore|-uuu)([;&|[:space:]]|$)'; then
      blocked "bypassing ignore rules during a broad search can pull local sensitive files into output."
    fi
    if [ "$sensitive" -eq 1 ] && [ "$safe_metadata" -ne 1 ]; then
      blocked "shell command matched ${sensitive_reason:-a sensitive path}. Metadata-only git status/check-ignore/ls-files commands are allowed; content access is not."
    fi ;;
esac
exit 0
