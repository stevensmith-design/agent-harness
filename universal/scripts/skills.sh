#!/usr/bin/env bash
# Vendor capability skills from public libraries, pinned by commit SHA.
#
#   scripts/skills.sh add <owner/repo> <skill-path> [--ref <tag-or-sha>]
#   scripts/skills.sh verify        # content still matches the lock
#   scripts/skills.sh update [name] # re-pin deliberately, showing the diff
#   scripts/skills.sh list
#
# Why not `npx skills`: that CLI is good, but its lockfile hash is a change
# DETECTOR, not a pin — `skills update` re-clones the default branch and
# rewrites the hash, and its ref handling accepts branches and tags but not
# commit SHAs. For a harness, a dependency you cannot pin to an immutable commit
# is a dependency that can change under you between two checkouts of the same
# tree. So we vendor the directory and record the commit SHA plus a content hash
# of what we actually wrote.
#
# The other reason to own this: LICENCE. The best capability skills in this
# ecosystem sit behind a real licence hazard — one major library is CC BY-SA
# (copyleft, and not a software licence at all), another ships no LICENSE file
# while its README claims MIT. Vendoring without recording that is how a
# copyleft obligation ends up inside a client deliverable.
. "$(dirname "$0")/lib.sh"

LOCK="$HARNESS_ROOT/skills-lock.json"
DEST_ROOT="$HARNESS_ROOT/.agents/skills"

command -v python3 >/dev/null 2>&1 || fail "python3 is required"

# Content hash: sha256 over every file's path + bytes, sorted. Stable across
# machines, and independent of mtime, so it detects tampering and nothing else.
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
        with open(p, 'rb') as fh:
            h.update(fh.read())
        h.update(b'\0')
print(h.hexdigest())
PY
}

lock_read() { python3 -c "
import json,sys
try: print(json.dumps(json.load(open('$LOCK'))))
except Exception: print('{\"version\":1,\"skills\":{}}')"; }

lock_write() {  # lock_write <name> <json-object>
  python3 - "$LOCK" "$1" "$2" <<'PY'
import json, sys
lock_path, name, entry = sys.argv[1], sys.argv[2], json.loads(sys.argv[3])
try:
    d = json.load(open(lock_path))
except Exception:
    d = {"version": 1, "skills": {}}
d.setdefault("$comment", "Vendored capability skills, pinned by commit SHA + content hash. "
             "Workflow skills we author live in .agents/skills/ and are NOT listed here. "
             "Verify with `make skills-verify`; re-pin with `make skills-update`.")
d.setdefault("version", 1)
d.setdefault("skills", {})
d["skills"][name] = entry
d["skills"] = dict(sorted(d["skills"].items()))   # sorted: fewer merge conflicts
json.dump(d, open(lock_path, "w"), indent=2, sort_keys=False)
open(lock_path, "a").write("\n")
PY
}

# Detect the licence of a vendored skill: frontmatter first, then a LICENSE file.
detect_license() {  # detect_license <skill-dir> <repo-clone-root>
  local sk="$1" repo="$2" lic d f
  lic=$(awk '/^---/{n++;next} n==1 && /^license:/{sub(/^license:[[:space:]]*/,""); print; exit} n>1{exit}' "$sk/SKILL.md" 2>/dev/null)
  # Only trust a frontmatter value that looks like an SPDX identifier. Real
  # skills in the wild write `license: LICENSE` or
  # `license: Complete terms in LICENSE.txt` — pointers, not licences. Taking
  # those at face value records a licence that says nothing.
  if printf '%s' "$lic" | grep -qE '^(MIT|Apache-2\.0|BSD-[23]-Clause|ISC|MPL-2\.0|GPL-[23]\.0[^ ]*|AGPL-3\.0[^ ]*|LGPL-[23]\.[01][^ ]*|CC-BY(-SA)?-4\.0|CC0-1\.0|Unlicense|Proprietary)$'; then
    printf '%s' "$lic"; return
  fi
  # Skill directory first: some libraries licence per skill, not per repo, and
  # conflating the two is how a proprietary skill inherits a permissive label.
  for d in "$sk" "$repo"; do
    for f in LICENSE LICENSE.md LICENSE.txt COPYING; do
      [ -f "$d/$f" ] || continue
      grep -qi 'Attribution-ShareAlike' "$d/$f"                    && { echo "CC-BY-SA-4.0"; return; }
      head -5 "$d/$f" | grep -qiE 'source.available|not open source|proprietary' && { echo "Proprietary"; return; }
      head -5 "$d/$f" | grep -qi  'Apache License'                 && { echo "Apache-2.0"; return; }
      head -5 "$d/$f" | grep -qi  'MIT License'                    && { echo "MIT"; return; }
      head -5 "$d/$f" | grep -qiE 'GNU (General|Affero|Lesser)'    && { echo "GPL-family"; return; }
      head -5 "$d/$f" | grep -qi  'BSD'                            && { echo "BSD-3-Clause"; return; }
      echo "UNKNOWN"; return
    done
  done
  echo "NONE"      # no usable frontmatter licence and no LICENSE file anywhere
}

cmd_add() {
  local repo="${1:?usage: skills.sh add <owner/repo> <skill-path> [--ref X]}"
  local skpath="${2:?skill path within the repo, e.g. skills/foo}"
  shift 2
  local ref="" 
  while [ $# -gt 0 ]; do case "$1" in --ref) ref="$2"; shift 2;; *) shift;; esac; done

  local url="https://github.com/$repo.git"
  local tmp; tmp=$(mktemp -d); trap 'rm -rf "$tmp"' RETURN

  info "fetching $repo${ref:+ @ $ref}"
  if [ -n "$ref" ] && printf '%s' "$ref" | grep -qE '^[0-9a-f]{40}$'; then
    # A commit SHA needs a full-ish clone; --depth 1 cannot fetch an arbitrary commit.
    git clone -q --filter=blob:none --no-checkout "$url" "$tmp/repo" || fail "clone failed"
    git -C "$tmp/repo" checkout -q "$ref" || fail "commit $ref not found in $repo"
  else
    git clone -q --depth 1 ${ref:+--branch "$ref"} --filter=blob:none --no-checkout "$url" "$tmp/repo" \
      || fail "clone failed (is '$ref' a real tag or branch?)"
    git -C "$tmp/repo" checkout -q HEAD
  fi

  local sha; sha=$(git -C "$tmp/repo" rev-parse HEAD)
  local src="$tmp/repo/$skpath"
  [ -d "$src" ] || fail "'$skpath' is not a directory in $repo at $sha"
  [ -f "$src/SKILL.md" ] || fail "'$skpath' has no SKILL.md — that is not a skill"

  local name; name=$(basename "$skpath")
  # The spec requires frontmatter name == directory name. Several public skills
  # violate this; we rename the directory to match rather than shipping a skill
  # that fails a strict validator.
  local fmname; fmname=$(awk '/^---/{n++;next} n==1 && /^name:/{sub(/^name:[[:space:]]*/,""); print; exit} n>1{exit}' "$src/SKILL.md")
  if [ -n "$fmname" ] && [ "$fmname" != "$name" ]; then
    warn "frontmatter name '$fmname' != directory '$name' — vendoring as '$fmname' so it validates"
    name="$fmname"
  fi

  local lic; lic=$(detect_license "$src" "$tmp/repo")
  # Quarantine first. A skill is executable instruction: it does not enter the
  # live discovery directory until its portable metadata and instruction shapes
  # have passed. The previous order copied first and checked only licence/hash.
  local stage_root="$tmp/staged-skills" stage="$tmp/staged-skills/$name"
  mkdir -p "$stage"; cp -R "$src/." "$stage/"
  # Record where it came from, in the skill itself, for whoever finds it later.
  printf '%s\n' \
    "# Vendored capability skill" "" \
    "Source: https://github.com/$repo/tree/$sha/$skpath" \
    "Commit: $sha" \
    "Licence: $lic" "" \
    "Do not hand-edit. Re-pin with \`make skills-update NAME=$name\`. Local changes" \
    "are lost on update and will fail \`make skills-verify\` before then." \
    > "$stage/VENDORED.md"

  python3 "$HARNESS_ROOT/scripts/validate-skills.py" "$stage_root" \
    || fail "$name failed portable skill validation; nothing was installed"
  # A reviewed quoted fixture can be excepted only by a row already naming this
  # exact future skill path. Filter out other skills' rows so their legitimate
  # exceptions do not become "stale" while the scanner examines one candidate.
  awk -F '\t' -v p="$name/" '/^[[:space:]]*#/ || /^[[:space:]]*$/ || index($1,p)==1' \
    "$HARNESS_ROOT/.agents/skill-trust-allow.tsv" > "$tmp/agent-trust-allow.tsv"
  python3 "$HARNESS_ROOT/scripts/scan-skill-trust.py" "$stage_root" "$tmp/agent-trust-allow.tsv" \
    || fail "$name contains unsafe instruction shapes; review upstream, do not bypass the scan"

  local dest="$DEST_ROOT/$name"
  rm -rf "$dest"; mkdir -p "$dest"; cp -R "$stage/." "$dest/"

  local chash; chash=$(hash_dir "$dest")
  lock_write "$name" "$(python3 -c "
import json,sys
print(json.dumps({'source':'github.com/$repo','skillPath':'$skpath','commit':'$sha',
                  'ref':'${ref:-HEAD}','license':'$lic','contentHash':'$chash'}))")"
  ok "vendored $name  ($lic, pinned to ${sha:0:12})"
  [ "$lic" = "NONE" ] || [ "$lic" = "UNKNOWN" ] && \
    warn "  no verifiable licence — 'make check' will refuse this until you resolve it"
  return 0
}

cmd_verify() {
  local rc=0 n=0
  while IFS=$'\t' read -r name chash lic; do
    [ -n "$name" ] || continue
    n=$((n+1))
    local d="$DEST_ROOT/$name"
    if [ ! -d "$d" ]; then warn "$name: in the lock but not on disk — run 'make skills-sync'"; rc=1; continue; fi
    local actual; actual=$(hash_dir "$d")
    if [ "$actual" != "$chash" ]; then
      warn "$name: content does not match its pin."
      warn "    expected ${chash:0:16}…  got ${actual:0:16}…"
      warn "    A vendored skill was edited in place. Revert it, or re-pin deliberately."
      rc=1
    fi
  done < <(python3 -c "
import json
try: d=json.load(open('$LOCK'))
except Exception: d={'skills':{}}
for k,v in d.get('skills',{}).items():
    print('\t'.join([k, v.get('contentHash',''), v.get('license','NONE')]))")
  [ "$rc" -eq 0 ] || fail "vendored skills have drifted from their pins"
  ok "vendored skills verified ($n pinned)"
}

cmd_update() {
  local only="${1:-}" rc=0
  while IFS=$'\t' read -r name repo skpath ref; do
    [ -n "$name" ] || continue
    [ -n "$only" ] && [ "$only" != "$name" ] && continue
    if [ "$repo" = "bundled" ] || [ -z "$skpath" ]; then
      warn "$name is bundled and has no immutable upstream path; automatic update refused."
      warn "    Import a reviewed source through the same quarantine checks, then update its content hash deliberately."
      rc=1
      continue
    fi
    info "re-pinning $name from $repo"
    cmd_add "${repo#github.com/}" "$skpath" ${ref:+--ref "$ref"}
  done < <(python3 -c "
import json
try: d=json.load(open('$LOCK'))
except Exception: d={'skills':{}}
for k,v in d.get('skills',{}).items():
    r=v.get('ref','HEAD')
    print('\t'.join([k, v.get('source',''), v.get('skillPath',''), '' if r=='HEAD' else r]))")
  warn "review the diff before committing — an upstream skill can change what it tells your agents to do"
  [ "$rc" -eq 0 ] || fail "one or more bundled skills require a deliberate reviewed import"
}

cmd_list() {
  python3 -c "
import json
try: d=json.load(open('$LOCK'))
except Exception: d={'skills':{}}
s=d.get('skills',{})
if not s: print('  no vendored skills. See docs/skills-catalog.md for a vetted list.'); raise SystemExit
w=max(len(k) for k in s)
for k,v in s.items():
    print(f\"  {k:<{w}}  {v.get('license','?'):<14} {v.get('source','?')}@{v.get('commit','?')[:12]}\")"
}

case "${1:-}" in
  add)    shift; cmd_add "$@" ;;
  verify) cmd_verify ;;
  update) shift; cmd_update "${1:-}" ;;
  list)   cmd_list ;;
  *) fail "usage: skills.sh add <owner/repo> <skill-path> [--ref X] | verify | update [name] | list" ;;
esac
