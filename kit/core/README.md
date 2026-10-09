# Core template

The domain-empty harness: every organ in `../ANATOMY.md`, with nothing domain-specific in it. Copy this, fill it, then apply a pack from `../packs/`.

## Layout

```
AGENTS.md            the constitution — routes, does not contain
read-first.md        what to read before each kind of task — on demand, grows with the work
harness.yaml         the single adaptation point
GOVERNANCE.md        owners, what needs approval, exceptions, cadence
config/surfaces.tsv  where work lands, blast radius, approval tier
contracts/           the required shape of brief · review · approval · handoff
procedures/          repeatable work — _TEMPLATE.md is the required shape
capabilities/         reviewed external skills only; quarantined until intake passes
capabilities-lock.json  source, licence, reviewer and content pin for each capability
decisions/log.md     one line per decision, and the ideas not to propose again
decisions/           full records where a line is not enough; 0000-template.md includes the revisit trigger
evidence/approvals.md   the approval log — the gate artifact
learning/candidates.md  staged rules, not yet in force
learning/changelog.md   what was promoted, and the check that enforces it
learning/journal/       session notes: what went well, what was corrected, what caused friction
learning/retros.md      one row per retro, with the always-loaded size at the time
learning/corpus/        judged examples, with reasons
rubrics/                the articulated standard — method, template, three exemplars
learning/reviews/       dated reviews, with machine-comparable finding lines
loading-order.md        what loads on every session, and the budget for the set
memory/                 what we would otherwise re-learn
foundations/            what the AI must not invent
runs/                run records: procedure + foundations + SHA
scripts/             the command surface
```

`procedures/upstream-feedback.md` is the optional write-back path for a lesson
that a local retro proves belongs in the source kit, pack, or template. It
creates a sanitized local proposal only. A person must separately approve its
disclosure and destination before anything is sent.

## Configuration keys

Every key in `harness.yaml` is read by something, and `scripts/gates/dead-config.sh` fails if one is not.

| Key | Read by | Meaning |
|---|---|---|
| `name` | this README, the build skill | What this harness is called |
| `kit_version` | the build skill | Which kit version produced it |
| `mode` | `scripts/doctor.sh` | `template` tolerates placeholders; `instance` fails on them |
| `owner` / `approver` | `GOVERNANCE.md` | Named humans. An agent may never infer approval |
| `motion` | `../packs/_overlay.md`, the build skill | `greenfield` or `overlay` |
| `substrate` | `../SUBSTRATES.md`, the build skill | `repository` or `workspace` |
| `constitution` | `scripts/doctor.sh` | The file that loads every session. Its budget lives in `loading-order.md`, not here |
| `surfaces_file` | `scripts/resolve-surface.sh` | Where surfaces are declared. Patterns must be disjoint; `*` crosses `/` |
| `main_branch` | `scripts/gates/harness-content-split.sh` | The integration branch the split gate diffs against |
| `packs` | the build skill | Which domain packs are applied |
| `runtimes` | the build skill | What gets generated |

## Citing the kit from inside an instance

An instance is a **separate tree** from the kit that built it. A file here that
writes a kit-relative path in backticks — the scoping interview, say — creates a
reference that resolves in the kit and dangles in every instance, and
`dead-config.sh` will fail on it, correctly.

The same applies to a path in **another repository** — a citation to someone else's file dangles everywhere, including in the kit.

**Convention: instance files name kit documents and external documents in prose, never by path.** "The
kit's scoping interview" resolves for a reader and dangles for nobody. Paths are
for files that live in this tree.

This bit three times while the kit was being written, each time caught by the
gate rather than by review — which is the argument for the gate.

## Commands

| Command | Asks |
|---|---|
| `./scripts/doctor.sh` | Is the **harness** healthy? Organs present, references resolve, no unfilled placeholders, and surfaces resolve **both ways** — every pattern matches a file, and every file matches at most one pattern. The health floor — necessary, never sufficient. |
| `./scripts/check.sh` | Does this **work** comply? Runs every gate as a direct child and reads its own exit status. |
| `./scripts/gate-selftest.sh` | Can every gate still **fail**? Rigs each violation and asserts rejection, plus a clean-tree pass. |
| `./scripts/check-budget.sh` | Is the **always-loaded set** still short enough to be read? The set is declared in `loading-order.md`, and so is the number — a budget on one file is gameable by moving content into a second file that also loads every time. |
| `./scripts/check.sh` gate: data-boundary | What may never be committed: personal and private paths, secret material, structured personal data. **A green scan is not evidence a file is clean** — it says so itself. |
| `./scripts/check.sh` gate: capability-safety | External skills are portable, instruction-scanned, licensed, provenance-recorded, human-reviewed and pinned to exact content. Empty by default. |
| `./scripts/sync-skills.sh` | Regenerates a thin invokable skill per procedure. Procedures stay canonical and host-agnostic; the skills are pointers, never copies. Run after adding or renaming a procedure. |
| `./scripts/resolve-surface.sh --all\|--changed\|FILE...` | Which lane is this file in? The single reader of `config/surfaces.tsv`. One match → that surface's risk and approval; none → high/owner; **two → fails as ambiguous**, because approval tiers have no maximum to take. Reports its denominator even when the set is empty. |
| `bash scripts/retro-evidence.sh` | **What has happened since the last retro?** Counts runs, rejections, failed checkpoints, journal corrections and unconfirmed memory, shows what every session pays in always-loaded context and the largest on-demand files, and says whether a retro is due. `--due` prints one line only when it is — the session-start hook passes that on. Writes nothing. |
| `python3 scripts/mine-sessions.py [--usage]` | Optional. The person's own corrections in saved agent sessions since the last retro, matched against `config/correction-signals.txt` — only what the person typed, never tool output. With `--usage`: tokens per session, the share read from the prompt cache, the largest tool outputs, and the files read most. Writes nothing. |
| `./scripts/review-staleness.sh` | Is this review repeating the last one? Above the threshold the instruction is not "fix faster" — it is "write down why these keep surviving". |
| `./scripts/declare-harness-change.sh "<why>"` | Declares intent before editing the harness. |
| `bash scripts/checkpoint.sh` | **The point work has to pass before it counts as done.** Runs the full check once the harness is configured, or the data-boundary guardrail before that, and records the result in the checkpoint log (runs/.state/checkpoints). Wired as a finish-time hook in `.claude/settings.json` — it keeps the agent working while a check fails, and lets go after three attempts — and it is the last step of every procedure, which is the only checkpoint a shared folder has where the AI tool runs no hooks. |
| `scripts/hooks/pre-commit` | The same checkpoint at the commit, in a repository. Off until the owner runs `git config core.hooksPath scripts/hooks` and `chmod +x scripts/hooks/pre-commit`. |
| `./scripts/hooks/session-start.sh` | Runs automatically at session start (wired in `.claude/settings.json`). Reports whether this harness has ever been configured, whether it has ever carried work, whether a retro is due, and whether this is your first session in this working copy. Never blocks. |

## First steps

1. Fill `harness.yaml`, leaving `mode: template` until the end.
2. Write the foundations — what the AI must not invent. Everything else depends on this.
3. Fill `AGENTS.md`, especially the **prime directive**: what failure looks like when the output is technically fine.
4. Classify surfaces in `config/surfaces.tsv`. Every one gets a blast radius *and* an approval tier — they are different axes. **The four shipped rows classify the harness's own files** — they are the floor, not the job.
5. Apply a pack from `../packs/`.
6. Set `mode: instance` and run `./scripts/doctor.sh` until green.
7. **Run one real piece of work through it.** An installed harness that has never carried work is a rehearsal, not a result.
