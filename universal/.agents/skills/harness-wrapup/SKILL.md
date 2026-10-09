---
name: harness-wrapup
description: Close a working session — write the devlog entry for what happened, and state plainly what was left unverified. Use when stopping for the day, handing to another agent or person, or when a session ends without the work being merged. Not for opening a PR, which has its own evidence requirements.
license: MIT
metadata:
  harness.tier: workflow
allowed-tools: Read Glob Grep Write Edit Bash(git status) Bash(git log:*) Bash(git diff:*) Bash(ls:*) Bash(./scripts/emit-evidence.sh:*) Bash(./scripts/retro-evidence.sh:*)
---

# wrapup

The harness proves what ran. Nothing in it records what did not.

`.agents/runs/*.jsonl` and `make check` are evidence of execution — a gate
passed, a command exited zero, a spec had no unresolved markers. All of it is
positive. The next session opens with `session-start.sh` telling it the branch,
a glob-picked spec directory and a permission tier, and reconstructs the rest
from the diff. What it cannot reconstruct is the thing you knew and did not
write down: that the happy path was clicked through but the error path never
was, that a test was skipped rather than passing, that the fix works but you do
not know why.

That gap is where the same work gets redone, and where "it was working when I
left it" comes from.

| Use it when | Do not use it when |
|---|---|
| Stopping mid-change, with work still on the branch | Opening a PR — that is `/harness-pr`, which has its own evidence sections |
| Handing to another person or agent | A run that changed nothing — there is nothing to hand over |
| The session ran long enough that you have forgotten the start of it | Recording a decision — that is `/harness-decisions` or `/harness-adr` |
| A run went wrong and you are stopping to think | Turning a repeated failure into a harness change — that is `/harness-retro` |

**Owns:** the devlog entry for this session. **Never:** writes source, marks
anything complete, or substitutes for the PR's verification section.

## The entry

Append to `docs/devlog/YYYY-MM.md`, in the format that file's README already
defines, plus the two fields a session boundary needs that a PR does not:

```markdown
## 2026-08-31 · REQ-014 CSV export · session

**Context** — why this was being done now
**Decisions** — what was chosen along the way, and what was rejected
**Friction** — what was harder than expected, what surprised you
**Corrected** — what the person corrected, close to their words
**Left undone** — known gaps, deliberate deferrals
**Not verified** — what was changed but not exercised, and how you would exercise it
**New configuration** — variable and setting NAMES the next run will need
```

Write "nothing notable" rather than leaving a field blank. A blank field is
ambiguous between "nothing happened" and "nobody filled this in", and the
ambiguity resolves optimistically every time.

## Not verified — the field this skill exists for

Every other field is narrative and the entry survives a weak one. This one is a
claim, and a wrong one is worse than an empty one.

For each thing you changed, one of exactly three statements is true:

| | Write |
|---|---|
| A gate or test covered it | nothing — the evidence record already says so |
| You exercised it by hand | what you did, and what you saw. "Loaded the export page as a member, got a 12-row CSV" |
| Neither | name it here |

The third case is the entry. Be specific about the *unexercised path*, not the
feature: "export works; the empty-result and permission-denied branches were
never hit" is useful, "export needs more testing" is not.

Three shapes worth naming explicitly because they read as done and are not:

- **A test that was skipped, quarantined or marked pending** to get a run green.
  This one also belongs in `/harness-retro` if it happens twice.
- **A path exercised only in mock mode.** `MOCK_MODE` proves the wiring, not the
  integration.
- **A fix whose mechanism you do not understand.** If the change worked and you
  cannot say why, that is the most important line in the entry.

Do not write "everything works". If it did, say which commands say so and let
the evidence record carry it.

## Corrected

Every time the person corrected the agent this session — "no, use the other
template", "you skipped the tests again" — close to their words, not softened.
This is the field `/harness-retro` counts: a correction that appears in two
entries is a candidate rule, and one written as "minor adjustments" is invisible.
Before writing it, search earlier devlog entries; if the same correction is
already there, say so in the line. Write names of roles, never of people.

## New configuration

Names only. An environment variable the next run needs, a feature flag that has
to be on, a service that has to be running locally.

**Never a value.** Not a key, not a token, not a connection string, not a
password, and not an example that happens to be real. `.agents/rules/no-secrets.md`
governs this file exactly as it governs source: a secret written into a devlog
entry is a secret in the repository, and it is compromised from the moment it
lands. If one does, rotate it before doing anything else — including before
deleting the line, because the line is already in the reflog.

## Procedure

1. `git status` and `git diff --stat` against the branch point. Work from what
   actually changed, not from memory of what you meant to change — a session
   that ran long has drifted from its own plan more often than not.
2. Write the entry. One session, one entry, appended.
3. Fill **Not verified** by walking the diff, not by recalling the work.
4. If anything in the entry contradicts the spec or the register — scope moved,
   a requirement turned out wrong — that is not a devlog matter. Route it:
   `/harness-requirements` for scope, `/harness-decisions` for direction,
   `/harness-adr` for a technical choice. The devlog records that it happened;
   the owning artifact records the change. A durable fact the next session would
   otherwise re-learn goes to `.agents/memory/`, dated and sourced — through
   `/harness-retro`, because `.agents/` is protected.
5. A bug fixed this session without a row in `docs/quality/defects.md` is a fix
   that taught nothing — add the row (`/harness-defect` step 6). A question about
   intended behaviour that came up and was not logged goes in
   `docs/product/questions.md`, open.
6. If `./scripts/retro-evidence.sh --due` prints a line, tell the person a retro
   is due. Do not start one.
7. Record the close: `./scripts/emit-evidence.sh closure "<actor>" pass "wrapup: <branch>, N unverified"`.

## Anti-churn

A session that read code and changed nothing does not need an entry. Neither
does a run whose whole content is already in a PR body opened the same day —
write the entry when the work is *stopping*, not when it is finishing.

The failure this guards against is a devlog nobody mines because nine entries in
ten say "continued work on the feature". If the entry would say that, the
session did not need one.
