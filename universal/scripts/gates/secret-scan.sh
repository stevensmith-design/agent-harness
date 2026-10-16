#!/usr/bin/env bash
# Secret gate. Catches the common shapes before they reach a commit.
# Not a replacement for a real scanner (gitleaks/trufflehog) — it is the cheap
# rung that runs on every `make check`.
. "$(dirname "$0")/../lib.sh"

PATTERNS=(
  'AKIA[0-9A-Z]{16}'                              # AWS access key id
  'ghp_[A-Za-z0-9]{36}'                           # GitHub PAT
  'github_pat_[A-Za-z0-9_]{22,}'
  'sk-[A-Za-z0-9]{32,}'                           # generic provider key
  'xox[baprs]-[A-Za-z0-9-]{10,}'                  # Slack
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'
)
# Case-insensitive by design: the canonical real-world shapes are UPPERCASE env
# keys (API_KEY=, DB_PASSWORD=, SECRET_TOKEN=) and the case-sensitive version of
# this pattern matched none of them.
IPATTERNS=(
  '(password|passwd|secret|token|api_?key)[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"'$<{][^"'"'"']{7,}["'"'"']'
)
# Anchored to whole path segments / real suffixes. Unanchored substrings meant
# `src/config.lockfile.ts` and `src/x.example.config.ts` excluded themselves —
# a one-rename bypass for anything that wanted a red gate to go green.
ALLOW='(^|/)\.env\.sample$|(^|/)(fixtures?|__mocks__|node_modules)(/|$)|\.example$|\.lock$|^scripts/gates/secret-scan\.sh$|^\.secret-allow$'

# Full checks scan the working tree, including untracked work. The pre-commit
# hook scans only staged blobs: rescanning a large repository on every commit
# made the safety check slow enough to invite bypassing it, and reading the
# working copy could miss a secret staged in the index then edited away locally.
MODE=${1:-}
case "$MODE" in
  '') tracked=$(repo_files) ;;
  --staged) tracked=$(git -C "$HARNESS_ROOT" diff --cached --name-only --diff-filter=ACMR) ;;
  *) fail "usage: secret-scan.sh [--staged]" ;;
esac
[ -n "$tracked" ] || { ok "secret scan (no files)"; exit 0; }
files=$(printf '%s\n' "$tracked" | sgrep -Ev -e "$ALLOW" --)
[ -n "$files" ] || { ok "secret scan (everything excluded)"; exit 0; }

found=0
# Reviewed false positives:
#   <path><TAB><fixed substring of the line><TAB><family>
# `family` is `assignment` (the backward-compatible default) or `literal`.
# Keeping the family in the grant means allowing a fake password cannot also
# hide an AWS-shaped key that happens to be written on the same line.
SECRET_ALLOW="$HARNESS_ROOT/.secret-allow"
SECRET_USED=$(mktemp) || fail "cannot create a temp file"
trap 'rm -f "$SECRET_USED"' EXIT
suppress() { # suppress <family>; stdin: path:line:text hits
  local kind="$1"
  [ -f "$SECRET_ALLOW" ] || { cat; return 0; }
  local hit path text ap sub family hidden
  while IFS= read -r hit; do
    path=${hit%%:*}; text=${hit#*:}; text=${text#*:}; hidden=0
    while IFS=$'\t' read -r ap sub family || [ -n "$ap" ]; do
      case "$ap" in ''|'#'*) continue ;; esac
      family=${family:-assignment}
      [ "$ap" = "$path" ] && [ -n "$sub" ] || continue
      [ "$family" = "$kind" ] || continue
      case "$text" in *"$sub"*) hidden=1; printf '%s\t%s\t%s\n' "$ap" "$sub" "$family" >> "$SECRET_USED"; break ;; esac
    done < "$SECRET_ALLOW"
    [ "$hidden" = 1 ] || printf '%s\n' "$hit"
  done
}
scan() { # scan <family> <extra-grep-flag> <pattern>
  local kind="$1" flag="$2" p="$3" hits f
  local scan_files=()
  if [ "$MODE" = "--staged" ]; then
    hits=$(printf '%s\n' "$files" | while IFS= read -r f; do
      git -C "$HARNESS_ROOT" show ":$f" 2>/dev/null \
        | sgrep -nEI $flag -e "$p" -- \
        | cut -c1-160 | sed "s|^|$f:|"
    done | suppress "$kind")
  else
    while IFS= read -r f; do
      # Tracked but not on disk (deleted, unstaged, or a broken symlink).
      [ -f "$HARNESS_ROOT/$f" ] || { skipped "$f (tracked, not on disk)"; continue; }
      scan_files+=("$f")
    done <<< "$files"
    [ "${#scan_files[@]}" -gt 0 ] || return 0
    # One grep process per bounded batch, not one per file per pattern. The
    # bound avoids the shell's argument-length limit on genuinely large repos.
    # On the first production install this changed a minutes-long scan into a
    # normal gate.
    hits=$({
      cd "$HARNESS_ROOT"
      local chunk=()
      for f in "${scan_files[@]}"; do
        chunk+=("$f")
        if [ "${#chunk[@]}" -eq 200 ]; then
          sgrep -nEHI $flag -e "$p" -- "${chunk[@]}"
          chunk=()
        fi
      done
      [ "${#chunk[@]}" -eq 0 ] || sgrep -nEHI $flag -e "$p" -- "${chunk[@]}"
    } | cut -c1-160 | suppress "$kind")
  fi
  if [ -n "$hits" ]; then warn "possible secret:"; printf '%s\n' "$hits" | sed 's/^/    /'; found=1; fi
}
for p in "${PATTERNS[@]}";  do scan literal "" "$p"; done
for p in "${IPATTERNS[@]}"; do scan assignment "-i" "$p"; done
blind_spots

if [ -f "$SECRET_ALLOW" ] && [ "$MODE" != "--staged" ]; then
  while IFS=$'\t' read -r ap sub family || [ -n "$ap" ]; do
    case "$ap" in ''|'#'*) continue ;; esac
    family=${family:-assignment}
    case "$family" in assignment|literal) ;; *) warn "invalid secret exception family '$family': $ap"; found=1; continue ;; esac
    entry=$(printf '%s\t%s\t%s' "$ap" "$sub" "$family")
    grep -qxF -e "$entry" -- "$SECRET_USED" \
      || { warn "stale secret exception suppresses nothing: $ap${sub:+	$sub} [$family]"; found=1; }
  done < "$SECRET_ALLOW"
fi

# .env must never be tracked.
if git -C "$HARNESS_ROOT" ls-files --error-unmatch .env >/dev/null 2>&1; then
  warn ".env is tracked by git — remove it and rotate anything it held"; found=1
fi

[ "$found" -eq 0 ] || fail "secret scan failed"
ok "secret scan"
