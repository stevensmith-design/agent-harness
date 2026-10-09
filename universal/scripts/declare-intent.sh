#!/usr/bin/env bash
# Record a branch-bound, reasoned intent to do something the harness otherwise
# refuses — edit the harness itself, or land a change on a high-risk surface.
#
#   ./scripts/declare-intent.sh harness-edit  "policy.sh mis-ranks L4 as L3"
#   ./scripts/declare-intent.sh high-risk     "reviewed by SS in PR 412"
#   ./scripts/declare-intent.sh --clear
#
# This replaces HARNESS_ALLOW_SELF_EDIT=1 and HARNESS_HUMAN_APPROVED=1. Those
# were booleans: exported once, they authorised every subsequent change in the
# session, including the ones nobody looked at. A declaration expires the moment
# you switch branches, and says what it was for.
#
# WHAT THIS DOES NOT DO — read this before calling it an approval.
#
# It proves a DECLARATION WAS MADE. It does not prove a human made it. Any agent
# that can run repository scripts can author one, including this one, including
# the agent whose change the declaration is authorising. There is no identity
# here to check and no signature to verify.
#
# So every record it writes is stamped `trust=self_reported`, the weakest rung
# of the evidence vocabulary in .harness/schemas/shared-definitions.schema.json,
# and .harness/scripts/validate_governance.py refuses to let a self_reported
# record back an approvalClass=human approval.
#
# That is still a real improvement on the booleans it replaced — it is bound to
# one branch, it carries a reason, and it expires. It is a good audit trail. It
# is not authentication, and nothing downstream may describe it as one. If you
# need an approval a person actually gave, route it through a channel that
# issues identity: a GitHub required review, or a protected environment.
. "$(dirname "$0")/lib.sh"

SCOPES="harness-edit high-risk"

usage() {
  cat >&2 <<USAGE
usage: declare-intent.sh <scope> "<reason>"
       declare-intent.sh --clear
       declare-intent.sh --show

  scope    one of: $SCOPES
  reason   a sentence saying why, >= 12 characters. "fix" is not a reason;
           the next person reading this file is the one it is written for.
USAGE
  exit 1
}

case "${1:-}" in
  --clear) rm -f "$INTENT_FILE"; ok "intent cleared"; exit 0 ;;
  --show)
    [ -f "$INTENT_FILE" ] || { info "no intent declared"; exit 0; }
    cat "$INTENT_FILE"; exit 0 ;;
  ""|-h|--help) usage ;;
esac

scope="$1"; reason="${2:-}"
case " $SCOPES " in *" $scope "*) : ;; *) fail "unknown scope '$scope' — use one of: $SCOPES" ;; esac
[ "${#reason}" -ge 12 ] || fail "reason is ${#reason} characters. A declaration nobody can read is a boolean with extra steps — write a sentence."

branch=$(git -C "$HARNESS_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || printf '')
[ -n "$branch" ] || fail "not in a git worktree — an intent that cannot be bound to a branch cannot expire, and an intent that never expires is the boolean this replaces."
[ "$branch" != "$(cfg git.main_branch main)" ] || fail "refusing to declare intent on '$branch'. Branch first: this is the one place where 'just this once' becomes permanent."

{
  printf 'scope=%s\n'  "$scope"
  printf 'branch=%s\n' "$branch"
  printf 'reason=%s\n' "$reason"
  printf 'actor=%s\n'  "$(git -C "$HARNESS_ROOT" config user.email 2>/dev/null || printf 'unknown')"
  # The actor line above is git's configured email. It is a setting, not an
  # identity: whoever runs this controls it. Hence the line below.
  printf 'trust=self_reported\n'
} > "$INTENT_FILE"

ok "intent '$scope' declared on '$branch'  (trust: self_reported)"
info "  $reason"
info "  It stops applying the moment you leave this branch. ./scripts/declare-intent.sh --clear to end it now."
