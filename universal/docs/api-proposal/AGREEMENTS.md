# Sign-off ledger

One row per sign-off **event**. This is where an incremental handover is
recorded — the proposals hold the shapes, this holds the agreements about them.

Read by `make check-agreements`, which fails if an operation that was `agreed` or
`frozen` changes shape without a new row here naming it.

## Why this file exists separately from the proposals

Sign-off is sliced by **the unit you review**; OpenAPI is sliced by **resource**.
One review going out touches operations in three files, and one file holds
operations agreed on four different days. Neither slicing is wrong, so do not
force the YAML to follow the review: keep the proposals resource-sliced, and let
one row here name every operation a single review covered.

What that unit is belongs to the project — a feature, a `REQ-NNN`, a use case, a
screen, an endpoint group. The harness has no opinion; it only needs the row to
say which one.

## The columns

| | |
|---|---|
| `Date` | when the event happened, `YYYY-MM-DD` |
| `Reviewed` | the unit this sign-off covered — a `REQ-NNN`, a feature, a use case, a screen |
| `Operations` | the `operationId`s this event covers, space- or comma-separated |
| `Event` | `agreed` · `frozen` · `revised` · `reopened` |
| `Consumer told` | **where** — a PR number, a commit, a message link |

`Event`:

| | Means |
|---|---|
| `agreed` | both sides accept this shape. It may still change, with a row |
| `frozen` | no further change without a new version of the operation |
| `revised` | an agreed shape changed. Say what moved, and who now has to react |
| `reopened` | an agreement is withdrawn — the operation goes back to `changed` |

`reopened` exists because agreements do get withdrawn: a client's expectations
grow, and something already signed off comes back for a second review. The cost of supporting it is one
row and one status transition; the cost of not supporting it is that the first
time it happens the ledger records something false — and a ledger that has lied
once gets ignored from then on.

**`Consumer told` records where, never `yes`.** A tick nobody can check is a tick
everybody writes. No gate verifies this column — a PR number is what makes it
verifiable by a person in ten seconds, which is the only thing that keeps it
honest.

## Example

```
| Date | Reviewed | Operations | Event | Consumer told |
|------|----------|------------|-------|---------------|
| 2026-08-14 | Entry list (REQ-014) | listEntries getEntry | agreed | #482 |
| 2026-08-21 | Entry list (REQ-014) | listEntries | revised | #501 — cursor replaces page |
```

## Ledger

| Date | Reviewed | Operations | Event | Consumer told |
|------|----------|------------|-------|---------------|
