---
name: ui-design-review
description: >
  Review completed UI screens, screenshots, rendered HTML, Figma output, frontend files, or
  UI-focused diffs for visual quality, consistency, accessibility, and unjustified AI-style
  patterns. Use for “review this screen”, “is this ready to ship?”, client handoff, or a
  per-screen/per-PR quality gate. Run visual review for pixels and code review for files; combine
  them when both exist. Use ui-design-system instead for creating/extracting a system or auditing
  whole-app coherence and drift. Use impeccable-review for a whole-app scored critique or a
  read-only preview of an impeccable command. Use ui-design-principles during implementation.
---

# UI Design Review

Read-only quality gate for completed UI. A request to review does not authorize edits, design-doc
updates, snapshots, candidate logs, or exception entries — this holds even when the user asks you,
mid-review, to "just add the exception" so a scanner stops flagging. Authoring an override or
exception in the same pass that reviews the pattern is a self-authored, same-change override: the
justification and the thing it authorizes get written together, which is exactly what the gate
exists to stop (see gate question 6 below). The favour the user is asking for is the trap. Instead,
surface the exception as a labeled proposal for a separate, human-authorized decision that pre-dates
any future use, and leave the write to that later step — then the review stays read-only and the
override, if made, is legible rather than self-granted.

## Required dependencies

- `.agents/skills/ui-design-principles/references/rules.md` is the canonical rulebook. This skill's mirrored
  `references/rules.md` must remain byte-identical.
- `scripts/validate-tokens.py` owns deterministic token-relationship checks.
- If a dependency is unavailable, continue with the evidence available and mark the affected
  checks **[Not assessable]**; do not invent a substitute rule.

**Paths are fixed.** Every skill and reference named here lives at a known location in this
harness — `.agents/skills/<name>/` for skills, `scripts/validate-tokens.py` for the validator.
Do not guess a root, do not search for a copy. A path that does not resolve means the harness
is incomplete: say so and stop, rather than marking the check unassessable and continuing.

## Review model

Always assess three layers:

1. **Existence** — are type, colour, spacing, radius, component, and state rules defined?
2. **Quality** — are those rules sound together: contrast, hierarchy, scale, semantic roles,
   interaction geometry, and aesthetic coherence?
3. **Application** — does the implementation use them consistently, without unexplained drift?

Check for `DESIGN.md`, equivalent design guidance, and `tokens.json`. A current approved contract
is strong evidence, but it cannot waive accessibility/correctness. A shipped one-off can be drift.

Every adverse finding states:

- **Evidence:** `[Verified]`, `[Inferred]`, or `[Not assessable]`
- **Basis:** standard/correctness, project contract, established principle, heuristic/taste, or
  UX/product hypothesis
- **Scope checked:** local instance, shared component, and representative siblings
- **Repair prescription:** the smallest compatible change, specified implementation-ready per
  `references/repair-prescriptions.md` — cause/owner, preserve, exact-or-bounded change, scope, how,
  acceptance criteria. Scale to severity and to available evidence; a material finding without one is
  incomplete.

Only a standards/correctness defect or broken current project contract automatically fails
Correctness. Heuristics are optional notes. UX/product hypotheses are handed off, not presented as
UI defects.

## Mode routing

- **Visual review:** screenshots, rendered app/HTML, Figma, “review this screen”, sign-off.
  **Read `references/visual-checklist.md` before reviewing.** This is mandatory even for a single
  screenshot; do not rely on memory or the scanner.
- **Code review:** PR, diff, component files, automated hook. **Read
  `references/code-review.md` and run `scripts/scan.sh`.**
- **Both available:** run both, reconcile evidence, and issue one verdict.
- **System-level:** create/extract/audit coherence/drift across the product → `ui-design-system`.
- **Structural findings:** when the issue is navigation, grouping, labels, information scent, or
  progressive disclosure, run `ia-review` alongside this skill. Keep its structural verdict
  distinct from the visual verdict so a visually polished screen cannot silently pass broken IA.

## Visual-review procedure

1. Render the runnable target and capture the actual states/screens. If it is runnable but cannot
   be rendered, open with a **DEGRADED** banner. Use faithful project fonts; otherwise mark type
   judgments `[Not assessable]`.
2. Read and execute every required audit in `references/visual-checklist.md`, beginning with the
   compact-control geometry audit. A token-validator PASS or scanner PASS is never visual sign-off.
3. When `tokens.json` exists, run:

   ```bash
   python3 <ui-design-system-path>/scripts/validate-tokens.py <project-dir>
   ```

   Fold FAILs into Layer 2. Without tokens, measure visible contrast pairs manually when source
   colours are known; screenshots alone may be insufficient for exact ratios.
4. Inspect relevant states and representative siblings. Never fix one tab, pill, tile, or row in
   isolation without checking the equivalent components around it.
5. Use the report and verdict rules in `references/report-and-verdict.md`.

### Non-negotiable visual judgments

The five non-negotiables — hit-target-vs-visible-size, compact-action subordination, ordinary button
text at 4.5:1 (large-text exception only when size/weight proves it), minimum-sufficient state
signal, and accessibility-is-not-an-override — lead `references/visual-checklist.md` as **section 0
(read first)**. A green scanner/validator is never visual sign-off.

## Code-review procedure

Read `references/code-review.md`. Run the scanner on the requested scope, then perform its manual
consistency sweep because regex cannot judge dynamic styles, token drift, shared-state divergence,
visible geometry, or aesthetic coherence.

```bash
bash <ui-design-review-path>/scripts/scan.sh --staged
bash <ui-design-review-path>/scripts/scan.sh --diff main
bash <ui-design-review-path>/scripts/scan.sh <file-or-directory>
```

Project exceptions require an id in `scan-exceptions.conf` that resolves to a current DESIGN.md
override entry **whose decision pre-dates the use it authorizes**. An exception without that
governance is a violation — and so is one whose override entry was created in the same change as the
pattern it authorizes: a "purpose" the author writes for their own change is self-authored
justification, not legibility, so it does not clear the gate (gate question 6). When reviewing a
diff, treat a gradient/pattern whose only authorization is an override entry added in the *same*
diff as an unresolved finding, not a cleared one — the ship-the-flat-default form and hand the
exception to a human to ratify. Tier-2 overrides cannot waive Tier-1 accessibility/correctness.

## Verdict rules

Read `references/report-and-verdict.md` and rate Correctness, Consistency, Contextual fitness, and
Craft.

- **SHIP IT:** no material failures; optional notes only.
- **MINOR FIXES:** one or a few bounded, understood local defects with no systemic redesign needed.
  This may include an isolated correctness defect such as one known contrast pair when the fix and
  blast radius are clear.
- **MAJOR REVISION:** systemic or repeated correctness failure, two or more dimensions fail,
  governing rules/tokens need rethinking, or the safe fix is unresolved.

Never issue MINOR merely because a report is long, and never issue MAJOR solely because the word
“accessibility” appears. Severity follows impact, spread, uncertainty, and required scope.

**Record actual coverage in the verdict.** State the real viewport widths rendered (e.g. desktop
1440px, mobile 390px — not "responsive checked") and the interaction states observed (default, hover,
focus, active, disabled, error, loading, empty, selected). Any width or state not rendered is named
`[Not assessable]`, never assumed to pass.

**Worked finding + verdict line:**

> **[Consistency · Major] Selected tab invisible on the settings surface.** `[Verified]` at 1440px
> and 390px, default + selected states. Evidence: the active tab uses `bg-teal-50` on a `teal-50`
> canvas — 1.02:1, no second signal; siblings render identically, so it is systemic not local.
> Basis: standard/correctness (state meaning). Scope: shared Tabs component, 3 instances. Smallest
> fix: add the token's value-step fill + a weight change; re-render all three.
> **Verdict: MAJOR REVISION** — a state relied on by every settings screen fails to communicate.

## Applying changes

Do not modify source during a review. If the user separately asks to implement findings, use
`ui-design-principles`, inventory sibling contexts first, apply the smallest compatible change,
and re-render the target plus representative siblings.

## Closing step

Read `references/promote-findings.md` and classify lessons, but keep the review read-only. Propose
project decisions or generalizable candidates; persist them only with explicit authorization.
Never self-edit shared rules based on a single review.

## Tooling maintenance

Any scanner change requires a failing fixture before code and the complete suite:

```bash
bash <ui-design-review-path>/tests/run.sh
```

The qualitative cases in `tests/decision-regressions.md` must also remain satisfied. Keep
`references/rules.md` mirrored with the principles skill and `references/repair-prescriptions.md`
mirrored with the impeccable skill (`tests/check-mirror.sh` enforces both).
