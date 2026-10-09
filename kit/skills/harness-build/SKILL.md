---
name: harness-build
description: Instantiate a harness from an architecture document that has ALREADY been agreed — copy the core template, fill the foundations, apply a pack, wire the gates, and run real work through it. NOT the entry point, and the test is a condition rather than a wording: if no agreed architecture document exists, this skill cannot run, whatever the request says — create, build, set up, copy the template, install it, instantiate it, or skip the interview all go to harness-scope first, which gathers the context, decides whether a harness is warranted, and produces that document. Only use this when the architecture document exists and someone has signed off on it.
license: MIT
metadata:
  harness.destructive: "true"
  harness.entry: "false"
allowed-tools: Read, Glob, Grep, Edit, Write, Bash
---

# harness-build

**Requires:** an agreed architecture document. **Owns:** the instance. **Never:** invents foundations, or touches work it was not asked to touch.

## Read first — not optional

**These paths are relative to the kit.** Find it in this order, and **look before you ask**: a
**connected folder** holding `ANATOMY.md`, `LADDER.md`, `core/` and `packs/` — this is how Claude
Desktop and Cowork carry the kit, and it needs no configuration; then **`$HARNESS_KIT`**, where a
shell exists to have exported it; then ask for the path.

**Do not treat an unset `$HARNESS_KIT` as "no kit".** Nothing can set an environment variable in
Claude Desktop, so a skill that only looks there designs a harness from general intuition while
reporting no problem — exactly the failure this table exists to prevent.

| Read | For |
|---|---|
| `ANATOMY.md` | The organs you are instantiating, and **why each exists**. Building a slot without knowing the failure it prevents produces a filled template rather than a harness |
| `LADDER.md` | Which rung each surface starts at, and the trigger that would promote it |
| `packs/<domain>/PACK.md` | The three things that vary: the verbs, the foundations, the starting rung. Only if one exists for this domain |
| `packs/_deriving.md` | **When it does not — the normal case.** The architecture document should already carry the three variables, derived during scope; this is how they were arrived at and what to check them against |
| `packs/_overlay.md` | **If this is overlay rather than greenfield.** Its rules differ enough that greenfield habits damage the client's work |
| `core/README.md` | The layout you are writing, and every config key's reader |

**The architecture document says *what* to build. These say *why each part is shaped the way it is*** — which is what you need the moment reality does not match the plan, and it will.

## Preconditions — check all four, stop if any fails

1. **The architecture document exists and is marked agreed.** If it does not — if you arrived here because someone said *"create a harness for X"* — **stop and run `harness-scope` instead.** That is not a formality: scope gathers the context, records whether a harness was recommended and what the person decided, and designs around the environment it found. Starting here skips all three. Without it you are guessing at scope, and the guess gets baked into every surface, rung and rule below.
2. **You can get back to the state before this run** — and how depends on the substrate ([`SUBSTRATES.md`](../../SUBSTRATES.md)). In a **repository**: `git status` is clean, and a recovery branch exists at the current commit. In a **workspace** — a folder or shared drive with no git — a dated copy of the target taken *before* this run, outside the folder being written to, and you have opened it to confirm it is readable. Neither is optional: `install.sh` refusing to overwrite is a floor, not a recovery plan, and everything after Phase 2 edits the client's real files.
3. You know the motion — greenfield or overlay. **If overlay, read `packs/_overlay.md` now**; its rules differ enough that greenfield habits will damage the client's work.
4. If a harness is already present, this is an upgrade: diff before writing.

## Phase 1 — Inventory (read only, write nothing)

Report before changing anything:

- Existing instruction files — `AGENTS.md`, `CLAUDE.md`, `.cursor/rules/`, `.github/copilot-instructions.md`, `.codex/`, and the rest. **These are the client's existing rules. They get merged, never silently overwritten.**
- Existing gates: CI, hooks, linters, checks.
- Which foundations already exist, and where.
- Residue from a different harness.
- **Whether a judged corpus exists**, and how large.

Present it. Get agreement before Phase 2.

## Phase 2 — Instantiate

**Two trees.** You read from the kit and write to the target; they are different directories and confusing them is the commonest way this goes wrong.

```bash
<kit>/install.sh /path/to/target-project
```

**Never `cp -R <kit>/core/. .`.** That was the documented install, and it silently overwrote `README.md`, `AGENTS.md`, `.gitignore` and `.claude/settings.json` in any project that already had them — four paragraphs after this skill says those files "get merged, never silently overwritten". On a git substrate that is recoverable; in a workspace it is not. `install.sh` never overwrites: it stages every colliding file beside its target for a human to merge and names it in the report. A merge you were told about is work; a merge you were not told about is data loss.

Read the collision list it prints before Phase 3. An install that reports collisions is not a failed install — it is the install telling you what it refused to decide for you.

Then fill `harness.yaml`, leaving `mode: template` until the end.

**Copy the agreed architecture document in**, as `decisions/0001-architecture.md`. It records the fitness assessment, the surfaces and their rungs, and the revisit triggers — and until it lives in the instance, the reasoning behind every decision here exists only in the kit directory, cited by nothing. Add its line to `decisions/log.md`.

**Backfill the decision log** from the context gathered in scoping: decisions the team has already taken, and ideas it already turned down, each with where it was found. Follow the inventory mode in `procedures/record-decision.md` — show the list, write only what the person confirms. A harness that starts without this re-proposes last year's rejected ideas in its first week.

Then **verify by hand** that every surface pattern in `config/surfaces.tsv` actually matches files. A pattern matching nothing is a gate that silently never runs — the commonest way a harness looks installed and is not. `doctor.sh` checks this; do not skip reading its output.

## Phase 3 — Foundations

The phase that carries the value, and the one most likely to be rushed.

Write what the AI must not invent. Where it exists already, **adopt it as canonical** — a pointer, not a copy. A copy is a second truth that will diverge with nothing to say which is stale.

Include the **derivation rationale**, not just the values. And name every supersession you know about: where two sources disagree, say which wins and why.

**Gate:** if a foundation the architecture document names does not exist and cannot be written from real material, stop and say so. Do not generate plausible content about a real organisation.

## Phase 4 — Constitution

Fill `AGENTS.md`. The **prime directive** first — what failure looks like when the output is technically fine.

Then merge the client's existing rules, routing each to its owner:

| The rule is… | Put it in |
|---|---|
| Always true, short, traceable to a failure | the constitution |
| True only on some surfaces | that surface's rules |
| A procedure someone repeats | `procedures/` |
| A decision with a rationale | a line in `decisions/log.md`; a full record in `decisions/` where one line is not enough |
| A fact about how the work goes, not a rule | `memory/`, dated and sourced |
| "Before doing X, read Y" | a row in `read-first.md` |
| Checkable by a script | `scripts/gates/` **and** cited in the rule |
| Background and rationale | docs |

Then supersede the originals in place with a pointer. **Two copies of one rule is worse than none** — they drift and the agent obeys whichever it read last.

**Gate:** `./scripts/check-budget.sh` passes.

## Phase 5 — Pack

**The packs are documents, not file sets.** There is nothing to copy. Applying a pack means reading it and making the decisions it names: which verbs `check` maps to here, which foundations this domain cannot invent, and what rung each surface starts at.

Set each rung from the architecture document, not from ambition. Say plainly which parts of the pack you applied and which you skipped — a pack read and half-applied is indistinguishable from one applied in full unless someone writes it down.

**If a surface's standard is a judgement and no corpus exists, it starts at L1 and no deterministic quality gate is written.** Building the check first encodes today's guesses as permanent rules. Say this out loud rather than letting it look like an omission.

## Phase 6 — Enforcement

Only the checks the rungs justify.

Every gate added gets a case in `scripts/gate-selftest.sh` **in the same change**: one input it must flag, one it must not. A gate with no self-test is a gate you have no evidence works.

**Wire the checkpoint for this home.** Every harness ships `scripts/checkpoint.sh`. In a repository, tell the owner how to turn on the commit checkpoint — never turn it on for them. In a workspace, confirm the finish-time hook is present and make sure every procedure ends with the checkpoint step. Record which checkpoints are actually active; see `platforms/README.md` §2.

**Connections.** If the harness reads anything outside its own folder, copy `platforms/templates/connections.md` to `config/connections.md` and fill it in. Copy `mcp.json.example` or `env.example` only where a connection needs it — and never an `.env` into a shared drive.

**Gate:** `bash scripts/gate-selftest.sh` and `bash scripts/doctor.sh` both pass. Set `mode: instance` and run doctor again — placeholders now fail.

## Phase 7 — Run real work through it

**Do not skip this, and do not report the harness as delivered without it.**

Take one real piece of work end to end. An installed harness that has never carried work is a rehearsal, not a result — and it is the single most common place this stalls.

File the first judged example in `learning/corpus/`, accepted or rejected, with its reason. The corpus starting at zero is normal; the corpus staying at zero is the failure.

Close that session with `procedures/session-wrapup.md`, so the loop has run once before handover: a journal entry exists, anything learned is routed, and `bash scripts/retro-evidence.sh` reports real numbers rather than zeros.

## Phase 8 — Install report

**Write it to `runs/install-report.public.md`** — committable by the `.gitignore` rule, unlike everything else under `runs/`. Printing it to the terminal means the engagement's record dies with the session.

Then print the summary:

- Motion, packs applied, surfaces and their rungs
- Rules migrated: old path → new owner, for each
- Gates enforcing, and **gates deliberately deferred with the reason**
- **Which checkpoints are active** — commit, finish-time hook, procedure step — and which were only recommended
- What ran through it, and what happened
- **The improvement loop:** who runs the retro, whether the session-start reminder will reach them (it needs a host that runs hooks — otherwise name a calendar reminder), and whether transcript mining is available here
- **What still needs a human, named explicitly**

## Failure handling

Stop and report. Never silently fall back, never disable a gate to finish, never leave the target half-migrated. If you must stop mid-phase, say exactly which phase and what state things are in.
