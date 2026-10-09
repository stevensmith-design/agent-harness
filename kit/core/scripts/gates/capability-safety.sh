#!/usr/bin/env bash
# External capability skills are quarantined, portable, instruction-scanned,
# licensed, provenance-recorded and content-pinned before a runtime can see them.
# shellcheck source=../lib.sh
. "$(dirname "$0")/../lib.sh"
ROOT=$(harness_root "$(dirname "$0")") || exit 1
cd "$ROOT" || exit 1

python3 scripts/validate-skills.py capabilities || fail "capability skill frontmatter is not portable"
python3 scripts/scan-skill-trust.py capabilities config/skill-trust-allow.tsv \
  || fail "capability skill contains an unsafe instruction shape"
python3 scripts/verify-capabilities.py capabilities capabilities-lock.json \
  || fail "capability provenance or content pin failed"
pass "capability skills are reviewed and pinned" "$(find capabilities -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ') skill(s)"
finish
