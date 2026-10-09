# Routing eval — does the front door open for the sentence people actually say?

**External to the kit on purpose.** This lives in `eval/` at the repository root, not in
`kit/`, so it never ships to someone who installs the kit and never enters a
project's context budget. `check-kit.sh` does not see it.

## What it measures

One thing: **given an opening request, which kit skill claims it.** A host
matches on a skill's `name` and `description` and nothing else, so that is all a
run is allowed to show the judge. Reading a `SKILL.md` body would measure a
document nobody reads at routing time.

Cases and their expected claimants: [`cases.md`](cases.md). That file also states
what a run cannot see — read it before believing a score.

## How to run it

**One fresh agent per case.** Not one agent for the set: an agent shown four
cases together infers the distinctions between them, which makes the eval easier
in exactly the direction that produces a false pass.

Give each judge only:

1. the three skills' `name` and `description`, verbatim from their `SKILL.md`
   frontmatter, plus a fourth option, `none — no kit skill should claim this`;
2. one case's request;
3. the instruction to pick exactly one and give one sentence of reasoning.

Give it no kit documentation, no anatomy, no prior case, and no hint that a
routing eval is running. A judge that knows it is being tested on a front door
will find the front door.

**You cannot fully isolate a judge, and the run record must say so.** A subagent
carries its host session's skill catalogue, so other skills compete whether or not
the prompt names them — in run 1 a case was lost to a brand-voice skill the prompt
never mentioned. Treat the catalogue as a condition of the run and record it. This
is closer to a real session than a clean three-way choice, so it is worth keeping;
what is not acceptable is scoring as though the choice were clean.

## How it is scored

- **pass** — the judge picked the expected claimant.
- **fail** — it picked something else. Record what it picked and its reasoning:
  the reasoning is the finding, not the verdict.
- **not verified** — the judge could not be run, or answered nothing usable.
  Never a pass. A case that did not run is reported as not run.

The denominator is every case in `cases.md`, always stated. A run that scored 16
of 20 with 4 unrun is a 16/20 with four holes, not an 80%.

## What to do with a failure

**A misroute is a finding about a description, not a licence to edit one.** Ask
first which of the two it is:

- **A kit defect** — the description does not carry the phrasing people use, or
  two descriptions overlap where they should not. Fix the description, then
  re-run the whole set: a description edit is a change to every case at once.
- **A case defect** — the expected claimant was wrong, or the request is
  ambiguous enough that a person would also have to ask. Fix the case and say so
  in the run record. This is the more common one on a first pass, and recording it
  as a kit defect is how an eval starts driving the product instead of measuring it.

Either way the run record keeps the original verdict. A run rewritten to agree
with the fix is not evidence.

## Records

One dated file per run in [`runs/`](runs/), from [`runs/_TEMPLATE.md`](runs/_TEMPLATE.md).
Every run is recorded, including the ones that scored badly and the ones that
changed nothing — an eval with no losing runs in its history is an eval nobody
has run honestly.
