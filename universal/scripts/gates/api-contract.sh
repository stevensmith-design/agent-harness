#!/usr/bin/env bash
# Every proposed operation carries a status, and a name the ledger can address.
#
# The failure this prevents: a proposal marked `status: proposed` once at the top
# of the file, while its operations were agreed on five different days. Nothing
# then distinguishes the endpoint the backend has signed off from the one still
# being argued about, so a consumer builds against both as if they were equal.
#
# What this proves: presence and vocabulary — every operation has an x-status
# from the closed set, and a unique operationId.
# What it CANNOT prove: that the status is TRUE. Only the ledger and the
# api-agreements gate say anything about whether a status was earned.
. "$(dirname "$0")/../lib.sh"

DIR="$HARNESS_ROOT/docs/api-proposal"
[ -d "$DIR" ] || { ok "api proposals (none yet)"; exit 0; }

out=$(python3 "$HARNESS_ROOT/scripts/validate-api-proposals.py" \
        --mode status --root "$HARNESS_ROOT" 2>&1) || {
  printf '%s\n' "$out" >&2
  fail "api proposal status"
}
ok "api proposals — $out"
