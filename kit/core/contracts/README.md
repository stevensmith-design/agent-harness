# Contracts

The required shape of an artifact. **A contract missing a required field means the work has not started** — not that it is nearly finished.

| Contract | Governs |
|---|---|
| `brief.md` | What must exist before work starts |
| `review.md` | What a review reports — and that it reports and stops |
| `approval.md` | The state transition, and who may make it |
| `handoff.md` | How work leaves this harness |

The chain: `brief.md` → work → `review.md` → `approval.md` → `handoff.md`.

Contracts are also the seam between harnesses. Work leaves through `handoff.md` and is reviewed against it on the other side.
