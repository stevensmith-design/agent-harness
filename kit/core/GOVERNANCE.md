# GOVERNANCE

<!-- Solo work: one person holds every role — name them anyway. The point is
     that an agent can never INFER approval; it must exist as a logged entry. -->

## Owners

| Role | Owner |
|---|---|
| Foundations | {{OWNER}} |
| The constitution and rule promotion | {{OWNER}} |
| Approval on any `high` surface | {{APPROVER}} |

## Requires a logged approval in `evidence/approvals.md`

- Changing any foundation file
- Promoting a candidate from `learning/candidates.md`
- Adding an entry to `learning/corpus/`
- Accepting a documented exception
- Anything on a `high` surface in `config/surfaces.tsv`

## Who may read what

| Zone | Readable by |
|---|---|
| Everything not listed below | Everyone with access to the harness |
| A **team** subdirectory under foundations or memory | The team |
| A **personal** subdirectory anywhere, and anything under a **private** path | **The individual only. Never committed or shared.** |

Those subdirectories are optional and this harness may have none of them — the rule exists before the content, which is the only order that works for privacy.

Enforced by `scripts/gates/data-boundary.sh`, not by convention — a rule about access that only exists in prose is a rule that survives until the first person in a hurry.

**Four questions before any personal context enters this harness at all:** what gets stored · who can see it · how it is edited · **how it is deleted**. The last one is the one that gets skipped and the one people actually care about. If any is unanswered, that content is not ready to live here.

## Exceptions

A deviation is legitimate only when documented:

```
EX-<n>: <rule deviated from> — <justification> — scope: <where> — <owner> — review by: <date>
```

An undocumented deviation, including a suppressed check with no matching entry, is a defect.

**Active exceptions:** none

## Cadence

- **Per piece of work:** the gates in `scripts/check.sh`, then the human gate.
- **Monthly:** the retro — `procedures/harness-retro.md`.
- **Quarterly, and before any handover:** an independent adversarial review, by someone who did not build this. Rotate the lens rather than running a fixed checklist, which calcifies into something that passes trivially.
