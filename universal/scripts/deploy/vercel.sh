#!/usr/bin/env bash
# vercel — Vercel does not ship an official GitHub Action; the CLI is the
# supported path. pull -> build -> deploy --prebuilt.
#
# Required: VERCEL_TOKEN, VERCEL_ORG_ID, VERCEL_PROJECT_ID.
# Vercel's OIDC is OUTBOUND only (it lets your deployment authenticate to a
# cloud), so there is no keyless path INTO Vercel. VERCEL_TOKEN is a long-lived
# credential and belongs in a protected environment secret, never a repo secret.

_v() { npx --yes vercel@latest "$@"; }
_env_flag() { [ "$DEPLOY_ENV" = "production" ] && echo "production" || echo "preview"; }

deploy_plan() {
  need_env VERCEL_TOKEN VERCEL_ORG_ID VERCEL_PROJECT_ID
  info "would deploy $(build_ref) to vercel [$DEPLOY_ENV]"
  _v pull --yes --environment="$(_env_flag)" --token="$VERCEL_TOKEN"
  ok "project settings pulled; build inputs resolved"
}

deploy_apply() {
  require_confirm
  need_env VERCEL_TOKEN VERCEL_ORG_ID VERCEL_PROJECT_ID
  _v pull --yes --environment="$(_env_flag)" --token="$VERCEL_TOKEN"
  # NOTE: --prebuilt omits Vercel's System Environment Variables at build time.
  # If the framework needs them during build, drop --prebuilt here and accept
  # the slower remote build.
  if [ "$DEPLOY_ENV" = "production" ]; then
    _v build --prod --token="$VERCEL_TOKEN"
    # --skip-domain deploys production WITHOUT cutting traffic over, so a human
    # can verify before promote. This is the gate, not a formality.
    _v deploy --prebuilt --prod --skip-domain --token="$VERCEL_TOKEN" | tee /tmp/vercel-url
  else
    _v build --token="$VERCEL_TOKEN"
    _v deploy --prebuilt --token="$VERCEL_TOKEN" | tee /tmp/vercel-url
  fi
  ok "deployed: $(tail -1 /tmp/vercel-url)"
}

deploy_promote() {
  require_confirm
  need_env VERCEL_TOKEN
  local url="${1:-$(tail -1 /tmp/vercel-url 2>/dev/null)}"
  [ -n "$url" ] || fail "no deployment url to promote — pass one, or run deploy_apply first"
  _v promote "$url" --token="$VERCEL_TOKEN"
  ok "promoted $url to production traffic"
}

deploy_rollback() {
  need_env VERCEL_TOKEN
  _v rollback --token="$VERCEL_TOKEN"
}

deploy_status() { need_env VERCEL_TOKEN; _v ls --token="$VERCEL_TOKEN" | head -20; }
