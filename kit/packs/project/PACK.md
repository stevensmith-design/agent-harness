# Pack: Project

**Status: sketch.** Inferred from the anatomy alone, and the least trustworthy pack here.

The honest position: a project harness may not be a domain pack at all. It may be **the coordination layer that sits above several domain harnesses** — which would make it a different kind of thing, and building it as a pack would be a category error.

Decide that before building it.

## What is known

**The verbs:** status freshness · decision-log completeness · dependency and blocker checks · whether commitments have owners and dates.

**The foundations:** scope and non-goals · the commitment register (where status lives) · the decision log · stakeholders and who decides what · dependencies · the actual capacity of the people involved.

**Starting rung: L1.** Some of it is mechanically checkable and unusually cheap — a commitment with no owner, a status untouched in three weeks, a decision with no revisit trigger are all greppable. That may be the fastest L2 in any domain, if the register is structured.

## The one rule that transfers

**Status lives in exactly one place, and the narrative document holds no mutable state.**

This is a lesson from the dev pack that transfers directly. A harness's product layer should split a narrative PRD from a register where status lives, precisely because status inside a narrative document goes stale invisibly and nobody can tell which paragraph is current.

Rows in the register are never deleted; reversals are additive.

## What is unknown

- Whether the project harness *owns* surfaces or *inherits* them from the harnesses it coordinates.
- Whether "human gate" means anything different here, where almost everything is already a human decision.
- Whether the ratchet has a corpus at all, or whether retrospectives serve that role — and if so, what a judged example even looks like.
