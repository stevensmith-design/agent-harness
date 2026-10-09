#!/usr/bin/env bash
# data-boundary.sh — what may never be committed.
#
# Three rules, one gate:
#   1. Nothing under a personal/private path or secret-bearing filename is tracked.
#   2. No secret material in tracked files.
#   3. No structured personal data in tracked files.
#
# Rule 1 is the reliable one and does most of the work: it is structural, so it
# cannot be fooled by formatting. Rules 2 and 3 are pattern matches and are
# genuinely weaker — which this gate says out loud every time it passes, because
# the dangerous outcome is not a miss, it is a green tick someone trusted.
#
#   A green scan is NOT evidence a file is clean. It catches structured data —
#   addresses, numbers, key material. It cannot catch a bare name, and it never
#   will. Read the file.
#
# Codify BEFORE the first commit: history is not removable without a
# force-push, and by then other people have cloned it.
#
# Allow real, reviewed exceptions in .pii-allow (one path glob per line). Every
# line there is a decision someone made; treat its growth as a signal.

# shellcheck source=../lib.sh
. "$(dirname "$0")/../lib.sh"
ROOT=$(harness_root "$(dirname "$0")") || exit 1
cd "$ROOT" || exit 1
IFS=$(printf '\n\b'); IFS=${IFS%?}

# Only TRACKED files matter — an untracked file has not left the machine.
if git rev-parse --git-dir >/dev/null 2>&1; then
  FILES=$(git ls-files 2>/dev/null)
  SCOPE="tracked"
else
  FILES=$(find . -type f -not -path '*/.git/*' -not -path './runs/*' -not -name '.DS_Store' 2>/dev/null | sed 's|^\./||')
  SCOPE="all files (no git — nothing distinguishes committed from local)"
fi

allowed() {
  [ -f .pii-allow ] || return 1
  while IFS= read -r pat || [ -n "$pat" ]; do
    case "$pat" in ''|\#*) continue ;; esac
    # shellcheck disable=SC2254
    case "$1" in $pat) return 0 ;; esac
  done < .pii-allow
  return 1
}

# ── 1. Structural: protected paths and sensitive files are never tracked ────
n_files=0; n_zone=0
for f in $FILES; do
  n_files=$((n_files + 1))
  case "$f" in
    */personal/*|personal/*|*/private/*|private/*)
      allowed "$f" && continue
      if [ "$SCOPE" = "tracked" ]; then
        fail "committed under a protected path: $f"
        fail "  personal/ and private/ never enter history. Move it, or add a reviewed line to .pii-allow."
      else
        # No git: anything in this folder is as shared as the folder is. In a
        # shared drive that means everyone with access can already read it.
        fail "stored under a protected path in the harness folder: $f"
        fail "  personal/ and private/ never live in a shared harness. Move it out of this folder, or add a reviewed line to .pii-allow if this folder is yours alone."
      fi
      n_zone=$((n_zone + 1)) ;;
    .env|.env.*|*/.env|*/.env.*|*.pem|*.key|*.p12|*.pfx|*/id_rsa|*/id_dsa|*/id_ecdsa|*/id_ed25519|*.npmrc|*.pypirc|*.netrc|*credential*.json|*service-account*.json)
      case "$f" in *.sample|*.example|.env.sample|.env.example|*/.env.sample|*/.env.example|*.pub) continue ;; esac
      allowed "$f" && continue
      fail "sensitive file type is in the shared/tracked set: $f"
      fail "  Keep secret-bearing files outside the harness; samples contain names and placeholders only."
      n_zone=$((n_zone + 1)) ;;
  esac
done
[ "$n_zone" -eq 0 ] && pass "no protected personal/private paths or sensitive files" "$n_files $SCOPE"

# ── 2. Secret material ───────────────────────────────────────────────────────
SECRETS='-----BEGIN [A-Z ]*PRIVATE KEY-----|AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9]{32,}|ghp_[A-Za-z0-9]{36}|xox[baprs]-[A-Za-z0-9-]{10,}|(api[_-]?key|secret|password|token)[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"'[:space:]]{12,}["'"'"']'
n_sec=0
for f in $FILES; do
  [ -f "$f" ] || continue
  case "$f" in *.sample|*.example|*.example.*|.pii-allow|*/gates/data-boundary.sh) continue ;; esac
  allowed "$f" && continue
  if grep -Eqe "$SECRETS" -- "$f" 2>/dev/null; then
    fail "possible secret material in $f — read the name, never the value"
    n_sec=$((n_sec + 1))
  fi
done
[ "$n_sec" -eq 0 ] && pass "no secret material found" "$n_files $SCOPE"

# ── 3. Structured personal data ──────────────────────────────────────────────
# Deliberately narrow. A wide pattern that fires on prose gets the gate
# disabled, and a disabled gate is worse than no gate.
PII='[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}|\+[0-9]{1,3}[- ().]?[0-9]{2,4}[- ()0-9.]{6,}|0[0-9]{1,4}-[0-9]{1,4}-[0-9]{3,4}|(ssn|social[ -]?security|national[ -]?id|passport|my[ -]?number|マイナンバー)[^0-9]{0,24}[0-9][0-9 -]{6,17}[0-9]'
n_pii=0
for f in $FILES; do
  [ -f "$f" ] || continue
  case "$f" in *.sample|*.example|*.example.*|.pii-allow|*/gates/data-boundary.sh) continue ;; esac
  allowed "$f" && continue
  if grep -Eqe "$PII" -- "$f" 2>/dev/null; then
    fail "structured personal data in $f (address or number) — pseudonymise, or add a reviewed .pii-allow line"
    n_pii=$((n_pii + 1))
  fi
done
[ "$n_pii" -eq 0 ] && pass "no structured personal data found" "$n_files $SCOPE"

# An exception for no current file is dormant authority. If that path is later
# recreated, it would bypass the boundary without a fresh review.
if [ -f .pii-allow ]; then
  while IFS= read -r pat || [ -n "$pat" ]; do
    case "$pat" in ''|'#'*) continue ;; esac
    used=0
    for f in $FILES; do
      # shellcheck disable=SC2254
      case "$f" in $pat) used=1; break ;; esac
    done
    [ "$used" -eq 1 ] || fail "stale .pii-allow exception matches no current file: $pat"
  done < .pii-allow
fi

printf '%s  A green scan is not evidence a file is clean: it catches structured data\n' "$DIM"
printf '  and key material, and cannot catch a bare name. Read the file.%s\n' "$RST"
finish
