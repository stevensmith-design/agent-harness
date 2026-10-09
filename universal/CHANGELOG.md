# Changelog

Versions follow `harness.version` in `harness.config.yaml`. Upgrading an
installed harness is still by hand — `install.sh` refuses to install over an
existing one — so each entry says what an installed repo has to do.

## Unreleased — execution correctness

### Capability, dependency and data safety

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
- New data-boundary gate rejects tracked secret-bearing filenames,
  personal/private paths, and structured personal-data shapes without printing
  matched values. `.pii-allow` exceptions are path-scoped and fail when stale.

Installed repos should copy the new gates, validators, hooks, dependency-intake
skill, config keys, `.pii-allow`, settings/tiers, ignore rules and deterministic
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
