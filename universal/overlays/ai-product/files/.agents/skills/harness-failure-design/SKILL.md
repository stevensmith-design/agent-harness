---
name: harness-failure-design
description: Design what the product does when the AI gets it wrong — which failure types apply, what the user sees, what they can do next, and whether the action can be undone. Use before finalising any AI feature's success path, before launch, and whenever a new failure mode surfaces in testing or production.
license: MIT
metadata:
  harness.tier: ai
  source: Steven Smith, AI Product Design System — Failure Design Worksheet
allowed-tools: Read Glob Grep Write Edit
---

# failure-design

**Most AI products design for the success path. This designs for everything else.**

An AI feature has failure modes ordinary software does not, and the worst of them
produce output that is indistinguishable from success. You cannot handle those
with a `try/catch`. They have to be designed.

| Use it when | Do not use it when |
|---|---|
| Before the success path is finalised | Handling an exception — that is ordinary error handling |
| Before launch, as a check that failures were designed, not just anticipated | The feature has no model in it |
| A new failure mode appears in testing or production | You have not decided what the feature does yet |

**Produces:** a table with a row per applicable failure type and four decided
columns. A decision, not a principle: "hedge policy answers with a source link
and a timestamp", never "we'll communicate uncertainty".

## Step 1 — Which of these apply?

Mark each **Yes / No / Sometimes**. These are AI-specific; a taxonomy that only
lists technical errors has missed the point.

| Failure type | What it is |
|---|---|
| **Hallucination** | Generates plausible but factually incorrect information |
| **Overconfidence** | Presents an uncertain or wrong output with unwarranted certainty |
| **Silent failure** | Fails with no indication — the user gets a wrong or empty output and does not know |
| **Scope failure** | Asked something outside its reliable range, and answers anyway |
| **Misunderstood intent** | Addresses a different problem than the user meant |
| **Stale output** | A correct-seeming answer built on outdated information |
| **Cascading error** | An error in one step propagates and compounds through the next |
| **Partial completion** | Starts a task, makes progress, fails midway, leaves the user in an incomplete state |
| **Alignment error** | Does exactly what it was asked, correctly — and that was the wrong thing to ask for |

Add product-specific types. **Partial completion and cascading error are the two
most often skipped** — the first leaves ambiguous state, the second is small and
recoverable at the moment it happens and expensive by the time anyone notices.

**Alignment error is the one with no vocabulary**, which is why it goes
unnamed in most failure work. It is not misunderstood intent (the AI misread the
request) and not scope failure (the request was outside its range). The request
was read correctly, answered correctly, and the objective itself was wrong: a
summariser told to be concise drops the caveat that mattered; an assistant
optimised for resolution time closes tickets the customer does not consider
resolved. It is a design failure wearing a success costume, and it is invisible
at the level of a single interaction.

## Step 2 — Four decisions per applicable type

**Detection — will the user know it happened?**
Decide whether the product can detect this failure at all, or whether detection
depends entirely on the user noticing. *The most dangerous failure is one that
looks like a success.* An undetectable failure is the highest priority to design
an explicit safeguard for, not the lowest.

Alignment errors are a special case: **nothing at the interaction level can
detect them**, because every check the system runs says it succeeded. They show
up only in aggregate outcomes — the metric moves and the thing the metric stood
for does not. So the safeguard is never a runtime check. It is a named owner
watching an outcome measure that is *not* the one being optimised.

**Presentation — what does the user see?**

| Approach | When |
|---|---|
| **Explicit failure** — say something went wrong | The failure is detectable and the stakes justify interrupting |
| **Graceful degradation** — a reduced but still useful response | Partial output beats nothing, and the limit can be signalled clearly |
| **Silent fallback** — switch to an alternative without surfacing it | Only for low-stakes, easily reversible cases where the fallback is genuinely equivalent |

**Recovery — what can they do next?**
Every failure state needs a forward path. **"Contact support" is not a recovery
path — it is an exit.** Real ones: retry with a modified input · escalate to a
human with context carried over · show what the AI *can* do · undo to a known
good state · open the raw source it was working from.

**Rollback — can the action be undone?**
Only for failures where the AI *acted*, not merely produced output.

- **Full** — completely reversible
- **Partial** — some effects reverse, others do not
- **None** — irreversible, **and this requires a much stronger approval step
  before the action.** If there is no rollback and no approval gate, that is a
  design gap, not a risk to accept.

## Step 3 — The silent failure test

Run this on every type before finalising. For each one, write the *exact* user
experience — the screen, the message, the output.

**If the answer is "the same thing they would see if it succeeded", that is a
silent failure and it needs a design decision.**

Silent failures damage trust more than loud ones because the user discovers them
alone, later, with no context and no explanation.

## Closing rules

Resolve all of these before the design is done:

- No failure type answered with **"users won't notice"**. They will, eventually,
  and they will find out without you.
- No recovery path that **exits the product**.
- No **irreversible action** without an approval step before it.
- No type whose presentation decision is **"we'll handle it"**.
- Every **alignment error** has a named counter-metric and someone who reads it.
  "We'll notice" is not a detection strategy for a failure that looks like success.

## Done

- Every type marked Yes or Sometimes has all four columns decided.
- Every decision is specific enough to build from — a designer could draw it.
- The silent failure test has been run on every type, and any that failed it now
  have a design decision.
- Anything unresolved is recorded as an accepted risk with a named accepter, not
  left blank.

A worked example against a real feature shape is in
`references/worked-example.md`.
