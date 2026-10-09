#!/usr/bin/env bash
# Design-token drift gate. Turns "follow the design system" into a grep.
#
# Rules are data, not code: they live in `design.forbid` in harness.config.yaml,
# so adding one never means editing this file. Each rule is a POSIX extended
# regex that must NOT appear in files matching `paths` and not matching `allow`.
. "$(dirname "$0")/../lib.sh"

[ "$(cfg design.enabled true)" = "true" ] || { ok "design gate disabled"; exit 0; }

# Extract the design.forbid list. Tab-separated: id, pattern, paths, allow, message.
# NOTE the separator. Splitting on a TAB looks right and is not: tab is IFS
# whitespace, so bash collapses runs of it and every empty field shifts the
# later columns left. Omitting the optional `allow:` key used to feed the rule's
# message into the exclusion regex. Unit Separator is not IFS whitespace.
RULES=$(awk -v SEP=$'\x1f' '
  /^design:/ {inD=1; next}
  /^[^[:space:]#]/ {inD=0; inF=0}
  inD && /^  forbid:/ {inF=1; next}
  inD && inF && /^  [a-z_]+:/ {inF=0}
  inF && /^[[:space:]]*-[[:space:]]*id:/ {
    if (id!="") print id SEP pat SEP paths SEP allow SEP msg
    id=$0; sub(/.*id:[[:space:]]*/,"",id); pat=""; paths=""; allow=""; msg=""; next
  }
  function unq(s) { gsub(/^["'\'']|["'\'']$/,"",s); return s }
  inF && /^[[:space:]]*pattern:/ { pat=$0;   sub(/^[[:space:]]*pattern:[[:space:]]*/,"",pat);   pat=unq(pat);   next }
  inF && /^[[:space:]]*paths:/   { paths=$0; sub(/^[[:space:]]*paths:[[:space:]]*/,"",paths);                   next }
  inF && /^[[:space:]]*allow:/   { allow=$0; sub(/^[[:space:]]*allow:[[:space:]]*/,"",allow);                   next }
  inF && /^[[:space:]]*message:/ { msg=$0;   sub(/^[[:space:]]*message:[[:space:]]*/,"",msg);   msg=unq(msg);   next }
  END { if (id!="") print id SEP pat SEP paths SEP allow SEP msg }
' "$CONFIG")

[ -n "$RULES" ] || { ok "no design.forbid rules configured"; exit 0; }

# repo_files: tracked files AND the working tree. Scanning only the index meant
# the gate could not see the file that was just written — the exact moment the
# agent loop runs `make check`.
ALL_FILES=$(repo_files)
[ -n "$ALL_FILES" ] || ALL_FILES=$(must "file listing" sh -c "cd '$HARNESS_ROOT' && find . -type f -not -path './.git/*' | sed 's|^\./||'")

violations=0
while IFS=$'\x1f' read -r id pat paths allow msg; do
  # A rule whose `pattern:` key is missing or mistyped used to be skipped in
  # silence: the config looked like a rule, the gate reported clean. Rules are
  # data, and data with no schema needs the gate to complain about its shape.
  if [ -z "${pat:-}" ]; then
    warn "[${id:-?}] design.forbid rule has no 'pattern:' key — it can never match anything."
    warn "    Fix the key or delete the rule. A rule that cannot fire is worse than no rule."
    violations=$((violations + 1)); continue
  fi
  inc=$(glob_alt "$paths"); exc=$(glob_alt "$allow")

  files="$ALL_FILES"
  [ -n "$inc" ] && [ "$inc" != '^()$' ] && files=$(printf '%s\n' "$files" | sgrep -E -e "$inc" --)
  [ -n "$exc" ] && [ "$exc" != '^()$' ] && files=$(printf '%s\n' "$files" | sgrep -vE -e "$exc" --)
  [ -n "$files" ] || continue

  hits=$(printf '%s\n' "$files" | while read -r f; do
    [ -f "$HARNESS_ROOT/$f" ] || continue
    sgrep -nEI -e "$pat" -- "$HARNESS_ROOT/$f" | cut -c1-140 | sed "s|^|$f:|"
  done)

  if [ -n "$hits" ]; then
    warn "[$id] ${msg:-forbidden pattern}"
    printf '%s\n' "$hits" | head -20 | sed 's/^/    /'
    n=$(printf '%s\n' "$hits" | wc -l | tr -d ' ')
    [ "$n" -gt 20 ] && printf '    … and %s more\n' "$((n - 20))"
    violations=$((violations + 1))
  fi
done <<< "$RULES"

[ "$violations" -eq 0 ] || fail "$violations design-token rule(s) violated — see .agents/rules/design-tokens.md"
ok "design tokens"
