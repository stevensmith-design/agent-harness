#!/usr/bin/env bash
# `make verify` — prove the app actually runs, then record that as evidence.
#
# The evidence record is the whole point, so the one thing this must never do is
# write `result: pass` for a verb that did not run. It used to: the shipped
# adapter's verify was a TODO stub that exited 0, so a fresh install's first act
# was to manufacture a passing evidence record for an app nobody had started.
HARNESS_STUB_MARK="${TMPDIR:-/tmp}/harness-verify-stub.$$"; export HARNESS_STUB_MARK
. "$(dirname "$0")/lib.sh"
load_adapter
trap 'rm -f "$STUB_MARK"' EXIT

run_verb verify

if stubbed; then
  warn "adapter '$ADAPTER_NAME' has no real 'verify' — it is still a TODO stub."
  warn "  No evidence recorded. Evidence for a check that did not run is worse"
  warn "  than no evidence: it is a false record that a reviewer will trust."
  warn "  Implement cmd_verify() in scripts/adapters/$ADAPTER_NAME.sh — start the"
  warn "  app, hit one real path, assert on the result. See .agents/skills/harness-verify."
  fail "make verify: nothing was verified"
fi

"$HARNESS_ROOT/scripts/emit-evidence.sh" verify "${HARNESS_ACTOR:-runner:local}" pass "make verify"
