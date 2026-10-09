#!/usr/bin/env bash
# Record a verdict for one judge scorer.
#
#   ./evals/grade.sh 001-scoped-change no-drive-by-refactor pass "SS, reviewed the diff"
#
# The row is written with a checksum of the rubric AS IT STANDS NOW, so the
# verdict is bound to the question that was actually asked. Reword the rubric
# and this verdict stops applying — which is the point: a verdict that survives
# a change to what it judged is not evidence, it is a leftover.
. "$(dirname "$0")/../scripts/lib.sh"

CASES_DIR="$HARNESS_ROOT/$(cfg evals.cases_dir evals/cases)"
GRADES="$HARNESS_ROOT/$(cfg evals.grades_file evals/grades.tsv)"

id="${1:-}"; scorer="${2:-}"; verdict="${3:-}"; note="${4:-}"
[ -n "$id" ] && [ -n "$scorer" ] && [ -n "$verdict" ] || {
  cat >&2 <<USAGE
usage: grade.sh <case-id> <scorer-name> pass|fail "<who graded it, and why>"
USAGE
  exit 1
}
case "$verdict" in pass|fail) : ;; *) fail "verdict must be 'pass' or 'fail', not '$verdict'" ;; esac
[ -n "$note" ] || fail "a verdict with no note is an anonymous claim. Say who graded it and on what basis."

case_file=""
for f in "$CASES_DIR"/*.json; do
  [ -f "$f" ] || continue
  this=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['id'])" "$f")
  [ "$this" = "$id" ] && { case_file="$f"; break; }
done
[ -n "$case_file" ] || fail "no case with id '$id' in $CASES_DIR"

rubric=$(python3 -c "
import json,sys
d=json.load(open(sys.argv[1]))
for s in d['scorers']:
    if s['name']==sys.argv[2] and s['type']=='judge':
        print(' '.join(str(s.get('rubric','')).split())); sys.exit(0)
sys.exit(3)" "$case_file" "$scorer") || fail "case '$id' has no judge scorer named '$scorer'"

key=$(printf '%s' "$rubric" | cksum | tr -d ' ')
actor=$(git -C "$HARNESS_ROOT" config user.email 2>/dev/null || printf 'unknown')
today=$(date -u +%Y-%m-%d)

if [ ! -f "$GRADES" ]; then
  printf '# case\tscorer\trubric_cksum\tverdict\tactor\tdate\tnote\n' > "$GRADES"
  printf '# A verdict is bound to the rubric it judged. Change the rubric and the\n' >> "$GRADES"
  printf '# row below stops counting — re-grade it rather than editing the cksum.\n' >> "$GRADES"
fi

# Supersede any earlier verdict for this exact (case, scorer, rubric).
tmp="$GRADES.tmp.$$"
awk -F'\t' -v c="$id" -v s="$scorer" -v k="$key" \
  '!($1==c && $2==s && $3==k)' "$GRADES" > "$tmp"
mv "$tmp" "$GRADES"
printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$id" "$scorer" "$key" "$verdict" "$actor" "$today" "$note" >> "$GRADES"

ok "recorded: $id · $scorer · $verdict"
info "  bound to this rubric: $rubric"
