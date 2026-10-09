#!/usr/bin/env bash
# Protected-path gate (CI half — the hook is the local half).
# Fails when a PR touches the harness alongside product code, which is how a
# harness gets quietly relaxed to make a red gate go green.
. "$(dirname "$0")/../lib.sh"

# The configured main branch, not a literal `main`: a repository whose default is
# `master` otherwise never has a base ref here, and this gate reports a skip forever.
BASE="${1:-${GITHUB_BASE_REF:-origin/$(cfg git.main_branch main)}}"
git -C "$HARNESS_ROOT" rev-parse --verify "$BASE" >/dev/null 2>&1 || { ok "protected paths (no base ref '$BASE')"; exit 0; }

# changed_files(): repo-relative -> harness-relative, C-quoting undone. A
# harness installed in a monorepo subdirectory saw `packages/app/...` on every
# line, matched nothing, and passed everything.
changed=$(changed_files "$BASE")
[ -n "$changed" ] || { ok "protected paths (no changes)"; exit 0; }

# Deny by default: classify by the INVERSE of an allowlist. Enumerating protected
# paths means every path added later is silently unprotected — the harness grows,
# and the gate quietly stops covering the new parts. Listing what is *product*
# code instead means anything new defaults to protected and someone has to say so.
# The root-file branch used to be a blanket `^[^/]+\.(md|json|lock|txt)$`, which
# classified AGENTS.md, CLAUDE.md and skills-lock.json — the rulebook itself and
# the supply-chain pin — as PRODUCT code. The gate that exists to stop an agent
# relaxing its own constraints did not cover its own constraints. Root files are
# now allowlisted by name, and the rulebook is not on the list.
PRODUCT='^(src/|lib/|app/|test/|tests/|assets/|public/|migrations/|specs/|docs/(devlog|incidents|product|architecture|api-proposal)/)|^(README|CHANGELOG|LICENSE|CONTRIBUTING|SECURITY)(\.md)?$|^(package|pubspec|pyproject|go|Cargo|composer)\.(json|yaml|toml|mod|lock)$|^[^/]*\.(lock|txt)$|^\.(gitignore|gitattributes|editorconfig|nvmrc|prettierignore|prettierrc.*|eslintrc.*|env\.sample)$'
other=$(printf '%s\n' "$changed" | sgrep -E -e "$PRODUCT" --)
prot=$(printf '%s\n' "$changed" | sgrep -Ev -e "$PRODUCT" --)

if [ -n "$prot" ] && [ -n "$other" ]; then
  warn "this change edits the harness AND product code in one PR:"
  printf '%s\n' "$prot" | sed 's/^/    harness: /'
  warn "split it, or add 'harness-change: intentional' to the PR body."
  # Both sides need the default. The right-hand expansion had none, so under
  # `set -u` this line died with a raw shell error the moment the gate actually
  # detected something — which is proof it had never once been executed.
  _pb="${PR_BODY:-}"
  if [ "$_pb" != "${_pb#*harness-change: intentional}" ]; then
    ok "protected paths (override acknowledged)"; exit 0
  fi
  fail "protected paths gate"
fi
ok "protected paths"
