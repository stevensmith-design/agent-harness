#!/usr/bin/env bash
# Evidence gate — the CI half of `.claude/hooks/gate-done.sh`.
#
# The harness's definition of done ends with "evidence exists in .agents/runs/".
# Until now the only thing enforcing that was a Claude Code Stop hook: one tool,
# one machine, and switched off by deleting a line from settings.json. Everyone
# using Cursor, Copilot or a plain terminal was subject to a rule nothing checked,
# and the repo looked compliant either way.
#
# Local runs WARN. CI FAILS. That asymmetry is deliberate and is the same shape
# the hooks use: a check that shouts at you during exploratory work gets disabled
# within a week, and a disabled check enforces nothing. Make the fast one kind and
# the unavoidable one strict.
#
# `.agents/runs/*.jsonl` is gitignored, so this reads what THIS pipeline produced,
# not repo history. What it catches is a job that reported green without running
# the steps that emit evidence.
. "$(dirname "$0")/../lib.sh"

RUNS="$HARNESS_ROOT/.agents/runs"
branch=$(git -C "$HARNESS_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || printf '-')
commit=$(git -C "$HARNESS_ROOT" rev-parse HEAD 2>/dev/null || printf '-')

shopt -s nullglob
records=("$RUNS"/*.jsonl)
shopt -u nullglob

complain() {  # complain <message...>
  if strict; then   # CI, or a readiness point (HARNESS_STRICT=1) — lib.sh
    warn "$*"
    warn "    'make verify' emits a record. A pipeline that reports success without"
    warn "    one has not shown its work — which is the rule this harness opens with."
    fail "evidence"
  fi
  warn "$*"
  info "  Local run: warning only. CI and readiness points fail on this — run 'make verify' before opening the PR."
  exit 0
}

[ "${#records[@]}" -gt 0 ] || complain "no evidence records in .agents/runs/ for this run."

# For THIS commit, not merely for this branch: a record from an earlier commit on
# the same branch is evidence about code that has since changed.
# grep -l lists the files that match; scount then counts those lines. (`scount -l`
# is grep -c -l, which prints names, not a number — it read as a valid count and
# tripped `[: integer expression expected`.)
# Built as a variable so the grep argument carries no backslash-escaped quotes:
# the BSD-grep lint's scanner reads `\"` as a string terminator and flags the
# line as a bare pattern. Correct code that trips a lint gets the lint disabled.
AT_COMMIT='"commit":"'"$commit"'"'
hits=$(sgrep -l -e "$AT_COMMIT" -- "${records[@]}" | scount .)
if [ "${hits:-0}" -eq 0 ]; then
  complain "evidence exists, but none of it was recorded at $commit (branch '$branch')."
fi

# An evidence record saying `fail` is still evidence — of a failure.
bad=$(sgrep -h -e "$AT_COMMIT" -- "${records[@]}" | sgrep -e '"result":"fail"' -- || true)
if [ -n "$bad" ]; then
  warn "evidence for $commit records a failure:"
  printf '%s\n' "$bad" | head -5 | sed 's/^/    /' >&2
  fail "evidence records a failed run at this commit"
fi

# NOT VERIFIED and BLOCKED are not done. The latest record per operation wins,
# so a real pass at the same commit — adapter filled in, check re-run —
# supersedes an earlier not_verified. (Unlike `fail` above, which stays.)
# Timestamps are whole seconds, and the files come in glob order, so on a tie
# the WORSE result wins: a pass can never override not_verified by file order.
nv=$(sgrep -h -e "$AT_COMMIT" -- "${records[@]}" | awk '
  function rank(r) { return r=="fail" ? 3 : r=="blocked" ? 2 : r=="not_verified" ? 1 : 0 }
  {
    op=$0; sub(/.*"operation":"/,"",op); sub(/".*/,"",op)
    r=$0;  sub(/.*"result":"/,"",r);     sub(/".*/,"",r)
    t=$0;  sub(/.*"timestamp":"/,"",t);  sub(/".*/,"",t)
    if (!(op in lt) || t > lt[op] || (t == lt[op] && rank(r) > rank(lr[op]))) { lt[op]=t; lr[op]=r }
  }
  END { for (o in lr) if (lr[o]=="not_verified" || lr[o]=="blocked") printf "%s (%s) ", o, lr[o] }' || true)
if [ -n "$nv" ]; then
  not_verified "evidence at $commit: the latest record for ${nv% } — work can continue, it is not done"
  exit 0
fi

ok "evidence ($hits record file(s) at $commit)"
