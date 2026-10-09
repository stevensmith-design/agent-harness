#!/usr/bin/env bash
# Branch-hygiene gate. Makes .agents/rules/git-flow.md checkable instead of
# merely written down. Rules are data — they live in the `git:` block of
# harness.config.yaml, so changing the convention never means editing this file.
#
# Checks, in order of how much they hurt when violated:
#   1. not working directly on the protected main branch
#   2. branch name matches the convention
#   3. commit subjects on this branch match the convention
#   4. the branch has not grown past the point of being reviewable
. "$(dirname "$0")/../lib.sh"

git -C "$HARNESS_ROOT" rev-parse --git-dir >/dev/null 2>&1 || { ok "branch hygiene (not a git repo)"; exit 0; }

MAIN=$(cfg git.main_branch main)
PATTERN=$(cfg git.branch_pattern '')
COMMIT_PATTERN=$(cfg git.commit_pattern '')
MAX_AHEAD=$(cfg git.max_commits_ahead 0)
PROTECT=$(cfg git.protect_main true)
EXEMPT=$(cfg git.branch_exempt '' | tr -d "[]\"'" | tr ',' ' ')

BRANCH=$(git -C "$HARNESS_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')
[ -n "$BRANCH" ] && [ "$BRANCH" != "HEAD" ] || { ok "branch hygiene (detached HEAD — nothing to check)"; exit 0; }

rc=0

# A CI run triggered by a push to the default branch is looking at a MERGE
# RESULT, not at someone working on main. Failing there made the harness's own
# generated CI fail on every merge, and made the documented first `make check`
# (run on main, right after init) impossible to pass.
if [ "$BRANCH" = "$MAIN" ] && [ -n "${CI:-}" ] && [ "${GITHUB_EVENT_NAME:-push}" = "push" ]; then
  ok "branch hygiene (post-merge run on $MAIN)"
  exit 0
fi

# 1. Working directly on main.
if [ "$PROTECT" = "true" ] && [ "$BRANCH" = "$MAIN" ]; then
  if ! git -C "$HARNESS_ROOT" diff --quiet HEAD 2>/dev/null; then
    warn "uncommitted changes on '$MAIN'. Cut a branch: see .agents/skills/harness-branch/SKILL.md"
    rc=1
  else
    warn "you are on '$MAIN'. Start work on a branch, not here."
    rc=1
  fi
fi

# 2. Branch name.
exempt=0
for e in $EXEMPT; do [ "$BRANCH" = "$e" ] && exempt=1; done
if [ "$exempt" = 0 ] && [ -n "$PATTERN" ]; then
  if printf '%s' "$BRANCH" | grep -qE -e "$PATTERN" --; then
    :
  else
    warn "branch '$BRANCH' does not match the convention: $PATTERN"
    warn "  e.g. feat/PROJ-118-leave-workspace  ·  fix/PROJ-204-expired-invite"
    rc=1
  fi
fi

# 3 & 4 need a base to compare against; skip cleanly when there is none.
BASE=""
for ref in "origin/$MAIN" "$MAIN"; do
  git -C "$HARNESS_ROOT" rev-parse --verify --quiet "$ref" >/dev/null 2>&1 && { BASE="$ref"; break; }
done

if [ -n "$BASE" ] && [ "$BRANCH" != "$MAIN" ]; then
  RANGE="$BASE..HEAD"
  # `|| echo 0` here was the quiet one: a range git cannot resolve produced a
  # count of 0, which skipped the commit-subject check AND the ahead-of-base
  # check, and the gate reported clean. Zero commits and "I could not count"
  # must not be the same value.
  count=$(must "git rev-list --count $RANGE" git -C "$HARNESS_ROOT" rev-list --count "$RANGE")

  if [ -n "$COMMIT_PATTERN" ] && [ "$count" -gt 0 ]; then
    subjects=$(must "git log $RANGE" git -C "$HARNESS_ROOT" log --format='%s' "$RANGE")
    bad=$(printf '%s\n' "$subjects" | sgrep -vE -e "$COMMIT_PATTERN" -- | sgrep -vE -e '^(Merge|Revert) ' --)
    if [ -n "$bad" ]; then
      warn "commit subjects do not match the convention:"
      printf '%s\n' "$bad" | head -10 | sed 's/^/    /'
      warn "  expected: <type>(<scope>): <imperative summary>   e.g. feat(settings): let a member leave a workspace"
      rc=1
    fi
  fi

  if [ "$MAX_AHEAD" -gt 0 ] && [ "$count" -gt "$MAX_AHEAD" ]; then
    warn "branch is $count commits ahead of $BASE (limit $MAX_AHEAD). This is a spec that should have been split."
    rc=1
  fi
fi

[ "$rc" -eq 0 ] || fail "branch hygiene — see .agents/rules/git-flow.md"
ok "branch hygiene ($BRANCH)"
