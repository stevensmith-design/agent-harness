# Component integration — adopting a component without a second design language

Read this before an **external** component (a shadcn/registry component, a copy-in library, a
snippet from a reference) or a **newly created** component enters the shared system. The goal is to
absorb useful behavior without importing a parallel token system, idiom, or motion grammar. Match
the ceremony to the size of the change — the three tiers below.

## Contents

1. Tier A — existing-family adaptation
2. Tier B — external component or new behavior
3. Tier C — new component idiom or library
4. Promotion gate (when adoption must fail)
5. Before promotion

## 1. Tier A — existing-family adaptation

A new variant or small extension of a component that already exists (another `Button` variant, a
denser list row). Keep it lightweight:

- reuse the authoritative primitive; do not fork it;
- consume existing tokens (no new colour, radius, or spacing value unless the system defines it);
- verify the states this change actually touches;
- check representative siblings so the variant stays in family;
- render it in context.

No full promotion record. A Tier-A change that finds itself introducing new tokens or a new idiom is
really a Tier-B or Tier-C change — escalate.

## 2. Tier B — external component or new behavior

An external component adopted as-is, or a genuinely new interaction the system hasn't had. Do
everything in Tier A **and** record:

- **semantics + keyboard** — roles, focus order, keyboard operation preserved;
- **state vocabulary** — enabled/hover/focus/pressed/selected/disabled/loading/error/empty as
  applicable, mapped to the system's existing state signals;
- **responsive behavior** — compact/expanded, text scaling, long localized labels;
- **geometry & density** — height, padding, radius, and information density match the family;
- **icons & motion** — one icon family, one motion grammar; no imported easing or icon set;
- **portals, overlays, scroll & z-index** — layering resolves through the system's z-index ramp;
- **dependencies & licensing** — bundle cost and license are acceptable and recorded.

## 3. Tier C — new component idiom or library

A new *idiom* for a control the system already has (a second dialog model, a second selection
paradigm) or a whole library. This is the highest-risk adoption. Require:

- the complete **compatibility matrix** (every Tier-B dimension, filled, not skimmed);
- the `ui-design-system` **promotion gate** (token mapping, coherence check, validator run);
- **representative-screen integration** — build it into real screens, not a demo;
- an **app-wide consistency review** (`impeccable-review` whole-app lane) before package sign-off.

## 4. Promotion gate — adoption must FAIL when the candidate introduces

- a **second idiom** for the same control (two dialog models, two selection paradigms);
- an **independent token or theme system** running beside the project's;
- **conflicting state behavior** (its "selected" contradicts the system's);
- **incompatible geometry or density** that can't be reconciled through tokens;
- **inaccessible semantics** (div-buttons, lost focus, missing names) — never waivable;
- **unexplained visual or motion language** with no role in the committed direction.

A failed gate is not "restyle later" — it is *do not promote until reconciled*. Restyling hides a
parallel system; it does not remove it.

## 5. Before promotion

Test the candidate **locally, against its family, on representative screens, and across the app**
before it becomes a shared component. Restyle through project tokens; preserve its semantics, focus,
and keyboard behavior. Each surviving defect becomes a repair prescription in the coherence backlog
(see `mode-coherence.md` and the review skills' `repair-prescriptions.md`), not a vague "make it
consistent."
