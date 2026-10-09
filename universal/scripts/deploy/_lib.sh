#!/usr/bin/env bash
# Shared guards for every deploy module. Sourced, never run directly.

DEPLOY_ENV="${DEPLOY_ENV:-preview}"

# Refuse production without an explicit confirmation. CI sets this only after an
# approved environment gate; a human sets it deliberately. An agent must never
# set it on its own initiative.
require_confirm() {
  [ "$DEPLOY_ENV" != "production" ] && return 0
  [ "${DEPLOY_CONFIRM:-0}" = "1" ] && return 0
  fail "production deploy refused: DEPLOY_CONFIRM=1 is required.
    That flag is set by an approved CI environment or by a person, deliberately.
    If you are an agent and nobody asked for a production deploy in this turn, stop."
}

# Fail loudly on a missing credential rather than deploying a half-configured app.
need_env() {
  local missing=""
  for v in "$@"; do
    eval "val=\${$v:-}"
    [ -n "${val:-}" ] || missing="$missing $v"
  done
  [ -z "$missing" ] || fail "missing required environment:$missing"
}

# Immutable image/build identity. Never 'latest' — a mutable tag makes it
# impossible to say what is running or to reproduce a rollback.
build_ref() {
  git -C "$HARNESS_ROOT" rev-parse --short=12 HEAD 2>/dev/null || echo "unknown"
}
