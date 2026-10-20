# Changelog

Versions follow `harness.version` in `harness.config.yaml`. Upgrading an
installed harness is still by hand — `install.sh` refuses to install over an
existing one — so each entry says what an installed repo has to do.

## Unreleased — execution correctness

### Additive installation and combined-harness compatibility

- `harness-init.sh --dry-run` is read-only. It used to guard only the config
  writes, so it still rewrote `AGENTS.md`, deleted rule copies and ran both
  generators; it now validates, prints the planned values and rule removals,
  and stops. Every answer is also an argument (`--adapter`, `--name`,
  `--stack`, `--src`, `--tests`, `--ui`, `--datastore`, `--level`), validated
  before any write, so an agent no longer needs a terminal. Without a terminal,
  an unanswered value fails — `--yes` accepts detected defaults but never the
  `<stack>` placeholder. `make harness-init ARGS='…'` passes them through.
- The macOS Git/GitHub guard now decides whether a command is a network
  operation before inspecting shell composition, resolves Git subcommands after
  global options, rejects configuration/hook/refspec/force bypasses, and uses a
  deny-by-default `gh` allowlist (`gh api` is not permitted).
- Harness and dependency intent files are operator-controlled: direct Edit,
  Write and recognizable Bash writes are blocked, declaration commands live in
  the permission prompt list, and broad script/worktree/merge permissions were
  replaced by documented command shapes. Protected-path classification now
  resolves nested Git worktree roots and normalizes case on macOS; recognizable
  shell redirects are covered, with CI retained as the full diff backstop.
- Changed-file policy resolves an explicit base first, then GitHub's base ref,
  then `origin/<main>`, and fails closed when no comparison is possible. API
  implementation and machine-readable accepted contracts remain high-risk,
  while shipped API documentation templates no longer make a fresh install a
  high-risk change.
- The secret-bearing automatic AI review workflow is no longer installed by
  default. Governance checkout credentials do not persist, `jsonschema` is
  pinned, and UI initialization/doctor emit a non-blocking warning when the
  configured token directory does not exist.
- `install.sh` now requires a Git target and never overwrites an existing
  project file. Shared-name collisions are preserved byte-for-byte and receive
  a `.harness-candidate` beside them for manual reconciliation; the old
  `--force` overwrite behavior is deprecated.
- Empty `design.forbid[].allow` lists no longer abort the token gate, `make
  setup` is no longer misclassified as package installation, and the
  branch-bound harness-edit declaration now controls protected writes without
  an unliftable settings-level deny.
- Locked vendored skills are exempt from the authored-skill line cap while
  remaining hash-gated. `.secret-allow` provides exact path-plus-line-substring
  reviewed exceptions and fails on stale entries.
- Zero-dependency `package.json` files no longer require meaningless empty
  lockfiles. Common root-level server and `public/` layouts are included in the
  shipped rule routes, and harness-init now requires all retained rule paths to
  be checked against the actual repository layout.
- The first production install also exposed avoidable execution cost. The
  default Stop and post-edit hooks are removed; verification runs at intentional
  checkpoints instead of after every edit or conversational turn. Commit-time secret scanning reads only
  staged blobs, installed projects are not failed by maintainer-only size caps
  on on-demand rules and skills, and normal project CI no longer runs the
  harness's large rejection self-test (`make harness-ci` remains available).
- Full secret scans now batch files instead of starting thousands of grep
  processes. Secret exceptions are also scoped to a pattern family, so allowing
  a fake password cannot hide a key-shaped value elsewhere on the same line.
- Review records no longer invalidate already-recorded product evidence, and
  the CI guide documents the one-time bootstrap when a pull request introduces
  a repository's first workflow.
- Always-loaded Git and security guidance was reduced to enforceable
  non-negotiables, moving the source template from 180 to 121 lines of startup
  context without removing its gates or on-demand security procedures.
- Generated CI now verifies repository-owned enforcement with `--ci` instead
  of requiring one developer's local skill links and Git hooks. `make check`
  also checks generated instruction and workflow drift, matching pre-commit.
- Permission tiers are replaced by one ownership-based policy. Routine branch
  pushes, PR operations, merging and clean owned-worktree cleanup are available;
  destructive history rewriting remains denied and release/deploy stays an
  explicit approval boundary.
- On macOS, only explicit fetch-with-prune, fast-forward pull, owned-branch
  push, and required `gh pr` shapes leave the sandbox. A command-shape guard
  blocks alternate upload/receive programs, hook bypasses, refspecs, shell
  composition and admin merges; a ref-aware pre-push hook separately blocks
  default-branch, tag and history-rewrite pushes.
- `project.product_paths` is now the shared adaptation point for finish-time
  evidence reminders and mixed harness/product change detection. Project-owned
  design contracts and root server files no longer require a harness override.
- Sensitive-access matching distinguishes credential filenames from program
  member access such as `event.key`; environment-dump commands are matched only
  at command boundaries.
- Review is now risk-based and capped at two rounds. Low-risk changes use
  deterministic checks and a producer checklist; standard/high-risk changes get
  one read-only reviewer. The producer remains free to repair and push its own PR.
- The PR procedure now follows owned work through confirmed `MERGED` state and
  clean branch/worktree removal, without imposing an independent reviewer on
  low-risk changes. Any gate, hook, sandbox, permission, or host-classifier
  block is diagnosed once and reported with safe options instead of retried or
  silently reworded.
- Development processes are stopped only by a PID recorded when the agent
  started them; broad name- and port-based killing is forbidden.
- `make check` now runs product checks only. `make harness-check` owns governance,
  generated-file drift and harness integrity, and generated GitHub CI runs it
  only when harness paths change.
- The generic adapter accepts an explicit `none: <reason>` for checks a project
  genuinely does not have, instead of leaving CI permanently NOT VERIFIED.
- Conventional `test/`, `tests/`, `__tests__/`, and `spec/` changes now resolve
  to a low-risk test surface instead of being reported as unexamined policy input.
- Self-test fixtures copy only version-controlled harness inputs, never the
  adopter's whole working tree. Skill linking preserves and reports collisions
  rather than deleting project-owned directories.
- PR-body validation cleans input once and avoids a long-body `pipefail` race;
  API agreement checks fall back to `origin/<main_branch>` in CI clones that do
  not create a local default branch.
- `security.sensitive_paths` lets each project block local databases, exports,
  recordings, and similar data from agent reads and shell output while allowing
  metadata-only Git queries. The policy gate now classifies changed files in a
  single pass instead of starting a process for every file/surface pair.

### Capability, dependency and data safety

- External API, SDK, data-provider, platform, and store changes now carry a
  concise current-terms checkpoint before implementation. The optional
  `external-terms-audit` overlay adds the supplied read-only whole-application
  audit and Markdown/HTML report workflow without adding another ordinary-PR
  gate; focused checks self-verify while formal or consequential audits receive
  an independent cross-check.
- Capability skills now pass strict portable-frontmatter and agent-trust gates.
  `skills-add` scans a quarantined copy before it enters discovery, and exact-line
  reviewed exceptions fail when stale. Bundled skills no longer pretend they
  can be updated from an upstream path the lock does not record.
- New `/harness-dependency-intake`, dependency-source/integrity/lifecycle gate,
  and branch-bound install declaration. Setup no longer installs dependencies.
  Node and Python adapters refuse unlocked or non-deterministic fallback installs.
- Claude runtime hooks block sensitive-file access, environment dumps, broad
  ignore-bypassing searches, undeclared package installation, global installs,
  and download-to-shell forms before their output reaches the model.
- Sensitive-access matching no longer treats ordinary prose containing
  `credential`, or a quoted search alternation containing `env`, as a secret
  access attempt; credential-shaped config filenames and real environment-dump
  commands remain blocked and have regression cases.
- New data-boundary gate rejects tracked secret-bearing filenames,
  personal/private paths, and structured personal-data shapes without printing
  matched values. `.pii-allow` exceptions are path-scoped and fail when stale.

Installed repos should copy the new gates, validators, hooks, dependency-intake
skill, config keys, `.pii-allow`, ownership-based settings, ignore rules and deterministic
adapter changes; then run `make harness-sync`, `make link-skills`, and
`make gate-selftest` before enabling them in CI.

### Spec and review completeness

- **A spec that is still the template does not pass.** `spec-clarity` now also
  rejects the template's own placeholders, fields left as `…`, a missing
  section, a section still in the template's words, and `N/A` with no reason.
  Every rule is derived from `specs/000-template/` at run time, so adding a
  section to the template is all it takes to require it.
- **New spec sections**, each answerable with `N/A — <reason>`: screen states,
  data that persists, roles and permissions, states this touches, failure and
  recovery. These are where the defects a spec-driven loop misses come from.
- **`specs/000-template/spec.example.md`** — one spec filled in, to read before
  writing the first one.
- **A spec section answered `N/A` needs the reason.** Any spelling, dash or
  capitalisation with nothing after it is the section unanswered. A
  `[NEEDS CLARIFICATION]` marker inside a code fence is the syntax being quoted:
  it does not block, and the count of markers skipped that way is printed.
- **Review rounds are capped.** `scripts/review-rounds.sh` + new
  `git.max_review_rounds` (default 3): at the cap with a blocking finding still
  open it records `blocked` evidence and escalates to a person. Reaching the cap
  is never approval. Counted from the committed `.agents/reviews/` files.
- **Exploration brief.** The `feature` workflow writes one short brief from the
  diff and the human lane, and it is the PR's Not verified section — not a new
  testing subsystem.
- **`make retro-evidence`** counts findings, still-open findings, claims raised
  on more than one branch, and branches at the round cap with something blocking
  still open. With `gh` it reports how many of the last 20 merged PRs carried a
  `CHANGES_REQUESTED` review — read from each PR's review history, since
  `reviewDecision` is the PR's current state and a merged PR's is almost always
  `APPROVED`. Without `gh`, or if the forge will not return the history, the line
  says NOT VERIFIED rather than zero.


Three results, not two: `pass`, `fail`, and `not_verified` (the check could
not run, or ran over a stub).

- **`not_verified` lets work continue and is never done.** `make check` over
  stub adapter verbs now records `not_verified` instead of `pass`. It prints
  loudly and exits 0 locally; in a readiness context — CI, or `HARNESS_STRICT=1`
  (the feature workflow's closure node) — it fails like `fail`. One rule, in
  `lib.sh` `strict()` / `not_verified()`.
- **Evidence.** `emit-evidence.sh` rejects unknown results, and refuses to record
  `make check` as `pass` while stub verbs ran. `make check-evidence` reports the
  latest `not_verified` or `blocked` record at the commit (a later real pass
  supersedes it; on an equal-second tie the worse result wins). Every evidence
  problem — none, stale, not_verified, blocked — is fatal under `HARNESS_STRICT=1`.
  Workflows no longer write their own `pass` after `make check`.
- **Stop hook.** Fresh `not_verified` evidence ends the session at once with a
  message to the person — no three-attempt loop over a stub the agent cannot fix.
- **Self-test.** A group that could not run is `NOT VERIFIED`, and fails in CI.
  The render-audit group is only owed when `render-pages.txt` lists pages.
- **Bug lane stops for real on a spec gap.** New `scripts/sweep-guard.sh`, run by
  `bug.workflow.yaml` between `sweep` and `fix`: the sweep starts with
  `gap:` and `status: clear | BLOCKED_ON_DECISION Q-NNN`; blocked exits 2 until
  the `Q-` is decided and the sweep re-runs.
  The bug lane now ends on a `readiness` node (`HARNESS_STRICT=1` evidence gate).
- **Skill links.** `verify-harness` names every skill missing from
  `.claude/skills/` (`harness-wrapup` was).

### For installed repos

Copy the changed scripts, `sweep-guard.sh`, both workflows and the evidence
schema; run `make link-skills` and `make harness-sync`. CI that ran the
self-test without Playwright while listing pages in `render-pages.txt` now
fails — install Playwright in that job, or it was never testing the audit.

## 1.16.0 — the learning loop

A fixed bug now has to leave a lesson, and the same rule breaking twice makes a
retro due.

- **Questions close into rules.** `docs/product/questions.md` (`Q-NNN`) closes
  only into a `DEC-`, `INV-` or `REQ-` that exists. The `## Open` table in
  `decisions.md` now points there. Owned by the `decisions` skill.
- **Defect lessons.** `docs/quality/defects.md` (`DEF-NNN`): the rule broken,
  the gap (`spec` · `test` · `render` · `judgement`), the sweep, and where the
  lesson lives. New skill `harness-defect`; the `bug` workflow gains `sweep`
  and `learn` nodes.
- **`make check-learning`** (`scripts/gates/learning.sh`). Advisory until
  `product.enforce_learning: true`. New config keys: `product.enforce_learning`,
  `product.question_stale_days`.
- **`make retro-evidence`** counts defect lessons, rules broken again, and open
  questions; a rule broken again after its lesson makes a retro due.
- **`make render-audit`** (`scripts/render-audit.mjs`, needs Playwright): tap
  targets, text size, overflow, overlap and sideways scroll at phone and
  desktop width, with a contact sheet. Pages in `docs/quality/render-pages.txt`.
- **`docs/quality/`** — the human lane, three layers of "good", judged examples.

### Breaking for installed repos

- **The PR body now needs a `## Not verified` section**, and CI fails when it
  is missing or empty. Copy the section from `.github/pull_request_template.md`
  into your template before upgrading `gates.yml`, or every open PR goes red.
- The PR check moved from inline YAML to `scripts/ci/pr-body.sh`. The old inline
  check passed an untouched template (a comment's middle line counted as
  evidence); the new one does not, so PRs that relied on that now fail.
