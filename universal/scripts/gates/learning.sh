#!/usr/bin/env bash
# The learning loop — questions close into rules, and defects leave lessons.
#
# Two failures this exists for, both seen on AI-built products tested by hand:
#
#   1. A tester asks "is this intended?", someone answers in the ticket, and
#      the answer never reaches the file the implementer and the agent read.
#      The same question comes back from the next screen. So a question in
#      docs/product/questions.md may only close into a DEC-, INV- or REQ- that
#      exists — or say why no rule is needed.
#
#   2. A defect is fixed, and nothing about the fix stops the next one. So
#      every row in docs/quality/defects.md names its gap in the loop, what the
#      sweep across sibling paths found, and where the lesson now lives — and a
#      lesson must match its gap (a `test` gap is closed by a file that exists,
#      not by a sentence). When a rule breaks again on a later day, the lesson
#      recorded before did not hold; recording the SAME lesson again is refused.
#
# What this proves: every closure points at something that exists.
# What it CANNOT prove: that the rule is right, that the test tests it, or that
# the sweep was complete. It catches "nothing was learned", never "the wrong
# thing was learned". Lessons are compared after normalising case, backticks
# and punctuation — a reworded sentence is still a new string.
#
# Advisory by default (reports, exits 0). Set product.enforce_learning: true
# once the registers are in use; from then on a missing register fails too.
. "$(dirname "$0")/../lib.sh"

Q="docs/product/questions.md"
D="docs/quality/defects.md"
ENFORCE=$(cfg product.enforce_learning false)
STALE_DAYS=$(cfg product.question_stale_days 14)
case "$STALE_DAYS" in ''|*[!0-9]*) fail "product.question_stale_days must be a whole number of days, not '$STALE_DAYS'" ;; esac

problems=0
note() { warn "$1"; problems=$((problems + 1)); }
trim() { sed 's/^[[:space:]]*//; s/[[:space:]]*$//'; }
col() { printf '%s' "$1" | awk -F'|' -v c="$2" '{ print $(c + 1) }' | trim; }
# An escaped pipe in cell text must not split the cell. It is swapped for a
# placeholder before any row is split, everywhere a row is read.
unpipe() { sed 's/\\|/¦/g'; }

# has_id <ID> — the ID has a real row (not a template placeholder) in the
# register that owns its prefix.
has_id() {
  local f
  case "$1" in
    DEC-*) f="docs/product/decisions.md" ;;
    INV-*) f="docs/product/domain-rules.md" ;;
    REQ-*) f="docs/product/requirements.md" ;;
    Q-*)   f="$Q" ;;
    *) return 1 ;;
  esac
  [ -f "$HARNESS_ROOT/$f" ] || return 1
  [ -n "$(sgrep -E -e "^\|[[:space:]]*$1[[:space:]]*\|" -- "$HARNESS_ROOT/$f" | grep -v -E -e '<[a-z][^>]*>' -- || true)" ]
}
# ids_in <text> [prefixes] — register IDs in <text>, restricted to the prefixes
# given (an alternation, e.g. 'DEC|INV|REQ').
ids_in() { printf '%s' "$1" | grep -o -E -e "(${2:-DEC|INV|REQ|Q})-[0-9]+" -- || true; }

# cites_existing <text> <prefixes> — at least one ID of an allowed kind, and
# every one resolves. Prints the first unresolved ID.
cites_existing() {
  local ids id; ids=$(ids_in "$1" "$2")
  [ -n "$ids" ] || return 1
  for id in $ids; do has_id "$id" || { printf '%s' "$id"; return 1; }; done
  return 0
}

# has_file <text> — some token in <text> is a regular FILE in this repo. A
# directory, `.`, or a glob is not a check anybody runs.
has_file() {
  local t rc=1
  set -f
  for t in $(printf '%s' "$1" | tr '`,;()' '     '); do
    t=${t%%:*}
    case "$t" in */*|*.*) ;; *) continue ;; esac
    case "$t" in .|..|./|../) continue ;; esac
    [ -f "$HARNESS_ROOT/$t" ] && { rc=0; break; }
  done
  set +f
  return $rc
}

jdn() {
  printf '%s\n' "$1" | awk -F- '{ y=$1+0; m=$2+0; d=$3+0; a=int((14-m)/12); yy=y+4800-a; mm=m+12*a-3;
    print d+int((153*mm+2)/5)+365*yy+int(yy/4)-int(yy/100)+int(yy/400)-32045 }'
}
TODAY=$(jdn "$(date -u +%Y-%m-%d)")
is_date() { printf '%s' "$1" | grep -q -E -e '^20[0-9]{2}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$' --; }

# shape <file> <PREFIX> <columns> — strays, wrong widths and duplicate IDs are
# problems. Same defect the requirement gate was fixed for: a row that does not
# parse must be reported, never skipped. Runs in THIS shell so note() counts.
shape() {
  local f="$1" p="$2" want="$3" lp strays r bad dupes
  lp=$(printf '%s' "$p" | tr 'A-Z' 'a-z')
  strays=$(sgrep -n -E -e "^[[:space:]]+\|[[:space:]]*($p|$lp)-|^\|[[:space:]]*$lp-" -- "$HARNESS_ROOT/$f")
  if [ -n "$strays" ]; then
    note "$f: these lines look like rows but do not parse as one — start at column 1 with '| $p-NNN |':"
    printf '%s\n' "$strays" | sed 's/^/      /' >&2
  fi
  r=$(sgrep -E -e "^\|[[:space:]]*$p-[0-9]+[[:space:]]*\|" -- "$HARNESS_ROOT/$f" | unpipe)
  bad=$(printf '%s\n' "$r" | awk -F'|' -v w="$want" 'NF && NF != w + 2 { print $2 " (" NF-2 " columns, expected " w ")" }')
  if [ -n "$bad" ]; then
    note "$f: rows with the wrong number of columns — write a '|' inside text as '\\|':"
    printf '%s\n' "$bad" | sed 's/^/      /' >&2
  fi
  dupes=$(printf '%s\n' "$r" | awk -F'|' 'NF { gsub(/ /, "", $2); print $2 }' | sort | uniq -d)
  [ -n "$dupes" ] && note "$f: duplicate IDs: $(printf '%s' "$dupes" | tr '\n' ' ')"
  return 0
}
# rows <file> <PREFIX> <columns> — the rows that parse, and only those.
rows() {
  sgrep -E -e "^\|[[:space:]]*$2-[0-9]+[[:space:]]*\|" -- "$HARNESS_ROOT/$1" | unpipe \
    | awk -F'|' -v w="$3" 'NF == w + 2'
}
# register <file> — present, or (when enforced) a problem; never a silent green.
register() {
  opt_input "$1" && return 0
  [ "$ENFORCE" = "true" ] && note "$1 is missing — product.enforce_learning is on, so the register must exist (restore the template)"
  return 1
}

# --- questions ----------------------------------------------------------------
nq=0; open=0; stale=""
if register "$Q"; then
  shape "$Q" Q 6
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    nq=$((nq + 1))
    id=$(col "$row" 1); raised=$(col "$row" 2); q=$(col "$row" 4)
    status=$(col "$row" 5); res=$(col "$row" 6)
    is_date "$raised" || note "$id: Raised '$raised' is not a YYYY-MM-DD date"
    [ -n "$q" ] || note "$id: the question is empty"
    case "$status" in
      open)
        open=$((open + 1))
        { [ -z "$res" ] || [ "$res" = "—" ] || [ "$res" = "-" ]; } \
          || note "$id: open, but Resolution says '$res' — close it, or clear the Resolution"
        if is_date "$raised" && [ $((TODAY - $(jdn "$raised"))) -gt "$STALE_DAYS" ]; then
          stale="$stale $id"
        fi ;;
      decided)
        miss=$(cites_existing "$res" 'DEC|INV|REQ') || {
          if [ -n "$miss" ]; then note "$id: decided by '$miss', which has no row in its register"
          else note "$id: decided, but the Resolution cites no DEC-, INV- or REQ- — an answer that lives only here is an answer the implementer never reads"; fi; } ;;
      not-a-rule)
        { [ "${#res}" -ge 12 ] && [ "$res" != "—" ]; } \
          || note "$id: not-a-rule needs the reason no rule is needed — '$res' does not give one" ;;
      duplicate)
        dup=$(ids_in "$res" 'Q' | head -1)
        if [ -z "$dup" ]; then note "$id: duplicate, but the Resolution names no Q-"
        elif [ "$dup" = "$id" ]; then note "$id: marked a duplicate of itself"
        else has_id "$dup" || note "$id: duplicate of '$dup', which has no row"; fi ;;
      *) note "$id: unknown status '$status' — expected open, decided, not-a-rule or duplicate" ;;
    esac
  done <<EOQ
$(rows "$Q" Q 6)
EOQ
fi

# --- defects ------------------------------------------------------------------
nd=0; recurring=""; n_recurring=0
if register "$D"; then
  shape "$D" DEF 7
  DROWS=$(rows "$D" DEF 7)
  KEYED=""   # date <TAB> id <TAB> rule-key <TAB> normalised lesson — for recurrence
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    nd=$((nd + 1))
    id=$(col "$row" 1); date=$(col "$row" 2); rule=$(col "$row" 4)
    gap=$(col "$row" 5); sweep=$(col "$row" 6); lesson=$(col "$row" 7)
    is_date "$date" || note "$id: Date '$date' is not a YYYY-MM-DD date"

    # Recurrence is counted by the rule's ID, not its wording: "INV-004 (again)"
    # is INV-004. A rule with no ID is keyed by its text.
    rkey=""
    case "$rule" in
      ''|—|-) note "$id: Rule is empty — name the rule it broke, or write 'none' if there was none" ;;
      none) [ "$gap" = "test" ] && note "$id: gap 'test' means a rule existed and nothing checked it — name the rule" ;;
      *) rids=$(ids_in "$rule" 'DEC|INV|REQ|Q')
         for rid in $rids; do has_id "$rid" || note "$id: Rule '$rid' has no row in its register"; done
         if [ -n "$rids" ]; then rkey=$(printf '%s' "$rids" | head -1)
         else rkey=$(printf '%s' "$rule" | tr 'A-Z' 'a-z' | tr -cd 'a-z0-9'); fi ;;
    esac

    { [ -z "$sweep" ] || [ "$sweep" = "—" ] || [ "$sweep" = "-" ]; } \
      && note "$id: no sweep recorded — which other paths does this rule cover, and were they checked? ('n/a — <why>' if genuinely one path)"

    case "$lesson" in
      ''|—|-|none|None|n/a|N/A)
        note "$id: no lesson — a fix without one prevents this instance and nothing else"; continue ;;
    esac
    case "$gap" in
      spec)
        miss=$(cites_existing "$lesson" 'DEC|INV|REQ|Q') || {
          if [ -n "$miss" ]; then note "$id: lesson cites '$miss', which has no row in its register"
          else note "$id: a spec gap is closed by a rule — cite the DEC-, INV-, REQ- or Q- it now lives in"; fi; } ;;
      test)
        has_file "$lesson" || note "$id: a test gap is closed by a check — name the test, gate or scanner file (it must exist)" ;;
      render)
        { has_file "$lesson" || printf '%s' "$lesson" | grep -q -e 'human-lane' --; } \
          || note "$id: a render gap is closed by a fixture or visual check (a file that exists), or 'human-lane'" ;;
      judgement)
        { cites_existing "$lesson" 'DEC|INV|REQ' >/dev/null || has_file "$lesson" || printf '%s' "$lesson" | grep -q -e 'human-lane' --; } \
          || note "$id: a judgement gap is closed by a DEC-, a design rule (a file), or 'human-lane'" ;;
      *) note "$id: unknown gap '$gap' — expected spec, test, render or judgement" ;;
    esac
    if [ -n "$rkey" ] && is_date "$date"; then
      KEYED="$KEYED$(printf '%s\t%s\t%s\t%s' "$date" "$id" "$rkey" "$(printf '%s' "$lesson" | tr 'A-Z' 'a-z' | tr -cd 'a-z0-9/._-')")
"
    fi
  done <<EOD
$DROWS
EOD

  # Recurrence: the same rule on more than one day. Siblings a sweep finds on
  # the same day are one discovery, not a recurrence, and may share a lesson.
  # Sorted by date first, so the order rows sit in the file changes nothing.
  SORTED=$(printf '%s' "$KEYED" | sort)
  recurring=$(printf '%s\n' "$SORTED" | awk -F'\t' 'NF { if (!(($3, $1) in day)) { day[$3, $1] = 1; n[$3]++ } }
    END { for (r in n) if (n[r] > 1) printf "%s×%d ", r, n[r] }')
  n_recurring=$(printf '%s\n' "$SORTED" | awk -F'\t' 'NF { if (!(($3, $1) in day)) { day[$3, $1] = 1; n[$3]++ } }
    END { k = 0; for (r in n) if (n[r] > 1) k++; print k }')
  repeats=$(printf '%s\n' "$SORTED" | awk -F'\t' 'NF {
      k = $3 SUBSEP $4
      if ((k in first) && $1 > fdate[k]) print $2 " repeats the lesson " first[k] " recorded for " $3
      else if (!(k in first)) { first[k] = $2; fdate[k] = $1 } }')
  if [ -n "$repeats" ]; then
    while IFS= read -r line; do
      [ -n "$line" ] && note "$line — it did not hold. Record a stronger one (memory → rule → test → gate)"
    done <<EOR
$repeats
EOR
  fi
fi

[ -n "$stale" ] && warn "open longer than $STALE_DAYS days:$stale — each one is a spec gap being paid for again on every screen that raises it"
[ -n "$recurring" ] && warn "rules broken on more than one day: ${recurring}— the loop leaks here; take them to /harness-retro"

blind_spots
tail=""
[ "$open" -gt 0 ] && tail="$tail, $open open question(s)"
[ "$n_recurring" -gt 0 ] && tail="$tail, $n_recurring recurring rule(s)"
if [ "$problems" -eq 0 ]; then
  ok "learning loop ($nq question(s), $nd defect lesson(s), consistent$tail)"
  exit 0
fi
[ "$ENFORCE" = "true" ] && fail "$problems learning-loop problem(s)"
info "$problems learning-loop problem(s) — advisory. Set product.enforce_learning: true to gate on this."
