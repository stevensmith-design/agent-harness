# Security in this harness

Security here is deliberately **tiered**. Everything cheap and objective runs on
every change; everything expensive runs when it is worth it. A security control
that runs constantly and finds nothing is a control people learn to skim.

## The four tiers

| Tier | What | When | Cost |
|---|---|---|---|
| **Always on** | `.agents/rules/security.md` — authz, input handling, secrets, untrusted content | every change, loaded into context | free |
| **Every PR** | secrets + personal-data boundaries, dependency and skill trust, supply chain, protected paths, rule coverage, surface policy | `make check` + CI | seconds |
| **On escalation** | full review + `/harness-security-review` when the diff touches a sensitive path | automatic — `scripts/gates/policy.sh` resolves the diff to its `surfaces:` and applies that surface's risk and rung | minutes |
| **On demand** | `/harness-threat-model` before building · `/harness-security-review` before release · dependency and SAST scans | a person or a schedule decides | hours |

The escalation tier is the important one: it means you do not have to remember
to be careful, because the *path* decides. A one-line change to a workflow file,
an IAM policy, a migration, or anything named `auth` gets the deep pass whether
or not anyone thought to ask for it.

## What runs every time

- **`.agents/rules/security.md`** is `trigger: always`, so it is in context for
  every change. It is short on purpose — four failure classes, not a manual.
- **`scripts/gates/secret-scan.sh`** — credential shapes, and `.env` tracked by git.
- **`scripts/gates/data-boundary.sh`** — protected personal/private paths,
  sensitive filenames, and structured personal-data shapes; reports paths, not values.
- **`scripts/gates/supply-chain.sh`** — unpinned CI actions, committed templates
  holding real values, missing lockfile.
- **`scripts/gates/dependency-safety.sh`** — mutable/non-registry dependency
  sources, unexpected registry hosts, missing integrity, and install scripts.
- **Skill gates** — portable metadata plus instruction-trust patterns, before a
  vendored candidate enters the live skill tree.
- **`scripts/gates/protected-paths.sh`** — a PR that edits the harness alongside
  product code, which is how gates get quietly relaxed.
- **Permission tiers** (`.claude/tiers/`) — the agent cannot push, cannot read
  `.env`, cannot edit its own rules, and is sandboxed to an allowlisted network
  where the runtime supports it.

## What you invoke

**`/harness-threat-model`** — before building anything with money, personal data,
credentials, uploads, or multi-tenancy. Produces `docs/security/threat-model-*.md`
and, more importantly, acceptance criteria in the spec. A threat model that did
not change the spec was a writing exercise.

**`/harness-security-review`** — an adversarial pass over a change or a whole surface.
Read-only, findings-with-reproductions, and it reports what it did *not* examine.
Run before a release, on a sensitive change, or on a schedule.

**`/harness-dependency-intake`** — before any package, SDK, action, plugin,
CLI, or skill is added or updated. It inspects identity, licence, archive,
permissions and lifecycle hooks without executing the candidate. The agent-loop
hook blocks undeclared installs and permanently blocks global/download-to-shell forms.

## What this harness does not do

Named honestly, because a gap you know about is manageable and a gap you assume
is covered is not:

- **No SAST.** Add CodeQL, Semgrep, or your language's equivalent as a separate
  workflow when the codebase is worth it.
- **No always-on live vulnerability feed.** Intake runs the ecosystem's
  read-only advisory check and dates the result, but a deterministic CI gate
  cannot prove the feed is current. Add a pinned scheduled scanner or updater
  when the codebase needs continuous coverage.
- **The secret scan is a shape-matcher, not a scanner.** It catches the common
  formats. `gitleaks` or `trufflehog` in CI is strictly better — this exists so
  there is a floor with no dependencies, not a ceiling.
- **No runtime protection.** No WAF, rate limiting, or anomaly detection is
  configured here; those live in your infrastructure.
- **No live testing.** Scanning or exploiting a deployed environment requires
  written authorization naming the target and the window. That is a person's
  decision, never an agent's.

## Adding a scanner properly

Whatever you add, four rules make the difference between a gate and a placebo:

1. **Pin the tool version** and verify the download. A scanner that
   auto-updates changes your build's behaviour without a commit.
2. **Make a broken scanner fail the build.** Distinguish "found nothing" from
   "could not run" — `|| true` on a scanner is worse than not having it, because
   everyone now believes it is running. `scripts/lib.sh`'s `sgrep`/`must`
   helpers exist for exactly this.
3. **Ship a fixture it must flag and one it must not.** An unproven detector is
   a hope.
4. **Budget the false positives.** A gate that fires on correct work gets
   disabled within a month, and a disabled gate is worse than none.
