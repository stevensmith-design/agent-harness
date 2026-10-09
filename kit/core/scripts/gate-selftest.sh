#!/usr/bin/env bash
# gate-selftest.sh — prove every gate can still fail.
#
# A gate you have never observed failing is a gate you have no evidence works.
# A gate that has only ever run on a clean tree has never been tested.
#
# Each case rigs the violation in a throwaway copy and asserts rejection.

. "$(dirname "$0")/lib.sh"
ROOT=$(harness_root "$(dirname "$0")") || exit 1

TMP=$(mktemp -d) || exit 1
trap 'rm -rf "$TMP"' EXIT
cp -R "$ROOT/." "$TMP/" 2>/dev/null
rm -rf "$TMP/.git"
# A maintainer may have a live local declaration in the source tree. It is
# session authority, not fixture data; copying it would pre-authorise the mixed
# change case below and make that rejection test pass without rejecting.
rm -f "$TMP/runs/.state/harness-change-declared"

cases=0; failures=0

# expect_fail NAME COMMAND... — the gate must reject the rigged tree.
expect_fail() {
  local name="$1"; shift
  cases=$((cases + 1))
  if ( cd "$TMP" && "$@" >/dev/null 2>&1 ); then
    printf '%s✗ selftest: %s did NOT fail on a rigged violation%s\n' "$RED" "$name" "$RST" >&2
    failures=$((failures + 1))
  else
    printf '%s✓%s selftest: %s rejects its violation\n' "$GRN" "$RST" "$name"
  fi
}

# expect_fail_saying NAME EXPECTED-SUBSTRING COMMAND... — reject, for the RIGHT
# reason. Plain expect_fail() treats any non-zero exit as success, so a case
# passes just as happily when the fixture never applied, a different gate blew
# up, or the script died on a typo. Every case below that rigs a surfaces-table
# violation must name the message it expects to see.
expect_fail_saying() {
  local name="$1" want="$2"; shift 2
  cases=$((cases + 1))
  local out rc
  out=$( cd "$TMP" && "$@" 2>&1 ); rc=$?
  if [ "$rc" -eq 0 ]; then
    printf '%s✗ selftest: %s did NOT fail on a rigged violation%s\n' "$RED" "$name" "$RST" >&2
    failures=$((failures + 1))
  elif ! printf '%s' "$out" | grep -qFe "$want" --; then
    printf '%s✗ selftest: %s failed, but not for its reason — no %s%s%s in the output%s\n' \
      "$RED" "$name" "$RST$DIM" "$want" "$RED" "$RST" >&2
    failures=$((failures + 1))
  else
    printf '%s✓%s selftest: %s rejects its violation, saying so\n' "$GRN" "$RST" "$name"
  fi
}

expect_pass() {
  local name="$1"; shift
  cases=$((cases + 1))
  if ( cd "$TMP" && "$@" >/dev/null 2>&1 ); then
    printf '%s✓%s selftest: %s passes a clean tree\n' "$GRN" "$RST" "$name"
  else
    printf '%s✗ selftest: %s fails on a CLEAN tree — false positive%s\n' "$RED" "$name" "$RST" >&2
    failures=$((failures + 1))
  fi
}

# --- clean-tree baseline: EVERY gate, no exceptions ---------------------------
# A false positive gets a gate disabled within a week, and the one gate missing
# its clean-tree case was the one that shipped two of them.
expect_pass "check-budget"    bash scripts/check-budget.sh
expect_pass "capability-safety" bash scripts/gates/capability-safety.sh
expect_pass "dead-config"     bash scripts/gates/dead-config.sh
expect_pass "content-split"   bash scripts/gates/harness-content-split.sh
expect_pass "doctor"          bash scripts/doctor.sh
expect_pass "check"           bash scripts/check.sh
expect_pass "first-contact"   bash scripts/gates/first-contact.sh
expect_pass "resolve-surface (--all)" bash scripts/resolve-surface.sh --all

# --- budget: over the limit ---------------------------------------------------
CONST=$(cd "$TMP" && bash -c '. scripts/lib.sh; cfg constitution AGENTS.md')
cp "$TMP/$CONST" "$TMP/.const.bak"
for i in $(seq 1 200); do printf 'rule line %s\n' "$i" >> "$TMP/$CONST"; done
expect_fail "check-budget (over limit)" bash scripts/check-budget.sh
cp "$TMP/.const.bak" "$TMP/$CONST"

# --- budget: constitution deleted --------------------------------------------
mv "$TMP/$CONST" "$TMP/.const.gone"
expect_fail "check-budget (file absent)" bash scripts/check-budget.sh
mv "$TMP/.const.gone" "$TMP/$CONST"

# --- dead-config: a key nothing reads ----------------------------------------
# The probe key is ASSEMBLED, never written literally. A literal would appear
# in this file, which dead-config searches — so the gate would correctly find a
# reader and the case would silently never test anything. (It did, first try.)
_p1=zzdead; _p2=probe; PROBE_KEY="${_p1}_cfg_${_p2}"
printf '\n%s: true\n' "$PROBE_KEY" >> "$TMP/harness.yaml"
expect_fail "dead-config (unread key)" bash scripts/gates/dead-config.sh
grep -ve "$PROBE_KEY" -- "$TMP/harness.yaml" > "$TMP/.y" && mv "$TMP/.y" "$TMP/harness.yaml"

# --- dead-config: a reference to a file that does not exist -------------------
printf '\nSee [the missing rule](rules/does-not-exist.md).\n' >> "$TMP/$CONST"
expect_fail "dead-config (broken reference)" bash scripts/gates/dead-config.sh
cp "$TMP/.const.bak" "$TMP/$CONST"

# --- doctor: a missing organ --------------------------------------------------
mv "$TMP/evidence/approvals.md" "$TMP/.appr.bak" 2>/dev/null
expect_fail "doctor (missing organ)" bash scripts/doctor.sh
mv "$TMP/.appr.bak" "$TMP/evidence/approvals.md" 2>/dev/null

# --- check.sh: propagates a gate failure, rather than the last pipe stage ------
printf '#!/usr/bin/env bash\nexit 1\n' > "$TMP/scripts/gates/zz-forced-fail.sh"
chmod +x "$TMP/scripts/gates/zz-forced-fail.sh"
expect_fail "check.sh (propagates failure)" bash scripts/check.sh
rm -f "$TMP/scripts/gates/zz-forced-fail.sh"

# --- doctor: a gate that cannot parse is a gate that never fires --------------
cp "$TMP/scripts/gates/dead-config.sh" "$TMP/.dc.bak"
printf '\nif then fi\n' >> "$TMP/scripts/gates/dead-config.sh"
expect_fail_saying "doctor (gate with a syntax error)" "syntax error" bash scripts/doctor.sh
mv "$TMP/.dc.bak" "$TMP/scripts/gates/dead-config.sh"

# --- no executable bits: a harness in a shared drive or a downloaded zip -------
# Sync tools and downloads strip the executable bit. Everything must still run
# through `bash`, and doctor must not call that a failure.
find "$TMP/scripts" -name '*.sh' -exec chmod -x {} +
expect_pass "check.sh (no executable bits anywhere)" bash scripts/check.sh
expect_pass "doctor (no executable bits anywhere)" bash scripts/doctor.sh
find "$TMP/scripts" -name '*.sh' -exec chmod +x {} +

# --- doctor: sync conflict copies and unreadable cloud shortcuts --------------
# Two people editing a shared-drive harness at once leave two versions of a
# rule; a Google Doc in a synced folder is a link, not text the agent can read.
cp "$TMP/GOVERNANCE.md" "$TMP/GOVERNANCE (1).md"
expect_fail_saying "doctor (sync conflict copy beside its original)" "sync conflict copy" bash scripts/doctor.sh
rm -f "$TMP/GOVERNANCE (1).md"
printf '{"doc_id":"x"}\n' > "$TMP/foundations/brand.gdoc"
expect_fail_saying "doctor (cloud shortcut inside an organ)" "cloud shortcut, not content" bash scripts/doctor.sh
rm -f "$TMP/foundations/brand.gdoc"

# --- checkpoint: the point work passes when there is no commit ---------------
expect_pass "checkpoint (clean tree, by hand)" bash scripts/checkpoint.sh
# As a Stop hook it must BLOCK (exit 2) on a failing guardrail, and must let go
# after three attempts so an unfixable check cannot trap a session.
mkdir -p "$TMP/foundations/personal"; printf 'x\n' > "$TMP/foundations/personal/me.md"
( cd "$TMP" && git add -f foundations/personal/me.md >/dev/null 2>&1 ) || true
cases=$((cases + 1))
_rcs=""; _last=""
for _i in 1 2 3 4; do
  _last=$( cd "$TMP" && printf '{"session_id":"selftest"}' | CLAUDE_PROJECT_DIR="$TMP" bash scripts/checkpoint.sh --hook 2>/dev/null ); _rcs="$_rcs$?"
done
# Letting go must tell the person, and on exit 0 only stdout JSON reaches them.
printf '%s' "$_last" | grep -qFe '{"systemMessage":"Finished without a passing checkpoint' -- || _rcs="$_rcs (no systemMessage when letting go)"
if [ "$_rcs" = "2220" ]; then
  printf '%s✓%s selftest: checkpoint hook blocks a failing guardrail, then lets go after 3 attempts\n' "$GRN" "$RST"
else
  failures=$((failures + 1)); printf '%s✗ selftest: checkpoint hook exit codes were %s, want 2220%s\n' "$RED" "$_rcs" "$RST" >&2
fi
( cd "$TMP" && git rm -r -q --cached foundations/personal >/dev/null 2>&1 ) || true
rm -rf "$TMP/foundations/personal" "$TMP/.harness/local"

# --- dead-config: a file name with spaces is ONE file -------------------------
# The name is assembled at runtime: written literally here, this script would
# itself cite the file, and the orphan check would rightly find it referenced.
_sp="Old Meeting"; _sp="$_sp Notes.md"
printf '# Old notes\n' > "$TMP/foundations/$_sp"
expect_fail_saying "dead-config (orphan whose name has spaces)" "orphan: ./foundations/$_sp is" bash scripts/gates/dead-config.sh
rm -f "$TMP/foundations/$_sp"

# --- doctor: a surface pattern that matches nothing ---------------------------
cp "$TMP/config/surfaces.tsv" "$TMP/.sf.bak"
printf 'nowhere/never/*\thigh\towner\tmatches nothing\tshould fail\n' >> "$TMP/config/surfaces.tsv"
expect_fail "doctor (surface matches nothing)" bash scripts/doctor.sh
cp "$TMP/.sf.bak" "$TMP/config/surfaces.tsv"

# --- doctor: an empty LOG is not a defect -------------------------------------
# The negative direction of the content_status ladder. A log starts empty and
# that is its correct day-one state; only organs that must carry content fail
# as stubs. Without this case, "make doctor stricter" quietly breaks day one.
cp "$TMP/evidence/approvals.md" "$TMP/.ap.bak"
: > "$TMP/evidence/approvals.md"
expect_pass "doctor (empty log is a legitimate state)" bash scripts/doctor.sh
cp "$TMP/.ap.bak" "$TMP/evidence/approvals.md"

# --- check-budget: a non-numeric budget must not fall into the pass branch ----
# In `[ ]` the error branch IS the false branch, so a malformed number silently
# becomes a passing check.
cp "$TMP/loading-order.md" "$TMP/.lo0.bak"
sed 's/^\*\*Budget: 60 lines\.\*\*/**Budget: sixty lines.**/' "$TMP/loading-order.md" > "$TMP/.y" && mv "$TMP/.y" "$TMP/loading-order.md"
expect_fail "check-budget (non-numeric budget)" bash scripts/check-budget.sh
cp "$TMP/.lo0.bak" "$TMP/loading-order.md"

# --- content-split: harness and content in one change -------------------------
( cd "$TMP" && git init -q . && git add -A >/dev/null 2>&1 && \
  git -c user.email=t@t -c user.name=t commit -qm base >/dev/null 2>&1 ) || true
printf '\n# harness edit\n' >> "$TMP/scripts/lib.sh"
printf 'content edit\n' >> "$TMP/memory/README.md"
expect_fail "content-split (mixed change)" bash scripts/gates/harness-content-split.sh
# ...and that declaring intent releases it
( cd "$TMP" && bash scripts/declare-harness-change.sh "selftest" >/dev/null 2>&1 )
expect_pass "content-split (declared)" bash scripts/gates/harness-content-split.sh
rm -f "$TMP/runs/.state/harness-change-declared"

# --- first-contact: work begun inside an unconfigured harness -----------------
# Both directions, because the whole value of this gate is the boundary: a
# template with nothing in it is fine, and the same template with one real
# foundation file in it is not.
printf 'the brand voice is...\n' > "$TMP/foundations/brand.md"
expect_fail "first-contact (work begun, still template)" bash scripts/gates/first-contact.sh
cp "$TMP/harness.yaml" "$TMP/.hy2.bak"
sed 's/^mode: template/mode: instance/' "$TMP/harness.yaml" > "$TMP/.y" && mv "$TMP/.y" "$TMP/harness.yaml"
expect_pass "first-contact (work begun, configured)" bash scripts/gates/first-contact.sh
cp "$TMP/.hy2.bak" "$TMP/harness.yaml"
rm -f "$TMP/foundations/brand.md"

# --- session-start hook: must never block, in any state ----------------------
# A SessionStart hook that can fail the session gets removed within a day, so
# "exits 0 even when the harness is broken" is the property worth asserting.
expect_pass "session hook (template state)" bash scripts/hooks/session-start.sh
mv "$TMP/harness.yaml" "$TMP/.hy3.bak"
expect_pass "session hook (no harness.yaml at all)" bash scripts/hooks/session-start.sh
mv "$TMP/.hy3.bak" "$TMP/harness.yaml"
rm -rf "$TMP/.harness/local"

# --- session hook: announces first contact when the config is a template -----
if ( cd "$TMP" && bash scripts/hooks/session-start.sh 2>/dev/null | grep -qe 'FIRST CONTACT' -- ); then
  cases=$((cases + 1)); printf '%s✓%s selftest: session hook announces FIRST CONTACT\n' "$GRN" "$RST"
else
  cases=$((cases + 1)); failures=$((failures + 1))
  printf '%s✗ selftest: session hook did NOT announce FIRST CONTACT on a template harness%s\n' "$RED" "$RST" >&2
fi
rm -rf "$TMP/.harness/local"

# --- session hook: a CONFIGURED harness must NOT announce first contact ------
# The positive case above was passing while the hook cried first contact at a
# fully configured harness that had one leftover placeholder. Testing only the
# direction you expect to fire is how a false positive ships.
cp "$TMP/harness.yaml" "$TMP/.hy4.bak"
sed 's/^mode: template/mode: instance/' "$TMP/harness.yaml" > "$TMP/.y" && mv "$TMP/.y" "$TMP/harness.yaml"
mkdir -p "$TMP/runs/2026-01-01-selftest"; printf 'x\n' > "$TMP/runs/2026-01-01-selftest/out.md"
cases=$((cases + 1))
if ( cd "$TMP" && bash scripts/hooks/session-start.sh 2>/dev/null | grep -qe 'FIRST CONTACT' -- ); then
  failures=$((failures + 1))
  printf '%s✗ selftest: session hook cried FIRST CONTACT at a CONFIGURED harness%s\n' "$RED" "$RST" >&2
else
  printf '%s✓%s selftest: session hook stays quiet on a configured harness\n' "$GRN" "$RST"
fi
rm -rf "$TMP/runs/2026-01-01-selftest" "$TMP/.harness/local"
cp "$TMP/.hy4.bak" "$TMP/harness.yaml"

# --- budget: the SET, not one file -------------------------------------------
# The point of the contract is that content cannot be moved sideways into a
# second always-loaded file to get under the number.
cp "$TMP/loading-order.md" "$TMP/.lo.bak"
printf 'x\n%.0s' $(seq 1 90) > "$TMP/second-always-loaded.md"
sed 's|^- `AGENTS.md`$|- `AGENTS.md`\n- `second-always-loaded.md`|' "$TMP/loading-order.md" > "$TMP/.y" && mv "$TMP/.y" "$TMP/loading-order.md"
expect_fail "check-budget (set over budget)" bash scripts/check-budget.sh
cp "$TMP/.lo.bak" "$TMP/loading-order.md"

# --- budget: a Tier 2 bullet must NOT be counted ------------------------------
# Counting the whole contract file would count an on-demand set documented in
# the same file, and fail falsely.
# Section scoping is the fix, and this is the case that proves it.
sed 's|^- `foundations/` — when generating anything$|- `second-always-loaded.md`|' "$TMP/loading-order.md" > "$TMP/.y" && mv "$TMP/.y" "$TMP/loading-order.md"
expect_pass "check-budget (Tier 2 bullet not counted)" bash scripts/check-budget.sh
cp "$TMP/.lo.bak" "$TMP/loading-order.md"
rm -f "$TMP/second-always-loaded.md"

# --- budget: a declared file that does not exist ------------------------------
sed 's|^- `AGENTS.md`$|- `AGENTS.md`\n- `does-not-exist.md`|' "$TMP/loading-order.md" > "$TMP/.y" && mv "$TMP/.y" "$TMP/loading-order.md"
expect_fail "check-budget (declared file absent)" bash scripts/check-budget.sh
cp "$TMP/.lo.bak" "$TMP/loading-order.md"

# --- budget: no contract at all -----------------------------------------------
mv "$TMP/loading-order.md" "$TMP/.lo.gone"
expect_fail "check-budget (no contract)" bash scripts/check-budget.sh
mv "$TMP/.lo.gone" "$TMP/loading-order.md"

# --- review staleness: both directions ----------------------------------------
printf -- '- [P1] false-green · scripts/doctor.sh · warns instead of failing\n- [P1] dead-config · harness.yaml · key read by nothing\n' > "$TMP/learning/reviews/2026-01-01-a.md"
printf -- '- [P1] false-green · scripts/doctor.sh · still warns\n- [P1] dead-config · harness.yaml · still unread\n' > "$TMP/learning/reviews/2026-02-01-b.md"
expect_fail "review-staleness (review repeats the last one)" bash scripts/review-staleness.sh
printf -- '- [P1] data-boundary · AGENTS.md · no personal-data rule\n- [P2] overlay · packs/_overlay.md · contradiction\n' > "$TMP/learning/reviews/2026-03-01-c.md"
expect_pass "review-staleness (fresh findings)" bash scripts/review-staleness.sh
rm -f "$TMP/learning/reviews/2026-0"*.md

# --- content_status: presence is not content ----------------------------------
# An organ that exists and says nothing must not grade as a pass. This is the
# difference between an unpacked template and a configured harness.
cp "$TMP/harness.yaml" "$TMP/.hy5.bak"
sed 's/^mode: template/mode: instance/' "$TMP/harness.yaml" > "$TMP/.y" && mv "$TMP/.y" "$TMP/harness.yaml"
printf 'x\n' > "$TMP/foundations/real.md"          # satisfy the foundations check
cp "$TMP/GOVERNANCE.md" "$TMP/.gov.bak"
printf '# GOVERNANCE\n\n<!-- nothing here yet -->\n' > "$TMP/GOVERNANCE.md"
expect_fail "doctor (organ present but a stub)" bash scripts/doctor.sh
cp "$TMP/.gov.bak" "$TMP/GOVERNANCE.md"

# --- foundations empty in instance mode ---------------------------------------
rm -f "$TMP/foundations/real.md"
expect_fail "doctor (instance mode, no foundations written)" bash scripts/doctor.sh
cp "$TMP/.hy5.bak" "$TMP/harness.yaml"

# --- doctor: rubrics is an organ ---------------------------------------------
mv "$TMP/rubrics/README.md" "$TMP/.rb.bak"
expect_fail "doctor (rubrics method missing)" bash scripts/doctor.sh
mv "$TMP/.rb.bak" "$TMP/rubrics/README.md"

# --- every exemplar declares its kind ----------------------------------------
# The kind decides the shape, the starting rung, and whether a gate is reachable
# at all. An exemplar that does not declare one teaches the wrong lesson.
cases=$((cases + 1))
_missing_kind=0
for _f in "$TMP"/rubrics/examples/*-*.md; do
  grep -qe '^kind:[[:space:]]*\(mechanical\|structural\|judgement\)$' -- "$_f" || _missing_kind=1
done
if [ "$_missing_kind" -eq 0 ]; then
  printf '%s✓%s selftest: every rubric exemplar declares a valid kind\n' "$GRN" "$RST"
else
  failures=$((failures + 1))
  printf '%s✗ selftest: a rubric exemplar has no valid kind: field%s\n' "$RED" "$RST" >&2
fi

# --- records must NOT be orphans ---------------------------------------------
# Filing a judged example, a review and an ADR is what a first real run
# produces. All three used to fail the orphan check at the moment of creation,
# which turned the step the kit says never to skip into a red gate.
printf -- '- judged good\n' > "$TMP/learning/corpus/accepted/2026-01-02-x.md"
printf -- '- [P1] cat · path · claim\n' > "$TMP/learning/reviews/2026-01-02-r.md"
cp "$TMP/decisions/0000-template.md" "$TMP/decisions/0001-x.md"
expect_pass "dead-config (records are not orphans)" bash scripts/gates/dead-config.sh
rm -f "$TMP/learning/corpus/accepted/2026-01-02-x.md" "$TMP/learning/reviews/2026-01-02-r.md" "$TMP/decisions/0001-x.md"

# --- a genuine orphan is still caught -----------------------------------------
# The probe FILENAME is assembled, never written literally — the orphan check
# matches on basename across every doc and script, this file included, so a
# literal name would find itself and the case would test nothing. Second time
# this exact trap has been hit.
_o1=orph; _o2=probe; PROBE_DOC="${_o1}-${_o2}.md"
printf -- '# probe\n\nnothing points here\n' > "$TMP/procedures/$PROBE_DOC"
expect_fail "dead-config (a real orphan still fails)" bash scripts/gates/dead-config.sh
rm -f "$TMP/procedures/$PROBE_DOC"

# --- doctor: unmerged install collisions --------------------------------------
mkdir -p "$TMP/.harness-incoming" && printf 'x\n' > "$TMP/.harness-incoming/AGENTS.md"
expect_fail "doctor (unmerged install collisions)" bash scripts/doctor.sh
rm -rf "$TMP/.harness-incoming"

# --- declared intent expires --------------------------------------------------
( cd "$TMP" && git init -q . && git add -A >/dev/null 2>&1 && \
  git -c user.email=t@t -c user.name=t commit -qm base >/dev/null 2>&1 ) || true
printf '\n# harness edit\n' >> "$TMP/scripts/lib.sh"
printf 'content\n' >> "$TMP/memory/README.md"
mkdir -p "$TMP/runs/.state"
printf 'old\t1\tstale declaration\n' > "$TMP/runs/.state/harness-change-declared"
touch -t 202001010000 "$TMP/runs/.state/harness-change-declared" 2>/dev/null
expect_fail "content-split (stale declaration does not unlock)" bash scripts/gates/harness-content-split.sh
rm -f "$TMP/runs/.state/harness-change-declared"

# --- skills-sync: drift is caught ---------------------------------------------
cp "$TMP/.claude/skills/harness-retro/SKILL.md" "$TMP/.sk.bak"
printf '\nedited by hand\n' >> "$TMP/.claude/skills/harness-retro/SKILL.md"
expect_fail "skills-sync (generated skill edited by hand)" bash scripts/gates/skills-sync.sh
cp "$TMP/.sk.bak" "$TMP/.claude/skills/harness-retro/SKILL.md"

# --- a procedure with no description cannot generate a skill ------------------
cp "$TMP/procedures/harness-retro.md" "$TMP/.pr.bak"
grep -ve '^description:' -- "$TMP/procedures/harness-retro.md" > "$TMP/.y" && mv "$TMP/.y" "$TMP/procedures/harness-retro.md"
expect_fail "skills-sync (procedure has no description)" bash scripts/gates/skills-sync.sh
cp "$TMP/.pr.bak" "$TMP/procedures/harness-retro.md"

# --- an orphaned generated skill is residue -----------------------------------
mkdir -p "$TMP/.claude/skills/gone" && printf -- '---\nname: gone\n---\n' > "$TMP/.claude/skills/gone/SKILL.md"
expect_fail "skills-sync (skill whose procedure is gone)" bash scripts/gates/skills-sync.sh
rm -rf "$TMP/.claude/skills/gone"

# --- data boundary: three rules, all directions --------------------------------
( cd "$TMP" && git init -q . && git add -A >/dev/null 2>&1 ) || true
expect_pass "data-boundary (clean tree)" bash scripts/gates/data-boundary.sh

# --- capability intake: quarantine, trust scan and provenance pin ------------
mkdir -p "$TMP/capabilities/unlocked"
printf -- '---\nname: unlocked\ndescription: Safe-looking fixture whose missing provenance is the defect.\nlicense: MIT\n---\n\n# Fixture\n' > "$TMP/capabilities/unlocked/SKILL.md"
expect_fail_saying "capability-safety (skill bypasses intake lock)" "absent from capabilities-lock.json" \
  bash scripts/gates/capability-safety.sh
rm -rf "$TMP/capabilities/unlocked"

mkdir -p "$TMP/capabilities/unsafe"
printf -- '---\nname: unsafe\ndescription: Fixture for instruction-shape scanning.\nlicense: MIT\n---\n\n# Fixture\n\nnpx --yes unreviewed-tool\n' > "$TMP/capabilities/unsafe/SKILL.md"
expect_fail_saying "capability-safety (skill instructs an unsafe install)" "T1-install" \
  bash scripts/gates/capability-safety.sh
rm -rf "$TMP/capabilities/unsafe"

# --- runtime boundary: stop disclosure and package execution before output ----
printf '{"tool_name":"Read","tool_input":{"file_path":"%s/.env"}}' "$TMP" > "$TMP/.hook-secret.json"
printf '{"tool_name":"Read","tool_input":{"file_path":"%s/.env.sample"}}' "$TMP" > "$TMP/.hook-sample.json"
printf '{"tool_name":"Bash","tool_input":{"command":"npm install unreviewed"}}' > "$TMP/.hook-install.json"
printf '{"tool_name":"Bash","tool_input":{"command":"cat .env .env.sample"}}' > "$TMP/.hook-mixed.json"
expect_fail_saying "runtime hook (sensitive read)" "sensitive file contents" \
  bash -c 'CLAUDE_PROJECT_DIR="$1" bash scripts/hooks/block-sensitive-runtime.sh < .hook-secret.json' _ "$TMP"
expect_pass "runtime hook (public sample)" \
  bash -c 'CLAUDE_PROJECT_DIR="$1" bash scripts/hooks/block-sensitive-runtime.sh < .hook-sample.json' _ "$TMP"
expect_fail_saying "runtime hook (sample cannot mask secret)" "sensitive file" \
  bash -c 'CLAUDE_PROJECT_DIR="$1" bash scripts/hooks/block-sensitive-runtime.sh < .hook-mixed.json' _ "$TMP"
expect_fail_saying "runtime hook (agent package install)" "does not let an agent install" \
  bash -c 'CLAUDE_PROJECT_DIR="$1" bash scripts/hooks/block-sensitive-runtime.sh < .hook-install.json' _ "$TMP"
rm -f "$TMP/.hook-secret.json" "$TMP/.hook-sample.json" "$TMP/.hook-install.json" "$TMP/.hook-mixed.json"

# --- surface-resolution: the GATE, on a tree that actually has git -------------
# Both of this gate's cases used to run before `git init`, so both took the
# no-git early return and the entire --changed path was never executed by any
# test — you could replace the gate with `exit 0` and the suite stayed 60/60.
# One case was even NAMED for the gate while invoking the resolver directly.
# COMMIT FIRST. With an unborn HEAD, `git add -A` leaves all 53 files in the
# index diff, so the gate correctly reports 53 examined and an assertion of
# "1 examined" fails against working code. The fixture has to create a real
# delta, not just a staged tree.
# Identity passed with -c, never written to config: a machine with no global
# user.email fails `git commit` silently, `|| true` swallows it, and the fixture
# is left in the unborn-HEAD state it was meant to leave. The case then fails on
# working code, which is how a real gate gets deleted.
( cd "$TMP" && git -c user.email=selftest@invalid -c user.name=selftest \
    commit -qm selftest-baseline >/dev/null 2>&1 ) || true
expect_pass "surface-resolution (clean tree, with git)" bash scripts/gates/surface-resolution.sh

printf 'x\n' >> "$TMP/foundations/README.md"
cases=$((cases + 1))
_chg=$( cd "$TMP" && bash scripts/gates/surface-resolution.sh 2>&1 )
if printf '%s' "$_chg" | grep -qFe "1 examined" --; then
  printf '%s✓%s selftest: surface-resolution sees the changed file\n' "$GRN" "$RST"
else
  printf '%s✗ selftest: the gate went green without seeing the changed file%s\n' "$RED" "$RST" >&2
  printf '%s\n' "$_chg" | sed 's/^/      /' >&2
  failures=$((failures + 1))
fi

# A non-ASCII filename. git C-quotes these unless -z/core.quotepath=false, and a
# quoted path matches no file on disk — so it left the change set entirely and
# the gate reported a SMALLER denominator with a green tick. It failed on one
# machine and passed on another, because core.quotepath is per-clone.
_j1=$(printf '\346\227\245'); _j2=$(printf '\346\234\254')
printf 'x\n' > "$TMP/foundations/${_j1}${_j2}.md"
cases=$((cases + 1))
_chg=$( cd "$TMP" && bash scripts/gates/surface-resolution.sh 2>&1 )
if printf '%s' "$_chg" | grep -qFe "2 examined" --; then
  printf '%s✓%s selftest: surface-resolution counts a non-ASCII filename\n' "$GRN" "$RST"
else
  printf '%s✗ selftest: a non-ASCII filename fell out of the change set%s\n' "$RED" "$RST" >&2
  printf '%s\n' "$_chg" | sed 's/^/      /' >&2
  failures=$((failures + 1))
fi
rm -f "$TMP/foundations/${_j1}${_j2}.md"

# The gate must carry a real failure through, not just its early return.
cp "$TMP/config/surfaces.tsv" "$TMP/.sf3.bak"
printf 'foundations/README.md\thigh\towner\toverlap\tambiguous on purpose\n' >> "$TMP/config/surfaces.tsv"
expect_fail_saying "surface-resolution gate (overlap reaches the gate)" "must be disjoint" \
  bash scripts/gates/surface-resolution.sh
cp "$TMP/.sf3.bak" "$TMP/config/surfaces.tsv"
( cd "$TMP" && git checkout -- foundations/README.md 2>/dev/null ) || true

# substrate: repository with no git is a change-set check that can never run.
# Template mode is exempt — nothing has been set up yet — so the case has to
# flip mode too, or it tests the exemption instead of the rule.
cp "$TMP/harness.yaml" "$TMP/.hy.bak"
# Substrate is set explicitly: an install into a folder with no git writes
# substrate: workspace, and this case must not depend on which one it copied.
sed -e 's/^mode: template/mode: instance/' -e 's/^substrate:.*/substrate: repository/' "$TMP/.hy.bak" > "$TMP/harness.yaml"
mv "$TMP/.git" "$TMP/.git-off"
expect_fail_saying "surface-resolution (repository substrate, no git)" "can never run here" \
  bash scripts/gates/surface-resolution.sh
# The same folder declared as what it is — a workspace — is not a failure.
sed -e 's/^mode: template/mode: instance/' -e 's/^substrate:.*/substrate: workspace/' "$TMP/.hy.bak" > "$TMP/harness.yaml"
expect_pass "surface-resolution (workspace substrate, no git)" bash scripts/gates/surface-resolution.sh
mv "$TMP/.git-off" "$TMP/.git"
cp "$TMP/.hy.bak" "$TMP/harness.yaml"


mkdir -p "$TMP/foundations/personal"; printf 'how I work\n' > "$TMP/foundations/personal/x.md"
( cd "$TMP" && git add -f foundations/personal/x.md >/dev/null 2>&1 )
expect_fail "data-boundary (personal path tracked)" bash scripts/gates/data-boundary.sh
( cd "$TMP" && git rm -r --cached foundations/personal >/dev/null 2>&1 ); rm -rf "$TMP/foundations/personal"

printf 'placeholder only\n' > "$TMP/.env.production"
( cd "$TMP" && git add -f .env.production >/dev/null 2>&1 )
expect_fail_saying "data-boundary (sensitive filename tracked)" "sensitive file type" \
  bash scripts/gates/data-boundary.sh
( cd "$TMP" && git rm --cached .env.production >/dev/null 2>&1 ); rm -f "$TMP/.env.production"

# Assembled at runtime — a literal key in this file would be found by the gate
# that scans this file. Third time this trap has come up.
_k1=sk; _k2=abcdefghijklmnopqrstuvwxyz012345
printf 'api_key = "%s-%s"\n' "$_k1" "$_k2" > "$TMP/foundations/cfg.md"
( cd "$TMP" && git add foundations/cfg.md >/dev/null 2>&1 )
expect_fail "data-boundary (secret material)" bash scripts/gates/data-boundary.sh
( cd "$TMP" && git rm --cached foundations/cfg.md >/dev/null 2>&1 ); rm -f "$TMP/foundations/cfg.md"

_a=someone; _b=example.co.jp
printf 'contact: %s@%s\n' "$_a" "$_b" > "$TMP/foundations/c.md"
( cd "$TMP" && git add foundations/c.md >/dev/null 2>&1 )
expect_fail "data-boundary (structured personal data)" bash scripts/gates/data-boundary.sh
printf 'foundations/c.md\n' >> "$TMP/.pii-allow"
expect_pass "data-boundary (reviewed .pii-allow exception)" bash scripts/gates/data-boundary.sh
( cd "$TMP" && git rm --cached foundations/c.md >/dev/null 2>&1 ); rm -f "$TMP/foundations/c.md"
expect_fail_saying "data-boundary (stale .pii-allow exception)" "matches no current file" \
  bash scripts/gates/data-boundary.sh
grep -ve '^foundations/c\.md$' -- "$TMP/.pii-allow" > "$TMP/.y" && mv "$TMP/.y" "$TMP/.pii-allow"


# --- surface resolution: the reverse direction ---------------------------------
# doctor's forward check (a pattern matching nothing) is tested above. These
# test the direction that was missing entirely: given a file, which lane is it
# in? Each rigs ONE malformation and names the message it expects, so a case
# cannot pass because something else broke.
cp "$TMP/config/surfaces.tsv" "$TMP/.sf2.bak"
# printf '%b', never printf "$1". The argument is DATA: as a format string, the
# first fixture containing a % would be silently mangled and its case would pass
# for the wrong reason. %b still expands the \t and \n these fixtures need.
_sf() { cp "$TMP/.sf2.bak" "$TMP/config/surfaces.tsv"; printf '%b' "$1" >> "$TMP/config/surfaces.tsv"; }

# Two rows, one file. Max-risk would silently resolve this; approval has no max.
#
# The patterns are `?.md` and `[ab].md`, NOT a nested pair — nesting is caught
# earlier now, at validation, so a nested fixture would exercise the overlap
# check and never reach this code path. These two overlap without either
# matching the other as a string, which is exactly the case the pairwise check
# admits it cannot see. This case is the evidence that the per-file backstop is
# load-bearing rather than decorative.
mkdir -p "$TMP/zzB"; printf 'x\n' > "$TMP/zzB/a.md"
_sf 'zzB/?.md\thigh\towner\tone char\tx\nzzB/[ab].md\tlow\tnone\tone of a,b\tx\n'
expect_fail_saying "resolve-surface (one file, two surfaces)" "matches 2 surfaces" \
  bash scripts/resolve-surface.sh --all
expect_fail_saying "doctor (ambiguous surfaces)" "do not resolve cleanly" \
  bash scripts/doctor.sh
rm -rf "$TMP/zzB"

# A value outside the closed vocabulary. Assembled, not literal: a bare word
# like the risk levels appears all over this tree, and a literal would be found
# by the gates that scan it — the trap that has now cost four defects.
_r1=CRIT; _r2=ICAL
_sf "zz1/*\t${_r1}${_r2}\towner\tbad risk\tx\n"
expect_fail_saying "resolve-surface (risk outside the vocabulary)" "risk must be low, medium or high" \
  bash scripts/resolve-surface.sh --all
_a1=some; _a2=body
_sf "zz2/*\thigh\t${_a1}${_a2}\tbad approval\tx\n"
expect_fail_saying "resolve-surface (approval outside the vocabulary)" "approval must be owner, reviewer or none" \
  bash scripts/resolve-surface.sh --all

# A tab inside a prose field shifts every field after it. This is the one that
# classifies silently and wrongly rather than erroring.
_sf 'zz3/*\thigh\towner\twhy with\ta stray tab\tx\n'
expect_fail_saying "resolve-surface (stray tab in prose)" "more than 5 tab-separated fields" \
  bash scripts/resolve-surface.sh --all
_sf 'zz4/*\thigh\towner\tonly four fields\n'
expect_fail_saying "resolve-surface (too few fields)" "needs 5 tab-separated fields" \
  bash scripts/resolve-surface.sh --all

# The second row can never be the one that applies, so it is a lie about policy.
_sf 'memory/*\tlow\tnone\tduplicate\tx\n'
expect_fail_saying "resolve-surface (pattern declared twice)" "is declared twice" \
  bash scripts/resolve-surface.sh --all
_sf '/abs/*\thigh\towner\tabsolute\tx\n'
expect_fail_saying "resolve-surface (absolute pattern)" "is absolute" \
  bash scripts/resolve-surface.sh --all

# A fallback with a narrow override. Both patterns match something, so doctor's
# forward check is green; the per-file ambiguity check is ALSO green until
# somebody creates a file in the overlap — months later, and not the person who
# wrote the config. Caught at write time now.
_sf 'zzC/*\thigh\towner\tbroad\tx\nzzC/never/*\tlow\tnone\tnarrow override\tx\n'
expect_fail_saying "resolve-surface (nested patterns overlap)" "must be disjoint" \
  bash scripts/resolve-surface.sh --all

# A pattern naming a directory. doctor's old `find -path` parser scored this as
# covered; the resolver can never match a file with it. That disagreement is
# why there is now one reader.
_sf 'foundations\thigh\towner\tdirectory not file\tx\n'
expect_fail_saying "resolve-surface (pattern matching no file)" "matches no file" \
  bash scripts/resolve-surface.sh --all

cp "$TMP/.sf2.bak" "$TMP/config/surfaces.tsv"

# An empty surfaces table classifies nothing while looking configured.
: > "$TMP/config/surfaces.tsv"
expect_fail_saying "resolve-surface (empty surfaces table)" "nothing is classified" \
  bash scripts/resolve-surface.sh --all
cp "$TMP/.sf2.bak" "$TMP/config/surfaces.tsv"

# The resolver is the ONLY reader. If it goes missing, doctor must say so
# rather than losing the check quietly — a gate that cannot run never fires.
mv "$TMP/scripts/resolve-surface.sh" "$TMP/.rs.bak"
expect_fail_saying "doctor (resolver missing)" "nothing checks that a file lands in exactly one lane" \
  bash scripts/doctor.sh
mv "$TMP/.rs.bak" "$TMP/scripts/resolve-surface.sh"

# --- runtime assumptions, checked on the machine actually running ------------
# The kit is written on Linux/bash 5/GNU coreutils and run on macOS/bash 3.2/BSD.
# A `sort` without -z returns NOTHING for a NUL stream, so every file set would
# be empty and every gate would report a green zero — the failure this suite
# exists to make impossible. Rigged with a stub `sort` earlier in PATH.
mkdir -p "$TMP/.fakebin"
printf '#!/usr/bin/env bash\nfor a in "$@"; do case "$a" in -*z*) exit 2 ;; esac; done\nexec /usr/bin/sort "$@"\n' \
  > "$TMP/.fakebin/sort"
chmod +x "$TMP/.fakebin/sort"
cases=$((cases + 1))
_rt=$( cd "$TMP" && PATH="$TMP/.fakebin:$PATH" bash scripts/resolve-surface.sh --all 2>&1 ); _rtrc=$?
if [ "$_rtrc" -ne 0 ] && printf '%s' "$_rt" | grep -qFe "cannot sort a NUL-delimited stream" --; then
  printf '%s✓%s selftest: resolve-surface refuses a userland whose sort lacks -z\n' "$GRN" "$RST"
else
  printf '%s✗ selftest: a broken sort produced rc=%s instead of a named refusal%s\n' "$RED" "$_rtrc" "$RST" >&2
  printf '%s\n' "$_rt" | tail -2 | sed 's/^/      /' >&2
  failures=$((failures + 1))
fi
rm -rf "$TMP/.fakebin"

# --- the two record-forging guards, which survived deletion with a green suite -
# Mutation testing found both: delete either check and gate-selftest, check-kit
# and check-kit-selftest all stayed green. A check no case can kill is a check
# nobody is maintaining.

# A path carrying a tab or newline splits its own --records line and forges a
# second one. check-kit.sh parses those records with `cut`, so a file named
# "x<tab>high<tab>owner<tab>y.md" handed it a fabricated row and it reported
# "0 unclassified" while the resolver had just said 1.
#
# The fixture is built with printf into a variable, never as a literal path in
# this file: a literal would be a tab in a source line that other gates scan.
_tabname="$TMP/foundations/zztab$(printf '\t')high$(printf '\t')owner.md"
if printf 'x\n' > "$_tabname" 2>/dev/null; then
  expect_fail_saying "resolve-surface (tab in a path forges a record)" "no line-based record can represent it" \
    bash scripts/resolve-surface.sh --all
  rm -f "$_tabname"
else
  printf '%s! selftest: filesystem refused a tab in a filename — case skipped%s\n' "$YEL" "$RST" >&2
fi

# $'\n', not $(printf '\n'): command substitution strips trailing newlines, so
# the fixture built an ordinary filename and the case passed while testing
# nothing. It reported "did NOT fail" only because the tab case sets the same
# expectation — otherwise this would have been a silent green.
_nlname="$TMP/foundations/zznl"$'\n'"zz.md"
if printf 'x\n' > "$_nlname" 2>/dev/null; then
  expect_fail_saying "resolve-surface (newline in a path forges a record)" "no line-based record can represent it" \
    bash scripts/resolve-surface.sh --all
  rm -f "$_nlname"
else
  printf '%s! selftest: filesystem refused a newline in a filename — case skipped%s\n' "$YEL" "$RST" >&2
fi

# A directory is not a file. Without this the mutant gave scripts/gates the lane
# of scripts/* — a classification for something that cannot be changed.
expect_fail_saying "resolve-surface (a directory is not a file)" "is a directory" \
  bash scripts/resolve-surface.sh scripts/gates

# Provably disjoint patterns must NOT be rejected. `runs/[0-9]*` and
# `runs/[!0-9]*` cannot both match anything — a character is a digit or it is
# not — yet the overlap check read the literal `[` of one as a filename the
# other matched, and blocked a legitimate policy with no override. A false
# positive in a gate is worse than a missing check: it gets the gate deleted.
mkdir -p "$TMP/runs/2026-01-01" "$TMP/runs/archive"
printf 'x\n' > "$TMP/runs/2026-01-01/out.md"; printf 'x\n' > "$TMP/runs/archive/old.md"
cp "$TMP/.sf2.bak" "$TMP/config/surfaces.tsv"
grep -ve '^runs/\*' -- "$TMP/.sf2.bak" > "$TMP/config/surfaces.tsv"
printf 'runs/[0-9]*\tlow\tnone\tdated output\tx\nruns/[!0-9]*\tmedium\treviewer\teverything else under runs\tx\n' \
  >> "$TMP/config/surfaces.tsv"
expect_pass "resolve-surface (disjoint character classes are allowed)" \
  bash scripts/resolve-surface.sh --all
cp "$TMP/.sf2.bak" "$TMP/config/surfaces.tsv"
rm -rf "$TMP/runs/2026-01-01" "$TMP/runs/archive"

# An empty set is a RESULT and must carry its denominator. Testing only the
# direction you expect to fire is how a false positive ships.
_zero=$( cd "$TMP" && printf '' | bash scripts/resolve-surface.sh - 2>&1 )
cases=$((cases + 1))
if printf '%s' "$_zero" | grep -qFe "0 examined" --; then
  printf '%s✓%s selftest: resolve-surface reports the zero denominator\n' "$GRN" "$RST"
else
  printf '%s✗ selftest: resolve-surface went green over an empty set without saying so%s\n' "$RED" "$RST" >&2
  failures=$((failures + 1))
fi

# --- the improvement loop: retro evidence, the due reminder, transcripts -------
# The retro is only as good as what it is shown. These cases rig the evidence
# and assert the counts, in both directions: a reminder that never fires is a
# loop that never runs, and one that fires on a quiet harness gets ignored.

# check_out NAME WANT COMMAND... — output must contain WANT ("" = must be empty),
# exit status ignored. For scripts that report rather than gate.
check_out() {
  local name="$1" want="$2"; shift 2
  cases=$((cases + 1))
  local out; out=$( cd "$TMP" && "$@" 2>&1 )
  if { [ -z "$want" ] && [ -z "$out" ]; } || { [ -n "$want" ] && printf '%s' "$out" | grep -qFe "$want" --; }; then
    printf '%s✓%s selftest: %s\n' "$GRN" "$RST" "$name"
  else
    printf '%s✗ selftest: %s — wanted %s, got: %s%s\n' "$RED" "$name" "${want:-no output}" "$(printf '%s' "$out" | head -3)" "$RST" >&2
    failures=$((failures + 1))
  fi
}

mkdir -p "$TMP/runs/.state"
cp "$TMP/learning/retros.md" "$TMP/.retros.bak"
[ -f "$TMP/runs/.state/checkpoints" ] && cp "$TMP/runs/.state/checkpoints" "$TMP/.cp.bak"
_today=$(date -u +%Y-%m-%d)

printf '| %s | selftest | 41 | 0 | 0 | 0 |\n' "$_today" >> "$TMP/learning/retros.md"
: > "$TMP/runs/.state/checkpoints"
check_out "retro-evidence --due is silent right after a retro" "" bash scripts/retro-evidence.sh --due

printf '2020-01-02T00:00:00Z\tfail\tx\n2020-01-03T00:00:00Z\tfail\tx\n2020-01-04T00:00:00Z\tfail\tx\n' > "$TMP/runs/.state/checkpoints"
check_out "retro-evidence --due ignores failures from before the last retro" "" bash scripts/retro-evidence.sh --due

cp "$TMP/.retros.bak" "$TMP/learning/retros.md"
printf '| 2020-01-01 | selftest | 30 | 0 | 0 | 0 |\n' >> "$TMP/learning/retros.md"
check_out "retro-evidence --due fires on failed checkpoints since the last retro" "3 failed checkpoints" bash scripts/retro-evidence.sh --due
check_out "retro-evidence reports always-loaded growth against the last retro" "since the last retro: net zero" bash scripts/retro-evidence.sh

# A standard broken again after its lesson was recorded is the loop leaking —
# that alone makes a retro due. Two finds from one sweep, same day, are not.
cp "$TMP/learning/findings.md" "$TMP/.findings.bak"
printf '| 2020-01-02 | wrong fee in a proposal | rubrics/pricing.md | check | 4 proposals | a pricing check step |\n| 2020-01-02 | same, found by the sweep | rubrics/pricing.md | check | swept | a pricing check step |\n' >> "$TMP/learning/findings.md"
check_out "retro-evidence: two finds from one sweep are not a recurrence" "Broken again      none" bash scripts/retro-evidence.sh
printf '| 2020-01-09 | wrong fee again | rubrics/pricing.md | check | 6 proposals | a gate over every proposal |\n' >> "$TMP/learning/findings.md"
check_out "retro-evidence --due fires when a standard breaks again after its lesson" "broken again after a lesson" bash scripts/retro-evidence.sh --due
cp "$TMP/.findings.bak" "$TMP/learning/findings.md"; rm -f "$TMP/.findings.bak"

# It must write nothing. Compare every file's checksum before and after.
_sum() { ( cd "$TMP" && find . -type f -not -path './.git/*' -exec cksum {} + 2>/dev/null | sort ); }
_before=$(_sum); ( cd "$TMP" && bash scripts/retro-evidence.sh >/dev/null 2>&1 ); _after=$(_sum)
cases=$((cases + 1))
if [ "$_before" = "$_after" ]; then
  printf '%s✓%s selftest: retro-evidence writes nothing\n' "$GRN" "$RST"
else
  failures=$((failures + 1)); printf '%s✗ selftest: retro-evidence changed files in the harness%s\n' "$RED" "$RST" >&2
fi

# The size a retro records must be the size the gate enforces.
_gate=$( cd "$TMP" && bash scripts/check-budget.sh 2>&1 | sed -n 's/.*(\([0-9]\{1,\}\)\/[0-9]\{1,\} lines.*/\1/p' )
_size=$( cd "$TMP" && bash scripts/check-budget.sh --size | cut -d' ' -f1 )
cases=$((cases + 1))
if [ -n "$_gate" ] && [ "$_gate" = "$_size" ]; then
  printf '%s✓%s selftest: check-budget --size agrees with the gate (%s lines)\n' "$GRN" "$RST" "$_size"
else
  failures=$((failures + 1)); printf '%s✗ selftest: check-budget --size says %s, the gate says %s%s\n' "$RED" "$_size" "$_gate" "$RST" >&2
fi

# The reminder reaches the session, and a broken evidence script never blocks it.
sed -i.bak 's/^mode:.*/mode: instance/' "$TMP/harness.yaml"; rm -f "$TMP/harness.yaml.bak"
mkdir -p "$TMP/runs/2020-01-05-selftest"
check_out "session-start passes on a due retro" "Retro due" env CLAUDE_PROJECT_DIR="$TMP" bash scripts/hooks/session-start.sh
cp "$TMP/scripts/retro-evidence.sh" "$TMP/.re.bak"; printf 'exit 3\n' > "$TMP/scripts/retro-evidence.sh"
expect_pass "session-start (evidence script broken)" env CLAUDE_PROJECT_DIR="$TMP" bash scripts/hooks/session-start.sh
cp "$TMP/.re.bak" "$TMP/scripts/retro-evidence.sh"
rm -rf "$TMP/runs/2020-01-05-selftest" "$TMP/.harness/local"
sed -i.bak 's/^mode:.*/mode: template/' "$TMP/harness.yaml"; rm -f "$TMP/harness.yaml.bak"

cp "$TMP/.retros.bak" "$TMP/learning/retros.md"
if [ -f "$TMP/.cp.bak" ]; then cp "$TMP/.cp.bak" "$TMP/runs/.state/checkpoints"; else rm -f "$TMP/runs/.state/checkpoints"; fi

# A journal entry is a record, not an orphaned document.
printf '## 2020-01-01 · selftest\n- Corrected: none\n' > "$TMP/learning/journal/2020-01.md"
expect_pass "dead-config (a journal entry is a record, not an orphan)" bash scripts/gates/dead-config.sh
rm -f "$TMP/learning/journal/2020-01.md"

# The decision log is an organ.
mv "$TMP/decisions/log.md" "$TMP/.dlog.bak"
expect_fail_saying "doctor (decision log missing)" "missing organ: decisions/log.md" bash scripts/doctor.sh
mv "$TMP/.dlog.bak" "$TMP/decisions/log.md"

# Writing the journal and the decision log DURING work is the habit these files
# exist for; the split gate must not treat it as a harness change. A fresh repo,
# because the cases above leave harness edits in the shared one.
_cs=$(mktemp -d) && cp -R "$ROOT/." "$_cs/" 2>/dev/null && rm -rf "$_cs/.git"
( cd "$_cs" && git init -q . && git add -A >/dev/null 2>&1 && \
  git -c user.email=t@t -c user.name=t commit -qm base >/dev/null 2>&1 ) || true
printf 'content\n' >> "$_cs/foundations/README.md"
printf '## 2020-01-01 · selftest\n- Corrected: none\n' > "$_cs/learning/journal/2020-01.md"
printf '| 2020-01-01 | selftest decision | x | proposed | x |\n' >> "$_cs/decisions/log.md"
cases=$((cases + 1))
if ( cd "$_cs" && bash scripts/gates/harness-content-split.sh >/dev/null 2>&1 ); then
  printf '%s✓%s selftest: content-split treats the journal and decision log as work, not harness\n' "$GRN" "$RST"
else
  failures=$((failures + 1)); printf '%s✗ selftest: content-split called a journal entry or decision a harness change%s\n' "$RED" "$RST" >&2
fi
rm -rf "$_cs"

# Transcript mining keeps only what the person typed. Tool output and the
# agent's own words contain the same phrases, and counting them would turn every
# failing command into a "correction".
if command -v python3 >/dev/null 2>&1; then
  _tx="$TMP/.tx"; mkdir -p "$_tx"
  {
    printf '%s\n' '{"type":"assistant","timestamp":"2030-01-02T00:00:00Z","message":{"content":[{"type":"text","text":"AGENTWORDS you forgot again"}]}}'
    printf '%s\n' '{"type":"user","timestamp":"2030-01-02T00:00:01Z","message":{"content":[{"type":"tool_result","content":"TOOLWORDS you forgot again"}]}}'
    printf '%s\n' '{"type":"user","timestamp":"2030-01-02T00:00:02Z","isMeta":true,"message":{"content":"METAWORDS again"}}'
    printf '%s\n' '{"type":"user","timestamp":"2030-01-02T00:00:03Z","message":{"content":"PERSONWORDS you used the old template again"}}'
  } > "$_tx/s.jsonl"
  cases=$((cases + 1))
  _mo=$( cd "$TMP" && python3 scripts/mine-sessions.py --dir "$_tx" --since 2030-01-01 2>&1 )
  if printf '%s' "$_mo" | grep -qFe PERSONWORDS -- && ! printf '%s' "$_mo" | grep -qe 'AGENTWORDS\|TOOLWORDS\|METAWORDS' --; then
    printf '%s✓%s selftest: mine-sessions keeps only what the person typed\n' "$GRN" "$RST"
  else
    failures=$((failures + 1)); printf '%s✗ selftest: mine-sessions matched the wrong lines:%s\n%s\n' "$RED" "$RST" "$_mo" >&2
  fi
  # --usage counts one API response once, though the host writes it as several records.
  {
    printf '%s\n' '{"type":"assistant","timestamp":"2030-01-02T00:00:04Z","message":{"id":"m1","usage":{"input_tokens":10,"cache_creation_input_tokens":100,"cache_read_input_tokens":890,"output_tokens":5},"content":[{"type":"tool_use","id":"t1","name":"Read","input":{"file_path":"AGENTS.md"}}]}}'
    printf '%s\n' '{"type":"assistant","timestamp":"2030-01-02T00:00:04Z","message":{"id":"m1","usage":{"input_tokens":10,"cache_creation_input_tokens":100,"cache_read_input_tokens":890,"output_tokens":5},"content":[{"type":"text","text":"x"}]}}'
    printf '%s\n' '{"type":"user","timestamp":"2030-01-02T00:00:05Z","message":{"content":[{"type":"tool_result","tool_use_id":"t1","content":"BIGOUTPUT"}]}}'
  } >> "$_tx/s.jsonl"
  check_out "mine-sessions --usage counts a response once, though it is written as several records" "1 session(s), 1 model response(s)" \
    python3 scripts/mine-sessions.py --usage --dir "$_tx" --since 2030-01-01
  check_out "mine-sessions --usage lists the file it read" "1 reads    1 sessions  AGENTS.md" \
    python3 scripts/mine-sessions.py --usage --dir "$_tx" --since 2030-01-01
  rm -f "$_tx/s.jsonl"
  expect_fail_saying "mine-sessions (no transcripts is not a clean result)" "not a clean result" \
    python3 scripts/mine-sessions.py --dir "$_tx"
  rm -rf "$_tx"
else
  printf '%s! selftest: python3 not found — transcript mining cases skipped%s\n' "$YEL" "$RST" >&2
fi

# "every file in this tree is classified" is NOT asserted here. By the time the
# cases above have run, $TMP holds a dozen .bak fixtures this script wrote, and
# they are genuinely unclassified — the resolver is right and the tree is dirty.
# Worse, in a configured instance the same assertion would fail on the user's
# own unclassified work, and a false positive gets a gate switched off within a
# week. The claim is about the KIT, so it is checked by the kit's own suite
# against the pristine template instead.

printf '\n'
if [ "$failures" -eq 0 ]; then
  printf '%s✓ gate selftest passed%s %s(%s cases)%s\n' "$GRN" "$RST" "$DIM" "$cases" "$RST"
  exit 0
fi
printf '%s✗ gate selftest: %s/%s cases failed%s\n' "$RED" "$failures" "$cases" "$RST" >&2
exit 1
