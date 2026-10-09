---
name: harness-adr
description: Record an architecture decision in MADR format, including how it will be confirmed. Use when a technical or architectural choice constrains future work, or when superseding an existing ADR. Product and scope decisions are /harness-decisions.
license: MIT
metadata:
  harness.tier: planning
allowed-tools: Read Glob Grep Write Bash(ls:*)
---

# adr

An ADR is how the harness answers "why can't I just refactor this?". Without one,
every agent re-derives the decision from scratch and half of them get it wrong.

| Use it when | Do not use it when |
|---|---|
| A choice constrains future work | It is reversible and cheap — just do it |
| The same debate has come up twice | It is a coding convention — that is a rule, not an ADR |
| You are overriding an existing decision | It is a product requirement — that is a spec |

## Procedure

1. Next number: `ls docs/decisions/`. Never reuse or renumber.
2. Copy `docs/decisions/0000-template.md` to `NNNN-short-title-with-dashes.md`.
3. Fill in — honestly, including the options you rejected:

   - **Context and problem statement** — the forces, not the conclusion.
   - **Considered options** — at least two real ones. One option means you are
     documenting, not deciding.
   - **Decision outcome** — what was chosen and why it beat the alternatives.
   - **Consequences** — good *and* bad. An ADR with no downside is marketing.
   - **Confirmation** — how anyone can check this decision is still being
     honoured: a gate script, a test, a review step. This is the section that
     makes an ADR enforceable rather than decorative. Write it every time.

4. Status starts `proposed`. A human moves it to `accepted`. An agent may
   propose; only a human accepts.
5. Superseding: set the old ADR's status to `superseded by NNNN` and link both
   ways. Never edit a decision's history — decisions are append-only.
6. If the decision constrains specific paths, add a `.agents/rules/` file citing
   the ADR so it loads when those files are touched. An ADR nobody's context
   loads is an ADR nobody follows.

## Rules for agents

- An `accepted` ADR is binding. If it blocks your task, say so and propose a
  superseding ADR — do not route around it, and do not treat it as advice.
- ADRs live under a protected path. Writing one requires the human to have asked.
