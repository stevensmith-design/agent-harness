---
name: product
description: Where product intent lives and what an agent must check before building. Applies to the product layer and to any change that adds, alters, or drops a requirement.
paths: ["docs/product/**", "specs/**"]
trigger: glob
---

# Product intent

Prevents the two most expensive product failures: building something that was
already decided against, and losing the record of why something is the way it is.

## Before building anything that resembles a past idea

Read `docs/product/decisions.md`, and specifically the **do-not-re-propose**
list at its foot. If what you are about to build is on it, **stop and ask**.
Do not implement, and do not quietly re-litigate — reviving a killed idea is a
decision someone makes in the open, not a thing that happens by accident.

This check is cheap and it prevents the failure that costs most on a long
project: implementing something, getting it green, and having it reverted
because it had already been ruled out.

## Where things live

| | Owns |
|---|---|
| `docs/product/PRD.md` | the narrative. **No status, no checkboxes** — owned by the `prd` skill |
| `docs/product/requirements.md` | the register — the only place a requirement's status is written |
| `docs/product/domain-rules.md` | the invariant register — what must always be true, and who enforces it |
| `docs/product/decisions.md` | dated product decisions + the do-not-re-propose list |
| `specs/REQ-NNN-<slug>/` | acceptance criteria, plan, tasks |
| `docs/decisions/` | ADRs — technical decisions, not product ones |

Never write a second tracker. Two files holding the same state disagree within
weeks and nothing detects it. The invariant register is not a second tracker: a
requirement is a deliverable that ships, an invariant is a constraint that
outlives every feature respecting it. Same sentence in both files means it is a
requirement.

## Requirements

- Work traces to a requirement ID. A branch and a spec directory are named after
  it, which makes traceability a directory listing rather than a discipline.
- **Never edit an agreed requirement's statement in place.** Amend with a dated
  decision, or supersede it with a new ID. Never delete a row.
- A requirement arriving mid-build: if it is a fix or polish, proceed. If it is
  net-new scope or changes agreed behaviour, record it before implementing.
- Status changes the moment the thing is true, not batched later. Batched
  updates become rubber-stamping.
