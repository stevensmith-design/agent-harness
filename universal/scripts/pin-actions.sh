#!/usr/bin/env bash
# Resolve every `uses: owner/repo@tag` in .github/workflows/ to the commit SHA
# that tag currently points at, and rewrite it as `owner/repo@<sha> # tag`.
#
# Why: a tag is mutable. Whoever controls the action can move `v4` to new code,
# and that code runs inside your CI with whatever token the job holds. A SHA
# cannot be moved. The trailing comment keeps it readable and tells the next
# person what to re-resolve.
#
#   scripts/pin-actions.sh            # rewrite in place
#   scripts/pin-actions.sh --check    # report what is unpinned, change nothing
#
# Re-run deliberately when you want to take an action's updates — pinning means
# you now own that decision, so pair it with Dependabot or a calendar reminder.
. "$(dirname "$0")/lib.sh"

CHECK=0; [ "${1:-}" = "--check" ] && CHECK=1
WF="$HARNESS_ROOT/.github/workflows"
[ -d "$WF" ] || { ok "no workflows to pin"; exit 0; }

command -v git >/dev/null 2>&1 || fail "git is required"

resolve() { # resolve <owner/repo> <tag> -> sha on stdout
  local repo="$1" tag="$2" out sha
  out=$(git ls-remote --tags "https://github.com/$repo.git" "$tag" "$tag^{}" 2>/dev/null) || return 1
  # ^{} is the peeled commit of an annotated tag — that is what actually runs.
  sha=$(printf '%s\n' "$out" | awk -v t="refs/tags/$tag^{}" '$2==t{print $1}')
  [ -n "$sha" ] || sha=$(printf '%s\n' "$out" | awk -v t="refs/tags/$tag" '$2==t{print $1}')
  [ -n "$sha" ] || return 1
  printf '%s' "$sha"
}

changed=0; unpinned=0
for f in "$WF"/*.yml "$WF"/*.yaml; do
  [ -f "$f" ] || continue
  while IFS= read -r line; do
    ref=$(printf '%s' "$line" | sed -n 's/.*uses:[[:space:]]*\([^[:space:]#]*\).*/\1/p')
    case "$ref" in
      */*@*) ;;
      *) continue ;;
    esac
    repo="${ref%@*}"; ver="${ref##*@}"
    # Already a 40-hex SHA: nothing to do.
    case "$ver" in
      [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]*)
        [ "${#ver}" -eq 40 ] && continue ;;
    esac
    unpinned=$((unpinned + 1))
    if [ "$CHECK" -eq 1 ]; then
      warn "unpinned: $repo@$ver in $(basename "$f")"
      continue
    fi
    if sha=$(resolve "$repo" "$ver"); then
      esc_repo=$(printf '%s' "$repo" | sed 's/[\/&]/\\&/g')
      sed -i.bak "s|uses:[[:space:]]*$esc_repo@$ver|uses: $esc_repo@$sha # $ver|" "$f" && rm -f "$f.bak"
      ok "$repo@$ver -> $sha"
      changed=$((changed + 1))
    else
      warn "could not resolve $repo@$ver — left unpinned (no network, or the tag does not exist)"
    fi
  done < <(sgrep -n -e 'uses:' -- "$f")
done

if [ "$CHECK" -eq 1 ]; then
  [ "$unpinned" -eq 0 ] && ok "all actions pinned to a SHA" || warn "$unpinned unpinned action reference(s)"
  exit 0
fi
[ "$changed" -gt 0 ] && ok "pinned $changed action reference(s) — commit this" || ok "nothing to pin"
