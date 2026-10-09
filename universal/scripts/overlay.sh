#!/usr/bin/env bash
# Overlays — a named pack of additions applied on top of this harness.
#
#   scripts/overlay.sh list
#   scripts/overlay.sh apply <name>
#   scripts/overlay.sh verify
#
# WHY THIS EXISTS, AND THE RULE THAT MAKES IT WORK
#
# The alternative was forking the harness per domain. This project has four
# recorded examples of what that produces: two stale copies of the design skills
# (434 lines and 9 files behind), a redundant Flutter tree, and root docs that
# drifted 11 and 19 lines from their originals. A fork does not stay a variant;
# it becomes a second thing to fix everything in, and then only one gets fixed.
#
# So an overlay may ADD files and SET config keys. It may never overwrite a base
# file. If an overlay needs the base to behave differently, the base gains a
# config knob and the overlay sets it — which means the change is visible, named,
# and available to everyone rather than buried in a copy.
#
# That single constraint is the whole design. Everything below enforces it.
. "$(dirname "$0")/lib.sh"

OVERLAY_DIR="$HARNESS_ROOT/overlays"
LOCK="$HARNESS_ROOT/overlays-lock.json"

hash_dir() {
  python3 - "$1" <<'PY'
import hashlib, os, sys
root = sys.argv[1]
h = hashlib.sha256()
for dirpath, dirnames, filenames in os.walk(root):
    dirnames.sort()
    for f in sorted(filenames):
        p = os.path.join(dirpath, f)
        rel = os.path.relpath(p, root).replace(os.sep, '/')
        h.update(rel.encode()); h.update(b'\0')
        with open(p, 'rb') as fh: h.update(fh.read())
        h.update(b'\0')
print(h.hexdigest())
PY
}

meta() { # meta <overlay-dir> <key>
  awk -v k="$2" '
    $0 ~ "^[[:space:]]*" k ":" { v=$0; sub(/^[^:]*:[[:space:]]*/,"",v); sub(/[[:space:]]+#.*$/,"",v)
      gsub(/^["\x27]|["\x27]$/,"",v); print v; exit }
  ' "$1/overlay.yaml"
}

# Semver-ish: does <have> satisfy ">=<want>"?
version_ok() {
  local have="$1" want="${2#>=}"
  [ -n "$want" ] || return 0
  printf '%s\n%s\n' "$want" "$have" | sort -V -C 2>/dev/null || return 1
  return 0
}

cmd_list() {
  local found=0
  for d in "$OVERLAY_DIR"/*/; do
    [ -f "$d/overlay.yaml" ] || continue
    found=1
    local n v r applied="not applied"
    n=$(meta "$d" name); v=$(meta "$d" version); r=$(meta "$d" requires_base)
    if [ -f "$LOCK" ] && grep -q "\"$n\"" "$LOCK" 2>/dev/null; then applied="applied"; fi
    printf '  %-16s %-8s needs base %-10s  %s\n' "$n" "$v" "$r" "$applied"
    printf '      %s\n' "$(meta "$d" description)"
  done
  [ "$found" = 1 ] || info "no overlays in overlays/"
}

cmd_apply() {
  local name="${1:?usage: overlay.sh apply <name>}"
  local d="$OVERLAY_DIR/$name"
  [ -f "$d/overlay.yaml" ] || fail "no overlay '$name' in overlays/ — run 'make overlay-list'"

  local base req; base=$(cfg harness.version 0.0.0); req=$(meta "$d" requires_base)
  version_ok "$base" "$req" || fail "overlay '$name' needs base $req; this harness is $base.
    Upgrade the base, or the overlay was written against a harness that no longer exists."

  # --- the rule: an overlay may not overwrite a base file ---
  local clashes=""
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    [ -e "$HARNESS_ROOT/$rel" ] && clashes="$clashes    $rel"$'\n'
  done < <(cd "$d/files" 2>/dev/null && find . -type f | sed 's|^\./||')
  if [ -n "$clashes" ]; then
    warn "overlay '$name' would overwrite base files:"
    printf '%s' "$clashes" >&2
    fail "an overlay adds; it does not replace. If it needs the base to behave
    differently, add a config knob to the base and set it from the overlay —
    then the change is named and everyone gets it, instead of living in a copy."
  fi

  # --- copy the additions ---
  local n=0
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    mkdir -p "$HARNESS_ROOT/$(dirname "$rel")"
    cp "$d/files/$rel" "$HARNESS_ROOT/$rel"
    case "$rel" in *.sh|*.py) chmod +x "$HARNESS_ROOT/$rel" ;; esac
    n=$((n+1))
  done < <(cd "$d/files" 2>/dev/null && find . -type f | sed 's|^\./||')

  # --- apply the config patch ---
  if [ -f "$d/config.patch.yaml" ]; then
    python3 "$HARNESS_ROOT/scripts/overlay-config.py" "$CONFIG" "$d/config.patch.yaml" \
      || fail "config patch failed"
  fi

  # --- record it ---
  python3 - "$LOCK" "$name" "$(meta "$d" version)" "$req" "$(hash_dir "$d")" <<'PY'
import json, os, sys
lock, name, ver, req, h = sys.argv[1:6]
d = {"$comment": "Overlays applied to this harness. `make overlay-verify` fails if an "
                 "overlay's source changed without being re-applied, or if the base moved "
                 "below what the overlay requires.", "version": 1, "overlays": {}}
if os.path.exists(lock):
    try: d = json.load(open(lock))
    except Exception: pass
d.setdefault("overlays", {})[name] = {"version": ver, "requiresBase": req, "sourceHash": h}
json.dump(d, open(lock, "w"), indent=2); open(lock, "a").write("\n")
PY
  ok "overlay '$name' applied ($n files)"
  info "run 'make harness-sync' and 'make check'"
}

cmd_verify() {
  [ -f "$LOCK" ] || { ok "overlays (none applied)"; return 0; }
  local rc=0 n=0 base; base=$(cfg harness.version 0.0.0)
  while IFS=$'\t' read -r name _ver req want; do
    [ -n "$name" ] || continue
    n=$((n+1))
    local d="$OVERLAY_DIR/$name"
    if [ ! -d "$d" ]; then
      warn "$name: applied, but overlays/$name is gone — its files are now unowned"; rc=1; continue
    fi
    version_ok "$base" "$req" || { warn "$name needs base $req; harness is $base"; rc=1; }
    local actual; actual=$(hash_dir "$d")
    if [ "$actual" != "$want" ]; then
      warn "$name: the overlay source changed since it was applied."
      warn "    expected ${want:0:16}…  got ${actual:0:16}…"
      warn "    Re-apply it ('make overlay-apply NAME=$name') or revert the source."
      rc=1
    fi
  done < <(python3 -c "
import json,sys
d=json.load(open('$LOCK'))
for k,v in d.get('overlays',{}).items():
    print('\t'.join([k, v.get('version','?'), v.get('requiresBase',''), v.get('sourceHash','')]))")
  [ "$rc" -eq 0 ] || fail "overlays"
  ok "overlays ($n applied, sources match, base compatible)"
}

# The gates every applied overlay declares, one per line. `make check` runs these.
cmd_gates() {
  [ -f "$LOCK" ] || return 0
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    local d="$OVERLAY_DIR/$name"
    [ -f "$d/overlay.yaml" ] || continue
    awk '/^gates:/{g=1;next} g && /^[[:space:]]*-[[:space:]]/{v=$0; sub(/^[[:space:]]*-[[:space:]]*/,"",v); gsub(/[[:space:]]/,"",v); print v; next} g && /^[^[:space:]#]/{g=0}' "$d/overlay.yaml"
  done < <(python3 -c "
import json
try: d=json.load(open('$LOCK'))
except Exception: d={}
for k in d.get('overlays',{}): print(k)")
}

case "${1:-}" in
  list)   cmd_list ;;
  gates)  cmd_gates ;;
  apply)  shift; cmd_apply "$@" ;;
  verify) cmd_verify ;;
  *) fail "usage: overlay.sh list | apply <name> | verify | gates" ;;
esac
