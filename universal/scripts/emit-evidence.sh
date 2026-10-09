#!/usr/bin/env bash
# Append one evidence line to .agents/runs/<run-id>.jsonl.
#
# These are HARNESS-OPERATION records — who ran which gate, on what commit, with
# what result. They are deliberately NOT OpenTelemetry GenAI telemetry, and an
# earlier version of this comment claimed they were: it said the field names
# followed the `gen_ai.*` semantic conventions so real tracing would be "a
# mapping, not a rewrite". No field here is `gen_ai.*`, the string appeared
# nowhere else in the repo, and nobody had worked out what that mapping would be.
# A claim about future work is still a claim.
#
# What is actually true: this is a flat JSONL record with stable field names. To
# ship it to a collector you would write an exporter that maps
#   operation -> a span name        actor.id -> an attribute
#   result    -> a span status      run.id   -> a trace id
# and OTel GenAI conventions would only apply to the subset of operations that
# are genuinely model calls (`execute_tool` and any future `chat`), which would
# need the fields those conventions require — gen_ai.system, gen_ai.request.model,
# gen_ai.usage.input_tokens, gen_ai.usage.output_tokens — none of which this
# script has access to. Nothing emits them today, so nothing pretends to.
#
#   scripts/emit-evidence.sh <operation> <actor> <result> [detail]
#     operation: check | verify | review | approval | closure | execute_tool
#     actor:     an id — "agent:claude", "human:steven", "runner:ci"
#     result:    pass | fail | not_verified | blocked
#                not_verified = the check could not run, or ran over a stub. It
#                lets work continue and never counts as done (lib.sh strict()).
#
# Every record also carries `trust`, which says what the record is WORTH as
# opposed to who it names. The two are not the same question, and conflating
# them is how "an agent ran a script" became "a human approved this".
#
# This script can honestly emit exactly two values:
#
#   deterministic_runner  the actor is a runner: AND we are in CI — a program
#                         with a fixed output produced this, and the run repeats
#   self_reported         everything else, INCLUDING a "human:" actor id
#
# A `human:` id is self_reported because nothing here authenticates it: the
# caller supplies the string. Any agent that can run this script can pass
# `human:steven`.
#
# The other three values — independent_reviewer, authenticated_human,
# external_policy — cannot be produced by this script AT ALL, and there is
# deliberately no flag or environment variable to force one. They require a
# channel that issues identity (a GitHub required review, a protected
# environment, an external authority), and this harness reads no such channel
# today. An override would be a one-command way to mint the strongest claim in
# the vocabulary from the weakest position, which is the escape hatch this
# whole change exists to close.
. "$(dirname "$0")/lib.sh"

op="${1:?operation}"; actor="${2:?actor}"; result="${3:?result}"; detail="${4:-}"

case "$result" in
  pass|fail|not_verified|blocked) ;;
  *) fail "unknown result '$result' — use pass, fail, not_verified or blocked" ;;
esac
# `make check` over stub adapter verbs proved nothing about the code, so nobody
# may record it as passing — not check-summary.sh, not a workflow step, not an
# agent. (Scoped to make-check claims: a migration's own check is a different one.)
if [ "$op" = check ] && [ "$result" = pass ] && [ "${detail#make check}" != "$detail" ] && stubbed; then
  fail "refusing to record 'check pass': this run used stub adapter verbs ($(tr '\n' ' ' < "$STUB_MARK")). Record not_verified."
fi

case "$actor" in
  runner:*) [ -n "${CI:-}" ] && trust=deterministic_runner || trust=self_reported ;;
  *)        trust=self_reported ;;
esac
run_id="${HARNESS_RUN_ID:-$(git -C "$HARNESS_ROOT" rev-parse --short HEAD 2>/dev/null || echo local)-$$}"
out="$HARNESS_ROOT/.agents/runs/$run_id.jsonl"
mkdir -p "$(dirname "$out")"

esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr -d '\n'; }

printf '{"run.id":"%s","operation":"%s","actor.id":"%s","trust":"%s","result":"%s","detail":"%s","branch":"%s","commit":"%s","timestamp":"%s"}\n' \
  "$(esc "$run_id")" "$(esc "$op")" "$(esc "$actor")" "$(esc "$trust")" "$(esc "$result")" "$(esc "$detail")" \
  "$(git -C "$HARNESS_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo -)" \
  "$(git -C "$HARNESS_ROOT" rev-parse HEAD 2>/dev/null || echo -)" \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$out"

echo "$out"
