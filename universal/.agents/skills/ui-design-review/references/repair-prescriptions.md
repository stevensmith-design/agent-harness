# Repair prescriptions — from finding to implementation-ready change

A finding that names a problem without naming its fix leaves the reader to re-derive the solution.
Every **material or actionable** finding must ship an implementation-ready repair — scaled to the
finding's **severity** and to the **evidence** actually available. A follow-on command may *execute*
a repair; it never *substitutes* for specifying one.

> **Mirror note.** This file is an intentional byte-for-byte mirror:
> `.agents/skills/ui-design-review/references/repair-prescriptions.md` (canonical) and
> `impeccable/reference/repair-prescriptions.md`. Edit one copy, then re-mirror the other (`cp`);

## The repair contract (eight fields)

A full prescription answers all eight. Fields collapse by tier (below), but none may be silently
dropped on a material finding.

1. **Cause** — name the *owner* of the defect: a token, a shared component, a layout wrapper, or a
   single local instance. Not the visible symptom. "The shared `Button` is used with
   `variant="primary"` for three different action roles," not "the buttons look the same."
2. **Preserve** — the constraints that must stay unchanged: established typography, brand anchor,
   component semantics, interaction model, row height, or another explicit invariant. A repair that
   doesn't say what it protects invites collateral drift.
3. **Change** — the exact `old → new` mapping when source is available; bounded alternatives when it
   is not (see evidence tiers).
4. **Scope** — every affected component, state, breakpoint, and representative sibling. A fix
   validated only on the one screen in front of you is not scoped.
5. **Why** — the **basis class** (standard/correctness · project contract · established principle ·
   platform convention · heuristic/taste · UX/product hypothesis) plus the measured or observed
   evidence. Heuristic/taste is labelled as such, never dressed as correctness.
6. **How** — the implementation form: token edit, component variant, CSS change, structural rewrite,
   or a concise patch-shaped snippet.
7. **Proof** — measurable acceptance criteria and the exact views/states to re-render to confirm the
   fix. Criteria are *testable*, not a restatement of the complaint (see acceptance rules).
8. **Uncertainty** — when the evidence cannot justify an exact value, give bounded alternatives and
   the test that selects between them, rather than silently guessing a number.

## Severity tiers — match ceremony to the change

- **P0 / P1 / material failure** → the **full eight-field contract**.
- **Minor bounded defect** → a **compact prescription**: cause · exact-or-bounded change ·
  acceptance check. (Preserve/scope stated only if non-obvious.)
- **Warning / optional note** → a one-line recommendation. No contract; do not inflate a 2px nudge
  into eight fields.

## Evidence tiers — how concrete the *Change* field must be

The prescription is only as specific as the evidence allows. Being honest about the tier is part of
the contract.

**Source and tokens available → exact edits.** Give the precise token, variant, class, or structural
edit, and name the **owning layer**: fix the call-site when only one use is wrong; fix the shared
token when every sibling consumes it. Do not patch one instance when siblings share the token; do not
rewrite a global token to correct a single call-site.

```
Replace (src/settings/Row.tsx:88, :141, :194):
  <Button variant="primary">          →  Save: keep variant="primary"
                                          Notify: <Switch …>  (existing component)
                                          Details: variant="ghost" + trailing chevron
                                          Disconnect: variant="outline"
Do NOT edit the global --button-primary token: Save is already correct.
```

**Screenshot only → relational prescription + bounded candidates.** You cannot see tokens or files,
so **never invent hex values, contrast ratios, file paths, or token names.** Prescribe the
relationship and give two bounded candidates plus the rule that chooses between them.

```
The selected tile needs one persistent non-colour channel.
  Candidate A: keep the current fill, add the established 1px selected border.
  Candidate B: deepen the fill by one existing neutral/brand ramp step and raise the
               label from regular to medium.
Choose A if borders already carry selection elsewhere in the product; otherwise B.
Do NOT add a checkmark unless the tile must stay identifiable outside its group.
```

**No design system exists → an explicit provisional draft.** Propose the missing rule as a clearly
*provisional* draft awaiting validation; the model may propose but may not present the proposal as an
approved system.

```
Proposed action hierarchy (PROVISIONAL — validate against content/platform before DESIGN.md):
  Primary: filled brand, one per decision region · Secondary: neutral outline ·
  Tertiary: text/ghost · Destructive: danger text/outline, spatially separated.
  Draft heights 44/36/36 · radii 8 controls / 12 containers · x-padding 16 primary / 12 compact.
```

## Command handoff (impeccable consumers)

A command (`$impeccable colorize`, `layout`, `polish`, …) is an **execution handoff after** the
repair is specified — never a stand-in for it. Name what changes, where, to what, and how success is
verified *first*; then, optionally, hand the specified change to a command to apply. "Run
`$impeccable colorize`" on its own is a routing note, not a prescription, and does not satisfy a
material finding.

## Acceptance-criteria rules

- Criteria must be **measurable and re-renderable** — e.g. "Save is the first action perceived in a
  squint and grayscale test," "no routine row action shares Save's visual mass," "every action keeps
  its 24px (web) / 44pt (touch) target," "focus/hover/pressed/disabled stay distinguishable" — not
  "hierarchy improved."
- Name the exact **views and states to re-render** to verify (widths, and default/hover/focus/
  pressed/disabled/error/loading/empty/selected as applicable).
- **Accessibility and correctness failures are mandatory fixes.** They are never routed to an
  override log or deferred behind a taste rationale.

## Portability and promotion

No field assumes a `DESIGN.md` or `tokens.json` exists — the "no design system" evidence tier is the
portable path when none is present. A prescription is a *proposed* change: do not promote it to
`DESIGN.md`, tokens, shared components, or a client guideline before cross-context validation and
explicit authorization. Specifying the repair is in scope for any review; persisting it is not.
