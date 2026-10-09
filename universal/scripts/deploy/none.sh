#!/usr/bin/env bash
# none — the default. No deploy configured for this environment.
deploy_plan()     { info "no deploy target configured for $DEPLOY_ENV"; }
deploy_apply()    { info "no deploy target configured for $DEPLOY_ENV"; }
deploy_promote()  { :; }
deploy_rollback() { :; }
deploy_status()   { info "no deploy target configured"; }
