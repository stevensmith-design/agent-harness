# Contract: Approval

The state transition. If it is not logged in `evidence/approvals.md`, it did not happen — and an agent will infer it.

## Required

- **Who** approved — a name, not a role
- **When**
- **Exactly what** — the specific scope, narrow enough that a reader can tell what is *not* covered
- **The evidence they saw** — the review, the run, the diff
- **What it unlocks** — the thing that may now proceed

## Rules

- **The producer never approves their own work.**
- An agent may never record an approval on a person's behalf. It may draft the row; a person confirms it.
- Approval is scoped and does not generalise. Approving one output does not approve the pattern.
