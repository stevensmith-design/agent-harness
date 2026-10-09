# Design directions — selection, composition, and style integrity

Read this reference when the user names a visual style, the direction is unresolved, multiple
styles are being mixed, or an external style recommender is used. It is a selection framework, not
a gallery of presets.

For any external *source* supplied as input — a site, screenshot, component library, or found
design-system file, not only a named style — run `reference-intake.md` first to record its role and
provenance; this reference then classifies and disciplines the style it suggests.

## Contents

1. Classify the request correctly
2. Select a direction from product evidence
3. Direction families
4. Composition rules
5. Optional `ui-ux-pro-max` interoperability
6. Direction review

## 1. Classify the request correctly

Do not treat every design term as a visual style. First classify it:

| Kind | Examples | What it decides |
|---|---|---|
| **Visual language** | flat, skeuomorphic, brutalist, editorial, retro, illustrative, Material | how surfaces, type, shape, imagery, and motion behave |
| **Layout strategy** | grid-based, asymmetric, fullscreen, single-page | how content is arranged |
| **Content primitive** | cards, lists, tables, feeds | how information is grouped and operated on |
| **Theme or mode** | dark mode, monochrome, high contrast | a system-wide presentation variant |
| **Effect** | glass, neumorphic relief, parallax, colour blocking | a local technique that must earn a functional role |
| **Requirement** | responsive, adaptive, accessible | a quality property, never an aesthetic option |

A direction may combine one item from several rows: “editorial visual language, asymmetric grid,
card-free article index, light/dark paired themes.” It must not combine several visual languages by
accident.

## 2. Select a direction from product evidence

Choose from these inputs, in order:

1. **Task and consequence:** scanning, creation, transaction, reflection, entertainment; speed and
   error cost.
2. **Platform and interaction:** web, iOS, Android, touch, pointer, keyboard, assistive technology.
3. **Content character:** density, repetition, imagery, data, text length, localization.
4. **Audience and emotional register:** expertise, frequency, trust, play, calm, urgency.
5. **Brand evidence:** existing assets, type, colour, product voice, physical or cultural references.
6. **Technical cost:** performance, browser/device support, maintainability, reduced-motion behavior.

Write one direction sentence and one exclusion sentence:

> **Direction:** Calm editorial utility — strong type hierarchy, flat opaque surfaces, restrained
> warm-neutral palette, and one asymmetric content break.
>
> **Exclusions:** No glass cards, ornamental gradients, skeuomorphic controls, or motion that delays
> scanning.

The exclusion sentence prevents “style soup” more reliably than a long inspiration list.

## 3. Direction families

These are starting hypotheses. A family never overrides product evidence or platform convention.

| Family | Strong fit | Required discipline | Common failure |
|---|---|---|---|
| **Flat / minimal** | tools, content, high-frequency product UI | hierarchy must come from type, spacing, value, and structure; affordances stay explicit | “minimal” becomes low contrast, ambiguous controls, or empty sameness |
| **Material** | Android and cross-device products that adopt Material components/tokens | use component behavior, roles, states, adaptive patterns, and motion as a system | copying rounded shapes and shadows without the interaction model |
| **Skeuomorphic / tactile** | focused creation tools, playful objects, strong real-world metaphor | map visual depth to manipulability; keep labels, states, and targets clear | decorative realism obscures state or adds cognitive load |
| **Editorial / typography-led** | publishing, portfolios, cultural and brand surfaces | deliberate measure, rhythm, content hierarchy, and responsive re-composition | large type used as decoration; product actions become secondary to art direction |
| **Brutalist / raw** | cultural, experimental, campaign, or deliberately confrontational work | preserve usability, hierarchy, focus, and responsive behavior beneath the raw treatment | “unpolished” becomes careless alignment, weak affordance, or inaccessible contrast |
| **Retro / vintage / Art Deco** | historically anchored brands, entertainment, hospitality, events | name the era and source motifs; translate them into a small token set | costume made from arbitrary fonts, borders, grain, and colour |
| **Illustrative** | onboarding, storytelling, education, emotionally expressive products | art has a content role, a consistent authorial hand, and designed loading/fallback behavior | generic spot art fills empty space or competes with the task |
| **Monochrome / colour-blocked** | strong brand systems, portfolios, focused utilities | hierarchy survives without extra hues; semantic colours retain meaning | colour blocks become decorative scaffolding or hide weak structure |

Treat glass, neumorphic relief, parallax, fullscreen media, and dark mode as effects/modes rather
than complete directions. Each needs a purpose, fallback, accessibility check, and a documented
surface or transition role. Read `rules.md` → **Design decision gates** before using them.

## 4. Composition rules

- Keep **one dominant visual language**. A second influence is allowed only when its role is named
  (for example, flat product chrome around an illustrative content world).
- Keep layout strategy independent from surface style. An asymmetric layout does not require
  brutalist typography; cards do not require Material.
- Derive components from the direction's grammar: type, shape, surface, border/elevation, icon,
  imagery, and motion rules. Do not style components one by one.
- Test the direction on a mundane screen—settings, errors, dense lists—not only the hero. A language
  that works only in a showcase is not a product system.
- Run a subtraction pass. Any flourish that adds no meaning, hierarchy, affordance, feedback, or
  brand recognition is a removal candidate.

## 5. Optional `ui-ux-pro-max` interoperability

When `ui-ux-pro-max` is installed or supplied by the user, use it as **retrieval**, not authority.
Discover its active path; do not hard-code the example repository path.

Useful read-only queries:

```bash
python3 <ui-ux-pro-max-path>/scripts/search.py "<product task audience register>" --design-system
python3 <ui-ux-pro-max-path>/scripts/search.py "<direction keywords>" --domain style -n 5
python3 <ui-ux-pro-max-path>/scripts/search.py "<interaction or accessibility question>" --domain ux -n 5
python3 <ui-ux-pro-max-path>/scripts/search.py "<implementation concern>" --stack <stack>
```

Use the results to produce at most three candidate directions. For each candidate, state:

- why it fits the task, platform, content, and brand evidence;
- what it explicitly excludes;
- its accessibility, performance, and maintenance risks;
- which recommendation is evidence-backed versus merely retrieved.

Do **not** let the external tool persist `design-system/MASTER.md` or page overrides when this
project already uses `DESIGN.md` and `tokens.json`; that creates competing sources of truth.
Translate an accepted candidate into the existing design contract through `ui-design-system`.
Current project evidence, authoritative components, accessibility, and this skill's decision gates
win any conflict with a database recommendation.

## 6. Direction review

Before implementation and again at sign-off, answer:

1. Can the direction be named from the rendered screen without reading the design document?
2. Does it fit the task and platform, not merely the product category stereotype?
3. Do type, surfaces, shapes, icons, imagery, and motion speak the same language?
4. Are controls and states still obvious when decorative effects are removed?
5. Does the direction survive dense content, long text, error/empty/loading states, narrow screens,
   and reduced motion?
6. Is there one product-specific decision a reviewer could not predict from “industry + trendy
   style” alone?

If the answer to 2, 4, or 5 is no, change the direction. If 1 or 3 is no, the system is incoherent.
If 6 is no, the result is likely competent but generic.
