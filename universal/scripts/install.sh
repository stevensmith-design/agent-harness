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
trap 'rm -f "$LIST"' EXIT
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
# Two changes. Collisions are now enumerated PER FILE, so the message names what
# is actually at risk. And --force no longer means "overwrite everything": it
# covers only the files a repository legitimately shares a NAME with the harness
# over, and it takes a backup of each. Anything else refuses with or without the
# flag, because a flag that can destroy work you did not author is not a
# confirmation, it is a trapdoor.
if [ -f "$DEST/harness.config.yaml" ]; then
  c_warn "$DEST already contains a harness (harness.config.yaml)."
  c_warn "Installing over it in place is NOT implemented — there is no managed-file"
  c_warn "manifest and no merge, so this would overwrite local edits with no record"
  c_warn "of which were yours. Install into a fresh checkout and diff, or remove the"
  c_warn "existing harness deliberately first."
  c_die "install stopped — nothing was written"
fi

# Files a repository plausibly already has under a name the harness also uses.
# These are genuinely the caller's to decide about, which is what --force is for.
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

if [ "${#mergeable[@]}" -gt 0 ] && [ "$FORCE" = 0 ]; then
  c_warn "these already exist in $DEST and differ from the harness's copies:"
  printf '    %s\n' "${mergeable[@]}" >&2
  c_warn ""
  c_warn "Your CLAUDE.md, Makefile or README are not the harness's to replace."
  c_warn "Move or merge them first, then re-run. To overwrite anyway: --force"
  c_warn "(--force keeps a <name>.pre-harness copy of each, so nothing is lost.)"
  c_die "install stopped — nothing was written"
fi

# --force overwrites the mergeable set, but never without a copy. A confirmation
# flag that leaves no way back is a flag people learn to fear rather than read.
if [ "${#mergeable[@]}" -gt 0 ]; then
  for m in "${mergeable[@]}"; do
    cp -p "$DEST/$m" "$DEST/$m.pre-harness"
    c_warn "backed up $m -> $m.pre-harness"
  done
fi

# tar, not cp: dotfiles included, no nesting surprise, and only the listed files.
( cd "$SRC" && tar cf - -T "$LIST" ) | ( cd "$DEST" && tar xf - )

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
done < "$LIST"

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

c_ok "harness installed into $DEST"
printf '\n  next:\n'
printf '    cd %s\n' "$DEST"
printf '    git switch -c chore/install-harness   # gates refuse to run on the default branch\n'
printf '    make setup\n'
printf '    make harness-init\n'
printf '    make check\n'
