# Report and verdict

## Required structure

```markdown
## Visual Review — [screen/component]

### Verdict: [SHIP IT / MINOR FIXES / MAJOR REVISION]

| Dimension | Result | Reason |
|---|---|---|
| Correctness | pass/fail | ... |
| Consistency | pass/fail | ... |
| Contextual fitness | pass/fail | ... |
| Craft | pass/fail | ... |

### Failures
- **[Rule]:** [Verified/Inferred] observation. **Basis:** class + source. **Scope checked:** ...
  **Repair:** an implementation-ready prescription per `repair-prescriptions.md` — cause/owner,
  preserve, exact-or-bounded change, scope, why, how, acceptance criteria, uncertainty. Scale it to
  severity (full contract for material failures; compact cause · change · acceptance check for minor;
  one line for warnings) and to evidence (exact edits when source exists; bounded candidates + a
  selection rule when screenshot-only; a provisional draft when no design system exists).

### Warnings and optional notes
...

### What's working
...

### Coverage
- Screens/viewports/states/files/tokens/tools inspected
- Not assessable
```

Report all three system layers: rule existence, rule quality, and application. Include measured
contrast pairs when source colours are known. Do not manufacture exact ratios from compressed
screenshots. A material failure without a repair prescription at its severity tier is incomplete
(see `repair-prescriptions.md`).

## Verdict calibration

- **SHIP IT:** all dimensions pass; no material defect remains.
- **MINOR FIXES:** bounded local defects with a known correction and limited blast radius. An
  isolated accessibility failure can be minor in redesign scope while still being mandatory to
  fix before shipping.
- **MAJOR REVISION:** a defect is systemic/repeated, two or more dimensions fail, the design rules
  themselves are broken, or the safe solution is uncertain and requires structural rework.

Correctness failure does not mechanically force MAJOR. Separate defect importance from redesign
scope: “mandatory fix” and “major revision” are not synonyms.

## Override boundary

Overrides may record intentional aesthetic exceptions. Never recommend an override as resolution
for applicable accessibility/correctness failures. Fix the failure; document only the resulting
valid design decision if useful.
