# Harness manifest — what is here and how to adopt it

Read `HARNESS-GUIDE.md` for the reasoning. This file is the checklist.

## The one build artifact

`harness-init.skill` bundles a full copy of this harness in `assets/`, so it is a
**build output, not a source file**. Left sitting in a folder it goes stale the
moment the harness changes, and a stale installer silently scaffolds an old
harness into a new repo — worse than having no installer.

```bash
make harness-package     # build it from the current tree
```

Save it to your agent account, then delete the file. Rebuild whenever you need a
fresh one. It refuses to build from a tree whose generated files have drifted,
so the artifact can never be newer than the checks that passed.

## Adopt it

```bash
./scripts/install.sh <your-repo>     # refuses to clobber; carries no .git
cd <your-repo>
git switch -c chore/install-harness  # the gates refuse to run on the default branch
make setup                           # env, hooks, skill symlinks, deps
make harness-init                    # fill in harness.config.yaml (or run /harness-init)
make check                           # must go green before you trust anything else
make harness-verify                  # is the harness itself intact?
```

Do not use `cp -R`. With a trailing slash it nests the harness inside your repo;
without one, the shell glob drops every dotfile — `.agents/`, `.claude/`,
`.github/`, `.githooks/` — which is two thirds of the harness, and `make setup`
will report success on what is left. `install.sh` also stops rather than
overwriting a `Makefile`, `README.md` or `CLAUDE.md` you already have.

`make setup` creates the `.claude/skills/` and `.claude/rules/` symlinks into
`.agents/`. They are not committed as symlinks, because archive extraction and
some filesystems turn a symlink into a text file containing its target — and a
broken symlink there is a silently missing skill. `make harness-verify` checks
they resolve; `make link-skills` repairs them.

The `/harness-init` skill is the better path for an **existing** codebase — it
inventories what is already there, merges any existing agent rules instead of
overwriting them, and stops on the first failed gate.

## File map

```
.
├── AGENTS.md                       ★ canonical instructions (≤80 lines, budgeted)
├── CLAUDE.md                       generated — @AGENTS.md + Claude-only tail
├── harness.config.yaml             ★ the single adaptation point
├── HARNESS-GUIDE.md                why each part exists
├── HARNESS-MANIFEST.md             this file
├── Makefile                        the one command vocabulary
├── .env.sample .gitignore .worktreeinclude .mcp.json.example
├── skills-lock.json                ★ vendored capability skills, pinned by commit + hash
│
├── .agents/                        canonical, tool-neutral
│   ├── rules/*.md                  path-scoped constraints (paths: frontmatter)
│   ├── skills/*/SKILL.md           portable Agent Skills format
│   ├── memory/MEMORY.md            index + topic files, budgeted
│   └── runs/                       evidence trail (*.jsonl)
│
├── .claude/                        Claude Code view
│   ├── settings.json               active permission tier + hooks
│   ├── tiers/{explore,build,release}.settings.json
│   ├── hooks/{session-start,block-protected,block-sensitive-access,block-package-install,post-edit-check,gate-done}.sh
│   ├── agents/reviewer.md          independent reviewer, no write tools
│   └── skills/ rules/              symlinks into .agents/
│
├── .cursor/rules/*.mdc             GENERATED — do not edit
├── .github/
│   ├── copilot-instructions.md     GENERATED — do not edit
│   ├── instructions/*.md           GENERATED — do not edit
│   ├── pull_request_template.md    evidence contract, enforced in CI
│   └── workflows/{gates,governance,agent-review}.yml
├── .githooks/pre-commit            prevent locally what CI can only detect
├── .gitattributes                  marks generated views linguist-generated
├── .mcp.json.example               placeholder MCP servers — tokens by ${VAR} only
├── .env.sample                     variable NAMES only, never values
│
├── scripts/
│   ├── lib.sh run.sh               config reader + verb dispatch
│   ├── adapters/{generic,react-web,react-native,flutter,node-api,python-api}.sh  ← the only stack-aware files
│   ├── gates/{design-tokens,secret-scan,data-boundary,spec-clarity,protected-paths,
│   │          instruction-budget,branch-hygiene,rule-coverage,supply-chain,
│   │          dependency-safety,skill-frontmatter,skill-trust,skills-integrity,
│   │          requirements,policy,design-system,
│   │          hook-parity,evidence,invariants,learning,api-contract,api-agreements}.sh
│   ├── ci/pr-body.sh               the PR body carries evidence and a Not verified section
│   ├── render-audit.mjs            measures the rendered UI (tap targets, text, overflow, overlap) + contact sheet
│   ├── declare-intent.sh           branch-bound, reasoned harness-edit unlock
│   ├── declare-dependency-change.sh  short-lived branch record after dependency intake + operator approval
│   ├── sub.sh                      portable in-place substitution — `sed -i` without the platform trap
│   ├── finding.sh                  record/list/resolve findings in one parseable identity line
│   ├── validate-skills.py scan-skill-trust.py  portable metadata + instruction trust before discovery
│   ├── check-dependency-safety.py  dependency sources, lock integrity and lifecycle scripts
│   ├── validate-tokens.py          token-graph validator: backs the design skills AND check-design
│   ├── validate-api-proposals.py   per-operation status + agreement-drift: backs check-api AND check-agreements
│   ├── gate-selftest.sh            proves each gate REJECTS — run by `make ci`
│   ├── install.sh                  install into a repo without clobbering it
│   ├── overlay.sh                  apply a named overlay — ADDS files, never replaces
│   ├── overlay-config.py           line-level config patcher (keeps the comments)
│   ├── deploy.sh deploy/{vercel,cloud-run,supabase,static,none}.sh
│   ├── harness-init.sh harness-sync.sh verify-harness.sh emit-evidence.sh pin-actions.sh sweep-guard.sh
│   ├── review-rounds.sh            caps the review-and-fix loop — escalates, never approves
│   ├── ci-gen.sh skills.sh          CI rendering · capability-skill vendoring
│   ├── doctor.sh                   reports missing CLIs from tooling: — never installs
│   ├── package-skill.sh            builds harness-init.skill — a build artifact, not a source file
│
├── docs/
│   ├── product/                    PRD.md (narrative, skill: prd) · requirements.md (the register)
│   │                               · decisions.md (product ledger + do-not-re-propose)
│   │                               · domain-rules.md (invariants + who enforces each)
│   │                               · questions.md (questions that close only into a DEC-/INV-/REQ-)
│   ├── quality/                    defects.md (each defect's gap, sweep, lesson) · README.md (the
│   │                               human lane; what "good" looks like) · render-pages.txt · examples/
│   ├── decisions/                  MADR ADRs, with a Confirmation section
│   ├── devlog/ incidents/          OPT-IN L3 — session trail · postmortems
│   ├── architecture/
│   ├── api-proposal/               OpenAPI proposals (x-status + x-req per
│   │                               operation) + AGREEMENTS.md, the sign-off
│   │                               ledger. x-req is the join across all three
│   ├── security.md ci-cd.md skills-catalog.md security/ mock-mode.md
│
├── overlays/<name>/               a domain pack: overlay.yaml + files/ + config.patch.yaml
│   └── ai-product/                model in the critical path — boundaries, evals, model choice
├── specs/000-template/{spec,plan,tasks}.md · spec.example.md (one spec filled in)
├── evals/                          OPT-IN L4 — cases + vendor-free runner
│   ├── run-evals.sh                exit 2 = ungraded judge scorers (not a pass)
│   └── grade.sh                    records a verdict, bound to the rubric it judged
└── .harness/                       OPT-IN L3 — workflows, lifecycle, schemas, fixtures, validator
```

★ = the two files everything else derives from.

## Fill-in checklist

- [ ] `make harness-init`, then read `harness.config.yaml` by hand.
- [ ] **Verify every glob matches real files.** `project.src`, `project.tests`,
      each `surfaces[].paths`, each `design.forbid[].paths`. A glob that matches
      nothing is a gate that silently never runs — the most common way a harness
      looks installed and is not.
- [ ] Fill in `scripts/adapters/<adapter>.sh`. Run each verb individually before
      running `make check`. Leave a verb undefined rather than stubbing it green.
- [ ] Replace `<placeholders>` — `grep -rn '<[a-z-]*>' AGENTS.md .env.sample docs/`.
- [ ] Point `design.tokens_path` at your real token layer, or set
      `design.enabled: false` and delete `.agents/rules/design-tokens.md`.
- [ ] Set the toolchain step in your **adapter's `ci_setup()`**, then run
      `make ci-gen`. Do not edit `.github/workflows/gates.yml` directly — it is
      generated, and `make ci` fails on a hand-edit.
- [ ] `make install-hooks`, then confirm `git config core.hooksPath` = `.githooks`.
- [ ] Pick a starting tier: `make tier-build` (or `tier-explore` for a cautious start).
- [ ] Turn the two or three rules your team most cares about into `design.forbid`
      entries or new gate scripts.
- [ ] Delete what you do not have. An unused rule teaches agents that rules here
      are decorative.

## What you get at each rung

| Rung | Ships | Turn it on by |
|---|---|---|
| L1 | instruction graph, rules, skills, command surface, ADRs, specs, product register + decision ledger, design system + review | it is on |
| L2 | gates, hooks, tiers, CI, PR contract, sync drift check | it is on (**default**) |
| L3 | `docs/devlog/`, `docs/incidents/`, `.harness/` workflows, lifecycle SOP, evidence schemas with an explicit `trust` rung, producer-cannot-self-certify validator | `governance.enabled: true` + `level: L3` |
| L4 | `evals/` cases, deterministic + judge scorers, a verdict ledger bound to the rubric it judged | `evals.enabled: true` |

Three rules run underneath all four rungs, because each closes a way a green
result can be untrue:

- **A named input that is missing is not a clean run.** A gate either reports
  "clean" or reports "I did not look" — never the second as the first. Gates say
  which of their inputs are required (`req_input`) and which are optional
  (`opt_input`, whose absence is printed as a blind spot).
- **Permission is declared, not exported.** `./scripts/declare-intent.sh` records
  a scope, a branch and a sentence. It stops applying when you leave the branch,
  which the `HARNESS_ALLOW_SELF_EDIT` / `HARNESS_HUMAN_APPROVED` booleans it
  replaced never did.
- **A hook is a convenience, never the only enforcement.** Every hook declares
  the CI gate enforcing the same rule (`# ci-parity:`), checked by
  `scripts/gates/hook-parity.sh`. Local hooks warn; CI blocks.

## Deliberately not included

- A design-token *implementation* or component library — only the rules, the
  checklist, and the drift gate. Tokens are product-specific.
- Ticket-intake, componentize, and design-feedback skills. Add the ones your
  process actually repeats, following the same `SKILL.md` shape.
- A workflow runtime. `.harness/workflows/*.yaml` are written for one; without
  it, `.harness/lifecycle/feature.lifecycle.md` is the authoritative SOP.
- Real CI toolchain setup. That is one step in `gates.yml`, and it is yours.

## Adding a stack adapter

Copy `scripts/adapters/generic.sh`, implement the verbs, save as `<name>.sh`,
set `harness.adapter: <name>`. A green `make check` on a fresh clone is the
adapter's acceptance test. Nothing else in the harness changes — that is the
point of the adapter boundary.
