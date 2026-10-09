#!/usr/bin/env bash
# Check that this machine has what the harness needs, and say exactly what to do
# about anything missing.
#
# It never installs anything. A setup script that silently installs software is
# one people stop running — and on a shared or managed machine it is the wrong
# thing to do regardless. Report, and let the person decide.
#
#   scripts/doctor.sh            # report
#   scripts/doctor.sh --strict   # non-zero exit if anything REQUIRED is missing
. "$(dirname "$0")/lib.sh"

STRICT=0; [ "${1:-}" = "--strict" ] && STRICT=1

# Read a tooling list (required|optional) out of the config: name/why/install.
tool_list() {
  KIND="$1" awk '
    /^tooling:/ {inT=1; next}
    # Leaving tooling: must also close the list, or the next section (deploy:)
    # has its own `- name:` entries read as tools.
    /^[^[:space:]#]/ {inT=0; inK=0}
    inT && $0 ~ "^[[:space:]]+"ENVIRON["KIND"]":" {inK=1; next}
    inT && inK && /^[[:space:]]{2}[a-z_]+:/ {inK=0}
    inK && /^[[:space:]]*-[[:space:]]*name:/ {
      if (n!="") print n "\t" w "\t" i
      n=$0; sub(/.*name:[[:space:]]*/,"",n); gsub(/^ +| +$/,"",n); w=""; i=""; next
    }
    inK && /^[[:space:]]*why:/     { w=$0; sub(/^[[:space:]]*why:[[:space:]]*/,"",w); next }
    inK && /^[[:space:]]*install:/ { i=$0; sub(/^[[:space:]]*install:[[:space:]]*/,"",i); gsub(/^"|"$/,"",i); next }
    END { if (n!="") print n "\t" w "\t" i }
  ' "$CONFIG"
}

missing_required=0; missing_optional=0
check() {  # check <kind>
  local kind="$1"
  while IFS=$'\t' read -r name why install; do
    [ -n "$name" ] || continue
    if command -v "$name" >/dev/null 2>&1; then
      ok "$name"
    else
      if [ "$kind" = required ]; then
        warn "$name — MISSING ($why)"; missing_required=$((missing_required+1))
      else
        info "$name — not installed; $why will not work"; missing_optional=$((missing_optional+1))
      fi
      [ -n "$install" ] && printf '      install: %s\n' "$install"
    fi
  done < <(tool_list "$kind")
}

# A python module cannot be found with `command -v`, so a gate that imports one
# has no way to declare it in the lists above. It got declared nowhere instead,
# and the first person without it met a stack trace from a gate rather than a
# sentence from doctor. Checked with a real import, because "pip3 show" lies
# when several pythons are installed and the gate runs under a different one.
check_modules() {
  local any=0
  while IFS=$'\t' read -r name why install; do
    [ -n "$name" ] || continue
    any=1
    if command -v python3 >/dev/null 2>&1 && python3 -c "import $name" >/dev/null 2>&1; then
      ok "python module: $name"
    else
      warn "python module: $name — MISSING ($why)"
      missing_required=$((missing_required+1))
      [ -n "$install" ] && printf '      install: %s\n' "$install"
    fi
  done < <(tool_list python_modules)
  [ "$any" = 1 ] || info "none declared"
}

info "required"; check required
echo; info "optional"; check optional
echo; info "python modules (required)"; check_modules

# The stack's own toolchain is the adapter's business, not ours — but a missing
# one is the most common reason `make check` fails confusingly on a new machine.
echo; info "stack toolchain (adapter: $(cfg harness.adapter generic))"
load_adapter
if declare -f cmd_deps >/dev/null; then
  case "$(cfg harness.adapter generic)" in
    react-web|react-native|node-api) command -v node >/dev/null 2>&1 \
      && ok "node $(node --version 2>/dev/null)" || warn "node — MISSING; the adapter cannot run" ;;
    python-api) command -v python3 >/dev/null 2>&1 \
      && ok "python3 $(python3 --version 2>&1 | cut -d' ' -f2)" || warn "python3 — MISSING" ;;
    flutter) command -v flutter >/dev/null 2>&1 || command -v fvm >/dev/null 2>&1 \
      && ok "flutter toolchain present" || warn "flutter/fvm — MISSING" ;;
    *) info "generic adapter — nothing to check" ;;
  esac
fi

# Harness wiring that people forget and then debug for twenty minutes.
echo; info "harness wiring"
[ "$(git -C "$HARNESS_ROOT" config core.hooksPath 2>/dev/null)" = ".githooks" ] \
  && ok "git hooks installed" || { warn "git hooks not installed — run 'make install-hooks'"; }
[ -n "$(find "$HARNESS_ROOT/.claude/skills" -mindepth 1 -maxdepth 1 -type l 2>/dev/null)" ] \
  && ok "skills linked" || warn "skills not linked — run 'make link-skills'"
[ -f "$HARNESS_ROOT/.env" ] && ok ".env present" || info ".env missing — run 'make env-init'"
# Check the VALUES, not a substring of the file: the literal text <product> in a
# comment used to read as "not configured", and a real unfilled <stack> that had
# been left in a value read as configured.
unfilled=""
for k in project.name project.stack project.src project.tests; do
  case "$(cfg "$k" '<unset>')" in *'<'*'>'*) unfilled="$unfilled $k" ;; esac
done
if [ -n "$unfilled" ]; then
  warn "harness.config.yaml still holds placeholders:$unfilled"
  warn "    Run 'make harness-init', then fill the rest by hand. A placeholder in"
  warn "    project.stack is copied verbatim into AGENTS.md and read by every agent."
else
  ok "harness configured"
fi
[ -f "$HARNESS_ROOT/.mcp.json" ] && ok ".mcp.json present" \
  || info "no .mcp.json — copy .mcp.json.example if this project needs MCP servers"

echo
if [ "$missing_required" -gt 0 ]; then
  warn "$missing_required required tool(s) missing"
  # `[ "$STRICT" = 1 ] && exit 1` as the last command returns 1 when STRICT=0,
  # which became the script's exit status and aborted `make setup` on the first
  # missing CLI. The header documents the opposite: plain run reports, --strict
  # exits non-zero.
  if [ "$STRICT" = 1 ]; then exit 1; fi
elif [ "$missing_optional" -gt 0 ]; then
  ok "everything required is present ($missing_optional optional missing)"
else
  ok "everything present"
fi
