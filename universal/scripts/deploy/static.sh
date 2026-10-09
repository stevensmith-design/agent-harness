#!/usr/bin/env bash
# static — build artifacts to any object store / CDN. Fill in the two commands.
deploy_plan()  { info "would sync $(cfg project.src dist)/ build output to ${STATIC_BUCKET:-<bucket>}"; }
deploy_apply() { require_confirm; need_env STATIC_BUCKET; warn "TODO: sync build output to $STATIC_BUCKET"; }
deploy_promote()  { :; }
deploy_rollback() { warn "TODO: re-sync the previous build, or flip a CDN origin"; }
deploy_status()   { warn "TODO: report what is currently published"; }
