# Worked example — an AI customer support agent

From the AI Product Design System's reference product **Aria**: handles order
queries, returns, refunds, product questions and account support; can read order
data, process standard refunds, and escalate to a human; handles ~80% of support
volume autonomously.

It is here rather than in the skill because the value of a worked example is
comparison — read it *after* you have drafted your own table, to check the
resolution you worked at, not to copy from.

## Which types applied

| Failure type | Applies | Why |
|---|---|---|
| Hallucination | Sometimes | Product and policy detail — not order data, which is live |
| Overconfidence | Yes | Every response comes out at the same confidence regardless of certainty |
| Silent failure | Yes | **Highest risk** — a confident wrong answer is indistinguishable from a right one |
| Scope failure | Yes | Customers ask legal, complaints and complex edge cases constantly |
| Misunderstood intent | Yes | Common with poorly phrased queries, and with customers in distress |
| Stale output | Yes | Policy and pricing lag product updates |
| Cascading error | Sometimes | Refund workflows — an early misread of order data affects the whole resolution |
| Partial completion | Yes | Return + refund + replacement can fail partway |
| Alignment error | Yes | Optimised for resolution time — closing a ticket is not the same as solving a problem |

## The four decisions

| Type | Detection | Presentation | Recovery | Rollback |
|---|---|---|---|---|
| **Hallucination** | Not detectable by the system | Graceful degradation — policy answers carry "based on our current information" plus a source link | Inline "this doesn't look right" flag, routed to a human review queue | N/A — output only |
| **Overconfidence** | Not detectable | Differentiated language: order data stated flatly, policy and advice hedged | Presentation fix; no separate path | N/A |
| **Silent failure** | Not detectable | Every resolution ends with "does this resolve your issue?" — a No escalates immediately | One-click escalation from any response | N/A |
| **Scope failure** | Detectable — it knows its own scope | Explicit: "this is outside what I can help with — connecting you to the team" | Warm handoff, full conversation context carried | N/A |
| **Misunderstood intent** | Partial — intent confirmed before acting on anything complex | "Just to confirm — you're asking about X. Is that right?" shown before any action | Customer corrects in one message; agent re-attempts | N/A — nothing acted on until confirmed |
| **Stale output** | Partial — policy content is versioned | Every policy answer timestamped, with a link to the live page | Customer sent to the live policy page | N/A |
| **Cascading error** | Detectable — the workflow has validation checkpoints | Pauses and confirms state at each checkpoint; surfaces at the first anomaly | Restart from the last confirmed checkpoint; human handoff if unresolvable | **Partial** — pre-refund steps reverse, post-payment steps do not |
| **Partial completion** | Detectable — the workflow is tracked | Explicit: "I finished steps 1 and 2 but couldn't complete step 3 — here's where things stand" | Customer finishes manually, or hands to an agent | **Full** — nothing commits until all steps succeed |
| **Alignment error** | **Not detectable at the interaction level** — every ticket it closes looks like a success | No user-facing presentation; the safeguard is a counter-metric: reopen rate and 7-day repeat-contact rate, read weekly by the support lead | Reopening is one click and does not require re-explaining | N/A — the resolution itself is reversible, the misdirected incentive is not |

## What to notice

**Three of the eight are undetectable by the system**, and those got the most
design attention rather than the least — a confirmation prompt, hedged language,
an inline flag. Undetectable does not mean unaddressable; it means the safeguard
has to be in the interface rather than in the code.

**The refund is the one with no rollback**, and that is what forces a
confirmation step before execution. The rollback column is not documentation —
it changes the interaction design. An irreversible action without an approval
gate is the finding this whole exercise exists to surface.

**Two failure types resolved to presentation changes alone.** Not every row needs
machinery. Overconfidence was fixed by writing differently.

**The alignment error has no user-facing design at all**, and that is correct.
Its row exists to force the question "what would tell us this is happening?" —
and the answer is a counter-metric with a named reader, not an interface change.
Resolution time going down while repeat contacts go up is the shape of it.
