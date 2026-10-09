#!/usr/bin/env bash
# react-native — Expo / bare RN + TypeScript + Jest (+ Maestro or Detox for e2e).

_pm() {
  if [ -n "${PM:-}" ]; then echo "$PM"; return; fi
  [ -f "$HARNESS_ROOT/pnpm-lock.yaml" ] && { echo pnpm; return; }
  [ -f "$HARNESS_ROOT/yarn.lock" ]      && { echo yarn; return; }
  echo npm
}
_run() { local pm; pm=$(_pm); case "$pm" in npm) npm run "$@";; *) "$pm" run "$@";; esac; }
_expo() { [ -f "$HARNESS_ROOT/app.json" ] || [ -f "$HARNESS_ROOT/app.config.ts" ]; }

cmd_deps() {
  local pm; pm=$(_pm)
  case "$pm" in
    npm)  [ -f "$HARNESS_ROOT/package-lock.json" ] || fail "npm install refused without package-lock.json"; npm ci ;;
    pnpm) pnpm install --frozen-lockfile ;;
    yarn) yarn install --immutable 2>/dev/null || yarn install --frozen-lockfile ;;
    *)    fail "unsupported package manager '$pm'" ;;
  esac
}
cmd_dev()          { if _expo; then npx --yes expo start; else _run start; fi; }
cmd_dev_mock()     { MOCK_MODE=true EXPO_PUBLIC_MOCK_MODE=true cmd_dev; }
cmd_lint()         { _run lint; }
cmd_format()       { npx --yes prettier --write .; }
cmd_format_check() { npx --yes prettier --check .; }
cmd_typecheck()    { npx --yes tsc --noEmit; }
cmd_test()         { npx --yes jest --ci; }
cmd_coverage()     { npx --yes jest --coverage --ci; }
cmd_build()        { if _expo; then npx --yes eas build --platform all --non-interactive --no-wait; else warn "configure a native build"; fi; }
cmd_e2e()          { command -v maestro >/dev/null && maestro test .maestro/ || npx --yes detox test; }
cmd_verify() {
  # Evidence recipe: the bundle compiles. Simulator runs are a human gate.
  npx --yes expo export --platform ios --output-dir /tmp/harness-rn-export >/dev/null \
    || fail "bundle did not build"
  ok "JS bundle builds"
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
    gitlab) echo '  image: node:22' ;;
  esac
}
