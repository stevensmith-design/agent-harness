#!/usr/bin/env bash
# supabase — database migrations and edge functions.
#
# ⚠️ SUPABASE MIGRATIONS HAVE NO ROLLBACK. Not a weak rollback — none. There are
# no down migrations and no revert command. `supabase migration repair` rewrites
# the history table WITHOUT touching the schema, which leaves the database and
# its history disagreeing. The only real recovery is a restore from backup plus
# a compensating forward migration.
#
# That is why deploy_plan runs a real dry run and why production always confirms.
# Required: SUPABASE_ACCESS_TOKEN, SUPABASE_PROJECT_ID, SUPABASE_DB_PASSWORD.

_sb() { supabase "$@"; }

_link() {
  need_env SUPABASE_ACCESS_TOKEN SUPABASE_PROJECT_ID SUPABASE_DB_PASSWORD
  _sb link --project-ref "$SUPABASE_PROJECT_ID" >/dev/null
}

deploy_plan() {
  _link
  info "migrations that WOULD be applied to [$DEPLOY_ENV]:"
  _sb db push --dry-run
  info "local vs remote migration history:"
  _sb migration list || true
}

deploy_apply() {
  require_confirm
  _link
  # Always show the plan first, even in CI. The two-step separation is the point:
  # a human reads this before the gate that allows the next line to run.
  _sb db push --dry-run
  _sb db push
  if [ -d "$HARNESS_ROOT/supabase/functions" ]; then
    _sb functions deploy --project-ref "$SUPABASE_PROJECT_ID"
    ok "edge functions deployed"
  fi
  ok "migrations applied to $DEPLOY_ENV"
}

deploy_promote() { :; }   # migrations have no separate cutover step

deploy_rollback() {
  warn "Supabase has no migration rollback."
  warn "  Recovery is: restore the database from a backup, then write a"
  warn "  compensating forward migration. 'supabase migration repair' only"
  warn "  rewrites the history table and will desynchronise it from the schema."
  fail "no automatic rollback available — this needs a person"
}

deploy_status() { _link; _sb migration list; }
