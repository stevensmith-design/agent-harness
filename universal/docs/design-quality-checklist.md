# Design quality — where it lives now

This file used to hold a short manual checklist. It was referenced by no skill
and no script, while three other pieces of machinery behaved as though a design
layer existed. That is fixed: the design layer is real, and it has owners.

| Need | Owner |
|---|---|
| Create or extract the design system — `DESIGN.md` + `tokens.json` | `.agents/skills/ui-design-system` |
| Build a screen against it | `.agents/skills/ui-design-principles` |
| Review a finished screen or a PR | `.agents/skills/ui-design-review` |
| Navigation, hierarchy, labelling | `.agents/skills/ia-review` |
| Raw hex and magic numbers in source | `make check-tokens` (`design.forbid` rules) |
| Whether the tokens actually cohere | `make check-design` (`scripts/validate-tokens.py`) |
| Geometry on the rendered page — tap targets at phone width, text size, overflow, overlap — and a contact sheet | `make render-audit` (`scripts/render-audit.mjs`) |

The gates check different things and none replaces another. `render-audit`
measures the page as drawn — the only one of them that sees a 20px close button
or a customer name spilling out of its card — and its contact sheet is the
screenshot evidence `ui-design-review` asks for.
`check-tokens` is a regex over files: it catches a hardcoded `#ff0000` or a
`padding: 12px`. `check-design` computes the relationships *between* tokens —
contrast pairs, neutral-ramp derivation, type-scale ratios, elevation
monotonicity — which no per-file rule can see. A project can pass one and fail
the other, and the failures mean different things.

The visual checklist itself is now
`.agents/skills/ui-design-review/references/visual-checklist.md`, maintained
with the skill that uses it.

Delete this file, the four skills and the `design:` config block for a project
with no UI.
