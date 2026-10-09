# Deploy modules

One file per deploy target. The Makefile and the generated CI files speak verbs;
only these files know a vendor CLI — the same boundary that makes the stack
adapters work.

Select them per environment in `harness.config.yaml` under `deploy.environments`.
Multiple targets run **in the listed order**, which is how you get migrations
applied before the app that depends on them.

## The verb contract

| Verb | Must | Notes |
|---|---|---|
| `deploy_plan` | show what *would* change, mutate nothing | required if the vendor offers a dry run |
| `deploy_apply` | perform the deploy | may deploy without taking traffic |
| `deploy_promote` | send traffic to what was deployed | only where deploy and cutover are separable |
| `deploy_rollback` | return to the previous good state | must state honestly if the platform has none |
| `deploy_status` | report what is currently live | |

Every verb reads `DEPLOY_ENV` (`preview` / `staging` / `production`) and must
refuse to touch production unless `DEPLOY_CONFIRM=1` is set — which only a human
gate or an approved CI environment sets.

## Rollback is not uniform, and that matters

- **Cloud Run** — real rollback. Revisions are immutable, traffic is a pointer,
  reverting takes seconds and no rebuild.
- **Vercel** — `promote` an earlier deployment. Effectively a rollback.
- **Supabase migrations** — **none.** No down migrations, no revert command.
  `migration repair` rewrites the history table without touching the schema,
  which leaves the database and its history disagreeing. The only real recovery
  is restore-from-backup plus a compensating forward migration.

That asymmetry is why `production` defaults to `approval: true` and why the
Supabase module refuses to run without an explicit confirmation.
