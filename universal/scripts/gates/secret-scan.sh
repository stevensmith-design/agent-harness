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
ALLOW='(^|/)\.env\.sample$|(^|/)(fixtures?|__mocks__|node_modules)(/|$)|\.example$|\.lock$|^scripts/gates/secret-scan\.sh$'

# The working tree, not just the index. Scanning `git ls-files` alone meant a
# fresh `git init` reported clean with a live key on disk, and an established
# repo never scanned the file that had just been written.
tracked=$(repo_files)
[ -n "$tracked" ] || { ok "secret scan (no files)"; exit 0; }
files=$(printf '%s\n' "$tracked" | sgrep -Ev -e "$ALLOW" --)
[ -n "$files" ] || { ok "secret scan (everything excluded)"; exit 0; }

found=0
scan() { # scan <extra-grep-flag> <pattern>
  local flag="$1" p="$2" hits
  hits=$(printf '%s\n' "$files" | while IFS= read -r f; do
    # Tracked but not on disk (deleted, unstaged, or a broken symlink). Not an
    # error, but this file was in scope and was not scanned — say so.
    [ -f "$HARNESS_ROOT/$f" ] || { skipped "$f (tracked, not on disk)"; continue; }
    sgrep -nEI $flag -e "$p" -- "$HARNESS_ROOT/$f" | cut -c1-160 | sed "s|^|$f:|"
  done)
  if [ -n "$hits" ]; then warn "possible secret:"; printf '%s\n' "$hits" | sed 's/^/    /'; found=1; fi
}
for p in "${PATTERNS[@]}";  do scan "" "$p"; done
for p in "${IPATTERNS[@]}"; do scan "-i" "$p"; done
blind_spots

# .env must never be tracked.
if git -C "$HARNESS_ROOT" ls-files --error-unmatch .env >/dev/null 2>&1; then
  warn ".env is tracked by git — remove it and rotate anything it held"; found=1
fi

[ "$found" -eq 0 ] || fail "secret scan failed"
ok "secret scan"
