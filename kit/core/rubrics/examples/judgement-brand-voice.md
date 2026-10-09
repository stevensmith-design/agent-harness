---
standard: brand-voice
title: "Voice conformance"
kind: judgement
covers: customer-facing writing — messages, proposals, collateral, posts
default_severity: fix
derived_from:
  - "this harness's brand and voice foundation files"
  - "the rejected examples in learning/corpus/rejected/ — the reasons, read first"
status: prose
---

# Voice conformance

**Example of a JUDGEMENT standard — and the kind most people actually need.**

Nothing below is measurable. There is no gate at the end of this rubric and there may never be one.
That is not a gap; it is the standard's nature, and pretending otherwise is how a harness ends up
with a check that scores the wrong thing confidently.

**This rubric starts at L1 and stays there until the corpus says what the rule is.** Its criteria
come from **what was actually rejected here, and why** — not from a theory of good writing. A voice
rubric written from general principles is a style guide. A voice rubric written from this
organisation's rejections is a standard.

**Worth stating plainly:** every criterion here is applied by a person, or by an AI reviewer reading
the corpus alongside it. The human gate is not a fallback for this rubric. It is the mechanism.

## How it fails in practice

**These are the rubric.** Each one should trace to a real rejection in the corpus.

- **Interchangeable** — the paragraph would work for any organisation in the sector with the name
  swapped. What you see: substitute a competitor's name and nothing breaks.
- **Fluent and empty** — clean, warm, and says nothing a reader could act on or repeat. What you see:
  nobody can summarise it afterwards.
- **Borrowed register** — the voice belongs to whatever the model reads most, not to the team. What
  you see: vocabulary nobody here uses, which nobody chose.
- **Unsourced claim** — a number or a superlative stated as fact. What you see: nobody can say where it
  came from, and it ships anyway.
- **Over-familiar** — warmth pitched at a relationship that does not exist. What you see: the
  recipient would find it presumptuous.

## What this protects

Trust that took years to build. The person whose name is on the message should not have to rewrite
it before sending; a recipient who knows the organisation should not hear a false note; and a
reviewer should be able to say *why* something is off, so the same correction is not made by hand
forever.

## Where it applies

- **Applies to:** a follow-up to a long-standing client that should reference something specific to
  them; a first-contact message where nothing specific is known yet — the hardest case, and where
  generic output is most tempting; collateral read by people who have read the rest of it.
- **Does not apply to:** internal notes; transactional messages with fixed wording, such as receipts
  or password resets; legal text, which answers to a different standard.

## Criteria

### could-only-be-us
**Rule:** the piece contains something only this organisation could have written.
**Severity:** blocking
**Answers:** interchangeable
**Meets:** a specific detail, decision or story traceable to a foundation file.
**Misses:** swap the name for a competitor's and it still reads correctly.

### specific-over-smooth
**Rule:** specificity is not traded away for polish.
**Severity:** blocking
**Answers:** fluent-and-empty
**Meets:** one concrete, slightly awkward, true detail survives the final edit.
**Misses:** the edit pass removed the only specific thing in it.

### register-matches-relationship
**Rule:** warmth matches the actual relationship, not an assumed one.
**Severity:** fix
**Answers:** over-familiar
**Meets:** first contact is direct and useful; a long-standing client gets the shorthand they have earned.
**Misses:** first contact opens with a familiarity nobody extended.

### claims-are-sourced
**Rule:** every factual claim, number or superlative traces to something.
**Severity:** blocking
**Answers:** unsourced-claim
**Meets:** the figure cites the foundation file it came from.
**Misses:** a plausible number nobody can locate.

### vocabulary-is-ours
**Rule:** terminology matches how people here actually speak.
**Severity:** fix
**Answers:** borrowed-register
**Meets:** the words appear in accepted examples in the corpus.
**Misses:** a register that showed up from nowhere and nobody chose.

---

## When this becomes checkable — and when it does not

Some of it will. `claims-are-sourced` becomes mechanical once claims carry citations — that is a
**structural** check hiding inside a judgement rubric, and worth extracting early.
`vocabulary-is-ours` becomes a banned-terms check once the corpus has enough rejections to fill the
list honestly.

**`could-only-be-us` and `specific-over-smooth` will not become checkable**, and a harness that
claims otherwise is lying to itself. The failure is invisible from the inside: a model optimising for
fluency cannot score its own output for distinctiveness.

**So this rubric's job is not to be automated. It is to make a rejection produce a reusable reason
instead of a feeling** — which is what turns the corpus from a folder of examples into a ratchet.
