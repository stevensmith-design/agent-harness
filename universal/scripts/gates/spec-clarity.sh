#!/usr/bin/env bash
# Clarify gate. Implementation may not begin while the active spec still holds
# an unresolved ambiguity marker — the cheapest anti-hallucination device there
# is — or while it is still the shipped template wearing a feature's name.
#
# The second half exists because the first was not enough: delete the
# `[NEEDS CLARIFICATION]` line and a spec of untouched placeholders passed,
# which is `B4` in the kit's rubric — presence mistaken for content.
#
# Every rule below is derived from `specs/000-template/` at run time, never from
# a list kept here. So a `<T>` in a real spec is only a placeholder if the
# template has the same one, and adding a section to the template is enough to
# make it required — there is no second place to update.
. "$(dirname "$0")/../lib.sh"

TPL="$HARNESS_ROOT/specs/000-template"
[ -d "$HARNESS_ROOT/specs" ] || { ok "spec clarity (no specs/ directory)"; exit 0; }
specs=$(must "find specs/" find "$HARNESS_ROOT/specs" -name '*.md' -not -path '*/000-template/*')
[ -n "$specs" ] || { ok "spec clarity (no active specs)"; exit 0; }

# Fenced code blocks are quoted material, not the spec's own answers: a `##`
# heading, a `<placeholder>` or a `…` inside one is an EXAMPLE of a spec, which
# is exactly what the example spec and any spec that shows a payload contains.
# Every rule below reads the file with fences removed.
# Fenced lines are BLANKED rather than dropped, so every line number this gate
# prints still matches the file a person will open.
defenced() {  # defenced <file>
  awk '
    /^[[:space:]]*(```|~~~)/ { fence = !fence; print ""; next }
    { print (fence ? "" : $0) }
  ' "$1"
}

# Body of one section, blank lines and HTML comments removed.
section_body() {  # section_body <file> <heading>
  defenced "$1" | awk -v h="$2" '
    $0 == h { inS=1; next }
    /^## / { inS=0 }
    inS && !/^[[:space:]]*$/ && !/^[[:space:]]*<!--/ { print }
  '
}

hits=""
note() { hits="$hits$1
"; }

# Which template a real file is measured against. Name first; then the title it
# gives itself, so `012-export/export-spec.md` is still a spec. Anything else is
# checked for markers only AND SAID SO — a file this gate could not structure-check
# must never be counted in the same breath as one it did.
counterpart() {  # counterpart <file> — prints the template path, or nothing
  local base; base=$(basename "$1")
  if [ -f "$TPL/$base" ]; then printf '%s' "$TPL/$base"; return 0; fi
  case "$(head -1 "$1")" in
    '# Spec:'*)  [ -f "$TPL/spec.md" ]  && printf '%s' "$TPL/spec.md" ;;
    '# Plan:'*)  [ -f "$TPL/plan.md" ]  && printf '%s' "$TPL/plan.md" ;;
    '# Tasks:'*) [ -f "$TPL/tasks.md" ] && printf '%s' "$TPL/tasks.md" ;;
  esac
}

# A spec directory with no spec.md has nothing the structure rules can hold on
# to — and that is how a "spec" folder ends up being three loose notes.
for d in "$HARNESS_ROOT"/specs/*/; do
  case "$d" in *'/000-template/') continue ;; esac
  [ -n "$(find "$d" -maxdepth 1 -name '*.md' -print -quit)" ] || continue
  [ -f "$d/spec.md" ] || note "${d#"$HARNESS_ROOT/"}: holds .md files but no spec.md — the structure rules have nothing to check"
done

num() { case "${1:-}" in ''|*[!0-9]*) printf '0' ;; *) printf '%s' "$1" ;; esac; }
structured=0; markers_only=""; fenced_markers=0
for f in $specs; do
  rel="${f#"$HARNESS_ROOT/"}"
  # A marker inside a code fence is the SYNTAX being shown — the example spec
  # and any spec that quotes one contain it. Same rule as every check below:
  # fenced text is quoted material. What was skipped is counted and reported,
  # so "no markers" can never mean "did not look".
  while IFS= read -r line; do
    [ -n "$line" ] && note "$rel: unresolved ambiguity — $line"
  done <<< "$(defenced "$f" | sgrep -nF -e '[NEEDS CLARIFICATION' || true)"
  all_m=$(sgrep -cF -e '[NEEDS CLARIFICATION' -- "$f" || printf 0)
  vis_m=$(defenced "$f" | sgrep -cF -e '[NEEDS CLARIFICATION' || printf 0)
  fenced_markers=$((fenced_markers + $(num "$all_m") - $(num "$vis_m")))

  # 2. A field left as its ellipsis. `- Loading: …` is not a screen state —
  #    while prose that trails off mid-sentence is just prose. Only a line that
  #    is a label and an ellipsis, or an ellipsis alone, is an unfilled field.
  while IFS= read -r line; do
    [ -n "$line" ] && note "$rel: field never filled in — $line"
  done <<< "$(defenced "$f" | sgrep -n -e '^[[:space:]]*\(-[[:space:]]*\)\{0,1\}\([^:]\{0,80\}:[[:space:]]*\)\{0,1\}…[[:space:]]*$' || true)"

  tpl=$(counterpart "$f")
  if [ -z "$tpl" ]; then
    markers_only="$markers_only $rel"
    continue
  fi
  structured=$((structured + 1))

  # 1. Placeholders the template ships, still sitting in the real spec.
  #    NOTE: never `sgrep -q`. sgrep maps "no match" to empty output and exit 0,
  #    so as a boolean it is always true — which made every token report as a
  #    hit the first time this was written. Test the OUTPUT, not the status.
  while IFS= read -r tok; do
    [ -n "$tok" ] || continue
    if [ -n "$(defenced "$f" | sgrep -F -e "$tok")" ]; then
      note "$rel: still holds the template placeholder $tok"
    fi
  done <<< "$(sgrep -o -e '<[^<>]\{1,60\}>' -- "$tpl" | sort -u || true)"

  # 3. Every section the template declares, present and answered. A section may
  #    be answered with `N/A — <the reason>`; "N/A" on its own is not a reason.
  while IFS= read -r h; do
    [ -n "$h" ] || continue
    if [ -z "$(defenced "$f" | sgrep -xF -e "$h")" ]; then
      note "$rel: missing section '$h' — delete a section and nobody is reminded to answer it"
      continue
    fi
    body=$(section_body "$f" "$h")
    if [ -z "$body" ]; then
      note "$rel: '$h' is empty — answer it, or write 'N/A — <reason>'"
    elif [ "$body" = "$(section_body "$tpl" "$h")" ]; then
      note "$rel: '$h' is still the template's own words"
    else
      # "N/A" in any spelling, dash or capitalisation, with nothing after it,
      # is the section unanswered. Two ways this goes wrong, both seen here:
      # the token must be a WHOLE WORD — "Nagoya only" and "NASA feed" are
      # answers, not N/A — and a short reason is still a reason ("N/A — no UI").
      norm=$(printf '%s\n' "$body" | tr '\n' ' ' | sed 's/[[:space:]][[:space:]]*/ /g; s/^ //; s/ $//')
      verdict=$(printf '%s\n' "$norm" | awk '{
        s = $0; low = tolower(s)
        if (match(low, /^(n\/a|na|not applicable)/)) {
          rest = substr(low, RLENGTH + 1)
          # It is the N/A token only at the end or before a known separator.
          # Do not use "not ASCII alphanumeric" as the boundary: that treats
          # the first character of a non-English word as punctuation.
          if (rest == "" || rest ~ /^[[:space:]\/:;,.!?()_-]/ || rest ~ /^[—–]/) {
            s = substr(s, RLENGTH + 1)
            sub(/^[[:space:]]+/, "", s)
            sub(/^[-\/:;,.!?()_]+[[:space:]]*/, "", s)
            sub(/^[—–][[:space:]]*/, "", s)
            print "R" s
            next
          }
        }
        print "X"
      }')
      case "$verdict" in
        R*) r=${verdict#R}
            [ "${#r}" -ge 4 ] || note "$rel: '$h' says N/A with no reason — say why it does not apply" ;;
      esac
    fi
  done <<< "$(sgrep -e '^## ' -- "$tpl" || true)"
done

if [ -n "$hits" ]; then
  warn "the spec is not ready to implement from:"
  printf '%s' "$hits" | sed 's/^/    /'
  fail "spec clarity gate"
fi
fenced_note=""
[ "$fenced_markers" -gt 0 ] && fenced_note="; $fenced_markers ambiguity marker(s) inside code fences read as examples, not as work"
if [ -n "$markers_only" ]; then
  ok "spec clarity ($structured file(s) checked against specs/000-template/; markers and fields only, no template to check against:$markers_only$fenced_note)"
else
  ok "spec clarity ($structured file(s) checked against specs/000-template/$fenced_note)"
fi
