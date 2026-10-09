---
name: harness-eval-design
description: Write evals for a model-backed feature — decide what to measure, build a case that can fail, and set a threshold you would actually act on. Use before writing a prompt, when a model-backed feature changes, or when someone says "it seems better now".
license: MIT
metadata:
  harness.tier: ai
allowed-tools: Read Glob Grep Write Edit Bash(make:*) Bash(git:*)
---

# eval-design

An eval is a test for behaviour you cannot assert exactly.

The failure this prevents is specific: a prompt gets tweaked, three examples look
better, it ships, and nobody finds out for six weeks that a fourth case regressed.
Without evals the only feedback is a user complaint, and by then the change that
caused it is twenty commits back.

| Use it when | Do not use it when |
|---|---|
| Before writing the prompt for a new feature | Testing deterministic code — that is `writing-tests` |
| A model, prompt, or retrieval index changes | Checking an API returns 200 |
| Choosing between two models — see `model-choice` | The output has one correct string; assert it |
| Someone says "it seems better now" | You have not decided what "better" means |

## Write the eval before the prompt

Not for purity. Because writing the eval is how you find out what you actually
want, and a prompt written first anchors the eval to what that prompt happens to
do. You end up measuring your first draft.

## The four kinds, in the order they earn their keep

1. **Assertions** — a property that must hold every time. The output parses as
   JSON. It never contains another customer's id. It cites only documents that
   were in the context. Cheap, deterministic, and catches the failures that
   actually hurt. Most features need only these.
2. **Golden cases** — an input with a known-good output, compared by a rule you
   can state: exact match, contains, matches a schema. Few, and chosen because
   they are hard.
3. **Rubric grading** — a second model scores the output against written criteria.
   Use only when the quality is genuinely subjective, and treat the grader as a
   component you also have to evaluate: run it against cases with known scores
   before you trust it.
4. **Human review** — the ground truth the other three approximate. Sample, do
   not attempt coverage.

Reach for 3 only after 1 and 2 are exhausted. A rubric grader is a second
non-deterministic system judging the first, and its own drift is invisible.

## A case that cannot fail is not a case

Before recording a case, run it against a deliberately wrong answer and watch it
fail. This is the same rule as `writing-tests` and it matters more here, because
an eval that passes everything looks identical to one that works.

## Set a threshold you would act on

"85%" is not a threshold unless you know what you do at 84%. Decide first:
- **blocks the merge** — an assertion failure, always
- **blocks the release** — golden-case pass rate below the line
- **opens a finding** — rubric score drift beyond the noise band

If the answer to "what happens at 84%?" is "we discuss it", the number is
decoration. Either it gates something or it is a report.

## Record the run, not just the number

An eval score with no record of which model, which prompt version and which index
produced it cannot be compared to the next one. That is what `.agents/runs/`
is for.

## Anti-patterns

- **Evals written from the model's output.** You are asking whether it did what
  it did. Write them from the requirement.
- **One giant case.** When it fails you learn that something is wrong.
- **Averaging away the tail.** The mean is fine and the p95 is why users churn.
  Report the worst cases, not the average.
- **Chasing the eval.** Prompt changes that move the score without improving the
  behaviour are overfitting to a test set of ten.

## Done

- Every case has failed at least once, deliberately.
- Each threshold names what happens when it is missed.
- `make evals` runs them, and CI runs `make evals`.
- The run recorded the model, prompt version and index it scored.
