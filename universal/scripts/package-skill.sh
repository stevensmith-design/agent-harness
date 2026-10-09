#!/usr/bin/env bash
# Build harness-init.skill from the current tree.
#
# The .skill bundles a full copy of the harness in assets/, which means it is a
# BUILD ARTIFACT, not a source file. Left lying around it goes stale the moment
# the harness changes — and a stale installer silently scaffolds an old harness
# into a new repo, which is worse than having no installer at all.
#
# So: build it when you need one, save it to your agent account, delete the file.
# Never edit the .skill; edit the harness and rebuild.
#
#   scripts/package-skill.sh [output.skill]
. "$(dirname "$0")/lib.sh"

OUT="${1:-$HARNESS_ROOT/harness-init.skill}"
command -v zip >/dev/null 2>&1 || fail "zip is required"

# Refuse to package a harness that does not pass its own checks. Shipping an
# installer built from a broken tree is how the break propagates to every repo
# that installs it.
"$HARNESS_ROOT/scripts/harness-sync.sh" --check >/dev/null 2>&1 \
  || fail "generated tool files have drifted — run 'make harness-sync' first"
"$HARNESS_ROOT/scripts/ci-gen.sh" --check >/dev/null 2>&1 \
  || fail "generated CI files have drifted — run 'make ci-gen' first"
"$HARNESS_ROOT/scripts/gates/instruction-budget.sh" >/dev/null \
  || fail "instruction budgets exceeded — fix before packaging"
"$HARNESS_ROOT/scripts/gates/rule-coverage.sh" >/dev/null 2>&1 \
  || warn "rule-coverage is not clean — packaging anyway (a template legitimately has unmatched globs)"

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
pkg="$tmp/harness-init"
mkdir -p "$pkg/assets" "$pkg/references"

# The portable SKILL.md is the harness's own harness-init skill, plus the
# install-from-scratch preamble it needs when the harness is not there yet.
src="$HARNESS_ROOT/.agents/skills/harness-init/SKILL.md"
[ -f "$src" ] || fail "no harness-init skill to package"
version=$(cfg harness.version 0.0.0)

python3 - "$src" "$pkg/SKILL.md" "$version" <<'PYEOF'
import re, sys
src, dst, version = sys.argv[1], sys.argv[2], sys.argv[3]
text = open(src).read()
m = re.match(r'^---\n(.*?)\n---\n(.*)$', text, re.S)
if not m:
    sys.exit("packaged skill has no frontmatter")
fm, body = m.group(1), m.group(2)

# The description is the only thing an agent sees before deciding to load the
# skill, so the packaged variant must say that it carries the scaffold.
DESC = ('description: Install or adapt a stack-agnostic AI-agent development harness into a '
        'repository — instruction graph, path-scoped rules, portable skills, one command surface, '
        'deterministic gates, hooks, permission tiers, generated CI/CD, and opt-in governance and '
        'evals. The full scaffold is bundled in assets/. Use when setting up agent tooling in a new '
        'or existing repo, hardening a repo where agents repeat the same mistakes, or consolidating '
        'scattered agent rules (CLAUDE.md, .cursorrules, copilot-instructions) into one owned source.')

out, seen_desc, stamped = [], False, False
for line in fm.split('\n'):
    if line.startswith('description:'):
        out.append(DESC); seen_desc = True; continue
    # a folded/continued description line belongs to the key we just replaced
    if seen_desc and (line.startswith((' ', '\t')) and ':' not in line.split('#')[0]):
        continue
    seen_desc = False
    out.append(line)
    if line.rstrip() == 'metadata:':
        out.append(f'  harness.version: "{version}"')
        stamped = True
if not stamped:
    out.append('metadata:'); out.append(f'  harness.version: "{version}"')

fm = '\n'.join(l for l in out if l.strip() != '')
preamble = ("\n> **This package carries the whole scaffold** in `assets/universal-harness/`.\n"
            "> Copy it into the target repo, then follow the phases below. Reference material\n"
            "> for the decisions each phase asks you to make is in `references/`.\n")
open(dst, 'w').write(f"---\n{fm}\n---\n{preamble}{body}")
PYEOF

cp -R "$HARNESS_ROOT" "$pkg/assets/universal-harness"
rm -rf "$pkg/assets/universal-harness/.git" "$pkg/assets/universal-harness/harness-init.skill"
# Symlinks do not survive archive extraction on every filesystem; `make setup`
# recreates them, and a broken symlink is a silently missing skill.
find "$pkg/assets/universal-harness/.claude/skills" "$pkg/assets/universal-harness/.claude/rules" \
     -maxdepth 1 -type l -delete 2>/dev/null || true

for f in HARNESS-GUIDE.md:harness-design-guide HARNESS-MANIFEST.md:file-map-and-checklist \
         docs/security.md:security-tiering docs/ci-cd.md:ci-cd docs/skills-catalog.md:skills-catalog; do
  cp "$HARNESS_ROOT/${f%%:*}" "$pkg/references/${f##*:}.md"
done

# Build to a temp path and move into place. Deleting the target first fails on
# any filesystem that disallows unlink (network mounts, some sandboxes) and
# leaves a 0-byte file behind — an artifact that looks built and is not.
# Normalise modes before archiving. `cp -R` and `zip` carry whatever the
# BUILDER's tree happened to have, so the v1.13.0 .skill shipped a spread of
# 644/755/600/444/555/711 — including docs/api-proposal/AGREEMENTS.md and
# docs/product/domain-rules.md at 0444, two registers a human is supposed to
# EDIT, arriving read-only in every repo that installed it.
#
# A file's mode inside a release archive is a fact about the SHIPPED artifact,
# not about whoever ran the build. So it is set here rather than hoped for.
# git cannot do this for us: it records the executable bit and nothing else.
normalise_modes() {  # normalise_modes <dir>
  find "$1" -type d -exec chmod 0755 {} +
  find "$1" -type f -exec chmod 0644 {} +
  find "$1" -type f \( -name '*.sh' -o -name '*.py' \) -exec chmod 0755 {} +
  # Executables without an extension — .githooks/pre-commit is the one that
  # matters, and it is the one a naive *.sh rule would have missed.
  find "$1" -type f ! -name '*.sh' ! -name '*.py' -exec sh -c \
    'head -c2 "$1" 2>/dev/null | grep -q "^#!" && chmod 0755 "$1"' _ {} \;
}
normalise_modes "$pkg"

( cd "$tmp" && zip -qry "$tmp/out.skill" harness-init ) || fail "zip failed"
mv -f "$tmp/out.skill" "$OUT" || fail "could not write $OUT"
[ -s "$OUT" ] || fail "wrote an empty archive to $OUT"
ok "built $(basename "$OUT")  (harness $version, $(ls -d "$pkg/assets/universal-harness/.agents/skills/"*/ | wc -l | tr -d ' ') skills, $(du -h "$OUT" | cut -f1))"
info "save it to your agent account, then delete the file — rebuild with 'make harness-package'"
