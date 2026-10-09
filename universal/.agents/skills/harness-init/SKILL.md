---
name: harness-init
description: Install or adapt this harness into a repository — inventory what exists, fill in harness.config.yaml, wire the adapter, generate tool files, and report what still needs a human. Use when setting up the harness in a new or existing project, or re-running it after the stack changed.
license: MIT
metadata:
  harness.tier: install
  harness.destructive: "true"
allowed-tools: Read Glob Grep Edit Write Bash(make:*) Bash(./scripts/:*) Bash(git:*)
---

# harness-init

Installation is a validated process, not a copy-paste. This skill inventories
the target, applies the harness in phases, and **stops on the first failed gate**
rather than papering over it.

| Use it when | Do not use it when |
|---|---|
| Standing the harness up in a new repo | You only want to change one rule — edit `.agents/rules/` |
| Adopting it into an existing codebase | The harness is already installed and green — use `/harness-retro` |
| The stack changed and the adapter no longer matches | You want a new skill — write it in `.agents/skills/` |

**Owns:** `harness.config.yaml`, the adapter selection, generated tool files.
**Produces:** a filled config, a working `make check`, an install report.
**Never:** touches product source, invents project requirements, or deletes work.

## Preconditions — check all four, stop if any fails

1. `git status` is clean. Uncommitted work plus a scaffold is unrecoverable.
2. A backup branch exists: `git checkout -b pre-harness-backup && git checkout -`.
3. You know the stack. If not, ask — do not guess an adapter.
4. If a harness is already present, this is an *upgrade*: diff before writing.

## Phase 1 — Inventory (read only, write nothing)

Report what you find before changing anything:

- Language, framework, package manager, lockfile.
- Existing instruction files: `AGENTS.md`, `CLAUDE.md`, `.cursorrules`,
  `.cursor/rules/`, `.github/copilot-instructions.md`, `.clinerules`,
  `.windsurf/rules/`, `.devin/rules/`. **These are the client's existing rules —
  they get merged into `AGENTS.md`, never silently overwritten.**
- Existing gates: CI workflows, git hooks, lint/format config, test setup.
- Whether there is a UI layer and whether design tokens already exist.
- Residue from a different harness (stale `.harness/`, orphaned skills).

Present the inventory and the proposed adapter. Get agreement before Phase 2.

## Phase 2 — Config

Run `./scripts/harness-init.sh` (or `--yes` for non-interactive). Then verify by
hand: `project.src`, `project.tests`, and every `surfaces[].paths` glob must
actually match files in this repo. A glob that matches nothing is a gate that
silently never runs — the most common way a harness looks installed and isn't.

## Phase 3 — Adapter

Fill in `scripts/adapters/<adapter>.sh` so every verb maps to a real command.
Run each verb individually before running `make check`. A verb you genuinely do
not have (no typecheck in a JS repo without TS) stays undefined — it is skipped
with a warning, which is honest. A verb you *stub out to pass* is a lie the
harness will repeat for a year.

**Gate:** `make check` must pass, or exit and report. Do not continue.

## Phase 4 — Merge the client's existing rules

For each rule found in Phase 1, decide its owner and move it there:

| The rule is… | Put it in |
|---|---|
| always true, short, and traceable to a failure | `AGENTS.md` |
| true only for some paths | a new file in `.agents/rules/` with `paths:` |
| a procedure someone repeats | a skill in `.agents/skills/` |
| a decision with a rationale | an ADR in `docs/decisions/` |
| checkable by a script | a gate in `scripts/gates/` **and** cited in the rule |
| background, rationale, long-form | `docs/` |

Then delete the originals and run `make harness-sync`. Two copies of one rule is
worse than none — they drift, and the agent picks whichever it read last.

## Phase 5 — Enforcement

- `make install-hooks`, then confirm `git config core.hooksPath` says `.githooks`.
- Add the PR template and the `gates` workflow. Set the toolchain step in
  `.github/workflows/gates.yml` to your stack's real setup action.
- Pick the starting tier — `make tier-build` unless the team wants read-only first.
- Turn the two or three rules the team most cares about into `design.forbid`
  entries or new gate scripts. Prose nobody checks is the thing that rots.

**Gate:** `make harness-verify LEVEL=2` must pass.

## Phase 6 — Install report

Write it to `docs/harness-install-report.md` and print the summary:

- Adapter chosen, and which verbs are implemented vs skipped.
- Rules migrated, with old path → new owner for each.
- Gates now enforcing, and gates deliberately deferred with the reason.
- Maturity rung reached, and the single next thing that would raise it.
- **Anything that still needs a human**, named explicitly.

## Failure handling

Stop and report. Never silently fall back, never disable a gate to finish,
never leave the repo half-migrated — if you must stop mid-phase, say exactly
which phase and what state the repo is in.
