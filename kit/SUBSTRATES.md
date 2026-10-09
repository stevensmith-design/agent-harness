# Substrates — one layout, two runtimes

A harness is a set of files and the checks over them. **Where those files live is a separate decision from what they are**, and the kit is built so the same layout works either way.

This matters because the usual framing — "technical teams get git, business teams get a folder" — is wrong twice. A small business team's revenue harness can be exactly right in git, with hooks and gates, because several people maintain it and `git` is what makes a ratchet auditable. Meanwhile plenty of engineering teams keep a marketing lane that has no business in CI.

**Choose on maintenance, not on job title.**

---

## Repository — the default

Git, one command surface, hooks, CI where the checks are worth running.

**Choose it when** more than one person maintains the harness, or when you need to trace an output back to the state of the context that produced it. Versioning, diffing and review come free, and they are the preconditions for evidence, provenance and an auditable ratchet.

**What you get:** commit SHAs in run records · a real diff on every rule change · protected paths and declared-intent hooks · gates that run identically locally and in CI · history as the record of what actually changed.

**Cost:** everyone who maintains the harness must be willing to branch and open a PR. That is a real cost and it is the only one that should decide against it.

---

## Workspace — a folder, synced or local

A folder the AI can read, write and run scripts in: a shared Google Drive, OneDrive or SharePoint library, Dropbox, Box, or a folder on one computer. No git, no CI. **For many non-developer teams this is the right home, not a fallback** — a harness they will actually open beats a better one in a tool they won't.

Which service, what it can read, and how to connect the team's other tools: [`platforms/README.md`](platforms/README.md).

**Choose it when** the people who must maintain this will not use git, and you would rather have a real harness they update than a perfect one they abandon.

**What you keep:** the constitution, foundations, surfaces, procedures, contracts, the corpus, the approval log, the retro. **These are most of the anatomy**, and they are the organs that carry the value.

**What you lose, and must say out loud:**

| Lost | Consequence | Mitigation |
|---|---|---|
| Commit SHAs | Run provenance cannot cite repo state | Record a dated snapshot of the foundations consumed |
| Diffs on rule changes | The ratchet is not auditable | `learning/changelog.md` becomes mandatory, not optional |
| Pre-write hooks | No mechanical self-protection | Harness edits become a declared, logged step in the retro |
| The commit, as a checkpoint | Checks run when someone remembers — the failure a harness exists to prevent | `scripts/checkpoint.sh` takes its place: a finish-time hook where the AI tool runs hooks, and the last step of every procedure everywhere else, with each result recorded in `runs/.state/checkpoints` |
| CI | No second, independent run | Gates still run through the checkpoint, with the denominator reported |

**What a synced folder adds, and the kit handles:** scripts lose their executable setting in sync and downloads, so everything runs through `bash`; two people editing at once leave conflict copies, which `doctor` flags; and native Google or Office online files are links rather than text, which `doctor` flags when one sits where the AI is meant to read.

**The migration is a move, not a rewrite.** `git init`, commit, wire the scripts. This is why the layout is identical.

---

## What changes between them

| | Repository | Workspace |
|---|---|---|
| Constitution | `AGENTS.md`; a pack may generate tool-specific copies from it | `AGENTS.md`, read by the client |
| Config | `harness.yaml` | `harness.yaml` |
| Surfaces | `config/surfaces.tsv`, read by a script | `config/surfaces.tsv`, read by a procedure |
| Gates | `scripts/gates/*.sh`, in `check`, the commit checkpoint and CI | `scripts/gates/*.sh`, through `scripts/checkpoint.sh` at finish and before handover |
| Doctor | `scripts/doctor.sh` | `scripts/doctor.sh`, run by the AI or by hand |
| Evidence | `runs/<date>-<procedure>/` + SHA | `runs/<date>-<procedure>/` + foundation snapshot |
| Protection | Split gate + declared intent; a pre-write hook where the runtime has one | Declared step, logged in the retro |

Everything else is byte-identical.

---

## Hosts — one constitution, thin redirects

Substrate is where the files live. **Host** is which tool reads them, and it is a separate axis: the same repository is read by Claude Code, Codex, Cursor, Copilot and whatever ships next quarter.

**`AGENTS.md` is the single source of truth.** Claude Code, Codex CLI, Cursor CLI, Windsurf and GitHub Copilot all read it natively. Hosts that do not get a **thin redirect**, never a copy:

| Host | File | Content |
|---|---|---|
| Claude Code | `CLAUDE.md` | One line: `@AGENTS.md` |
| Cursor IDE | `.cursor/rules/AGENTS.mdc` | `alwaysApply: true`, globs `**/*`, body points at `AGENTS.md` |
| Windsurf | `.windsurf/rules/agent.md` | Points at `AGENTS.md` |
| Copilot | `.github/copilot-instructions.md` | Points at `AGENTS.md` |

**A redirect, not a copy.** A copy is a second rulebook that drifts, and nothing tells you which one the agent read. Each redirect should carry a comment saying why it exists, or the next person deletes it as duplication.

### Procedures are canonical; skills are generated pointers

The same rule one level down. A harness's procedures — the retro, first contact, whatever the domain adds — live in `procedures/` as host-agnostic markdown carrying harness metadata a skill file has no room for: which surface they belong to, who owns them, whether they are live.

**But in that form nothing can invoke them.** They are documents you have to know to open, which is how a ratchet quietly stops being run.

So `./scripts/sync-skills.sh` generates a thin `.claude/skills/<id>/SKILL.md` per procedure whose whole body points back at the procedure, and `scripts/gates/skills-sync.sh` fails on drift. **Generation without a drift check is copying with extra steps.**

Adding another host means another generator target, not another copy of the content.

### Say what degrades

Hosts differ in what they can run, and the honest move is a table rather than silence:

| Capability | Absent means |
|---|---|
| Session hooks | `scripts/hooks/session-start.sh` never fires. `scripts/gates/first-contact.sh` is the backstop, and holds everywhere |
| Sub-agent dispatch | Reviews run serially instead of in parallel. **Same output, more wall time** — as long as each lens's criteria live in a file the main loop can read, rather than inside an agent |
| Structured questions | Fall back to numbered lists |
| CI | Gates run when someone remembers. `local = CI` parity is unavailable, so L2 is not honestly reachable on that surface |

**The design rule underneath:** a sub-agent should be a context-isolation wrapper, not a capability. If a lens's criteria live in a file and the agent only reads that file and applies it, the whole thing degrades to a slower loop. If the capability lives *inside* the agent, its absence is a hole rather than a delay.

## The rule that survives both

**A gate still reports its denominator.** `✓ checked 14 slides` is auditable whether a script printed it or a person wrote it. `✓ checked` is not, in either substrate.
