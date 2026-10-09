# Evals — opt-in L4

A harness you cannot measure is one you can only admire. This is the smallest
thing that counts as measurement: **Data, Task, Scorers.**

> **What actually runs today: the Scorers, and only the Scorers.**
> `run-evals.sh` reads the repository as it finds it, runs each case's
> deterministic scorer commands against that tree, and looks up a verdict for
> each judge scorer. It does **not** execute a case's `task` — there is no agent
> runtime here — and it does **not** apply a case's `setup` block; branch and
> fixture are read and ignored, so the runner now reports an unapplied setup per
> case rather than scoring the wrong tree in silence. There are no trials and no
> variance handling: one run, one number. A green run therefore means "the
> repository state satisfies these scorers", not "an agent did the task well".
> Building the missing half — fixtures, a runtime adapter, trials, baselines,
> variance — is a real piece of work, and it should be designed against a
> project that actually runs it rather than guessed at now. The three headings
> below describe the model; only the third is implemented.

- **Data** — `cases/*.json`, a handful of representative tasks with a baseline.
- **Task** — what the agent is asked to do, verbatim. *Documentation: nothing
  here executes it.*
- **Scorers** — how the result is judged. Two families:
  - *deterministic* — did the gate pass, was the file written, did the test run.
    Free, objective, and where you should spend first.
  - *judge* — a model or a person grading an open-ended output against a
    rubric. Use only for things no script can decide.

**A judge scorer with no verdict does not pass — it leaves the run ungraded.**
The whole reason a rubric is in the case is that no script can decide it, so
counting it as fine because nothing objected grades the easy half and reports it
as the whole.

Four exit codes, because "the change is bad" and "the harness is broken" are not
the same news:

| exit | meaning |
| --- | --- |
| 0 | everything graded, everything passed |
| 1 | **FAILED** — a scorer ran and said no |
| 2 | **INCOMPLETE** — a judge scorer has no live verdict, or a case declared a `setup` nothing applied. Not a pass |
| 3 | **INFRA_ERROR** — the *runner* broke: a case file that will not parse, an unknown scorer type, a command that could not be executed at all (exit 126/127). Not a statement about the work under test |

`INFRA_ERROR` outranks the rest: if the runner broke, the pass/fail counts cover
only the cases that ran, and reporting them as a verdict would be the same
overclaim this page had to correct about itself.

Record a verdict:

```bash
./evals/grade.sh 001-scoped-change no-drive-by-refactor pass "SS — read the diff, no drive-by changes"
```

That writes a row to `evals/grades.tsv` carrying a checksum of the rubric text
it judged. Reword the rubric and the verdict goes **stale** and stops counting:
a verdict that outlives the question it answered is a leftover, not evidence.

Runs with no vendor account. If you later wire up LangSmith or Braintrust, the
case shape maps over directly.

```bash
make evals
```

## Writing a case

Start with **5–10 examples of "good"** for the parts of the harness you care
most about. More than that up front and you will maintain cases instead of the
harness.

Good candidates: a task that previously went wrong (regression), a task that
touches a high-risk surface, a task where the agent has repeatedly over-scoped.

## What to report

Pass rate is not enough on its own. Report **pass rate, cost, and steps**
together — a harness change that lifts pass rate from 70% to 75% while doubling
token spend is usually a bad trade, and the number alone hides that.

Track over time: first-pass approval rate, rework rate, recurrence of known
failures, and how often a gate fired on correct work (false positives are how
gates get disabled).
