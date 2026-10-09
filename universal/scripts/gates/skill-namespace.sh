#!/usr/bin/env bash
# Skill-namespace gate — the check that makes docs/decisions/0001 a rule rather
# than a paragraph.
#
# The harness ships skills whose names are ordinary words for things every team
# already does: review, release, branch, spec, requirements, verify, pr. A
# universal installer cannot assume any of them is free in someone else's repo,
# and before v1.15.0 `install.sh --force` would overwrite a team's own review
# skill in silence. Namespacing makes the collision structurally impossible
# instead of merely detected.
#
# Three checks:
#   1. every skill the harness AUTHORS lives under `harness-`
#   2. every skill's declared `name:` matches its directory
#   3. every `.agents/skills/<x>` path referenced anywhere actually resolves
#
# Check 3 is the one that earns its keep. ADR-0001 rejected the install-time
# alias option because its failure mode was "a reference pointing at a skill
# that does not exist" — silent, and found only when an agent needs the skill.
# Doing the rename by hand has exactly that failure mode, so the gate that
# enforces the convention also proves no reference was left behind.
#
# VENDORED SKILLS ARE EXEMPT, and the exemption is a LOOKUP, not a judgement:
# a directory is exempt iff skills-lock.json lists it. Vendoring means holding a
# copy of someone else's artifact, pinned by content hash so an in-place edit is
# visible. Renaming one edits its frontmatter, which forks it from upstream and
# breaks the pin — the tail wagging the dog. ADR-0001 originally claimed the
# pins would survive a rename; they did not, and this gate is where that was
# found. The ADR now records the correction.
. "$(dirname "$0")/../lib.sh"

SKILLS_DIR="$HARNESS_ROOT/.agents/skills"
[ -d "$SKILLS_DIR" ] || { ok "skill namespace (no skills directory)"; exit 0; }

PREFIX="harness-"
# The namespace rule is the HARNESS's to keep. In a repo that installed it, a
# skill called `review` under .agents/skills/ is that team's own, and demanding
# they rename it is the harness claiming authority over work it did not write —
# it would also fail `make check` on every install. scripts/install.sh sets this
# to false in the target. The other two checks below hold everywhere.
AUTHORED_HERE=$(cfg harness.authored_here true)
LOCK="$HARNESS_ROOT/skills-lock.json"

# The exempt set, read from the lockfile. A lockfile that will not parse is a
# BROKEN CHECK, not an empty exemption list: treating it as empty would fail
# every vendored skill and teach people the gate is noise.
vendored=""
if [ -f "$LOCK" ]; then
  command -v python3 >/dev/null 2>&1 || fail "python3 is required to read skills-lock.json"
  vendored=$(python3 -c "
import json,sys
try: d=json.load(open('$LOCK'))
except Exception as e: sys.stderr.write(str(e)+chr(10)); sys.exit(3)
print(' '.join(d.get('skills',{})))") || fail "skills-lock.json will not parse — refusing to read that as 'nothing is vendored'"
fi

# Match the lock key with OR without the prefix. The first version compared the
# directory name only, so a vendored skill that had been wrongly prefixed no
# longer matched its lock key, was classified as harness-authored, and sailed
# past the very check written to catch it. A check that cannot fire on the case
# it names is this harness's recurring defect — caught here by the self-test
# case, which failed for the wrong reason rather than passing quietly.
is_vendored() {
  case " $vendored " in *" $1 "*) return 0 ;; esac
  case "$1" in "$PREFIX"*) case " $vendored " in *" ${1#"$PREFIX"} "*) return 0 ;; esac ;; esac
  return 1
}

rc=0; n_owned=0; n_vendored=0
for d in "$SKILLS_DIR"/*/ "$HARNESS_ROOT"/overlays/*/files/.agents/skills/*/; do
  [ -d "$d" ] || continue
  base=$(basename "$d")
  rel=${d#"$HARNESS_ROOT"/}; rel=${rel%/}

  if is_vendored "$base"; then
    n_vendored=$((n_vendored+1))
    case "$base" in
      "$PREFIX"*) warn "$rel: vendored skills keep their UPSTREAM name — the '$PREFIX' prefix"
                  warn "    edits the frontmatter, which forks the copy and breaks its content pin."
                  rc=1 ;;
    esac
  else
    n_owned=$((n_owned+1))
    case "$base" in
      "$PREFIX"*) : ;;
      *) [ "$AUTHORED_HERE" = "true" ] || continue
         warn "$rel: a harness-authored skill must be named '$PREFIX$base'."
         warn "    Its name is not the harness's to claim in someone else's repository."
         warn "    See docs/decisions/0001-skill-namespace.md."
         rc=1 ;;
    esac
  fi

  # The declared name must match the directory, or the skill is discovered
  # under one name and referenced by another.
  if [ -f "$d/SKILL.md" ]; then
    declared=$(awk '/^---/{n++; next} n==1 && /^name:/{sub(/^name:[[:space:]]*/,""); gsub(/[[:space:]]+$/,""); print; exit} n>1{exit}' "$d/SKILL.md")
    [ -z "$declared" ] || [ "$declared" = "$base" ] || {
      warn "$rel: declares 'name: $declared' but lives in '$base'"; rc=1; }
  else
    warn "$rel: no SKILL.md"; rc=1
  fi
done

# Every referenced skill path must resolve. This is what catches a rename that
# updated 20 references and missed the 21st.
dangling=""
while IFS= read -r ref; do
  [ -n "$ref" ] || continue
  [ -d "$HARNESS_ROOT/.agents/skills/$ref" ] && continue
  # An overlay ships skills that LAND in .agents/skills/ when it is applied, so
  # a reference to one resolves even though the base tree has no such directory.
  [ -n "$(find "$HARNESS_ROOT"/overlays -type d -path "*/files/.agents/skills/$ref" 2>/dev/null)" ] && continue
  # `<name>` and friends are template placeholders, not references.
  case "$ref" in *'<'*|*'>'*|'*'|'$'*) continue ;; esac
  dangling="$dangling
      .agents/skills/$ref"
done <<EOF
$(git -C "$HARNESS_ROOT" grep -ohE '\.agents/skills/[A-Za-z0-9_<>-]+' 2>/dev/null \
  | sed 's|.*\.agents/skills/||' | sort -u)
EOF
if [ -n "$dangling" ]; then
  warn "these skill paths are referenced but do not exist:$dangling"
  warn "    A reference to a skill that is not there is the silent half of a rename."
  rc=1
fi

# Slash-form references (`/harness-spec`) are how prose actually cites a skill,
# and the path check above never sees them: it resolves `.agents/skills/<x>`
# only. The 2026-08 audit found eight live examples across rules, docs, the
# README and five skills — every one a survivor of the rename ADR-0001 records,
# and every one invisible to the check above. That is the exact failure ADR-0001
# says it rejected aliases to avoid. (This comment deliberately names none of
# them in citation form: the gate greps its own source too, and a scanner that
# fires on the file explaining it is a scanner people switch off.)
slash_dangling=""
while IFS= read -r ref; do
  [ -n "$ref" ] || continue
  [ -d "$HARNESS_ROOT/.agents/skills/$ref" ] && continue
  [ -n "$(find "$HARNESS_ROOT"/overlays -type d -path "*/files/.agents/skills/$ref" 2>/dev/null)" ] && continue
  # Only flag a bare word that looks like one of our skills stripped of its
  # prefix. Anything else in a slash is a path, a date, or a URL fragment.
  [ -d "$HARNESS_ROOT/.agents/skills/$PREFIX$ref" ] || continue
  slash_dangling="$slash_dangling
      /$ref  →  /$PREFIX$ref"
done <<EOF
$(git -C "$HARNESS_ROOT" grep -ohE '`/[A-Za-z0-9_-]+`' 2>/dev/null \
  | tr -d '`/' | sort -u)
EOF
if [ -n "$slash_dangling" ]; then
  warn "these skills are cited by their pre-prefix name:$slash_dangling"
  warn "    Prose cites skills as \`/<name>\`. A citation that resolves to nothing is"
  warn "    silent until an agent needs the skill and cannot find it."
  rc=1
fi

[ "$rc" -eq 0 ] || fail "skill namespace — see docs/decisions/0001-skill-namespace.md"
if [ "$AUTHORED_HERE" = "true" ]; then
  ok "skill namespace ($n_owned harness-authored under '$PREFIX', $n_vendored vendored at upstream names, every reference resolves)"
else
  ok "skill namespace (harness.authored_here is false — your own skills are yours; names match their directories and every reference resolves)"
fi
