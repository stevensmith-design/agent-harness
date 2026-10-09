#!/usr/bin/env bash
# Dispatch a harness verb to the configured stack adapter.
#   scripts/run.sh <verb> [args...]
. "$(dirname "$0")/lib.sh"
load_adapter
[ $# -ge 1 ] || fail "usage: run.sh <verb>"
run_verb "$@"
# A stub is not a passing check. Locally this says so; in CI it fails the build.
stub_summary
