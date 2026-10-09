# Feature lifecycle — stages, gates, evidence, actors

The SOP behind `../workflows/feature.workflow.yaml`. Follow this even with no
workflow engine running. Each stage names its gate type, the record it emits,
and who is permitted to act.

| # | Stage | Gate type | Actor | Emits | Advance requires |
|---|---|---|---|---|---|
| 1 | intake | deterministic | runner | — | `work-item.json` is schema-valid |
| 2 | plan | AI | producer | `plan.md`, `spec.md` | no `[NEEDS CLARIFICATION]` remaining; no source edits |
| 3 | implement | AI | producer | code diff, in a worktree | plan implemented; smallest diff |
| 4 | deterministic-validation | deterministic | runner | `EvidenceRecord(deterministic_validation)` | `make check` passes |
| 5 | independent-review | AI | reviewer, **fresh context** | `EvidenceRecord(governed_review)`, `Finding[]` | review passes; **reviewer ≠ producer** |
| 6 | human-approval | human | approver, **human only** | `Approval` (`trust: authenticated_human`) | required by policy; blocking findings resolved. No channel in this harness issues that trust today — see HARNESS-GUIDE.md |
| 7 | closure | deterministic | closer, **human** | `ClosureRecord` | review + approval referenced; **closer ≠ producer** |

## Gate ordering

Deterministic → probabilistic → human. Never spend a model call on something a
script can decide, and never spend a person on something a model can. The order
is a cost argument, not a hierarchy of trust.

## Anti-self-certification — the core rule

Enforced by `../scripts/validate_governance.py`:

1. **Independent review.** A `governed_review` evidence record must have
   `provenance.cleanContext = true`, `inputAccess = read_only`,
   `resultEmission = governed_output_only`, and `actorId ≠ producerActorId`.
2. **Human approval.** An approval with `approvalClass = human` must have
   `principalKind = human` **and** `trust = authenticated_human`. An agent
   cannot stand in for a human approver — and neither can a claim. A
   declaration made with `scripts/declare-intent.sh` is `self_reported` and is
   rejected here, because that script proves a declaration was made, not that a
   person made it. Note the limit: this is a labelling discipline, not
   authentication. Nothing in this harness currently issues the identity that
   `authenticated_human` asserts; see the trust table in `HARNESS-GUIDE.md`.
3. **Closure.** A closure record must reference at least one independent review
   and one approval, and its closing actor must be a human with
   `actorId ≠ producerActorId`.

## When human approval is required

Default policy — edit `governance.human_approval_required_for` in
`harness.config.yaml`. Ships requiring it for auth, payments, data deletion,
release config, and routing. Skip it for low-risk changes whose review passed
with no blocking findings; that is what the `bug` workflow does.

## Failure and recovery

- Failed deterministic gate → back to `implement`, failing evidence attached.
- Blocking review findings → back to `implement`, findings preserved.
- Rejected approval → emit a `Rejection`, back to `implement`.
- Closure is terminal. Corrective work opens a new work item — you do not reopen
  a closed one, because that is how an audit trail becomes fiction.
