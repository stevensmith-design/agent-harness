# ai-product overlay

For products where a model is in the critical path — not a repo that happens to
call an API once.

## What it adds

| File | Does |
|---|---|
| `.agents/rules/ai-boundaries.md` | path-scoped rule: the trust boundary around model input and output |
| `scripts/gates/ai-evals.sh` | an AI surface with no evals does not ship |
| `.agents/skills/harness-eval-design/` | writing evals that can fail, before the prompt |
| `.agents/skills/harness-model-choice/` | model selection as a recorded decision with falsifiable criteria |
| `.agents/skills/harness-failure-design/` | what the product does when the AI is wrong — the design side |

## What it changes in the base

- `evals.enabled: true` — for an AI product, evals stop being an L4 option
- adds an `ai` surface at `risk: high, level: L3`, so the policy gate requires a
  recorded human approval before a change to model-facing code merges

It overwrites nothing. If it needed the base to behave differently, the base
would gain a config knob and this overlay would set it — see `scripts/overlay.sh`
for why that constraint exists.

## Apply

```bash
make overlay-apply NAME=ai-product
make harness-sync && make check
```

## The design half

`failure-design` is the first skill carrying AI *product design* discipline, drawn
from Steven Smith's AI Product Design System (his own material, used with
permission as the overlay's author).

The rule for this half: **the decision content lives in the skill.** An agent
should never be sent to open a 500KB playbook to answer "what are the failure
types". The taxonomy, the three presentation approaches and the rollback states
are inline; only the worked example — which is for comparison, not lookup — sits
in `references/`.

Three more are candidates and are not built yet, because their source material
has two unresolved contradictions (two incompatible L0–L5 autonomy scales, and
two different pattern vocabularies):

- **`ai-fit`** — should this be AI at all? The archetype and autonomy framework.
- **`interaction-map`** — the AI Moment Scan and the map it produces.
- **`ai-readiness`** — the pre-launch pass/fail gate.

## Scope — what this overlay covers, and what it does not

The design half is built on a system its author assessed against Google's PAIR
guidebook, topic by topic: **83 topics, scored Direct 17 · Adapted 3 ·
Partial 31 · Not included 32.** His own verdict:

> Strong in design; thin on data, measurement, and harm.

That assessment decides what gets built here. Skills are written only where the
source material is *stronger* than the guidebook it draws on — the author names
the Autonomy Scale, Interaction Design Policy, Failure Design Framework and
Trust Calibration Guide as places where it "operationalise[s] PAIR content in
ways that are more immediately actionable than the source material," plus the
archetype and autonomy framework as an original contribution PAIR does not have.
`failure-design` is one of those four. That is why it exists and reads as
confident.

**Three areas are deliberately not covered, and will not be until the source
material is deepened.** A skill built on partial coverage restates a summary
while reading as authoritative, which is worse than an honest gap:

| Not covered | Why it matters | Anything else covering it? |
|---|---|---|
| **Data and model lifecycle** | data quality, labelling, data cascades, trust continuity across model updates | **No.** The base's `data-access` rule is about database access patterns, not training data. |
| **Sociotechnical harm** | allocative, quality-of-service, representational, social, interpersonal harm | **Partly.** `threat-model` and `security-review` cover *security* harm. Sociotechnical harm is uncovered by either half. |
| **Explanation design** | the explanation-type taxonomy — influential feature, contrastive, example-based, interactive | **No.** |

Measurement is the exception: it is thin in the design system but covered from
the engineering side by `eval-design`, the `ai-evals` gate and
`evals.enabled: true`. The combined overlay is stronger there than either half
alone.

Adopting this overlay means: **use it for product and experience design
decisions; supplement it for data strategy, model evaluation methodology and
harm assessment.** That sentence is the author's, not a disclaimer added here.
