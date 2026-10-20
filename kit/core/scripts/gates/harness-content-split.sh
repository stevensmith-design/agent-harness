#!/usr/bin/env bash
# harness-content-split.sh — a change may not alter a rule and its enforcement
# at the same time as the work it governs.
#
# The failure this catches is not malice. It is an agent midway through a task,
# blocked by a gate, editing the gate because that is the shortest path to
# green. A change to a rule and its check in one commit looks the same whether
# it tightens or loosens, and nothing in the repo can tell them apart.
#
# DENY BY DEFAULT: `content` is enumerated below and everything else is
# harness. Enumerating protected paths instead would leave every file added
# later unprotected until someone remembered to list it.
#
# Overridable, because every maintenance session must edit the harness and a
# gate that blocks its own maintenance path gets switched off within a day —
# at which point everyone still believes it is running. The escape hatch is
# cheap to use and impossible to use invisibly:
#     ./scripts/declare-harness-change.sh "why"

# shellcheck source=../lib.sh
. "$(dirname "$0")/../lib.sh"
ROOT=$(harness_root "$(dirname "$0")") || exit 1
cd "$ROOT" || exit 1

# What counts as CONTENT. Everything else is harness.
# The journal and the decision log are written DURING the work, by design: a
# correction is noted when it happens, and a decision is recorded before it is
# built on. Treating them as harness would make the gate fire on the habit it
# exists to protect. Promoting either into a rule is still a harness change.
CONTENT_PATHS='^\(runs/\|foundations/\|learning/corpus/\|learning/journal/\|decisions/\|memory/\)'

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  # Workspace substrate: no diff to inspect. The split becomes a declared,
  # logged step in the retro instead — say so rather than printing a tick.
  pass "harness/content split not applicable" "no git; substrate=$(cfg substrate workspace)"
  finish
fi

RANGE=$(comparison_base) || exit 1
CHANGED=$(git diff --name-only "$RANGE"...HEAD 2>/dev/null; git diff --name-only 2>/dev/null; git diff --cached --name-only 2>/dev/null)
CHANGED=$(printf '%s\n' "$CHANGED" | grep -e . -- | sort -u)

n_changed=$(printf '%s\n' "$CHANGED" | nlines)
[ "${n_changed:-0}" -eq 0 ] && { pass "harness/content split" "0 files changed"; finish; }

n_content=$(printf '%s\n' "$CHANGED" | grep -ce "$CONTENT_PATHS" -- 2>/dev/null); case "${n_content:-}" in ''|*[!0-9]*) n_content=0 ;; esac
n_harness=$((n_changed - ${n_content:-0}))

if [ "${n_content:-0}" -gt 0 ] && [ "$n_harness" -gt 0 ]; then
  # A declaration older than a working day is not "this session" any more. It
  # never expired before, so the second use onward was invisible — inside the
  # very mechanism whose header claims the escape hatch is impossible to use
  # invisibly.
  intent=runs/.state/harness-change-declared
  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)
  intent_branch=$(sed -n 's/^branch=//p' "$intent" 2>/dev/null | head -1)
  reason=$(sed -n 's/^reason=//p' "$intent" 2>/dev/null | head -1)
  if [ -n "$(find "$intent" -mmin -480 2>/dev/null)" ] \
     && [ -n "$reason" ] && [ "$current_branch" = "$intent_branch" ]; then
    pass "harness/content split overridden — declared: ${reason:-unstated}" \
         "$n_harness harness, ${n_content} content"
  else
    fail "this change touches $n_harness harness file(s) AND ${n_content} content file(s)."
    [ -f runs/.state/harness-change-declared ] && \
      fail "  (a declaration exists but is over 8 hours old — declare again for this session)"
    fail "  Split them, or declare intent: ./scripts/declare-harness-change.sh \"why\""
  fi
else
  pass "harness/content split" "$n_changed files: $n_harness harness, ${n_content:-0} content"
fi
finish
