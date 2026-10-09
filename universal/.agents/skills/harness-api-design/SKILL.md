---
name: harness-api-design
description: Write an OpenAPI proposal for an operation that does not exist yet, or whose shape is wrong, derived from the requirement that needs it. Use when a contract has to be agreed between the side that consumes it and the side that implements it.
license: MIT
metadata:
  harness.tier: planning
allowed-tools: Read Glob Grep Write Bash(ls:*)
---

# api-design

Turns "the backend hasn't decided yet" from a blocker into a proposal. The app
knows exactly what it needs; write that down instead of waiting.

| Use it when | Do not use it when |
|---|---|
| A requirement needs data no operation provides | An endpoint exists and works — use it |
| An existing endpoint's shape forces bad client code | You are changing a live contract — that needs an ADR and the owning team |
| You want a contract before integration week | You are implementing the backend — this is a proposal, not an implementation |

**Produces:** `docs/api-proposal/<resource>.yaml` + a short rationale.
**Never:** implements the endpoint, or assumes the proposal was accepted.

## Procedure

1. Start from the **requirement**, not the database. List exactly what the
   consumer needs to render or act on, which states it must handle (loading,
   empty, partial, error), and what a user can do. The operation exists to serve
   that. Where the requirement lives — a screen, a use case, a job — is the
   project's business; the `REQ-NNN` is what you carry into the proposal.
2. Write OpenAPI 3.x. Be specific about the things that cause integration pain:
   - Pagination shape, and what an empty page looks like.
   - Nullability on **every** field. "It's probably always there" is the bug.
   - Enums with their full value set, and what the client does on an unknown value.
   - Error responses with a stable machine-readable code, not just a message.
   - Timestamps: format and timezone, stated.
3. Include a realistic example response — the same data your stub returns, so
   the proposal and the stub cannot drift apart.
4. Add a rationale block: which requirement needs this, why an existing
   operation does not serve it, and what the consumer does today without it.
5. Keep the stub aligned. If the proposal changes, the stub changes in the same
   commit.

## Rules

- A proposal is a request, not a decision. Give every operation
  `x-status: proposed` and expect the owning team to change it.
- **Every operation carries `x-req: REQ-NNN`** — the requirement it serves, from
  `docs/product/requirements.md`. It is the join between the contract, the
  sign-off ledger and the invariant register, and it is what lets anyone ask
  "I am building REQ-014, what do I need to know?" rather than reading three
  files and guessing. `make check-api` fails without it, and fails again if a
  requirement in build has no operation naming it.
- Do not design for hypothetical future requirements. Propose what the current
  spec needs; extend later when a real one arrives.
