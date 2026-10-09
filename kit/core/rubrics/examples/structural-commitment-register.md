---
standard: commitment-register
title: "Commitment register integrity"
kind: structural
covers: registers, trackers, backlogs, roadmaps and decision logs
default_severity: fix
derived_from:
  - "One split that holds for any register: status lives in exactly one place, and rows are never deleted"
status: prose
---

# Commitment register integrity

**Example of a STRUCTURAL standard.** Nothing here judges whether a commitment is *good*. Every
criterion is about **shape** — a required field, an owner, a resolvable link, a row that was not
deleted. That makes this the cheapest gate available in almost any domain, and the one most often
left unwritten because it feels too obvious to bother with.

It is also the most portable rubric in this kit. A register of commitments exists in project
management, product, business development and delivery, and it fails the same way in all of them.

## How it fails in practice

- **The deleted row** — a dropped commitment is removed. What you see: it is proposed again four
  months later, and nobody can say why it was dropped the first time.
- **Status in the narrative** — a planning document says "in progress". What you see: it still says
  that in November, and nothing errored.
- **The ownerless commitment** — a row with a deliverable and no name. What you see: it survives three
  reviews untouched, and nobody notices it belongs to no one.
- **The undated status** — a status with no date. What you see: nobody can tell whether "blocked" was
  true yesterday or last quarter.
- **The dangling reference** — a row cites a document that has moved. What you see: the link resolves
  to nothing, and the row now asserts something unverifiable.
- **Two registers** — a spreadsheet and a tracker, both live. What you see: the answer depends on who
  you ask.

## What this protects

Anyone who needs to know what is true *now* — someone returning after two weeks, whoever inherits
the work, the person asked for a status update, and an agent deciding what is committed. Without a
single dated, owned source they reconstruct the truth from prose, and an agent reconstructs it
generously.

## Where it applies

- **Applies to:** any list of commitments with a status — requirement registers, delivery trackers,
  sales pipelines, roadmaps, decision logs.
- **Does not apply to:** narrative documents that *describe* a plan and link to the register; idea
  backlogs where nothing is committed yet; meeting notes.

## Criteria

### single-source-of-status
**Rule:** status appears in exactly one artifact; narrative documents link to it and state none.
**Severity:** blocking
**Answers:** status-in-the-narrative, two-registers
**Meets:** the planning document links to the register; the register holds every status value.
**Misses:** the planning document says "shipped" and the register says "in review".

### every-row-has-an-owner
**Rule:** every row names a person, not a team or a role.
**Severity:** blocking
**Answers:** the-ownerless-commitment
**Meets:** `owner: J. Rivera`.
**Misses:** `owner: operations` — or empty.

### every-row-is-dated
**Rule:** every row carries the date its status last changed.
**Severity:** fix
**Answers:** the-undated-status
**Meets:** `committed 2026-08-14`.
**Misses:** a status with no date, which cannot be aged.

### reversals-are-additive
**Rule:** no row is ever deleted; a dropped commitment is marked superseded in place, with a reason.
**Severity:** blocking
**Answers:** the-deleted-row
**Meets:** `status: superseded — see R-041; capacity, not merit`.
**Misses:** the row is gone from the diff.

### references-resolve
**Rule:** every path or link a row cites exists.
**Severity:** fix
**Answers:** the-dangling-reference
**Meets:** the cited document is at the path given.
**Misses:** the path returns nothing, and the row now asserts something nothing supports.

---

**Why this one earns its place:** all five checks are greppable against a structured register, so
this reaches **L2 immediately** — no corpus needed. If a domain has any register at all, this is
almost always the first rubric worth writing, and it costs an afternoon.
