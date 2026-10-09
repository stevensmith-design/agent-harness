---
name: harness-verify
description: Prove the application actually runs and serves, then record the recipe so the next agent does not have to rediscover it. Use before claiming a change works, and whenever the run recipe changes.
license: MIT
metadata:
  harness.tier: gate
allowed-tools: Read Write Edit Bash(make:*) Bash(./scripts/:*) Bash(curl:*)
---

# verify

**Owns:** the run recipe and the evidence that it ran. **Never:** changes
product code to make verify pass — a recipe that needs the app altered to
succeed is reporting a real failure.

`make check` proves the code is well-formed. `verify` proves the app *runs*.
Those are different claims and teams routinely conflate them.

| Use it when | Do not use it when |
|---|---|
| Before saying a user-visible change works | For a docs-only or comment-only change |
| After a dependency, config, or build change | As a substitute for tests — it is in addition |
| The build recipe changed | You have not run `make check` yet — do that first |

## Procedure

1. Start from a state as close to clean as you can afford: fresh deps if the
   lockfile changed, no dev server already running.
2. Run `make verify`. It calls the adapter's `cmd_verify`, which must do the
   minimum that would embarrass you if it failed in front of a user: the app
   builds, starts, and answers.
3. If `cmd_verify` does not exist or does not actually prove anything, **write
   it now** in `scripts/adapters/<adapter>.sh`. That is the durable artifact —
   the point of this skill is that nobody rediscovers the run recipe twice.
4. For user-visible change, capture the result: a screenshot, a recording, or
   the response body. Attach it to the PR under "How this was verified".
5. **Say what verify did not see.** `verify` proves the app answers, and a
   screenshot proves one state at one width. For UI, run `make render-audit`
   — it measures what can be measured on the rendered page (tap targets, text
   size, overflow, overlap) at phone and desktop widths, and writes a contact
   sheet for the person. What is still unseen goes in the PR's **Not verified**
   section, starting from `docs/quality/README.md`.
6. Evidence is recorded automatically by `make verify`. If you verified by hand,
   record it: `./scripts/emit-evidence.sh verify "<actor>" pass "<what you did>"`.

## What a good `cmd_verify` looks like

- **Web:** production build succeeds, server starts, `/` returns 200.
- **Mobile:** the bundle or debug binary compiles for a real target.
- **Service:** it boots, the health endpoint answers, a migration runs clean.
- **Library:** it builds, and the published example imports and runs.

Keep it under a minute. A verify step slow enough to skip is a verify step that
gets skipped.

## Anti-churn

Only rewrite the recipe when a run was actually steered wrong by the old one.
This file should not produce a diff on every use.
