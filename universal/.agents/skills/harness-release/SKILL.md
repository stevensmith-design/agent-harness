---
name: harness-release
description: Cut a release and take it to production safely — verify the gates, tag, deploy without traffic, verify live, then cut over behind a human approval, with the rollback known before you start. Use when shipping to production or preparing a release.
license: MIT
metadata:
  harness.tier: gate
  harness.destructive: "true"
allowed-tools: Read Glob Grep Bash(make:*) Bash(./scripts/:*) Bash(git:*) Bash(gh:*)
---

# release

The step with the largest blast radius in a normal week.

| Use it when | Do not use it when |
|---|---|
| Shipping to production | Deploying a preview — that is automatic on PR |
| Preparing release notes and a tag | Gates are red — fix those first |
| Rolling back a bad release | Nobody asked. **An agent never releases on its own initiative.** |

**Never:** sets `DEPLOY_CONFIRM=1` on its own. That flag comes from a person or
from an approved CI environment, and inventing it defeats every gate below it.

## Before anything

1. `make check` green on the commit you are releasing — not on some other commit.
2. `make verify` green.
3. An independent review passed, by someone who is not the producer.
4. **Know the rollback before you start.** Write it down in the release notes.
   It differs per platform and the difference is the whole risk picture:
   Cloud Run flips traffic back in seconds; Vercel promotes an earlier
   deployment; **Supabase migrations have none at all** — recovery is a restore
   from backup plus a compensating forward migration.
5. If the release includes a migration, read `/harness-migration` first. A schema change
   and an app deploy are two releases that happen to travel together, and they
   are ordered: expand the schema, deploy the app, contract later.

## Cutting it

```bash
git tag -a vX.Y.Z -m "…" && git push origin vX.Y.Z
```

Release notes from the merged PRs since the last tag — what changed, what to
watch, and the rollback. Written for whoever is on call at 3am, not for a
changelog reader.

## Deploying

```bash
./scripts/deploy.sh production plan     # always. reads, mutates nothing
# → human approval gate
./scripts/deploy.sh production apply    # deploys WITHOUT taking traffic
```

Then **verify the thing you just deployed, not the thing that is still live.**
Cloud Run gives it a tagged URL; Vercel `--skip-domain` leaves it addressable
without traffic. Hit the real endpoint. A green build is not a working release.

```bash
./scripts/deploy.sh production promote  # cut traffic over
```

For anything risky, promote in steps — `PROMOTE_PERCENT=10`, watch, then 100.

## After

Watch for one full traffic cycle before calling it done: error rate, latency,
the specific thing this release changed. Then record it:

```bash
./scripts/emit-evidence.sh execute_tool "<actor>" pass "release vX.Y.Z to production"
```

## Rolling back

Decide fast and decide early — a rollback in the first ten minutes is routine;
an hour in, with data written against the new schema, it is an incident.

```bash
./scripts/deploy.sh production rollback
```

Roll back **first**, diagnose after. The instinct to find the cause before
reverting is what turns a five-minute blip into an outage. If the release
included a migration, the rollback is not symmetric — the code reverts, the
schema does not, and that gap is exactly why migrations expand before they
contract.

Afterwards, write down what happened and feed it to `/harness-retro`. A release
that went wrong and taught nothing has cost you twice.
