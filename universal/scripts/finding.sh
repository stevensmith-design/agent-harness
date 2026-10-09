#!/usr/bin/env bash
# Findings, in a grammar something can read.
#
# A review used to end in prose: "blocking · file:line · what is wrong". Perfectly
# clear to a person, and unparseable — so nothing could tell whether this review's
# findings were the same as last review's, whether a finding was ever resolved, or
# whether a verdict still applied to the code it judged.
#
# The fix is a fixed identity line, and it has to come FIRST: history accumulates
# afterwards, but only if the schema was there while it was being written. Waiting
# until there is enough history to be worth structuring is how you arrive with
# three years of unstructured findings.
#
#   IDENTITY   [severity] category · path:line · claim
#   BOOKKEEPING raised=<commit> digest=<cksum of the file when raised> status=<state>
#
# Two findings with the same identity are the same finding, whoever raised them.
# `digest` binds a finding to the bytes it judged: when the file changes, the
# finding is STALE — not resolved, not open, but re-check-me. A finding that
# outlives the code it described is the review equivalent of a green gate that
# stopped running.
#
#   scripts/finding.sh record <severity> <category> <path[:line]> "<claim>"
#   scripts/finding.sh list [--stale|--open]
#   scripts/finding.sh resolve <path[:line]> "<claim>"
. "$(dirname "$0")/lib.sh"

DIR="$HARNESS_ROOT/.agents/reviews"
branch=$(git -C "$HARNESS_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || printf 'detached')
FILE="$DIR/${branch//\//-}.md"

digest_of() {  # digest_of <path> — cksum of the file as it stands, or "-"
  local f="$HARNESS_ROOT/${1%%:*}"
  [ -f "$f" ] && cksum < "$f" | tr -d ' ' || printf '%s' -
}

cmd_record() {
  local sev="${1:?severity}" cat="${2:?category}" loc="${3:?path[:line]}" claim="${4:?claim}"
  case "$sev" in blocking|advisory) : ;; *) fail "severity must be 'blocking' or 'advisory', not '$sev'" ;; esac
  case "$cat" in *' '*|'') fail "category must be one word (correctness, security, scope, tests, a11y, …)" ;; esac
  [ "${#claim}" -ge 15 ] || fail "the claim is ${#claim} characters. State the defect, not a label — the next reader has only this line."
  case "$claim" in *' · '*) fail "the claim may not contain ' · ' — that separator delimits the identity" ;; esac
  [ -f "$HARNESS_ROOT/${loc%%:*}" ] || warn "note: ${loc%%:*} does not exist in this worktree"

  mkdir -p "$DIR"
  [ -f "$FILE" ] || {
    printf '# Review findings — %s\n\n' "$branch" > "$FILE"
    printf '<!-- One finding per line. Identity is [severity] category · path · claim.\n' >> "$FILE"
    printf '     Edit via scripts/finding.sh, not by hand: `digest` binds each finding\n' >> "$FILE"
    printf '     to the bytes it judged and is what makes staleness computable. -->\n\n' >> "$FILE"
  }
  local commit; commit=$(git -C "$HARNESS_ROOT" rev-parse --short HEAD 2>/dev/null || printf '-')
  printf -- '- [%s] %s · %s · %s · raised=%s digest=%s status=open\n' \
    "$sev" "$cat" "$loc" "$claim" "$commit" "$(digest_of "$loc")" >> "$FILE"
  ok "recorded: [$sev] $cat · $loc"
}

# A line is stale when the file it points at no longer hashes to what it did.
classify() {  # reads a line on stdin, prints open|stale|resolved
  local line="$1" status loc d_then d_now
  status=$(printf '%s' "$line" | sed -n 's/.*status=\([a-z]*\).*/\1/p')
  [ "$status" = "resolved" ] && { printf 'resolved'; return; }
  loc=$(printf '%s' "$line" | awk -F' · ' '{print $2}')
  d_then=$(printf '%s' "$line" | sed -n 's/.*digest=\([0-9-]*\).*/\1/p')
  d_now=$(digest_of "$loc")
  if [ "$d_then" != "-" ] && [ "$d_then" != "$d_now" ]; then printf 'stale'; else printf 'open'; fi
}

cmd_list() {
  local want="${1:-}" n=0 stale=0 open=0
  [ -f "$FILE" ] || { info "no findings recorded on '$branch'"; return 0; }
  while IFS= read -r line; do
    case "$line" in '- ['*) : ;; *) continue ;; esac
    local st; st=$(classify "$line")
    case "$st" in stale) stale=$((stale+1)) ;; open) open=$((open+1)) ;; esac
    case "$want" in
      --stale) [ "$st" = stale ] || continue ;;
      --open)  [ "$st" = open ]  || continue ;;
    esac
    printf '%-8s %s\n' "$st" "${line#- }"
    n=$((n+1))
  done < "$FILE"
  echo
  info "$open open · $stale stale (the file changed since the finding was raised)"
  [ "$stale" -gt 0 ] && info "  A stale finding is not resolved. Re-read it against the current code, then record or resolve."
  return 0
}

cmd_resolve() {
  local loc="${1:?path[:line]}" claim="${2:?claim}"
  [ -f "$FILE" ] || fail "no findings file for '$branch'"
  local tmp="$FILE.tmp.$$" hit=0
  while IFS= read -r line; do
    if [ "$hit" = 0 ] && [ "$line" != "${line#- [}" ] \
       && [ "$line" != "${line/ · $loc · $claim · /X}" ]; then
      printf '%s\n' "${line/status=open/status=resolved}"; hit=1
    else
      printf '%s\n' "$line"
    fi
  done < "$FILE" > "$tmp"
  [ "$hit" = 1 ] || { rm -f "$tmp"; fail "no open finding matching: $loc · $claim"; }
  mv "$tmp" "$FILE"
  ok "resolved: $loc · $claim"
}

case "${1:-list}" in
  record)  shift; cmd_record "$@" ;;
  list)    shift || true; cmd_list "${1:-}" ;;
  resolve) shift; cmd_resolve "$@" ;;
  *) fail "usage: finding.sh record|list|resolve — see the header" ;;
esac
