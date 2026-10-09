#!/usr/bin/env bash
# check.sh — does this WORK comply with the harness?
#
# Runs each gate as a direct child and reads ITS exit status. Do not pipe a
# gate through anything: `gate | tail` reports tail's status, and a check.sh
# built that way printed "check passed" unconditionally — while being the first
# checkbox on the PR template.

# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
ROOT=$(harness_root "$(dirname "$0")") || exit 1
cd "$ROOT" || exit 1

rm -f runs/.state/stubs 2>/dev/null

status=0
n_gates=0

# check-budget lives outside gates/ because the retro and the docs address it
# by name. It still has to RUN — the constitution's budget was enforced only
# when someone remembered.
for g in scripts/check-budget.sh scripts/gates/*.sh; do
  [ -f "$g" ] || continue
  n_gates=$((n_gates + 1))
  printf '%s── %s%s\n' "$DIM" "$(basename "$g" .sh)" "$RST"
  if [ -x "$g" ]; then
    "$g"            # direct invocation; status is the gate's own
  else
    bash "$g"
  fi
  rc=$?
  [ $rc -eq 0 ] || status=1
done

printf '\n'
if [ "$n_gates" -eq 0 ]; then
  printf '%s✗ no gates ran. An empty check is not a passing check.%s\n' "$RED" "$RST" >&2
  exit 1
fi
if [ $status -eq 0 ]; then
  printf '%s✓ check passed%s %s(%s gates)%s\n' "$GRN" "$RST" "$DIM" "$n_gates" "$RST"
else
  printf '%s✗ check failed%s %s(%s gates ran)%s\n' "$RED" "$RST" "$DIM" "$n_gates" "$RST" >&2
fi
exit $status
