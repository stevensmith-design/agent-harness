# Mode 4 — Drift (DESIGN.md/tokens vs shipped UI)

A system exists; verify the code still obeys it.

1. **Run the validator** to confirm the *system itself* is still coherent (a token file can drift
   from its own DESIGN.md prose, or an edit can break a relationship). Fix the system before checking
   the code against it — comparing code to a broken standard wastes the pass.

   Pass **`--theme PATH`** (pointing at the shipped theme CSS, e.g. `theme.css` / `globals.css`) so
   the validator diffs the *implementation's* resolved values against `tokens.json` and raises
   `drift/theme-vs-tokens` when the CSS silently disagrees with the tokens — the "green as false
   comfort" case where `tokens.json` validates but the shipped CSS carries different values (see
   `references/validator-rationale.md`):

   ```bash
   python3 <resolved>/validate-tokens.py <project-dir> --theme path/to/theme.css --json
   ```
   Without `--theme`, this specific implementation-vs-tokens check is SKIPPED, not passed — say so in
   the report rather than implying the code was checked.
2. Compare the codebase against the documented tokens:

   | Drift pattern | What it looks like |
   |--------------|-------------------|
   | **Radius** | `border-radius` not matching a `--radius-*` token |
   | **Spacing** | hard-coded px off the grid / off the scale |
   | **Colour** | ad-hoc hex/hsl in components instead of a token |
   | **Font** | sizes or families not in the type scale |
   | **Shadow** | box-shadow not matching the `--elev-*` ramp |
   | **Button** | differing heights/padding/radii across the code |

   For code-side detection, `ui-design-review`'s `scan.sh` and its consistency sweep do the per-file
   pattern work; this mode consumes their findings at the system level.
3. Report each drift: file, token expected, value found. Items in the DESIGN.md override log are
   intentional — not drift.

## Drift output format

```
## Design System Drift — [project scope]

### Validator: [PASS / PASS w/ warnings / FAIL]  (system-level coherence)
[paste the one-line summary; list any FAIL relationships]

### Code drift (if any)
| File | Token expected | Value found | Fix |
|------|---------------|-------------|-----|
| Card.tsx:24 | --radius-card (16px) | border-radius: 20px | use --radius-card |

### Recommendation
[ALIGNED — validator green, no code drift]
[DRIFT — N inconsistencies; align code or log overrides]
[SYSTEM FAIL — a token relationship is broken; fix DESIGN.md/tokens first]
```
