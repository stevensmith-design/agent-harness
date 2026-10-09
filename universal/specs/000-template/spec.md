# Spec: <feature name>

Status: draft · Owner: <name> · Created: YYYY-MM-DD

## Problem

What is broken or missing today, for whom, and what does it cost them?
No solution language in this section.

## Users and context

Who does this serve, and what are they doing when they hit it?

## User stories

### US-1: <title>
As a <role>, I want <capability>, so that <outcome>.

**Acceptance criteria** — each one testable, each one a fact you can check:

- [ ] Given <state>, when <action>, then <observable result>
- [ ] Given <error state>, when <action>, then <specific error behaviour>

## Screen states

Each state a person can land in, and what it shows. `N/A — <reason>` if this
change has no UI. The most common defect found by looking rather than testing
is a state nobody specified.

- Loading: …
- Empty (zero rows, no results): …
- Error (the call failed, the input was refused): …
- Success: …

## Data that persists

What is stored, where, and what a half-written change leaves behind.
`N/A — <reason>` if nothing is saved — and then nothing here may write.

## Roles and permissions

Who may do this, who may not, and what the refused case shows.
`N/A — <reason>` if every user of the product may do it.

## States this touches

The states that fan out across features — archived, deleted, withdrawn, expired,
permission removed — and which paths must still work in each. A defect found on
one path usually holds on its siblings. `N/A — <reason>` if none apply.

| State | What must happen |
|---|---|
| | |

## Failure and recovery

What the person sees when it fails, and how they get back to a good state.
`N/A — <reason>` only when there is no failure path, which is rare.

## Non-functional requirements

- Performance: …
- Accessibility: … (sits above design in the authority chain)
- Security / privacy: …
- Offline / failure behaviour: …

## Non-goals

What this deliberately does **not** do. The most-skipped and most-valuable
section — it is what stops scope creep in review.

- …

## Open questions

Every assumption you had to make, as a marker. `make check` fails while any
remain, so these must be answered before implementation starts.

- [NEEDS CLARIFICATION: <question>]

## Success

How we will know this worked, after it ships.
