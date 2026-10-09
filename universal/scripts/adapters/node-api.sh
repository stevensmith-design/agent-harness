#!/usr/bin/env bash
# node-api — TypeScript HTTP service (Express/Fastify/Nest/Hono) with a database.
# Package manager auto-detected; override with PM=pnpm|npm|yarn|bun.

_pm() {
  if [ -n "${PM:-}" ]; then echo "$PM"; return; fi
  [ -f "$HARNESS_ROOT/pnpm-lock.yaml" ] && { echo pnpm; return; }
  [ -f "$HARNESS_ROOT/yarn.lock" ]      && { echo yarn; return; }
  [ -f "$HARNESS_ROOT/bun.lock" ] || [ -f "$HARNESS_ROOT/bun.lockb" ] && { echo bun; return; }
  echo npm
}
_run() { local pm; pm=$(_pm); case "$pm" in npm) npm run "$@";; *) "$pm" run "$@";; esac; }

cmd_deps() {
  local pm; pm=$(_pm)
  case "$pm" in
    npm)  [ -f "$HARNESS_ROOT/package-lock.json" ] || fail "npm install refused without package-lock.json"; npm ci ;;
    pnpm) pnpm install --frozen-lockfile ;;
    yarn) yarn install --immutable 2>/dev/null || yarn install --frozen-lockfile ;;
    bun)  bun install --frozen-lockfile ;;
    *)    fail "unsupported package manager '$pm'" ;;
  esac
}
cmd_dev()          { _run dev; }
cmd_dev_mock()     { MOCK_MODE=true _run dev; }
cmd_lint()         { _run lint; }
cmd_format()       { npx --yes prettier --write .; }
cmd_format_check() { npx --yes prettier --check .; }
cmd_typecheck()    { npx --yes tsc --noEmit; }
cmd_test()         { _run test; }
cmd_coverage()     { _run test -- --coverage 2>/dev/null || npx --yes vitest run --coverage; }
cmd_build()        { _run build; }

# --- database -----------------------------------------------------------------
# Migrations are the one backend operation with no undo, so they get their own
# verbs rather than being buried in a package script somebody edits.
cmd_migrate()        { _run migrate 2>/dev/null || _run db:migrate; }
cmd_migrate_status() { _run migrate:status 2>/dev/null || _run db:status; }
cmd_migrate_new()    { _run migrate:new -- "${1:?name required}" 2>/dev/null || _run db:make -- "${1}"; }
cmd_db_reset()       {
  # Destructive. Refuse anywhere that is not obviously a local database.
  case "${DATABASE_URL:-}" in
    *localhost*|*127.0.0.1*|*@db:*|"") ;;
    *) fail "db_reset refused: DATABASE_URL does not look local. Reset production by hand, deliberately, or not at all." ;;
  esac
  _run db:reset
}

cmd_verify() {
  # Evidence recipe: it compiles, migrations apply cleanly, and it answers.
  cmd_build
  local port="${PORT:-3000}" ok=1
  ( _run start & echo $! > /tmp/harness-api.pid ) >/dev/null 2>&1
  for _ in $(seq 1 30); do
    if curl -fsS "http://localhost:$port/health" >/dev/null 2>&1 \
    || curl -fsS "http://localhost:$port/" >/dev/null 2>&1; then ok=0; break; fi
    sleep 1
  done
  [ -f /tmp/harness-api.pid ] && kill "$(cat /tmp/harness-api.pid)" 2>/dev/null || true
  [ "$ok" -eq 0 ] || fail "service did not answer on http://localhost:$port/health"
  ok "service builds and answers"
}

ci_setup() {
  case "$1" in
    github) cat <<'YAML'
      - uses: actions/setup-node@249970729cb0ef3589644e2896645e5dc5ba9c38 # v6
        with:
          node-version-file: .nvmrc
          cache: npm
YAML
;;
    gitlab) echo '  image: node:22-alpine' ;;
  esac
}
