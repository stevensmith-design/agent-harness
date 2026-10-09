#!/usr/bin/env bash
# Fill in harness.config.yaml for this repo. Detects what it can, asks for the
# rest, and never overwrites a filled-in value without being told to.
#
# Safe to re-run: it is an inventory + patch, not a scaffold. Non-interactive
# (CI, agent) mode: pass --yes to accept every detected default.
. "$(dirname "$0")/lib.sh"

YES=0; DRY=0
# An unrecognised flag used to be ignored and the full destructive init ran
# anyway — so `--help` rewrote the config and deleted rule files. The skill that
# owns this script lists "deletes work" under Never.
while [ $# -gt 0 ]; do
  case "$1" in
    --yes)     YES=1 ;;
    --dry-run) DRY=1 ;;
    -h|--help)
      cat <<'USAGE'
harness-init — inventory this repo and fill in harness.config.yaml.

  --yes       accept every detected default (non-interactive: CI, agents)
  --dry-run   report what it would change; write nothing
  -h, --help  this text

It rewrites harness.config.yaml and removes rules that do not apply to the
detected stack. Commit first, or use --dry-run.
USAGE
      exit 0 ;;
    *) fail "unknown option '$1' — see 'scripts/harness-init.sh --help'.
    Refusing to run a destructive init on an argument I do not understand." ;;
  esac
  shift
done

detect_adapter() {
  [ -f "$HARNESS_ROOT/pubspec.yaml" ] && { echo flutter; return; }
  if [ -f "$HARNESS_ROOT/package.json" ]; then
    grep -qE '"(react-native|expo)"' "$HARNESS_ROOT/package.json" && { echo react-native; return; }
    grep -qE '"(next|react|vite)"'   "$HARNESS_ROOT/package.json" && { echo react-web; return; }
    grep -qE '"(express|fastify|@nestjs/core|hono|koa)"' "$HARNESS_ROOT/package.json" && { echo node-api; return; }
  fi
  if [ -f "$HARNESS_ROOT/pyproject.toml" ] || [ -f "$HARNESS_ROOT/requirements.txt" ]; then
    grep -rqiE '(fastapi|django|flask)' "$HARNESS_ROOT/pyproject.toml" "$HARNESS_ROOT/requirements.txt" 2>/dev/null \
      && { echo python-api; return; }
  fi
  echo generic
}
has_datastore() {
  for p in migrations db prisma alembic; do [ -d "$HARNESS_ROOT/$p" ] && { echo true; return; }; done
  grep -qiE '(prisma|drizzle|typeorm|sequelize|knex|sqlalchemy|alembic|mongoose)' \
    "$HARNESS_ROOT/package.json" "$HARNESS_ROOT/pyproject.toml" 2>/dev/null && { echo true; return; }
  echo false
}
detect_src() {
  for d in src lib app; do [ -d "$HARNESS_ROOT/$d" ] && { echo "$d"; return; }; done; echo src
}
detect_tests() {
  for d in tests test __tests__ spec; do [ -d "$HARNESS_ROOT/$d" ] && { echo "$d"; return; }; done; echo tests
}
detect_name() {
  if [ -f "$HARNESS_ROOT/package.json" ]; then
    grep -m1 '"name"' "$HARNESS_ROOT/package.json" | sed 's/.*"name"[^"]*"\([^"]*\)".*/\1/'; return
  fi
  if [ -f "$HARNESS_ROOT/pubspec.yaml" ]; then grep -m1 '^name:' "$HARNESS_ROOT/pubspec.yaml" | awk '{print $2}'; return; fi
  basename "$HARNESS_ROOT"
}

ask() { # ask <prompt> <default>
  local p="$1" d="$2" a
  if [ "$YES" = 1 ] || [ ! -t 0 ]; then echo "$d"; return; fi
  read -r -p "$p [$d]: " a </dev/tty || a=""
  echo "${a:-$d}"
}

set_cfg() { # set_cfg <section> <key> <value>
  if [ "$DRY" = 1 ]; then info "would set $1.$2 = $3"; return 0; fi
  local sec="$1" key="$2" val="$3"
  python3 - "$CONFIG" "$sec" "$key" "$val" <<'PY'
import sys, re
path, sec, key, val = sys.argv[1:5]
lines = open(path).read().split('\n')
out, in_sec, done = [], False, False
for ln in lines:
    if re.match(r'^[^\s#]', ln):
        in_sec = ln.split(':')[0].strip() == sec
    if in_sec and re.match(rf'^\s+{re.escape(key)}:', ln):
        indent = ln[:len(ln)-len(ln.lstrip())]
        comment = ''
        m = re.search(r'(\s+#.*)$', ln)
        if m: comment = m.group(1)
        ln = f"{indent}{key}: {val}{comment}"
        done = True
    out.append(ln)
open(path,'w').write('\n'.join(out))
sys.exit(0 if done else 0)
PY
}

info "inventorying the repo"
A=$(detect_adapter); S=$(detect_src); T=$(detect_tests); N=$(detect_name)
ok "adapter: $A   source: $S/   tests: $T/   name: $N"

A=$(ask "adapter (generic|react-web|react-native|flutter)" "$A")
N=$(ask "project name" "$N")
STACK=$(ask "stack (one line, e.g. 'Next.js 15 + TypeScript')" "<stack>")
S=$(ask "source dir" "$S")
T=$(ask "tests dir" "$T")
case "$A" in node-api|python-api|generic) ui_default=false ;; *) ui_default=true ;; esac
UI=$(ask "does this project have a UI? (true/false)" "$ui_default")
DB=$(ask "does this project own a datastore? (true/false)" "$(has_datastore)")
LVL=$(ask "target maturity level (L1|L2|L3)" "L2")

set_cfg harness adapter "$A"
set_cfg harness level "$LVL"
set_cfg project name "$N"
set_cfg project stack "\"$STACK\""
set_cfg project src "$S"
set_cfg project tests "$T"
set_cfg design enabled "$UI"
set_cfg design tokens_path "$S/theme"
[ "$LVL" = "L3" ] && set_cfg governance enabled true

# AGENTS.md placeholders
sed -i.bak "s|\`<product>\`|\`$N\`|; s|\`<stack>\`|\`$STACK\`|; s|\`<src>/\`|\`$S/\`|; s|\`<tests>/\`|\`$T/\`|" "$HARNESS_ROOT/AGENTS.md" && rm -f "$HARNESS_ROOT/AGENTS.md.bak"

drop_rule() {  # a rule that cannot apply here is deleted, not left inert
  local n="$1"
  rm -f "$HARNESS_ROOT/.agents/rules/$n.md" \
        "$HARNESS_ROOT/.cursor/rules/$n.mdc" \
        "$HARNESS_ROOT/.github/instructions/$n.instructions.md" \
        "$HARNESS_ROOT/.claude/rules/$n.md"
  info "removed the $n rule (does not apply here)"
}
[ "$UI" = "true" ] || drop_rule design-tokens
[ "$DB" = "true" ] || drop_rule data-access
case "$A" in
  react-web|react-native|flutter) [ "$DB" = "true" ] || drop_rule api-design ;;
esac

"$HARNESS_ROOT/scripts/harness-sync.sh"
# harness-init picks the adapter, and the adapter supplies CI's toolchain step —
# so the generated pipeline is stale the moment the adapter changes. Without
# this, the very next `make ci` failed on a drift the user did not cause.
"$HARNESS_ROOT/scripts/ci-gen.sh" >/dev/null && info "regenerated CI for adapter '$A'"
ok "harness.config.yaml written"

# Suggest capability skills for what we actually found. Suggest, never install:
# a vendored skill is instructions your agents will follow, and that is a
# decision with a licence attached.
info "capability skills worth vendoring for this stack (see docs/skills-catalog.md):"
[ "$DB" = "true" ] && \
  echo "    make skills-add REPO=supabase/agent-skills SKILL=skills/supabase-postgres-best-practices   # Postgres: schema, indexes, RLS, locking"
[ "$UI" = "true" ] && \
  echo "    make skills-add REPO=addyosmani/web-quality-skills SKILL=skills/accessibility               # WCAG 2.2 + HTML patterns"
case "$A" in
  react-web)
    echo "    make skills-add REPO=vercel-labs/agent-skills SKILL=react-best-practices                   # React/Next perf rules"
    echo "    make skills-add REPO=anthropics/skills SKILL=skills/webapp-testing                         # Playwright E2E" ;;
  react-native)
    echo "    make skills-add REPO=vercel-labs/agent-skills SKILL=composition-patterns                   # React architecture" ;;
  flutter)
    echo "    make skills-add REPO=flutter/skills SKILL=skills/flutter-add-widget-test"
    echo "    make skills-add REPO=dart-lang/skills SKILL=skills/dart-add-unit-test" ;;
  python-api)
    echo "    make skills-add REPO=anthropics/skills SKILL=skills/webapp-testing                         # Playwright E2E" ;;
esac
info "next: fill in scripts/adapters/$A.sh if needed, then run 'make check'"
