#!/usr/bin/env bash
# Supply-chain gate. Three cheap deterministic checks that between them close
# the most common ways a repo leaks or executes something it did not intend.
#
#   1. Unpinned third-party CI actions   — a mutable tag is remote code execution
#                                          with your CI token, on someone else's schedule.
#   2. Committed templates holding real values — `.env.sample`, `*.example`,
#                                          `config.example.*` exist to show the SHAPE.
#                                          A real value in one is a leaked secret
#                                          that no .gitignore will ever catch.
#   3. Lockfile presence                 — an unlocked dependency tree resolves
#                                          differently on every machine and in CI.
#
# Configured by the `supply_chain:` block in harness.config.yaml.
. "$(dirname "$0")/../lib.sh"

PIN_POLICY=$(policy supply_chain.require_pinned_actions warn)   # error | warn | off
TEMPLATES=$(cfg supply_chain.template_globs '.env.sample, *.example, *.example.*, .mcp.json.example')
LOCK_POLICY=$(policy supply_chain.require_lockfile warn)

rc=0
soft() { # soft <policy> <message>
  case "$1" in
    error) warn "$2"; rc=1 ;;
    warn)  info "$2" ;;
    off)   : ;;
    # An unrecognised policy used to fall off the end of this case and discard
    # the finding entirely — not even a warning. `policy()` rejects bad values
    # at read time now; this branch is the belt to that pair of braces.
    *)     fail "unrecognised policy '$1' — refusing to decide what it meant" ;;
  esac
}

# --- 1. unpinned actions ------------------------------------------------------
WF="$HARNESS_ROOT/.github/workflows"
if [ -d "$WF" ] && [ "$PIN_POLICY" != "off" ]; then
  unpinned=""
  for f in "$WF"/*.yml "$WF"/*.yaml; do
    [ -f "$f" ] || continue
    while IFS= read -r line; do
      ref=$(printf '%s' "$line" | sed -n 's/.*uses:[[:space:]]*\([^[:space:]#]*\).*/\1/p')
      case "$ref" in */*@*) ;; *) continue ;; esac
      # Local actions (./.github/actions/x) are your own code — not a supply chain.
      case "$ref" in ./*) continue ;; esac
      ver="${ref##*@}"
      if ! printf '%s' "$ver" | grep -qE '^[0-9a-f]{40}$'; then
        unpinned="$unpinned
    $(basename "$f"): $ref"
      fi
    done < <(sgrep -h -e 'uses:' -- "$f")
  done
  if [ -n "$unpinned" ]; then
    soft "$PIN_POLICY" "third-party actions pinned to a mutable tag:${unpinned}
    Run 'make pin-actions' to resolve them to commit SHAs."
  else
    ok "actions pinned"
  fi
fi

# --- 2. templates must contain placeholders, not values -----------------------
# A template's job is to show the shape. The heuristic: a value that looks like
# a real credential (long, high-entropy, not obviously a placeholder) in a file
# whose whole purpose is to be committed.
tracked=$(git -C "$HARNESS_ROOT" ls-files 2>/dev/null) || tracked=""
if [ -n "$tracked" ]; then
  # glob -> anchored ERE. The prefix must be (^|.*/) — an alternation whose
  # first branch is a bare ^ matches every string, which is how a "template
  # only" scan quietly becomes a scan of the whole repo.
  tmpl_re=$(printf '%s' "$TEMPLATES" | tr -d "[]\"'" | tr ',' '\n' | sed 's/^ *//; s/ *$//' \
    | sgrep -v '^$' | sed 's/\./\\./g; s/\*/[^\/]*/g; s|^|(^\|.*/)|; s/$/$/' | paste -sd'|' -)
  files=$(printf '%s\n' "$tracked" | sgrep -E -e "$tmpl_re" --)
  hits=""
  for f in $files; do
    [ -f "$HARNESS_ROOT/$f" ] || { skipped "$f (tracked, not on disk)"; continue; }
    # Prose is not configuration. A .md "example" is documentation.
    case "$f" in *.md|*.txt) continue ;; esac
    # key = value, where value is >=16 chars of credential-ish material and is
    # NOT a placeholder (<...>, ${...}, op://, CHANGEME, xxx, your-, example).
    # A real credential mixes character classes. A hyphenated english word does
    # not — so require at least one digit AND one letter in a >=16-char value,
    # then subtract everything that self-identifies as a placeholder.
    found=$(sgrep -nE -e '^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*[:=][[:space:]]*"?[A-Za-z0-9+/_=-]{16,}"?[[:space:]]*$' -- "$HARNESS_ROOT/$f" \
      | sgrep -E -e '[0-9]' -- \
      | sgrep -E -e '[A-Za-z]' -- \
      | sgrep -ivE -e '(<[^>]*>|\$\{|op://|vault:|changeme|placeholder|example|your[-_]|xxx+|todo|replace|dummy|sample|localhost|0000|aaaa|1234|abcd)' --)
    [ -n "$found" ] && hits="$hits
    $f:$found"
  done
  if [ -n "$hits" ]; then
    warn "committed template appears to hold a real value, not a placeholder:${hits}"
    warn "    A template exists to show the shape. If this value is genuinely public,"
    warn "    add a comment beside it saying why it is safe to commit — otherwise rotate it."
    rc=1
  else
    ok "templates hold placeholders"
  fi
fi

# --- 3. lockfile --------------------------------------------------------------
if [ "$LOCK_POLICY" != "off" ]; then
  have_manifest=0; have_lock=0
  for m in package.json pubspec.yaml pyproject.toml requirements.txt go.mod Cargo.toml Gemfile; do
    [ -f "$HARNESS_ROOT/$m" ] && have_manifest=1
  done
  for l in package-lock.json pnpm-lock.yaml yarn.lock bun.lock bun.lockb pubspec.lock \
           poetry.lock uv.lock requirements.lock go.sum Cargo.lock Gemfile.lock; do
    [ -f "$HARNESS_ROOT/$l" ] && have_lock=1
  done
  if [ "$have_manifest" -eq 1 ] && [ "$have_lock" -eq 0 ]; then
    soft "$LOCK_POLICY" "dependencies are declared but no lockfile is committed — builds are not reproducible"
  elif [ "$have_manifest" -eq 1 ]; then
    ok "lockfile committed"
  fi
fi

blind_spots
[ "$rc" -eq 0 ] || fail "supply chain"
ok "supply chain"
