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
| A PR went stale and needs a rebase | You want to merge your own PR unreviewed — never |

**Owns:** the PR body, pushing the branch, responding to findings.
**Never:** approves the PR, merges without an independent review, or edits the
reviewer's comments.

## Opening it

1. **Gates first.** `make check`, and `make verify` for anything user-visible.
   Opening a red PR spends a reviewer's attention on something a script would
   have caught in thirty seconds.
2. `git push -u origin <branch>` — the `build` tier denies push, so this needs
   `make tier-release` or a human. That gate is deliberate.
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

- Conflicts: rebase onto `main`, force-push **with lease** to your own unmerged
  branch. Do not repeatedly merge `main` in — it weaves the history into
  something no one can review.
- A PR growing past a few hundred lines of real change should be split. Say so.
- Stale for days: rebase, re-run gates, and ping. A PR nobody has looked at is
  the producer's problem to solve.

## Merging

Squash into `main`, delete the branch. Required first: gates green, an
independent review passed by someone who is not the producer, and — for a
surface listed in `governance.human_approval_required_for` — a named human
approval. You do not merge your own PR on your own say-so.
