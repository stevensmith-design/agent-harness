# Known gaps

What two independent adversarial reviews found and this version did **not** fix. Recorded rather than smoothed over, because the kit's own rule is that the rejected list matters as much as the accepted one — and because an unexamined harness with green checkmarks is more dangerous than no harness.

Ranked by what would hurt first.

---

## Build status — what has and has not been proven

Moved here from the README, which describes what the kit does. This section records how far that has been verified.

**v0.14.0 — built, self-verified, adversarially reviewed, not yet installed on a real engagement.**

| | |
|---|---|
| Core template | Working. `doctor.sh`, `check.sh`, `gate-selftest.sh` green on a fresh copy |
| Surfaces resolve both ways | Every declared pattern matches a file **and** every file matches at most one pattern, from **one reader** — doctor used to carry a second parser of the same table and the two disagreed. New in v0.12.0, and it found 30 of 51 shipped files belonging to no surface, every gate script among them. Classifying a file `high` does not yet *stop* anything: nothing consumes the approval tier until approval records exist |
| Mutation-tested | Every check in the resolver was deleted in turn to confirm a self-test case goes red. Two checks survived the first attempt and now have cases. A check no case can kill is a check nobody is maintaining |
| Runtime assumptions | Checked on the machine running, not claimed from the machine it was written on. The kit is developed on Linux/bash 5/GNU coreutils and run on macOS/bash 3.2/BSD; `assert_runtime` proves `sort -z`, `read -d ''` and empty-array-under-`set -u` work before anything depends on them, and refuses by name if they do not. **Not yet observed passing on macOS** — that is the first thing to run there |
| Gate self-tests | Each case rigs a violation and asserts rejection, plus a clean-tree pass per gate |
| Any domain, not five | A pack is a shortcut for a domain someone has already run, never a licence to work in one. When none exists — **the normal case** — `packs/_deriving.md` derives the same three variables from the user's own context, and `harness-build` cannot tell the difference because it consumes the variables, not the file. `check-kit.sh` fails if a skill names a pack without routing the uncatalogued case |
| Packs | `dev` · `design` · `business-development` are complete; `marketing` · `project` are marked sketches, and derivation is the better path than either. **No pack is yet a set of files you can copy** — each is a document describing the decisions to make |
| Installed anywhere | **No.** This is the next thing, and the kit's own advice says a harness that has never carried real work is a rehearsal |
| First contact | A session-start hook reports whether the harness has ever been configured and whether it has ever carried work; `first-contact.sh` enforces the same fact where hooks do not reach. `core/procedures/first-contact.md` routes by what the user actually opened with |
| Procedures are invokable | `sync-skills.sh` generates a thin `.claude/skills/<id>/SKILL.md` per procedure — pointers, never copies — with a drift gate. A procedure nothing can invoke is a document you have to know to open |
| Rubrics | A method and three exemplars covering three **kinds** of standard, not a domain library — see `KNOWN-GAPS.md` §5 for why |
| Presence grading | `content_status` is a four-state ladder, not a boolean — `stub` is what separates an unpacked template from a configured harness |
| Budget | Covers the always-loaded **set** declared in `loading-order.md`, not one file, because a per-file budget is evaded by moving content sideways |
| Review staleness | `review-staleness.sh` measures a review against its predecessor. High overlap is a finding about the team, not the work |
| Improvement loop | Session wrap-up writes a journal; `retro-evidence.sh` counts what happened since the last retro and says when one is due, and the session-start hook passes that on; `mine-sessions.py` finds the person's corrections in saved sessions, and with `--usage` where the tokens went; the retro proposes, a person approves, and every retro is logged with the always-loaded size. Self-tested in both directions and mutation-checked. **Run only on fixtures so far** — see §11c |
| Memory and decisions | Memory entries are dated, sourced and confirmed, verified before use, and pruned at retro. A decision log with a *do not propose again* list, and a task-keyed read-first index, both on demand. The always-loaded set did not grow to add them |
| Known gaps | [`KNOWN-GAPS.md`](KNOWN-GAPS.md) — what the reviews found and this version did not fix |
| The kit checks itself | **Partially, since v0.8.0** — `check-kit.sh` covers references, orphans and entry routing. Pack claims and theory coherence still need a reader. |
| The kit as an instance of itself | **Not yet.** `harness.yaml` sits at `core/`, so the kit's own gates see `core/` and never examine `README.md`, `ANATOMY.md`, `packs/` or `skills/`. Two adversarial reviews found real defects in exactly that unexamined region — including all five packs orphaned by the kit's own citation check. Making the kit an instance of itself is the highest-value unbuilt change |

Defects found and fixed during the build, listed because a kit claiming a clean build it did not have would be committing the defect it exists to prevent:

**By its own gates, while being written** — a broken-reference check that failed *silently* (a `while read` in a pipeline is a subshell, and the last line without a newline is dropped); an exported PID that let a child gate kill its own self-test after two cases; `grep -c` printing `0` *and* exiting 1; and a self-test whose probe string was written literally into the file the gate searches, so the case tested nothing.

**By two independent adversarial reviews afterwards** — `doctor.sh` printing `✓ scripts executable (7 scripts, 2 not executable)`, a denominator contradicted by the verdict beside it; an instance-mode placeholder check that could never go green because a comment *describing* the check contained a placeholder, while missing every prose placeholder including the prime directive; a declared-intent mechanism asserted in four documents with nothing reading its output; two files telling a reviewer opposite things about what a null result means; and the organ count stated as 15 in both entry documents, above a list of 17.

Neither review was run by whoever built the thing. That is the whole method, and it is the reason to trust this list more than the green ticks above it.

---

## 0 · What a pre-trial review found, and what it cost

An independent read against one lens — *"I have to run this on a real project on Monday"* — found four blockers and nine degradations in a kit that was green on all its own gates. Fixed in v0.6.0, recorded because the pattern matters more than the bugs:

- **The documented install destroyed the target's files.** `cp -R core/. .` overwrote `README.md`, `AGENTS.md`, `.gitignore` and `.claude/settings.json` — the four files most likely to exist, and the ones the build procedure says four paragraphs earlier are *"merged, never silently overwritten."* Now `install.sh`, which never overwrites and stages collisions for a human.
- **The obvious workaround was silently worse.** Installing into a subdirectory went green while surface patterns matched nothing and the split gate could never fire. Now refused, with the reason.
- **Filing the first judged example turned the harness red.** Every corpus entry, review and ADR failed the orphan check at the moment of creation — so the one step the kit says never to skip was the step that broke it. Append-only records are now exempt; a genuine orphan still fails.
- **Run records could not leave the machine.** The `.public.md` escape never applied to the prescribed nested layout, because git will not descend into an excluded directory.
- **The installed skills could not read their own required reading.** Copied to `~/.claude/skills/`, the theory paths resolved to nothing. Now bound to `$HARNESS_KIT`.
- **The architecture document and install report had no home** in the instance. Now `decisions/0001-architecture.md` and `runs/install-report.public.md`.
- **Declared intent never expired** — invisible from the second use onward, inside the mechanism whose header claims the escape hatch cannot be used invisibly. Now 8 hours.

**Three of these were introduced by fixes to earlier reviews.** The install command came from the pass that added `INSTALL.md` to unblock testing. **A gate suite going green says the gates work, not that the thing works** — and no amount of self-testing substitutes for one competent stranger trying to use it.

## 0 · An external review (Codex, v0.11.1) — what it found and what was done

Verdict: *"sound with concerns"* — and the concern is right: **the gap is between the theory and
what the constructor can enforce or generate automatically.** Fixed immediately:

- **`detect.sh` errored on an empty markdown file** — the `grep -c` trap for the **fifth** time, and
  this instance existed because `detect.sh` does not source `lib.sh`, so the `nlines()` helper
  written to prevent it was out of reach. **A helper only helps where it can be reached.**
- **Three stale numeric claims** — the kit selftest count, the config key count, and a
  `constitution_lines` key that no longer exists. All in this file.
- **No root LICENSE** while the skills declare MIT.

And its best idea, now built: **`check-kit.sh` checks numeric claims against reality** — version
agreement, config-key count, and every key documented in both directions. It caught an
undocumented `main_branch` on first run, which is the dead-config class the substring check
structurally cannot see. Three self-test cases.

**Accepted and built in v0.12.0: the surface resolver.** The review's sharpest structural finding —
`doctor.sh` proved every declared pattern matched a file and nothing asked whether every file
matched a pattern. It did not: **30 of the 51 files the template shipped resolved to no surface**,
including every gate script, `AGENTS.md`, `GOVERNANCE.md` and `config/surfaces.tsv` itself. All of
them were silently high-risk by the surfaces file's own stated policy, and nothing said so.
`scripts/resolve-surface.sh` is now the single reader of that table, asked about the whole tree by
`doctor.sh` and about a change set by `scripts/gates/surface-resolution.sh`. Fourteen rows were
added to lay the floor the header always promised, and `check-kit.sh` fails if the template ever
ships an unclassified file again.

**Two costs to keep visible.** Patterns must be **disjoint**, because a file matching two rows
fails as ambiguous rather than resolving to the higher risk — approval has no maximum, so choosing
between two tiers would be a policy decision made inside a config reader. That forbids the natural
`clients/*` plus `clients/acme/contracts/*` shape, and the first real engagement is where we find
out whether that is a discipline or a cliff. And classifying a file `high` **still stops nothing**:
nothing consumes the approval tier until approval records exist, so today the resolver reports and
the gate fails only on ambiguity and malformed config. Do not read the tick as enforcement.

**Disjointness is checked in two places, and only one of them is complete.** A pairwise pass catches
*nesting* — one pattern matching the other as a literal filename, which is the shape of every
fallback-plus-override anyone writes — at the moment the table is edited. It is not a decision
procedure for glob intersection: `zzB/?.md` and `zzB/[ab].md` overlap without either matching the
other, and only the per-file check catches that pair, once a file exists in the overlap. The
per-file check is the backstop, and a selftest case exists to prove it is load-bearing rather than
decorative. The pairwise pass also needs a **self-match guard** — `runs/[!0-9]*` read as a literal
filename begins with `[`, which `runs/[0-9]*` matches, so two provably disjoint patterns were
rejected until the check required a pattern to match itself before being used as a witness.

**What two adversarial passes cost, and what they bought.** Four blockers and ten real defects, in
a kit green on every one of its own gates at each hand-off. The blockers: git C-quotes any
non-ASCII path unless told otherwise, so **every Japanese and accented filename fell out of the
change set** — on one machine and not another, because `core.quotepath` is per-clone; `git diff`
speaks repository-relative paths while every pattern speaks harness-relative ones, so a harness in
a subdirectory reported **green over 2 of 31 changed files**, in the repository this kit is
developed in; `--full-name` then double-prefixed the untracked list, dropping **new files**
specifically; and the gate's own selftest case invoked the resolver rather than the gate, so the
gate could be replaced with `exit 0` and the suite stayed green. Mutation testing — delete a check,
confirm a case goes red — found two more checks that no case could kill. **Every check in the
resolver now has a case that kills it, and that was verified by deleting each one.**

**Accepted and still deferred, with reasons:**
approval records that **hash content, not paths** · a config schema replacing substring
reader-detection · graph reachability for orphans.

**Deferred on principle:** the run manifest and lifecycle state machine. Codex marks it P0 while
its own recommended order says *"run the first engagement, then design the run manifest from that
evidence."* The second is right, and it is this kit's own rule — **do not build machinery ahead of
the corpus that justifies it.**

**Scope note worth keeping:** several of the review's asks — run state machines, approval hashing,
CI generation — are machinery for a *generated harness*, and in some cases for a *software* one.
The constructor's job is to know when they are warranted. Building them into `core/` would push the
kit back toward being a software harness, which is the thing it deliberately is not.

## 0a · The kit now checks itself — partially

`./check-kit.sh` runs the domain-neutral discipline over the kit: do its references resolve, is any
document orphaned, does **exactly one** skill declare `metadata.harness.entry: "true"`, and does that skill's
description actually carry the phrasings people use. It also validates portable
skill frontmatter and scans instruction trust shapes before release.
`./check-kit-selftest.sh` proves those checks can fail.

The kit is **not** an instance of itself and does not get doctor's organ list: it is a constructor,
not a harness, and pretending otherwise would demand foundations and runs it has no business
having. What it gets is the checks that apply to any body of documents and skills.

**Still outside every check:** whether a pack's claims are true, whether the theory documents
contradict each other, and whether a procedure actually works. Those need a reader.

## 0b · The defect that forced 0a

The routing defect found in v0.7.0 is the clearest case yet for §1 below. For three versions, the
only skill whose description matched *"help me create a harness"* — the sentence almost every
engagement opens with — was **`harness-build`**, the one that requires an already-agreed
architecture document and skips fitness and scoping entirely. The natural first sentence routed to
exactly the wrong skill.

**No gate could have caught it**, because the kit is not an instance of itself and its `skills/`
are outside every check. A person reading it found it.

A real fix needs a kit-level check that each skill's description carries the phrases that should
reach it and none that should not — which is a rubric of the *structural* kind, and one the kit is
now equipped to write.

## 0c · Detection now decides the motion — what it does not do

`./detect.sh` decides between greenfield · scattered · overlay · harness, fails closed, writes
nothing, and is self-tested across all four plus a no-write assertion.

**What it does not do**, and the honest limits:

- It reads *structure*, never *work*. Whether the material it finds is any good, current, or
  followed is a judgement it cannot make. `content_status` grades presence; only a reader grades truth.
- Its scattered probe is `.md` files two levels deep. Material in a wiki, a drive, a Notion or a
  Slack thread is invisible to it — and in a non-code workspace that may be **most** of the material.
- It cannot detect contradictions, which `packs/_scattered.md` names as the highest-value output of
  that motion. Finding them requires reading the files together.

## 1 · The kit is not an instance of itself — **the highest-value unbuilt change**

`harness.yaml` sits at `core/`, so the kit's own gates see `core/` and never examine `README.md`, `ANATOMY.md`, `PRINCIPLES.md`, `packs/` or `skills/`.

When a reviewer rebuilt the tree with `harness.yaml` at the root and ran `dead-config.sh`, it failed — **all five packs were orphans** by the kit's own citation rule, and four external paths were broken. Those defects sat in the region the kit does not check, which is exactly the failure mode the kit is built to name.

Fixing this would have surfaced gaps 2, 3 and several fixed ones mechanically, before a human read a line.

## 2 · `dead-config.sh`'s config check is weaker than the prose around it

It greps for the key name across every doc and script. **A mention in a README table satisfies it permanently.** It does not test that anything *reads* the key.

Of the 12 shipped keys, only `mode`, `constitution`, `surfaces_file`, `main_branch` and `substrate` are read by code. The rest are read by documents. The gate cannot tell the difference, and `core/README.md` claims it can.

The self-test's own workaround is the tell: the probe key has to be *assembled at runtime*, because a literal would appear in the test file the gate searches.

**What would fix it:** a declared reader per key — `# reader: scripts/doctor.sh` — checked mechanically, rather than a substring search.

## 3 · The orphan check tests an inbound edge, not reachability

Two documents citing only each other, unreachable from any entry point, pass. Matching is on *basename* and as a regex, so `contracts/foo.md` counts as referenced by any mention of `docs/foo.md`.

**What would fix it:** a real graph walk from the entry points.

## 4 · The domain packs are where non-dev generality actually lives — and three of five are thin

The theory is domain-general by construction and the gates assume no toolchain. **What is uneven is the domain knowledge**, and that is the half that decides whether a marketing or PM harness comes out well.

| Pack | State |
|---|---|
| `dev` | Complete, with `universal/` as its reference implementation |
| `design` | Complete |
| `business-development` | Complete, and non-code |
| `marketing` | **Sketch.** Never run |
| `project` | **Sketch.** Inferred only, and may not even be a domain pack — it might be a coordination layer above several harnesses, which would make building it as a pack a category error |

So: a dev, design or business-development harness gets designed from a complete pack. A marketing or PM one gets designed from the anatomy plus judgement — which works, and is visibly thinner. **Build a sketch out when a real engagement demands it, not before** — but know which side of that line you are on when you start.

## 5 · Rubrics ship as a method, not a library — by decision, not omission

`core/rubrics/` carries the authoring method, a template, and **three exemplars covering three
*kinds* of standard** — mechanical, structural, judgement. It does not carry a rubric library, and
the alternative was considered and rejected.

Vendoring the thirteen design rubrics available under MIT would have been an afternoon's work and
would have made `packs/design/` a file set. It was declined because **a library covers the domains
someone thought of, and the next domain is always the one nobody catalogued** — which turns one
universal kit into N domain-specific kits sharing a directory.

**The line: pre-package what is externally standardised, derive what is organisation-specific.**
WCAG, ISO date and currency formats and a regulatory requirement genuinely transfer between organisations.
Brand voice, what counts as a good spec here, and what "on brand" means do not — they come from
that team's own foundations and rejections, and shipping them is how a harness ends up judging work
against someone else's standard.

**What this costs:** a domain with a large body of external standards — accessibility is the clearest
— gets less out of the box than a library would give. If that becomes a real constraint, the fix is
a pack that ships *only* the externally-standardised rubrics, not a general library.

## 6 · Packs are documents, not copyable file sets

Every pack is one `PACK.md` describing decisions. `harness-build` Phase 5 says "apply the pack from `packs/`"; there is nothing to apply. Only the dev pack has a reference implementation (`universal/`); for the others the pack document is all there is.

**This is the largest single piece of unbuilt work**, and turning the three complete packs into file sets is what would make `harness-build` executable rather than advisory.

## 7 · `expect_fail` cannot distinguish "the gate rejected the violation" from "the gate is broken"

It treats any non-zero exit as success and discards stderr. A gate with a syntax error passes its own rejection cases.

Partly mitigated: every gate now has a clean-tree `expect_pass`, so a broken gate fails *that* case. But the rejection cases still do not assert *which* failure occurred, and the rigging steps are not verified to have applied.

**What would fix it:** assert on the expected message, and check that each rig actually changed the tree.

## 8 · Performance and scale limits in `dead-config.sh`

It is O(docs × files) in `grep` invocations and did not finish within two minutes on a 400-document tree. Separately, the `printf | while read | grep -q` idiom interacts with `pipefail` and SIGPIPE somewhere above roughly 1,500 files, producing **false reds** — every key reported as unread.

It becomes unrunnable before it becomes wrong, so nobody would ship on a stale green. But a gate that cries wolf gets switched off, which is the worse outcome.

## 9 · The data-boundary gate ships — with honest limits

`scripts/gates/data-boundary.sh` enforces three rules: nothing tracked under a personal/private
path or secret-bearing filename, no secret material, no structured personal data. Reviewed
exceptions go in `.pii-allow`. Self-tests cover both directions, the allow-list path, and a
sensitive filename whose harmless-looking contents would evade a value scanner.

**Rule 1 does most of the work** and is the only reliable one — it is structural, so formatting
cannot fool it. Rules 2 and 3 are pattern matches, and the gate prints their limitation on every
pass rather than hiding it:

> A green scan is not evidence a file is clean. It catches structured data and key material, and
> **cannot catch a bare name** — it never will. Read the file.

**Still open:** the patterns are Latin-alphabet-biased. Japanese formats — full-width digits,
unhyphenated mobiles, kanji names — are exactly the case that matters most for Japanese-market
harnesses and are not covered. A domain pack serving that market owes its own patterns.

## 9b · Levels above the organisation are a service offering, not an organ

Foundations and memory now support optional **team** and **personal** subdirectories, and `doctor`
does **not** require either. Most working harnesses have no team, role or individual
layer and run real work well without one — so the anatomy is right to omit it.

What the kit owes is not the layer but **the boundary**: if a service produces personal context,
the harness must refuse to commit it. That rule now exists before the content does, which is the
only order that works for privacy.

`AGENTS.md` states both rules and `PRINCIPLES.md` D10 requires them. The core
data-boundary gate now supplies the structural and common-format floor, and its
Claude runtime hook blocks sensitive reads before values reach model context.
Market-specific identifiers remain pack work: the universal floor cannot detect
bare names or every local format without becoming a false-positive generator.

## 10 · `local = CI` is required at L2 and nothing ships CI

`LADDER.md` and `PRINCIPLES.md` D9 both require it. The kit ships no CI file and no generator. A repository-substrate harness at L2 has to write its own, unaided.

## 11 · Runtime safety hooks exist only for Claude Code

`ANATOMY.md` §11 describes three self-protection mechanisms. The core now ships
a Claude `PreToolUse` boundary that blocks sensitive reads, environment dumps,
download-to-shell forms and agent-run package installation. The split gate and
deny-by-default classification remain the tool-independent controls. Cursor,
Codex, Windsurf and shared-folder hosts still need equivalent runtime renderers.

## 11b · The finish-time checkpoint is only as good as the host

`scripts/checkpoint.sh` ships, wired as a Claude Code Stop hook and as an opt-in git pre-commit hook. Whether other hosts — Claude's desktop apps, Cursor, Codex — run project hooks is not established here, so in those the checkpoint is the procedure step, which is followed rather than enforced. The loop breaker lets a session finish after three failed attempts; that is a deliberate trade against a hook people switch off, and it means a determined agent can outlast it. On Windows the scripts need a bash, such as the one Git for Windows provides. **None of this has yet been observed on a real team's shared drive.**

## 11c · The improvement loop has only run on fixtures

Every piece has a self-test, and each test was checked by breaking the code it guards. None of that shows the loop is *useful* on a real team.

- **Session mining reads one shape.** `mine-sessions.py` parses JSON-lines transcripts in the shape Claude Code saves. Another host needs `--dir`, and may not parse at all — unreadable lines are counted, not guessed at. The default signal list is English; teams working in other languages must add their own phrases.
- **The reminder needs hooks.** Where the host runs no session-start hook, nobody is told a retro is due. Someone runs `retro-evidence.sh` by hand, or schedules it.
- **Rejection counts use modification times.** Judged examples carry no date in their name, so a synced drive that rewrites times on copy or restore can inflate the count. Runs, checkpoints and journal entries are dated in their content and are not affected.
- **Memory confirmation dates are a convention.** Nothing enforces them; the evidence script counts entries without one, and the retro acts on the count.
- **`procedures/harness-retro.md` is the largest on-demand file**, about 12 KB. It is read at a retro, not per task, so the cost is paid rarely — but it is the first candidate for trimming.

## 11d · Findings are counted, not gated

`learning/findings.md` records each finding's gap, sweep and lesson, and `retro-evidence.sh` counts it — including a standard broken again after its lesson, which makes a retro due on its own. **Nothing refuses a malformed row, a missing sweep or a lesson recorded twice.** The universal dev harness has that gate (`check-learning`), where the vocabulary — `INV-`, `DEC-`, test paths — is fixed enough to check. The kit's standards are rubric files, decision dates and foundation facts, which differ by domain; a gate written now would be machinery ahead of evidence (F8). The row format is fixed so one can be written the day a harness has enough findings to show which checks matter. Open questions in `decisions/log.md` are counted the same way and gated the same way — not at all.

The **render** gap has a measuring tool only in the dev harness (`make render-audit`). For decks, documents and designs, "only visible as the recipient sees it" is real and domain-shaped — a slide overflowing, a PDF font substituted — and belongs in a pack.

## 12 · `dead-config.sh` has no notion of an illustrative example

A path written in backticks to *demonstrate what not to write* is flagged as a broken reference, because the extractor sees a path and cannot see intent. It caught the convention note in `core/README.md` explaining this very rule.

Worked around by phrasing examples as prose rather than paths. **A real escape — an inline ignore marker — is unbuilt**, and deliberately: an escape hatch on a gate is a thing people reach for, and this one has cost two rewordings and no false negatives so far.

## 13 · Smaller, verified, unfixed

- `cfg` has no schema: an unknown key silently returns the default, and a typo (`moed:`) reverts to permissive with a green tick. `cfg_has` exists to catch this and is called by nothing.
- `check.sh` counts gate *files*, not checks. A gate that emits no `pass`/`fail` at all is counted as having run.
- `doctor.sh`'s surface patterns are root-relative, so installing into a subdirectory of an existing repo silently breaks them.
- The `runtimes`, `packs`, `name` and `kit_version` keys are read only by prose.
- Kit skills now pass the strict portable frontmatter subset used by packaged skill hosts; runtime invocation behavior still needs an end-to-end trial under Cursor and Codex.
- **Only Claude Code gets generated skills.** `sync-skills.sh` writes `.claude/skills/`. Cursor, Codex and Windsurf need their own generator targets; the procedures are already host-agnostic, so this is a rendering job, not a redesign.
- **Repo-first vocabulary.** "commit", "SHA", "branch" and "repo" appear across the core template. None of it is *load-bearing* — the gates assume no toolchain and `SUBSTRATES.md` covers the workspace case — but the default framing reads as software to someone building a marketing harness. The lines the agent and the owner actually read — constitution, governance, procedure template, run records, session hook, data-boundary messages, installer — now cover a folder harness as well as a repository; the longer theory documents still read repository-first.
- The session-start hook is wired for Claude Code only (`.claude/settings.json`). Cursor and Codex have their own hook mechanisms and no equivalent ships. `scripts/gates/first-contact.sh` is the tool-independent backstop and does hold everywhere — which is the reason it exists.
- The hook's "first session in this working copy" marker lives at `.harness/local/seen` and is gitignored. Anyone who commits their gitignore differently, or works in a directory that is not a git repo, loses that signal. It degrades to silence, not to a wrong answer.

---

## Considered and deliberately not adopted

Recorded because the list of what was considered and declined is worth as much as the list of what was adopted.

**A hash-based consent mechanism before any rule lands in the constitution.** The instinct is right; the common implementation is not. A consent hash over titles, dates and file *paths* never covers file *contents*, so it cannot detect the drift it exists to catch. The salvageable half is one line — **a consent artifact hashes content, not paths** — and it is recorded in `PRINCIPLES.md` A9 rather than built. Building the ceremony before the need is how you get a mechanism nobody has ever run.

**A large starter-rubric library.** A shelf of rubrics is an asset and also a shelf of things to maintain. This kit's position is that the corpus produces the rules, so a shipped library would arrive ahead of the corpus that justifies it. Revisit if a domain pack ever needs more than a handful.

**Sub-agents as a shipped layer.** The gate worth keeping in mind: *prove two invocation sites across two skills, or a case where an isolated context window measurably improves quality. Do not create speculatively.*

**Automatically applying review findings.** Re-deriving edits by parsing a review's prose is fragile. The identity line in `core/learning/reviews/README.md` is the structured half that would make it reliable; the automated apply is not built, and should not be until reviews have accumulated.

---

## The pattern, stated plainly

The kit is built on one thesis — *machinery that points at something nothing produces* — and shipped that defect in several places anyway. One reviewer put it exactly right: that is not hypocrisy, it is the predicted outcome of the kit's own claim that this is the hardest defect class to see and that review is structurally blind to it.

The method worked. Neither review was run by whoever built the thing, and that is the only reason this list exists.
