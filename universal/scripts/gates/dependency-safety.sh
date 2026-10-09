#!/usr/bin/env bash
# Deterministic, reviewable dependency sources. Network vulnerability checks are
# intentionally kept in the intake procedure because they go stale and require I/O.
. "$(dirname "$0")/../lib.sh"

NON_REGISTRY=$(cfg supply_chain.allowed_non_registry_dependencies '[]')
LIFECYCLE=$(cfg supply_chain.allowed_install_scripts '[]')
HOSTS=$(cfg supply_chain.allowed_registry_hosts '[registry.npmjs.org]')

python3 "$HARNESS_ROOT/scripts/check-dependency-safety.py" \
  "$HARNESS_ROOT" "$NON_REGISTRY" "$LIFECYCLE" "$HOSTS" \
  || fail "dependency safety failed"
ok "dependency safety"
