# Validator provenance & rationale

Dated provenance for individual validator checks. The authoritative inline copies remain as comments
in `scripts/validate-tokens.py` next to the code they explain (that is where a maintainer editing the
check will see them); this file collects them in one place so the reasoning is legible without
reading the script. When a check's rationale changes, update both.

## Provenance log (calibration review series, 2026-07)

> "JT" tags below mark cases from an early consumer-app design-review series used to calibrate these thresholds; the checks themselves are app-agnostic — they encode the relationship, not the app.

- **Primary ↔ disabled distinctness (`distinct/primary-vs-disabled`).** The 2026-07 "CTA reads as disabled" bug shipped because an enabled
  primary and a ghost/disabled state were only ~1.92:1 apart at `#27A390` — confusable. The check
  computes enabled-vs-disabled distance and warns on low separation. (`validate-tokens.py` ~L404.)
- **Badge/count-label-on-accent.** Small inline badge labels are caught by the render/inline sweep;
  the validator assesses the pair only when a badge fill role is declared (the JT case — badges are
  inline). (~L381.)
- **Background ↔ card value step.** JT case: a surface measured 1.033 on the canvas but 1.126 on the
  card it actually sits on; a canvas-only check misses it. The check evaluates the step against the
  ground the element really sits on. (~L522.)
- **Selection ≠ action second signal.** Promoted 2026-07-13 from a JT review where a mockup dropped
  the scale-lift and the selected tile read as blending; the check reminds the reviewer to verify the
  non-colour channel. (~L527.)
- **Tinted-tile separation config.** The JT-2026-07 configuration (12% tint + 1.04 lift + ink check,
  decorative border retired) is what the tile/well/chip/callout separation check guards; a
  retired-border NOTE flagged the fragile config. (~L547–555.)
- **Theme-vs-tokens drift ("green as false comfort").** The 2026-07-11 external reviews both hit the
  same failure class: `tokens.json` validated while the shipped theme CSS carried different values.
  The `--theme` diff (Drift mode) exists to catch it. (~L773.)
