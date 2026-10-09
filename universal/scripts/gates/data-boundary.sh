#!/usr/bin/env bash
# Personal-data and sensitive-path boundary. Reports filenames only: a scanner
# must not leak the value it is protecting into agent-visible output.
. "$(dirname "$0")/../lib.sh"

ALLOW_FILE="$HARNESS_ROOT/.pii-allow"
allowed() {
  [ -f "$ALLOW_FILE" ] || return 1
  local rel="$1" pattern
  while IFS= read -r pattern || [ -n "$pattern" ]; do
    case "$pattern" in ''|'#'*) continue ;; esac
    # shellcheck disable=SC2254
    case "$rel" in $pattern) return 0 ;; esac
  done < "$ALLOW_FILE"
  return 1
}

rc=0; examined=0
tracked=$(git -C "$HARNESS_ROOT" -c core.quotepath=false ls-files 2>/dev/null || true)
for file in $tracked; do
  case "$file" in
    personal/*|*/personal/*|private/*|*/private/*)
      allowed "$file" || { warn "protected personal/private path is tracked: $file"; rc=1; } ;;
    .env|.env.*|*/.env|*/.env.*|*.pem|*.key|*.p12|*.pfx|*/id_rsa|*/id_dsa|*/id_ecdsa|*/id_ed25519|*.npmrc|*.pypirc|*.netrc|*credential*.json|*service-account*.json)
      case "$file" in *.sample|*.example|.env.sample|.env.example|*/.env.sample|*/.env.example|*.pub) ;; *)
        warn "sensitive file type is tracked: $file"; rc=1 ;;
      esac ;;
  esac
done

EMAIL='[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
PHONE='\+[0-9]{1,3}[- ().]?[0-9]{2,4}[- ()0-9.]{6,}|0[0-9]{1,4}-[0-9]{1,4}-[0-9]{3,4}'
LABELLED_ID='(ssn|social[ -]?security|national[ -]?id|passport|my[ -]?number|マイナンバー)[^0-9]{0,24}[0-9][0-9 -]{6,17}[0-9]'

files=$(repo_files)
has_pii() {
  local file="$1" code=0
  grep -qEI -e "$EMAIL|$PHONE|$LABELLED_ID" -- "$file" || code=$?
  case "$code" in
    0) return 0 ;;
    1) return 1 ;;
    *) fail "personal-data scan could not read $file (grep exit $code)" ;;
  esac
}
for file in $files; do
  [ -f "$HARNESS_ROOT/$file" ] || continue
  case "$file" in
    .pii-allow|scripts/gates/data-boundary.sh|*/fixtures/*|*/__mocks__/*|*/node_modules/*|*.sample|*.example|*.example.*) continue ;;
  esac
  allowed "$file" && continue
  examined=$((examined + 1))
  if has_pii "$HARNESS_ROOT/$file"; then
    warn "possible structured personal data in $file — value suppressed; pseudonymise or review a path exception"
    rc=1
  fi
done

# An exception that matches nothing is dormant policy: it can silently approve
# a future file nobody reviewed. Exact/glob exceptions expire with their target.
if [ -f "$ALLOW_FILE" ]; then
  while IFS= read -r pattern || [ -n "$pattern" ]; do
    case "$pattern" in ''|'#'*) continue ;; esac
    used=0
    for file in $files; do
      # shellcheck disable=SC2254
      case "$file" in $pattern) used=1; break ;; esac
    done
    [ "$used" -eq 1 ] || { warn "stale personal-data exception matches no file: $pattern"; rc=1; }
  done < "$ALLOW_FILE"
fi

[ "$rc" -eq 0 ] || fail "data boundary failed"
ok "data boundary ($examined file(s); a green pattern scan cannot detect a bare name)"
