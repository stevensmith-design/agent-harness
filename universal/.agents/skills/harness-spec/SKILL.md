---
name: harness-spec
description: Turn a request into a spec, a plan, and a task list with explicit ambiguity markers and pre-implementation gates. Produces a requirement-slug folder containing spec, plan, and tasks documents from an accepted requirement. Use once a requirement is accepted and before implementation starts. Capturing a new ask is /harness-requirements; setting up the branch is /harness-branch.
license: MIT
metadata:
  harness.tier: planning
allowed-tools: Read Glob Grep Write Edit Bash(git:*)
---

# spec

Prevents the most expensive agent failure: inventing requirements, implementing
them confidently, and defending them in review.

| Use it when | Do not use it when |
|---|---|
| The work touches more than one file or surface | A one-line fix with an obvious right answer |
| The request leaves anything to interpretation | The spec already exists — read it |
| Work will be split across agents or sessions | You are mid-implementation — do not re-plan |

**Produces:** `specs/REQ-NNN-<slug>/{spec.md, plan.md, tasks.md}`. The number is
the requirement ID from the register, never a new sequence — `scripts/gates/requirements.sh`
scans `specs/REQ-*/` for orphans, so a directory named any other way is invisible to it.
**Never:** writes source code. Planning and producing are separate lanes.

## 1. spec.md — what and why, never how

Copy `specs/000-template/`. Fill in: problem, who it is for, user stories with
testable acceptance criteria, non-functional requirements, and — the section
people skip — **non-goals**.

Every place you had to assume something becomes:

```
[NEEDS CLARIFICATION: does an expired invite show an error or silently re-send?]
```

Write the marker instead of choosing. `scripts/gates/spec-clarity.sh` fails
`make check` while any marker remains, so implementation genuinely cannot start
on a guess. Then **ask the human those questions** — that is the deliverable of
this phase, not the prose.

## 2. plan.md — how, and what you are deliberately not doing

Architecture, data model, contracts, and the pre-implementation gates. Tick each
gate explicitly; a deviation is allowed only if it is written into the Complexity
Tracking table with the reason.

- **Simplicity** — no layer, abstraction, or dependency added for a requirement
  that does not exist yet.
- **Anti-abstraction** — use the framework directly. One representation of a
  concept, not a model plus a DTO plus a view-model that all say the same thing.
- **Integration-first** — contracts defined and contract tests written before the
  implementation they describe.
- **Rules** — name the `.agents/rules/` files and ADRs this work must satisfy.

## 3. tasks.md — ordered, small, parallel-marked

One task per checkable outcome, each naming the files it touches and how it will
be verified. Mark independent tasks `[P]` so they can be fanned out to parallel
agents or worktrees. A task that cannot state its verification is not a task yet.

## Handoff

A fresh agent with no memory of this conversation must be able to execute
`tasks.md` from the spec alone. If it could not, the spec is not finished — that
is the actual test, not length.
