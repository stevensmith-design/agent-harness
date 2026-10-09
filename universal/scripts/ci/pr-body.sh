#!/usr/bin/env bash
# The PR body carries evidence, and says what it could not see.
#
#   BODY="$(gh pr view --json body -q .body)" scripts/ci/pr-body.sh
#   scripts/ci/pr-body.sh < body.md
#
# Moved out of the generated workflow so it can be self-tested. Inline, it had a
# never-red hole: a section counted as filled if any line survived a filter for
# lines STARTING with '<!--' or '-->' — so the middle line of the template's own
# multi-line comment counted as evidence, and an untouched template passed.
# Comments are now removed whole, across lines, before anything is counted.
#
# ci-parity: this is the CI gate; there is no local hook for a PR body.
set -uo pipefail
if [ -n "${BODY:-}" ]; then body="$BODY"; else body=$(cat); fi

strip_comments() {
  awk '{ line = $0; out = ""
    while (length(line)) {
      if (inc) { i = index(line, "-->"); if (!i) { line = ""; break }; line = substr(line, i + 3); inc = 0 }
      else     { i = index(line, "<!--"); if (!i) { out = out line; line = "" }
                 else { out = out substr(line, 1, i - 1); line = substr(line, i + 4); inc = 1 } }
    }
    print out }'
}
# section <heading> — the section's text: comments, blank lines and unticked
# template boxes removed. The heading must match exactly — "## Not verified yet"
# is not the section.
section() {
  printf '%s\n' "$body" | strip_comments \
    | tr -d '\r' \
    | awk -v h="## $1" '{ l = $0; sub(/[[:space:]]+$/, "", l) } l == h { f = 1; next } /^## / { f = 0 } f' \
    | grep -vE '^[[:space:]]*$' | grep -vE '^[[:space:]]*- \[ \]' || true
}

rc=0
err() { printf '::error::%s\n' "$1"; rc=1; }
for s in "What and why" "How this was verified" "Not verified" "Blast radius"; do
  printf '%s\n' "$body" | strip_comments | tr -d '\r' | grep -qxE "## $s[[:space:]]*" \
    || err "PR body is missing '## $s' — do not delete template sections."
done
[ -n "$(section 'How this was verified')" ] \
  || err "'How this was verified' is empty. Say what you ran and what it printed."
[ -n "$(section 'Not verified')" ] \
  || err "'Not verified' is empty. Say what no check here could see — or 'Nothing: <why>'."
[ "$rc" -eq 0 ] && printf '✓ PR body carries evidence and names what it did not see\n'
exit "$rc"
