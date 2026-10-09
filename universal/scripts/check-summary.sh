#!/usr/bin/env bash
# The last line of `make check`.
#
# "✓ all deterministic gates passed" was printed unconditionally — including on
# the shipped adapter, where lint, format-check and test are TODO stubs that exit
# 0. The harness's headline non-negotiable is "run `make check` before claiming
# anything works; 'it should work' is not evidence." A green line over four stubs
# is exactly the claim that rule forbids.
. "$(dirname "$0")/lib.sh"
load_adapter

# Read what actually happened this run. Static-analysing the adapter for the
# word `todo` was wrong the moment a verb gained a real branch AND a fallback:
# `cmd_test` that runs the tests when package.json defines them, and stubs when
# it does not, is not a stub — unless it stubbed on THIS run.
stubs=""
[ -f "$STUB_MARK" ] && stubs=$(cat "$STUB_MARK")

absent=""
for v in lint format_check typecheck test; do
  declare -f "cmd_$v" >/dev/null 2>&1 || absent="$absent $v"
done

# Record that check ran, at this commit. `.agents/runs/` is the harness's only
# durable statement that work was actually verified, and until now only
# `make verify` wrote to it — so the rule "evidence exists" was enforced by a
# local Stop hook and by nothing a CI job could not skip.
# scripts/gates/evidence.sh is what reads this.
emit() {
  "$HARNESS_ROOT/scripts/emit-evidence.sh" check "${HARNESS_ACTOR:-runner:local}" "$1" "$2" >/dev/null 2>&1 || true
}

if [ -z "$stubs" ]; then
  emit pass "make check${absent:+ (adapter verbs absent:$absent)}"
  if [ -z "$absent" ]; then ok "all deterministic gates passed"; exit 0; fi
  ok "harness gates passed"
  info "adapter '$ADAPTER_NAME' does not define:$absent (fine if your stack has no such step)"
  exit 0
fi

# Stubbed verbs ran: the harness gates passed, the code was not checked. That is
# NOT VERIFIED — recorded as such, so nothing downstream can read it as a pass.
emit not_verified "make check — stubbed verbs: $(printf '%s' "$stubs" | tr '\n' ' ')"
ok "harness gates passed"
[ -n "$absent" ] && info "adapter '$ADAPTER_NAME' does not define:$absent (fine if your stack has no such step)"
warn "but this run did not actually check your code:"
printf '%s\n' "$stubs" | sed 's/^/    /' >&2
warn "  Fill these in in scripts/adapters/$ADAPTER_NAME.sh before you trust a green run."
not_verified "make check ran over unimplemented adapter verbs. Work can continue; it cannot be called done"
