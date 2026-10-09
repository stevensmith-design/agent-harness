# Product layer

One job per file, and the separation between them is the point.

For a greenfield product or major new area, run `harness-product-start`. It
reconciles rough material into these existing files, tests value, feasibility
and quality risk, and stops for agreement before producing the first spec. It
does not create a second intake document or scaffold code.

| File | Holds | Changes |
|---|---|---|
| `PRD.md` | the narrative — problem, users, objectives, non-goals, how success is measured (skill: `prd`) | rarely |
| `requirements.md` | **the register** — every requirement, its status, priority, and links | constantly |
| `decisions.md` | dated product decisions, and the do-not-re-propose list | on each decision |
| `questions.md` | questions about intended behaviour, each closing into a `DEC-`, `INV-` or `REQ-` | as they are raised |

**`PRD.md` holds no mutable state.** No checkboxes, no phase status, no progress
table. The moment status lives inside the narrative document, that document
becomes a build database, and a build database that is also a stakeholder
artifact is neither — it gets version-forked within a couple of months and
replaced by a scatter of dated markdown files.

**The register is the only place a requirement's status is written.** Not a
second roadmap, not a tracker. Two hand-maintained files holding the same state
disagree within weeks and nothing detects it.

**Detailed acceptance criteria are not here.** They live in
`specs/REQ-NNN-<slug>/spec.md`. The register carries the one-sentence statement
and a pointer; the spec carries the detail. The PRD names who/what/why; the spec
names how.
