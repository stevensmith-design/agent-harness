#!/usr/bin/env bash
# install.sh — copy the core template into a target project WITHOUT destroying it.
#
# The documented install used to be `cp -R core/. .`, which silently overwrote
# README.md, AGENTS.md, .gitignore and .claude/settings.json in any project that
# already had them. The build procedure said, four paragraphs earlier, that
# those exact files "get merged, never silently overwritten". On a git
# substrate that is recoverable; in a workspace it is not.
#
# So: nothing is ever overwritten. Colliding files are staged beside the target
# for a human to merge, and named in the report. A merge you were told about is
# work; a merge you were not told about is data loss.

set -uo pipefail
KIT="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1-}"

RED=$'\033[31m'; GRN=$'\033[32m'; YEL=$'\033[33m'; DIM=$'\033[2m'; RST=$'\033[0m'
[ -t 1 ] || { RED=""; GRN=""; YEL=""; DIM=""; RST=""; }

[ -n "$TARGET" ] || { printf 'usage: %s /path/to/target-project\n' "$0" >&2; exit 2; }
[ -d "$TARGET" ] || { printf '%s✗ %s is not a directory%s\n' "$RED" "$TARGET" "$RST" >&2; exit 1; }
TARGET="$(cd "$TARGET" && pwd)"
[ "$TARGET" = "$KIT" ] && { printf '%s✗ refusing to install the kit into itself%s\n' "$RED" "$RST" >&2; exit 1; }

# Root-only, deliberately. Surface patterns and the harness/content split gate
# both resolve from the harness root, so a subdirectory install goes green while
# being unable to classify the work it governs — a false green in the gate that
# exists to prevent false greens.
GITROOT="$(git -C "$TARGET" rev-parse --show-toplevel 2>/dev/null || true)"
if [ -n "$GITROOT" ] && [ "$GITROOT" != "$TARGET" ]; then
  printf '%s✗ %s is inside the repository %s, not its root.%s\n' "$RED" "$TARGET" "$GITROOT" "$RST" >&2
  printf '  A harness installed below the repo root cannot classify the work it governs:\n' >&2
  printf '  surface patterns resolve from the harness root and match nothing, and the\n' >&2
  printf '  harness/content split gate compares repo-relative paths and never fires.\n' >&2
  printf '  Install at %s instead — collisions are staged, not overwritten.\n' "$GITROOT" >&2
  exit 1
fi

cd "$KIT/core" || exit 1
FILES=$(find . -type f -not -name '.DS_Store' | sed 's|^\./||' | sort)

collisions=""; n_new=0; n_col=0
for f in $FILES; do
  if [ -e "$TARGET/$f" ]; then collisions="$collisions $f"; n_col=$((n_col + 1)); else n_new=$((n_new + 1)); fi
done

printf '\n%sharness-kit → %s%s\n' "$DIM" "$TARGET" "$RST"
printf '  %s new file(s), %s collision(s)\n\n' "$n_new" "$n_col"

if [ "$n_col" -gt 0 ]; then
  printf '%sThese already exist and will NOT be touched:%s\n' "$YEL" "$RST"
  for f in $collisions; do printf '    %s\n' "$f"; done
  printf '\n'
fi

printf 'Proceed? (y/N) '
read -r reply
case "$reply" in y|Y) ;; *) printf 'cancelled — nothing written\n'; exit 0 ;; esac

# Copy only what does not exist.
for f in $FILES; do
  [ -e "$TARGET/$f" ] && continue
  mkdir -p "$TARGET/$(dirname "$f")"
  cp "$KIT/core/$f" "$TARGET/$f"
done
find "$TARGET/scripts" -name '*.sh' -exec chmod +x {} \; 2>/dev/null

# Stage collisions for a human to merge. Never merged automatically: two of
# these are rule files, and merging rules by machine is how you get a harness
# asserting two different things with nothing reporting a conflict.
if [ "$n_col" -gt 0 ]; then
  STAGE="$TARGET/.harness-incoming"
  for f in $collisions; do
    mkdir -p "$STAGE/$(dirname "$f")"
    cp "$KIT/core/$f" "$STAGE/$f"
  done
  printf '%s✓%s copied %s file(s)\n' "$GRN" "$RST" "$n_new"
  printf '%s!%s %s collision(s) staged at .harness-incoming/ — merge by hand:\n' "$YEL" "$RST" "$n_col"
  for f in $collisions; do
    case "$f" in
      AGENTS.md) printf '    %-26s your rules are canonical. Fold the kit'"'"'s sections in; keep yours.\n' "$f" ;;
      README.md) printf '    %-26s yours stays. The kit'"'"'s is about the template, not your project.\n' "$f" ;;
      .gitignore) printf '    %-26s append the kit'"'"'s block; do not replace yours.\n' "$f" ;;
      .claude/settings.json) printf '    %-26s merge the hooks key into your existing settings.\n' "$f" ;;
      *) printf '    %s\n' "$f" ;;
    esac
  done
  printf '\n  Delete .harness-incoming/ when done — doctor flags it as residue.\n'
else
  printf '%s✓%s copied %s file(s), nothing overwritten\n' "$GRN" "$RST" "$n_new"
fi

# Where it lives decides what can enforce anything. Record the fact the target
# already makes true — no git means a folder harness — rather than leaving a
# template default that later fails as "repository with no git". Only in a
# harness.yaml this run created; an existing one is the owner's.
if [ -z "$GITROOT" ] && ! printf '%s\n' "$collisions" | tr ' ' '\n' | grep -qx 'harness.yaml'; then
  sed 's/^substrate:[[:space:]]*repository/substrate: workspace/' "$TARGET/harness.yaml" > "$TARGET/.harness.yaml.tmp" \
    && mv "$TARGET/.harness.yaml.tmp" "$TARGET/harness.yaml"
  printf '\n%sNo git here — set substrate: workspace.%s\n' "$YEL" "$RST"
  printf '  There is no commit to check at, so scripts/checkpoint.sh stands in for it: when the AI\n'
  printf '  finishes (in tools that run hooks) and as the last step of every procedure.\n'
  printf '  Shared drive, Notion, SharePoint and the rest: see platforms/README.md in the kit.\n'
  printf '  Some harness files start with a dot (.claude, .gitignore, .pii-allow) and are hidden by\n'
  printf '  default — Finder: Cmd+Shift+. · File Explorer: View > Show > Hidden items.\n'
fi

printf '\nNext: cd %s && bash scripts/doctor.sh\n\n' "$TARGET"
