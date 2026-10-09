# Plan: <feature name>

Spec: `./spec.md`

## Approach

One paragraph: the shape of the solution and why this shape.

## Pre-implementation gates

Tick each before writing code. A deviation is allowed only if it is recorded in
Complexity Tracking below with a reason.

- [ ] **Simplicity** — no layer, abstraction, or dependency added for a
      requirement that does not exist yet.
- [ ] **Anti-abstraction** — the framework is used directly; one representation
      per concept, not a model + DTO + view-model that all say the same thing.
- [ ] **Integration-first** — contracts defined and contract tests written before
      the implementation they describe.
- [ ] **Rules** — the `.agents/rules/` files and ADRs this work must satisfy are
      listed below and have been read.
- [ ] **No unresolved `[NEEDS CLARIFICATION]` markers in the spec.**

Applicable rules / ADRs: …

## Design

Architecture, data model, contracts, states. Diagrams welcome.

## Complexity tracking

Anything that breaks a gate above, and the reason it earns its cost.

| Deviation | Gate broken | Why it is worth it | Simpler option rejected because |
|---|---|---|---|
| | | | |

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|

## Verification strategy

How this will be proven: which tests, which `make verify` outcome, what a human
needs to look at with their own eyes.
