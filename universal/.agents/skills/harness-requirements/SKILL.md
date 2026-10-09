---
name: harness-requirements
description: Manage the requirement register — propose, accept, reject, reprioritise, supersede, remove, and report. Use when a requirement is added, agreed, changed, dropped, or needs its status updating, and when checking whether the register still matches reality.
license: MIT
metadata:
  harness.tier: product
allowed-tools: Read Glob Grep Write Edit Bash(git:*) Bash(make:*) Bash(./scripts/:*) Bash(gh pr:*)
---

# requirements

The register is the single place a requirement's state is written. Not the PRD,
not a roadmap, not a second tracker.

That last point is the whole design. The most common failure here is keeping
status in two hand-maintained files: they disagree within weeks, nothing detects
it, and from then on nobody trusts either one.

| Use it when | Do not use it when |
|---|---|
| A requirement is proposed, agreed, or rejected | Deciding *how* to build it — that is `spec` |
| Priority changes, or scope is cut | Recording a technical decision — that is `adr` |
| A requirement changes or is removed after agreement | Tracking today's tasks — that is `tasks.md` in the spec |
| Reporting what is agreed, in flight, or shipped | Writing the product narrative — that is `docs/product/PRD.md` |

**Owns:** `docs/product/requirements.md`.
**Never:** writes acceptance criteria (they live in the spec), names an endpoint,
a table, or a file, or edits `PRD.md`.

## The register

```markdown
| ID | Requirement | Priority | Status | Spec | PR | Changed |
|----|-------------|----------|--------|------|----|---------|
| REQ-014 | A member can export their own records as CSV | P1 | shipped | specs/REQ-014-csv-export/ | #482 | 2026-08-12 |
| REQ-015 | An admin can export any member's records | P2 | rejected | — | — | 2026-08-12 · DEC-009 |
| REQ-016 | Export includes archived records | P1 | accepted | — | — | 2026-08-18 · supersedes part of REQ-014 |
```

- **ID** — `REQ-NNN`, monotonic. **Never reused, never renumbered**, even when a
  requirement is split, merged, or removed. An ID that moves breaks every link
  to it in a spec, a branch name, a PR, or someone's memory.
- **Requirement** — one sentence, product language, no mechanism in it. If it
  names an endpoint or a table, it belongs in the spec.
- **Priority** — one declared scheme with written meanings. Default: `P0` cannot
  ship without · `P1` this release · `P2` wanted, not committed · `P3` someday.
  Whatever you use, write the meanings down once and do not improvise a second
  scheme later.
- **Status** — exactly one of the eight below.
- **Changed** — the date, and *why*: a decision ID, or the requirement that
  superseded this one. A blank here on a non-`proposed` row is a missing record.

## The lifecycle

```
proposed ──accept──> accepted ──spec──> specced ──build──> in-progress ──merge──> shipped
    │                    │                                                            │
    └──reject──> rejected└──supersede──> superseded <──────supersede──────────────────┘
                         └──remove────> removed
```

| Status | Means |
|---|---|
| `proposed` | captured, not yet agreed. Costs nothing to sit here |
| `accepted` | agreed to build. Needs a dated decision |
| `specced` | a spec directory exists |
| `in-progress` | a branch exists and work has started |
| `shipped` | merged, with a PR number |
| `rejected` | decided against. **Stays in the register forever** |
| `superseded` | replaced. Points at the requirement that replaced it |
| `removed` | was agreed, then dropped. Dated, with a reason |

## The rule that matters most

> **Never delete a row. Never edit an accepted requirement's statement in place.**

A deleted requirement takes its history with it, and six months later "why
doesn't it do X?" has no answer. A silently edited one means the acceptance
criteria a PR was built against are no longer the ones in the document, and
nothing records that.

So:

- **Small clarification** — amend the statement, and log the amendment in
  `decisions.md` with a date. The row keeps its ID.
- **Real change** — write a **new** `REQ-`, set the old one to `superseded`
  pointing at the new ID. Both rows stay.
- **Dropped after agreement** — status `removed`, dated, with a one-line reason
  in the `Changed` column and a decision entry. Do not delete the row.
- **Rejected before agreement** — status `rejected`, dated, reason. Also do not
  delete. A rejected requirement that vanishes gets re-proposed in three months
  by someone who wasn't in the room.

## Update the moment it is true

Change the status when the thing actually happens — not in a batch at the end of
the week. Batched updates become rubber-stamping: nobody re-checks eight rows,
they just set them all to `shipped`. One row, at the moment it changed, is the
only version of this that stays honest.

## Modes

**add** — capture as `proposed`. One sentence, a priority guess, today's date.
Do not ask for acceptance criteria yet; most proposals never get accepted, and
criteria written now are wasted or wrong.

**accept / reject** — a decision, so it gets an entry in `decisions.md` and a
`DEC-` reference in the `Changed` column. Rejection needs a reason someone could
disagree with; "out of scope" is not one.

**reprioritise** — change the priority, date it, say what changed. Priority that
moves without a record is priority nobody trusts.

**supersede / remove** — as above. Never in place, never deleted.

**status** — report the register grouped by status. `shipped` since the last
release tag is your release-notes input.

**check** — validate, and report only what is wrong:

- duplicate or reused IDs
- a row at `specced` or later with no spec directory
- a spec directory with no register row (an orphan)
- a row at `shipped` with no PR number
- a `superseded` row pointing at an ID that does not exist
- any non-`proposed` row with an empty `Changed`

Run it after anything bulk, and before a release. `make requirements-check`
does the same thing without a model.

## Handing off to `spec`

When a requirement reaches `accepted` and work is about to start, `spec` takes
the ID and the statement and produces `specs/REQ-NNN-<slug>/`. Name the
directory and the branch after the ID — that makes traceability a directory
listing rather than a discipline someone has to maintain.

The register then holds one word about that requirement. Everything else —
acceptance criteria, plan, tasks — lives in the spec.
