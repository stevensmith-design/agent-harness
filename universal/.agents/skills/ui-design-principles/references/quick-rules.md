# Quick Rules — index card

One line per rule. **rules.md is canonical** — this file is an index and never overrides it. Work from this card; open the named rules.md section at each decision point (routing table at the end). New rules are promoted into rules.md sections first, then get one pointer line here.

**Three tiers (→ Decision tiers and the override process):** Tier 1 Quality requirements = non-negotiable · Tier 2 Design decision gates = earn their place via the six gate questions + DESIGN.md log; the reviewer assesses the *reasoning*, not the pattern · Tier 3 AI-tell risk indicators = co-occurrence scrutiny, not per-item failure.

**System gate (→ ui-design-system):** relationships *between* tokens (contrast pairs incl. CTA-label, selection ≠ action, value step, ramp hue, scale ratios) are checked by `validate-tokens.py`, not by eye — run it after defining tokens and before the first component; a `FAIL` blocks. Whole-system work (create / extract / coherence audit / drift) is the `ui-design-system` skill, not this card.

**Direction gate (→ design-directions.md):** classify visual language separately from layout,
content primitive, theme/mode, effect, and responsive/accessibility requirements. Commit one
dominant language plus an exclusion sentence. When available, `ui-ux-pro-max` may retrieve
candidates; project evidence and this skill adjudicate them.

## Quality requirements (Tier 1 — non-negotiable)

- No placeholder/lorem-ipsum text in production
- Animate `transform`/`opacity` only — never width/height/padding/margin/top/left
- Every reachable state designed: loading, empty, error, partial data
- Color is never the only signal
- Data-entry fields use visible labels by default; every control retains a persistent accessible name and context
- Semantic/index ramp (the meaning-carrying palette) never used for decoration — that leak corrupts the signal and is never waivable (→ Quality requirements → Semantic-palette leak)

## Design decision gates (Tier 2 — the tells; each earns its place via DESIGN.md log)

Each line is a *gate*, not a ban: the pattern is available to a design that clears Purpose · Direction-fit · Systematic · Survives-removal · No a11y/hierarchy cost · Legible, logged in DESIGN.md. Write "lacks a defined role," never "failure: found." Recurring five with explicit gates: gradient, shadow, glass, oversized radius, dark theme (→ Design decision gates → Decision gates for the recurring five).

- No gradient buttons or gradient text (exception: committed same-hue ≤5% vertical light cue)
- No colored side-stripe borders; no decorative accent border/stripe/top-bar that encodes no data (consistency ≠ purpose; position ≠ meaning); no ghost-cards (border + wide shadow); no nested cards
- Card radius ≤ system cap (16px default; playful mobile may commit 20–24); nested radii concentric
- Canvas: one flat colour from the brand hue at 2–5% sat; no unmotivated cream; no gradient/glow layer — including via CSS variables
- Content surfaces opaque — no rgba-white fills, no backdrop-blur on cards
- Shadows neutral, positive y-offset (no `0 0` glows), ≤16px blur; never brand tints; blur may run 3–4× offset
- No icon-tile feature-card template; one card primitive with varied prominence; no 4+ card treatments per screen
- Homogeneous lists = plain rows + dividers, never per-item cards; settings = one section card
- No eyebrow-on-every-section, no 01/02/03 markers, no long all-caps
- No emoji as chrome (documented JP content-emoji system (JP consumer apps) is fine; chrome stays distinct from content)
- No sketchy SVG scenes, glow orbs/aurora, neon multi-accent dark, decorative status dots, rainbow accents
- No oversized italic serif hero; display font is a considered choice (not Inter/Roboto/Arial/Geist); no purple-gradient-on-white
- No badge-above-hero-H1, stat banner rows, unmotivated permanent dark theme, centered-hero assembly
- No image scale/rotate on hover; no bounce/elastic easing
- No buzzwords; ≤2 em-dashes per block; CTAs specific ("Save changes", not "Submit"); no "X theater" framing (→ Copy hygiene)
- Decoration test: if removing it loses no meaning, remove it; ≤1 signature decorative moment per screen

## AI-tell risk indicators (Tier 3 — co-occurrence, not per-item failure) (→ AI-tell risk indicators)

- Assemblies, not single patterns: centered-hero assembly · icon-tile feature-card grid · badge-above-H1 · stat banner row · eyebrow-on-every-section · 01/02/03 markers · symmetry-everywhere
- One in isolation may be fine; **weight rises as they stack** — 2+ with no unifying rationale = strong "assembled, not designed" tell → downgrade Contextual fitness / Craft
- Fix is "break the assembly" (asymmetry, product-first, real screenshot), never "remove the gradient"

## Craft — the numbers (→ named section)

- Canvas: brand hue, S 2–5%, L 96–98%; cards pure #FFF; value step 1.05–1.12:1 (→ Choosing the canvas)
- One brand-tinted neutral ramp drives canvas, border, muted text, ink (→ Choosing the canvas)
- Separation order: whitespace → value step → hairline → container (→ Separation toolkit)
- Elevation by role: static = hairline+step, no shadow; tappable = elev-1; menus = elev-2; sheets = elev-3 (→ Surface and elevation)
- Radius: 4–8 inputs / 12 cards / 16 large / pill tags; inner = outer − gap (→ Border radius scale)
- Spacing: 8pt grid, 9 named steps; rhythm, not uniformity; text never touches an edge (≥8px in containers, ≥16px at viewport) (→ Spacing system)
- Type: heading ratios ≥ 1.25× target at display levels (validator hard floor 1.15×; dense-UI adjacents may use weight/colour); body ≥ 14/16px; LH by size — body 1.5–1.7 (JP 1.6–1.9), display 1.1–1.25; single family OK for product UI, pairing for brand UI; tabular-nums on data; display size follows actual measure, language, wrap, and hierarchy—not a word-count formula (→ Typography)
- JP (JP consumer apps): no italics, no negative tracking, ~35–40 chars/line, verify real font weights, manage heading breaks (`auto-phrase`/`<wbr>` — no dead whitespace from unmanaged wraps) (→ Japanese/CJK)
- Contrast: body and ordinary button labels ≥ 4.5:1; large (≥24px reg / 18.5px bold — bold alone is not large) ≥ 3:1; interactive boundaries ≥ 3:1; disabled/placeholder exempt; grays take the surface hue; count badge / small label on accent = full 4.5:1 (→ Color contrast)
- Colour: semantic roles; colour budgets such as 60/30/10 are diagnostics, not laws; selection and action remain distinguishable in context; multi-select needs each item independently identifiable through the smallest established non-colour channel, not necessarily a check; heavy/dark treatments require a precedent-context compatibility check (→ Color — semantic roles; Color strategy)
- Palette permission: every hue must be brand/action, brand-derived support, semantic state, or data/category; unrelated accents need explicit approval and contextual harmony; adjacent tinted surfaces must separate by value/space/border, not merely different hex values (→ Color strategy)
- Page hierarchy: family resemblance + role distinction; inventory action/content priority, spend position/space before colour/elevation, verify with squint and grayscale tests; repeated settings-row actions stay quieter than the region's Save/Apply, and destructive actions live in a separated danger zone (→ Page-level visual hierarchy; Button rules)
- Buttons: one dominant action per decision context (not two co-equal primaries); five states; heights 36/44/52; pressed states on tappable rows too; primary CTA stays reachable (→ Button rules)
- Tap targets: iOS 44pt, Android 48dp; web WCAG AA 24×24 CSS px including its spacing exception, with ~44px preferred for touch-heavy controls; preserve visible geometry via expanded hit areas; native controls clear safe areas (→ Tap targets)
- Forms: label above field, validate on blur, inline specific errors (→ Form and input rules)
- Charts: token colours, hairline gridlines, direct labels, no 3D/gradient fills; tappable elements visibly affordant at rest (→ Data visualization)
- Images: one fixed ratio per slot, cover-fit; avatars one shape, 2–3 sizes, designed placeholder (→ Imagery and avatars)
- Text on photos: overlay / pill / floor-fade / blur / scrim — pick one method and systematize (→ Text on imagery)
- Icons: one family, one stroke weight, 16/20/24; filled/outline only as state (→ Icon system)
- Cognitive load: > ~6 choices grouped; one primary job per screen; hide system-operated controls; one idiom per control type; disabled-in-place with reason, never a lock modal (→ Cognitive load)
- Modals: weight matches action; sheet = grabber + swipe (no ×); dialog = de-emphasized × (→ Modal and sheet weight)
- Motion: ease-out expo curves; ~150/250/350ms; reduced-motion fallback (→ Motion)
- States: role/permission variants; empty-state quality bar; prototype hygiene (no demo controls, won't-save cues) (→ Edge cases and states)
- Copy: parses one way; gentle register for sensitive states; truncation decided per slot, survives JP↔EN (→ Copy hygiene)
- Nav: tab bar 3–5 labelled items, unambiguous active state; back = chevron, never × (→ Platform notes)
- A11y semantics: aria-label on every icon-only control; real `<button>`/`<a>`, no clickable divs; headings descend; modals trap + return focus, Esc closes (→ Accessible semantics and keyboard)
- Hover never gates functionality — on any element, tooltips included (→ Tap targets)
- Popovers/menus/tooltips escape clipping ancestors — overflow:hidden must not cut them off (→ Platform notes)
- Responsive: use a small committed breakpoint set; design narrow and wide variants; test representative extremes; avoid accidental page-level horizontal scroll (→ Responsive and adaptive layout)
- Tables: align text/numbers for scanning; choose hairlines/zebra/sticky headers from density and width; card conversion or a labelled horizontal region may be correct on narrow screens (→ Data tables)
- Z-index: token ramp by layer role; no literals, 9999 banned (→ Surface and elevation)
- Undo over confirm for reversible actions; confirm only the irreversible (→ Button rules)
- Loading: indicators delayed ~300ms, shown ≥500ms; skeleton = exact content size (→ Edge cases)
- Optical alignment: audit shared page/section/card/form/row axes at narrow and wide breakpoints;
  distinguish intentional indentation from accidental 2–8px gutter drift; perception beats
  geometry only for documented ±1–2px nudges (→ Optical alignment)
- Commit: build grayscale-first; pass first-order AND second-order reflex checks (→ Design commitment check)
- Docs integrity: DESIGN.md absolute claims (zero/no/never/all) are checked against inline styles, not just tokens; a code comment citing an override must resolve to a real override-log entry (scan.sh #25) (→ Documentation integrity)

## Decision-point routing

| Building… | Open rules.md section |
|---|---|
| Screen canvas / surfaces / shadows | Choosing the canvas; Surface and elevation; Shadows |
| First card or list | Border radius scale; List and card patterns |
| Buttons / CTAs | Button rules; Tap targets |
| Type system | Typography; Japanese/CJK (Platform notes) |
| Colour system | Color — semantic roles; Color strategy; Color contrast; Page-level visual hierarchy |
| Chart / stats | Data visualization |
| Images / avatars | Imagery and avatars; Text on imagery |
| Forms | Form and input rules |
| Modal / sheet | Modal and sheet weight |
| Microcopy | Copy hygiene |
| Any gradient | Gradients — when and how |
| States / density / settings pages | Edge cases and states; Cognitive load; Page-level visual hierarchy; Button rules |
| Data table | Data tables |
| Web layout / breakpoints | Responsive and adaptive layout |
| Named/unclear/mixed visual style | `design-directions.md` → selection, composition, and review |
| External reference / screenshot / component library / found DESIGN.md | `reference-intake.md` → record provenance, extract principles, adopt nothing as authority |
| Material / Android / Material-token project | `material-3.md` → adoption boundary, system layers, components, adaptive layout |
| Accessibility semantics | Accessible semantics and keyboard |
| Whole design system / tokens.json | ui-design-system skill (Create/Extract/Coherence audit/Drift) + `validate-tokens.py` gate |
| DESIGN.md claims / override citations | Documentation integrity |
