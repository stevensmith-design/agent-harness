#!/usr/bin/env bash
# Vendored-skill gate. Two checks, both cheap, both catching a silent failure.
#
#   1. Integrity — every vendored skill's content still matches its pin. A
#      vendored skill edited in place is a dependency that has quietly forked:
#      the next `skills update` discards the edit, and until then nobody knows
#      the local copy differs from what the lock claims.
#
#   2. Licence — every vendored skill's licence is on this project's allowed
#      list. This is the real hazard in the skills ecosystem right now: the
#      strongest capability libraries carry CC BY-SA (copyleft, and not a
#      software licence at all), ship no LICENSE file while claiming MIT in a
#      README, or are source-available-but-not-open-source. Vendoring without
#      checking is how a copyleft obligation ends up inside a client deliverable.
. "$(dirname "$0")/../lib.sh"

LOCK="$HARNESS_ROOT/skills-lock.json"
[ -f "$LOCK" ] || { ok "skills integrity (no lockfile)"; exit 0; }

ALLOWED=$(cfg skills.allowed_licenses 'MIT, Apache-2.0, BSD-3-Clause, BSD-2-Clause, ISC' | tr -d "[]\"'" | tr ',' ' ')
# This check ran BEFORE the guard that was supposed to protect it, so a missing
# interpreter produced a raw shell error instead of the message written for it.
command -v python3 >/dev/null 2>&1 || fail "python3 is required for the skills gate — install it, or set skills.enabled: false"

# A lockfile that will not parse is a BROKEN CHECK, not an empty one. The old
# `except Exception: print(0)` turned a truncated, tampered or merge-conflicted
# lockfile — the most likely broken state this file has — into "nothing
# vendored", silently disabling both the licence and the integrity check.
n=$(python3 -c "
import json,sys
try:
    d=json.load(open('$LOCK'))
except Exception as e:
    sys.stderr.write(str(e)+chr(10)); sys.exit(3)
if not isinstance(d,dict): sys.stderr.write('lockfile is not an object'+chr(10)); sys.exit(3)
print(len(d.get('skills',{})))") || fail "skills-lock.json will not parse — refusing to read that as 'nothing vendored'.
    Fix the file (a merge conflict marker is the usual cause) or delete it."
[ "$n" -gt 0 ] || { ok "skills integrity (nothing vendored)"; exit 0; }

rc=0

# --- 1. licences ---
while IFS=$'\t' read -r name lic src; do
  [ -n "$name" ] || continue
  allowed=0
  for a in $ALLOWED; do [ "$lic" = "$a" ] && allowed=1; done
  if [ "$allowed" -eq 0 ]; then
    warn "$name — licence '$lic' is not on this project's allowed list"
    case "$lic" in
      CC-BY-SA-4.0) warn "    CC BY-SA is copyleft AND not a software licence. Modifying a vendored" 
                    warn "    skill under it plausibly attaches ShareAlike to your derivative." ;;
      NONE)         warn "    No LICENSE file and no usable frontmatter licence. A README claiming" 
                    warn "    a licence is not a licence — ask upstream to add the file." ;;
      Proprietary)  warn "    Source-available is not open source. Do not redistribute." ;;
      UNKNOWN)      warn "    A LICENSE file exists but was not recognised — read it yourself." ;;
    esac
    warn "    Fix: remove it, or add '$lic' to skills.allowed_licenses if your counsel agrees."
    warn "    Source: $src"
    rc=1
  fi
done < <(python3 -c "
import json
d=json.load(open('$LOCK'))
for k,v in d.get('skills',{}).items():
    print('\t'.join([k, v.get('license','NONE'), v.get('source','?')]))")

# --- 2. integrity ---
if ! "$HARNESS_ROOT/scripts/skills.sh" verify >/dev/null 2>&1; then
  "$HARNESS_ROOT/scripts/skills.sh" verify || true
  rc=1
fi

[ "$rc" -eq 0 ] || fail "vendored skills"
ok "vendored skills ($n pinned, licences allowed, content matches)"
