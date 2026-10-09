---
name: harness-pipeline
description: Build or change the CI/CD pipeline — wire a stack's toolchain, add a deploy target, set up keyless cloud auth, or add a stage. Use when CI does not exist yet, when a deploy target is being added, or when the pipeline needs a new job.
license: MIT
metadata:
  harness.tier: install
allowed-tools: Read Glob Grep Edit Write Bash(make:*) Bash(./scripts/:*) Bash(git:*) Bash(gh:*)
---

# pipeline

CI files here are **generated** from `harness.config.yaml`. You change the
config and the adapter, not the YAML — so the same pipeline renders for GitHub,
GitLab and Bitrise, and moving platform is a re-render rather than a rewrite.

| Use it when | Do not use it when |
|---|---|
| Standing CI up for the first time | Fixing a failing test — that is the test's problem |
| Adding a deploy target or environment | Running a deploy — that is `/harness-release` |
| Wiring keyless cloud auth | Hand-editing a workflow file (it will be overwritten) |
| Moving to another CI platform | Debugging one flaky job |

**Owns:** `harness.config.yaml` (`ci:` and `deploy:`), `scripts/adapters/*.sh`
`ci_setup`, `scripts/deploy/*.sh`. **Produces:** generated CI files + an
explicit list of what a human must still do by hand.

## 1. Make the gates run first

Before any deploy work, the deterministic pipeline must be green.

- `ci.platforms` — which files to render. `github` is primary.
- The **toolchain step comes from the adapter**, not the CI file:
  `ci_setup()` in `scripts/adapters/<adapter>.sh` emits the setup steps. If your
  stack needs a version file (`.nvmrc`, `pyproject.toml`), make sure it exists —
  a setup action pointed at a missing file fails confusingly.
- `make ci-gen` then `make check`. Commit the generated files; CI fails on drift.

## 2. Add a deploy target

Each environment lists targets that run **in order** — put migrations before the
app that depends on them.

```yaml
deploy:
  enabled: true
  environments:
    - name: production
      targets: [supabase, cloud-run]   # schema first, then the service
      approval: true
      staged_cutover: true
```

A target that does not exist yet gets a new file in `scripts/deploy/`
implementing five verbs — `plan`, `apply`, `promote`, `rollback`, `status`.
`scripts/deploy/README.md` has the contract. Two rules: `plan` must mutate
nothing, and `rollback` must state honestly if the platform has none rather than
pretending.

## 3. Wire authentication

**Keyless where it exists** (GCP, AWS, Azure). For GCP you need, once, by hand:

1. A Workload Identity Pool and Provider, **with an attribute condition**. Bind
   it on `repository_id` and `repository_owner_id` — not on a name-parsed
   `sub`, which breaks when the repo is renamed or transferred.
2. A deploy service account with `roles/run.developer` on the service,
   `roles/artifactregistry.writer` on the repo, and
   `roles/iam.serviceAccountUser` **on the specific runtime service account** —
   scope that one to the SA, never the project. Project-level lets the deployer
   act as every identity in the project.
3. `GCP_WIF_PROVIDER` and `GCP_DEPLOY_SA` as repository *variables*.

**Where keyless does not exist** — Vercel and Supabase — the token is long-lived.
Put it in the *environment* secret, not a repo secret, so it is unreadable until
the protection rule passes. Say so in the PR; it is an accepted risk, not an
oversight.

## 4. Set the gate a human must set

`make ci-gen` prints it, because it cannot do it: **required reviewers on the
production environment are configured in repo settings and cannot be expressed
in YAML.** Emitting `environment: production` alone gives you a label, not a
gate. Do not report the pipeline as finished until a person has set it.

## 5. Prove it

- Open a throwaway PR and watch the gates run. Green on a real PR is the only
  evidence that counts.
- Run `./scripts/deploy.sh preview plan` locally. It should describe the change
  and touch nothing.
- Deploy to preview, then staging, before production is ever configured.
- Confirm the platform's own Git integration is off if you deploy from CI —
  two pipelines racing on one commit is a genuinely bad day.

## Report

What renders, what each environment deploys, which credentials are keyless and
which are not, and **the list of things a human must still do by hand**. That
last list is the deliverable; everything else is generated.
