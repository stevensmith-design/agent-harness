#!/usr/bin/env bash
# harness-check.sh — is the harness machinery healthy and internally coherent?
# This is a maintainer checkpoint, not an every-task tax. The expensive
# rejection self-test remains an explicit command for changes to checks.

# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
ROOT=$(harness_root "$(dirname "$0")") || exit 1
cd "$ROOT" || exit 1

status=0
for g in scripts/check-budget.sh scripts/gates/*.sh; do
  [ -f "$g" ] || continue
  printf '%s── %s%s\n' "$DIM" "$(basename "$g" .sh)" "$RST"
  if [ -x "$g" ]; then "$g"; else bash "$g"; fi
  [ $? -eq 0 ] || status=1
done

printf '%s── doctor%s\n' "$DIM" "$RST"
bash scripts/doctor.sh || status=1

if [ "$status" -eq 0 ]; then
  pass "harness check" "governance gates + doctor"
else
  fail "harness check failed"
fi
exit "$status"
