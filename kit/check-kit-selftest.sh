#!/usr/bin/env bash
# check-kit-selftest.sh — prove check-kit.sh can still fail.
#
# Every case here rigs a defect that ACTUALLY SHIPPED. The entry-routing one
# lived through six versions: "help me create a harness for X" — the sentence
# almost every engagement opens with — matched only harness-build, the skill
# that requires an already-agreed architecture document and skips the fitness
# check that can correctly end an engagement. No gate could catch it, because
# the kit's own skills sat outside every gate.
#
# A gate you have never observed failing is a gate you have no evidence works,
# and that applies to the kit's own checks as much as to the ones it ships.

. "$(dirname "$0")/core/scripts/lib.sh"
KIT="$(cd "$(dirname "$0")" && pwd)"
TMP=$(mktemp -d) || exit 1
trap 'rm -rf "$TMP"' EXIT
cp -R "$KIT/." "$TMP/" 2>/dev/null
rm -rf "$TMP/.git"

cases=0; failures=0
expect_fail() {
  local n="$1"; shift; cases=$((cases + 1))
  if ( cd "$TMP" && "$@" >/dev/null 2>&1 ); then
    printf '%s✗ selftest: %s did NOT fail%s\n' "$RED" "$n" "$RST" >&2; failures=$((failures + 1))
  else printf '%s✓%s selftest: %s rejects its violation\n' "$GRN" "$RST" "$n"; fi
}
expect_pass() {
  local n="$1"; shift; cases=$((cases + 1))
  if ( cd "$TMP" && "$@" >/dev/null 2>&1 ); then
    printf '%s✓%s selftest: %s passes a clean kit\n' "$GRN" "$RST" "$n"
  else printf '%s✗ selftest: %s fails on a CLEAN kit — false positive%s\n' "$RED" "$n" "$RST" >&2; failures=$((failures + 1)); fi
}

expect_pass "check-kit" bash check-kit.sh

# The real defect: the entry skill stops claiming the phrases people use.
cp "$TMP/skills/harness-scope/SKILL.md" "$TMP/.sc.bak"
grep -ve '^description:' -- "$TMP/.sc.bak" > "$TMP/.y"
printf 'description: Decide whether work should have a harness and design its architecture.\n' >> "$TMP/.y"
mv "$TMP/.y" "$TMP/skills/harness-scope/SKILL.md"
expect_fail "check-kit (entry skill loses the opening phrasings)" bash check-kit.sh
cp "$TMP/.sc.bak" "$TMP/skills/harness-scope/SKILL.md"

# Two front doors — the request routes by luck.
sed 's/harness\.entry: "false"/harness.entry: "true"/' "$TMP/skills/harness-build/SKILL.md" > "$TMP/.y" && mv "$TMP/.y" "$TMP/skills/harness-build/SKILL.md"
expect_fail "check-kit (two skills claim the front door)" bash check-kit.sh
sed 's/harness\.entry: "true"/harness.entry: "false"/' "$TMP/skills/harness-build/SKILL.md" > "$TMP/.y" && mv "$TMP/.y" "$TMP/skills/harness-build/SKILL.md"

# No front door at all.
sed 's/harness\.entry: "true"/harness.entry: "false"/' "$TMP/skills/harness-scope/SKILL.md" > "$TMP/.y" && mv "$TMP/.y" "$TMP/skills/harness-scope/SKILL.md"
expect_fail "check-kit (no skill claims the front door)" bash check-kit.sh
cp "$TMP/.sc.bak" "$TMP/skills/harness-scope/SKILL.md"

# A skill with no description — nothing for a host to match on.
grep -ve '^description:' -- "$TMP/skills/harness-audit/SKILL.md" > "$TMP/.y" && mv "$TMP/.y" "$TMP/skills/harness-audit/SKILL.md"
expect_fail "check-kit (skill with no description)" bash check-kit.sh

# A filesystem loader accepts metadata that portable upload refuses.
cp -R "$KIT/." "$TMP/" 2>/dev/null
awk '{print} /^license: MIT$/{print "version: 1"}' "$TMP/skills/harness-audit/SKILL.md" > "$TMP/.y" && mv "$TMP/.y" "$TMP/skills/harness-audit/SKILL.md"
expect_fail "check-kit (skill frontmatter a strict host rejects)" bash check-kit.sh

# A skill is executable instruction. Auto-confirmed package execution is not
# made safe by arriving in Markdown.
cp -R "$KIT/." "$TMP/" 2>/dev/null
printf '\nnpx --yes unreviewed-tool\n' >> "$TMP/skills/harness-audit/SKILL.md"
expect_fail "check-kit (skill contains an unsafe install instruction)" bash check-kit.sh

# A skill over the 200-line budget. The kit argues a convention without a gate is
# a paragraph; this is that argument applied to the kit's own skills.
cp -R "$KIT/." "$TMP/" 2>/dev/null
awk 'BEGIN{for(i=0;i<220;i++) print "padding line " i}' >> "$TMP/skills/harness-audit/SKILL.md"
expect_fail "check-kit (a skill over the 200-line budget)" bash check-kit.sh

# ...but blank lines and HTML comments do not count toward it, so padding a skill
# with those must NOT fail. A budget that counts whitespace is a formatting rule.
cp -R "$KIT/." "$TMP/" 2>/dev/null
awk 'BEGIN{for(i=0;i<220;i++) print ""}' >> "$TMP/skills/harness-audit/SKILL.md"
awk 'BEGIN{for(i=0;i<220;i++) print "<!-- a comment -->"}' >> "$TMP/skills/harness-audit/SKILL.md"
expect_pass "check-kit (blank lines and comments do not count toward the budget)" bash check-kit.sh
cp -R "$KIT/." "$TMP/" 2>/dev/null

# A broken reference between kit documents.
cp -R "$KIT/." "$TMP/" 2>/dev/null
printf '\nSee [the missing one](NOWHERE-AT-ALL.md).\n' >> "$TMP/README.md"
expect_fail "check-kit (broken kit reference)" bash check-kit.sh

# --- detect.sh decides all four motions, and fails closed --------------------
# The motion decides whether the engagement CREATES or ADOPTS. Getting it wrong
# on someone's real repository is the difference between helpful and
# destructive, so every branch gets a case.
mode_of() { ( cd "$KIT" && ./detect.sh "$1" 2>/dev/null | sed -n 's/^.*MODE: \([a-z]*\).*$/\1/p' | head -1 ); }
expect_mode() {
  local want="$1" dir="$2" label="$3"; cases=$((cases + 1))
  local got; got=$(mode_of "$dir")
  if [ "$got" = "$want" ]; then
    printf '%s✓%s selftest: detect %s → %s\n' "$GRN" "$RST" "$label" "$want"
  else
    failures=$((failures + 1))
    printf '%s✗ selftest: detect %s → got "%s", want "%s"%s\n' "$RED" "$label" "$got" "$want" "$RST" >&2
  fi
}

D="$TMP/detectcases"
mkdir -p "$D/green"
expect_mode greenfield "$D/green" "(empty dir)"

mkdir -p "$D/scat/docs"
awk 'BEGIN{for(i=0;i<40;i++)print "x"}' > "$D/scat/CLAUDE.md"
expect_mode scattered "$D/scat" "(CLAUDE.md with real content)"

mkdir -p "$D/over/.claude/skills/x"
printf -- '---\nname: x\n---\n' > "$D/over/.claude/skills/x/SKILL.md"
expect_mode overlay "$D/over" "(another tool's skills)"

mkdir -p "$D/harn"; printf 'name: "t"\nmode: template\n' > "$D/harn/harness.yaml"
expect_mode harness "$D/harn" "(harness.yaml present)"

# Fail closed: a near-empty instruction file must NOT read as greenfield if it
# carries real content, and a stub must not tip an empty repo into scattered.
mkdir -p "$D/stub"; printf '# TODO\n' > "$D/stub/CLAUDE.md"
expect_mode scattered "$D/stub" "(even a thin instruction file is not greenfield)"

# And detect must never write.
cases=$((cases + 1))
_before=$(find "$D/green" | wc -l)
( cd "$KIT" && ./detect.sh "$D/green" >/dev/null 2>&1 )
_after=$(find "$D/green" | wc -l)
if [ "$_before" = "$_after" ]; then
  printf '%s✓%s selftest: detect wrote nothing to the target\n' "$GRN" "$RST"
else
  failures=$((failures + 1)); printf '%s✗ selftest: detect MODIFIED the target%s\n' "$RED" "$RST" >&2
fi

# Several targets: context rarely arrives as one directory. The overall stance
# must be the most conservative motion found, whatever order the targets come in
# — a greenfield folder listed first must not mask a harness listed last.
cases=$((cases + 1))
_overall=$( cd "$KIT" && ./detect.sh "$D/green" "$D/scat" "$D/harn" 2>/dev/null | sed -n 's/^OVERALL: \([a-z]*\).*$/\1/p' | head -1 )
if [ "$_overall" = "harness" ]; then
  printf '%s✓%s selftest: detect over several targets → most conservative (harness)\n' "$GRN" "$RST"
else
  failures=$((failures + 1)); printf '%s✗ selftest: detect over several targets → got "%s", want "harness"%s\n' "$RED" "$_overall" "$RST" >&2
fi

# --- documentation claims must match reality ---------------------------------
# An external reviewer found three stale numbers no check could see. These are
# the cases that stop that recurring.
cp -R "$KIT/." "$TMP/" 2>/dev/null
sed 's/^kit_version: .*/kit_version: "9.9.9"/' "$TMP/core/harness.yaml" > "$TMP/.y" && mv "$TMP/.y" "$TMP/core/harness.yaml"
expect_fail "check-kit (version drift between README and harness.yaml)" bash check-kit.sh
cp -R "$KIT/." "$TMP/" 2>/dev/null

printf '\nzz_undocumented_key: true\n' >> "$TMP/core/harness.yaml"
expect_fail "check-kit (config key documented nowhere)" bash check-kit.sh
cp -R "$KIT/." "$TMP/" 2>/dev/null

sed 's/Of the 12 shipped keys/Of the 99 shipped keys/' "$TMP/KNOWN-GAPS.md" > "$TMP/.y" && mv "$TMP/.y" "$TMP/KNOWN-GAPS.md"
expect_fail "check-kit (stale numeric claim in the docs)" bash check-kit.sh
cp -R "$KIT/." "$TMP/" 2>/dev/null

# The surface floor. Both directions, because each was green while the other
# was broken: doctor proved every PATTERN matched a file for eleven versions
# while 30 of 51 files matched no pattern at all.
mkdir -p "$TMP/core/unclassified-zone"
printf 'a file in no lane\n' > "$TMP/core/unclassified-zone/x.md"
expect_fail "check-kit (core ships a file matching no surface)" bash check-kit.sh
cp -R "$KIT/." "$TMP/" 2>/dev/null; rm -rf "$TMP/core/unclassified-zone"

printf 'foundations/README.md\thigh\towner\toverlap\tambiguous on purpose\n' >> "$TMP/core/config/surfaces.tsv"
expect_fail "check-kit (a core file matching two surfaces)" bash check-kit.sh
cp -R "$KIT/." "$TMP/" 2>/dev/null

# The kit designs harnesses; it does not stock domains. Drop the derivation
# route from the entry skill and the front door quietly names five domains again.
grep -ve '_deriving' -- "$TMP/skills/harness-scope/SKILL.md" > "$TMP/.y" && mv "$TMP/.y" "$TMP/skills/harness-scope/SKILL.md"
expect_fail "check-kit (entry skill stops routing an uncatalogued domain)" bash check-kit.sh
cp -R "$KIT/." "$TMP/" 2>/dev/null

# Standalone means no pointer to anything that exists only on the author's
# machine. One case per leak kind, including the untracked private-terms file.
printf '\nSee /Users/someone/Desktop/old-harness for the original.\n' >> "$TMP/ANATOMY.md"
expect_fail "check-kit (personal machine path in a doc)" bash check-kit.sh
cp -R "$KIT/." "$TMP/" 2>/dev/null

printf '\nDerived from eight specimens across four domains.\n' >> "$TMP/LADDER.md"
expect_fail "check-kit (citing harnesses the reader cannot see)" bash check-kit.sh
cp -R "$KIT/." "$TMP/" 2>/dev/null

# Installing into a folder with no git records the fact: substrate: workspace.
# Left at the template's "repository", the harness fails later as a repository
# with no git — a folder harness punished for being a folder.
cases=$((cases + 1))
_ws="$TMP/.install-ws"; rm -rf "$_ws"; mkdir -p "$_ws"
( yes | bash "$KIT/install.sh" "$_ws" >/dev/null 2>&1 )
if grep -qx 'substrate: workspace' "$_ws/harness.yaml" 2>/dev/null; then
  printf '%s✓%s selftest: install into a folder with no git sets substrate: workspace\n' "$GRN" "$RST"
else
  failures=$((failures + 1)); printf '%s✗ selftest: install into a no-git folder did not set substrate: workspace%s\n' "$RED" "$RST" >&2
fi
rm -rf "$_ws"

# A kit doc whose name has spaces is ONE orphan, not one per word. The name is
# assembled at runtime so this script does not itself cite it.
cases=$((cases + 1))
_sp="Old Kit"; _sp="$_sp Notes.md"
printf '# old\n' > "$TMP/packs/$_sp"
_out=$( cd "$TMP" && bash check-kit.sh 2>&1 )
if printf '%s\n' "$_out" | grep -qF -- "orphan: ./packs/$_sp is"; then
  printf '%s✓%s selftest: check-kit (orphan whose name has spaces) reports it as one file\n' "$GRN" "$RST"
else
  failures=$((failures + 1)); printf '%s✗ selftest: check-kit did not report a spaced file name as one orphan%s\n' "$RED" "$RST" >&2
fi
rm -f "$TMP/packs/$_sp"

printf '# private names\nzzprivateclientzz\n' > "$TMP/.private-terms"
printf '\nAs zzPrivateClientzz does it.\n' >> "$TMP/SUBSTRATES.md"
expect_fail "check-kit (a term from .private-terms in a doc)" bash check-kit.sh
cp -R "$KIT/." "$TMP/" 2>/dev/null; rm -f "$TMP/.private-terms"

# A procedure's stop, escalation and re-entry. Both halves of the check, because
# each was green while the other was broken in every version of this shape: the
# heading present with nothing under it reads exactly like a filled field.
cp -R "$KIT/." "$TMP/" 2>/dev/null
grep -ve '^## Stops when$' -- "$TMP/core/procedures/_TEMPLATE.md" > "$TMP/.y" && mv "$TMP/.y" "$TMP/core/procedures/_TEMPLATE.md"
expect_fail "check-kit (the procedure template drops a required field)" bash check-kit.sh
cp -R "$KIT/." "$TMP/" 2>/dev/null

# The heading survives; its entries do not. This is the shape a field takes on
# its way to being dead config, and the half a presence check cannot see.
awk '$0=="## Escalates when"{o=1;print;next} /^## /{o=0} o&&/^- /{next} {print}' \
  "$TMP/core/procedures/session-wrapup.md" > "$TMP/.y" && mv "$TMP/.y" "$TMP/core/procedures/session-wrapup.md"
expect_fail "check-kit (a live procedure's required field is a heading over nothing)" bash check-kit.sh
cp -R "$KIT/." "$TMP/" 2>/dev/null

# ...and the template itself must stay exempt. It ships those fields EMPTY on
# purpose; a check tightened to demand entries everywhere would fail the one
# file whose job is to carry them unfilled, and the clean kit would go red.
for _h in "Stops when" "Escalates when" "Safe to re-run when"; do
  awk -v h="## $_h" '$0==h{print;print "";print "-";print "";o=1;next} /^## /{o=0} o{next} {print}' \
    "$TMP/core/procedures/_TEMPLATE.md" > "$TMP/.y" && mv "$TMP/.y" "$TMP/core/procedures/_TEMPLATE.md"
done
expect_pass "check-kit (the template carries those fields empty, and that is not a violation)" bash check-kit.sh
cp -R "$KIT/." "$TMP/" 2>/dev/null

# The kit's own case count, checked against the thing it is a count OF.
#
# check-kit greps THIS file's SOURCE for case shapes. The truth is $cases,
# which exists only here, at run time. Two counters for one number drift, and
# this one did: check-kit reported 25 while the suite ran 29 — green, because
# four hand-written cases matched no pattern it knew. Widening the pattern
# fixed that instance; it does not stop the next case shape desyncing the same
# way, silently, behind a tick. So the claim is compared to the run, here,
# where both numbers exist at once. This is check-kit's own §5 rule — counts
# are computed and then checked — applied to check-kit's own count.
cases=$((cases + 1))
_claimed=$( cd "$KIT" && bash check-kit.sh 2>/dev/null | sed -n 's/.*(\([0-9]*\) kit cases.*/\1/p' | head -1 )
if [ "${_claimed:-}" = "$cases" ]; then
  printf '%s✓%s selftest: check-kit claims the case count this suite actually runs (%s)\n' "$GRN" "$RST" "$cases"
else
  failures=$((failures + 1))
  printf '%s✗ selftest: check-kit claims %s kit cases, this suite runs %s%s\n' "$RED" "${_claimed:-nothing}" "$cases" "$RST" >&2
fi

printf '\n'
if [ "$failures" -eq 0 ]; then
  printf '%s✓ kit selftest passed%s %s(%s cases)%s\n' "$GRN" "$RST" "$DIM" "$cases" "$RST"; exit 0
fi
printf '%s✗ kit selftest: %s/%s failed%s\n' "$RED" "$failures" "$cases" "$RST" >&2; exit 1
