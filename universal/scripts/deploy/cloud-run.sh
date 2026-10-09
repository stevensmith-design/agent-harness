#!/usr/bin/env bash
# cloud-run — Google Cloud Run. The only one of these targets with a real
# rollback: revisions are immutable and traffic is a pointer, so reverting is a
# seconds-long flip with no rebuild.
#
# Auth in CI is Workload Identity Federation (keyless) — see .agents/rules/ci-cd.md.
# Required: GCP_PROJECT, GCP_REGION, CLOUD_RUN_SERVICE, ARTIFACT_REPO.

_gc() { gcloud "$@"; }
_image() { printf '%s-docker.pkg.dev/%s/%s/%s:%s' "$GCP_REGION" "$GCP_PROJECT" "$ARTIFACT_REPO" "$CLOUD_RUN_SERVICE" "$(build_ref)"; }

deploy_plan() {
  need_env GCP_PROJECT GCP_REGION CLOUD_RUN_SERVICE ARTIFACT_REPO
  info "image:   $(_image)"
  info "service: $CLOUD_RUN_SERVICE in $GCP_REGION"
  _gc run services describe "$CLOUD_RUN_SERVICE" --region "$GCP_REGION" \
      --format='value(status.traffic)' 2>/dev/null || info "(service does not exist yet)"
}

deploy_apply() {
  require_confirm
  need_env GCP_PROJECT GCP_REGION CLOUD_RUN_SERVICE ARTIFACT_REPO
  local img; img=$(_image)
  _gc auth configure-docker "$GCP_REGION-docker.pkg.dev" --quiet
  docker build -t "$img" "$HARNESS_ROOT"
  docker push "$img"
  if [ "$DEPLOY_ENV" = "production" ]; then
    # Deploy WITHOUT traffic, addressable at a tagged URL, so it can be verified
    # before cutover. This is the primitive the other platforms only approximate.
    _gc run deploy "$CLOUD_RUN_SERVICE" --image "$img" --region "$GCP_REGION" \
        --no-traffic --tag "r$(build_ref)" --quiet
    ok "deployed as revision tag r$(build_ref), taking NO traffic. Verify, then promote."
  else
    _gc run deploy "$CLOUD_RUN_SERVICE" --image "$img" --region "$GCP_REGION" --quiet
  fi
}

deploy_promote() {
  require_confirm
  need_env GCP_REGION CLOUD_RUN_SERVICE
  local pct="${PROMOTE_PERCENT:-100}"
  _gc run services update-traffic "$CLOUD_RUN_SERVICE" --region "$GCP_REGION" \
      --to-tags "r$(build_ref)=$pct" --quiet
  ok "sent $pct% of traffic to r$(build_ref)"
}

deploy_rollback() {
  need_env GCP_REGION CLOUD_RUN_SERVICE
  local rev="${1:-${ROLLBACK_REVISION:-}}"
  [ -n "$rev" ] || fail "pass the good revision name: deploy_rollback <revision>
    List them with: gcloud run revisions list --service $CLOUD_RUN_SERVICE --region $GCP_REGION"
  _gc run services update-traffic "$CLOUD_RUN_SERVICE" --region "$GCP_REGION" \
      --to-revisions "$rev=100" --quiet
  ok "100% of traffic returned to $rev"
}

deploy_status() {
  need_env GCP_REGION CLOUD_RUN_SERVICE
  _gc run services describe "$CLOUD_RUN_SERVICE" --region "$GCP_REGION" --format=yaml | head -40
}
