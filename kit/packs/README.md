# Domain packs

> **A pack is a description of what varies, not a library of domain content.**
>
> The temptation is to grow each pack into a catalogue — rubrics, templates, checklists per domain.
> That builds N domain-specific kits wearing one coat, and the next domain you walk into is always
> the one nobody catalogued. **The kit stays universal by shipping the method and deriving the
> content**: `core/rubrics/` carries the authoring method and three exemplars covering three *kinds
> of standard*, and a rubric for a domain nobody has seen is derived from that team's own
> foundations and rejections.
>
> A pack earns files only where the content is **externally standardised** — WCAG, ISO date and currency
> formats, a regulatory requirement — because that content genuinely transfers between organisations.
> Anything organisation-specific is derived, never shipped.

The core template is the anatomy with nothing domain-specific in it. A pack supplies the three things that actually vary:

1. **The verbs** — what "check" means here
2. **The foundations** — what the AI must not invent in this domain
3. **The starting rung** — which follows from whether the standard is scorable yet

**Motion first, domain second.** Run the kit's `./detect.sh` against the target: it decides which of three motions applies and fails closed toward the one that writes least.

| Motion | Read |
|---|---|
| **greenfield** — nothing exists | straight to the domain pack |
| **scattered** — AI material exists, it is yours, nothing organises it | [`_scattered.md`](_scattered.md) — the commonest real starting state |
| **overlay** — it exists and belongs to someone else | [`_overlay.md`](_overlay.md) | Its rules are materially different and getting them wrong damages a client's existing work.

## No pack for your domain? That is the normal case

**Five packs exist. There are not five domains.** A pack is a shortcut for a domain someone has
already run an engagement in — not a licence to work in it. For anything else,
[`_deriving.md`](_deriving.md) derives the same three variables from the user's own context, and
nothing downstream can tell the difference: `harness-build` consumes the variables, not the file
they came from.

The failure this prevents is telling someone their domain is not supported. The kit designs
harnesses. It does not stock domains.

## Status — read this before relying on a pack

| Pack | Status | Reference |
|---|---|---|
| [`dev/PACK.md`](dev/PACK.md) | **Complete** | `universal/` in this repository |
| [`design/PACK.md`](design/PACK.md) | **Complete** | — |
| [`business-development/PACK.md`](business-development/PACK.md) | **Complete** | — |
| [`marketing/PACK.md`](marketing/PACK.md) | **Sketch** | Not yet exercised |
| [`project/PACK.md`](project/PACK.md) | **Sketch** | Inferred from the anatomy alone |

**Complete** means the pack covers all three variables for its domain. **Sketch** means it is a starting hypothesis — see below.

**What a pack is, today:** a document describing the three variables for its domain, plus a pointer to a reference implementation where one ships with the kit. **It is not yet a set of files you can copy.** Applying a pack currently means reading it and making the decisions it names. Turning the three complete packs into copyable file sets is the largest single piece of unbuilt work in this kit.

The sketches are marked as sketches deliberately. A pack that claims more than it has is the same defect as a config key nothing reads — it looks like capability to anyone skimming. **Build a sketch out when a real engagement demands it, not before.**

**And prefer derivation over a sketch.** For `marketing` and `project`, [`_deriving.md`](_deriving.md) is the better path: a sketch is inference wearing the same format as evidence, so an agent reads inferred lines with the authority of a proven pack. Derived-from-their-context beats inferred-from-the-anatomy every time. A sketch is a lead for the person deriving, never a substitute for doing it.
