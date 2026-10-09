# CI/CD

The pipeline is described **once**, in `harness.config.yaml`, and rendered per
platform by `make ci-gen`. Moving from GitHub to GitLab is a re-render, not a
rewrite. Generated files are committed and CI fails if they drift from the config.

```
harness.config.yaml ─┬─► .github/workflows/{gates,deploy}.yml
   + adapter ci_setup ├─► .gitlab-ci.yml
   + deploy modules  └─► bitrise.yml
```

Three things keep a CI file from having to know your stack:

- **`ci_setup()` in the adapter** emits the toolchain steps. That is what removes
  the "TODO: set up your toolchain" line — the adapter knows Node from Flutter,
  so the template does not have to.
- **`scripts/deploy/<target>.sh`** is the only place a vendor CLI appears.
- **Everything else speaks `make`.** The CI file runs `make test`, never `vitest run`.

## Pipeline shape

| Stage | Runs | Needs a toolchain? |
|---|---|---|
| deterministic | eight gates + drift checks + harness-verify | no — fails in seconds |
| toolchain | deps, lint, format, typecheck, test | yes |
| pr-contract | the PR body carries real verification evidence | no |
| deploy | per environment, after gates pass | yes |

Deterministic first is deliberate: a malformed change fails before you have paid
for a dependency install.

## Deploy environments

```yaml
deploy:
  enabled: true
  environments:
    - name: preview
      targets: [vercel]
      trigger: pull_request
    - name: production
      targets: [supabase, cloud-run]   # order matters: schema, then service
      approval: true
      staged_cutover: true
```

Targets run in the listed order. `staged_cutover` splits deploy from traffic
cutover so the approval gate has something to sit between.

## The gate you must set by hand

`environment: production` in a workflow is a **reference**. The gate — required
reviewers, wait timer, branch policy — lives in repo settings and **cannot be
expressed in YAML**. `make ci-gen` prints the instruction; nothing in this repo
can verify you did it.

Do it, and put deploy credentials in that *environment's* secrets rather than
repo secrets. Environment secrets are unreadable until the protection rule
passes — that is the actual security boundary, not the label.

## Platform notes

These are the facts that bite, per target.

**Vercel** — no official GitHub Action; the CLI is the supported path
(`pull` → `build` → `deploy --prebuilt`). `--prebuilt` **omits Vercel's System
Environment Variables at build time**; if your framework needs them, drop the
flag. Vercel's OIDC is outbound only, so there is no keyless path *into* Vercel —
`VERCEL_TOKEN` is long-lived and belongs in an environment secret. If you deploy
from CI, disable Vercel's own Git integration (`git.deploymentEnabled: false`)
or you get two deploys racing on one commit.

**Supabase** — `supabase db push --dry-run` before every push, always. **There
is no rollback.** No down migrations, no revert command; `migration repair`
rewrites the history table without touching the schema and will leave the two
disagreeing. Recovery is restore-from-backup plus a compensating forward
migration. `db reset` drops the database and must never be reachable from a
production job. If Supabase's GitHub integration is enabled it applies migrations
on merge itself — running the workflow too is the same double-deploy problem.

**Cloud Run** — the only target here with a real rollback: revisions are
immutable and traffic is a pointer, so reverting takes seconds and no rebuild.
Deploy with `--no-traffic --tag`, verify at the tagged URL, then flip. Tag images
by commit SHA, never `latest`. `--set-secrets` **replaces** all secrets;
`--update-secrets` merges. Secrets exposed as env vars resolve once at instance
start, so pin a numeric version; mounted as volumes they refetch, so `latest`
works and rotation needs no redeploy.

## Keyless auth

GCP, AWS and Azure accept GitHub OIDC — use it. The job needs
`permissions: { contents: read, id-token: write }`; without `id-token` there is
no token and you are back to a long-lived key.

The pool **must** carry an attribute condition. Without one, any repository on
GitHub can enter it. Bind on `repository_id` and `repository_owner_id` rather
than a name-parsed `sub`: GitHub is moving subjects to an immutable ID-embedded
form, and name-based matches break the next time a repo is renamed or transferred.

Vercel and Supabase have no keyless path. That is a documented, accepted risk —
scope the token to a protected environment and say so in the PR.

## Keeping actions current

Vendor tutorials run two to three majors behind the action ecosystem. Do not
copy versions out of them. `make pin-actions` resolves each tag to the commit
SHA it currently points at and rewrites it as `owner/repo@<sha> # tag` — pinning
means you now own the update decision, so pair it with Dependabot.

Two 2026 changes worth knowing: runners default to **Node 24** (pinning an old
action major does not avoid this — old majors stop working as Node 20 is
withdrawn), and `actions/checkout` v7 **refuses by default to check out fork
code under `pull_request_target`**, which closes the pwn-request class. Do not
reach for `allow-unsafe-pr-checkout`.
