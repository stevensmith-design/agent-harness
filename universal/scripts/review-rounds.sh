#!/usr/bin/env bash
# Is this review still converging, or is it going round?
#
#   scripts/review-rounds.sh            check the current branch
#
# A review-and-fix loop with no stop condition is the failure the loop-engineering
# write-ups name: the same finding is raised, half-answered and raised again
# until someone's patience, not the code, ends it. So the loop gets a cap —
# `git.max_review_rounds` — and reaching the cap escalates to a person. It never
# approves anything: the only thing this script can do at the cap is record
# `blocked` evidence, which the evidence gate already refuses to call done.
#
# A round is one commit that findings were raised against, counted from
# `.agents/reviews/<branch>.md` (committed, so it survives a fresh clone and a
# different machine — unlike the local evidence trail).
. "$(dirname "$0")/lib.sh"

CAP=$(cfg git.max_review_rounds 3)
# A cap that cannot be read must not quietly become no cap. `[ "$CAP" -gt 0 ]`
# on a non-number is a shell ERROR, and the `|| ok "disabled"` that used to
# follow it turned every typo in the config into a switched-off loop guard.
case "$CAP" in
  ''|*[!0-9]*) fail "git.max_review_rounds is '$CAP' — set a whole number. 0, and only 0, disables the cap" ;;
esac
[ "$CAP" -eq 0 ] && { ok "review rounds (cap deliberately disabled: git.max_review_rounds is 0)"; exit 0; }

branch=$(git -C "$HARNESS_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || printf 'HEAD')
if [ "$branch" = HEAD ]; then
  # Findings are filed per branch. Detached, this script cannot tell which file
  # is this work's — and "no findings" would read as "the loop is converging".
  not_verified "review rounds: detached HEAD, so there is no branch whose findings to count"
  exit 0
fi
FILE="$HARNESS_ROOT/.agents/reviews/${branch//\//-}.md"
[ -f "$FILE" ] || { ok "review rounds (no findings recorded on '$branch')"; exit 0; }

rounds=$(sgrep -o -e 'raised=[^ ]*' -- "$FILE" | sort -u | scount .)
unresolved=$(sgrep -e '^- \[blocking\].*status=open' -- "$FILE" | scount .)

if [ "$rounds" -lt "$CAP" ] || [ "$unresolved" -eq 0 ]; then
  ok "review rounds ($rounds of $CAP used, $unresolved blocking finding(s) open)"
  exit 0
fi

# At the cap with blocking findings still open. Recorded, then handed over —
# and if the record could NOT be written, the message says that instead of
# claiming a record exists. A script that reports its own evidence on faith is
# the false green this harness exists to prevent.
# `|| rec_rc=$?` is load-bearing: under `set -e` a failing command substitution
# ends the script right there, with no message at all — which is how "could not
# record" would have become silence.
rec_rc=0
rec_err=$("$HARNESS_ROOT/scripts/emit-evidence.sh" review "${HARNESS_ACTOR:-runner:local}" blocked \
  "review rounds: $rounds of $CAP used, $unresolved blocking finding(s) still open on $branch" 2>&1 >/dev/null) || rec_rc=$?
warn "$rounds review rounds on '$branch' and $unresolved blocking finding(s) still open:"
sgrep -e '^- \[blocking\].*status=open' -- "$FILE" | head -5 | sed 's/^/    /' >&2
warn "  The loop is not converging. A person decides what happens next — it may be"
warn "  a wrong finding, a spec that never settled, or work that should be split."
if [ "$rec_rc" -eq 0 ]; then
  warn "  Recorded as blocked evidence: reaching the cap is not approval."
else
  warn "  NOT recorded — writing the blocked evidence failed: ${rec_err:-no reason given}"
  warn "  Say so when you escalate: nothing downstream will see this stop."
fi
fail "review rounds — escalate to a person (see .agents/skills/harness-pr/SKILL.md)"
