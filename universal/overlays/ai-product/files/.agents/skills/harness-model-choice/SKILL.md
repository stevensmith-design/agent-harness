---
name: harness-model-choice
description: Choose a model for a task and record why, with criteria that could come back wrong — latency budget, cost per call, and eval pass rate. Use when picking a model, when swapping one, or when a provider deprecates the one in production.
license: MIT
metadata:
  harness.tier: ai
allowed-tools: Read Glob Grep Write Edit Bash(make:*)
---

# model-choice

An ADR with a fixed shape. `adr` owns architecture decisions generally; this is
the flavour for "which model, and what would make us change our mind".

It exists because model choice is the decision most often made once, informally,
and never revisited — and it is also the one most likely to be invalidated by
someone else's release note.

## Decide these four before comparing anything

1. **The latency budget.** Not "fast". The number of milliseconds at which the
   feature stops being worth having, and whether that is p50 or p95. A summariser
   in a batch job and a typeahead have nothing in common.
2. **The cost ceiling.** Per call, and per active user per month. A model that
   is 3× better and 30× dearer is a different product decision, not a technical one.
3. **The quality bar.** The eval pass rate below which you would not ship. Set it
   before you see any scores, or you will set it wherever the favourite lands.
4. **The failure mode you can live with.** Confidently wrong, or refuses too
   often? These trade against each other and the right answer is task-specific.
   A support agent and a code reviewer want opposite ends.

## Then compare, cheaply

Two or three candidates, the same eval set, the same prompt. Record for each:
pass rate, p50 and p95 latency, cost per call, and the shape of its failures —
the last is the one that changes minds.

Resist a matrix of ten models against twenty dimensions. It takes a week, and the
providers ship before you finish.

## Write it down as a decision

Use the ADR template with these sections filled:

- **Decision** — model, provider, version, and the exact identifier in production.
- **Criteria** — the four numbers above, as they were set *before* comparing.
- **Measured** — what each candidate scored. Include the ones you rejected; the
  next person will otherwise re-run them.
- **Confirmation** — how you will know this is still right. Name the eval and
  the cadence. A decision with no confirmation is a guess that got old.
- **Reversal cost** — what swapping would take. Usually the honest answer is
  "unknown", and finding out is cheaper now than in an incident.

## Pin the version

"gpt-class model" is not a decision. Record the exact identifier and pin it in
config. A silent upgrade is a change to your product that no PR shows, and the
eval run that would have caught it is the one this skill exists to make routine.

## Revisit when, not if

Set the trigger: a provider deprecation notice, a cost line that crosses the
ceiling, an eval pass rate that drops below the bar, or six months. Put it in
`docs/product/decisions.md` so it is visible rather than remembered.

## Anti-patterns

- **The biggest model by default.** Most tasks in a product are extraction,
  classification and formatting. A small model with a good prompt often wins on
  every criterion including quality.
- **Choosing on a demo.** Three impressive outputs is not a pass rate.
- **One model for everything.** Routing a cheap task to an expensive model is the
  most common avoidable cost in an AI product.
- **Comparing without an eval set.** Then you are comparing vibes, and the newest
  model always wins on vibes.
