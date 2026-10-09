---
name: harness-prd
description: Write and maintain the product narrative in docs/product/PRD.md — the problem, who it serves, objectives, non-goals, and how success is measured. Use when starting a product or a major feature area, when the direction changes, or when someone asks what this product is actually for. Not for tracking status; that is the requirement register.
license: MIT
metadata:
  harness.tier: product
allowed-tools: Read Glob Grep Write Edit Bash(git:*) Bash(ls:*)
---

# prd

Owns `docs/product/PRD.md`, and nothing else.

The PRD is the argument for the product: what is broken, for whom, what we are
choosing to do about it, and what we are deliberately not doing. It is read
start to finish by someone new, and it is rewritten when the direction changes —
not when a ticket moves.

| Use it when | Do not use it when |
|---|---|
| Starting a product, or a feature area big enough to need its own case | Adding one requirement — that is `requirements` |
| Direction changed and the narrative is now wrong | Recording that something shipped |
| Someone cannot say what the product is for | Writing the build plan — that is `spec` |
| A non-goal keeps getting re-argued | Choosing a library — that is `adr` |

## The one rule

**The PRD holds no mutable state.** No statuses. No checkboxes. No priority
column. No phase table. No progress.

This is not tidiness. A document that is both the argument for a product *and*
the record of what is done becomes unreliable as both: the argument rots as
statuses churn, and the statuses drift because nobody re-reads a twelve-page
narrative to update one cell. Two hand-maintained trackers holding the same
state diverge within weeks, and from then on nobody trusts either.

So: the register (`requirements.md`) holds every changing fact. The ledger
(`decisions.md`) holds why it changed. The PRD holds the case, in prose.

If you catch yourself typing a status into the PRD, the row belongs in the
register. Write it there and link to it.

## Modes

**`create`** — no PRD yet. Work through the sections below in order. Do not
skip Non-goals; it is the most-skipped section and it prevents the most argument
later. Where you do not know something, write
`[NEEDS CLARIFICATION: the specific question]` and stop — do not invent a user,
a metric, or a business reason. An invented objective is worse than a marked gap
because nobody knows to challenge it.

**`revise`** — the direction moved. Rewrite the affected sections in place.
Then check the knock-ons in the same pass:
- Does a requirement in the register now contradict the narrative? Supersede or
  remove it via `requirements`, do not delete the row.
- Is this change big enough to be a decision? Record it via `decisions`.
- Did a non-goal just become a goal, or the reverse? Say so explicitly in the
  section, with the date. A silently deleted non-goal is how a settled argument
  restarts.

**`check`** — read the PRD against the register. Report, do not edit:
- objectives with no requirement pointing at them (an intention nobody is building)
- requirements at P0/P1 that serve no stated objective (work with no case)
- non-goals that a live requirement contradicts
- `[NEEDS CLARIFICATION]` markers still open
- a "Last substantive change" date older than the newest accepted requirement,
  which means the narrative has been overtaken

## The sections, and what makes each one real

| Section | Real when | Fake when |
|---|---|---|
| The problem | Someone outside the team recognises it | It describes a missing feature |
| Who this is for | It says what they are doing when they hit it | It says "users" |
| Objectives | Two to four, each falsifiable | Six, each a restatement of a feature |
| Non-goals | Each says *why*, and whether it is "never" or "not yet" | Empty, or a list of things nobody asked for |
| How we will know | A measure that could come back bad | "Users are happy" |
| Constraints | Names the real ones — budget, platform, deadline, law | Absent |

Two to four objectives is a real limit. A PRD with eight objectives has none:
nothing can be traded off against anything, so every argument becomes a
stalemate that seniority resolves.

## Anti-patterns

- **The living PRD.** Statuses creep back in "just for now". Within a month it
  is the third tracker and the least accurate.
- **Solution in the problem statement.** "Users need a dashboard" is a solution.
  What can they not currently see, and what does that cost them?
- **Non-goals as a wish list.** A non-goal is something a reasonable person
  would expect you to build. If nobody would ask for it, it is not a non-goal.
- **Rewriting instead of superseding.** When direction changes, the old case
  matters — it is why the register holds what it holds. Record the change in
  `decisions.md` rather than quietly replacing the paragraph.
- **Writing it after the build.** A PRD written to describe what was already
  built is documentation, not a decision record, and it will never be re-read.

## Done

- Every section has content or a `[NEEDS CLARIFICATION]` marker.
- No status, checkbox, priority or phase appears anywhere in the file.
- `Last substantive change` is today's date if you changed the argument.
- `check` mode reports no objective without a requirement, and no requirement
  at P0/P1 without an objective.
- Anything that changed direction is in `decisions.md`, and anything that
  changed scope is in `requirements.md`.
