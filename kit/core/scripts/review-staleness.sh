#!/usr/bin/env bash
# review-staleness.sh — is this review saying what the last one said?
#
# Measures a review against its predecessor. The mechanism is a Jaccard
# overlap on finding identity; the valuable part is what it recommends when
# the overlap is high.
#
#   A finding that recurs across reviews has stopped being information about
#   the work. It is information about the team: someone has decided, without
#   saying so, not to act on it.
#
# So the instruction above the threshold is NOT "fix these faster". It is
# "write down why these keep surviving" — as a lesson, or as an explicit
# deferral with a reason. An open finding nobody intends to close quietly
# devalues every other finding in the file.
#
# Identity is `(category, path)` from the finding line defined in
# learning/reviews/README.md:   - [P1] category · path · claim

# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
ROOT=$(harness_root "$(dirname "$0")") || exit 1
cd "$ROOT" || exit 1

THRESHOLD=${1:-70}
DIR=learning/reviews

ids() {
  # P1 and P2 only. A P3 note recurring is not evidence of anything.
  grep -oe '^[[:space:]]*-[[:space:]]*\[P[12]\][^·]*·[^·]*·' -- "$1" 2>/dev/null \
    | sed -E 's/^[[:space:]]*-[[:space:]]*\[P[12]\][[:space:]]*//; s/[[:space:]]*·[[:space:]]*$//; s/[[:space:]]+·[[:space:]]+/·/g' \
    | sed 's/[[:space:]]*$//' \
    | sort -u
}

# Two most recent by filename date, which is why the name carries one.
set -- $(find "$DIR" -maxdepth 1 -type f -name '20*.md' 2>/dev/null | sort -r)
NEW="${1-}"; PRIOR="${2-}"

if [ -z "$NEW" ]; then
  pass "review staleness" "0 reviews on file — nothing to compare"
  finish
fi
if [ -z "$PRIOR" ]; then
  pass "review staleness" "1 review on file ($(basename "$NEW")) — no predecessor to compare"
  finish
fi

A=$(mktemp) || { fail "cannot create a temp file — refusing to report a result"; finish; }
B=$(mktemp) || { fail "cannot create a temp file — refusing to report a result"; finish; }
ids "$NEW" > "$A"; ids "$PRIOR" > "$B"

n_new=$(nlines "$A")
n_old=$(nlines "$B")

if [ "$n_new" -eq 0 ] || [ "$n_old" -eq 0 ]; then
  warn "one of the two reviews has no parseable P1/P2 finding lines — see $DIR/README.md for the required shape"
  pass "review staleness" "$(basename "$NEW"): $n_new, $(basename "$PRIOR"): $n_old findings"
  rm -f "$A" "$B"; finish
fi

INTER=$(comm -12 "$A" "$B" | nlines)
UNION=$(cat "$A" "$B" | sort -u | nlines)
PCT=$(( INTER * 100 / UNION ))

printf '%s    %s: %s findings · %s: %s findings · shared %s · union %s%s\n' \
  "$DIM" "$(basename "$NEW")" "$n_new" "$(basename "$PRIOR")" "$n_old" "$INTER" "$UNION" "$RST"

if [ "$PCT" -ge "$THRESHOLD" ]; then
  fail "${PCT}% of this review repeats the last one (threshold ${THRESHOLD}%)."
  fail "  These findings are no longer telling you about the work. Either record why they"
  fail "  keep surviving — a lesson in memory/, or an explicit deferral with a reason in the"
  fail "  review file — or close them. Do not file a third review that says the same thing."
  printf '%s    repeated:%s\n' "$DIM" "$RST"
  comm -12 "$A" "$B" | sed 's/^/      /'
else
  pass "review staleness" "${PCT}% overlap with $(basename "$PRIOR"), threshold ${THRESHOLD}%"
fi
rm -f "$A" "$B"
finish
