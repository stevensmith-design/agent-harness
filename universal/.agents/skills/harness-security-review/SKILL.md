---
name: harness-security-review
description: Run an adversarial security pass over a change or a whole feature — try to break the authorization, the input handling, and the trust assumptions, then report exploitable findings with a reproduction. Use on request before a release, on a sensitive change, or periodically; not on every PR.
license: MIT
metadata:
  harness.tier: gate
allowed-tools: Read Glob Grep Bash(git diff:*) Bash(git log:*) Bash(rg:*) Bash(make check-secrets) Bash(./scripts/gates/:*) Bash(./scripts/finding.sh:*) Bash(./scripts/emit-evidence.sh:*)
---

# security-review

The deep pass. Deliberately **not** wired into every PR — running it constantly
trains people to skim it. Run it on the changes that deserve it, or on a
schedule.

| Use it when | Do not use it when |
|---|---|
| Before a release, or on an auth/payments/data change | On every PR — that is the always-on rule plus the gates |
| The `review` skill's sensitive-path escalation fired | You are the person who wrote it — get an independent actor |
| Periodically over a whole surface | You intend to fix as you go — findings first, fixes after |
| A pen-test or customer security review is coming | The deterministic gates are red — fix those first |

**Owns:** findings. **Mutates:** nothing — read tools only, same reason as
`review`. A reviewer that can patch what it finds stops being a reviewer.

## Posture

Start from green. Run `make check-secrets` and `./scripts/gates/supply-chain.sh`
first — a red deterministic gate is not a finding for this pass, it is a
prerequisite, and reporting one as a discovery wastes the reader's attention on
something a script already said.

You are trying to **break it**, not to confirm it looks fine. A pass with no
findings is a real outcome, but only after you genuinely tried. For each
control, ask "what input, ordering, or identity makes this not run?"

`references/attack-payloads.md` — the concrete inputs for each area below: the
three-identity fixture, the cross-owner requests, the injection strings, the
indirect prompt-injection vectors, and the flat pass/fail conditions. Read it
when you start the pass, not when deciding whether to run one.

## Where to look, in order of what actually ships broken

1. **Authorization.** For every endpoint the change touches: what happens if the
   caller is authenticated but not the owner? Another tenant? A revoked member?
   An expired invite? Read the handler, not the route table — a guard on one
   entrypoint tells you nothing about the other four. Look for authorization
   inferred from the URL, from a client-supplied id, or from the fact the UI
   doesn't show the button.
2. **The gap between check and use.** Where is something authorized, then acted
   on later with a re-read that isn't re-checked? Background jobs, retries,
   webhooks, and cache reads are where this lives.
3. **Input reaching an interpreter.** SQL, shell, template, deserializer, path,
   regex, redirect target, file type. Trace one real user-controlled value all
   the way to its sink and see what happens to it on the way.
4. **Secrets and output.** New logging, new error messages, new fixtures, new
   analytics events. Would this line print a token if the value were set?
5. **Untrusted content.** Anything from a user, a webhook, a dependency, or a
   fetched page — rendered, executed, or fed to an agent. Includes prompt
   injection into anything an LLM reads.
6. **Limits.** What is unbounded? Payload size, page size, retries, file upload,
   loop over user-supplied collection, regex over user text.
7. **Failure modes.** When the auth service is down, the token can't be parsed,
   or the flag is unreadable — does it fail closed or open? Read the code path,
   do not assume.

## Report

Findings only, most severe first. Each one:

- **severity** — `critical` (exploitable now, real impact) · `high` · `medium` ·
  `low` · `informational`
- **file:line**
- **what the flaw is**, stated as a defect
- **reproduction** — the concrete request, input, or sequence. A finding without
  a repro is a hypothesis, and hypotheses get argued away in review.
- **impact** — what an attacker gets. "Bad practice" is not an impact.
- **fix direction** — one line. Do not implement it.

Then: what you examined and found sound, and **what you did not examine** —
areas out of scope, things you could not reach, assumptions you had to make.
A review whose coverage is unstated reads as a clean bill of health for the
whole system, which it never is.

Record each finding with the repo's finding grammar so it can be deduplicated
and go stale when the file changes, rather than living only in prose:

```
./scripts/finding.sh record <severity> security <path>:<line> "<claim>"
```

Then the pass itself: `./scripts/emit-evidence.sh review "<actor>" pass|fail "security-review: N critical, M high"`.

## Boundaries

Do not run active scanners, fuzzers, or exploits against any deployed
environment from this skill — reading code and reasoning is the scope. Live
testing needs written authorization naming the target and the window, and that
is a decision for a person, not an agent.
