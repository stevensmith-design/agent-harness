---
id: harness-retro
surface: harness
status: live
owner: {{OWNER}}
description: The harness improving itself from evidence — count what happened since the last retro, turn repeated failures and corrections into durable changes routed to the layer that owns them, keep memory and the always-loaded set lean, and log the result. Use when scripts/retro-evidence.sh says a retro is due, after a run went wrong, or when the same correction has come up twice.
---

# Harness retro

The maintenance loop. Without it a harness decays: the same correction gets made by hand every week and never becomes a rule, memory fills with things that stopped being true, and the always-loaded set grows a line at a time until nobody reads it.

**A harness without a write-back loop is a document, not a harness.**

| Run it when | Do not run it when |
|---|---|
| `bash scripts/retro-evidence.sh --due` prints a reason — the session-start hook passes it on | It happened once — once is noise |
| The same correction has come up twice | Mid-task. Finish, then retro |
| A run went wrong in a way nobody expected | You want to skip a gate that is working correctly |
| The person says "again", "every time", "I already said" | The fix belongs in the work, not the harness |
| Quarterly: an independent adversarial review is due | You built the thing — get someone who did not |

The due triggers — a week with work in it, a month regardless, a pile-up of runs, rejections or failed checkpoints, or a standard broken again after its lesson — live in `scripts/retro-evidence.sh`, and only there.

**Requires:** a declared harness change — `./scripts/declare-harness-change.sh "retro"`.

## 0 · Gather the evidence

**Before forming a view.** A retro run from memory reviews the last two days and the most annoying failure.

1. `bash scripts/retro-evidence.sh` — runs, rejections, acceptances, checkpoint failures, journal entries and corrections since the last retro; memory entries that were never or long ago confirmed; what every session pays in always-loaded context; the largest on-demand files.
2. `python3 scripts/mine-sessions.py` where python3 and saved sessions exist — what the person actually typed when correcting the agent, since the last retro. It prints places to look, not findings. With `--usage` it shows where the tokens went: tokens per session, how much came from the prompt cache, the largest tool outputs, and the files read again and again.
3. In a repository: review comments on changes merged since the last retro. The same comment on two changes is a candidate.
4. `learning/journal/` since the last retro.
5. `learning/findings.md` — **Broken again** first. A standard that broke after its lesson was recorded is the loop leaking, and it outranks every new finding: the question is not "what went wrong" but "why did the lesson not hold". Then the gap counts, and the *Open questions* in `decisions/log.md` — five questions about the same area are one missing decision.

**First by hand, then on a schedule.** Run the first two or three retros by hand, with the owner there, until the evidence and the proposals it leads to are trusted. Then schedule it — a scheduled task in the agent host, or cron — to do steps 0–4 and write its proposals to `runs/<YYYY-MM-DD>-harness-retro/`. It stops there — see *Escalates when*.

## 1 · Prove the gates can still fail

**Before reading a single finding.** Run `./scripts/gate-selftest.sh`.

Almost every gate, at some point, reports a tick while checking nothing — a check that inherits the wrong exit status, or skips a missing file and passes. That is found by making it fail on purpose, never by use.

**A gate you have never observed failing is a gate you have no evidence works.**

If you added a gate since the last retro and did not add its self-test case, that is the first finding.

## 2 · Evidence → spec

**The job that matters most, and the one most likely to be skipped.**

1. Read everything added to `learning/corpus/rejected/` since the last retro — **reasons first** — then the journal's *Corrected* lines and the transcript matches.
2. Cluster them. Three rejections and a correction all saying the same thing are one finding, not four.
3. For any cluster with **two or more** independent occurrences, ask: *does the current spec already forbid this?*
   - **It does** → the spec is not the problem; it was not applied. Ask whether the rule is buried, whether `read-first.md` should route to it, or whether the procedure needs a check at the point of generation.
   - **It does not** → a real gap. Write it into the spec as a specific disqualifier, using the actual rejected wording as the example.
4. **What went well.** Read `learning/corpus/accepted/` and the journal's *Went well* lines. Name what to protect. Patterns in what worked are rarer and more valuable, because good is easier to recognise than to describe — and a proposal in §4 that would break one of them carries that cost.

**A spec that never changes after contact with real output is not stable — it is ignored.**

## 3 · Route each finding to the layer that owns it

Getting this wrong is how a constitution grows to 400 lines and stops being read.

| The failure is… | Goes to | Why |
|---|---|---|
| A fact about the work's subject we got wrong | a foundation file | It is ground truth |
| A fact about *the work* we keep re-learning | `memory/` | Durable, but not a rule |
| A file an agent should have read before a task, and did not | a row in `read-first.md` | Routes reading without growing the constitution |
| A convention violated everywhere | one line in the constitution | Always-on, must stay small |
| A constraint true only on some surfaces | that surface's row and rules | Loads only when relevant |
| A multi-step procedure done inconsistently | a procedure | Procedures belong in procedures |
| Something that must **never** happen | a script in `scripts/gates/` | Instructions are advisory; scripts are not |
| A decision being relitigated, or an idea that keeps coming back | `decisions/log.md` | Records the why, and what not to propose again |
| A standard broken again after its lesson was recorded | one rung up from that lesson: memory → rubric or procedure step → gate | The rung that was tried did not hold |
| A person keeps making the same "this feels off" call | a judged example in `learning/corpus/`, with the reason; a rubric line once two share it | Taste nobody wrote down is taste the agent guesses |

Default to the **most specific** destination that works, and the **most mechanical** one available. A grep beats a sentence, because a sentence needs someone to remember it.

## 4 · Propose, then apply

**Nothing changes until the owner has seen it.** Put each proposal in one line:

> the finding · its evidence, with dates and counts · where it goes · the check that will enforce it · what it adds to the always-loaded set

The owner approves, changes or turns down each one. Apply only what was approved. A turned-down proposal goes to `learning/candidates.md` → *Rejected*, or, if it is likely to come back, to *Do not propose again* in `decisions/log.md` — with the reason in the owner's words.

## 5 · Ship it with a check

A rule with nothing checking it is a wish.

- Deterministic rule → a gate in `scripts/gates/`, **plus a case in `gate-selftest.sh`**: one input it must flag, one it must not. Run both before committing.
- Prose rule → put the failing example into the rule itself, so the next agent sees what it looks like.
- Either way, log it in `learning/changelog.md` with the occurrences that justified it and the check that now enforces it.

## 6 · Memory and decision hygiene

Memory that is never pruned becomes a list of things that used to be true, and it is believed.

- **Unconfirmed or long-unconfirmed entries** the evidence flagged: check each against the current state. Still true → update its confirmed date. Not true → delete it. Cannot tell → ask, or delete.
- **Duplicates** → merge. **An entry that contradicts a foundation** → the foundation wins; fix the entry.
- **An entry that has become a rule** — it keeps being applied as one → route it per §3 and remove it from memory.
- **Topic files past a screen and a half** → condense or split.
- **Decision log:** decisions whose *revisit when* has come true get reopened with the owner; nothing is deleted, only struck through.

## 7 · Context cost

What every session pays before anyone types.

1. `./scripts/check-budget.sh` sums the whole always-loaded set declared in `loading-order.md`, not just the constitution — a per-file budget gets evaded without anyone deciding to, by moving content into a second file that also loads every time. If the set is over, something in it has stopped earning its place. **Move detail into an on-demand file; do not raise the number.** The skill listing the evidence script shows is paid every session too: a procedure nobody runs any more is set to `retired`, which removes its skill.
2. **Net zero.** Compare the size with the last row of `learning/retros.md`; the evidence script prints the change. If it grew, name what was added and what came out to pay for it. If nothing came out, take something out now, or say in the log why not. The ceiling catches a blow-out; the trend catches the slow growth that gets there.
3. **The largest on-demand files, and what sessions actually spent.** A procedure or rubric read on every run of its task costs that task every time; if one is long because it explains history, move the history to a note it links to. From `mine-sessions.py --usage`: an output that recurs large gets filtered, or replaced by a script that returns a summary; a file read in most sessions gets a `read-first.md` row or gets shorter; a low share read from the cache means sessions keep changing what they load, or sit idle past the cache lifetime.

## 8 · Review staleness

Run `./scripts/review-staleness.sh` after filing a review. If it fails, **do not open by re-fixing the repeats.**

A finding that survives two reviews has stopped being information about the work and started being information about the team: someone decided not to act on it and did not say so. Write that down — a lesson in `memory/`, or an explicit deferral with a reason in the review file. Then close it or leave it closed-with-a-reason.

An open finding nobody intends to act on quietly devalues every other finding in the file.

## 9 · Ask what is now unnecessary

As models improve, some scaffolding becomes dead code. A check that exists only to prevent a failure the model no longer makes is cost with no benefit, and one more green tick that means nothing. **Removing a rule is a legitimate and under-used outcome.**

## 10 · Independent adversarial review

**Quarterly, and before any handover.** Not by whoever built the thing under review — including the agent running this retro. The reviewer needs no context from the build; that absence *is* the qualification.

Give a fresh agent the harness and **one lens at a time**, rotating rather than running all of them. A fixed checklist calcifies into something that passes trivially.

**The lens list lives in one place** — the `harness-audit` skill in the kit this harness was built from, §2 — because a second copy drifts. If the kit is not to hand, the reviewer's own list is fine; write down which lens was used, so the next quarter rotates rather than repeats.

Brief them to be blunt, and to separate what they **verified** from what they **suspect**. On what a null result means, the rule lives in `contracts/review.md` — brief them to it rather than restating it here.

**The uncomfortable general point:** unexamined is the default state, and an unexamined harness with green checkmarks is more dangerous than no harness, because the checkmarks are load-bearing in people's heads.

## 11 · Log and report

**Append a row to `learning/retros.md` every time** — date, trigger, always-loaded lines, findings, what changed, what was turned down. A retro that changed nothing still gets its row; without it the next retro's evidence window starts in the wrong place, and nobody can tell the loop ran.

Then report:

- Candidates found, and how many occurrences each had.
- What was written, where, and the failure each one prevents.
- **Candidates turned down, and why.** This list matters as much as the accepted one — it is the record of what was decided not to systematise.
- The always-loaded size, and its change since last time.

## Stops when
- `./scripts/declare-harness-change.sh "retro"` has not been run. This procedure edits the harness, and an undeclared harness edit is exactly what that gate refuses.
- `gate-selftest.sh` fails at §1. Findings read against gates that cannot fail are worthless — and that failure is the first finding.
- A cluster has fewer than two independent occurrences (§2.3). One is noise, and a rule built from one fires forever.
- It is mid-task, or the motive is to get past a gate that is working correctly.

## Escalates when
- A proposal in §4 has not been approved. Nothing is applied unapproved — which is where a scheduled retro stops every time: it writes its proposals to `runs/<YYYY-MM-DD>-harness-retro/` and the owner runs §4 onward.
- The always-loaded set is over budget at §7 and nothing obvious can come out. What has stopped earning its place is the owner's call.
- A decision's *revisit when* has come true (§6). Reopened with the owner; nothing is struck through here.
- §10 is due, or a handover is coming. That review goes to someone who did not build the thing — which includes this agent.

## Safe to re-run when
- Up to §3, always: steps 0–3 read evidence and write nothing. From §4 it applies changes, so a run following a partial one reads `learning/retros.md` and `learning/changelog.md` first, for what the interrupted run already applied. The same proposal applied twice is how one occurrence becomes two in the next retro's evidence.


## Anti-churn

Only write when a run was actually steered wrong. A retro that produces a diff every time is noise, and people stop reading the diffs — at which point the loop is worse than not having it.

**"No changes needed" is a valid, common and good outcome.** Say it plainly, log the row, and stop.

## Success metric

The same correction is not made by hand three times, and the always-loaded set is no larger than it was a quarter ago. If either fails, the retro is not working — or is not being run.
