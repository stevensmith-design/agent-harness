---
name: harness-decisions
description: Record product decisions that change direction, scope, or an agreed requirement — and maintain the do-not-re-propose list so a killed idea stays killed. Use when a product decision is made or reversed, when scope moves in or out, or when checking whether a proposal conflicts with a past decision, or when someone asks whether a behaviour is intended. Technical and architecture choices are /harness-adr.
license: MIT
metadata:
  harness.tier: product
allowed-tools: Read Glob Grep Write Edit Bash(git:*) Bash(ls:*)
---

# decisions

Product decisions, not architecture ones. `adr` owns *how we build it*; this
owns *what we agreed the product does, and when that changed*.

This exists because of a specific, expensive failure: an agent implements
something that was already decided against, gets it green, and it is reverted —
or strips something a client had confirmed, because nothing in the repo said so.

| Use it when | Do not use it when |
|---|---|
| Direction changes, or scope moves in or out | Choosing a library or a pattern — that is `adr` |
| An idea is killed, or a killed one is revived | Adjusting one screen's spacing or copy |
| A requirement is added, changed, or dropped | Something is still being discussed |
| Before implementing anything that feels contentious | Recording a bug fix |

**Owns:** `docs/product/decisions.md`, `docs/product/questions.md`, and
`docs/product/decisions/` for the long ones.

## The test

> **Would someone picking this up in three months be in trouble not knowing it?**

No → do not write it. Unsure → **ask** rather than guessing. Writing everything
down is the failure mode, not the safe option: a log full of small judgements
buries the part that actually works, and then nobody reads any of it.

**Record:** a feature added or removed · the direction of a feature changing ·
scope in or out · anything product-wide (naming, tone, terminology) · anything
agreed with a client or stakeholder · a reversal of any of the above.

**Do not record:** design micro-adjustments (a shade, a spacing value — the
tokens are the record) · implementation detail (names, file placement, refactor
approach) · one piece of wording · bug fixes · **anything still under
discussion**. A proposal is not a decision. A prototype is not a decision — it
earns a line the day it is adopted, not the day it is built.

The grey-zone rule: a design change counts if *the whole product looks
different* — a brand colour, unifying every CTA shape. One screen's adjustment
does not. The line is **one surface, or the whole thing.**

## Two tiers

**Tier 1 — one line, always.** Append a row to the current month's table. This
is the scannable record; details do not go here.

```markdown
## 2026-08

| ID | Date | Decision | Detail |
|----|------|----------|--------|
| DEC-009 | 08-12 | ❌ Admin export dropped from v1 | REQ-015 · scope |
| DEC-010 | 08-18 | 🔴 Export now includes archived records | [detail](decisions/archived-export-2026-08-18.md) · REQ-016 |
| DEC-011 | 08-21 | ✅ Confirmed: CSV only, no XLSX | REQ-014 |
```

**ID** — `DEC-NNN`, monotonic. Never reused, never renumbered, exactly like
`REQ-NNN`. The register requires a `DEC-` reference in its `Changed` column and
`docs/product/domain-rules.md` accepts one as a provenance key, so a decision
recorded without an ID is a citation four other files cannot resolve.

`🔴` changed direction · `✅` confirmed · `❌` killed or not adopted ·
`⏸` out of scope for now.

**Tier 2 — a file, only for the big ones.** `decisions/<slug>-YYYY-MM-DD.md`:

```markdown
**Logged:** 2026-08-18 · **Status:** confirmed · **Owner:** <name>
**Affects:** REQ-014, REQ-016

## The change in one line
## Before → After          (a two-column table)
## Why this is being recorded now
## Knock-on areas that need rework
## Open questions
## Related                 (requirement IDs, ADRs, PRs)
```

## Appending the line is not the job

The work is **chasing the knock-ons.** A decision that changes direction leaves
stale statements behind it, and those are what mislead the next agent:

1. Update the affected rows in `requirements.md` — supersede, remove, or
   reprioritise. Never edit an agreed statement in place.
2. Update `PRD.md` if the narrative is now wrong.
3. Note the affected specs. A spec built against a superseded requirement should
   say so at the top rather than be silently left standing.
4. If it kills an idea, add it to the do-not-re-propose list below. **This is
   the highest-value step in the whole skill.**

## Reversals are additive

Never delete or rewrite an old row. Add a new one, and annotate the old:
`→ reversed 2026-09-02`. The log is a record of what was believed and when. A
log you can edit is a log that cannot be trusted about anything.

## The do-not-re-propose list

At the foot of `decisions.md`, and the reason the file earns its place:

```markdown
## Decided against — do not re-propose

- **Group chat** — 2026-06-14 · out of scope for the platform, not a cost question
- **Admin export of member data** — 2026-08-12 · privacy review said no · DEC-009
- **XLSX export** — 2026-08-21 · CSV covers the need; revisit only if asked twice more
```

Each line: what, when, and the reason in a form that answers the question rather
than restating the decision. "Out of scope" tells the next person nothing and
they will raise it again.

**Read this list before proposing or implementing anything that resembles it.**
If what you are about to build is on it, stop and ask — do not implement, and do
not quietly re-litigate. That check is the difference between a log and a
decision *system*.

Reviving a killed idea is itself a decision: a new dated row, and the old line
struck through with a pointer to it. That is a legitimate move, made in the open.

## Questions — `docs/product/questions.md`

Decisions that have not happened yet, so they stop being rediscovered. Most
arrive after the code does: a tester asks *"is it intended that an inactive
customer can be edited?"*, *"a scale accepts text — OK?"*, *"two edit buttons —
on purpose?"*. Those are not bugs and not decisions. They are the spec's gaps,
found by someone using the product.

1. **Log it** — a `Q-NNN` row, `open`, with who raised it. Do not answer it by
   implementing something: an agent that picks an answer has invented a rule.
2. **Get it decided** by whoever owns the product call.
3. **Close it into a rule** — a `DEC-` here, an `INV-` in `domain-rules.md`, or a
   `REQ-`. The answer goes where the implementer and the agent read, not into
   the ticket where the question was asked. Then the next screen that breaks the
   rule fails a test instead of raising the same question again.
4. If no rule is needed, close it `not-a-rule` and say why.

`make check-learning` reports a `decided` row that cites nothing, or cites an ID
that has no row — and fails on it once `product.enforce_learning` is on. Questions open past `product.question_stale_days` are reported
there and counted by `make retro-evidence` — each is a gap paid for again on
every screen that raises it.

Before logging, search the register: the same question from a different screen
is a `duplicate`, and a pattern of them is one rule missing, not five.
