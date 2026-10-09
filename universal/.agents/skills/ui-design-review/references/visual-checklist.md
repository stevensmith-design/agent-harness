# Visual review checklist

Read this file for every visual review, including a single screenshot. `rules.md` is canonical;
open only the named sections needed to adjudicate a finding. **A token-validator PASS or scanner
PASS is never visual sign-off — a green scan is not approval.**

**Contents**
- 0. Non-negotiable visual judgments (read first)
- 1. Compact-control geometry audit — mandatory
- 2. Hierarchy, layout, and spacing
- 3. Colour, contrast, type, and states
- 4. Components, interaction, and platform
- 5. Surface, imagery, motion, copy, and completeness
- 6. Coherence and AI-tell adjudication · 7. Coverage record

## 0. Non-negotiable visual judgments (read first)

- **Hit target is not visible size.** Platform minimums apply to the interactive area, not the
  painted pill. Do not enlarge visible controls merely to reach 44pt/48dp/24px when an invisible
  hit-area expansion can preserve better geometry.
- **Compact repeated actions must remain subordinate.** Compare visible height, width, horizontal
  padding, corner radius, label length, repetition count, and surrounding row height. Flag controls
  that become near-circular, dominate the subject/content, or feel like primary CTAs in every row.
  There is no universal "36 good / 44 bad" cutoff; the failure is the evidenced relationship.
- **Ordinary button text needs 4.5:1.** The 3:1 text threshold is allowed only when the actual
  rendered label is WCAG-large (at least 24px regular or about 18.5px bold). Bold alone is not
  large. Token-only validation therefore defaults CTA labels to 4.5:1 unless size/weight metadata
  proves the large-text exception. *(This is the exception that defeats the WCAG bait — do not drop
  it.)*
- **Minimum sufficient state signal.** "Do not rely on colour alone" does not mean "add a
  checkmark." Preserve the component language; a border, weight, shape, underline, position, label,
  or mark may already be sufficient. Single-select tabs normally communicate through relation to
  siblings; multi-select items need independent persistence, not automatically checks.
- **Accessibility is not an override category.** An override may document a deliberate Tier-2
  aesthetic choice; it cannot legitimize a contrast, semantics, target, focus, or other applicable
  accessibility failure. Report the failure and fix it.

## 1. Compact-control geometry audit — mandatory

For every repeated pill, chip, row action, segmented item, badge, and small button:

1. Identify the painted bounds and the interactive hit bounds separately.
2. Compare visible height, width, horizontal padding, radius, label length, and icon/label balance.
3. Compare the control to its row height, subject/avatar/text block, sibling actions, and controls
   of the same role elsewhere.
4. Ask whether repetition amplifies its visual weight: do the actions dominate the people/content?
5. Inspect short and long labels. Does a short label plus large padding/radius become near-circular?
6. Check whether the control looks like a primary CTA despite being a repeated secondary action.
7. If the hit target is deficient, prefer transparent hit slop or row-level affordance before
   enlarging the visible pill. Never cite WCAG as requiring a 44px painted web pill.

Flag only with relational evidence, for example: “The 44pt painted action occupies most of a
56pt row and repeats twice per row, giving secondary actions more mass than the identity block;
retain the platform hit target but restore the compact painted height.” A number alone is not a
design verdict.

## 2. Hierarchy, layout, and spacing

- Visual ranking matches importance; one dominant action per decision context.
- Repeated secondary actions remain subordinate; low-frequency/destructive actions are not louder
  than the content they operate on.
- Run the page-level hierarchy inventory from `rules.md`: rank action/content roles, verify the
  first reading path with a squint/blur check, and re-check in grayscale. Component consistency
  means family resemblance plus role distinction, not equal prominence.
- Audit alignment lines and gutters at every nesting level: page edge, section heading, card/list
  content, form labels/fields, and repeated rows. Elements intended to share an axis must resolve to
  the same edge or a documented optical offset; unexplained 2–8px left-edge drift is a craft finding.
- Spacing follows the project scale with intentional grouping, not equal padding everywhere.
- Section boundaries are clear without relying on interaction.
- Text avoids clipped overflow, accidental wrapping, and unmanaged CJK phrase breaks.
- Responsive layouts are intentional at narrow and wide sizes; tables may use a labelled,
  deliberate horizontal-scroll region when relationships need preservation.
- Nested radii are concentric; visible shapes match the stated aesthetic rather than drifting into
  pills/circles merely because the hit target grew.

## 3. Colour, contrast, type, and states

- Run the token validator when tokens exist.
- Audit palette permission: every non-neutral hue must serve brand/action, brand-derived support,
  semantic state, or data/category distinction. A tokenized colour is not automatically coherent;
  inspect hue, chroma, temperature, usage proportion, and the documented harmony rule in context.
- Compare every tinted tile, well, chip, banner, and callout with the surface it actually touches.
  Different token values can still collapse visually; use whitespace, value step, or a hairline
  before adding hue, saturation, shadow, or glow.
- Body, secondary, ordinary button, and small badge text require 4.5:1. Use 3:1 for text only when
  actual size/weight proves WCAG-large; boldness by itself does not qualify.
- Interactive boundaries and focus indicators meet their applicable 3:1 requirement.
- Meaning does not rely on colour alone. Inventory fill/value, border, weight, underline/position,
  shape, icon/mark, and elevation; use the minimum sufficient compatible signal.
- Selection remains distinct from action. Do not add checkmarks to single-select tabs or emoji
  tiles unless existing channels are demonstrably ambiguous for that selection model.
- Enabled, pressed, focus, disabled, error, loading, empty, and partial states are designed as
  applicable. Disabled styling must not be confused with enabled.
- Adjacent type levels are visibly distinct; line height, tracking, and measure fit the language.
- Semantic colours remain distinguishable and aligned with established roles.

## 4. Components, interaction, and platform

- Hit targets meet the target platform: iOS 44pt, Android 48dp, web WCAG 2.5.8 24×24 CSS px with
  its spacing exception. These are interaction-area requirements, not mandatory painted sizes.
- Native controls clear safe-area/home-indicator/gesture zones.
- Buttons, rows, tabs, sheets, modals, close/back controls, and inputs use one coherent idiom per
  role and follow platform conventions.
- Inputs keep an accessible name and sufficient context during/after entry.
- Icon-only controls have accessible labels; keyboard focus order, modal trapping/return, and Esc
  behavior work where applicable.
- Nothing essential is hover-only; menus/popovers escape clipping ancestors.
- Modal weight matches consequence. Reversible actions consider undo; consequential actions use
  protection proportionate to risk and recoverability.
- Primary actions remain reachable as content expands.

## 5. Surface, imagery, motion, copy, and completeness

- Surface/elevation choices are systematic and support hierarchy; no unexplained glow, glass,
  gradient, excessive shadow, or decorative treatment merely because a detector named it.
- Scan for accent borders / stripes / top-bars that encode nothing — a coloured bar that means only
  "leftmost / phase 1" is decorative-by-default, not a status. Consistency across several is
  systematic decoration, not justification.
- Check the semantic/index ramp has not leaked into decoration: a border, stripe, or shadow drawn
  from the meaning-carrying ramp (status/category/index colours) is a Tier-1 correctness failure —
  it corrupts the signal and is not waivable.
- Cards and lists match content structure; homogeneous rows are not needlessly cardified.
- Images use stable ratios and intentional placeholders; icons share a family and weight.
- Motion has purpose, respects reduced-motion needs, and avoids demonstrated jank.
- CTA labels are specific; copy is clear, non-placeholder, and appropriate to sensitive states.
- No demo/reviewer controls leak into product UI; truncation and localization are designed.

## 6. Coherence and AI-tell adjudication

For any suspicious pattern, ask whether it has purpose, fits product/platform/direction, is
systematic, communicates without the effect, preserves accessibility/hierarchy, and is legibly
documented. A Tier-2 pattern is **presumed a defect** — the design carries the burden of a
documented, functional reason; "I couldn't find a reason to keep it" resolves to *remove*, not
*leave*. Consistency/polish/positional-only meaning do **not** clear the gate (see
`impeccable-review/references/adjudication.md` → "What does NOT count as justification"). Multiple
unrelated generic patterns can form an “assembled, not designed” finding; one isolated pattern is
still presumed-defect until the design justifies it, though a single tell is usually only a prompt
to inspect the rest.

When a named visual style or Material system is claimed, read the applicable
`.agents/skills/ui-design-principles/references/design-directions.md` or `material-3.md` reference. Verify the
claim as a system: type, shape, surface, icon, imagery, motion, component behavior, and non-default
states. Do not approve a Material claim from rounded shapes/elevation alone, or a named style from a
hero while mundane product screens speak a different language.

## 7. Coverage record

List screens, viewports, states, source files, token files, and tools actually inspected. Name
anything unavailable as `[Not assessable]`. A clean scanner/validator does not cover visual craft.
