# 002 · Rule outcome tracking

**Status:** proposal, not implemented. Nothing here ships to installs: `proposals/`
sits outside `kit/` and `universal/`, as `eval/` does.

## Problem

The harness records *why* a rule was added, but never *whether it worked*.
`kit/core/learning/changelog.md` logs each promotion with the occurrences that
justified it and the check that enforces it. After that, the row is never touched
again.

So two later judgements are made from memory:

- **Retro §9, "what is now unnecessary".** Deciding a rule is dead scaffolding
  needs evidence that it stopped mattering. Today that is a feeling.
- **Generalising a lesson.** A lesson that "worked" gets reused, passed upstream,
  or promoted a rung. Nothing distinguishes a rule that held from one that landed
  in the same week as three other changes and a model upgrade.

## Design

### An "Observed effect" column

Add one column to `kit/core/learning/changelog.md`:

| Date | Change | Home | Occurrences that justified it | Check that enforces it | Approved by | **Observed effect** |
|---|---|---|---|---|---|---|

It is left empty when the rule ships. It is filled in **at a later retro**, never
the one that shipped it, from the evidence that retro gathered at §0.

Vocabulary, exactly four values, each followed by one line of evidence with dates:

- **helped** — the failure it targets recurred less, or not at all, over work
  that would have triggered it.
- **hurt** — it blocked correct work, caused a new failure, or was worked around.
- **no observed effect** — the work that would trigger it happened, and nothing
  changed either way.
- **confounded** — something else could explain the result.

**Prefer *confounded*** when several harness changes landed together, the model
or host changed in the same window, or a single run is all the evidence. It is
the honest default, not a failure. A row can move from *confounded* to another
value at a later retro once separate evidence arrives.

An empty cell after two retros is itself a finding: either the triggering work
never happened (say so), or nobody looked.

### What reads it

- **Retro §9** reads this column instead of judging from memory. A rule whose
  latest effect is *no observed effect* over two retros, with the triggering
  work present, is a removal candidate. *hurt* goes to the owner at §4 as a
  proposal to change or remove it.
- **Generalising.** A lesson that rests **only** on *confounded* rows is narrowed
  to the case it was seen in, or declined for promotion and for upstream feedback.
  The record says which and why.
- **Broken again** (findings) and *hurt* are related but different: the first is
  the rule failing to prevent its failure, the second is the rule causing a new
  one. Both route one rung up per §3.

### Universal harness

The universal harness has no per-rule changelog. Each retro writes one row to
`docs/retros.md`, and the change itself is a PR. The equivalent is either an
*Observed effect* column on a new small table in `docs/retros.md` (one row per
shipped rule, keyed by PR), or a line in the PR that shipped the rule, revisited
at the next retro. See open questions.

### Optional: reuse the shape for upstream feedback

The four fields that make a row useful, *situation / lesson / evidence /
confidence*, are the same ones an upstream-feedback proposal needs. Confidence
maps directly onto this vocabulary: a lesson whose rows say *helped* is offered
with high confidence, and one resting on *confounded* is either not sent or sent
labelled as such. The upstream-feedback procedure could require that field
instead of leaving confidence implicit. This is optional and separable.

## What it costs

- **Per retro:** one pass over rows shipped since the retro before last, a few
  minutes each, using evidence the retro already gathers at §0. No new script is
  required to start.
- **Always-loaded context:** none. `changelog.md` is on-demand, read at the retro.
  The retro procedure grows by about 10 lines (the vocabulary and the §9 rule);
  `candidates.md` or the changelog header carries the vocabulary once.
- **Check:** `check-kit.sh` could later verify the column exists and holds one of
  the four values or is empty. That is a follow-up, not part of the proposal.

## What it deliberately does not do

- It does not measure. There is no metric, dashboard or score. The value is a
  judgement with dated evidence, made at a retro by someone who can say
  *confounded*.
- It does not fill the column automatically, or at ship time. A rule's author
  rating it on the day it shipped is the bias this exists to avoid.
- It does not remove rules by itself. §9 still proposes; the owner still decides.
- It does not backfill. Rows shipped before the column existed stay empty, and
  that is stated rather than guessed.

## Open questions

- Is *two retros* the right window before an empty cell becomes a finding, or
  should it be tied to the triggering work occurring at least twice?
- In the universal harness: a table in `docs/retros.md`, or a revisit line on the
  PR? The first keeps one home; the second keeps the evidence next to the diff.
- Should a *hurt* value bypass the two-occurrence threshold for removal, since a
  rule that blocks correct work once is already costing?
- Does *probe before approve* (proposal 001) pre-fill anything here? Probably
  not: a probe is evidence before shipping, this column is evidence after.
