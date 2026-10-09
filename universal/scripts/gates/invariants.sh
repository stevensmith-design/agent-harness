#!/usr/bin/env bash
# Invariant register integrity — and, above all, enforcement attribution.
#
# The failure this prevents was observed on a real handover: a domain rule that
# both sides believed the other was enforcing, so neither did. A schema cannot
# express "once per user per day" or "immutable after commit", so those rules
# lived only in the app — and the backend requirements list had to be
# reconstructed from client code after the fact.
#
# What this proves: every row names a side, from a closed vocabulary, and no row
# reaches 'agreed' still owned by nobody.
# What it CANNOT prove: that the attribution is CORRECT, or that the invariant is
# true. It catches "nobody decided", never "they decided wrong".
#
# Advisory by default (reports, exits 0). Set product.enforce_invariants: true
# once the register is real.
. "$(dirname "$0")/../lib.sh"

REG="$HARNESS_ROOT/docs/product/domain-rules.md"
[ -f "$REG" ] || { ok "invariant register (none yet)"; exit 0; }

ENFORCE=$(cfg product.enforce_invariants false)

problems=0
note() { warn "$1"; problems=$((problems + 1)); }

rows=$(sgrep -E -e '^\|[[:space:]]*INV-[0-9]+[[:space:]]*\|' -- "$REG")

# Same defect the requirement gate was fixed for: a row that does not parse must
# be reported, never skipped. A leading space or a lowercase `inv-` silently
# disappearing a row means the gate reports "consistent" on a register it did
# not fully read.
strays=$(sgrep -nE -e '^[[:space:]]+\|[[:space:]]*[Ii][Nn][Vv]-|^\|[[:space:]]*[Ii][Nn][Vv][^-]|^\|[[:space:]]*inv-' -- "$REG")
if [ -n "$strays" ]; then
  note "these lines look like register rows but do not parse as one:"
  printf '%s\n' "$strays" | sed 's/^/      /' >&2
  warn "      A row must start at column 1 with '| INV-NNN |'. No leading space or tab,"
  warn "      uppercase INV, and the ID separated by a hyphen."
fi

badpipe=$(printf '%s\n' "$rows" | awk -F'|' 'NF && NF != 8 {print $2 " (" NF-2 " columns, expected 6)"}')
if [ -n "$badpipe" ]; then
  note "these rows do not have 6 columns — escape any '|' inside the text as '\\|':"
  printf '%s\n' "$badpipe" | sed 's/^/      /' >&2
fi

[ -n "$rows" ] || { [ "$problems" -eq 0 ] && { ok "invariant register (no rows yet)"; exit 0; }; }

n=0; unassigned=0
while IFS= read -r row; do
  [ -n "$row" ] || continue
  n=$((n + 1))
  id=$(printf     '%s' "$row" | awk -F'|' '{gsub(/ /,"",$2); print $2}')
  enforced=$(printf '%s' "$row" | awk -F'|' '{gsub(/^ +| +$/,"",$4); print $4}')
  status=$(printf   '%s' "$row" | awk -F'|' '{gsub(/^ +| +$/,"",$6); print $6}')
  changed=$(printf  '%s' "$row" | awk -F'|' '{gsub(/^ +| +$/,"",$7); print $7}')

  case "$status" in
    proposed|agreed|enforced|superseded|removed) ;;
    *) note "$id: unknown status '$status'" ;;
  esac

  # The whole point of the file.
  case "$enforced" in
    client|server|both|db) ;;
    unassigned)
      unassigned=$((unassigned + 1))
      # An agreed invariant owned by nobody is the exact failure this gate exists
      # for. 'unassigned' is an honest holding value while a row is still being
      # argued about; it is not an answer.
      case "$status" in
        proposed) ;;
        *) note "$id: status '$status' but 'Enforced by' is still unassigned — an agreed invariant nobody owns is one nobody implements" ;;
      esac ;;
    "") note "$id: 'Enforced by' is empty — say which side enforces this, or write 'unassigned' and leave the row proposed" ;;
    *)  note "$id: 'Enforced by' is '$enforced' — expected one of: client, server, both, db, unassigned" ;;
  esac

  [ "$status" != "proposed" ] && { [ "$changed" = "—" ] || [ -z "$changed" ]; } \
    && note "$id: status '$status' with an empty Changed column"

  if [ "$status" = "superseded" ]; then
    target=$(printf '%s' "$changed" | sed -nE 's/.*(INV-[0-9]+).*/\1/p' | head -1)
    if [ -z "$target" ]; then
      note "$id: superseded but does not name the invariant that replaced it"
    elif ! printf '%s\n' "$rows" | awk -F'|' '{gsub(/ /,"",$2); print $2}' | grep -qx "$target"; then
      note "$id: superseded by '$target', which has no row in this register"
    fi
  fi
done <<EOD
$rows
EOD

dupes=$(printf '%s\n' "$rows" | awk -F'|' '{gsub(/ /,"",$2); print $2}' | sort | uniq -d)
[ -n "$dupes" ] && note "duplicate IDs: $(printf '%s' "$dupes" | tr '\n' ' ')"

# Reported on the success line, not silently: a register where everything is
# 'unassigned' passes every check above and has decided nothing.
tail=""
[ "$unassigned" -gt 0 ] && tail=", $unassigned unassigned"

if [ "$problems" -eq 0 ]; then
  ok "invariant register ($n rows, consistent$tail)"
  exit 0
fi
if [ "$ENFORCE" = "true" ]; then
  fail "$problems invariant register problem(s)"
fi
info "$problems invariant register problem(s) — advisory. Set product.enforce_invariants: true to gate on this."
