# Requirement register

The single source of truth for what is agreed and where it stands. Managed by
the `requirements` skill; validated by `make requirements-check`.

**Never delete a row.** A requirement that is rejected, superseded or removed
keeps its row with a terminal status and a reason. Deleting takes the history
with it, and six months later "why doesn't it do X?" has no answer.

**IDs are never reused and never renumbered** — a moved ID breaks every link to
it in a spec, a branch, a PR, or someone's memory.

## Priority

| | Means |
|---|---|
| `P0` | cannot ship without it |
| `P1` | committed for this release |
| `P2` | wanted, not committed |
| `P3` | someday; revisit when asked again |

## Status

`proposed` · `accepted` · `specced` · `in-progress` · `shipped` ·
`rejected` · `superseded` · `removed`

## Register

| ID | Requirement | Priority | Status | Spec | PR | Changed |
|----|-------------|----------|--------|------|----|---------|
| REQ-001 | <one sentence, product language, no mechanism> | P1 | proposed | — | — | YYYY-MM-DD |

<!-- Add rows at the bottom. Next ID = highest ever used + 1, including rows
     that are rejected or removed. Never reuse. -->
