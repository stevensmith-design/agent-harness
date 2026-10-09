#!/usr/bin/env bash
# Design-system coherence gate.
#
# The design-tokens gate greps for raw hex and magic numbers — per-file rules a
# regex can see. This one checks the relationships BETWEEN tokens, which no
# per-file rule can: contrast pairs, semantic-colour distinctness, neutral-ramp
# derivation, type-scale ratios, elevation monotonicity.
#
# It exists because the harness had the enforcement and not the thing enforced:
# `design.tokens_path` was set by harness-init without checking anything was
# there, the rule said "use tokens from that path", and no skill created a token
# layer. The `ui-design-system` skill now creates it and this gate checks it.
# One validator, at scripts/validate-tokens.py, shared by both.
. "$(dirname "$0")/../lib.sh"

[ "$(cfg design.enabled true)" = "true" ] || { ok "design system gate disabled"; exit 0; }

VALIDATOR="$HARNESS_ROOT/scripts/validate-tokens.py"
[ -f "$VALIDATOR" ] || fail "scripts/validate-tokens.py is missing — the design skills and this gate both need it.
    This is a broken harness, not a project problem. Restore the file."

command -v python3 >/dev/null 2>&1 || fail "python3 is required for the design-system gate — install it, or set design.enabled: false"

# Find the token file. Explicit config wins; otherwise look where a design system
# normally puts it.
TOKENS="$(cfg design.tokens_file '')"
if [ -z "$TOKENS" ]; then
  for c in tokens.json "$(cfg design.tokens_path src/theme)/tokens.json" design/tokens.json src/tokens.json; do
    [ -f "$HARNESS_ROOT/$c" ] && { TOKENS="$c"; break; }
  done
fi

REQUIRE=$(cfg design.require_tokens false)
if [ -z "$TOKENS" ] || [ ! -f "$HARNESS_ROOT/$TOKENS" ]; then
  if [ "$REQUIRE" = "true" ]; then
    fail "no tokens.json found and design.require_tokens is true.
    Run the ui-design-system skill (Create mode) to establish DESIGN.md + tokens.json,
    or set design.tokens_file to point at yours."
  fi
  info "no tokens.json yet — run the 'ui-design-system' skill to create one"
  info "  (set design.require_tokens: true once it exists, to gate on it)"
  ok "design system (no token file to check)"
  exit 0
fi

DESIGN_MD=""
for c in DESIGN.md docs/DESIGN.md design/DESIGN.md; do
  [ -f "$HARNESS_ROOT/$c" ] && { DESIGN_MD="$c"; break; }
done

args=(--tokens "$HARNESS_ROOT/$TOKENS")
[ -n "$DESIGN_MD" ] && args+=(--design "$HARNESS_ROOT/$DESIGN_MD")
[ "$(cfg design.strict_tokens true)" = "true" ] && args+=(--strict)

out=$(python3 "$VALIDATOR" "${args[@]}" 2>&1) && rc=0 || rc=$?
printf '%s\n' "$out" | sed 's/^/    /'
if [ "$rc" -ne 0 ]; then
  warn "token graph does not cohere ($TOKENS)"
  warn "    A broken relationship in the tokens propagates into every screen built on them."
  warn "    Fix it before building components — see .agents/skills/ui-design-system/references/validator-checks.md"
  fail "design system gate"
fi
ok "design system ($TOKENS coheres)"
