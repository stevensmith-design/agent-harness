#!/usr/bin/env bash
# Install the harness into an existing repository.
#
#   scripts/install.sh <target-repo>
#
# `cp -R universal-harness/ repo/` was the documented step and it was wrong in
# both directions: with the trailing slash cp NESTS the tree inside the target,
# and the obvious alternative (`cp -R universal-harness/* repo/`) silently drops
# every dotfile — .agents, .claude, .github, .cursor, .githooks, .harness, which
# is two thirds of the harness. It also overwrote the target's own Makefile,
# README.md, CLAUDE.md and .gitignore without asking.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${1:-}"
FORCE=0; [ "${2:-}" = "--force" ] && FORCE=1

c_ok()   { printf '\033[32m✓\033[0m %s\n' "$*"; }
c_warn() { printf '\033[33m!\033[0m %s\n' "$*" >&2; }
c_die()  { printf '\033[31m✗\033[0m %s\n' "$*" >&2; exit 1; }

[ -n "$DEST" ] || c_die "usage: scripts/install.sh <target-repo> [--force]"
[ -d "$DEST" ] || c_die "no such directory: $DEST"
DEST="$(cd "$DEST" && pwd)"
[ "$DEST" != "$SRC" ] || c_die "refusing to install the harness into itself"
git -C "$DEST" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || c_die "target is not a git repository: $DEST
Initialise and commit the project first; the installer needs recoverable history
before it adds governance files."

# --- What ships ----------------------------------------------------------------
#
# Only what the harness's own repository would commit. This used to tar the
# whole directory, and the directory is usually a working checkout — which holds
# things that were never meant to leave it: a .env created by `make env-init`,
# a declared intent naming the maintainer's branch, gate records carrying their
# commit hashes. All of it arrived in someone else's repository, and the .env
# arrived somewhere its owner had no idea it had gone.
#
# In a git checkout the list is exactly what git would commit: tracked files
# plus untracked ones .gitignore does not exclude. Outside git (a downloaded
# archive), the same local state is filtered by name. Regenerated views —
# .claude/skills and .claude/rules, rebuilt by `make setup` — never ship.
LIST=$(mktemp) || c_die "cannot create a temp file"
INSTALL_LIST="$LIST.install"
trap 'rm -f "$LIST" "$INSTALL_LIST" "$INSTALL_LIST.next"' EXIT
if git -C "$SRC" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  ( cd "$SRC" && git -c core.quotePath=false ls-files --cached --others --exclude-standard ) \
    | while IFS= read -r rel; do
        if [ -e "$SRC/$rel" ] || [ -L "$SRC/$rel" ]; then printf '%s\n' "$rel"; fi
      done > "$LIST"
else
  ( cd "$SRC" && find . \( -type f -o -type l \) | sed 's|^\./||' ) > "$LIST"
fi
# In both cases, and whatever .gitignore says: local state by name (an .env of
# any suffix but the sample, at any depth), the harness's own git history, the
# packaged skill, dependencies, and the regenerated views.
awk '$0 == ".env.sample" || $0 ~ /\/\.env\.sample$/ { print; next }
     $0 ~ /(^|\/)\.env(\..*)?$/ { next }
     $0 ~ /^(\.harness-intent|\.agents\/runs\/.*\.jsonl|\.agents\/runs\/\.stubs|\.agents\/runs\/\.stop-.*)$/ { next }
     $0 ~ /^(\.git\/|node_modules\/|\.claude\/skills\/|\.claude\/rules\/)/ || $0 == "harness-init.skill" { next }
     { print }' "$LIST" > "$LIST.f" \
  && cat "$LIST.f" > "$LIST" && rm -f "$LIST.f"
[ -s "$LIST" ] || c_die "found nothing to install in $SRC"

# --- Collision detection ------------------------------------------------------
#
# This used to compare TOP-LEVEL ENTRIES: `ls -A` in the source, `[ -e ]` in the
# target. So a repo with its own `.agents/skills/harness-review/SKILL.md` — six months of
# a team's review conventions — was reported as the single word `.agents`, and
# the advice printed underneath talked about CLAUDE.md, Makefile and README, none
# of which were the thing at risk. Anyone reading that reasonably concluded
# --force would cost them a README. It cost them the skill, silently, and the
# only evidence was behavioural: their review skill started saying something
# else.
#
# Two changes. Collisions are enumerated PER FILE, so the message names what is
# actually at risk. Project-owned files are never overwritten: ordinary shared
# names get a `.harness-candidate` beside the original for manual reconciliation,
# while any deeper collision stops before writing. `--force` is accepted only
# for backwards compatibility and cannot weaken either rule.
if [ -f "$DEST/harness.config.yaml" ]; then
  c_warn "$DEST already contains a harness (harness.config.yaml)."
  c_warn "Installing over it in place is NOT implemented — there is no managed-file"
  c_warn "manifest and no merge, so this would overwrite local edits with no record"
  c_warn "of which were yours. Install into a fresh checkout and diff, or remove the"
  c_warn "existing harness deliberately first."
  c_die "install stopped — nothing was written"
fi

# Files a repository plausibly already has under a name the harness also uses.
# These are genuinely the caller's to reconcile, so the harness copy is written
# beside the original as a visible candidate and is never activated implicitly.
MERGEABLE='^(README\.md|CLAUDE\.md|AGENTS\.md|Makefile|\.gitignore|\.gitattributes|\.prettierignore|\.env\.sample)$'

mergeable=(); foreign=()
while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  [ -e "$DEST/$rel" ] || continue
  # Identical content is not a collision — it is the same file.
  cmp -s "$SRC/$rel" "$DEST/$rel" && continue
  if printf '%s' "$rel" | grep -qE "$MERGEABLE"; then
    mergeable+=("$rel")
  else
    foreign+=("$rel")
  fi
done < "$LIST"

# Foreign collisions stop the install outright. There is deliberately no flag.
# The harness ships skills with ordinary names — review, spec, verify, release —
# and until those are namespaced (docs/decisions/0001-skill-namespace.md) a name
# clash with a team's own work is expected, not exceptional. The right answer is
# for a person to look at both files, which no flag can do for them.
if [ "${#foreign[@]}" -gt 0 ]; then
  c_warn "$DEST already has ${#foreign[@]} file(s) the harness would overwrite, and they are"
  c_warn "not files the harness is entitled to replace:"
  printf '    %s\n' "${foreign[@]}" >&2
  c_warn ""
  c_warn "These are yours. --force does NOT cover them and there is no flag that does."
  c_warn "Rename or move your versions, then re-run. If a skill name is the clash"
  c_warn "(review, spec, verify, release, branch, pr, requirements are the likely ones),"
  c_warn "rename YOURS for now — the harness's are due to be namespaced harness-*."
  c_die "install stopped — nothing was written"
fi

cp "$LIST" "$INSTALL_LIST"
NEEDS_MERGE=0
if [ "${#mergeable[@]}" -gt 0 ]; then
  NEEDS_MERGE=1
  c_warn "existing project files will be preserved byte-for-byte:"
  # Preflight every candidate before writing any of them. A stale candidate for
  # the last file must not leave new candidates for the earlier files behind.
  for m in "${mergeable[@]}"; do
    candidate="$m.harness-candidate"
    [ ! -e "$DEST/$candidate" ] || c_die "merge candidate already exists: $candidate
Review or remove that previous candidate before re-running; it will not be overwritten."
  done
  for m in "${mergeable[@]}"; do
    candidate="$m.harness-candidate"
    mkdir -p "$DEST/$(dirname "$candidate")"
    cp -p "$SRC/$m" "$DEST/$candidate"
    c_warn "  kept $m; wrote $candidate for manual reconciliation"
    awk -v skip="$m" '$0 != skip' "$INSTALL_LIST" > "$INSTALL_LIST.next" \
      && mv "$INSTALL_LIST.next" "$INSTALL_LIST"
  done
  [ "$FORCE" = 0 ] || c_warn "--force is deprecated and does not overwrite project files"
fi

# tar, not cp: dotfiles included, no nesting surprise, and only the listed files.
( cd "$SRC" && tar cf - -T "$INSTALL_LIST" ) | ( cd "$DEST" && tar xf - )

# Same normalisation the .skill package applies, and for the same reason: tar
# preserves the SOURCE tree's modes, so a harness installed from a checkout with
# an odd umask arrives with registers the maintainer cannot edit and gates that
# do not run. 0644 for documents and config, 0755 for anything executable.
#
# Scoped to the files this install actually WROTE, enumerated from the source.
# An earlier version walked $DEST instead, which chmod'd the target repository's
# own files — a tool that quietly changes permissions on work it did not write
# is a tool nobody should run against a repo they care about.
while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  [ -f "$DEST/$rel" ] || continue
  case "$rel" in
    *.sh|*.py) chmod 0755 "$DEST/$rel" 2>/dev/null || true ;;
    *) if head -c2 "$DEST/$rel" 2>/dev/null | grep -q '^#!'; then
         chmod 0755 "$DEST/$rel" 2>/dev/null || true
       else
         chmod 0644 "$DEST/$rel" 2>/dev/null || true
       fi ;;
  esac
done < "$INSTALL_LIST"
# Bash 3 treats an empty array expansion as an unset variable under `set -u`.
for m in ${mergeable[@]+"${mergeable[@]}"}; do
  candidate="$DEST/$m.harness-candidate"
  [ -f "$candidate" ] && chmod 0644 "$candidate" 2>/dev/null || true
done

# This repo is no longer the harness's own. The namespace rule applies to skills
# the HARNESS authors; the target's skills are the target's. Without this flip,
# the namespace gate fails `make check` in every repo that installs the harness,
# telling people to rename work the harness did not write.
"$SRC/scripts/sub.sh" 's/^  authored_here: true$/  authored_here: false/' "$DEST/harness.config.yaml" 2>/dev/null || \
  c_warn "could not clear harness.authored_here in $DEST/harness.config.yaml — set it to false by hand"

# The branch every gate compares against. The config ships `main`; in a
# repository whose default is `master` or `trunk`, the first `make check` failed
# on a merge base that could not exist, and branch hygiene guarded a branch
# nobody uses. Read it from the repository, in order of how much it can be
# trusted: the remote's HEAD, then a conventional local branch, then HEAD itself
# (an unborn repository has only that).
base=""
if git -C "$DEST" rev-parse --git-dir >/dev/null 2>&1; then
  base=$(git -C "$DEST" symbolic-ref --short -q refs/remotes/origin/HEAD 2>/dev/null || true)
  base=${base#origin/}
  if [ -z "$base" ]; then
    for b in main master trunk develop; do
      if git -C "$DEST" show-ref --verify -q "refs/heads/$b"; then base=$b; break; fi
    done
  fi
  [ -n "$base" ] || base=$(git -C "$DEST" symbolic-ref --short -q HEAD 2>/dev/null || true)
fi
if [ -n "$base" ] && [ "$base" != main ]; then
  if printf '%s' "$base" | grep -q -E -e '^[A-Za-z0-9._/-]+$' -- && \
     "$SRC/scripts/sub.sh" "s|^  main_branch: main\$|  main_branch: $base|" "$DEST/harness.config.yaml" 2>/dev/null; then
    c_ok "default branch is '$base' — set git.main_branch to match (check it in harness.config.yaml)"
  else
    c_warn "default branch looks like '$base' — set git.main_branch in harness.config.yaml by hand"
  fi
fi

if [ "$NEEDS_MERGE" = 1 ]; then
  c_warn "HARNESS FILES INSTALLED, BUT PROJECT FILES NEED MANUAL RECONCILIATION."
  c_warn "Nothing that existed before this run was replaced. Review each"
  c_warn "<name>.harness-candidate beside the original, merge only the parts"
  c_warn "this project needs, delete the candidate, then run make setup."
  exit 4
fi

c_ok "harness installed into $DEST"
printf '\n  next:\n'
printf '    cd %s\n' "$DEST"
printf '    git switch -c chore/install-harness   # gates refuse to run on the default branch\n'
printf '    make setup\n'
printf '    make harness-init\n'
printf '    make check\n'
