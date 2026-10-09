# Mode 1 — Create (intent → principles → tokens → relationships)

Greenfield. Build the system in the same order as the four layers (see
`references/design-system-layers.md`), and do not skip down to token values before the layer above is
decided.

1. **Intent (Layer 1).** Name the aesthetic commitment in one sentence (vague is wrong). State
   platform, audience, register (product UI vs brand UI). Settle the **task structure** first
   (primary action, information priority, interaction primitive, surface type, irreversibility,
   responsive behaviour) — structure precedes the visual direction. Fill the *Defaults retained vs
   product-specific decisions* declaration — a system that retained everything and decided nothing is
   a finding, not a system.
2. **System principles (Layer 2).** Choose the colour strategy and record why every non-neutral hue
   is permitted (brand/action, brand-derived support, semantic state, or data/category). Define the
   page hierarchy model, including how repeated actions stay subordinate to decision actions. Then
   choose the separation model (value step / neutral shadow / hairline — never glow),
   elevation-by-role, and motion character. These are the rules the tokens will instantiate.
3. **Tokens (Layer 3).** Fill `tokens.json` and the DESIGN.md token sections from the template.
   Derive all neutrals from **one brand-tinted ramp** (brand hue at 2–8% chroma). Pick the primary
   for **AA contrast against its own label** before anything else commits to it.
4. **Relationships (Layer 4).** Write down why the values cohere, then prove it with the validator
   (invocation in SKILL.md — greenfield uses `--strict`):

   ```bash
   python3 <resolved>/validate-tokens.py <project-dir> --strict
   ```

   `--strict`: the core relationships (body-on-canvas, CTA-label, value step, neutral ramp) must be
   *assessed*, not SKIPped — an unresolved required role FAILs, so a half-populated token file can't
   pass on missing coverage.
   **The system must cohere before the first component.** Resolve every FAIL and record the checked
   relationships (contrast pairs, selection≠action, value step, ramp hue) in Layer 4. Only then hand
   off to `ui-design-principles` for building screens.

## Required output sections

A Create run outputs: (1) the four-layer `DESIGN.md`, (2) `tokens.json` mirroring Layer 3 1:1,
(3) the validator summary showing **PASS under `--strict`**, and (4) the Layer-4 relationship record
(which pairs were checked and why they hold). A run missing the Layer-4 record or the `--strict` PASS
is incomplete.

### Worked example — a filled Layer-4 entry

```
## Layer 4 — Relationships & rationale

- Body-on-canvas: ink #1A2422 on canvas #F7F9F8 = 13.1:1 (AA/AAA). Checked.
- CTA-label-on-CTA: white #FFFFFF on primary #0E7C66 = 4.9:1 (AA for normal text). Checked —
  this is the pair that most often fails; primary was chosen for this ratio before anything else.
- Value step: card #FFFFFF vs canvas #F7F9F8 = 1.06 (within 1.05–1.12). Separation is by value
  step, not shadow — matches the "calm, flat" intent.
- Selection ≠ action: selected fill #E3EFEC vs primary #0E7C66 — deltaE 41 plus a 2px inset ring,
  so selection never reads as the CTA even in grayscale.
- Neutral ramp: derived from brand hue 168° at 4% chroma — tinted, not dead-gray, not off-hue.
- Override log: none yet. (Any Tier-2 pattern added later lands here with its six-gate reasoning.)
```
