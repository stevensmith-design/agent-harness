---
name: domain-invariants
description: Domain constraints that are not shapes, and which side enforces each one. Applies to any code that implements or relies on a business rule, and to API proposals.
paths: ["src/**", "app/**", "lib/**", "api/**", "server/**", "services/**", "routes/**", "handlers/**", "migrations/**", "db/**", "prisma/**", "alembic/**", "docs/api-proposal/**"]
trigger: glob
---

# Domain invariants

Prevents: a rule enforced on the client and nowhere else, because each side
assumed the other owned it. Observed on a handover where the contract described
every field and none of the rules — once-per-day limits, immutability after
commit, what a `404` meant on each endpoint — and the backend list had to be
reconstructed from the app.

- **The register is `docs/product/domain-rules.md`.** Read it before implementing
  a business rule. It holds what must always be true and, per row, who enforces
  it. A schema does not express any of this.
- **Every invariant names a side.** `client` · `server` · `both` · `db`. An
  invariant with no side named is one nobody is implementing. `unassigned` is
  legal only while a row is `proposed`.
- **You are implementing one half.** When the register says `both`, shipping the
  client half does not make the row `enforced`. It stays `agreed` until every
  named side is done.
- **A constraint you discover while building goes in the register**, at
  `proposed`, before you code around it. The rules that cost most are the ones
  that were only ever in someone's head and then only ever in one codebase.
- **Never edit an agreed invariant in place** — supersede it with a new ID. Never
  delete a row. Same discipline as the requirement register, same reason.
- Shapes belong in `docs/api-proposal/*.yaml`; rules belong here. If you are
  about to write a constraint into a schema `description:`, it belongs in the
  register with an ID, and the description can cite it.
