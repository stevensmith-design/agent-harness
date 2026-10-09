#!/usr/bin/env bash
# What has happened since the last retro, counted — and whether one is due.
#
# A retro run from memory reviews the last two days and the most annoying
# failure. The evidence is already in the repo: devlog corrections and "Not
# verified" lines, incidents, gate results in .agents/runs/, commits on the main
# branch, defect lessons and open questions, the size of what every session loads. This counts it, so /harness-retro
# opens with numbers rather than impressions.
#
# WRITES NOTHING. Deciding what the evidence means, and changing the harness, is
# the retro's job — through a declared intent and a PR.
#
#   scripts/retro-evidence.sh          the full report
#   scripts/retro-evidence.sh --due    one line if a retro is due, else nothing.
#                                      Always exits 0: session-start.sh calls it,
#                                      and a reminder must never block a session.
#
# ci-parity: none — informational. It reports and enforces nothing.
#
# Deliberately does not source lib.sh: its `set -e` and fail-closed helpers are
# right for gates and wrong for a reminder, which must degrade to silence.
# Date arithmetic is awk, not `date -d`/`date -j`, which differ on macOS.

# When a retro is due — whichever comes first. The thresholds live here only;
# the skill reads this script's output rather than keeping a copy.
DUE_DAYS=7              # a week has passed AND something happened in it
DUE_DAYS_ANYWAY=30      # a month has passed, whatever happened
DUE_CORRECTIONS=3       # devlog entries recording a human correction
DUE_INCIDENTS=1         # any new incident
DUE_COMMITS=40          # commits on the main branch
STALE_MEMORY_DAYS=180   # a memory entry not confirmed in this long gets flagged
DUE_RECURRENCES=1       # a rule in docs/quality/defects.md broken again in the window:
                        # the lesson recorded last time did not hold

DUE_ONLY=0; [ "${1:-}" = "--due" ] && DUE_ONLY=1
ROOT="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)" || exit 0
cd "$ROOT" || exit 0
[ -f harness.config.yaml ] || { [ "$DUE_ONLY" = 1 ] && exit 0; printf 'no harness.config.yaml at %s\n' "$ROOT" >&2; exit 1; }

jdn() {
  printf '%s\n' "$1" | awk -F- '{ y=$1+0; m=$2+0; d=$3+0; a=int((14-m)/12); yy=y+4800-a; mm=m+12*a-3;
    print d+int((153*mm+2)/5)+365*yy+int(yy/4)-int(yy/100)+int(yy/400)-32045 }'
}
num() { case "${1:-}" in ''|*[!0-9]*) printf '0' ;; *) printf '%s' "$1" ;; esac; }
TODAY=$(date -u +%Y-%m-%d)
MAIN=$( . scripts/lib.sh >/dev/null 2>&1 && cfg git.main_branch main 2>/dev/null ) || MAIN=main
[ -n "$MAIN" ] || MAIN=main

# --- the window: last row of docs/retros.md ----------------------------------
# Devlog month files only (YYYY-MM.md): the README carries an example entry, and
# counting it would report work that never happened.
LAST=""; LAST_LINES=""
if [ -f docs/retros.md ]; then
  row=$(grep -E -e '^\|[[:space:]]*20[0-9]{2}-[01][0-9]-[0-3][0-9][[:space:]]*\|' -- docs/retros.md 2>/dev/null | tail -1)
  if [ -n "$row" ]; then
    LAST=$(printf '%s\n' "$row" | awk -F'|' '{ gsub(/[[:space:]]/, "", $2); print $2 }')
    LAST_LINES=$(printf '%s\n' "$row" | awk -F'|' '{ print $4 }' | grep -o -E -e '[0-9]+' -- | head -1)
  fi
fi
after() { awk -v l="$LAST" 'l=="" || $0 > l'; }

DEVLOG_DATES=$(cat docs/devlog/20[0-9][0-9]-[01][0-9].md 2>/dev/null | sed -n 's/^##[[:space:]]*\(20[0-9][0-9]-[01][0-9]-[0-3][0-9]\).*/\1/p')
INCIDENT_DATES=$(ls docs/incidents 2>/dev/null | sed -n 's/^\(20[0-9][0-9]-[01][0-9]-[0-3][0-9]\)-.*\.md$/\1/p')
RUN_LINES=$(cat .agents/runs/*.jsonl 2>/dev/null)

WINDOW_FROM="$LAST"
if [ -z "$WINDOW_FROM" ]; then
  WINDOW_FROM=$( { printf '%s\n' "$DEVLOG_DATES" "$INCIDENT_DATES"
                   printf '%s\n' "$RUN_LINES" | sed -n 's/.*"timestamp":"\(20[0-9-]\{8\}\).*/\1/p'; } \
                 | grep -E -e '^20[0-9]{2}-' -- | sort | head -1 )
fi

DEVLOG=$(printf '%s\n' "$DEVLOG_DATES" | grep -e . -- | after | grep -c -e . -- 2>/dev/null)
INCIDENTS=$(printf '%s\n' "$INCIDENT_DATES" | grep -e . -- | after | grep -c -e . -- 2>/dev/null)
CORR=$(cat docs/devlog/20[0-9][0-9]-[01][0-9].md 2>/dev/null | awk -v l="$LAST" '
  /^##[[:space:]]*20[0-9][0-9]-/ { d=$2; next }
  (l=="" || d > l) && /^\*\*Corrected\*\*/ {
    t=tolower($0); sub(/^\*\*corrected\*\*[[:space:]]*(—|-|:)?[[:space:]]*/, "", t)
    if (t != "" && t !~ /^(nothing notable|none|n\/a)\.?[[:space:]]*$/) n++ }
  END { print n+0 }')
UNVERIFIED=$(cat docs/devlog/20[0-9][0-9]-[01][0-9].md 2>/dev/null | awk -v l="$LAST" '
  /^##[[:space:]]*20[0-9][0-9]-/ { d=$2; next }
  (l=="" || d > l) && /^\*\*Not verified\*\*/ {
    t=tolower($0); sub(/^\*\*not verified\*\*[[:space:]]*(—|-|:)?[[:space:]]*/, "", t)
    if (t != "" && t !~ /^(nothing notable|none|n\/a)\.?[[:space:]]*$/) n++ }
  END { print n+0 }')
GATE_RUNS=$(printf '%s\n' "$RUN_LINES" | sed -n 's/.*"result":"\([a-z]*\)".*"timestamp":"\(20[0-9-]\{8\}\).*/\2 \1/p' | awk -v l="$LAST" 'l=="" || $1 > l' )
GATE_ALL=$(printf '%s\n' "$GATE_RUNS" | grep -c -e . -- 2>/dev/null)
GATE_FAIL=$(printf '%s\n' "$GATE_RUNS" | grep -c -E -e ' (fail|blocked)$' -- 2>/dev/null)

COMMITS=0
if git rev-parse --git-dir >/dev/null 2>&1 && git rev-parse --verify -q "$MAIN" >/dev/null 2>&1; then
  if [ -n "$LAST" ]; then
    COMMITS=$(git log --first-parent --oneline --since="$LAST 23:59:59" "$MAIN" 2>/dev/null | grep -c -e . -- 2>/dev/null)
  else
    COMMITS=$(git log --first-parent --oneline "$MAIN" 2>/dev/null | grep -c -e . -- 2>/dev/null)
  fi
fi

# The learning loop: defect lessons and questions. A rule is recurring when it
# broke on more than one day and at least one of those days is in the window.
# Rows on the same day are one sweep's findings, not a recurrence.
# Rows are read as check-learning reads them: escaped pipes kept inside a cell,
# and only rows with the right number of columns — so the two never disagree.
# The rule is keyed by its first register ID, so "INV-004 (again)" is INV-004.
DEF_ROWS=$(grep -E -e '^\|[[:space:]]*DEF-[0-9]+[[:space:]]*\|' -- docs/quality/defects.md 2>/dev/null \
  | sed 's/\\|/¦/g' | awk -F'|' 'NF == 9')
DEF_NEW=$(printf '%s\n' "$DEF_ROWS" | awk -F'|' -v l="$LAST" 'NF { d=$3; gsub(/[[:space:]]/, "", d); if (l == "" || d > l) n++ } END { print n+0 }')
DEF_GAPS=$(printf '%s\n' "$DEF_ROWS" | awk -F'|' -v l="$LAST" 'NF { d=$3; g=$6; gsub(/[[:space:]]/, "", d); gsub(/[[:space:]]/, "", g)
    if (l == "" || d > l) n[g]++ }
  END { printf "spec %d · test %d · render %d · judgement %d", n["spec"], n["test"], n["render"], n["judgement"] }')
RECUR_AWK='NF { r=$5; d=$3; gsub(/[[:space:]]/, "", d)
    if (match(r, /(DEC|INV|REQ|Q)-[0-9]+/)) r = substr(r, RSTART, RLENGTH)
    else { gsub(/^[ \t]+|[ \t]+$/, "", r); r = tolower(r) }
    if (r == "none" || r == "") next
    if (!((r, d) in seen)) { seen[r, d] = 1; days[r]++ }
    if (l == "" || d > l) inwin[r] = 1 }'
RECUR=$(printf '%s\n' "$DEF_ROWS" | awk -F'|' -v l="$LAST" "$RECUR_AWK"'
  END { for (r in days) if (days[r] > 1 && (r in inwin)) printf "%s (%d days) ", r, days[r] }')
RECUR_N=$(printf '%s\n' "$DEF_ROWS" | awk -F'|' -v l="$LAST" "$RECUR_AWK"'
  END { k = 0; for (r in days) if (days[r] > 1 && (r in inwin)) k++; print k }')
Q_STALE_DAYS=$( . scripts/lib.sh >/dev/null 2>&1 && cfg product.question_stale_days 14 2>/dev/null ) || Q_STALE_DAYS=14
Q_OPEN_DATES=$(grep -E -e '^\|[[:space:]]*Q-[0-9]+[[:space:]]*\|' -- docs/product/questions.md 2>/dev/null \
  | awk -F'|' '{ s=$6; gsub(/[[:space:]]/, "", s); d=$3; gsub(/[[:space:]]/, "", d); if (s == "open") print d }')
Q_OPEN=$(printf '%s\n' "$Q_OPEN_DATES" | grep -c -e . -- 2>/dev/null)
Q_STALE=0
for d in $Q_OPEN_DATES; do
  printf '%s' "$d" | grep -q -E -e '^20[0-9]{2}-[01][0-9]-[0-3][0-9]$' -- || continue
  [ $(( $(jdn "$TODAY") - $(jdn "$d") )) -gt "$(num "$Q_STALE_DAYS")" ] && Q_STALE=$((Q_STALE + 1))
done

for v in DEVLOG INCIDENTS CORR UNVERIFIED GATE_ALL GATE_FAIL COMMITS DEF_NEW RECUR_N Q_OPEN Q_STALE; do eval "$v=\$(num \"\${$v}\")"; done
DAYS=0
if printf '%s\n' "$WINDOW_FROM" | grep -q -E -e '^20[0-9]{2}-[01][0-9]-[0-3][0-9]$' --; then
  DAYS=$(( $(jdn "$TODAY") - $(jdn "$WINDOW_FROM") ))
fi
ACTIVITY=$((DEVLOG + INCIDENTS + GATE_ALL + COMMITS))
if [ -n "$LAST" ]; then SINCE="the last retro"; else SINCE="the first recorded work"; fi

REASONS=""
add() { if [ -z "$REASONS" ]; then REASONS="$1"; else REASONS="$REASONS; $1"; fi; }
if [ -n "$WINDOW_FROM" ]; then
  [ "$DAYS" -ge "$DUE_DAYS_ANYWAY" ] && add "$DAYS days since $SINCE"
  [ "$DAYS" -ge "$DUE_DAYS" ] && [ "$DAYS" -lt "$DUE_DAYS_ANYWAY" ] && [ "$ACTIVITY" -gt 0 ] && add "$DAYS days, with work in them, since $SINCE"
fi
[ "$CORR" -ge "$DUE_CORRECTIONS" ] && add "$CORR corrections in the devlog"
[ "$INCIDENTS" -ge "$DUE_INCIDENTS" ] && add "$INCIDENTS new incident(s)"
[ "$COMMITS" -ge "$DUE_COMMITS" ] && add "$COMMITS commits on $MAIN"
[ "$RECUR_N" -ge "$DUE_RECURRENCES" ] && add "$RECUR_N rule(s) broken again after a lesson was recorded"

if [ "$DUE_ONLY" = 1 ]; then
  [ -n "$REASONS" ] && printf 'Retro due: %s. When the current work is done, suggest /harness-retro; do not start it unasked.\n' "$REASONS"
  exit 0
fi

printf 'Retro evidence — %s\n\n' "$TODAY"
if [ -n "$LAST" ]; then printf 'Last retro         %s (%s days ago)\n' "$LAST" "$DAYS"
else printf 'Last retro         none in docs/retros.md — window is all recorded work%s\n' "${WINDOW_FROM:+, from $WINDOW_FROM}"; fi
printf 'Commits on %-7s %s\n' "$MAIN" "$COMMITS"
printf 'Devlog entries     %s — %s record a correction, %s something not verified\n' "$DEVLOG" "$CORR" "$UNVERIFIED"
printf 'Incidents          %s new\n' "$INCIDENTS"
printf 'Gate records       %s in .agents/runs/, %s fail or blocked\n' "$GATE_ALL" "$GATE_FAIL"
printf 'Defect lessons     %s new — %s\n' "$DEF_NEW" "$DEF_GAPS"
if [ "$RECUR_N" -gt 0 ]; then printf 'Broken again       %s— each lesson recorded last time did not hold\n' "$RECUR"
else printf 'Broken again       none\n'; fi
printf 'Questions          %s open, %s older than %s days\n' "$Q_OPEN" "$Q_STALE" "$(num "$Q_STALE_DAYS")"

# The review loop, from the committed findings files — no network, no gh, no
# "0 findings" that really means "could not look". A finding raised on two
# branches is the retro candidate: the same comment written twice is a rule
# nobody encoded.
RV_F=0; RV_OPEN=0; RV_ROUNDS_OVER=""
# This script does not source lib.sh (its set -e would end a report early), so
# it borrows cfg in a subshell — the same shape as MAIN above.
RV_CAP=$( . scripts/lib.sh >/dev/null 2>&1 && cfg git.max_review_rounds 3 2>/dev/null ) || RV_CAP=3
case "$RV_CAP" in ''|*[!0-9]*) RV_CAP=0 ;; esac   # unreadable cap: report no branch as over it
for f in .agents/reviews/*.md; do
  [ -f "$f" ] || continue
  n=$(grep -c -E -e '^- \[(blocking|advisory)\]' -- "$f" 2>/dev/null)
  RV_F=$((RV_F + $(num "$n")))
  # Anchored to finding lines: any other line that happens to say status=open
  # is not a finding, and counting it turns prose into evidence.
  o=$(grep -c -E -e '^- \[(blocking|advisory)\].*status=open' -- "$f" 2>/dev/null)
  RV_OPEN=$((RV_OPEN + $(num "$o")))
  # A branch is only "going round" if it is at the cap AND something blocking is
  # still open. Rounds that ended in resolution are a review working, not a loop.
  r=$(grep -o -E -e 'raised=[^ ]*' -- "$f" 2>/dev/null | sort -u | grep -c -e . -- 2>/dev/null)
  ob=$(grep -c -E -e '^- \[blocking\].*status=open' -- "$f" 2>/dev/null)
  if [ "$RV_CAP" -gt 0 ] && [ "$(num "$r")" -ge "$RV_CAP" ] && [ "$(num "$ob")" -gt 0 ]; then
    RV_ROUNDS_OVER="$RV_ROUNDS_OVER $(basename "$f" .md)"
  fi
done
# The claim is the third · field. Severity and category are matched loosely on
# purpose: `a11y` — the harness's own example category — has a digit in it, and
# a `[a-z]*` category silently matched nothing, so recurring findings counted 0.
# Claims are made unique WITHIN each branch first. The same claim twice on one
# branch is one reviewer repeating themselves; across two branches it is a rule
# nobody encoded, which is the only one of the two a retro can act on.
RV_REPEAT=$(for f in .agents/reviews/*.md; do
  [ -f "$f" ] || continue
  sed -n 's/^- \[[^]]*\] [^ ]* · [^·]* · \([^·]*\) ·.*/\1/p' "$f" 2>/dev/null | sort -u
done | sort | uniq -d | grep -c -e . -- 2>/dev/null)
printf 'Review findings    %s recorded, %s still open, %s claim(s) raised on more than one branch\n' \
  "$(num "$RV_F")" "$(num "$RV_OPEN")" "$(num "$RV_REPEAT")"
[ -n "$RV_ROUNDS_OVER" ] && printf 'Review rounds      at or over the cap of %s:%s — a loop that went round is itself the finding\n' "$(num "$RV_CAP")" "$RV_ROUNDS_OVER"
# The same question about MERGED PRs needs the forge, and the honest answer when
# it is not reachable is "not verified" — never a zero that reads as "none".
# `reviewDecision` is the PR's CURRENT state, and a merged PR's is almost always
# APPROVED — counting it would report "none were ever sent back" for every repo.
# The history lives in each PR's reviews, so that is what is asked for; if the
# forge will not give it, the line says NOT VERIFIED rather than inventing a zero.
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1 \
   && PRJSON=$(gh pr list --state merged --limit 20 --json number,reviews 2>/dev/null) && [ -n "$PRJSON" ]; then
  # One PR per line, so a CHANGES_REQUESTED counts once for the PR that carries
  # it — not once per review, and not once for the whole page of JSON.
  PRLINES=$(printf '%s' "$PRJSON" | sed 's/{"number":/\
&/g' | grep -e '^{"number":' -- 2>/dev/null)
  PR_N=$(printf '%s\n' "$PRLINES" | grep -c -e '^{"number":' -- 2>/dev/null)
  PR_CR=$(printf '%s\n' "$PRLINES" | grep -c -e 'CHANGES_REQUESTED' -- 2>/dev/null)
  printf 'Merged-PR reviews  %s of the last %s merged PR(s) had a CHANGES_REQUESTED review at some point\n' "$(num "$PR_CR")" "$(num "$PR_N")"
else
  printf 'Merged-PR reviews  NOT VERIFIED — gh is unavailable, not signed in, or would not return per-PR review history, so this was not read (it is not zero)\n'
fi

TURNED=$(grep -c -E -e '^\|[[:space:]]*20[0-9]{2}-' -- docs/retros.md 2>/dev/null)
NOREPROP=$(awk '/do not re-propose/{s=1;next} /^## /{s=0} s && /^- /' docs/product/decisions.md 2>/dev/null | grep -c -e . -- 2>/dev/null)
printf 'Retros logged      %s    Product ideas on the do-not-re-propose list  %s\n' "$(num "$TURNED")" "$(num "$NOREPROP")"

# Memory: the index budget, and entries nobody has confirmed.
MI_L=$(grep -c -v -E -e '^[[:space:]]*(<!--|$)' -- .agents/memory/MEMORY.md 2>/dev/null); MI_B=$(wc -c < .agents/memory/MEMORY.md 2>/dev/null | tr -d ' ')
MEM_FILES=0; MEM_UNDATED=0; MEM_STALE=0; T=$(jdn "$TODAY")
for f in .agents/memory/*.md; do
  [ -f "$f" ] || continue
  case "$f" in */MEMORY.md) continue ;; esac
  MEM_FILES=$((MEM_FILES + 1))
  # Template placeholder lines (`<term>`) are not entries.
  u=$(grep -E -e '^[[:space:]]*- ' -- "$f" 2>/dev/null | grep -v -E -e '<[a-z][a-z ,]*>' -- | grep -c -v -e 'confirmed 20' -- 2>/dev/null)
  MEM_UNDATED=$((MEM_UNDATED + $(num "$u")))
  for c in $(grep -o -E -e 'confirmed 20[0-9]{2}-[01][0-9]-[0-3][0-9]' -- "$f" 2>/dev/null | sed 's/confirmed //'); do
    [ $((T - $(jdn "$c"))) -gt "$STALE_MEMORY_DAYS" ] && MEM_STALE=$((MEM_STALE + 1))
  done
done
printf 'Memory             index %s lines / %s bytes (limit 200 / 25000); %s topic file(s); %s entries never confirmed, %s not in %s days\n' \
  "$(num "$MI_L")" "$(num "$MI_B")" "$MEM_FILES" "$MEM_UNDATED" "$MEM_STALE" "$STALE_MEMORY_DAYS"

SIZE=$(bash scripts/gates/instruction-budget.sh --size 2>/dev/null | tail -1)
L=$(printf '%s' "$SIZE" | cut -d' ' -f1); B=$(printf '%s' "$SIZE" | cut -d' ' -f2)
if [ -n "$L" ] && [ "$(num "$L")" = "$L" ]; then
  DELTA=""
  if [ -n "$LAST_LINES" ]; then
    D=$((L - LAST_LINES))
    if [ "$D" -gt 0 ]; then DELTA=" — up $D since the last retro: net zero means something comes out"
    elif [ "$D" -lt 0 ]; then DELTA=" — down $((-D)) since the last retro"
    else DELTA=" — unchanged since the last retro"; fi
  fi
  printf '\nAlways loaded      %s lines, %s bytes (about %s tokens)%s\n' "$L" "$B" "$((B / 4))" "$DELTA"
else
  printf '\nAlways loaded      unknown — run make check-budget\n'
fi
# Every skill's name and description loads into every session, used or not.
# It sits outside the instruction budget, so it is shown rather than left uncounted.
SK_N=0; SK_C=0
for f in .agents/skills/*/SKILL.md; do
  [ -f "$f" ] || continue
  c=$(awk '/^---[[:space:]]*$/ { n++; next } n==1 && /^(name|description):/ { sub(/^[a-z]+:[[:space:]]*/, ""); t += length($0) } END { print t+0 }' "$f")
  SK_N=$((SK_N + 1)); SK_C=$((SK_C + $(num "$c")))
done
printf 'Skill listing      %s skills, %s characters of names and descriptions (about %s tokens), loaded every session\n' "$SK_N" "$SK_C" "$((SK_C / 4))"
printf 'Largest skills and path rules (loaded when they fire; about tokens = bytes / 4):\n'
for f in .agents/skills/*/SKILL.md .agents/rules/*.md; do
  [ -f "$f" ] && printf '%s\t%s\n' "$(wc -c < "$f" | tr -d ' ')" "$f"
done | sort -rn | head -5 | awk -F'\t' '{ printf "  %7d bytes  ~%5d tokens  %s\n", $1, $1/4, $2 }'

printf '\nAlso read before deciding anything:\n'
command -v python3 >/dev/null 2>&1 && \
  printf '  python3 scripts/mine-sessions.py%s [--usage]    corrections the person typed, or where the tokens went\n' "${LAST:+ --since $LAST}"
printf '  review comments on PRs merged since %s — the same comment on two PRs is a candidate\n' "${LAST:-the start}"
printf '  docs/devlog/ Friction, Corrected and Not verified since %s; the Turned down column of docs/retros.md\n' "${LAST:-the start}"
printf '\n'
if [ -n "$REASONS" ]; then printf 'Due: %s.\n' "$REASONS"
else printf 'Not due by the numbers. A retro is still right if the same correction has come up twice.\n'; fi
exit 0
