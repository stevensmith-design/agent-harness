# UI Design Rules

Shared reference for `ui-design-principles` and `ui-design-review`. Contains the complete rule set — three decision tiers (quality requirements, design decision gates, AI-tell risk indicators) plus the design standards. Nothing here is banned absolutely except the Tier-1 quality requirements; everything else earns its place through legible, systematic reasoning. Both skills load this file.

<!-- MIRROR INVARIANT: this file is a byte-for-byte mirror of .agents/skills/ui-design-review/references/rules.md.
     Do NOT edit one copy alone. Edit one, then re-mirror the other (cp) so both are identical.


## Contents

- [Decision tiers and the override process](#decision-tiers-and-the-override-process)
- [Quality requirements](#quality-requirements) — correctness and completeness, non-negotiable
- [Design decision gates](#design-decision-gates) — patterns that must earn their place with legible, systematic reasoning
- [AI-tell risk indicators](#ai-tell-risk-indicators) — scrutiny triggers, not automatic failures; weight rises when several co-occur
- [Border radius scale](#border-radius-scale)
- [Shadows](#shadows) — incl. light-from-the-sky anatomy
- [Surface and elevation](#surface-and-elevation) — incl. choosing the canvas, separation toolkit
- [Gradients — when and how](#gradients--when-and-how)
- [Text on imagery](#text-on-imagery)
- [Icon system](#icon-system)
- [Optical alignment](#optical-alignment)
- [List and card patterns](#list-and-card-patterns)
- [Color — semantic roles](#color--semantic-roles)
- [Color strategy](#color-strategy)
- [Page-level visual hierarchy](#page-level-visual-hierarchy)
- [Data visualization](#data-visualization)
- [Data tables](#data-tables)
- [Imagery and avatars](#imagery-and-avatars)
- [Accessible semantics and keyboard](#accessible-semantics-and-keyboard)
- [Responsive and adaptive layout](#responsive-and-adaptive-layout-web)
- [Typography](#typography)
- [Color contrast](#color-contrast)
- [Tap targets](#tap-targets)
- [Button rules](#button-rules)
- [Form and input rules](#form-and-input-rules)
- [Spacing system](#spacing-system)
- [Edge cases and states](#edge-cases-and-states)
- [Copy hygiene](#copy-hygiene)
- [Information hierarchy](#information-hierarchy)
- [Cognitive load and interaction density](#cognitive-load-and-interaction-density)
- [Modal and sheet weight](#modal-and-sheet-weight)
- [Motion](#motion)
- [Platform notes](#platform-notes)
- [Design commitment check](#design-commitment-check)
- [Documentation integrity — absolute claims must be verifiable](#documentation-integrity--absolute-claims-must-be-verifiable)

---

## Decision tiers and the override process

The rules below sort into three tiers. **Only the first is a hard line. Nothing in the other two is banned absolutely — but a Tier-2 pattern is *presumed a defect by default*, and the design carries the burden of a documented, functional justification to keep it.** Absence of that justification — silence, "no reason found," or a reason that rests only on consistency/polish — *is* the finding; the pattern's mere presence, unjustified, resolves to remove. The reviewer still assesses *reasoning* rather than reflexively failing a technique that names a real job (the anti-dumb-linter carve-outs stand — see the functional exceptions throughout), but the burden has flipped: "I couldn't find a reason to keep it" now resolves to **remove it**, not leave it. "Failure: gradient found" is still the wrong *phrasing*; "the gradient has no defined role and isn't documented — presumed decorative, remove or justify" is the right one.

**Tier 1 — Quality requirements.** Correctness, completeness, accessibility, or demonstrated
performance failure. Wrong regardless of aesthetic intent; cannot be overridden. A failed
contrast ratio, inaccessible semantics, or a missing reachable/error state is a defect, not
taste. Performance patterns require scale and evidence: a layout animation across a large or
repeated subtree that measurably janks is a defect; a small isolated transition is a reviewable
risk, not automatically a correctness failure.

**Tier 2 — Design decision gates.** The patterns that read as AI slop *by default* — not because they're forbidden, but because their unexplained use signals no decision was made. A gate is not a "no"; it is a set of questions the choice must survive. A pattern passes the gate when it satisfies **all** of:

1. **Purpose** — it does a specific job here (not "looks better").
2. **Direction-fit** — it follows from the Step-1 aesthetic commitment, the product, the audience, and the platform.
3. **Systematic** — applied as a system decision, not a one-off; the same choice recurs wherever the same condition does.
4. **Still communicates without it** — hierarchy/meaning don't *depend* on the effect (it survives grayscale / removal).
5. **No accessibility or hierarchy cost** — it doesn't break contrast, tap targets, or the reading order.
6. **Legible** — the reasoning is written where a reviewer can find it (`DESIGN.md` override log), not carried in the author's head, and applied where an existing brand/product language already points. Legibility requires the decision to **pre-date** the use: an override entry created in the *same* change that introduces the pattern is self-justification, not legibility — and is itself a finding.

**The bar is legible intent.** An unexplained choice reads as AI even when it's good — "I don't understand why this button has a gradient" is a failed review regardless of the gradient's quality. Some treatments also carry a cultural tax: guilt-by-association from AI-era overuse, so the intent must be strong enough to outweigh the association *and* legible enough that the design itself communicates it. A pattern that clears the six questions and is logged in `DESIGN.md` is a design decision; the same pattern dropped in unexplained is a tell.

- **Legitimate:** a brand whose identity IS a warm cream palette uses a warm canvas, logged in `DESIGN.md`. Purpose, direction-fit, systematic, legible — it clears the gate.
- **Illegitimate:** the model self-decides a gradient button "looks better here." No purpose, no system, nothing written — the gate exists for exactly this.

**Tier 3 — AI-tell risk indicators.** Assemblies and co-occurrences that are *scrutiny triggers, not failures on their own* (centered-hero assembly, icon-tile feature-card grids, badge-above-H1, stat banner rows). One in isolation may be fine; several together is strong evidence the screen was assembled from defaults rather than designed. Raise scrutiny as they stack — see the [AI-tell risk indicators](#ai-tell-risk-indicators) tier.

---

## Quality requirements

**Tier 1.** These cannot be overridden. They are not taste decisions — they are correctness, completeness, accessibility, or performance failures. (Formerly "hard bans.")

| Requirement (violation) | Why it's non-negotiable |
|-----|--------------|
| **Placeholder text (Lorem Ipsum) in production** | Unfinished work shipped as complete. |
| **Demonstrably harmful layout animation** | Animating layout properties can trigger repeated layout. Treat large/repeated animations or measured jank as defects. For a small isolated control, review duration, affected subtree, frequency, and device performance before ruling; prefer `transform`/`opacity` when they preserve the intended geometry. |
| **No edge-case states designed** | Loading, empty, error, and zero-data states are part of the feature, not optional polish. A screen without these states is incomplete. |
| **Color as the only signal** | Color alone fails color-blind users and breaks in dark/light mode inversions. Always pair color with a second non-colour channel — an icon/mark, label, shape, border, weight, or position. That second channel does not have to be an icon: for a single-select segmented/tab control the selected item's fill + border + weight + position already is it (see *Single-select vs multi-select* under Color — semantic roles). The failure is colour carrying the state *alone*, not the absence of a check specifically. |
| **Controls without a persistent accessible name/context** | Placeholder-only data-entry fields lose context after entry. Visible labels are the strong default for forms; compact search/filter controls may use another persistent accessible labelling pattern when purpose remains clear before, during, and after input. |
| **Semantic-palette leak** (semantic/index ramp used for decoration) | The palette that is supposed to *mean* something — safety, order, status, category — must not be spent on non-semantic decoration. Drawing a decorative bar, border, or fill from the semantic/index ramp (e.g. phase bars from `index-a/b/c`, a "goal" label tinted from the status ramp) corrupts the meaning-carrying layer: once the ramp appears where it encodes nothing, it can no longer be trusted where it encodes something. This is a correctness failure in the signalling system, not a taste call — it is **not waivable by an override** and essentially never clears sign-off. Fix: carry decoration/hierarchy with the neutral ramp, surface, weight, or structure; reserve the semantic ramp for real encoded meaning. |

---

## Design decision gates

**Tier 2.** These are the reach-for-it defaults that produce generic output *when unexamined*. Each row below names a pattern and its usual failure. Read it as a **gate, not a ban — but a gate whose default is closed**: the pattern is *presumed a defect*, and becomes available only to a design that actively runs it through the six gate questions (Purpose · Direction-fit · Systematic · Still-communicates-without-it · No a11y/hierarchy cost · Legible) *and logs the decision in* `DESIGN.md`. The reviewer assesses whether that documented reasoning exists and holds; **absence of it is the finding, not a reason to wait for proof of failure.** An unexplained instance is a defect to remove-or-justify; a justified, documented, systematic one is a design decision. Consistency alone does not clear the gate — a repeated decorative gesture is systematic *decoration* (see the "What does NOT count as justification" list under *Decision tiers and the override process* → this file's adjudication guidance, mirrored in `impeccable-review/references/adjudication.md`). (Formerly "default bans.")

**Reviewer stance — assess the reasoning, both directions:**

- ✗ *"Gradient on the primary button. No entry in DESIGN.md, used on one button only, no stated purpose — the gate isn't cleared. Finding: reads as decoration/AI-default."*
- ✓ *"Gradient on the onboarding hero. DESIGN.md logs it: brand palette, immersive surface, 2 stops within 40° hue, one direction system-wide, hierarchy survives grayscale. Gate cleared — no issue."*

The verdict language is the tell: write "the gradient lacks a defined role and isn't documented," never "failure: gradient found."

### Authoring resolution — ship the default, propose the pattern

When *authoring* a Tier-2 gated pattern (the recurring five — gradient, elevation shadow, glass/blur, oversized radius, dark theme — plus colored side-stripe borders and tinted shadows), "propose" does **not** mean "implement the gated form and write its authorizing `DESIGN.md` entry in the same change." That is self-authored justification, and self-authored justification is not legibility (gate question 6). Instead:

- **Implement the default (flat / solid / neutral) form now** — the form that needs no gate.
- **Surface the gated pattern as a labeled suggestion** carrying its six-gate justification (Purpose · Direction-fit · Systematic · Still-communicates-without-it · No a11y/hierarchy cost · Legible), for a human to ratify.

The gated form ships only after **(a)** a human ratifies the proposal, or **(b)** a **pre-existing** `DESIGN.md` override entry (resolved through `scan-exceptions.conf`) already authorizes it. Absence of a prior decision resolves as "no": ship the default, keep the pattern as a proposal. This restores the hard-ban's friction at the point of *shipping* while keeping the escape hatch at the point of *proposing* — good design surfaces as a reviewable proposal instead of being silently dropped, and the model cannot self-authorize the pattern into the code. (The review-side mirror of this resolution is in `impeccable-review/references/adjudication.md` → NEEDS INTENT.)

### Decision gates for the recurring five

The five patterns that most often show up unexamined. Each is legitimate through its gate; the questions below are how the reviewer (and the author) tell a decision from a reflex.

| Pattern | Passes the gate when… | Fails when… |
|---------|----------------------|-------------|
| **Gradient** (button/surface) | Documented in DESIGN.md: named surfaces, 2–3 stops within ~90° hue (or single-hue), one direction system-wide, hierarchy survives grayscale, no contrast interference. The one button gradient is the same-hue ≤5% lightness light-cue applied to *every* primary. | No DESIGN.md entry; per-element; two distant hues through gray; hierarchy leans on it; on chrome/text. |
| **Shadow** for elevation | Neutral (near-black), role-based from the `--elev` ramp, positive y-offset, spent only where the element floats/is tappable (elevation-by-role). | Brand-tinted or glow; offsetless `0 0`; on a static data card; eye-tuned per element. |
| **Glass / blur** | On native chrome that overlays *scrolling* content (nav/tab bar, sheet) — one place, justified by the overlay relationship. | On resting content cards/panels as a default surface treatment; more than the one justified instance. |
| **Oversized radius** (>16px) | A committed soft/playful **mobile** direction sets 20–24px as one named token, and every nested radius derives concentrically (inner = outer − gap). | Ad-hoc large radius; mixed radii; nesting that ignores the concentric rule. |
| **Dark theme** | A system feature paired with light, or a committed aesthetic direction in DESIGN.md; contrast re-checked on the dark surface; accents desaturated. | Dark-by-default "because it looks premium"; medium-grey body text failing AA; no light pair. |

### Visual

| Default-off pattern | Why | Fix (or the gate it must clear) |
|-----|-----|-----|
| **Gradient buttons / interactive elements** | Single most recognizable AI-design tell. Adds false depth with no meaning. | Flat solid color from the semantic color system. Exception: a same-hue vertical gradient of ≤ ~5% lightness on a primary button is a light-source cue (top lighter — see Shadows), not decoration. Commit it in DESIGN.md and apply it to every primary. |
| **Gradient text** | `background-clip: text` + gradient. Decorative, never meaningful. | Solid color — emphasize with weight or size instead |
| **Colored side-stripe borders** | `border-left/right` as a colored accent on cards, lists, callouts. Always a shortcut. | Full border, background tint, leading icon, or nothing |
| **Decorative accent border / stripe / top-bar** | A coloured top-bar, side-stripe, or accent border on a card or section that **encodes no data** — presumed decorative by default. Hierarchy and order are carried by structure, weight, or surface, not an applied accent. "The three phases each get a coloured bar" does **not** justify it: consistency is systematic decoration, and encoding only *position* (leftmost = phase 1) is not encoding meaning. Clears the gate only when the colour maps to a **real documented status/category** (not mere order) and is logged. If the colour comes from the semantic/index ramp, it is a Tier-1 semantic-palette leak, not this gate. | Carry order/hierarchy with structure, weight, spacing, or surface; drop the accent, or map it to a real status and log it |
| **Ghost-card pattern** | `border: 1px solid` AND `box-shadow` with blur ≥ 16px on the same element. Looks unresolved. | Pick one: solid border, OR shadow ≤ 8px blur |
| **Border radius ≥ 24px on cards / containers** | Ad-hoc oversized radius reads as AI default. The deeper tell is incoherence: mixed radii, or nesting that ignores geometry. | Cards top out at 16px by default. A soft/playful **mobile** aesthetic commitment may set 20–24px as the system value — one named token, committed in DESIGN.md (Habee-class apps do this). Every nested radius then follows the concentric-radius rule (see Border radius scale). |
| **Warm/cream/sand backgrounds as unmotivated default** | Token names like `--paper`, `--cream`, `--sand`, `--bone`, `--linen` are tells in themselves. The ban is on warm tints unrelated to the brand — not on warmth. | Derive the canvas from the brand hue at 2–5% saturation (see Choosing the canvas). A warm canvas is legitimate exactly when the brand is warm (Habee: yellow brand → warm neutral canvas) and it's committed in DESIGN.md. Saturation above ~8% reads as "cream paper" regardless of motivation. |
| **Purple gradient on white** | The single most clichéd AI color scheme. | Define a real color strategy before picking any gradient |
| **Glassmorphism as decoration** | Blurs and glass cards as default surface treatment. | Purposeful only — one element maximum, justified by context |
| **Generic feature-card template** | The icon-tile + heading + blurb card, ×3–6, is the universal AI template. The tell is the template — and screens mixing 4+ card treatments — not repetition itself. | Design one strong card primitive and repeat it consistently (repetition of a considered primitive is a signature, not a tell), or use a non-card pattern. Never the icon/heading/blurb template; never 4+ different card treatments on one screen. |
| **Nested cards** | Cards inside cards. No cost function for visual weight. | Flatten with spacing, typography, and dividers |
| **Card wrapping individual setting rows** | Each toggle or setting row gets its own card container. The card boundary implies "I am a distinct object" when the row is just a list item. Inflates visual weight with no semantic meaning. | One card container per settings section; rows inside it separated by dividers |
| **Unmotivated cards on homogeneous lists** | Repeating a heavy container around every same-type item can obscure grouping and inflate visual weight. | Start with rows/dividers for dense scanning; use cards when grouping, variable content, drag behaviour, selection, or the established product language gives the boundary a real job. |
| **Eyebrow text on every section** | Small all-caps tracked labels above every heading. AI editorial grammar. | One deliberate kicker as a system; otherwise remove |
| **Numbered section markers (01 / 02 / 03)** | Display numbers as section labels when content is not a true sequence. | Remove, or use real structural hierarchy |
| **Rounded-square icon tile above heading** | Small icon in a rounded-square container above a heading. The universal AI feature-card template. | Side-by-side icon + heading, or icon in flow without its own container |
| **Hand-drawn / sketchy SVG illustrations** | Crude hand-coded SVG scenes. Reads as amateurish. | Real assets or no illustration |
| **Decorative stripe / grid backgrounds** | Diagonal stripes or CSS grid overlays as texture. | Plain surface, product structure, or real assets |
| **Radial glow orbs / dark aurora background** | Radial gradients behind hero content. Learned as "premium dark mode" without purpose. | Plain dark surface, or a purposeful background image |
| **Neon / high-chroma palette on dark surface** | 5+ high-chroma accent colors on a dark background. Dribbble "modern SaaS" by reflex. | One saturated accent maximum; all others from the semantic role system |
| **Emoji as system / chrome icons** | Core UI elements (buttons, nav, notifications) use emoji. Chrome must stay visually distinct from content — when the content itself is emoji or emoji-labelled categories, emoji chrome destroys the distinction entirely. | SVG icon set throughout system chrome. Emoji in content and section labels is a legitimate JP consumer-app convention when it's a documented system (one emoji per category, logged in DESIGN.md) — never in buttons, nav, or notifications. |
| **Status dots on every item** | Colored dots on every list item with no semantic system. | Dots only where real status exists; use a label if the state isn't obvious from color |
| **Rainbow side tabs / multicolored card accents** | Multiple competing accent colors on adjacent card borders. No color budget. | One brand accent; semantic colors only (success/warning/error); never decorative |
| **Oversized italic serif hero headline** | A frequently repeated generic landing-page treatment when unrelated to the brand or content. | Set it roman, choose a product-specific display treatment, or document why it fits |
| **Image scale or rotate on hover** | Recurring AI-generated signature with no interaction meaning. | Let imagery sit still; use a color overlay or caption reveal if feedback is needed |
| **Generic fonts as the design choice** | A default system/grotesk—or a fashionable display face—used without a product-specific typographic reason. | Choose type for the product's register; a utilitarian system font may be correct when intentionally handled |
| **Translucent fills on resting content cards** | `rgba(255,255,255,0.7–0.9)` on cards/panels/rows over a tinted or gradient canvas never resolves to a clean surface; the colour varies across the card and separation reads as mush. Glassmorphism's quieter cousin — a top cheapness tell on light UI. | Opaque solid fill for all resting content surfaces. Reserve translucency + blur for native chrome that overlays scrolling content (nav/tab bars, sheets) — never content cards. |
| **Gradient or glow layer as the page/app background** | A `linear/radial-gradient` body background, or fixed "ambient" glow blobs behind content, is the light-mode twin of the banned dark-aurora orbs. Behind a card it destroys the value step. | One flat solid canvas colour. Separation comes from the surface system, not the background. |
| **Brand-tinted or coloured shadows for elevation** | Teal/purple-tinted `box-shadow`, or `glow` tokens used to lift elements, reads as decoration not depth — and at low opacity it's invisible, so nothing separates. | Neutral near-black shadow (`rgba(17,24,22,…)`). Glows are never an elevation tool. |
| **Pill badge directly above the hero H1** | The "✨ Now with AI" chip stacked over a centered headline — a near-universal slop marker. | Cut it, or fold the message into the headline or subhead |
| **Stat banner row** | 3–4 big numbers with labels in a horizontal band, used as decorative scaffold. | Only with real, sourced numbers the user cares about; otherwise remove |
| **Permanent dark theme as unmotivated default** | Dark-by-default used as atmosphere without product/platform rationale, often with weak secondary-text contrast. | Treat dark mode as a system feature or committed aesthetic direction, and verify every contrast relationship |
| **Centered-hero assembly** | Badge + centered H1 in a generic sans + two-button pair: the complete AI landing-page template, even when each part passes individually. | Break the assembly: asymmetric layout, product-first hero, or a real screenshot as the anchor |

### Motion

| Default-off pattern | Why | Fix (or the gate it must clear) |
|-----|-----|-----|
| **Bounce / elastic easing** | Spring physics on flat UI surfaces. Bounce is not a property of digital panels. | ease-out-quart/quint/expo. Reserve spring for physically simulated elements (drag, scroll-linked) |

### Copy

| Default-off pattern | Why | Fix (or the gate it must clear) |
|-----|-----|-----|
| **Marketing buzzwords in UI copy** | "Supercharge," "streamline," "empower," "enterprise-grade," "world-class," "next-generation," "game-changing" in buttons, headings, microcopy. | Specific verb + noun describing what the product literally does |
| **Em-dash overuse** | More than 2 em-dashes per text block is an AI cadence tell. | Use commas, colons, periods, or parentheses |

---

## AI-tell risk indicators

**Tier 3 — scrutiny, not failure.** These are *assemblies* — combinations of individually-defensible choices that, stacked, are the signature of a screen generated from defaults rather than designed. No single indicator is a finding on its own; a considered design can carry one deliberately. **The evidence is cumulative: weight rises as they co-occur.** One is a shrug; three on the same screen is a strong tell worth a direct conversation about whether any decision was actually made.

The reviewer treats these as a co-occurrence count, not a checklist of bans:

- **Centered-hero assembly** — badge + centered H1 in a generic sans + a two-button pair. Each part passes alone; together they are the complete AI landing-page template.
- **Icon-tile feature-card grid** — the rounded-square-icon + heading + blurb card, repeated ×3–6. The template is the tell, not the repetition.
- **Badge-above-H1** — the "✨ Now with AI" chip stacked over the headline.
- **Stat banner row** — 3–4 big numbers in a horizontal band used as decorative scaffold rather than real, sourced data.
- **Eyebrow-on-every-section** — small all-caps tracked labels above every heading (AI editorial grammar).
- **Numbered section markers** (01 / 02 / 03) where the content is not a true sequence.
- **Symmetry-everywhere** — every section centered, equal weight, no focal asymmetry.

**How to weigh it:** name the indicators you see and count them. One, with a plausible reason, is noted and passed. Two or more with no unifying rationale downgrade **Contextual fitness / Craft** and warrant the first-principles question: *was this designed, or assembled?* The fix is never "remove the gradient" — it's "break the assembly": introduce asymmetry, lead with the product, anchor on a real screenshot, cut the scaffold.

The individual patterns keep their detailed rows under [Design decision gates](#design-decision-gates) (each still has its own gate); this tier is about what their **combination** signals.

---

## Design standards

### Border radius scale

Define these tokens and use them consistently. Never exceed `--radius-lg` on cards or containers (unless the design system explicitly overrides with documented intent).

```
--radius-sm:   4–8px  → inputs, small chips, tooltips
--radius-md:   12px   → cards, panels, modals
--radius-lg:   16px   → large containers (max for cards by default)
--radius-pill: 999px  → tags, badge pills
```

Radius and spacing must feel related — tight spacing calls for smaller radius. Never mix large pill radius with standard rectangles in the same component without clear intent.

**Concentric radius rule.** When a rounded element sits inside a rounded container, the inner radius follows the geometry: `inner-radius = outer-radius − gap`. An image inside a 24px-radius card with 8px padding gets 16px radius. Equal inner and outer radii are what make AI-built cards look subtly "off". This rule also governs the playful-brand override: a 20–24px card system is fine only if every nested radius derives from it.

---

### Shadows

A shadow invisible at normal zoom isn't doing anything — remove it and use a border or background-color instead.

- Shadow purpose: separate layers, not add texture
- Test at 100% zoom in both light and dark contexts
- Ghost-card rule: border OR shadow — never both as decoration (see Design decision gates)
- Maximum blur for structural UI shadows: 16px. Wider = decorative, not structural.
- Dark mode: shadows need higher opacity to remain visible (multiply by ~2 vs light mode values)
- Shadows are neutral (near-black), never brand-tinted. A brand-coloured or glow shadow is decoration, not elevation — use the neutral elevation ramp (see Surface and elevation).

**Light comes from the sky.** All depth cues assume one overhead light source — this is the generative logic behind every shadow rule:

- Shadows sit **below** elements: the y-offset is positive and dominant over x. Soft shadows legitimately run blur at 3–4× the offset (our own ramp does; so does Material's). What's banned is the **offsetless glow** (`box-shadow: 0 0 Npx …`) — light doesn't radiate from inside a card.
- **Outset vs inset.** Raised elements (cards, buttons, popovers, sheets) get shadows below them. Carved elements (text inputs, wells, slider tracks, pressed states) are flat or subtly inset — never drop-shadowed.
- **Two-layer shadows read most naturally:** one tight contact shadow plus one soft diffuse, e.g. `0 1px 2px rgba(17,24,22,0.10), 0 4px 12px rgba(17,24,22,0.06)`. Prefer this form for `--elev-1/2` over a single wide blur.
- The one legitimate button gradient follows the same physics: a same-hue vertical gradient, top lighter, ≤ ~5% lightness (see Design decision gates).
- Higher surface = slightly lighter fill (Material 3 tonal logic). In dark mode this value shift — not the shadow — is the primary elevation cue.

---

### Surface and elevation

On light UI a card is read as a distinct plane through a **deliberate value step**, not through decoration. Get these four right and light-on-light looks professional; break any one and it looks cheap.

1. **Value step.** This section describes the **light-canvas strategy** (off-white canvas, near-white cards) — the default for product UI. Pure `#FFFFFF` cards are the specific move *of that strategy*, not a universal law: a tonal, dark, or drenched system defines its own surface relationships (cards sit *lighter* than the canvas in dark mode; a tinted system may key every surface to the brand hue). What's invariant is the *relationship* — a deliberate, small value step between canvas and card — not the literal white. On a light canvas: canvas is a slightly-off-white neutral; resting content cards are pure `#FFFFFF`. Aim for a background↔card contrast of ~1.05–1.12:1 — small but present. Shipped references measure: iOS grouped 1.09, HR payroll 1.086, McDonald's 1.071, Habee 1.052.
2. **Opaque surfaces.** Resting content cards are opaque. No `rgba` white fills, no backdrop-blur on content. (Blur/translucency is legitimate only for native chrome that overlays scrolling content — nav/tab bars, sheets.)
3. **Flat canvas.** The page background is one solid colour. No gradient, no ambient glow.
4. **Separation is one honest signal, matched to role (elevation-by-role).** A drop shadow reads as "this floats / can be pressed" — so it's a signal, not decoration. Spend it only where that's true:
   - **Static / data card** (roster, settings group, list container, read-only content): opaque fill + value step + a delicate ~1px hairline. **No drop shadow** — a shadow here makes a non-tappable card look tappable. This is the iOS grouped-list model.
   - **Interactive / floating** (a card that is itself tappable, popover, menu, tab bar): neutral shadow (`--elev-1/2`), no hairline.
   - **Overlay** (sheet, modal): neutral shadow (`--elev-3`).
   Never a glow, never a coloured shadow. This resolves the classic tension between "section separation too subtle" and "cards that aren't tappable look tappable."

**Elevation ramp** — a small neutral set tied to layer role, not eye-tuned per element:

    --elev-0   none                              static / data cards (separate via hairline + value step)
    --elev-1   0 1px 2px  rgba(17,24,22,0.06)    tappable cards, tab bar
    --elev-2   0 4px 12px rgba(17,24,22,0.08)    menus, popovers, key raised / interactive cards
    --elev-3   0 12px 32px rgba(17,24,22,0.12)   sheets, modals

Dark mode roughly doubles these opacities. Structural card shadows stay ≤ 16px blur; only the sheet/modal layer goes wider.

**The ramp is generative:** as elevation rises, blur and offset grow while opacity *falls*. Extending the ramp (an `--elev-4`) with rising opacity produces heavy, dark high-elevation shadows — the opposite of how distance from a surface reads.

**Z-index ramp.** Stacking order gets the same treatment as elevation: one token ramp tied to layer role — content < sticky chrome < dropdown/popover < sheet/modal < toast. No literal z-index values in components; `z-index: 9999` (and the arms race it starts) is a ban.

**Choosing the canvas — decision procedure.** Never pick the canvas in isolation; derive it:

1. Start from the brand hue. Desaturate to 2–5% saturation, lightness 96–98% (HSL). Zero-chroma gray is the fallback, not the goal — a dead-gray canvas under a colourful brand feels disconnected. Saturate neutrals toward the brand hue, including text inks (never dead black: near-black ink carries a trace of the brand hue).
2. Cards are pure `#FFFFFF`, opaque. Verify the value step lands at 1.05–1.12:1.
3. Derive the hairline border and muted text from the same hue family — build **one tinted-neutral ramp (~9 steps)** and pick canvas, border, muted text, and ink from it. One ramp = automatic coherence between canvas, borders, and shadows. This is the highest-leverage fix for "canvas, borders, and shading never quite match."
4. Test: a white card on the canvas at 100% zoom. Card boundary invisible → darken the canvas one ramp step. Canvas reads as a colour rather than off-white → desaturate.

**Separation toolkit — ordering.** To separate any two elements, try in this order and stop at the first that works:

1. Whitespace alone
2. A background value step
3. A hairline divider (not a full box)
4. A bordered or shadowed container

Reaching for a bordered box first is the amateur move — most separation problems are solved by space (fewer boxes, fewer borders, more whitespace). By the time you reach step 4, elevation-by-role (above) decides border vs shadow.

**Dark mode as a system** (when committed): invert the ramp — cards sit *lighter* than the canvas (elevation = lighter fill, the Material tonal model), shadows double in opacity but do less of the work. Desaturate the brand accent slightly (full-chroma accents vibrate on dark) and check every contrast pair again — muted text that passed on light usually fails on dark. Dark mode is a second surface system derived from the same ramp, not a colour swap.

---

### Gradients — when and how

Gradients are off by default on chrome, buttons (except the same-hue light cue), text, and the app canvas — each is available only through the Tier-2 gate. When a gradient is legitimate — brand/hero/drenched surfaces, data viz, illustration, logomark — craft rules apply:

- **2–3 colour stops.** Two distant hues interpolate through gray in the middle — add a mid-stop along the colour-wheel path between them.
- Keep stops within ~90° of hue, or use one hue varying only lightness/saturation (the safest form, and what professional "subtle gradient" work actually is).
- **A coherent direction model** — keep one direction within a surface family or lighting model;
  a brand system may intentionally define different directions for distinct roles when documented.
- The design must survive grayscale: hierarchy may never depend on the gradient.
- Log it in DESIGN.md: which surfaces, which stops, which angle. A system decision, not a per-element effect.

---

### Text on imagery

Raw text or badges on an untreated photo is banned — it fails the moment the image changes. Pick one method and systematize it:

| Method | Use |
|--------|-----|
| **Dark overlay** — 30–40% black over the whole image | Hero images, thumbnails with titles |
| **Text-in-a-pill/box** — solid or high-opacity fill behind the text | Badges and counts on photo cards |
| **Floor fade** — transparent → ~20% black gradient at the bottom, text at the bottom | Card imagery with captions; dark side down, consistent with overhead light |
| **Blur + darken region** | Native-style chrome over media |
| **Scrim** — elliptical translucent-black behind the text block | Subtle single-title overlays |

White text is the default on all of these. Test with every image the slot can receive, not just the demo image.

---

### Icon system

- **One icon family** per product (SF Symbols / Material Symbols / Lucide / Phosphor — pick one), one stroke weight, sizes snapped to 16/20/24.
- Outline = inactive, filled = active is a legitimate two-state system for tab bars and toggles. Mixing families or stroke weights on one screen is an instant amateur tell.
- Icons align optically with adjacent text: match cap height, sit on the baseline grid.
- Emoji never in chrome (see Design decision gates). Where the product's own emoji or iconography IS the content, chrome must be visually distinct from it.

---

### Optical alignment

When geometry and perception disagree, perception wins — nudge, and document the nudge.

**Shared-axis and gutter audit.** Before polishing, trace the major vertical axes through the whole
screen: viewport/page gutter, section headings, card/list content, form labels and fields, and
repeated rows. Elements intended to share an axis use the same token-derived inset. A 2–8px drift
between nominally aligned left edges is rarely expressive; it usually exposes nested padding or an
off-scale margin. Preserve deliberate indentation for hierarchy and documented ±1–2px optical
compensation, but do not confuse either with accidental gutter drift. Re-run the audit at narrow and
wide breakpoints because container nesting often changes there.

- A play triangle centered geometrically in a circle looks off-center: shift it right ~4–8% of the diameter.
- Text in a button centers on **cap height**, not the bounding box — geometric centering sits text visibly high or low depending on the font's metrics.
- A button with a leading icon needs slightly less padding on the icon side; icons carry less visual mass than glyphs.
- Large display type hangs its left edge slightly past the container edge — glyph side-bearings otherwise create a visual indent.
- These nudges are the sanctioned grid breaks (see Spacing system): ±1–2px, on a specific element, annotated.

---

### List and card patterns

**The test: is this a homogeneous list of same-type items?**

If yes → plain list rows with dividers, regardless of whether items are tappable. If no → consider cards.

This is consistent with Material Design and iOS HIG:

| Pattern | When | Example |
|---------|------|---------|
| **Plain list rows** | Homogeneous data — every item has the same structure | Members, chats, contacts, transactions, notifications |
| **Grouped card container** | A section of rows that belong together semantically | Settings section with title + 3 related toggles inside one card |
| **Individual cards** | Items with structurally variable or rich content — each item meaningfully differs in shape | Social posts (photo + caption + reactions + CTA vary per item) |

**Tappability is not the test.** Every chat list, contact list, and member list is tappable. WhatsApp, LINE, iMessage all use plain rows — not because the items aren't interactive, but because they're uniform in structure.

**Settings screens specifically:**
- Correct: one card container per section group, divider-separated rows inside
- Wrong: each individual toggle or nav row wrapped in its own card

**When cards on a list are legitimate:** each item shows substantively different content (one has an image, another a chart, another a long description). The variable structure is what the card boundary communicates — "parse this item on its own terms." Uniform items don't need that signal.

**One primitive ≠ uniform prominence.** Repeating one card primitive is a signature; giving every instance equal size, position, and emphasis is a hierarchy failure ("everything looks the same, I don't know where to look"). Vary prominence *within* the primitive system — the key metric gets the large variant or the top slot; secondary data gets the compact variant. Order, size, and emphasis carry priority; the primitive carries consistency.

For the whole-screen ranking procedure, settings/action-dense pages, squint test, and grayscale
verification, see **Page-level visual hierarchy**. This section owns the list/card primitive;
that section owns how its instances participate in the page's reading order.

---

### Color — semantic roles

Every color in the UI must map to one of these roles. No ad-hoc values.

| Role | Usage |
|------|-------|
| `--color-primary` | Main interactive action — CTAs, key buttons |
| `--color-secondary` | Supporting actions, alternative buttons |
| `--color-destructive` | Delete, remove, sign out, irreversible actions |
| `--color-success` | Confirmation, completion, positive state |
| `--color-warning` | Caution, pending, needs attention |
| `--color-error` | Failure, validation error, blocking state |
| `--color-info` | Neutral informational state |
| `--color-surface` | Card/panel backgrounds |
| `--color-border` | Dividers, input borders |
| `--color-muted` | Secondary text, placeholders |

Product-specific semantic roles (category colors in data viz, emotion states in a mood app) can extend this list — document them alongside these.

**Selection ≠ action.** Selected state and primary action must remain distinguishable in context.
They may share a brand hue when component shape, placement, label, border, weight, or indicator
keeps their meanings clear. Do not invent a new dark fill or checkmark merely to force numeric
distance; use the smallest established channel that removes actual ambiguity.

**A state treatment lives in one token; sibling surfaces move together.** Selected, active, and error states must be owned by a shared token (fill, border, label) that every surface reads — tabs, sub-tabs, tiles, list rows showing the same state must look identical because they resolve the same token. Two consequences the reviewer must enforce:
- **Fix the token, not the instance.** If a shared state token is broken or retired (e.g. a `selected-border` set to `transparent`), the fix belongs in the token so all consumers update at once. Hand-patching one surface — giving *one* tab a visible teal border because the shared token gives none — forks the pattern and leaves its siblings behind. That local override is itself a finding, not a fix.
- **After any state-style change, audit the siblings.** Changing a selected/active style on one component obligates you to grep for every other surface rendering that state and confirm they still match. Divergence between two surfaces that share a state (a `入力` tab styled one way, its `つながり` sub-tab another) is a coherence failure even when each looks fine alone.

**A state has more channels than colour — evaluate and design across all of them.** When you assess or build any differentiated state (selected, active, hover, pressed, error, disabled), do not reduce it to a fill/contrast question. Enumerate which channels actually carry the state from the full set: **value/fill, border, weight, size, elevation/shadow, scale-lift, position/indicator (underline/dot), and iconography (check)** — then filter that set by what the design language permits (a flat, opaque, neutral-elevation system rules elevation/coloured-shadow *out* as a selection channel; a layered system may use it). Two review obligations follow:
- **Report the channel inventory, not just the contrast number.** "The active tab is 3.3:1" is half a finding; "the active state is carried by hue alone — the border, weight, and fill value-step are doing no work" is the finding. A state that passes contrast can still be a fault if colour is the sole channel, and a faint fill is fine when a border, weight step, or lift genuinely carries it.
- **Don't fix a state by adjusting colour alone.** If a selected state is weak, the first moves are usually a committed border, a value-step deepening, or a weight change — not nudging the hue. Reach for the channel the design language actually allows before touching colour.

**Single-select vs multi-select — the second channel differs; don't demand a mark unless the
render needs one.** The "colour is never the only signal" rule is satisfied differently by the
two selection models:
- **Multi-select** (emotion tiles, filter chips, any independently toggled set) — every selected
  item must remain independently identifiable, but the second channel may be border, shape,
  weight, label, scale, or a mark. A check is useful when other established channels remain faint
  or ambiguous; it is not a universal requirement and should not be added when it has no product
  meaning or precedent.
- **Single-select** (segmented controls, tab bars, radio-style pickers — exactly one item active, choosing one deselects the rest) — the differentiator is the *contrast between the one active item and its inactive siblings*, carried by **fill + border + weight + position/underline**. A per-item check is **not** required; the active item reading differently from its neighbours (and not reading as the CTA — Selection ≠ action still applies) is the whole requirement. Do not flag a tab or segment for lacking an ink check; flag it only if the active state is carried by hue alone with no fill/border/weight/position difference.

**A treatment's precedent context is part of its meaning.** Reusing a heavy/dark fill outside its
established surface triggers a compatibility check, not an automatic finding. Compare all related
instances and ask whether the new surface shares the same role and register. If it creates visible
hierarchy or semantic inconsistency, recommend the smallest established alternative; otherwise
record it as a coherent extension. A valid token is necessary but not sufficient, and a novel use
is not automatically wrong.

---

### Color strategy

Before picking colors, commit to a strategy. Restrained is the safe default for product UI; committed or drenched for brand/campaign surfaces.

| Strategy | Description | When |
|----------|-------------|------|
| **Restrained** | Tinted neutrals + one accent ≤ 10% of surface | Product UI default |
| **Committed** | One saturated color carries 30–60% of surface | Brand-driven pages |
| **Full palette** | 3–4 named roles, each used deliberately | Campaigns, data viz |
| **Drenched** | The surface IS the color | Hero moments, campaign pages |

Strategy may also be assigned **per surface role** within one app, documented once: e.g. drenched onboarding/hero/player screens + restrained content screens — the standard pattern in polished consumer apps. What's banned is per-screen improvisation, not per-role assignment.

**60/30/10 proportion check.** Use this as a rough diagnostic for restrained colour strategies,
not a universal ratio or pass/fail threshold. Judge whether accent still preserves hierarchy and
semantic meaning; brand-led, data-rich, and drenched surfaces may use different documented budgets.

**Palette permission — every visible hue needs a reason to exist.** Build the palette outward from
the brand anchor instead of collecting attractive colours independently. A hue is allowed only when
it has one of four jobs: **brand/action**, **brand-derived support**, **semantic state**, or
**data/category distinction**. Brand-derived support should be visibly related to the anchor through
hue proximity, shared undertone, or a documented complementary/analogous scheme. Semantic colours
may leave the brand family because red, amber, and green carry learned meanings, but reserve them for
those meanings; do not use error red or success green decoratively. Data colours may be broader, but
belong to a named chart palette and must not leak into ordinary chrome.

An unrelated accent is not made coherent merely by turning it into a token. For example, a dark-teal
brand does not acquire purple buttons, badges, and illustrations by default. Purple earns a place
only through an approved supporting palette or a specific semantic/category role, and its temperature
and chroma must be tuned to the teal system. Otherwise derive the supporting colour from teal and its
tinted-neutral ramp. Test the palette in context, at approximate usage proportions, and in grayscale;
swatches viewed separately hide competition and hierarchy failures.

**Colour separation is relational, not a token-name check.** Compare adjacent surfaces at their
rendered size. A light-teal tile on a light-teal canvas may be technically different yet visually
collapse. If two neighbouring planes do not separate, change the permitted channel in this order:
whitespace, value/lightness step, hairline, then elevation when the role truly floats. Do not solve a
value-collapse problem by adding another hue, more saturation, or a glow.

---

### Page-level visual hierarchy

Professional coherence is **family resemblance plus role distinction**. Components that do the same
job share geometry, typography, states, and token logic; components with different importance do not
receive equal visual weight merely because they are all buttons, cards, or tiles.

Before polishing a screen, make a hierarchy inventory:

1. Name the screen's primary job and the one action that advances it.
2. Rank every visible action as **primary, secondary, tertiary/inline, navigation, destructive, or
   system/status**. Rank content as **page identity, section identity, primary content, supporting
   content, or metadata**.
3. Assign emphasis channels deliberately: position and whitespace first; then size/weight; then
   value/colour; border/elevation last. Do not turn every channel up on the same element unless it is
   genuinely the page's dominant moment.
4. Squint-test or blur the render. The primary job and first reading path should remain obvious;
   repeated controls should recede into groups rather than form a field of competing accents.
5. Remove colour and re-check. If hierarchy disappears in grayscale, colour is compensating for
   weak structure.

**Settings and action-dense pages.** Buttons should share a component family, not one identical
appearance. Routine row actions are usually navigation affordances, toggles, inline text/ghost
actions, or a trailing chevron—not repeated filled CTAs. A page-level Save/Apply may be the single
primary action for the edited region. Destructive account actions sit in a separated danger zone and
use destructive styling at the point of commitment; they do not compete with Save throughout the
page. Repetition lowers prominence: an action shown in every row should usually be quieter than a
one-off decision action.

**Hierarchy is a budget.** On a typical product screen, allow one dominant element in a visual field,
a small number of supporting emphases, and keep the remainder neutral. When everything is filled,
bordered, shadowed, saturated, large, or bold, no hierarchy remains. Consistency means the same role
resolves the same way; it does not mean every interactive element looks equally important.

This section is the page-level procedure. **Information hierarchy** owns the frequency/prominence
principle; **Cognitive load and interaction density** owns choice grouping and one-job-per-screen;
**List and card patterns** owns primitive selection. Apply them through this inventory rather than
restating their local rules in new sections.

---

### Data visualization

Charts and stats follow the same system as the rest of the UI — a chart is not a licence for new colours.

- **Colours come from the token system:** category colours are documented product-semantic roles; state colours (success/warning/error) mean the same thing in a chart as in a form. Never a rainbow default palette.
- **One data series → the brand accent on neutral.** Multi-series → documented category colours, distinguishable without a legend and colour-blind-safe (pair colour with shape, position, or a direct label).
- **Gridlines are hairline-weight** on the neutral ramp — never darker than the data. Drop them entirely if the values are labelled directly.
- **Direct labels beat legends** where space allows; legends force the eye to ping-pong.
- **No 3D, no gradient fills, no drop shadows on chart elements.** A soft single-hue area fill under a line (fading to transparent) is the one legitimate chart gradient.
- Axis numbers use `tabular-nums`; abbreviate consistently (1.2k, 3.4M).
- Charts have loading, empty, and single-datapoint states like any other component.
- **Hover is not an affordance on touch.** If chart elements are tappable (a bar opens a detail), the affordance must be visible at rest — hover/tooltip reveals only enhance. Anything discoverable only by hovering does not exist on mobile.

---

### Imagery and avatars

- **Fixed aspect ratio per slot.** Every image slot (card cover, hero, thumbnail) declares one ratio and crops to it (`object-fit: cover`) — never stretch, squash, or letterbox user content. Mixed ratios in one grid is an instant amateur tell.
- **Image radius follows the concentric rule** (inner = outer − gap) when inside a card; standalone images use the system radius.
- **Avatars: one shape, 2–3 sizes.** Pick circle or squircle once, define sm/md/lg sizes on the icon/spacing scale, and never mix shapes. Placeholder = initials or a brand mark on a neutral-ramp fill — not a gray silhouette default, not an emoji.
- **Placeholder/broken states designed:** loading skeleton matches the slot's exact ratio (no layout shift); failed loads show a neutral fill, never a broken-image glyph.
- Text or badges over any image → see Text on imagery.

---

### Typography

**Hierarchy first — sizes must contrast.** Font size steps should have a ratio of at least 1.25× **at display/heading levels above body**. If h1 is 32px, h2 should be ≥ 25px. Clustering sizes near each other (28/26/24) is a flat scale, not a hierarchy. In dense product UI, adjacent levels in the 13–17px band may legitimately be separated by weight and colour instead of size (Apple's own text styles do this) — the floor applies where size is the differentiator, not as a universal law. (The token-graph validator enforces a hard ≥1.15× *distinct-level* floor — below that two steps read as one level and it flags; the 1.25× here is the display-tier *target*, above the validator's floor. Target and floor are deliberately different numbers.)

**Emphasis has three axes — size, weight, colour.** Prefer weight shifts and ink-vs-muted colour steps before size jumps; size alone is the blunt instrument. Combine competing axes deliberately: large numerals in a light weight; tiny labels bold/caps/tracked. Only page titles get all-out emphasis (big AND bold AND dark). A big stat pairs with a small muted unit ("2,158 **steps**" — the number gets size, the unit gets colour), never equal weight. Use `font-variant-numeric: tabular-nums` on any number that updates or aligns in columns.

**Display letter-spacing floor:** ≥ -0.04em. Tighter and letters begin to touch. (Latin only — see Japanese/CJK in Platform notes.)

**Body letter-spacing ceiling:** ≤ 0.05em. Wide tracking on body text disrupts natural character groupings. Reserve tracked-out uppercase for short labels (4–6 words max).

**Body line length:** 65–75ch. Beyond 75ch reading becomes tiring; below 45ch the eye never settles into flow.

**Line height is inversely proportional to size:** body 1.5–1.7×, subheads ~1.3×, display/h1 1.1–1.25×. A multi-line headline at body line-height is visibly gappy — an every-screen amateur tell. Below 1.3× on body feels cramped.

**Body minimum size:** 14px for dense product UI, 16px preferred for reading-focused interfaces. Below 12px is inaccessible.

**Font pairing:** Pair on a contrast axis — serif + sans, geometric + humanist. Don't pair two similar sans-serifs (Inter + DM Sans is not a pairing, it's two defaults).

**Font selection precedence for CJK/JP (and any non-Latin script): coverage → legibility → performance → distinctiveness.** "Pick a distinctive display face" is a Latin-first heuristic and is *outranked* by script needs. A distinctive display font that lacks full kana/kanji coverage, renders JP at poor legibility, or ships megabytes of glyphs is the wrong choice even though it would win on a Latin landing page. For JP, prefer a well-hinted system or Noto-class family with the required weights that actually exist (see Japanese/CJK) over a "characterful" face that fails coverage — the considered choice there is legibility and correct rendering, not novelty.

**Font count is a register decision.** Brand UI (landing pages, campaigns) expects a considered display face paired with a refined body font. Product UI (apps, dashboards, tools) may legitimately use a **single well-set family** — iOS, Linear, and Stripe's dashboard all do — with the design energy going into the weight/size/colour system instead. What's never a decision: accepting the framework default font without choosing it, or reflexively bolting a decorative display font onto a dashboard (the forced "serif display + Inter body" pairing is itself becoming a tell).

**Display size follows available measure and hierarchy.** Short headlines often tolerate larger
type, but there is no universal word-count limit. Test the actual copy, language, viewport, wrap,
and fold; reduce size or edit copy only when the rendered hierarchy or line breaks fail.

**Avoid all-caps on long passages.** Word recognition relies on shape (ascenders and descenders). Reserve all-caps for short labels (1–4 words).

**Avoid justified text.** Without hyphenation, justified text creates uneven word spacing. Use `text-align: left` for body text.

**Text wrap:** Use `text-wrap: balance` on h1–h3; `text-wrap: pretty` on prose.

---

### Color contrast

- Body text: ≥ 4.5:1 against background (WCAG AA)
- Large text: ≥ 3:1 — but WCAG "large" means **18pt/24px regular or 14pt/≈18.5px bold**. Text at 16–23px regular is NOT large text and needs the full 4.5:1. (A common units error is reading the thresholds as px.)
- WCAG exemptions — do not flag: disabled controls, placeholder text used purely as a format hint, and logotypes are exempt from contrast minimums. A properly-muted disabled state is correct, not a violation.
- Interactive element indicators (focus rings, active state borders): ≥ 3:1
- **Non-text component contrast (WCAG 2.1 SC 1.4.11) — scoped to *interactive* elements.** The 3:1 boundary requirement applies to interactive components and their states (inputs, toggles, buttons, selectable tiles, tappable rows, focus/selected indicators). A purely decorative grouping card (roster, settings container, read-only data card) is not an interactive component and is not required to hit 3:1 — it may separate with the value step + a delicate hairline (~1.2:1, iOS-style). This is the correct reading of 1.4.11; the over-broad "every card must hit 3:1" version forces a darker background and makes cards look cheap. Translucent fills still fail: the fill never resolves and the step collapses.
- Most common failure: muted gray on tinted near-white. Move toward the ink end of the ramp.
- **Gray text on colored background:** A gray that passes on white will fail on a colored surface. Use a darker shade of the background hue, not generic gray.
- **Count badges / small labels on an accent fill.** Small text needs 4.5:1. Measure the actual
  foreground/background pair; do not infer failure from hue. Tint-fill + ink is a reliable option,
  and a darker brand accent is equally valid when the measured pair passes and still fits the
  approved palette.

---

### Tap targets

- iOS minimum: 44 × 44pt
- Android minimum: 48 × 48dp
- Web: 24 × 24 CSS px at WCAG 2.5.8 AA, including its spacing exception; 44 × 44px is an
  enhanced target for primary and touch-heavy controls, not a universal AA failure threshold.
- If the visible element is smaller, add transparent padding to meet the minimum — grow the *hit area*, not the visible box. Inflating the visible control's height alone (e.g. `minHeight` 34→44) while leaving its horizontal padding fixed squishes a short-label control into a tall, narrow pill. Prefer transparent hit-area padding that leaves the resting shape untouched.
- Prefer generous separation between adjacent targets; on web, assess the actual WCAG spacing
  exception rather than imposing a universal 8px rule.
- **Bottom safe zone (native).** Interactive elements must clear the bottom safe-area inset — the iOS home-indicator strip and the Android gesture-nav zone. Pad the bottom bar / pinned CTA by the safe-area inset (`env(safe-area-inset-bottom)` or the platform equivalent); never let a tappable control sit flush against the very bottom edge, where accidental taps and the system gesture overlap. This is a native concern — a web layout with a footer link at the page bottom is fine; a native screen with a CTA jammed into the home-indicator zone is not.
- Applies to: all buttons, toggles, links, icons used as interactive elements, form checkboxes and radios.
- **No functionality reachable only via hover — on any element.** Hover may enhance (highlight, preview, tooltip) but never gate: hover-revealed row actions, hover-only delete buttons, and tooltips as a control's only label all fail on touch. (This generalizes the chart-affordance rule.)

**Stacked bottom-of-screen actions (native mobile):**  
The bottom of the screen is where the thumb naturally rests and applies the most pressure. Stacking a secondary link or text action directly below a primary button in this zone causes accidental taps and makes the secondary action hard to hit deliberately.
- Minimum 24pt vertical gap between a primary CTA button and any secondary link/action below it.
- Low-frequency secondary actions (e.g. "skip", "maybe later", "cancel") should be placed above the primary CTA, or use a ghost/text button with enough spacing — not a small link underneath.
- If both actions must sit at the bottom, use a stacked button layout with equal touch targets rather than button + small link.

---

### Accessible semantics and keyboard

Contrast and tap targets alone don't make a UI accessible — names and keyboard behaviour do, and both are mechanically checkable.

- **Every icon-only interactive element has an `aria-label`.** An unlabelled icon button doesn't exist for a screen reader.
- **Interactive elements are real elements:** `<button>` and `<a>`, never clickable `<div>`/`<span>`. Real elements bring focus, keyboard activation, and semantics for free; fake ones bring bugs.
- **Heading levels descend without skipping** (h1 → h2 → h3). Headings are the screen-reader's table of contents, not font-size shortcuts.
- **Modals and sheets manage focus:** focus moves in on open, is trapped inside, `Esc` closes, and focus returns to the trigger on close. A modal without a focus trap strands keyboard users behind an invisible wall.
- **Enter submits** a focused single-field form.
- Focus-visible rings on every interactive element (web) — already required under Platform notes; restated here because it belongs to this contract.

---

### Responsive and adaptive layout (web)

One desktop layout that "reflows by accident" is not a responsive design. Adaptation is designed:

- **2–3 breakpoints maximum** (e.g. <640 / 640–1024 / >1024), committed as tokens in DESIGN.md. More breakpoints = eye-tuned chaos.
- **Every screen has a designed narrow variant.** Multi-column grids collapse in a declared order; side-by-side buttons stack with the primary on top; navigation transforms deliberately (rail → bottom bar / drawer).
- **Tables need a designed narrow strategy.** Card/row conversion works when records can be
  understood independently. A labelled horizontal-scrolling region is valid for wide comparative
  data when preserving column relationships matters; avoid accidental page-level body scroll.
- **Test every screen at 360px and 1440px** before shipping. Both extremes must look intended, not survived.
- Touch targets and type sizes never shrink below their minimums to fit a breakpoint — layout adapts, standards don't.

---

### Data tables

Dashboards are mostly tables, and agents default to bordered-everything, center-aligned grids. The professional defaults:

- **Text left-aligned; numbers right-aligned** with `tabular-nums`, so magnitudes line up.
- **Headers muted** — weight *or* colour, not both — and aligned with their column's content.
- Start with restrained row separation. Hairlines are a strong default; zebra striping can improve
  tracking across very wide or dense rows when tested, and vertical rules are appropriate only
  where column grouping would otherwise be ambiguous.
- Row height ≥ 44px when rows are tappable; the whole row is the target.
- Sortable columns show the affordance at rest (not on hover); the active sort direction is always visible.
- Sticky header when the table scrolls; first column sticky if horizontal scroll is unavoidable on wide data.
- Empty, loading (skeleton rows), and single-row states designed like any component.

---

### Button rules

**Hierarchy: one dominant action per decision context.** The rule is scoped to a *decision context*, not literally one button per rendered screen — a screen with genuinely separate regions (a toolbar action plus a distinct content CTA, a multi-section settings page) may carry one dominant action *per region* as long as they don't compete in the same visual field. What's banned is two co-equal primaries fighting for the same glance. Everything else is secondary or ghost.

| Variant | Use | Appearance |
|---------|-----|------------|
| **Primary** | The main action on the screen | Solid fill, `--color-primary` |
| **Secondary** | Supporting or alternative action | Outlined, or lower-contrast fill |
| **Ghost / text** | Low-priority or inline actions | No border, no fill — text only |
| **Destructive** | Irreversible actions | `--color-destructive`; require a confirmation step **only if irreversible** — see undo-vs-confirm below |
| **Link** | Navigation, not an action | Inline text only |

**All five button states are required:**

| State | Requirement |
|-------|-------------|
| Default | Resting appearance |
| Hover | Perceptible color shift (not just cursor change) |
| Active / pressed | Perceptible depression or darkening |
| Disabled | Reduced opacity or muted color. Use the `disabled` attribute when the control must be fully inert. Use `aria-disabled` + a click guard only when the control should stay focusable so its "why disabled" explanation is discoverable — `aria-disabled` alone does NOT prevent activation. |
| Loading | Spinner or skeleton inside the button; label persists or becomes "Loading…" |

**Sizing:**
- Minimum height: 36px (compact), 44px (standard), 52px (large/mobile primary)
- Minimum width: 80px; don't collapse below the label
- Padding: ≥ 12px horizontal for text labels
- **Height and horizontal padding scale together.** When you raise a control's height (e.g. to clear the tap-target minimum), scale its horizontal padding with it — otherwise a short 1–2-character label (承認, OK, ✕) sits in a tall, narrow box and the pill reads as a squished near-circle. Preferred fix is transparent hit-area padding that leaves the visible pill alone (see Tap targets); if you *do* enlarge the visible pill, hold roughly its resting height-to-padding ratio so the resting shape survives. Re-check short-label controls in the render after any height change.

**If a button is disabled, explain why.** A tooltip or adjacent text states the condition not met.

**Undo beats confirm for reversible actions.** Confirm only what's irreversible (permanent delete, send, payment). For reversible actions (archive, remove item, dismiss), act immediately and offer undo — a toast with an Undo action, ~5s. Confirmation dialogs on reversible actions train users to click through them, which destroys the protection exactly where it matters.

**The primary CTA stays reachable.** On mobile, the screen's primary action must remain visible or pinned as content expands — optional sections, revealed inputs, and long lists must not push it below the fold. If content grows, pin the CTA or collapse the growth, don't bury the action.

**Pressed states are not just for buttons.** On native, every tappable row, card, and list item needs touch-down feedback (background highlight or slight opacity dip, matching platform convention). A tappable row with no pressed state is a "web dev built this" tell in a native app.

**Do not:** run two co-equal primary buttons in the same decision context (one dominant action per context — see the hierarchy rule above); use *unmotivated* gradient fills on buttons (the committed same-hue light cue is the one gated exception); use emoji as button labels; stack buttons vertically on desktop unless the viewport is narrow.

---

### Form and input rules

**Labels remain available.** Placeholder-only data-entry fields lose context on focus or after
entry, so visible labels are the default for forms. Compact search/filter fields may use a
persistent accessible name plus stable surrounding context when a visible label would add no
information. Test before, during, and after entry—not only at rest.

**Placeholder text role:** Format hints only (e.g. "DD/MM/YYYY"). Never the field label.

**Input sizing:**
- Minimum height: 40px (web), 44pt (iOS), 48dp (Android)
- Width should match the expected input length — short code gets a short field, address gets a wider field

**Validation timing — reward early, punish late:**
- First pass: validate on blur (leaving the field), not on keypress
- Once a field is in an error state, re-validate on **every keystroke** so the error clears the instant it's fixed — "not on keypress" applies only before the first error
- Live-from-the-start validation is legitimate where feedback is the feature: password strength meters, username availability

**Prefer enabled-submit over disabled-submit.** For forms, the stronger pattern is keeping the submit button enabled and surfacing validation on press (focus jumps to the first error) — a disabled submit with no reachable explanation is a dead end for screen-reader and cognitively-loaded users. Reserve disabled-with-explanation for genuinely unavailable actions.

**Error placement and content:**
- Inline: below the field, not in a toast
- Name what's wrong and how to fix it. "Invalid email" is insufficient; "Enter a valid email address, e.g. name@example.com" is correct
- Color alone is not enough — pair error color with an icon and a text message

**Field grouping:**
- Group related fields visually (shipping address as a block)
- Use spatial proximity and light dividers to communicate grouping

**Required vs optional:**
- Mark only the minority ("Optional" if most are required; * if most are optional)
- Don't mark both

---

### Spacing system

Use an 8pt grid. All spacing values are multiples of 8 (or 4 for fine-grained internal spacing).

```
--space-1:   4px   → icon-to-label gap, tight internal
--space-2:   8px   → compact internal padding, adjacent element gap
--space-3:  12px   → standard internal padding for small components
--space-4:  16px   → standard element spacing, default component padding
--space-5:  24px   → component separation
--space-6:  32px   → section internal spacing
--space-7:  48px   → between sections
--space-8:  64px   → major section breaks, hero padding
--space-9:  96px   → page-level vertical rhythm
```

**Spacing must have rhythm — not uniformity.** Related items use tight spacing; unrelated sections use generous spacing. If every element has the same margin, the eye has no grouping signal.

**Monotonous spacing is an AI tell.** The same padding value everywhere signals no rhythm was set.

**Text never touches an edge.** ≥ 8px (ideally 12–16) of padding inside any bordered or filled container; ≥ 16px horizontal between body text and the viewport edge.

**Sanctioned grid breaks.** Off-grid values are legitimate only as *documented optical compensation* on a specific element — ±1–2px to align baselines or balance asymmetric glyphs, 1px hairlines, 2px gaps inside segmented controls. Never as layout spacing. Reviewers: flag off-grid layout spacing, not annotated optical nudges.

---

### Edge cases and states

Every screen that can be in a non-default state must have that state designed and implemented. AI generates only the happy path — absent states are an instant tell. (See also: Quality requirements above.)

| State | Requirement |
|-------|-------------|
| **Loading** | Skeleton screens preferred over spinners for content areas; spinners acceptable for action feedback. Timing: delay indicators ~300ms (fast operations show nothing); once shown, keep visible ≥ 500ms (no flicker). Skeletons match the exact size of the content they replace — zero layout shift on resolve. |
| **Empty / zero-data** | Distinguish **first-use**, **user-cleared**, and **no-results** because they need different explanations/actions. Use only the content necessary to orient the user; an illustration is optional and must fit the established product language. Applying one generic template to all three is the defect. |
| **Error** | Distinguish network errors from data errors from permission errors — each needs different copy and a recovery action |
| **Partial data** | What does the screen look like with 1 item? With 100? With a very long name? |
| **Role / permission variants** | Every screen seen by more than one role (owner/member, creator/joined, admin/user) needs each variant designed. AI generates the author's perspective only — the same failure class as a missing empty state. |

**Prototype hygiene.** Demo, reviewer, and dev controls never render on the product surface — a first-time user will try to parse a leaked state-toggle as a feature. Gate them behind a build flag or hidden gesture. Any non-persisted demo state (reactions, drafts that won't save) carries a visible "won't be saved" cue.

---

### Copy hygiene

**Em-dash overuse** (more than 2 in a single UI text block) is an AI cadence tell. Use commas, colons, periods, or parentheses.

**Marketing buzzwords** are banned in microcopy (see Design decision gates). Specific verb + noun instead.

**Aphoristic contrast cadence.** Sections that land on a short rebuttal ("Not a feature. A platform.") read as AI copy. Once may be intentional; repeated is a tell. Dismissing something as "theater" ("we killed the growth theater") is the same generated-copy tic — say plainly what the thing does or does not do.

**Redundant labels.** If the visual already communicates it, the label is noise.

**Action labels must be specific.** "Submit" describes nothing. "Save changes," "Send message," "Book appointment" — every CTA should complete "Click this to…"

**Emotional register matches the user's state.** Negative, sensitive, or failure states use gentle, indirect wording — never bluntly label the user's condition ("you are negative", "you failed"). In wellbeing contexts especially, the moment the user feels worst is the moment copy must be kindest. Frame around the action or the shared experience, not the diagnosis.

**Copy must parse one way.** If a phrase supports two readings ("resonated with the negative" vs "a negative resonance"), rewrite it. Test labels by asking what a first-time user would think each means.

**Truncation is a design decision, not an accident.** For every text slot, decide: single-line ellipsis (names in rows), N-line clamp (card descriptions), or wrap (headings, body). Truncated text must never hide the distinguishing part (truncate the middle of long unique IDs). Test with the long-name partial-data case. JP↔EN note: translations shift length dramatically in both directions — labels and buttons must survive both.

---

### Information hierarchy

This section defines local priority principles. Apply them across a complete screen through
**Page-level visual hierarchy** rather than inventing a second ranking method.

- **Frequency drives prominence.** Low-frequency actions (logout, delete account, rarely-changed settings) should be visually subordinate — smaller, lower in the list, lower contrast.
- **No redundant labels.** If the visual communicates it, the label is noise (an ON/OFF label next to a toggle; a count label next to the avatars it counts).

---

### Cognitive load and interaction density

This section owns density and choice-management rules. Use **Page-level visual hierarchy** for the
screen-wide role inventory and emphasis-channel ordering.

- **Choice sets:** more than ~6 simultaneous options need grouping (categories, positive/negative, tabs) or progressive disclosure. Eight ungrouped choices is a wall.
- **One screen, one primary job.** A screen dense with co-equal interactive areas has no job. Sequence inputs, stage them visually, or collapse secondary inputs behind disclosure — and keep exactly one dominant action.
- **Prefer dominance over navigation.** When two actions compete, make the primary visually dominant rather than splitting the flow into more screens — every added screen is added task burden.
- **Unavailability pattern:** avoid a modal whose only job is announcing that something is locked.
  Explain ordinary unavailability at the point of need. A requested detail/recovery flow,
  permission explanation, or consequential restriction may justify a dialog or sheet.
- **One idiom per control type.** A product teaches one segmented-control style, one sheet pattern, one close affordance, one toggle. Two visually different idioms for the same job double the vocabulary the user must learn — and read as two design sessions stitched together.
- **Don't expose system-operated controls.** If the system sets a control's state automatically (a tab that switches by time of day, a filter the app manages), it isn't a control — it's noise that invites confusion. Hide it, or make it genuinely user-operated. A control the user can see must be one the user meaningfully operates.
- **The decoration test.** For every decorative element or animation, ask: does removing it lose any meaning? If not, remove it. One signature decorative moment per screen maximum — decoration competes with the task everywhere else.

---

### Modal and sheet weight

Match transition weight to action weight:

| Transition | Use for |
|------------|---------|
| Full-screen modal | Multi-step flows, onboarding, camera/media capture |
| Half-modal / bottom sheet | Settings, detail views, quick actions, confirmations |
| Inline expansion | Minimal context switches |
| Toast / snackbar | Non-blocking success and info feedback only — never for errors |

**If the modal needs a scrollbar and multiple columns, it belongs on its own page.**

Toasts are for success and informational states. Never use a toast for a foreground error that requires user action — those are inline. Exception: failures of **background/async operations** (an upload that fails after navigation, a sync error) have no inline location; use a persistent, non-auto-dismissing snackbar with a retry action.

**Dismiss affordances — bottom sheet vs. centered dialog.** Match the dismiss affordance to the modal type. Don't stack redundant close controls.

| Modal type | Identifying trait | Dismiss affordances | Close button? |
|------------|-------------------|---------------------|---------------|
| Bottom sheet | Slides up from bottom; may have a grabber | Swipe/backdrop for lightweight sheets; explicit close/cancel when dismissal is not obvious, gestures are unavailable, or work may be lost | Contextual |
| Centered dialog | Floats centered, no edge attachment | Explicit close/cancel; backdrop may dismiss only when accidental dismissal is harmless | Usually |

A grabber is a visual hint, not a complete accessible dismissal mechanism. Choose affordances by
platform convention, action consequence, accessibility, and whether dismissal loses work. More
than one dismissal path is not automatically redundant when the paths serve different input modes.

Supporting rules:
- A grabber must actually drag. A decorative grabber with no swipe-to-dismiss logic (threshold ~120px) is a bug — the affordance lies about the behaviour. Wire up swipe + backdrop tap before removing any explicit close button.
- The × on a dialog can be visually secondary but must remain perceivable and meet the platform's
  target-size requirement. Backdrop dismissal is supplementary, not the primary accessible route.
- Redundant-close smell test: remove duplicate controls only when they serve the same input mode
  and add clutter. Preserve explicit cancel/close when it prevents loss or supports keyboard,
  switch, or screen-reader users.
- A full-width Cancel/Close action in a sheet is contextual: avoid it when it competes with the
  primary action without adding access, but retain it when platform convention, reachability,
  consequence, or assistive access warrants it.

---

### Motion

- Motion is intentional — designed at the same time as layout, not added at the end.
- Ease out with exponential curves (ease-out-quart/quint/expo). No bounce, no elastic (see Design decision gates).
- Durations: ~150ms for hover/small state changes, ~250ms for panels/dropdowns, ~350ms for modals/page transitions. Under 100ms reads as a glitch; over 400ms reads as lag.
- **Exits run faster than entrances** (~0.8×; ease-in or linear acceptable on exit) — the user has already decided to leave.
- **`transform-origin` is considered, not defaulted:** menus and popovers scale from their trigger corner, not from center.
- Stagger within one list: legitimate. The same entrance animation on every page section: AI grammar.
- `@media (prefers-reduced-motion: reduce)` is non-optional — crossfade or instant transition as fallback.
- Don't gate content visibility on a class-triggered animation.
- Animate `transform` and `opacity` only — not layout properties (see Quality requirements).

---

### Platform notes

The rules above apply universally. Platform-specific callouts:

**Web**
- Hover states are required; active states strongly recommended
- Focus rings are non-optional for keyboard and screen-reader users
- Max content width: 1280px typical; reading columns ≤ 75ch
- Scrollable containers must have a visible scroll affordance when content overflows
- Popovers, menus, and tooltips must escape clipping ancestors — an `overflow: hidden` container that cuts them off is a bug; free the overflow or portal the layer out

**Navigation chrome (native, both platforms)**
- Tab bar: 3–5 items, every item labelled (icon-only tab bars fail recognition), filled-vs-outline or colour as the active state, active state always unambiguous.
- Headers: one title convention system-wide (e.g. large title on roots, inline title + back on pushed screens). Back is a chevron/arrow top-left — never a custom X on a pushed screen (X means dismiss, not back).

**iOS (native)**
- Follow Apple Human Interface Guidelines for navigation (tab bar at bottom; stack navigation for hierarchy)
- Use system fonts (SF Pro) where brand permits — custom fonts require careful weight/size calibration
- Respect safe area insets, especially the bottom home indicator zone
- Prefer the platform presentation that preserves context and matches task weight; bottom sheets
  are useful for lightweight, mobile actions but are not a universal replacement for dialogs/pages.
- Provide haptic feedback on destructive actions

**Android (native)**
- Apply Material You design language where appropriate
- Navigation: three-button or gesture nav is a system responsibility — don't fight it
- 48dp minimum touch targets (enforced)
- Use Snackbars for dismissible feedback
- Avoid fixed bottom bars that clash with the gesture navigation zone

**Japanese / CJK text**
- Tracking: the −0.04em display floor is a Latin rule. JP display text: 0 to +0.05em; never negative-track kana/kanji.
- No italics in JP UI — emphasize with weight, size, or colour.
- Line height: JP body 1.6–1.9 (denser glyphs need more leading than Latin's 1.5–1.7).
- Line length: the 65–75ch rule doesn't map — target ~35–40 full-width characters.
- Name the JP font stack in DESIGN.md (e.g. Noto Sans JP, Hiragino Kaku Gothic). JP families ship fewer weights — verify the specified bold actually exists, or the browser fakes it (faux-bold is a cheapness tell).
- Headings: avoid awkward mid-phrase breaks — `word-break: auto-phrase` where supported, or manual `<wbr>`.
- Mixed JP/EN: dates and numbers stay Latin ("7月 9"); use a composite font stack so Latin glyphs harmonize with kana baselines.

**Cross-platform consistency:**
- Core spacing, color semantics, and interaction model should feel consistent
- Platform-specific controls should use native components — don't recreate them in custom CSS

---

### Design commitment check

Before shipping any interface, verify the design has a point of view:

- **First-order check:** Could someone guess the theme and palette from the product category alone? If yes, it's the first-reflex AI move. Rework.
- **Second-order check:** Could someone guess the aesthetic family from category + "not the obvious AI version"? If yes, the second reflex wasn't avoided either. Rework.

A design that feels considered has made at least one choice that surprises — a font, a color, a layout move — that signals a human was thinking about this specific product, not applying a template.

---

### Documentation integrity — absolute claims must be verifiable

An absolute claim in `DESIGN.md` ("**zero** coloured shadows," "no border+shadow combinations," "never a translucent fill," "all radii ≤ 16px") is a testable assertion, not prose. A doc that states an absolute the codebase contradicts is worse than silence — it gives a false green and stops reviewers from looking.

- **Every absolute doc claim is checked against the code, not taken on faith.** When `DESIGN.md` says *zero / no / never / always / all* about a property, the reviewer must confirm it in the **inline-style consistency sweep** (JSX `style={{…}}` and inline CSS the token graph can't see), not just against tokens.json. A "zero coloured shadows" claim contradicted by teal inline `box-shadow`s is a finding — the token validator sees only token values, so an inline violation hides behind a green validator.
- **An unverifiable or violated absolute is itself the finding.** If the claim can't be mechanically checked (too vague) or a sweep contradicts it, flag the *claim*: either the code must be brought into line, or the doc must be softened to what's true (e.g. "no coloured shadows *in tokens*" or "coloured shadows retired except the documented X"). Do not let an aspirational absolute stand as a statement of fact.
- Absolutes that map to an existing scanner pattern (coloured shadow, translucent fill, border+shadow, oversized radius) should be run through `scan.sh` over the whole surface, since the scanner reads inline styles the validator doesn't.
