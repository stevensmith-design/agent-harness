#!/usr/bin/env bash
# surface-resolution.sh — is every file in this change in a known lane?
#
# Thin on purpose. The resolver is scripts/resolve-surface.sh and it is the ONE
# reader of the surfaces table; this gate only decides WHICH files to ask about
# (the change set) and lets the resolver answer. Two readers of one config file
# eventually disagree about what a pattern means, and the disagreement shows up
# as a green tick on a file nobody classified.
#
# doctor.sh asks the same resolver about the whole tree. Same code, two
# denominators — which is the only honest way to have both.
#
# Fails on: a malformed surfaces table, or a file matching two surfaces.
# Warns on: files matching none (treated high/owner — that default is the
# surfaces file's stated policy, not this gate's invention).

# shellcheck source=../lib.sh
. "$(dirname "$0")/../lib.sh"
ROOT=$(harness_root "$(dirname "$0")") || exit 1
cd "$ROOT" || exit 1

# Direct invocation, status read directly — never through a pipe. check.sh
# carries the scar of a gate whose status came from `tail`.
# Through bash, not the executable bit — see skills-sync.sh.
bash ./scripts/resolve-surface.sh --changed
exit $?
