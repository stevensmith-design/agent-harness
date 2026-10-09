# Contract: Handoff

How work leaves this harness. The receiving side reviews against this document, so anything not in it is not agreed.

## First: is this one handover, or many?

**A handover has a cadence, and the cadence changes the artifact.** Getting this wrong is not a documentation problem — it produces a document that is correct and useless.

| | One-shot | Incremental |
|---|---|---|
| Shape | The work settles, then you hand it over | Each piece is handed over as it is signed off |
| Artifact | A snapshot | **A running agreement** |
| What the receiver needs | Everything, once | **Which parts are frozen and which are still moving** |

**Say which this is at the top of the document.** Most real handovers are incremental and get written as if they were one-shot, and the failure mode is specific: the receiver builds against a part that later moved, with nothing telling them it moved.

### For an incremental handover, two things are mandatory

**A status per item, not per document.** Proposed · agreed · implemented. Without it, the receiver cannot tell an agreed decision from a current guess, and will treat both the same way — usually as agreed.

**A record of what the receiver has already seen.** "Changed since you last looked" is the entire value of a running agreement, and it is the field that gets dropped first.

*(Both mechanisms probably already exist elsewhere in this harness — a requirement register or a status-tracked backlog does exactly this. Reuse that shape rather than inventing a second one.)*

## Required

- **What is being handed over**, and what state it is in
- **What was verified**, with denominators, and **what was not** — drawn from the human lane below, and including the latest checkpoint result (the checkpoint log (runs/.state/checkpoints), or the CI run in a repository)
- **The rules, not only the shapes** — see below
- **The foundations it depends on** — so the receiver knows what breaks it
- **Open questions and known gaps**, named rather than smoothed over
- **Who owns it now**, and who to ask

## The human lane — where "what was not" comes from

*"What was not verified"* is the field most likely to be written from memory, and memory shrinks it every handover. So it is not re-derived each time: it is drawn from a standing list.

**The human lane is the named list of what this harness's checks cannot reach.** Where it lives depends on the harness, so this contract does not fix a path. It fixes four things:

- **One place, named, and linked from every route that reaches it.** `../learning/findings.md` sends a `render` or `judgement` lesson here when no check can own it yet; a route to an unnamed destination is a rule with no enforcer (`../../PRINCIPLES.md` A9).
- **One owner, by name.** An unowned lane is D3's bare tick, written in prose.
- **Each line says what would be seen, and who looks** — *"totals on the printed page"*, not *"output quality"*. Same test the review contract applies to the failures it looks for.
- **A line leaves only when something in the harness now covers it, and it names that thing.** Dropping a line because nobody has hit it lately shrinks the lane while the gap stays — D5, reported as a pass.

**The lane is meant to get cheaper, not shorter.** Rendering the extremes into a fixture, measuring what can be measured, and handing the person a brief rather than *"please take a look"* all cut the cost of the looking without pretending the looking is done.

Each procedure's **Human gate** names its slice of the lane. The handover names the whole of it, as it stands.

## Shapes are necessary and never sufficient

The structured half of a handover — fields, types, required-ness, status codes, layout specs, token names — is the easy half, and the half tooling generates for you. **It is also not where the receiver's questions come from.**

The questions come from **domain rules**, which no structural format can hold:

- an action allowed once per relationship per day
- a record immutable after commit
- one state suppressing another on the same day
- an identifier written in one notation and not the obvious one
- the same error code meaning five different things at five different points

A generated schema expresses none of those and cannot be made to. **A handover carrying only shapes will be technically complete and will still produce a meeting.**

### Every rule names who enforces it

This is the field that turns a constraint list into a requirements list for the receiver:

| Rule | Enforced by | On violation |
|---|---|---|
| *(the invariant, in one line)* | producer · receiver · both | *(what happens, specifically)* |

**A constraint with no enforcement point is one both sides assume the other handles.** That assumption is invisible until it is wrong in production, and it costs more to find then than the row costs to write now.

## For a harness handover specifically

- The **fitness assessment** and what it concluded
- Which surfaces are at which rung, and **the trigger that would promote each**
- The **corpus** as it stands, and what it does not yet cover
- **What is deliberately not built**, and why — otherwise the next person builds it speculatively
- How to run the retro, and who runs it

Handover is in a form the receiving *team and their agents* can read — Markdown, not PDF. A handover an agent cannot parse defeats the point of the harness.
