# Invariant register

What must be true of this product's data and behaviour **regardless of what we
build next**, and — for each one — **who enforces it**. Validated by
`make check-invariants`.

## Why this is not the requirement register

`requirements.md` holds *what we agreed to build*: a deliverable, with a spec and
a PR, that is eventually shipped and done. This file holds *what must always be
true*: a constraint that outlives every feature that respects it. An invariant is
never "shipped", never has a PR column, and is not finished when a feature is.

Two registers, two different kinds of state, no overlap — the "never write a
second tracker" rule in `.agents/rules/product.md` is about two files holding the
**same** state. If you find yourself writing the same sentence into both, it is a
requirement and it belongs in `requirements.md`.

## Why the attribution column exists

OpenAPI expresses *shapes* — fields, types, nullability, status codes. The
questions that actually cost time on a handover are not shapes:

> one per user per day · immutable after commit · never show a category-A record
> to a user in state B, except in the archive view · this field carries
> `U+1F600` notation, not the glyph · `404` on this endpoint means "no such
> user", on that one "the user has no active plan"

None of those fit in a schema, and none of them are the same work on both sides
of a handover. **A constraint with no side named is a constraint each side
assumes the other is doing.** That is what the `Enforced by` column is for, and
it is why this is a table and not a page of prose — prose gives the attribution
nowhere to live and nothing to check.

## Enforced by

| | Means |
|---|---|
| `client` | the app enforces it; the server accepts whatever it is sent |
| `server` | the server rejects violations; the client need not pre-check |
| `both` | client for the message, server for the guarantee. The common answer |
| `db` | a constraint, unique index, or trigger. The only one nothing can bypass |
| `unassigned` | **stated, nobody owns it yet.** Legal only while `proposed` |

`client` alone on anything that protects data integrity is a decision, not a
default — say so in the `Changed` column when you choose it.

## Status

| | Means |
|---|---|
| `proposed` | someone stated it. Not agreed, may be wrong |
| `agreed` | both sides accept it. Needs a real `Enforced by` |
| `enforced` | it is implemented on every side the attribution names |
| `superseded` | replaced. Points at the invariant that replaced it |
| `removed` | was agreed, then dropped. Dated, with a reason |

**Never delete a row**, and never edit an agreed invariant in place — supersede
it with a new ID. A deleted invariant takes with it the answer to "was this ever
true?", which is the only question anyone asks of this file six months later.

IDs are `INV-NNN`, monotonic, never reused, never renumbered.

`Source` should be the `REQ-NNN` or `DEC-NNN` this came from wherever there is
one. That is what lets a single unit of work be looked up across all three
registers — the contract carries `x-req`, the ledger names what it reviewed, and
this column joins the invariant to the same requirement.

## Register

| ID | Invariant | Enforced by | Source | Status | Changed |
|----|-----------|-------------|--------|--------|---------|
| INV-001 | <one sentence, stated as a fact that is always true> | unassigned | REQ-001 | proposed | YYYY-MM-DD |

<!-- Add rows at the bottom. Next ID = highest ever used + 1, including rows
     that are superseded or removed. Never reuse.
     Source: the REQ-NNN or DEC-NNN this came from, or — if it came
     from nowhere in particular and is simply true. -->
