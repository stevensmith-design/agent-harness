---
name: harness-branch
description: Start a piece of work correctly — turn a ticket or spec into a properly named branch or worktree, confirm the starting state is clean, and set up the run so the work is attributable. Use at the beginning of any change, before writing code.
license: MIT
metadata:
  harness.tier: workflow
allowed-tools: Read Glob Grep Bash(git:*) Bash(make:*) Bash(gh issue:*) Bash(./scripts/:*)
---

# branch

The first two minutes of a task decide whether the last two hours are
recoverable. This is the skill agents most often improvise, and improvising it
is how you get work stranded on `main` or two agents in one checkout.

| Use it when | Do not use it when |
|---|---|
| Starting any change from a ticket, spec, or request | You are already on the right branch — just work |
| Picking up work another agent started | The change is a one-line docs fix on a clean tree |
| Fanning out `[P]` tasks to parallel agents | Reviewing — review needs no branch |

**Owns:** branch creation, worktree setup, the starting-state check.
**Never:** writes source code, opens the PR (that is `pr`), or merges anything.

## 1. Confirm the starting state

```bash
git status --porcelain     # must be empty
git fetch origin && git log --oneline -1 origin/main
```

If the tree is dirty, **stop and ask**. Uncommitted work belonging to someone
else is not yours to stash, commit, or discard. Say what is uncommitted and wait.

If you are on `main` with commits that never got pushed, say so — that is
usually a previous run that ended badly, and it needs a decision, not a guess.

## 2. Know what the work is

Read the source of truth before naming anything:

- A ticket → read it. `gh issue view <n>` if it is a GitHub issue.
- A spec → `specs/REQ-NNN-<slug>/spec.md`. If it holds any
  `[NEEDS CLARIFICATION]` marker, **stop** — implementation cannot start, and
  `make check` will refuse anyway.
- Neither → the work is not specified. Use `/harness-spec` first.

## 3. Name the branch

`<type>/<ticket-or-slug>-<short-description>` — see `.agents/rules/git-flow.md`
for the full convention. Types: `feat` `fix` `chore` `docs` `refactor` `spike`.

The name is read by humans scanning a branch list. `feat/PROJ-118-leave-workspace`
tells them everything; `feat/updates` tells them nothing.

## 4. Branch, or worktree

Apply the decision rule:

- Clean `main`, and the task needs live reload or a device/simulator →
  `git checkout -b <name>` in the main checkout.
- `main` is dirty, another agent is working, or the change is risky →
  **worktree.** It shares `.git`, so there is no re-clone cost, and
  `.worktreeinclude` copies `.env` across so `make check` runs there.

```bash
git worktree add ../wt-<name> -b <name> origin/main
```

Two agents in one checkout produces a diff nobody can attribute. Do not do it.

## 5. Confirm you are clean before writing anything

```bash
make check
```

A red gate on a fresh branch means you inherited a broken `main`. **Report it and
stop.** Do not start work on top of it — the failure will be attributed to your
diff, and you will spend the session debugging someone else's problem.

## 6. Report

State the branch name, whether it is a worktree and where, the base commit, and
the spec or ticket it implements. That line is what makes the run attributable
later — write it even when it feels obvious.
