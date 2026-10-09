---
name: ui-design-principles
description: >
  Apply human-centered UI design principles before and during interface creation. Use this
  skill whenever the user asks to build, design, add, or modify any UI — components, screens,
  flows, dashboards, forms, onboarding, empty states, or any visual interface. Also triggers
  when a design brief or spec mentions new screens, when impeccable is invoked, and when
  any frontend file (.tsx, .vue, .css, .html, component) is newly created or significantly
  changed. This is a guardrail skill — load it at the start of UI work, not after. If a
  project instructions reference this skill, apply it to the UI tasks those instructions cover.
  Siblings: use ui-design-system to create/extract/audit the design system as a whole,
  ui-design-review to review a finished screen or PR, and ia-review for navigation/flow
  structure; this skill is the build-time guardrail while a screen is being made.
---

# UI Design Principles

Guardrail skill for UI creation. Loads before design decisions are made — not after.

**Dependencies:** `ui-design-system` owns system creation/extraction and its token validator;
`ui-design-review` owns post-build sign-off. If either sibling is unavailable, do not silently
reimplement it here—state the limitation and keep this skill to build-time guardrails.
This skill's `references/rules.md` is canonical; the review skill carries a byte-identical mirror.

Three responsibilities:
1. **Commit to a design direction** before any code is written
2. **Define the design system** — establish binding token rules before the first component
3. **Apply the rules** throughout — preventing AI-generated-looking output

---

## Step 1: Design thinking (run before writing any code)

Before touching code or layout, answer these six questions. The answers become the design contract for this piece of work. Resolve the **task structure** before committing to a visual direction — an aesthetic chosen before the structure is settled ends up decorating the wrong layout.

If task structure involves navigation, grouping, labels, information scent, or progressive
disclosure, run `ia-review` before committing the visual direction. Consume its structural
findings here rather than silently treating visual layout decisions as IA approval.

**Purpose** — What problem does this interface solve? Who is the user and what do they need to do?

**Platform** — Web, iOS, Android, or cross-platform? Platform determines navigation conventions, tap target sizing, font choices, and which native components to use.

**Register** — Is this product UI (design serves the product — app, dashboard, tool) or brand UI (design IS the product — landing page, campaign)? This determines how bold to go.

**Task structure** — Settle these before any visual choice; they decide the layout, and the aesthetic only dresses it:

- the primary action / decision
- information priority
- frequency and expertise of the user
- the interaction primitive
- page vs. panel vs. modal
- progressive disclosure
- irreversibility / consequences
- responsive structural behaviour

**Aesthetic commitment** — Pick a clear direction and name it in one sentence. Vague is wrong. Examples:
- "Calm and minimal — no heavy shadows, flat structure, lots of white space"
- "Warm and playful — rounded forms, soft colors, expressive type"
- "Editorial — strong typographic hierarchy, restrained color, unexpected layout"
- "Dense and utilitarian — information-first, tight spacing, no decoration"

When the user names a style, the direction is unresolved, multiple styles are being mixed, or an
external style recommender is available, read `references/design-directions.md`. Classify visual
language separately from layout strategy, content primitive, theme/mode, effect, and requirements;
then write both a direction sentence and an exclusion sentence. Do not turn a style list into a
sampler.

When the user supplies or names an **external source** — a live site, a screenshot, a component
library, a design-system file (e.g. a found `DESIGN.md`), or a style recommender — read
`references/reference-intake.md` first. Record the source's role and provenance and treat it as
evidence, not authority; project evidence and these rules adjudicate what it suggests.

When the user explicitly requests Material Design, the target is Android, or the codebase already
uses Material 3 components/tokens, also read `references/material-3.md`. Decide whether the product
is Material-native, Material-adapted, or merely Material-compatible before selecting components.

**Differentiation** — What will make this screen feel considered rather than generated? One specific choice that signals a human made a decision here (a font pairing, a color, a layout move, a motion detail).

**Example output:**
```
Purpose: B2B dashboard for ops teams. Users scan status across 20+ items and act on exceptions fast.
Platform: Web.
Register: Product UI — design serves the task, not the brand.
Aesthetic: Dense and utilitarian — information-first, tight spacing, no decoration.
Differentiation: Status communicated by a left-aligned color ramp (not icons), so exceptions surface in peripheral vision without scanning each row.
```


### Evidence and authority — what can justify a change

The full authority and adjudication model is `references/rules.md` → **Decision tiers and the
override process** (accessibility/correctness first; then current project contract and authoritative
components; then platform conventions and named principles; generic heuristics last — a shipped
one-off can be drift, an override records intent but cannot waive accessibility). Every change states
basis, evidence, confidence, scope, and compatibility; before changing an existing component/state,
inventory representative instances, choose the smallest compatible correction, render the target plus
representative siblings, and promote into the system only after validation and authorization.

For state styling, use the **minimum sufficient signal**. "Do not rely on colour alone" does not mean
"always add a checkmark": a border, weight, shape, indicator, label, or positional relationship may
already communicate the state. Add a mark only when the selection model and rendered evidence need
one.

---

## Step 1.5: Design system bootstrap

**Scope gate — match the ceremony to the change.** Not every task needs a full system bootstrap:

- **Small change** (adjust a button, a spacing value, one component in an existing app): use the project's authoritative existing components and tokens as-is. Document only a *genuinely new* decision. Do not create a `DESIGN.md` to move one button.
- **Substantial new UI** (a new screen, flow, or feature): write a lightweight design contract (Step 1) and confirm the tokens it needs already exist or add them.
- **Missing or incoherent system** (no `DESIGN.md`, or the tokens don't cohere): invoke the `ui-design-system` skill (Create or Extract mode) — that skill *owns* establishing the system; this skill *consumes* it. Do not reverse-engineer the whole system inline here.

The bootstrap steps below apply to the substantial-new-UI and (via `ui-design-system`) the missing-system cases — not to a small change against a system that already exists.

Before writing any code, locate the project's design document. Look for `DESIGN.md` first; if not found, check for `design-guidelines.*`, `DESIGN_SYSTEM.md`, `brand.md`, or similar. Also look for a `tokens.json` alongside it.

### If a design doc exists (under any name):
Read it. Treat current, approved decisions as the project contract, while checking that the
rendered authoritative components still agree with it. Do not introduce conflicting spacing,
colour, radius, or type values. If a decision is uncovered, propose it and validate its blast
radius before persisting it; a review or small implementation request does not itself authorize
rewriting the design contract.

### If nothing exists (missing system → hand off to `ui-design-system`, don't build it here):

Per the scope gate, a missing or incoherent system is established by the **`ui-design-system`** skill, not by this one. Invoke it (**Create mode** → `.agents/skills/ui-design-system/references/mode-create.md`) to settle spacing scale, radius scale, colour tokens, typography, and surface/elevation and produce `DESIGN.md` + `tokens.json` from `references/design-system-template.md`, then return here to build screens against the result. Do the deciding there — do not reproduce or reinvent those token decisions inline here. Carry the **aesthetic commitment** from Step 1 into the file.

> **Gotcha — never synthesize a gradient or glow canvas, even if you believe a design doc committed one.** Verify the actual canvas token in the project's tokens file (tokens.json / theme) before styling the canvas. A half-remembered "documented gradient canvas" is almost always wrong; the only legitimate gradient surfaces are committed immersive screens, registered in the project's `scan-exceptions.conf`.

### Validator gate — the system must cohere before the first component

Once the tokens are defined (whether newly created or read from an existing file), run the
token-graph validator **as a gate**, before building any component:

```bash
make check-design          # or: python3 scripts/validate-tokens.py . --strict
```

The validator lives at `scripts/validate-tokens.py` in this harness — one copy, owned by the
harness, shared by this skill, `ui-design-system`, `ui-design-review` and the
`check-design` gate. There is no discovery step and no fallback root: if that file is
missing the harness is broken, and `make check-design` says so and fails. **Never report a
`PASS` for a validator that did not run.**

`--strict` requires the core relationships (body-on-canvas, CTA-label, value step, neutral ramp) to
actually be assessed — an unresolved required role becomes a `FAIL`, not a silent `SKIP`. It computes
the between-token relationships no per-component rule can see (full catalog in
`.agents/skills/ui-design-system/references/validator-checks.md`). **Resolve every `FAIL` before writing the first
component** — a broken relationship baked into the tokens propagates into every screen. A `PASS` is
the floor, not sign-off; it does not judge layout or taste. For full system work (Create / Extract /
Coherence audit / Drift), use the `ui-design-system` skill.

### Component-first token commitment

This is the most important principle: **when the AI introduces a new element type for the first time, it must define the token rules for that element before implementing it.**

- First card → define card `border-radius`, `padding`, `shadow`/`border` decision → apply consistently to all subsequent cards
- First button → define height, padding, border-radius, font-size for each variant → apply to all buttons
- First input → define height, border, label position → apply to all form inputs
- First modal → decide sheet vs. full modal, decide the radius, decide the backdrop → document it

The goal is that **every design decision is made once and then applied consistently** — not reinvented per component. A component that introduces a new spacing or radius value not in `DESIGN.md` is a sign that the design system wasn't followed.

If the project already has styles but no written system (existing app), that is the missing/incoherent-system case: use **`ui-design-system` (Extract mode)** to reverse-engineer the implicit decisions into `DESIGN.md` before adding new UI — don't extract ad hoc here. This makes inconsistencies visible and defines what to align to going forward.

---

## Step 2: Apply the rules

Read `references/quick-rules.md` now — the complete rule index, one line per rule. Do **not** read all of `references/rules.md` up front. Instead, open the named rules.md section at each decision point (the routing table at the end of quick-rules.md maps decisions → sections): choosing the canvas → "Choosing the canvas"; first card → "Border radius scale" + "List and card patterns"; first button → "Button rules"; and so on. rules.md remains canonical — when the index and the full text seem to differ, the full text wins.

**Build in grayscale first.** Establish layout, spacing, and hierarchy using the neutral ramp only. Then add colour in this order: (1) the one brand accent per the colour strategy; (2) semantic state colours; (3) nothing else. If the screen doesn't work in grayscale, colour won't fix it — and colour added last is colour with purpose. This is the cheapest mechanical defence against colour sprawl.

Before polishing, run the page-level hierarchy inventory in `rules.md` → **Page-level visual
hierarchy**. This is required for settings pages, dashboards, toolbars, and any screen with repeated
actions: repeated components share a family but receive prominence according to role, frequency,
and consequence. Finish with the squint test and a second grayscale check; token consistency alone
does not prove that the page has a clear reading order.

Rules sort into **three tiers** — the full definitions and the override process live in `references/rules.md` → **Decision tiers**. In brief (nothing outside Tier 1 is banned absolutely):

- **Tier 1 — Quality requirements**, never overridable when applicable (placeholder text in production, missing reachable/error states, colour-only meaning, controls without an accessible name; performance only when it causes demonstrated harm at real scale).
- **Tier 2 — Design decision gates**: available to a design that clears the **six gate questions** (Purpose · Direction-fit · Systematic · Still-communicates-without-it · No a11y/hierarchy cost · Legible) and logs the decision. Reach deliberately and record why; an unexplained one reads as AI.
- **Tier 3 — AI-tell risk indicators**: assemblies to avoid stacking (centered-hero, icon-tile grid, badge-above-H1, stat banner…). Any one may be fine; several together signal "assembled, not designed."

The rule index in quick-rules.md is the working reference throughout — every gate and every craft number appears there with its rules.md section named.

---

## Step 3: During implementation

Check against the design system and rules at each decision point.

When introducing or changing an element type:
1. Check if the element type is defined in `DESIGN.md`
2. Inventory its existing instances and states before changing the shared rule
3. If undefined — propose the rule, implement the smallest local proof, and validate representative siblings
4. If defined — use the tokens exactly unless evidence shows the contract is stale or defective
5. Persist a new or revised rule only with authorization and cross-context validation

**"Propose" for a Tier-2 gated pattern — ship the default, surface the pattern.** Do not implement a gated pattern and write its authorizing `DESIGN.md` entry in the same change (self-authored justification is not legibility). Ship the default/flat/neutral form now and surface the gated pattern as a labeled proposal carrying its six-gate justification, for a human to ratify or a pre-existing override to authorize. Full doctrine: `references/rules.md` → **Authoring resolution — ship the default, propose the pattern**.

> **Before / after — the hero CTA on a new onboarding screen.**
> - ✗ *Ship-the-gated-form (wrong):* implement `bg-gradient-to-b from-indigo-400 to-indigo-600` on the CTA **and** add a DESIGN.md override in the same commit. That is self-authorization — the gate never had a human.
> - ✓ *Ship-the-default, propose:* ship the CTA as the flat `--color-primary` solid now. Alongside, surface: *"Proposal: same-hue ≤5% vertical gradient on the primary as a light-source cue — Purpose: depth on the immersive hero; Direction-fit: matches the committed 'warm, tactile' onboarding; Systematic: applied to every primary; Communicates-without: hierarchy already holds in grayscale; No a11y cost: label contrast unchanged; Legible: pending your ratification → DESIGN.md Override Log."* The gradient ships only after a human says yes.

Flag any deviation: state which rule is affected, why the deviation is justified, and log it in the Override Log if proceeding.

---

## CLAUDE.md setup

To make this skill always active for UI work in a project, add to the project's CLAUDE.md:

```
## UI Design
Always apply @skills/ui-design-principles when creating or modifying any UI component, screen, or frontend file. Check for DESIGN.md and tokens.json at the project root and use them as the binding design contract. Read references/quick-rules.md before making any visual decisions, and open the named rules.md section at each decision point.
```
