#!/usr/bin/env bash
# generic adapter — fill these in for your stack, or pick a shipped adapter.
# Every unimplemented verb is skipped with a warning, so `make check` stays
# runnable while you fill it in.

cmd_deps()         { todo "install dependencies"; }
cmd_dev()          { todo "run the app"; }
cmd_dev_mock()     { MOCK_MODE=true todo "run the app against stubs"; }
cmd_lint()         { todo "lint"; }
cmd_format()       { todo "format"; }
cmd_format_check() { todo "format --check"; }
cmd_test()         { todo "test"; }
cmd_build()        { todo "build"; }
cmd_verify()       { todo "prove the app starts (see .agents/skills/harness-verify)"; }

# ci_setup <platform> — emit the toolchain setup steps for this stack.
# This is what removes the TODO from a generated CI file: the adapter knows the
# toolchain, so no CI template has to.
ci_setup() {
  case "$1" in
    github) cat <<'YAML'
      - name: Set up toolchain
        run: echo "TODO - add your stack setup step in scripts/adapters/generic.sh"
YAML
;;
    gitlab) echo '  image: alpine:latest' ;;
  esac
}
