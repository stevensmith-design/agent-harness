# Pack: Design

**Status:** complete. Covers two shapes of design harness: a constructor-plus-template harness for a single product-UI lane, and a multi-lane harness covering product, marketing, documents and presentations.

## The verbs

`validate-tokens` (relationships *between* tokens — contrast pairs, semantic distinctness, neutral-ramp derivation, type-scale ratios, elevation monotonicity) · `scan` (raw hex, magic spacing — per-file regex) · AI review · human approval.

**Two gates with different jobs, and both are needed.** A regex scan cannot tell you that your canvas and card tokens resolve to the same colour; a relationship validator cannot tell you someone hardcoded `#3B82F6` in a component.

## The foundations

`BRAND.md` (strategy, personality, voice, **and the derivation rationale** — *why* this hue, because the brand is X) → `PRODUCT.md` → `DESIGN.md` + `tokens.json`.

Tokens must be **derivable from brand**. Without the rationale, tokens are arbitrary and every new surface reinvents the look.

## Starting rung: **split**

**L2 for the mechanical part** — tokens, contrast, spacing. Writable today.
**L1 for craft** — hierarchy, whether it is any good. Needs the corpus.

Split the surface rather than averaging the rung. This is the clearest real example of why rungs are per-surface.

## Lanes, with enforcement depth that differs on purpose

| Lane | Creation | Review | Depth |
|---|---|---|---|
| Product UI | design-system + principles | review · IA · a11y | Full: validators, scanners, CI |
| Presentations | Locked template | Per-deck checklist | Template lock + checklist |
| Documents | Locked template | Lane checklist | Template lock |
| Marketing | Web inherits product tokens | Brand + slop checklist | Checklist |

**Do not build heavyweight machinery for the light lanes.** A one-page rules file plus a locked template captures most of collateral quality. The ratchet decides when a lane has earned more.

## Process gates specific to design

- **Review → approval → guideline.** A review reports findings with before/after and *stops*. The guideline is produced only after approval, logged. Never merge the two deliverables.
- **Handoff is the seam to engineering** — tokens used, component props, states, breakpoints, motion. Design crosses over only through it.
