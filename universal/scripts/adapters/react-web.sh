#!/usr/bin/env bash
# react-web — Next.js / Vite + TypeScript + Vitest + Playwright + ESLint/Prettier.
# Package manager is auto-detected; override with PM=pnpm|npm|yarn|bun.

_pm() {
  if [ -n "${PM:-}" ]; then echo "$PM"; return; fi
  [ -f "$HARNESS_ROOT/pnpm-lock.yaml" ] && { echo pnpm; return; }
  [ -f "$HARNESS_ROOT/yarn.lock" ]      && { echo yarn; return; }
  [ -f "$HARNESS_ROOT/bun.lockb" ]      && { echo bun;  return; }
  echo npm
}
_run() { local pm; pm=$(_pm); case "$pm" in npm) npm run "$@";; *) "$pm" run "$@";; esac; }

# A script this adapter calls but package.json does not define is a MISSING
# CHECK, not an error to dump raw. `npm run lint` on a repo with no lint script
# prints npm's "Did you mean npm link?" and a debug-log path — a dead end. Route
# it through todo() instead: locally it says what is missing, in CI it fails,
# and `make check` will not print a green summary over it.
_has_script() {
  [ -f "$HARNESS_ROOT/package.json" ] || return 1
  node -e "process.exit(require('$HARNESS_ROOT/package.json').scripts?.['$1']?0:1)" 2>/dev/null \
    || grep -qE "\"$1\"[[:space:]]*:" "$HARNESS_ROOT/package.json"
}
_run_script() { # _run_script <script> [args...]
  local sc="$1"; shift
  if _has_script "$sc"; then _run "$sc" "$@"
  else todo "$sc — package.json defines no \"$sc\" script. Add one, or drop the verb from this adapter."; fi
}

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
cmd_dev()          { _run_script dev; }
cmd_dev_mock()     { MOCK_MODE=true NEXT_PUBLIC_MOCK_MODE=true VITE_MOCK_MODE=true _run dev; }
cmd_lint()         { _run_script lint; }
cmd_format()       { local pm; pm=$(_pm); "$pm" exec prettier -- --write . 2>/dev/null || npx prettier --write .; }
cmd_format_check() { npx --yes prettier --check . ; }
cmd_typecheck()    {
  # No tsconfig means no TypeScript project to check. `npx tsc --noEmit` in that
  # case prints tsc's entire --help and exits non-zero: a dead end that tells you
  # nothing about your code.
  if [ -f "$HARNESS_ROOT/tsconfig.json" ]; then npx --yes tsc --noEmit -p "$HARNESS_ROOT/tsconfig.json"
  else todo "typecheck — no tsconfig.json. Add one, or remove cmd_typecheck from this adapter."; fi
}
cmd_test()         { if _has_script test; then _run test -- --run 2>/dev/null || _run test; else todo "test — package.json defines no \"test\" script"; fi; }
cmd_coverage()     { npx --yes vitest run --coverage; }
cmd_build()        { _run_script build; }
cmd_e2e()          { npx --yes playwright test; }
cmd_verify() {
  # Evidence recipe: the build succeeds and the server answers on / .
  cmd_build
  # Fail fast and say why, rather than starting nothing and then waiting 30s for
  # it to answer. A verify that hangs is a verify nobody runs.
  _has_script start || { todo "verify — package.json defines no \"start\" script to serve the built app"; return 0; }
  ( _run start & echo $! > /tmp/harness-web.pid ) >/dev/null 2>&1
  local ok=1
  for _ in $(seq 1 30); do
    if curl -fsS "http://localhost:${PORT:-3000}/" >/dev/null 2>&1; then ok=0; break; fi
    sleep 1
  done
  [ -f /tmp/harness-web.pid ] && kill "$(cat /tmp/harness-web.pid)" 2>/dev/null || true
  [ "$ok" -eq 0 ] || fail "app did not answer on http://localhost:${PORT:-3000}/"
  ok "app builds and serves"
}

ci_setup() {
  case "$1" in
    github)
      # Pin to .nvmrc when the repo has one; setup-node hard-fails if the file
      # named here does not exist, and the harness does not create it.
      if [ -f "$HARNESS_ROOT/.nvmrc" ]; then
        cat <<'YAML'
      - uses: actions/setup-node@249970729cb0ef3589644e2896645e5dc5ba9c38 # v6
        with:
          node-version-file: .nvmrc
          cache: npm
YAML
      else
        cat <<'YAML'
      - uses: actions/setup-node@249970729cb0ef3589644e2896645e5dc5ba9c38 # v6
        with:
          node-version: "22"      # add a .nvmrc and this pins to it instead
          cache: npm
YAML
      fi
      ;;
    gitlab) echo '  image: node:22-alpine' ;;
  esac
}
