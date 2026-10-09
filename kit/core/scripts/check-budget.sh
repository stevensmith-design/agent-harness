#!/usr/bin/env bash
# check-budget.sh — the always-loaded SET must stay small enough to be read.
#
# The budget covers every file that loads on every task, not just the
# constitution. A per-file budget is gameable and gets gamed by accident:
# content moves from the constitution into a second always-loaded file, the
# check goes green, and the attention cost is exactly what it was.
#
# The set is declared in loading-order.md, which is also where the number
# lives — a budget hardcoded in the script while a doc states a different one
# is two sources of truth, and the doc is the one people read.
#
# Missing file = FAILURE, not a skip. A previous version elsewhere skipped
# absent files, so deleting the constitution removed the line from the output
# and the check passed.

# Usage:
#   bash scripts/check-budget.sh          the gate
#   bash scripts/check-budget.sh --size   print "<lines> <bytes>" for the set and
#                                         exit; retro-evidence.sh reads this, so
#                                         the contract has one parser, not two

SIZE=0; [ "${1:-}" = "--size" ] && SIZE=1

# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
ROOT=$(harness_root "$(dirname "$0")") || exit 1
cd "$ROOT" || exit 1

CONTRACT=loading-order.md
[ -f "$CONTRACT" ] || { fail "$CONTRACT is missing — nothing declares what loads every session"; finish; }

# Budget from the contract, not from this script.
LIMIT=$(sed -n 's/^\*\*Budget:[[:space:]]*\([0-9]\{1,\}\)[[:space:]]*lines\.\*\*.*/\1/p' "$CONTRACT" | head -1)
case "${LIMIT:-}" in
  ''|*[!0-9]*) fail "$CONTRACT does not declare a numeric budget (expected a line like '**Budget: 60 lines.**')"; finish ;;
esac

# ONLY the "## Always loaded" section. Counting the whole file would also count
# an on-demand set documented beside it, and fail falsely. Sectioning is the fix.
FILES=$(awk '
  /^##[[:space:]]+Always loaded[[:space:]]*$/ { inside=1; next }
  /^##[[:space:]]/                            { inside=0 }
  inside && /^[[:space:]]*[-*][[:space:]]/    { print }
' "$CONTRACT" | sed -E 's/^[[:space:]]*[-*][[:space:]]*`?([^`[:space:]]+)`?.*/\1/')

# Rules only: skip blanks, HTML comments and headings. One definition, used by
# both modes, so the size a retro records is the size the gate enforces.
count_rules() {
  grep -ve '^[[:space:]]*$' -- "$1" \
    | grep -ve '^[[:space:]]*<!--' -- \
    | grep -ve '^[[:space:]]*#' -- \
    | wc -l | tr -d ' '
}

if [ "$SIZE" -eq 1 ]; then
  l=0; b=0
  for f in $FILES; do
    [ -f "$f" ] || { printf 'always-loaded file missing: %s\n' "$f" >&2; exit 1; }
    n=$(count_rules "$f")
    c=$(wc -c < "$f" | tr -d ' ')
    l=$((l + n)); b=$((b + c))
  done
  printf '%s %s\n' "$l" "$b"
  exit 0
fi

n_files=0; total=0; missing=0
for f in $FILES; do
  n_files=$((n_files + 1))
  if [ ! -f "$f" ]; then
    fail "$CONTRACT declares '$f' as always-loaded, and it does not exist"
    missing=$((missing + 1))
    continue
  fi
  n=$(count_rules "$f")
  total=$((total + n))
  printf '%s    %-28s %4s lines%s\n' "$DIM" "$f" "$n" "$RST"
done

[ "$n_files" -eq 0 ] && { fail "$CONTRACT declares no always-loaded files"; finish; }

if [ "$total" -gt "$LIMIT" ]; then
  fail "always-loaded set is $total lines against a budget of $LIMIT."
  fail "  Move detail into an on-demand file. Do not raise the budget — the budget is the forcing function."
elif [ "$missing" -eq 0 ]; then
  pass "always-loaded set within budget" "$total/$LIMIT lines across $n_files file(s)"
fi
finish
