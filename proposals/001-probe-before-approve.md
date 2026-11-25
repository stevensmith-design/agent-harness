# 001 · Probe before approve

**Status:** proposal, not implemented. Nothing here ships to installs: `proposals/`
sits outside `kit/` and `universal/`, as `eval/` does.

## Problem

The retro approves a harness change on argument. The owner reads one line at §4
(*finding · evidence · home · check · always-loaded cost*) and decides whether the
change *would have* stopped the failure. Nobody runs it. For a new prose rule that
is cheap to be wrong about. For two kinds of change it is not:

- **The always-loaded set.** Every session pays for a line in the constitution or
  `read-first.md`, whether or not it changes anything.
- **A gate.** A gate that blocks correct work gets switched off; one that never
  fires on the original failure is a green tick over nothing.

These are the changes where "it reads as if it would help" is weakest evidence and
most expensive to get wrong. `kit/LADDER.md` names the symptom as the L3 → L4
trigger: *you cannot tell whether a harness change helped.*

## Design

An optional retro step, **§4b · Probe**, between *Propose* and *Ship it with a
check*. It runs only for proposals that change the always-loaded set or a gate.

1. **Pick the task.** The task that triggered the finding, rewritten as a
   synthetic brief if the original carries client or personal data. If no task can
   be reconstructed, the probe is skipped (see below).
2. **Run it twice, fresh.** Two new agents, no shared context, same model, same
   brief:
   - **A** — the harness as it is now.
   - **B** — the same harness with the proposed change applied in a scratch copy.
   Each run writes its output and transcript to
   `runs/<YYYY-MM-DD>-harness-retro/probe/{a,b}/`.
3. **Judge blind.** A third fresh agent, or the owner, gets both outputs shuffled
   and labelled only `1` and `2`. The judge brief states, verbatim:
   - *"The output from the unchanged harness is a valid pick. Choosing it is not a
     failure of the judging."*
   - *"Length and polish are not merits. Prefer the output that avoids the failure
     described below, even if it is shorter or rougher."*
   - The failure from the finding, in one paragraph, with the rejected wording.
4. **Adopt only on divergence.** The judge's pick is not enough. The change is
   adopted only if the judge can point to **a specific moment** in B's transcript
   where behaviour diverged from A because of the change: a file read, a step
   not taken, a gate firing. "B was better overall" with no such moment is
   recorded as *no observed effect*, and the proposal goes back to the owner with
   that result attached.
5. **Record.** The §4 line gains a fifth field: *probe: diverged at <moment> /
   no divergence / skipped (<reason>)*.

### Isolation

The agent under test must not be able to read the scorer:

- No read access to `universal/evals/cases/`, any rubric, the judge brief, or the
  retro's own proposal text. The brief is the task, nothing more.
- Run it from a scratch copy that contains the harness and the task fixture only,
  not the repository's `runs/` or `learning/` history, so it cannot find the
  finding it is meant to be tested against.
- The judge sees outputs and transcripts, never which harness produced which.

A probe that leaks the rubric to the agent measures whether it can read.

### What it gives `universal/evals/`

`universal/evals/README.md` says plainly that the runner executes scorers only:
it does not run a case's `task`, applies no `setup`, and has no trials or
baseline. §4b is a task runner with a built-in baseline, A being the unchanged
harness. Once it has been run by hand a few times, the same mechanics (scratch copy,
fresh agent, captured output, blind comparison) are the missing half the evals
README asks to be designed against a real project. A probe whose task proved
useful becomes a case in `evals/cases/`, with A's output as its baseline.

## What it costs

- **Per probe:** three agent runs (A, B, judge) on one task. Order of minutes and
  the token cost of the task twice plus a comparison. Paid only for gate and
  always-loaded proposals, which are a minority of retro output.
- **Owner time:** reading one judge verdict with its cited moment, instead of
  reasoning about a hypothetical.
- **Always-loaded context:** none. §4b lives in the retro procedure, which is read
  only when the retro runs. The procedure grows by roughly 25 lines.
- **Maintenance:** a judge-brief template, and a scratch-copy recipe per host.

## When to skip it

- The change is not to the always-loaded set or a gate. Prose in a procedure,
  a memory entry, a corpus example: approve as today.
- The triggering task cannot be reconstructed without real client or personal
  data, and a synthetic version would not exercise the failure.
- The failure is non-deterministic enough that one run each proves nothing, and
  the cost of several trials is not justified for this change. Say so in the §4
  line; do not run one trial and report it as evidence.
- A deterministic gate whose self-test case already reproduces the failure. The
  self-test *is* the probe for that half; §4b then only checks it does not fire
  on the clean task.

## What it deliberately does not do

- It does not replace §4. The owner still approves; the probe is evidence for
  that decision, not the decision.
- It does not run on a schedule. A scheduled retro still stops at proposals.
- It does not grade the harness overall, keep a score, or compare models.
- It does not run trials or compute variance. One A, one B. If that is not
  enough for a given change, the answer is to skip and say so, not to pretend.

## Open questions

- Should the judge be an agent, the owner, or both? An agent judge is cheaper; the
  owner judging blind is closer to what the harness is meant to serve.
- What is the scratch-copy recipe on hosts without worktrees or sandboxed agents?
  Without real isolation the probe should report itself as not run.
- Does a *no divergence* result count against the proposal at the next retro, or
  is it only a reason to narrow it?
- Where does §4b live in the universal harness, whose retro proposes through a
  PR (§3) rather than an owner approval line?
