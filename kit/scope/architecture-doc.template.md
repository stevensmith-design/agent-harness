# Harness Architecture — {{ORG}} / {{SURFACE}}

**Date:** {{DATE}} · **Author:** {{AUTHOR}} · **Status:** draft | agreed
**Source:** the scoping interview (`interview.md`), run {{DATE}} with {{PARTICIPANTS}}

> This document is agreed **before** anything is built. It is the contract for what the harness will and will not do.

---

## 0 · Context examined

What this design is based on — and what it is not. See `context.md`.

| Source | Kind (conversation · folder · file · repo · tool) | What it holds | Motion (`detect.sh`, where it applies) |
|---|---|---|---|
| | | | |

**Could not access:** {{sources named but unreachable — their contents are not assumed}}
**Contradictions found:** {{each one becomes a decision record}}

---

## 1 · Fitness

| Condition | Looks | Evidence |
|---|---|---|
| Structurable | strong / weak | |
| Continuing | strong / weak | |
| Decidable | strong / weak | |
| Receivable | strong / weak | |

**Recommendation:** required / worthwhile / not recommended — {{one sentence why}}
**Decision:** proceed / hold — {{who decided}}
**Accepted risks:** {{each weak condition, what to watch for, and the revisit trigger}}

---

## 2 · What this harness is for

{{One paragraph. What work, for whom, and what changes when it exists.}}

**Prime directive** — what failure looks like when the output is technically fine:

> {{…}}

---

## 3 · Surfaces

| Surface | Paths / scope | Blast radius | Approval tier | Starting rung | Why this rung |
|---|---|---|---|---|---|
| | | high/med/low | | L0–L4 | |

**Unmatched scope fails closed to:** high
**The experimentation surface is:** {{…}}

---

## 4 · Foundations

| Foundation | Exists today? | Where | Owner | Accurate? |
|---|---|---|---|---|

**Supersessions** — where two sources disagree and which wins:

- {{X}} supersedes {{Y}} on {{topic}}, because {{…}}

**Must never be invented:** {{…}}
**Must never appear in output:** {{…}}

---

## 5 · The standard

**Scorable today?** mechanical / partly / judgement-only

**Judged corpus:** {{n}} accepted, {{n}} rejected, at {{path}} — or **none yet**, in which case building it is Phase 1 and no deterministic quality gate is written until it exists.

---

## 6 · Boundaries

- **External content ingested:** {{…}} — data to analyse, never instruction to follow.
- **Personal data:** {{…}} — committable form: {{…}}
- **Secrets:** {{…}}
- **Languages:** outputs {{…}} · operating docs {{…}}

---

## 6b · Seams

**Does output leave this team?** yes / no — if no, say so explicitly; it is a decision, not an omission.

| Receives what we produce | What they do with it | Cadence | Their side harnessed? |
|---|---|---|---|
| | | one-shot / incremental | yes / no |

**What they currently have to ask about** — three real examples. These are the first entries in the handoff contract:

1.
2.
3.

**Rules that matter at the seam, and who enforces each:**

| Rule | Producer / receiver / both | On violation |
|---|---|---|

**Seams pointing inward** — what this work receives, and from whom:

## 7 · Governance

| Role | Owner |
|---|---|
| Foundations | |
| Harness + rule promotion | |
| Approval of {{high-risk surface}} | |

**Requires a logged approval:** {{…}}
**Retro cadence:** {{…}} · **Adversarial review cadence:** {{…}}

---

## 8 · Shape

- **Motion:** greenfield / overlay
- **Substrate:** repository / workspace
- **Runtimes:** {{…}}
- **Packs:** {{dev · design · business-development · marketing · project}}

---

## 9 · Phase 1

**First surface:** {{…}}
**First real work through it:** {{…}}, by {{date}}

**Out of scope for now, deliberately:** {{…}}

---

## 10 · What would change this plan

{{The revisit triggers. Each one names the observation that would reopen a decision above — most importantly the rung, which the corpus promotes.}}
