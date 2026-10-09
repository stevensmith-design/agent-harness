# Reference intake — external sources as evidence, not authority

Read this reference when the user supplies or names an external source as input to a design decision:
a live site, a screenshot, a component library, a design-system file (e.g. a `DESIGN.md` found
online), or a style recommender. It is a **discipline, not a fetch**: no network access is required,
and a source that cannot be opened stays explicitly *unverified* rather than blocking the work.

## Contents

1. The intake packet
2. Source roles (routing)
3. Rules
4. Handoff

## 1. The intake packet

Record this before letting a reference influence the design. Keep it short; the point is provenance
and an explicit boundary, not a dossier.

- **Source & role** — what it is and which role it plays (§2).
- **Retrieval & provenance** — date; whether you actually inspected it or are working from the
  user's description. If you could not open it, mark it **unverified** and say so.
- **Evidence inspected** — the specific screens, tokens, or components actually examined (not the
  brand's reputation).
- **Transferable principles** — the *relationships* worth taking: spacing rhythm, contrast
  discipline, a hierarchy device, a motion grammar. Never the identity.
- **Rejected elements** — what you are deliberately not taking, and why (imitation, AI tells,
  off-brand, inaccessible).
- **Fit** — task, platform, content, and brand fit assessed against *project* evidence.
- **Risks & unknowns** — accessibility, performance, provenance, licensing.
- **Mapping** — how an accepted idea lands in project tokens / components / layout / motion.
- **Validation required** — what must be checked before anything is promoted.

## 2. Source roles (routing)

| Source | Portable role |
|---|---|
| **getdesign.md** / a found `DESIGN.md` | Unverified design-system *hypothesis* — never an approved contract |
| **shadcn/ui** | Component behavior + implementation primitive → defer to the installed shadcn skill |
| **Relume** | Marketing IA, sitemap, and wireframe candidate → `ia-review` |
| **React Bits** and copy-in effect libraries | Gated single-signature-motion candidate → `impeccable` `animate.md` gate |
| **GSAP** | Complex-motion implementation, after the motion concept is approved → `animate.md` gate |
| **ui-ux-pro-max** | Searchable style/direction candidate retrieval → `design-directions.md` §5 |
| **Screenshot / live site** | Visual evidence requiring provenance and an explicit scope of what was seen |

## 3. Rules

- **Sources are evidence, not authority.** Current project evidence, authoritative components,
  platform convention, accessibility, and this skill's decision gates win any conflict with a
  reference.
- **Compare, don't copy.** Prefer two or three references and extract the shared *relationship*;
  a single source copied wholesale imports its identity. Explicitly refuse "make it look like
  Linear / Stripe / Apple" — reproduce the *reasoning*, not the trade dress.
- **A found `DESIGN.md` is a hypothesis.** Never install a third-party design-system file as the
  approved project contract unchanged. Verify it against the real source when reachable, then
  synthesize an original, project-specific system via `ui-design-system`.
- **No required network.** If a source cannot be opened, mark it unverified, work from what is
  inspectable, and name the gap — do not fabricate what the source "probably" says.
- **No embedded catalogues.** Route to the source; do not inline a vendor's component or style list
  into the skill (it ages and bloats context).
- **Third-party component code** (shadcn registries, copy-in effect libraries) is code review, not
  design intake: check source, dependencies, security, accessibility, and visual fit before
  adoption, and restyle through project tokens rather than accepting default styling.

## 4. Handoff

Once the packet is recorded, route the accepted idea to the skill that owns its execution:

- structure / sitemap / wireframe candidate → `ia-review`;
- component adoption → `ui-design-system` → `references/component-integration.md` (tiered A/B/C);
- motion (GSAP, React Bits) → `impeccable` `reference/animate.md` gate;
- style / direction candidate (incl. `ui-ux-pro-max`) → `design-directions.md`.

The reference proposes; project evidence and these skills adjudicate.
