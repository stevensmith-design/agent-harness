#!/usr/bin/env bash
# Stop hook. A run that touched source must leave evidence behind. Exit 2 sends
# the agent back with a reason rather than letting "done" mean "I stopped".
#
# ci-parity: scripts/gates/evidence.sh
#
# It used to test `ls .agents/runs/*.jsonl` — the existence of ANY evidence file
# ever written. Since that directory is gitignored, one file from a session six
# months ago satisfied the gate indefinitely on that machine. Evidence has to be
# newer than the work it is evidence for.
#
# Loop breaker. A check the agent genuinely cannot satisfy must not hold the
# session: Claude Code only overrides a Stop hook after eight blocks in a row,
# and every one of those is a full turn of tokens spent going round. After three
# blocked stops in one session this lets the agent finish, and tells the PERSON —
# through systemMessage, because stderr on exit 0 reaches nobody — that the work
# ended unverified. The count is per session and resets when the check passes.
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
INPUT=""; [ -t 0 ] || INPUT=$(cat)
SID=$(printf '%s' "$INPUT" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 | tr -cd 'A-Za-z0-9_-')
[ -n "$SID" ] || SID=unknown
STATE=".agents/runs/.stop-$SID"

let_go() { rm -f "$STATE" 2>/dev/null; exit 0; }

nag() {
  local n
  n=$(cat "$STATE" 2>/dev/null || printf 0)
  case "$n" in ''|*[!0-9]*) n=0 ;; esac
  n=$((n + 1))
  if [ "$n" -gt 3 ]; then
    rm -f "$STATE" 2>/dev/null
    printf '{"systemMessage":"%s"}\n' "$(printf 'Finished without verification: the stop check still fails after 3 attempts. %s' "$1" | tr '\n' ' ' | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')"
    exit 0
  fi
  mkdir -p .agents/runs 2>/dev/null && printf '%s\n' "$n" > "$STATE" 2>/dev/null
  echo "$1 (stop check, attempt $n of 3)" >&2
  echo "Run 'make check' (and 'make verify' for anything user-visible), then let the run finish." >&2
  echo "If it cannot be made to pass, say so to the person — what fails, and why — rather than trying again." >&2
  exit 2
}

git diff --quiet HEAD -- 2>/dev/null && let_go          # nothing changed: fine
changed=$(git diff --name-only HEAD 2>/dev/null | grep -vE '^(docs/|\.agents/runs/|README)' || true)
[ -n "$changed" ] || let_go

ls .agents/runs/*.jsonl >/dev/null 2>&1 || nag "Source changed but no evidence was recorded."

# The newest evidence must be newer than the newest changed source file.
newest_src=""
while IFS= read -r f; do
  [ -f "$f" ] || continue
  [ -z "$newest_src" ] || [ "$f" -nt "$newest_src" ] && newest_src="$f"
done <<< "$changed"
[ -n "$newest_src" ] || let_go

if ! find .agents/runs -name '*.jsonl' -newer "$newest_src" -print -quit 2>/dev/null | grep -q .; then
  nag "Source changed after the last evidence was recorded — the evidence on disk is stale."
fi

# And it must be evidence for THIS branch.
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo -)
if [ "$branch" != "-" ] && ! grep -ql "\"branch\":\"$branch\"" .agents/runs/*.jsonl 2>/dev/null; then
  nag "Evidence exists but none of it was recorded on '$branch'."
fi

# Fresh evidence that says NOT VERIFIED (or blocked): the agent usually cannot
# fix a stub adapter, so sending it round again only spends turns. Let it
# finish, and tell the person plainly that the work is not done. The decision —
# latest check/verify at this commit, worse result wins a tie — is the evidence
# gate's; asking it here keeps one rule in one place.
if ./scripts/gates/evidence.sh 2>&1 | grep -q 'NOT VERIFIED'; then
  rm -f "$STATE" 2>/dev/null
  printf '{"systemMessage":"%s"}\n' "NOT VERIFIED: the latest check at this commit did not verify the work (stub adapter verbs, or blocked). It can continue, but it is not done — see make check-evidence."
  exit 0
fi
let_go
