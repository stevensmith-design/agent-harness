#!/usr/bin/env bash
# Requirement register integrity.
#
# The failure this prevents is specific and observed: two hand-maintained
# trackers holding the same state drift apart within weeks, nothing detects it,
# and from then on nobody trusts either. This harness keeps status in exactly
# one file — this check is what proves that file still matches reality.
#
# Advisory by default (reports, exits 0). Set product.enforce_register: true
# once the register is real and you want CI to hold the line.
. "$(dirname "$0")/../lib.sh"

REG="$HARNESS_ROOT/docs/product/requirements.md"
[ -f "$REG" ] || { ok "requirement register (none yet)"; exit 0; }

ENFORCE=$(cfg product.enforce_register false)
SPECS="$HARNESS_ROOT/specs"

problems=0
note() { warn "$1"; problems=$((problems + 1)); }

# Rows look like: | REQ-014 | statement | P1 | shipped | spec | PR | changed |
rows=$(sgrep -E -e '^\|[[:space:]]*REQ-[0-9]+[[:space:]]*\|' -- "$REG")

# Anything that LOOKS like a register row but does not match is reported, never
# skipped. Silently dropping unparseable rows and then printing a row count made
# the gate report "consistent" on a register two thirds of which it never read —
# a leading space, a tab, or a lowercase `req-` was enough to disappear a row.
strays=$(sgrep -nE -e '^[[:space:]]+\|[[:space:]]*[Rr][Ee][Qq]-|^\|[[:space:]]*[Rr][Ee][Qq][^-]|^\|[[:space:]]*req-' -- "$REG")
if [ -n "$strays" ]; then
  note "these lines look like register rows but do not parse as one:"
  printf '%s\n' "$strays" | sed 's/^/      /' >&2
  warn "      A row must start at column 1 with '| REQ-NNN |'. No leading space or tab,"
  warn "      uppercase REQ, and the ID separated by a hyphen."
fi

# A '|' inside the requirement text shifts every later column, so the gate would
# validate the wrong fields and report a problem that is not the real one.
badpipe=$(printf '%s\n' "$rows" | awk -F'|' 'NF && NF != 9 {print $2 " (" NF-2 " columns, expected 7)"}')
if [ -n "$badpipe" ]; then
  note "these rows do not have 7 columns — escape any '|' inside the text as '\\|':"
  printf '%s\n' "$badpipe" | sed 's/^/      /' >&2
fi

[ -n "$rows" ] || { [ "$problems" -eq 0 ] && { ok "requirement register (no rows yet)"; exit 0; }; }

n=0
while IFS= read -r row; do
  [ -n "$row" ] || continue
  n=$((n + 1))
  id=$(printf '%s' "$row" | awk -F'|' '{gsub(/ /,"",$2); print $2}')
  status=$(printf '%s' "$row" | awk -F'|' '{gsub(/^ +| +$/,"",$5); print $5}')
  spec=$(printf '%s' "$row" | awk -F'|' '{gsub(/^ +| +$/,"",$6); print $6}')
  pr=$(printf '%s' "$row" | awk -F'|' '{gsub(/^ +| +$/,"",$7); print $7}')
  changed=$(printf '%s' "$row" | awk -F'|' '{gsub(/^ +| +$/,"",$8); print $8}')

  case "$status" in
    proposed|accepted|specced|in-progress|shipped|rejected|superseded|removed) ;;
    *) note "$id: unknown status '$status'" ;;
  esac

  # A row past 'accepted' must point at a spec that exists.
  case "$status" in
    specced|in-progress|shipped)
      if [ "$spec" = "—" ] || [ -z "$spec" ]; then
        note "$id: status '$status' but no spec linked"
      elif [ ! -d "$HARNESS_ROOT/${spec%/}" ]; then
        note "$id: spec '$spec' does not exist"
      fi ;;
  esac

  [ "$status" = "shipped" ] && { [ "$pr" = "—" ] || [ -z "$pr" ]; } \
    && note "$id: shipped with no PR recorded"

  # Every state change is dated and reasoned. A blank here is a missing record.
  [ "$status" != "proposed" ] && { [ "$changed" = "—" ] || [ -z "$changed" ]; } \
    && note "$id: status '$status' with an empty Changed column"

  if [ "$status" = "superseded" ]; then
    target=$(printf '%s' "$changed" | sed -nE 's/.*(REQ-[0-9]+).*/\1/p' | head -1)
    if [ -z "$target" ]; then
      note "$id: superseded but does not name the requirement that replaced it"
    elif ! printf '%s\n' "$rows" | awk -F'|' '{gsub(/ /,"",$2); print $2}' | grep -qx "$target"; then
      # The skill advertises this check; the gate did not perform it.
      note "$id: superseded by '$target', which has no row in this register"
    fi
  fi

  # "TBD ask Dave" is not a PR. The skill promises the shape is checked.
  if [ "$status" = "shipped" ] && [ -n "$pr" ] && [ "$pr" != "—" ]; then
    case "$pr" in
      http://*|https://*|\#[0-9]*|PR-[0-9]*) ;;
      *) note "$id: PR column is '$pr' — expected a URL, #123, or PR-123" ;;
    esac
  fi
done <<EOF
$rows
EOF

# Duplicate IDs — the register's one unbreakable invariant.
dupes=$(printf '%s\n' "$rows" | awk -F'|' '{gsub(/ /,"",$2); print $2}' | sort | uniq -d)
[ -n "$dupes" ] && note "duplicate IDs: $(printf '%s' "$dupes" | tr '\n' ' ')"

# Orphan specs — a spec directory nothing in the register claims.
if [ -d "$SPECS" ]; then
  for d in "$SPECS"/REQ-*/; do
    [ -d "$d" ] || continue
    rid=$(basename "$d" | sed -E 's/^(REQ-[0-9]+).*/\1/')
    # grep -q "$rid" over the whole row matched REQ-01 inside REQ-010, and matched
    # an ID merely MENTIONED in another row's prose. Compare the ID column.
    printf '%s\n' "$rows" | awk -F'|' '{gsub(/ /,"",$2); print $2}' | grep -qx "$rid" \
      || note "orphan spec $(basename "$d") — no register row for $rid"
  done
fi

if [ "$problems" -eq 0 ]; then
  ok "requirement register ($n rows, consistent)"
  exit 0
fi
if [ "$ENFORCE" = "true" ]; then
  fail "$problems register problem(s)"
fi
info "$problems register problem(s) — advisory. Set product.enforce_register: true to gate on this."
