---
name: harness-audit
description: Adversarially review any existing harness — built by this kit or not — against the anatomy and the principles rubric, one lens per pass, rotating. Use to improve a harness someone already has, quarterly, before a handover, or when a harness has green checks nobody trusts. Reports findings and stops; it never edits.
license: MIT
allowed-tools: Read, Glob, Grep, Bash(./scripts/gate-selftest.sh:*), Bash(./scripts/check.sh:*), Bash(./scripts/doctor.sh:*), Bash(./scripts/gates/:*), Bash(git log:*), Bash(git diff:*), Bash(ls:*), Bash(find:*), Bash(grep:*)
metadata:
  harness.entry: "false"
---

# harness-audit

**Reports and stops.** Does not fix, does not approve.

**The reviewer must not be whoever built the thing under review** — including the agent that built it. The absence of build context *is* the qualification.

## 0 · Two kinds of target

**A harness this kit built** — the scripts below exist; run them.

**A harness someone else built** — from another kit, a client's, one grown in-house. The scripts will not be there, and that is not a finding in itself. Map their machinery onto the anatomy first: what plays the part of the constitution, the foundations, the gates, the corpus? **Judge the organ, not the filename.** An organ genuinely absent is a finding; an organ present under a different name is not.

Run its own checks, whatever they are called, and read their denominators.

## 1 · Run the mechanical half first

```
./scripts/gate-selftest.sh     # can every gate still fail?
./scripts/check.sh             # do the gates pass on a clean tree?
./scripts/doctor.sh            # is the harness itself intact?
./scripts/gates/dead-config.sh # does anything read what the config claims?
```

**Read the denominators, not the ticks.** `✓ secret scan` with no count cannot be distinguished from "I examined nothing".

If `gate-selftest.sh` does not exist, or has fewer cases than there are gates, that is finding one and it outranks everything else. A gate that has only ever met a clean tree is unverified, and it is the most common shape a harness defect takes.

## 2 · Pick one lens

**One per pass, rotating.** A fixed checklist run every time calcifies into something that passes trivially.

| Lens | Asks |
|---|---|
| **Dead config** | Start from the config and the docs. What reads each key? What produces each referenced path? What owns each file that is pointed at? (The gate does the mechanical half; the judgement half is not automatable, and this is the failure class adversarial review is structurally blind to.) |
| **False green** | For each gate: what exactly would make it print a tick while checking nothing? Piped exit statuses, empty path filters, a `fail` inside a subshell, a skipped missing file, a glob matching nothing. |
| **Data and boundaries** | Can a credential or an individual's details reach a committed file? Test the *local* formats — non-Latin names, unhyphenated numbers, full-width digits, non-ASCII filenames. Is external content treated as data rather than instruction? |
| **First run** | Clone it as a new person on Monday. Do cross-references resolve? Do two files contradict each other? Where do you bounce off? |
| **Authority** | Is there exactly one canonical rulebook? Is anything restated in two places? Does every rule trace to a named failure? Is the budget real? |
| **Fitness** | Does this harness serve the outcome it was built for? Is the thing that matters actually being recorded, today? What in here is now unnecessary because the model improved? |

## 3 · Score against the rubric

Work through the relevant section of `PRINCIPLES.md`. For each claim: **verified · violated · not applicable · could not determine.**

"Could not determine" is a legitimate and useful verdict. Recording it as verified is not.

## 4 · Report

Use `core/contracts/review.md`. Specifically:

- **What was examined, with denominators.**
- **What was verified clean** — this is what makes a null result credible.
- **Separate what you verified from what you suspect.** Say which is which for every finding.
- Severity, location, evidence, and the proposed change.
- Classify each finding for the ratchet: existing rule missed · one-off · candidate rule.

On a null result, `core/contracts/review.md` owns the rule and this skill does not restate it: what makes "nothing found" credible is the denominator beside it. A review that looked hard and found nothing is a result. A review that did not look is not.

## The thing to keep in mind

Unexamined is the default state, and an unexamined harness with green checkmarks is more dangerous than no harness, because the checkmarks are load-bearing in people's heads.

Three adversarial passes over one harness produced 47 findings including two silent-success bugs. None was visible before someone looked.
