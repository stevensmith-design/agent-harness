#!/usr/bin/env bash
# python-api — FastAPI/Django/Flask service. uv preferred, falls back to pip.

_py() { if command -v uv >/dev/null 2>&1 && [ -f "$HARNESS_ROOT/pyproject.toml" ]; then uv run "$@"; else python3 -m "$@"; fi; }
_has() { command -v "$1" >/dev/null 2>&1; }

cmd_deps() {
  if _has uv && [ -f "$HARNESS_ROOT/pyproject.toml" ]; then
    [ -f "$HARNESS_ROOT/uv.lock" ] || fail "uv sync refused without uv.lock"
    uv sync --frozen
  elif [ -f "$HARNESS_ROOT/requirements.txt" ]; then
    grep -q -- '--hash=sha256:' "$HARNESS_ROOT/requirements.txt" \
      || fail "pip install refused: requirements.txt must be pinned with hashes"
    python3 -m pip install --require-hashes -r "$HARNESS_ROOT/requirements.txt"
  else warn "no pyproject.toml or requirements.txt found"; fi
}
cmd_dev()          { _py uvicorn app.main:app --reload; }
cmd_dev_mock()     { MOCK_MODE=true cmd_dev; }
cmd_lint()         { if _has ruff; then ruff check .; else _py ruff check .; fi; }
cmd_format()       { if _has ruff; then ruff format .; else _py ruff format .; fi; }
cmd_format_check() { if _has ruff; then ruff format --check .; else _py ruff format --check .; fi; }
cmd_typecheck()    { _py mypy . 2>/dev/null || _py pyright; }
cmd_test()         { _py pytest -q; }
cmd_coverage()     { _py pytest --cov -q; }

cmd_migrate()        { _py alembic upgrade head 2>/dev/null || _py django manage.py migrate; }
cmd_migrate_status() { _py alembic current 2>/dev/null || _py django manage.py showmigrations; }
cmd_migrate_new()    { _py alembic revision --autogenerate -m "${1:?name required}"; }
cmd_db_reset() {
  case "${DATABASE_URL:-}" in
    *localhost*|*127.0.0.1*|*@db:*|"") ;;
    *) fail "db_reset refused: DATABASE_URL does not look local." ;;
  esac
  _py alembic downgrade base && _py alembic upgrade head
}

cmd_verify() {
  cmd_lint
  _py python -c "import app.main" 2>/dev/null || warn "could not import app.main — adjust cmd_verify for your layout"
  ok "imports and lints clean"
}

ci_setup() {
  case "$1" in
    github) cat <<'YAML'
      - uses: actions/setup-python@ece7cb06caefa5fff74198d8649806c4678c61a1 # v6
        with:
          python-version-file: pyproject.toml
          cache: pip
YAML
;;
    gitlab) echo '  image: python:3.12-slim' ;;
  esac
}
