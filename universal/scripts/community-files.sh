#!/usr/bin/env bash
# Scaffold the community health files a public repository is missing.
#
#   scripts/community-files.sh scaffold [--set KEY=VALUE]... [--dry-run]
#   scripts/community-files.sh check            same as scripts/gates/community-files.sh
#
# Run it through the harness-community-files skill, which explains each file and
# asks the owner for every value first.
#
# Three promises, each the reason this is a script rather than an agent writing
# files freehand:
#   - Existing files win. Anything the project already has — under any name or
#     location GitHub reads — is reported as present and never replaced, merged
#     or touched. Like install.sh, it checks every destination before writing
#     any of them, and refuses rather than overwriting.
#   - Nothing is invented, and nothing half-finished is written. A file is
#     written only when every {{PLACEHOLDER}} in it has a --set value; otherwise
#     it is skipped and reported as "not written: needs <KEY>". A code of
#     conduct with no way to report is worse than none, because it looks done.
#     Files that only work together (the issue-template set) are written or
#     skipped as one.
#   - No owner decisions. There is no LICENSE or README template: the licence is
#     the owner's choice and the README is the owner's description.
#
# Public repositories only (project.visibility: public). On a private one it
# writes nothing and says why.
. "$(dirname "$0")/lib.sh"

TEMPLATES="$HARNESS_ROOT/.harness/templates/community"
KEYS="PROJECT_NAME CONDUCT_CONTACT SECURITY_CONTACT REPOSITORY_URL"

usage() {
  sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//'
  printf '\nKeys: %s\n' "$KEYS"
}

cmd="${1:-}"; [ $# -gt 0 ] && shift
case "$cmd" in
  check) exec "$HARNESS_ROOT/scripts/gates/community-files.sh" ;;
  scaffold) ;;
  -h|--help|"") usage; exit 0 ;;
  *) fail "unknown command '$cmd' — use scaffold or check. Nothing was written." ;;
esac

DRY=0
SETS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --set) [ $# -ge 2 ] || fail "--set needs KEY=VALUE. Nothing was written."; SETS+=("$2"); shift ;;
    --set=*) SETS+=("${1#--set=}") ;;
    -h|--help) usage; exit 0 ;;
    *) fail "unknown option '$1' — see --help. Nothing was written." ;;
  esac
  shift
done

# Validate every value before anything is written. Values land inside Markdown
# and YAML, so they are one line, and may not smuggle in another placeholder.
for kv in ${SETS[@]+"${SETS[@]}"}; do
  k="${kv%%=*}"; v="${kv#*=}"
  [ "$k" != "$kv" ] || fail "--set '$kv' is not KEY=VALUE. Nothing was written."
  case " $KEYS " in *" $k "*) ;; *) fail "--set $k: unknown key. Known: $KEYS. Nothing was written." ;; esac
  [ -n "$v" ] || fail "--set $k is empty. Leave it out to keep the placeholder. Nothing was written."
  case "$v" in *'{{'*|*'}}'*) fail "--set $k contains a placeholder. Nothing was written." ;; esac
  [ "$(printf '%s' "$v" | wc -l | tr -d ' ')" = 0 ] || fail "--set $k must be one line. Nothing was written."
  [ "${#v}" -le 200 ] || fail "--set $k is longer than 200 characters. Nothing was written."
  if [ "$k" = REPOSITORY_URL ]; then
    printf '%s' "$v" | grep -qE -e '^https://[A-Za-z0-9.-]+/[A-Za-z0-9._/-]+[A-Za-z0-9_-]$' -- \
      || fail "--set REPOSITORY_URL must look like https://github.com/<owner>/<repo>, with no trailing slash. Nothing was written."
  fi
done

VIS=$(cfg project.visibility private)
case "$VIS" in
  public) ;;
  private) fail "project.visibility is private — community files are for public repositories, so nothing was written.
    If this repository is (or is about to be) public, set project.visibility: public
    in harness.config.yaml first." ;;
  *) fail "harness.config.yaml: project.visibility is '$VIS'. Use public or private. Nothing was written." ;;
esac
[ -d "$TEMPLATES" ] || fail "no templates at ${TEMPLATES#"$HARNESS_ROOT"/} — the harness install is incomplete. Nothing was written."

# kind → the template files that provide it, relative to $TEMPLATES and to the
# project root alike.
templates_for() {
  case "$1" in
    code_of_conduct) echo "CODE_OF_CONDUCT.md" ;;
    contributing)    echo "CONTRIBUTING.md" ;;
    security)        echo "SECURITY.md" ;;
    issue_templates) echo ".github/ISSUE_TEMPLATE/config.yml .github/ISSUE_TEMPLATE/bug_report.yml .github/ISSUE_TEMPLATE/feature_request.yml" ;;
    *) echo "" ;;
  esac
}

# given <KEY> — 0 if the owner supplied a value for KEY.
given() {
  local kv
  for kv in ${SETS[@]+"${SETS[@]}"}; do [ "${kv%%=*}" = "$1" ] && return 0; done
  return 1
}
# needs <files...> — the placeholders in these templates nobody gave a value
# for, space-separated, or nothing.
needs() {
  local k out=""
  for k in $( cd "$TEMPLATES" && grep -h -o -E -e '\{\{[A-Z][A-Z0-9_]*\}\}' -- "$@" 2>/dev/null \
                | tr -d '{}' | LC_ALL=C sort -u ); do
    given "$k" || out="$out $k"
  done
  printf '%s' "${out# }"
}

# --- Plan, then preflight every destination, then write ----------------------
plan=()
skipped=0
for kind in $COMMUNITY_KINDS; do
  label=$(community_label "$kind")
  have=$(community_locate "$kind")
  if [ -n "$have" ] && [ "$kind" = readme ] && [ "$(head -1 "$HARNESS_ROOT/$have" 2>/dev/null)" = "# Universal Harness" ]; then
    warn "$(printf '%-16s' "$label") $have is the harness's own README — not scaffolded: only the owner can describe the project"
    continue
  fi
  if [ -n "$have" ]; then
    info "$(printf '%-16s' "$label") present — $have, left as it is"
    continue
  fi
  files=$(templates_for "$kind")
  case "$kind" in
    license) warn "$(printf '%-16s' "$label") missing — not scaffolded: the licence is the owner's choice (see the skill)"; continue ;;
    readme)  warn "$(printf '%-16s' "$label") missing — not scaffolded: only the owner can describe the project"; continue ;;
    pr_template) warn "$(printf '%-16s' "$label") missing — the harness ships .github/pull_request_template.md; restore it from the harness"; continue ;;
  esac
  for f in $files; do
    [ -f "$TEMPLATES/$f" ] || fail "template missing: .harness/templates/community/$f. Nothing was written."
  done
  # shellcheck disable=SC2086  # $files is a space-separated list of fixed names
  missing=$(needs $files)
  if [ -n "$missing" ]; then
    skipped=$((skipped + 1))
    warn "$(printf '%-16s' "$label") not written: needs $(printf '%s' "$missing" | sed 's/ /, /g')"
    continue
  fi
  for f in $files; do plan+=("$f"); done
done

collide=()
for f in ${plan[@]+"${plan[@]}"}; do
  if [ -e "$HARNESS_ROOT/$f" ] || [ -L "$HARNESS_ROOT/$f" ]; then collide+=("$f"); fi
done
if [ "${#collide[@]}" -gt 0 ]; then
  warn "these paths already exist, and existing files are never overwritten:"
  printf '    %s\n' "${collide[@]}" >&2
  fail "scaffold stopped — nothing was written. Move or remove them deliberately, then re-run."
fi

if [ "${#plan[@]}" -eq 0 ]; then
  if [ "$skipped" -gt 0 ]; then
    ok "nothing written — every missing file still needs a value; pass it with --set KEY=VALUE"
  else
    ok "nothing to scaffold — every community file this harness has a template for is present"
  fi
  exit 0
fi

wrote_security=0
for f in "${plan[@]}"; do
  if [ "$DRY" = 1 ]; then info "would write $f"; continue; fi
  mkdir -p "$HARNESS_ROOT/$(dirname "$f")"
  python3 - "$TEMPLATES/$f" "$HARNESS_ROOT/$f" ${SETS[@]+"${SETS[@]}"} <<'PY'
import sys
src, dest, *pairs = sys.argv[1:]
text = open(src, encoding="utf-8").read()
for kv in pairs:
    k, v = kv.split("=", 1)
    text = text.replace("{{" + k + "}}", v)
# "x" mode: the preflight said this path is free; if that changed, refuse.
with open(dest, "x", encoding="utf-8") as out:
    out.write(text)
PY
  ok "wrote $f"
  [ "$f" != SECURITY.md ] || wrote_security=1
done
[ "$DRY" = 0 ] || { ok "dry run — nothing was written"; exit 0; }

if [ "$wrote_security" = 1 ]; then
  info "If SECURITY.md sends reporters to GitHub's private vulnerability reporting, turn it on"
  info "yourself: Settings → Code security → Private vulnerability reporting. The harness"
  info "does not change repository settings."
fi
info "next: make check-community"
