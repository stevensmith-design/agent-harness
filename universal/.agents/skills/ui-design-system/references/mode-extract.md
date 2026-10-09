# Mode 2 — Extract (existing app; frequency ≠ correctness)

Reverse-engineer the system already in the code. **The most common value is not automatically the
right one** — extraction surfaces the implicit system *and* its inconsistencies; it does not bless
whatever recurs most.

1. Inventory actual usage: every unique colour, font size, weight, radius, spacing value, shadow —
   with counts and the files they appear in.
2. Cluster into a proposed scale: dominant radius values → `--radius-*`; recurring colours → semantic
   roles; recurring sizes → type scale. Note near-duplicates (`#1A2E2B` vs `#1B2B2A` — almost
   certainly one intent) and off-scale outliers.
3. Draft a four-layer `DESIGN.md` + `tokens.json` from the clusters (see
   `references/design-system-layers.md`). Infer Layer 1 intent from the product; mark inferred intent
   as *provisional — confirm with the team*.
4. **Run the validator on the extracted tokens.** Extraction frequently reveals a relationship the
   code never satisfied (a muted text that never cleared 4.5:1, a selection that matches the CTA).
   These are extraction findings, not the validator being wrong.
5. Output the `DESIGN.md` **plus** a drift list: where the codebase already disagrees with the system
   you just extracted. That list is the alignment backlog.

## Required output sections

An Extract run outputs: (1) the usage inventory with counts, (2) the reverse-engineered four-layer
`DESIGN.md` + `tokens.json` with Layer 1 marked *provisional*, (3) the validator summary on the
extracted tokens, and (4) the drift/alignment backlog. Do not present extracted values as an approved
system — they are a proposal pending team confirmation.
