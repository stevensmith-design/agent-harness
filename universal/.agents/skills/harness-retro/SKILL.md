---
name: harness-retro
description: The harness improving itself from evidence — count what happened since the last retro, turn repeated failures and corrections into harness changes routed to the layer that owns them, keep memory and the always-loaded set lean, and log the result. Use when session start says a retro is due, after a run went wrong, after repeated review feedback, or when the same correction has come up twice.
license: MIT
metadata:
  harness.tier: maintenance
allowed-tools: Read Glob Grep Edit Write Bash(git:*) Bash(make:*) Bash(./scripts/:*) Bash(python3 scripts/mine-sessions.py:*)
---

# harness-retro

The maintenance loop. Without it a harness decays: the same correction gets made
by hand every week and never becomes a rule, memory fills with things that
stopped being true, and the always-loaded set grows a line at a time.

| Use it when | Do not use it when |
|---|---|
| `make retro-evidence` says a retro is due — session start passes that on | It happened once — once is noise |
| The same correction has come up 2+ times | You want to skip a gate that is working correctly |
| A run failed in a way the harness should have caught | You are mid-task — finish, then retro |
| Review feedback repeats across PRs | The fix belongs in product code, not the harness |

The due triggers — a week with work in it, a month regardless, repeated
corrections, any incident, a rule broken again after its lesson — live in `scripts/retro-evidence.sh`, and only there.

**Owns:** changes to `AGENTS.md`, `.agents/rules/`, `.agents/skills/`,
`.claude/hooks/`, `scripts/gates/`, `.agents/memory/`, and rows in `docs/retros.md`.
**Requires:** a declared intent — this is the one skill allowed past the
protected-path hook, and it must say why on the record first:

```bash
./scripts/declare-intent.sh harness-edit "<what the harness got wrong, in a sentence>"
# ... do the work ...
./scripts/declare-intent.sh --clear
```

The declaration is bound to the current branch and stops applying the moment you
leave it, so a retro cannot silently authorise the next piece of work.

## 1. Gather evidence

What actually happened since the last retro, not what you remember:

- `make retro-evidence` — commits, devlog corrections and unverified paths,
  incidents, gate results, unconfirmed memory, the always-loaded size and the
  largest skills. It writes nothing.
- `python3 scripts/mine-sessions.py` — what the person typed when correcting
  the agent, from saved sessions. Places to look, not findings. Optional.
  `--usage` shows where the tokens went: per session, the share read from the
  prompt cache, the largest tool outputs, the files read most.
- Review comments on PRs merged since the last retro. The same comment twice is a
  candidate.
- `docs/devlog/` — **Friction**, **Corrected** and **Not verified** since then.
- `docs/quality/defects.md` — **Broken again** first. A rule that broke after a
  lesson was recorded is the loop leaking, and outranks every new defect: the
  question is not "what went wrong" but "why did the lesson not hold". Then the
  gap counts: many `spec` → questions are not closing into rules; many `test` →
  sweeps are not becoming table-driven tests; many `render` → the stress fixture
  or `make render-audit` is missing something a person keeps finding.
- `docs/product/questions.md` — open ones past their stale date, and clusters:
  five questions from five screens are usually one missing rule.
- **What went well** — the entries with nothing to fix. Name what to protect; a
  change that would break it carries that cost.

Cluster them. **A candidate needs at least two independent occurrences.** One-off
mistakes become rules that fire forever on a problem that happened once.

**Before proposing anything,** read the *Turned down* column of `docs/retros.md`
and the do-not-re-propose list in `docs/product/decisions.md`. A candidate that is
already there needs a reason that is new, or it is dropped.

## 2. Route each candidate to the layer that owns it

This is the whole skill. Getting the layer wrong is how `AGENTS.md` grows to 400
lines and stops being read.

| The failure is… | Destination | Why |
|---|---|---|
| A convention got wrong everywhere | a line in `AGENTS.md` | always-on, cheap, small |
| A constraint that applies only to some paths | `.agents/rules/<n>.md` with `paths:` | loads only when relevant |
| A multi-step procedure done inconsistently | a skill | procedures belong in procedures |
| Something that must **never** happen | a hook or a gate script | instructions are advisory; hooks are not |
| A decision being relitigated | an ADR in `docs/decisions/` | records the why, ends the argument |
| A fact the agent could not know | `.agents/memory/` | durable, not a rule |
| A rule broken again after its lesson | one rung up: memory → rule → test → gate | the rung that was tried did not hold |
| A person keeps judging "this looks wrong" the same way | a measurable check in `make render-audit`, else a judged example | taste the agent cannot infer, written down |

Default to the **most specific** destination that works, and to the **most
mechanical** one available. A grep beats a sentence.

## 3. Propose, then ship it with a test

The retro proposes; a person approves. The changes land as **a PR**, never a
direct commit, with each change's evidence — dates, counts, the devlog or review
it came from — in the PR body. Candidates the reviewer turns down go in the log.

A rule with nothing checking it is a wish.

- Deterministic rule → add a `design.forbid` entry or a script in
  `scripts/gates/`, plus one file it must flag and one it must not.
- Prose rule → add the failing example to the rule itself so the next agent sees
  what it looks like.
- Hook → verify it blocks the bad case *and* stays silent on the good case. A
  hook that fires on correct work gets disabled within a week.

## 4. Memory hygiene

Memory that is never pruned becomes a list of things that used to be true, and it
is believed. For each entry `retro-evidence` flags as never or long unconfirmed:
still true → update its confirmed date; not true → delete it; cannot tell → ask.
Merge duplicates. An entry an ADR or `AGENTS.md` contradicts is wrong — fix it. An
entry that keeps being applied as a rule is routed per §2 and removed. Keep
`MEMORY.md` an index, under its budget.

## 5. Context cost — net zero

Run `make check-budget`. Over budget means something in the set has stopped
earning its place — move detail into `docs/` or a path rule; do not raise the
budget. Then compare the always-loaded size with the last row of `docs/retros.md`:
if it grew, name what came out to pay for what went in, or take something out now.
The ceiling catches a blow-out; the trend catches the slow growth that gets there.
The largest skills cost their task every time they fire — trim history out of them.
Every skill description is paid every session, used or not. From `--usage`: a
large output that recurs gets filtered or scripted; a file read in most sessions
gets a path rule or gets shorter.

## 6. Log and report

**Append a row to `docs/retros.md` every time**, including "no changes needed" —
date, trigger, always-loaded lines, findings, the PR, and what was turned down
with the reason. Without the row the next evidence window starts in the wrong place.

- Candidates found, and how many occurrences each had.
- What was written, where, and the failure each one prevents.
- Candidates **turned down** and why — this list matters as much as the accepted one.
- Run `make harness-sync` and `make harness-verify LEVEL=2` before finishing.

## Cadence

Run the first two or three retros by hand, until the evidence and the proposals it
leads to are trusted. Then schedule it — a scheduled agent task or a CI cron — to
gather evidence and open a **draft** PR of proposals. A scheduled retro never
merges; a person reviews it like any other change.

## Anti-churn

Only write when a run was actually steered wrong. A retro that produces a diff
every time it runs is noise, and the team will stop reading the diffs. "No
changes needed" is a valid, common, and good outcome — log the row and stop.

## The question that finds decorative machinery

Prose has no compiler, so a harness accumulates config that reads as enforcement
and enforces nothing. Ask one question of every rule, config key and doc claim:

> **What would I run to see this happen?**

If the answer is "an agent reads this section and does the right thing", it is a
wish. That is fine when it is *meant* to be — judgement does not compile — but it
must not sit in a file shaped like a control. Adversarial review answers "does
this code do what it says" and is blind to "is there any code here at all", so
this is its own pass: **start from the config and the docs, not from the
scripts, and for each claim name the file that would run it.** A claim with no
such file is either wired up or deleted. One is open: `docs/design-quality-checklist.md`
is cited by no skill and no script.
