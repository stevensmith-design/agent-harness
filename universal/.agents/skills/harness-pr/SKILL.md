---
name: harness-pr
description: Open a pull request and drive it to mergeable — fill every required section with real evidence, respond to review findings, verify each fix before claiming it resolved. Producer side: use when your own work is complete and ready for review, or when your PR has feedback to address. Reviewing someone else's change is /harness-review.
license: MIT
metadata:
  harness.tier: workflow
allowed-tools: Read Glob Grep Edit Write Bash(git:*) Bash(gh pr:*) Bash(gh api:*) Bash(make:*) Bash(./scripts/:*)
---

# pr

A PR is where a change stops being your work and becomes the team's. What it
carries is evidence, not a summary of what you did.

| Use it when | Do not use it when |
|---|---|
| Work is done and gates are green | Gates are red — fix those first, they are cheaper than a reviewer |
| A reviewer left findings to address | Reviewing someone else's PR — that is `review` |
| A PR went stale and needs its base updated | You want to bypass the configured review policy |

**Owns:** the PR body, pushing the branch, responding to findings, and the
owned-work lifecycle through verified merge and cleanup. **Never:** approves
its own PR, bypasses the configured risk-based review, or edits the reviewer's
comments. Low-risk work uses the producer checklist; it does not invent an
independent-review requirement that the configured policy does not have.

## Opening it

1. **Gates first.** `make check`, and `make verify` for anything user-visible.
   Opening a red PR spends a reviewer's attention on something a script would
   have caught in thirty seconds.
2. `git push -u origin <branch>` directly. The network-command guard admits
   only an explicit non-default branch. Never push work owned by someone else.
3. Open it against `main`, filling **every** section of
   `.github/pull_request_template.md`. Do not delete sections; CI fails on
   missing ones, and the empty-verification check fails on a section that only
   contains the comment.

### What each section actually needs

- **What and why** — one paragraph, linked to the spec. Not a file list.
- **Changes** — a change list, not a diff summary. "Members can now leave a
  workspace" beats "modified 4 files in src/settings".
- **How this was verified** — the commands you ran and **what they printed**.
  For user-visible change, a screenshot or a recording. `make check` alone is
  not verification of behaviour; it is verification of well-formedness.
- **Not verified** — what this change could break that nothing above could
  see. Start from the human lane in `docs/quality/README.md` and keep the lines
  that apply: how it feels, visual detail, IME input, environments CI does not
  run, sequences of actions, states no fixture renders. Written as a brief for
  the person who will explore it — *"withdraw, then resubmit, as an approver"* —
  not a disclaimer. CI fails the section empty; "Nothing: <why>" is an answer.
  The `feature` workflow writes this brief for you — paste it, do not rewrite it.
- **Blast radius** — which surfaces from `harness.config.yaml` this touches, and
  what else could break. Reviewers use this to decide where to look.
- **Review focus** — where you actually want eyes. This is the highest-leverage
  section and the one everyone leaves blank.
- **Harness changes** — if the diff touches `AGENTS.md`, `.agents/`, workflows or
  ADRs, say why, and add `harness-change: intentional`. Otherwise the
  protected-paths gate will fail the PR, correctly.

## Responding to findings

For each finding a reviewer raised:

1. Fix it, or say clearly why it is not a defect. "Fixed" and "disagree, here is
   why" are both fine answers. Silence is not.
2. **Verify the fix before claiming it.** `git show <sha>` the change you
   actually pushed, and re-run the gate that would catch a regression. Claiming
   a fix you have not looked at is the fastest way to lose a reviewer's trust.
3. Reply on the thread with the commit sha, so the reviewer can check in one click.
4. Re-request review. Do not resolve the reviewer's thread yourself — they close
   what they opened.
5. **Then `./scripts/review-rounds.sh`.** A loop that keeps going round is the
   finding. At `git.max_review_rounds` with a blocking finding still open, it
   records `blocked` evidence and stops: a person decides whether the finding is
   wrong, the spec never settled, or the change should be split. Reaching the
   cap is never approval, and nobody may merge on it.

Never weaken a test, loosen a lint rule, or add an allow-list entry to make a
finding go away. If a rule is genuinely wrong, that is a `harness-retro`
conversation, not a quiet edit inside a feature PR.

## Keeping it mergeable

- Behind base: use `gh pr update-branch <number> --rebase` when the repository
  supports it, then wait for the new checks. Do not locally rewrite a published
  branch or force-push it.
- A PR growing past a few hundred lines of real change should be split. Say so.
- Stale for days: rebase, re-run gates, and ping. A PR nobody has looked at is
  the producer's problem to solve.

## Merging and cleanup

1. Read draft state, base, mergeability, review decision, and required checks.
   Low risk needs the producer checklist; standard risk needs its one read-only
   reviewer; configured high-risk surfaces also need named human approval.
2. If behind, update the branch and wait for the replacement check run. Never
   use `--admin`, bypass a queue, or treat a still-pending check as green.
3. Merge with the repository's configured method and request branch deletion.
   Then query the PR again: command success is not evidence unless state is
   actually `MERGED`.
4. Only after that confirmation, delete the local branch and remove a worktree
   if this run created it and it is clean. Preserve shared, unknown, or dirty
   branches/worktrees and report the ambiguity once. The agent performs these
   routine commands; it does not print a shell recipe for the person to run.
