#!/usr/bin/env bash
# Portable skill metadata gate: local loaders are looser than upload/install paths.
. "$(dirname "$0")/../lib.sh"
python3 "$HARNESS_ROOT/scripts/validate-skills.py" "$HARNESS_ROOT/.agents/skills" \
  || fail "skill frontmatter is not portable"
ok "skill frontmatter"
