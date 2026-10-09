#!/usr/bin/env bash
# flutter — Flutter/Dart with build_runner codegen. fvm-aware.

_f()  { if command -v fvm >/dev/null 2>&1 && [ -f "$HARNESS_ROOT/.fvmrc" ]; then fvm flutter "$@"; else flutter "$@"; fi; }
_d()  { if command -v fvm >/dev/null 2>&1 && [ -f "$HARNESS_ROOT/.fvmrc" ]; then fvm dart "$@"; else dart "$@"; fi; }

cmd_deps()         { _f pub get; }
cmd_dev()          { _f run; }
cmd_dev_mock()     { _f run --dart-define=MOCK_MODE=true; }
cmd_lint()         { _f analyze --fatal-infos; }
cmd_format()       { _d format . ; }
cmd_format_check() { _d format --output=none --set-exit-if-changed . ; }
cmd_test()         { _f test; }
cmd_coverage()     { _f test --coverage; }
cmd_codegen()      { _d run build_runner build --delete-conflicting-outputs; }
cmd_build()        { _f build apk --release; }
cmd_verify() {
  # Evidence recipe: analysis is clean and the app compiles for a real target.
  cmd_lint
  _f build apk --debug >/dev/null || fail "debug build failed"
  ok "analyzes clean and builds"
}

ci_setup() {
  case "$1" in
    github) cat <<'YAML'
      - uses: subosito/flutter-action@1a449444c387b1966244ae4d4f8c696479add0b2 # v2
        with:
          channel: stable
          cache: true
YAML
;;
    gitlab) echo '  image: ghcr.io/cirruslabs/flutter:stable' ;;
  esac
}
