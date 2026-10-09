# Universal Harness

A stack-agnostic starting point for instrumenting a codebase so AI coding agents behave the way your best engineer would — repeatably, on a fresh context, in an unfamiliar area of the code.

It is one core plus a thin per-stack adapter. React/Next web, React Native/Expo, and Flutter adapters ship in the box; `generic` is the fallback for anything else.

```bash
make setup          # first run: env, hooks and skill symlinks; no packages
make harness-init   # (or run the /harness-init skill) fill in harness.config.yaml
make deps           # only after /harness-dependency-intake approval
make check          # lint + format + typecheck + test + design-token drift
make harness-verify # is the harness itself intact? (--level 1|2|3)
```

## The idea in one paragraph

A harness is an **instruction graph** plus an **enforcement system** plus a **maintenance loop**. The instruction graph tells an agent what is true here and routes it to exactly one owner file per rule. The enforcement system makes the rules that matter *checkable* — hooks, scripts, CI — rather than merely written down. The maintenance loop turns each repeated failure into a durable artifact in the layer that owns it. Anything that only instructs is a prompt library; anything that only enforces is a linter.

## Layout

| Path | What it is | Rung |
|---|---|---|
| `AGENTS.md` | **Canonical** instruction file. ≤80 lines of rules, each traceable to a failure. | L1 |
| `CLAUDE.md`, `.cursor/rules/`, `.github/copilot-instructions.md` | **Generated** from `AGENTS.md` + `.agents/rules/`. Never edited by hand. | L1 |
| `harness.config.yaml` | The single adaptation point: stack, paths, commands, surfaces, risk, gates. | L1 |
| `.agents/rules/*.md` | Path-scoped constraints (`paths:` frontmatter) — security, api-design, data-access, git-flow, tokens, tests. | L1 |
| `.agents/skills/*/SKILL.md` | Repeatable procedures, portable Agent Skills format. | L1 |
| `skills-lock.json` + `docs/skills-catalog.md` | Vendored capability skills, pinned by commit SHA, licence-checked. | L2 |
| `.agents/memory/MEMORY.md` | Durable project memory: index + topic files. | L1 |
| `Makefile` + `scripts/adapters/` | The one command vocabulary. Adapters: react-web, react-native, flutter, node-api, python-api, generic. | L1 |
| `scripts/gates/` | Twenty-three deterministic checks (plus overlay gates): tokens/design coherence, secrets and personal-data boundaries, spec clarity, protected paths, branch hygiene, rule coverage, supply/dependency safety, portable and trusted skills, vendored-skill integrity, instruction budgets, product registers, surface policy, API contracts/agreements, learning, hook parity, namespace and evidence. All fail-closed; `make gate-selftest` proves rejection paths. | L2 |
| `.claude/hooks/`, `.claude/tiers/` | Enforcement at the agent loop; three permission tiers. | L2 |
| `.github/workflows/`, `.gitlab-ci.yml` | **Generated** from the config by `make ci-gen` — gates, toolchain, and gated deploys. | L2 |
| `scripts/deploy/` | One module per deploy target: vercel, cloud-run, supabase, static. | L2 |
| `docs/decisions/` | MADR ADRs — why the agent may not "improve" this. | L1 |
| `specs/` | Spec → plan → tasks, with `[NEEDS CLARIFICATION]` and `[P]` markers. | L1 |
| `.harness/` | **Opt-in L3**: stateful workflows, evidence schemas, producer-cannot-self-certify. | L3 |
| `evals/` | **Opt-in L4**: Data / Task / Scorers cases with a vendor-free runner. | L4 |

Security is tiered rather than uniform — always-on rules, per-PR gates, escalation by path, and `/harness-threat-model` + `/harness-security-review` on demand. `docs/security.md` explains the tiering and, more usefully, states what the harness does *not* do.

Starting from an idea rather than an existing backlog? `/harness-product-start`
turns in-scope notes and references into the existing PRD, requirement register,
questions and first bounded spec. It deliberately stops before scaffolding or
dependency installation. Reusable lessons can be prepared with
`/harness-upstream-feedback`, which writes a sanitized local proposal and never
posts it automatically.

Read `HARNESS-GUIDE.md` for why each part exists and when to add the next rung. Read `HARNESS-MANIFEST.md` for the fill-in checklist.

## Multi-tool by construction

`AGENTS.md` and `.agents/` are the source of truth. `make harness-sync` generates the tool-specific views — Claude Code, Cursor, Copilot — and `make harness-sync-check` fails CI if any of them has drifted. One rule, one owner file, N tools.
