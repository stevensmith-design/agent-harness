# The four-layer DESIGN.md, evidence authority, and the promotion gate

SKILL.md points here for the structure every mode reads, writes, or verifies. The canonical template
is `.agents/skills/ui-design-principles/references/design-system-template.md` (one canonical template; do not fork
it).

## The four layers

A design system is not a token dump. It is four layers, and the fourth is the one that usually goes
missing — which is why systems drift and feel assembled.

| Layer | Name | What it holds | The question it answers |
|-------|------|---------------|-------------------------|
| **1** | **Intent** | Product character, audience, platform, aesthetic commitment in one sentence, and the defaults-retained-vs-decided declaration | *What is this system trying to feel like, and what did we actually decide?* |
| **2** | **System principles** | The strategy: colour strategy (restrained→drenched), separation model (value step / shadow / border), elevation-by-role, motion character | *What are the rules of this world?* |
| **3** | **Tokens & component rules** | The exact values — colour roles, radius, type, spacing, elevation ramp — mirrored 1:1 in `tokens.json`, plus per-component primitives | *What are the concrete values every screen must use?* |
| **4** | **Relationships & rationale** | Why the values work *together*: which contrast pairs were checked, why the neutral ramp is that hue, why selection≠action holds, why the value step is what it is — and the override log | *Why do these values cohere, and what would break if one changed?* |

Layer 3 is what most token files capture. Layer 4 is what the validator computes and what this skill
forces you to write down — so the next person (or the next AI) cannot silently break a relationship
it can't see.

## Evidence and authority — resolve conflicts, do not bless frequency

Judge both authority and current fitness:

1. Applicable accessibility/correctness requirements and demonstrated functional defects
2. Current, explicitly approved project contract (`DESIGN.md`, brand guidance, accepted override)
3. Authoritative shared components as rendered across representative contexts
4. Approved reference screens and clearly repeated product patterns
5. Relevant platform conventions
6. Named UI principles with observable evidence
7. Shared-skill defaults and unvalidated craft heuristics

Shipped does not automatically mean correct, and documentation can be stale. An override proves
intent, not continuing quality. Reconcile contradictions and identify the authoritative/most recent
source instead of silently following a one-off implementation or a generic default.

## System-promotion gate — local evidence before global rules

Do not promote a review recommendation into tokens, DESIGN.md, components, or a client guideline
until its blast radius is known:

1. Inventory all representative instances and states of the affected component or token.
2. Capture the dominant pattern and intentional variants; distinguish one-off drift from precedent.
3. Classify the correction as local, shared-component, or system-wide.
4. Choose the smallest compatible correction and render it in at least two sibling contexts when
   available, plus the original failing context.
5. Re-check resting geometry, hierarchy, contrast/accessibility, state meaning, and responsive use.
6. Record the decision status: **existing and verified**, **proposed**, **validated across
   representative screens**, **project-specific exception**, or **deprecated**.

A polished HTML guideline is a communication artifact, not proof that its prescriptions are correct.
Generate it from validated decisions and display the status/evidence for each rule so a speculative
local fix cannot silently become the canonical system.
