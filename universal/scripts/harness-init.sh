#!/usr/bin/env bash
# Fill in harness.config.yaml for this repo. Detects what it can, asks for the
# rest on a terminal, and takes every answer as an argument when there is none.
#
# Safe to re-run: it is an inventory + patch, not a scaffold. Non-interactive
# (CI, agent) mode: pass every answer as an argument, or --yes to accept the
# detected default for any you omit. --dry-run writes nothing at all.
. "$(dirname "$0")/lib.sh"

YES=0; DRY=0
ADAPTERS="generic|react-web|react-native|flutter|node-api|python-api"
# One provided-flag per answer: an empty value someone passed is an error to
# report, while an empty value nobody passed is a question still to resolve.
for k in adapter name stack src tests ui datastore level; do
  eval "ARG_$k=''; HAS_$k=0"
done
set_arg() { # set_arg <--option> <value>
  local k="${1#--}"
  eval "ARG_$k=\$2; HAS_$k=1"
}

usage() {
  cat <<'USAGE'
harness-init — inventory this repo and fill in harness.config.yaml.

  --adapter <name>     generic | react-web | react-native | flutter | node-api | python-api
  --name <name>        project name (letters, digits, . _ - @ /)
  --stack <text>       one line, e.g. "Next.js 15 + TypeScript"
  --src <dir>          handwritten source root, relative (e.g. src)
  --tests <dir>        test root, relative (e.g. test)
  --ui <bool>          true | false — false removes the design-tokens rule
  --datastore <bool>   true | false — false removes the data-access rule
  --level <rung>       L1 | L2 | L3 — L3 also enables governance
  --yes                accept the detected default for any answer not given
  --dry-run            validate, then report the planned configuration and
                       rule removals; writes nothing, runs no generator
  -h, --help           this text (writes nothing)

On a terminal, unanswered questions are asked. Without one (CI, agents), every
answer must come from an argument or, with --yes, from detection; anything
still unresolved — such as a stack nobody named — fails before any write.
Each option also accepts --option=value.

A real run rewrites harness.config.yaml and AGENTS.md, removes rules that do
not apply, and regenerates tool views and CI. Commit first, or use --dry-run.
USAGE
}

# An unrecognised flag used to be ignored and the full destructive init ran
# anyway — so `--help` rewrote the config and deleted rule files. The skill that
# owns this script lists "deletes work" under Never.
while [ $# -gt 0 ]; do
  case "$1" in
    --yes)     YES=1 ;;
    --dry-run) DRY=1 ;;
    -h|--help) usage; exit 0 ;;
    --adapter|--name|--stack|--src|--tests|--ui|--datastore|--level)
      [ $# -ge 2 ] || fail "$1 needs a value — see 'scripts/harness-init.sh --help'. Nothing was written."
      set_arg "$1" "$2"; shift ;;
    --adapter=*|--name=*|--stack=*|--src=*|--tests=*|--ui=*|--datastore=*|--level=*)
      set_arg "${1%%=*}" "${1#*=}" ;;
    *) fail "unknown option '$1' — see 'scripts/harness-init.sh --help'.
    Refusing to run a destructive init on an argument I do not understand. Nothing was written." ;;
  esac
  shift
done
INTERACTIVE=0
[ "$YES" = 0 ] && [ -t 0 ] && INTERACTIVE=1

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

detect_stack() { # a stack already written by an earlier run is not a placeholder
  local s
  s=$(HARNESS_CFG_OPTIONAL=1 cfg project.stack "")
  s=${s#\"}; s=${s%\"}
  printf '%s\n' "${s:-<stack>}"
}

# answer <key> <prompt> <default> — an argument wins; then a terminal answer;
# then, only with --yes, the detected default. Otherwise it stays unresolved
# (empty) and validation names the argument that is required.
answer() {
  local k="$1" p="$2" d="$3" a
  if [ "$(eval "echo \$HAS_$k")" = 1 ]; then eval "printf '%s\n' \"\$ARG_$k\""; return; fi
  if [ "$INTERACTIVE" = 1 ]; then
    read -r -p "$p [$d]: " a </dev/tty || a=""
    printf '%s\n' "${a:-$d}"; return
  fi
  [ "$YES" = 1 ] && printf '%s\n' "$d"
  return 0
}

ERRORS=""
bad() { ERRORS="$ERRORS
    $1"; }
# check <key> <value> <ERE> <what it may contain>
check() {
  local k="$1" v="$2" re="$3" what="$4"
  if [ -z "$v" ]; then
    if [ "$(eval "echo \$HAS_$k")" = 1 ]; then bad "--$k is blank"
    else bad "--$k is required: there is no terminal to ask, and without --yes no detected default is accepted"; fi
    return 0
  fi
  case "$v" in
    *'<'*|*'>'*) bad "--$k '$v' is an unresolved placeholder — pass --$k with the real value"; return 0 ;;
  esac
  [[ "$v" =~ $re ]] || bad "--$k '$v' is not allowed — $what"
  return 0
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
ok "detected — adapter: $A   source: $S/   tests: $T/   name: $N"

A=$(answer adapter "adapter ($ADAPTERS)" "$A")
N=$(answer name "project name" "$N")
STACK=$(answer stack "stack (one line, e.g. 'Next.js 15 + TypeScript')" "$(detect_stack)")
S=$(answer src "source dir" "$S"); S=${S%/}
T=$(answer tests "tests dir" "$T"); T=${T%/}
case "$A" in node-api|python-api|generic) ui_default=false ;; *) ui_default=true ;; esac
UI=$(answer ui "does this project have a UI? (true/false)" "$ui_default")
DB=$(answer datastore "does this project own a datastore? (true/false)" "$(has_datastore)")
LVL=$(answer level "target maturity level (L1|L2|L3)" "L2")

# Validate everything before anything is written. These values reach a YAML
# file, a sed replacement in AGENTS.md and rm paths, so the allowed characters
# are narrow on purpose.
PATH_RE='^[A-Za-z0-9_][A-Za-z0-9._/-]*$'
check adapter   "$A"     "^($ADAPTERS)$"                    "one of $ADAPTERS"
check name      "$N"     '^[A-Za-z0-9@][A-Za-z0-9._@/-]*$'  "letters, digits, . _ - @ /"
check stack     "$STACK" '^[A-Za-z0-9][A-Za-z0-9 .+_/(),:-]{0,119}$' "one line of letters, digits, spaces and . + _ / ( ) , : -"
check src       "$S"     "$PATH_RE"                         "a relative directory such as src"
check tests     "$T"     "$PATH_RE"                         "a relative directory such as test"
check ui        "$UI"    '^(true|false)$'                   "exactly true or false"
check datastore "$DB"    '^(true|false)$'                   "exactly true or false"
check level     "$LVL"   '^L[123]$'                         "L1, L2 or L3"
for pair in "src:$S" "tests:$T"; do
  case "/${pair#*:}/" in */../*|*/./*) bad "--${pair%%:*} '${pair#*:}' must not contain . or .. segments" ;; esac
done
if [ -z "$ERRORS" ] && [ ! -f "$HARNESS_ROOT/scripts/adapters/$A.sh" ]; then
  bad "--adapter '$A' has no scripts/adapters/$A.sh in this harness"
fi
[ -z "$ERRORS" ] || fail "harness-init cannot continue — nothing was written:$ERRORS
    See 'scripts/harness-init.sh --help'."

DROP=""
[ "$UI" = "true" ] || DROP="$DROP design-tokens"
[ "$DB" = "true" ] || DROP="$DROP data-access"
case "$A" in
  react-web|react-native|flutter) [ "$DB" = "true" ] || DROP="$DROP api-design" ;;
esac
rule_copies() { # every on-disk copy of one rule, canonical and generated
  local p
  for p in ".agents/rules/$1.md" ".cursor/rules/$1.mdc" \
           ".github/instructions/$1.instructions.md" ".claude/rules/$1.md"; do
    if [ -e "$HARNESS_ROOT/$p" ] || [ -L "$HARNESS_ROOT/$p" ]; then printf '%s\n' "$p"; fi
  done
}

set_cfg harness adapter "$A"
set_cfg harness level "$LVL"
set_cfg project name "$N"
set_cfg project stack "\"$STACK\""
set_cfg project src "$S"
set_cfg project tests "$T"
set_cfg design enabled "$UI"
set_cfg design tokens_path "$S/theme"
[ "$LVL" = "L3" ] && set_cfg governance enabled true

# A dry run stops here, before AGENTS.md, rule removal and the generators —
# every one of which used to run anyway and rewrite the tree it promised to
# leave alone.
if [ "$DRY" = 1 ]; then
  info "would replace AGENTS.md placeholders: <product> → $N, <stack> → $STACK, <src>/ → $S/, <tests>/ → $T/"
  for r in $DROP; do
    copies=$(rule_copies "$r")
    if [ -n "$copies" ]; then
      printf '%s\n' "$copies" | while IFS= read -r p; do info "would remove $p (the $r rule does not apply here)"; done
    else
      info "would remove the $r rule (no copy present)"
    fi
  done
  [ -n "$DROP" ] || info "would remove no rules"
  info "would regenerate tool views (scripts/harness-sync.sh) and CI (scripts/ci-gen.sh)"
  ok "dry run — nothing was written"
  exit 0
fi

# AGENTS.md placeholders
sed -i.bak "s|\`<product>\`|\`$N\`|; s|\`<stack>\`|\`$STACK\`|; s|\`<src>/\`|\`$S/\`|; s|\`<tests>/\`|\`$T/\`|" "$HARNESS_ROOT/AGENTS.md" && rm -f "$HARNESS_ROOT/AGENTS.md.bak"

for r in $DROP; do  # a rule that cannot apply here is deleted, not left inert
  rule_copies "$r" | while IFS= read -r p; do rm -f "$HARNESS_ROOT/$p"; done
  info "removed the $r rule (does not apply here)"
done

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
