#!/usr/bin/env bash
# retro-evidence.sh — what has happened since the last retro, counted.
#
# A retro run from memory reviews whatever the person running it happens to
# remember, which is the last two days and the most annoying failure. The
# evidence is already on disk: dated runs, judged rejections, checkpoint
# results, the journal. This script counts it, so a retro opens with numbers
# rather than impressions, and says whether a retro is due at all.
#
# It WRITES NOTHING. It reads the harness and prints. Deciding what the
# evidence means, and changing anything, is the retro's job and needs a person.
#
# Usage:
#   bash scripts/retro-evidence.sh         the full report
#   bash scripts/retro-evidence.sh --due   one line if a retro is due, nothing
#                                          otherwise. Always exits 0: the
#                                          session-start hook calls it, and a
#                                          reminder must never block a session.
#
# Portable on purpose: bash 3.2, BSD and GNU tools, no git required. Date
# arithmetic is done in awk, because `date -d` and `date -j` are not the same
# program on a Mac and on Linux.

# ── When a retro is due — whichever comes first. Change the numbers here; the
#    retro procedure reads this script's output rather than keeping a copy.
DUE_DAYS=7                # a week has passed AND something happened in it
DUE_DAYS_ANYWAY=30        # a month has passed, whatever happened
DUE_RUNS=10               # runs since the last retro
DUE_REJECTIONS=3          # new files in learning/corpus/rejected/
DUE_CHECKPOINT_FAILS=3    # failed checkpoints since the last retro
STALE_MEMORY_DAYS=180     # a memory entry not confirmed in this long gets flagged
DUE_RECURRENCES=1         # a standard in learning/findings.md broken again after
                          # its lesson was recorded: that lesson did not hold

DUE_ONLY=0; [ "${1:-}" = "--due" ] && DUE_ONLY=1

cd "$(dirname "$0")/.." 2>/dev/null || exit 0
[ -f harness.yaml ] || { [ "$DUE_ONLY" -eq 1 ] && exit 0; printf 'no harness.yaml above %s\n' "$(pwd)" >&2; exit 1; }

# Julian day number from YYYY-MM-DD. Plain arithmetic; no date(1) dialects.
jdn() {
  printf '%s\n' "$1" | awk -F- '{ y=$1+0; m=$2+0; d=$3+0; a=int((14-m)/12); yy=y+4800-a; mm=m+12*a-3;
    print d+int((153*mm+2)/5)+365*yy+int(yy/4)-int(yy/100)+int(yy/400)-32045 }'
}
is_date() { printf '%s\n' "$1" | grep -qe '^20[0-9][0-9]-[01][0-9]-[0-3][0-9]$' --; }

TODAY=$(date -u +%Y-%m-%d)

# ── Where the window starts: the last retro in learning/retros.md ────────────
LAST=""; LAST_LINES=""
if [ -f learning/retros.md ]; then
  row=$(grep -e '^|[[:space:]]*20[0-9][0-9]-[01][0-9]-[0-3][0-9][[:space:]]*|' -- learning/retros.md | tail -1)
  if [ -n "$row" ]; then
    LAST=$(printf '%s\n' "$row" | awk -F'|' '{ gsub(/[[:space:]]/, "", $2); print $2 }')
    LAST_LINES=$(printf '%s\n' "$row" | awk -F'|' '{ print $4 }' | grep -oe '[0-9]\{1,\}' -- | head -1)
  fi
fi

# Dated things, each as YYYY-MM-DD, one per line: runs, journal entries, checkpoints.
RUN_DATES=$(find runs -maxdepth 1 -type d -name '20*' 2>/dev/null | sed 's|.*/||' | cut -c1-10 | grep -e '^20' -- || true)
JOURNAL_DATES=$(cat learning/journal/*.md 2>/dev/null | sed -n 's/^##[[:space:]]*\(20[0-9][0-9]-[01][0-9]-[0-3][0-9]\).*/\1/p')
CP_LINES=$(cat runs/.state/checkpoints 2>/dev/null || true)

# No retro yet: the window starts at the first recorded activity.
WINDOW_FROM="$LAST"
if [ -z "$LAST" ]; then
  FIRST=$( { printf '%s\n' "$RUN_DATES"; printf '%s\n' "$JOURNAL_DATES"; printf '%s\n' "$CP_LINES" | cut -c1-10; } \
           | grep -e '^20[0-9][0-9]-' -- | sort | head -1)
  WINDOW_FROM="$FIRST"
fi

# Count dates strictly after the last retro (everything, when there was none).
after() { if [ -n "$LAST" ]; then awk -v l="$LAST" '$0 > l' ; else cat; fi; }
n_of() { grep -ce '^20' -- 2>/dev/null || true; }

RUNS=$(printf '%s\n' "$RUN_DATES" | grep -e . -- | after | n_of)
JOURNAL=$(printf '%s\n' "$JOURNAL_DATES" | grep -e . -- | after | n_of)
CP_ALL=$(printf '%s\n' "$CP_LINES" | grep -e . -- | cut -f1,2 | awk -v l="$LAST" 'l=="" || substr($1,1,10) > l' | grep -ce . -- || true)
CP_FAIL=$(printf '%s\n' "$CP_LINES" | grep -e . -- | awk -F'\t' -v l="$LAST" '(l=="" || substr($1,1,10) > l) && $2=="fail"' | grep -ce . -- || true)

# Judged examples have no date in their name, so compare modification times
# against a reference file stamped at the end of the retro day. `touch -t` and
# `find -newer` behave the same on BSD and GNU.
REF=$(mktemp 2>/dev/null) || REF=""
newer_count() {
  d=$1
  [ -d "$d" ] || { printf '0\n'; return; }
  if [ -z "$LAST" ] || [ -z "$REF" ]; then
    find "$d" -type f -not -name '.gitkeep' -not -name 'README.md' 2>/dev/null | grep -ce . -- || true
  else
    find "$d" -type f -not -name '.gitkeep' -not -name 'README.md' -newer "$REF" 2>/dev/null | grep -ce . -- || true
  fi
}
[ -n "$LAST" ] && [ -n "$REF" ] && touch -t "$(printf '%s' "$LAST" | tr -d '-')2359" "$REF" 2>/dev/null
REJ=$(newer_count learning/corpus/rejected)
ACC=$(newer_count learning/corpus/accepted)
rm -f "$REF"

# Findings: a standard is broken again when it appears on more than one day and
# one of those days is in the window. Same-day rows are one sweep, not a recurrence.
F_ROWS=$(grep -e '^|[[:space:]]*20[0-9][0-9]-[01][0-9]-[0-3][0-9][[:space:]]*|' -- learning/findings.md 2>/dev/null | sed 's/\\|/¦/g' | awk -F'|' 'NF == 8' || true)
FINDINGS=$(printf '%s\n' "$F_ROWS" | awk -F'|' -v l="$LAST" 'NF { d=$2; gsub(/[[:space:]]/, "", d); if (l == "" || d > l) n++ } END { print n+0 }')
F_GAPS=$(printf '%s\n' "$F_ROWS" | awk -F'|' -v l="$LAST" 'NF { d=$2; g=$5; gsub(/[[:space:]]/, "", d); gsub(/[[:space:]]/, "", g)
    if (l == "" || d > l) n[g]++ }
  END { printf "standard %d · check %d · render %d · judgement %d", n["standard"], n["check"], n["render"], n["judgement"] }')
AGAIN_AWK='NF { d=$2; r=$4; gsub(/[[:space:]]/, "", d); gsub(/^[ \t]+|[ \t]+$/, "", r)
    if (r == "" || r == "none" || r == "—") next
    if (!((r, d) in seen)) { seen[r, d] = 1; days[r]++ }
    if (l == "" || d > l) inwin[r] = 1 }'
AGAIN=$(printf '%s\n' "$F_ROWS" | awk -F'|' -v l="$LAST" "$AGAIN_AWK"'
  END { for (r in days) if (days[r] > 1 && (r in inwin)) printf "%s (%d days); ", r, days[r] }')
RECUR=$(printf '%s\n' "$F_ROWS" | awk -F'|' -v l="$LAST" "$AGAIN_AWK"'
  END { k = 0; for (r in days) if (days[r] > 1 && (r in inwin)) k++; print k }')
Q_OPEN=$(awk '/^## Open questions/{s=1;next} /^## /{s=0}
  s && /^\|[[:space:]]*20[0-9][0-9]-/ { n=split($0, c, "|"); x=c[5]; gsub(/[[:space:]]/, "", x); if (x == "" || x == "—" || x == "-") k++ }
  END { print k+0 }' decisions/log.md 2>/dev/null)

for v in RUNS JOURNAL CP_ALL CP_FAIL REJ ACC FINDINGS RECUR Q_OPEN; do
  eval "val=\${$v:-0}"; case "$val" in ''|*[!0-9]*) eval "$v=0" ;; esac
done

DAYS=0
[ -n "$WINDOW_FROM" ] && is_date "$WINDOW_FROM" && DAYS=$(( $(jdn "$TODAY") - $(jdn "$WINDOW_FROM") ))
ACTIVITY=$((RUNS + JOURNAL + CP_ALL + REJ + ACC))

# ── Is a retro due? ──────────────────────────────────────────────────────────
REASONS=""
if [ -n "$LAST" ]; then SINCE="the last retro"; else SINCE="the first recorded work"; fi
add() { if [ -z "$REASONS" ]; then REASONS="$1"; else REASONS="$REASONS; $1"; fi; }
if [ -n "$WINDOW_FROM" ]; then
  [ "$DAYS" -ge "$DUE_DAYS_ANYWAY" ] && add "$DAYS days since $SINCE"
  [ "$DAYS" -ge "$DUE_DAYS" ] && [ "$DAYS" -lt "$DUE_DAYS_ANYWAY" ] && [ "$ACTIVITY" -gt 0 ] && add "$DAYS days, with work in them, since $SINCE"
fi
[ "$RUNS" -ge "$DUE_RUNS" ] && add "$RUNS runs"
[ "$REJ" -ge "$DUE_REJECTIONS" ] && add "$REJ new rejections"
[ "$CP_FAIL" -ge "$DUE_CHECKPOINT_FAILS" ] && add "$CP_FAIL failed checkpoints"
[ "$RECUR" -ge "$DUE_RECURRENCES" ] && add "$RECUR standard(s) broken again after a lesson was recorded"

if [ "$DUE_ONLY" -eq 1 ]; then
  [ -n "$REASONS" ] && printf 'Retro due: %s. When the current work is done, suggest procedures/harness-retro.md to the person; do not start it unasked.\n' "$REASONS"
  exit 0
fi

# ── The report ───────────────────────────────────────────────────────────────
printf 'Retro evidence — %s\n\n' "$TODAY"
if [ -n "$LAST" ]; then
  printf 'Last retro        %s (%s days ago)\n' "$LAST" "$DAYS"
else
  printf 'Last retro        none recorded in learning/retros.md — window is all recorded work%s\n' "${WINDOW_FROM:+, from $WINDOW_FROM}"
fi
printf 'Runs              %s\n' "$RUNS"
printf 'Rejections        %s new    Acceptances  %s new\n' "$REJ" "$ACC"
printf 'Checkpoints       %s run, %s failed\n' "$CP_ALL" "$CP_FAIL"
printf 'Journal entries   %s\n' "$JOURNAL"

CORR=0
if [ -d learning/journal ]; then
  CORR=$(cat learning/journal/*.md 2>/dev/null | awk -v l="$LAST" '
    /^##[[:space:]]*20[0-9][0-9]-/ { d=$2; next }
    (l=="" || d > l) && tolower($0) ~ /^- *corrected:/ && tolower($0) !~ /corrected:[[:space:]]*(none|-|n\/a)?[[:space:]]*$/ { n++ }
    END { print n+0 }')
fi
printf 'Corrections       %s recorded in the journal\n' "$CORR"
printf 'Findings          %s new — %s\n' "$FINDINGS" "$F_GAPS"
if [ "$RECUR" -gt 0 ]; then printf 'Broken again      %s— each lesson recorded last time did not hold\n' "$AGAIN"
else printf 'Broken again      none\n'; fi
printf 'Open questions    %s in decisions/log.md\n' "$Q_OPEN"

STAGED=$(awk '/^## Staged/{s=1;next} /^## /{s=0} s && /^- / && !/none yet/' learning/candidates.md 2>/dev/null | grep -ce . -- || true)
REFUSED=$(awk '/^## Do not propose again/{s=1;next} /^## /{s=0} s && /^\|[[:space:]]*20/' decisions/log.md 2>/dev/null | grep -ce . -- || true)
printf 'Candidates        %s staged\n' "${STAGED:-0}"
printf 'Do not propose    %s idea(s) on the list\n' "${REFUSED:-0}"

# Memory hygiene: entries with no confirmation date, or confirmed long ago.
MEM_FILES=$(find memory -type f -name '*.md' -not -name 'README.md' 2>/dev/null | grep -ce . -- || true)
MEM_STALE=0; MEM_UNDATED=0
if [ "${MEM_FILES:-0}" -gt 0 ]; then
  T=$(jdn "$TODAY")
  for f in $(find memory -type f -name '*.md' -not -name 'README.md' 2>/dev/null); do
    u=$(grep -e '^[[:space:]]*- ' -- "$f" | grep -ve 'confirmed 20[0-9][0-9]-' -- | grep -ce . -- || true)
    MEM_UNDATED=$((MEM_UNDATED + ${u:-0}))
    for c in $(grep -oe 'confirmed 20[0-9][0-9]-[01][0-9]-[0-3][0-9]' -- "$f" | sed 's/confirmed //'); do
      [ $((T - $(jdn "$c"))) -gt "$STALE_MEMORY_DAYS" ] && MEM_STALE=$((MEM_STALE + 1))
    done
  done
fi
printf 'Memory            %s topic file(s); %s entr%s never confirmed, %s not confirmed in %s days\n' \
  "${MEM_FILES:-0}" "$MEM_UNDATED" "$([ "$MEM_UNDATED" -eq 1 ] && echo y || echo ies)" "$MEM_STALE" "$STALE_MEMORY_DAYS"

# ── Context cost: what every session pays, and the largest on-demand files ───
SIZE=$(bash scripts/check-budget.sh --size 2>/dev/null)
L=$(printf '%s' "$SIZE" | cut -d' ' -f1); B=$(printf '%s' "$SIZE" | cut -d' ' -f2)
if [ -n "$L" ]; then
  DELTA=""
  if [ -n "$LAST_LINES" ]; then
    D=$((L - LAST_LINES))
    if [ "$D" -gt 0 ]; then DELTA=" — up $D since the last retro: net zero means something comes out"
    elif [ "$D" -lt 0 ]; then DELTA=" — down $((-D)) since the last retro"
    else DELTA=" — unchanged since the last retro"; fi
  fi
  printf '\nAlways loaded     %s lines, %s bytes (about %s tokens)%s\n' "$L" "$B" "$((B / 4))" "$DELTA"
else
  printf '\nAlways loaded     unknown — scripts/check-budget.sh --size failed; run the gate\n'
fi
# The skill listing: hosts that list skills load every skill's name and
# description into every session, whether or not one is used. It sits outside
# the budget above, so it is shown here rather than left uncounted.
SK_N=0; SK_C=0
for f in .claude/skills/*/SKILL.md; do
  [ -f "$f" ] || continue
  c=$(awk '/^---[[:space:]]*$/ { n++; next } n==1 && /^(name|description):/ { sub(/^[a-z]+:[[:space:]]*/, ""); t += length($0) } END { print t+0 }' "$f")
  SK_N=$((SK_N + 1)); SK_C=$((SK_C + c))
done
printf 'Skill listing     %s skill(s), %s characters of names and descriptions (about %s tokens), loaded every session\n' "$SK_N" "$SK_C" "$((SK_C / 4))"
printf 'Largest on demand (about tokens = bytes / 4):\n'
find . -type f -name '*.md' -not -path './.git/*' -not -path './runs/*' -not -path './.claude/*' \
     -not -path './learning/corpus/*' 2>/dev/null \
  | while IFS= read -r f; do printf '%s\t%s\n' "$(wc -c < "$f" | tr -d ' ')" "${f#./}"; done \
  | sort -rn | head -5 | awk -F'\t' '{ printf "  %7d bytes  ~%5d tokens  %s\n", $1, $1/4, $2 }'

# ── Other evidence this script cannot count ──────────────────────────────────
printf '\nAlso read before deciding anything:\n'
command -v python3 >/dev/null 2>&1 && \
  printf '  python3 scripts/mine-sessions.py%s [--usage]   the person'"'"'s corrections, or where the tokens went\n' "${LAST:+ --since $LAST}"
git rev-parse --git-dir >/dev/null 2>&1 && \
  printf '  review comments on changes merged since %s — the same comment twice is a candidate\n' "${LAST:-the start}"
printf '  learning/journal/ entries since %s\n' "${LAST:-the start}"

printf '\n'
if [ -n "$REASONS" ]; then
  printf 'Due: %s.\n' "$REASONS"
else
  printf 'Not due by the numbers. A retro is still right if the same correction has come up twice.\n'
fi
exit 0
