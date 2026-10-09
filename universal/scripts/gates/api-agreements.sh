#!/usr/bin/env bash
# Did an agreement move without anyone being told?
#
# The failure this prevents is the one that actually costs a handover: not a
# missing document, but a STALE one. A screen is signed off, the consumer starts
# building, the shape is then amended for a good reason, and nothing anywhere
# marks that the agreement it was building against no longer holds.
#
# What this proves, exactly: for every operation whose x-status at the base
# commit was 'agreed' or 'frozen', its shape is byte-identical to the base — or
# a row naming it has been ADDED to docs/api-proposal/AGREEMENTS.md in the same
# change. Shapes are compared by a canonical hash of the parsed operation with
# the agreement metadata (x-status, x-changed, x-agreed) removed, so bumping a
# status is not itself a change and reformatting the YAML is not either.
#
# What it CANNOT prove: that the consumer was ACTUALLY told. The ledger's last
# column records where that happened so a human can check it in ten seconds.
# Nothing here verifies a message was sent.
. "$(dirname "$0")/../lib.sh"

DIR="$HARNESS_ROOT/docs/api-proposal"
[ -d "$DIR" ] || { ok "api agreements (no proposals yet)"; exit 0; }

MAIN=$(cfg git.main_branch main)

out=$(python3 "$HARNESS_ROOT/scripts/validate-api-proposals.py" \
        --mode drift --root "$HARNESS_ROOT" --main-branch "$MAIN" 2>&1) || {
  printf '%s\n' "$out" >&2
  warn "    Either restore the shape, or record the change: add a row to"
  warn "    docs/api-proposal/AGREEMENTS.md naming the operation, the event"
  warn "    ('revised' or 'reopened'), and where you told the consumer."
  fail "api agreement drift"
}
ok "api agreements — $out"
