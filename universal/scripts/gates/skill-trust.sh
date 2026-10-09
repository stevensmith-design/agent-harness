#!/usr/bin/env bash
# Agent-trust gate: a skill is executable instruction, even when its files are Markdown.
. "$(dirname "$0")/../lib.sh"
python3 "$HARNESS_ROOT/scripts/scan-skill-trust.py" \
  "$HARNESS_ROOT/.agents/skills" "$HARNESS_ROOT/.agents/skill-trust-allow.tsv" \
  || fail "skill trust scan failed"
ok "skill trust"
