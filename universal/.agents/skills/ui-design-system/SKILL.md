---
name: ui-design-system
description: >
  Create, extract, audit, or verify a project's design system as a whole. Use for greenfield
  DESIGN.md/tokens, extracting implicit rules from an existing app, diagnosing cross-screen
  incoherence, checking token relationships, or finding drift from DESIGN.md/tokens.json.
  Triggers on “set up/extract/audit the design system”, “why does nothing look consistent?”,
  “check for drift”, or a missing system that must be established before substantial UI work.
  Every mode runs the token validator. Use ui-design-principles to build a screen and
  ui-design-review to review one screen or PR; this skill owns the system above them.
---

# UI Design System

The system-level skill. `ui-design-principles` guards the making of a screen; `ui-design-review`
audits a finished screen; **this skill owns the design system the other two depend on** — the
tokens, their *relationships*, and the four-layer `DESIGN.md` that records the reasoning.

It exists because a screen can pass every element rule and the product can still feel incoherent.
Contrast, selection-vs-action distance, semantic-colour distinctness, ramp derivation, scale ratios
— these live *between* tokens, where regex-over-components can never see them. This skill makes those
relationships explicit and checks them with math.

**Dependencies.** The canonical DESIGN.md template and rulebook live in
`.agents/skills/ui-design-principles/references/`; code-side drift detection lives in `ui-design-review`. Locate
sibling skills through the harness/project configuration rather than assuming one
installation root, and print the resolved path as evidence. If a sibling is unavailable, report the
missing coverage instead of copying its logic.

---

## The token-graph validator (runs in every mode)

`scripts/validate-tokens.py` is the engine. It reads a project's `tokens.json` (and `DESIGN.md` if
present), resolves references, classifies colours into roles by name, and computes the relationships
that live *between* tokens — contrast pairs (including the recurring **CTA-label-on-CTA** miss),
selection ≠ action distance, semantic-colour distinctness, the neutral ramp's hue, the
background↔card value step, type-scale ratios, elevation monotonicity. The **full computed-check
catalog, exit codes, and coverage semantics are in `references/validator-checks.md`**; dated
per-check provenance is in `references/validator-rationale.md`.

```bash
# Discover the validator from the active catalog/config, then run it (do not hard-code a root):
python3 <resolved>/validate-tokens.py <project-dir>
# or: --tokens PATH [--design PATH]   ·   --json for machine-readable output
#     --theme PATH   diff shipped theme CSS against tokens.json (Drift mode; see references/mode-drift.md)
#     --strict       required-role coverage becomes FAIL, not silent SKIP (Create gating)
# Behaviour is locked by tests/run.sh (30/30 fixtures) — run it after any validator change.
```

**Caveat.** A PASS means the token *relationships* cohere — it is **not** visual sign-off. It cannot
see layout, rhythm, imagery, or whether the aesthetic is any good. It is the floor; the five-question
coherence test (`references/mode-coherence.md`) and `ui-design-review` are the judgment on top. If
the validator cannot be found or run, report relationships **UNVERIFIED** — never claim PASS.

---

## The four-layer DESIGN.md

A design system is not a token dump. It is four layers — **Intent · System principles · Tokens &
component rules · Relationships & rationale** — and the fourth (why the values cohere) is the one that
usually goes missing, which is why systems drift and feel assembled. Every mode reads, writes, or
verifies this structure. The full layer table, the **evidence-and-authority order**, and the
**system-promotion gate** are in **`references/design-system-layers.md`**. The canonical template is
`.agents/skills/ui-design-principles/references/design-system-template.md` (do not fork it).

---

## Mode detection

| Mode | Use when | Produces | Steps |
|------|----------|----------|-------|
| **Create** | Greenfield. No system yet; establishing one before real UI is built. | A four-layer `DESIGN.md` + `tokens.json`, validator-green | `references/mode-create.md` |
| **Extract** | An existing codebase with implicit rules and no (or stale) `DESIGN.md`. | A `DESIGN.md` reverse-engineered from real usage + a drift list | `references/mode-extract.md` |
| **Coherence audit** | Elements each look fine but the screens feel incoherent, generic, or "assembled." | A coherence verdict across seven axes + the five-question test | `references/mode-coherence.md` |
| **Drift** | A `DESIGN.md`/`tokens.json` exists; checking whether shipped UI still matches it. | A drift report: token expected vs value found | `references/mode-drift.md` |

If unsure between Extract and Coherence audit: Extract when there is no written system to compare
against (you are *establishing* the baseline); Coherence audit when a system exists (or you just
extracted one) and the question is whether it *hangs together*.

**Boundary.** Designing one screen → `ui-design-principles`. Reviewing one screen's rendered output →
`ui-design-review`. This skill is only for the system as a whole. Flow/IA structure (navigation,
grouping, labels) → `ia-review`.

**Adopting an external or newly created component** into the shared system →
`references/component-integration.md` (tiered A/B/C). A candidate that introduces a second idiom, a
parallel token system, or a conflicting state model must not be promoted until reconciled.

Load only the mode reference the request needs; every mode still runs the validator and reads
`references/design-system-layers.md`.

---

## Closing step — feed findings back (shared, approval-gated)

**One canonical rule for every mode:** a request to review/audit is read-only; creating or updating a
system authorizes only the named deliverables, never unrelated files; every other project-file or
shared-file write needs explicit approval. The shared substrate propagates to every project, so an
unreviewed edit there spreads a mistake everywhere — **log candidates, never self-promote.**

Applying that rule:

- **Project decisions** (a token, a DESIGN.md rule, a scan-exception) → propose the exact change, run
  the system-promotion gate (`references/design-system-layers.md`), and apply only when the task
  authorizes system updates or the user approves it. Record a changelog only when persistence is
  authorized.
- **A generalizable rule** for shared `rules.md`, **or** a new mechanical check for `scan.sh` /
  `validate-tokens.py` → propose a candidate for the project's configured review candidate log (if
  one exists). Do not assume a `docs/` path or persist during an audit without authorization. A
  validator check is promoted only after its `pass/` + `fail/` fixtures pass, exactly like a `scan.sh`
  check.
