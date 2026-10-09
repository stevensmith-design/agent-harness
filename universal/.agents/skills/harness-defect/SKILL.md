---
name: harness-defect
description: Fix a defect so its whole class stops recurring — name the rule it broke, sweep every sibling path, fix with a failing test first, and record the lesson where it will be enforced. Use for any bug a person, a test or an agent found; when the same kind of bug keeps coming back; or when a tester's report is really a question about intent.
license: MIT
metadata:
  harness.tier: workflow
allowed-tools: Read Glob Grep Edit Write Bash(git:*) Bash(make:*) Bash(./scripts/:*)
---

# defect

A fix prevents one instance. A lesson prevents the class. This skill is the
difference: nothing is fixed here without the question *"why did the loop let
this through, and what stops the next one?"* being answered in a file.

| Use it when | Do not use it when |
|---|---|
| Any bug — found by a person, a test, a review or an agent | The report is a question about intent — that is a `Q-` (`decisions`), not a defect |
| The same kind of bug has come back | A feature is missing by agreement — that is a requirement |
| A tester's finding needs turning into something permanent | Reviewing a diff — that is `review` |

**Owns:** the fix, its tests, and a row in `docs/quality/defects.md`.
**Never:** closes a defect with "fixed" and no lesson, or answers a question of
intent by choosing — that is inventing a rule on someone else's behalf.

## 1. Reproduce

A failing test that captures it, before any fix. A fix without one is a guess.
If it can only be seen on screen, capture it the way `make render-audit` does —
a fixture and a measurement — or say plainly that it needs a person.

## 2. Name the rule it broke

Look in `docs/product/domain-rules.md` (`INV-`), `decisions.md` (`DEC-`),
`requirements.md` (`REQ-`), `questions.md` (`Q-`) and the design rules. Then
classify the **gap** — which part of the loop let it through:

| Gap | Found when | Next step |
|---|---|---|
| `spec` | no rule says what should happen | **stop.** Raise a `Q-` and ask. Do not pick an answer and fix towards it. `scripts/sweep-guard.sh` enforces it: the sweep starts `gap:` / `status: clear` or `status: BLOCKED_ON_DECISION Q-NNN` |
| `test` | the rule exists; nothing checks it | the lesson is a check |
| `render` | only visible when drawn — long, many, none, overflow, overlap, tap size | a fixture or a measurement; `human-lane` only if neither can see it |
| `judgement` | "unclear", "feels wrong" — a person's call | the person decides; record it as a `DEC-` or a design rule |

## 3. Has this broken before?

`grep` the Rule column of `docs/quality/defects.md`. If the rule is there, the
lesson recorded last time **did not hold** — that is the real finding, and more
important than this bug. Climb one rung from what was tried:

> memory note → path rule → test → gate or scanner

A sentence did not stop it; a test will. A test in one place did not; a gate
over every path will. `make check-learning` reports the same lesson recorded
twice for one rule — and refuses it once `product.enforce_learning` is on.

## 4. Sweep — one bug, every path

The rule you named applies in more places than the one that broke. List them —
every screen, endpoint, state transition or import path the rule covers — as a
table in the PR, and check each one:

| Path | Respects the rule? | Evidence |
|---|---|---|
| Upload a drawing to an archived customer's project | ✗ — this defect | tests/archive-paths.test.ts:12 |
| Copy a drawing into it | ✗ — new, `DEF-015` | … |
| Reference it from another drawing | ✓ | … |

Every ✗ is its own `DEF-` row, found by the sweep. States that fan out across
features — archived, deleted, withdrawn, permission changed — are where sweeps pay
most. When the table is worth keeping, make it a table-driven test so the next
path added to the product is checked without anyone remembering to.

## 5. Fix

Smallest change that makes the failing tests pass. Do not refactor around it.

## 6. Record the lesson

Append a row to `docs/quality/defects.md` — the columns and what each gap's lesson
must be are in that file. Write the lesson to the **most specific, most
mechanical** owner available: a test beats a rule, a gate beats a test that only
covers one path. A lesson about how *the agent* works, rather than the product
— "this repo's dates are UTC", "Enter confirms IME conversion here" — goes to
`.agents/memory/` if nothing can check it.

Then `make check-learning`.

## 7. Say what is still unverified

In the PR's **Not verified** section: what this fix could still break that no
check sees. `docs/quality/README.md` lists the standing blind spots.

## Anti-churn

One lesson per defect, in one place. Five near-identical memory entries teach
less than one test. If a lesson turns out wrong, correct it where it lives; do not
add a second one beside it.
