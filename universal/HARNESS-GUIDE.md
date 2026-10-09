# Harness Design Guide

*How to build an agent harness for a software project. What goes in, in what order, and how much ceremony each part has to earn. Grounded in current best practice for agent harnesses.*

Companion files: `HARNESS-MANIFEST.md` (what is in this scaffold and how to fill it in), `README.md` (the door).

---

## 1. What a harness is

A harness is **the structure around an agent that makes its behaviour repeatable** — on a fresh context, with a new operator, in an unfamiliar part of the code. The model supplies intelligence. The harness supplies everything the model cannot be trusted to reinvent every run: authority, sequence, boundaries, state, and proof.

> A harness is an **instruction graph** plus an **enforcement system** plus a **maintenance loop**.

Three obligations follow:

1. **Instruct** — say what is true here, and route to exactly one authoritative source per rule.
2. **Enforce** — make the rules that matter *checkable*: scripts, hooks, tests, schemas, CI gates, permission tiers, human approvals.
3. **Maintain** — turn repeated failures into durable artifacts in the layer that owns them, so the thing improves instead of drifting.

A prompt library does (1). A linter does part of (2). A harness does all three, wired together.

### What it is not

- **Not an instructions file.** `AGENTS.md` is a door. Entry files stay thin and push real content into owned, single-source documents.
- **Not the model.** The workflow — not the model — owns sequence, state, permissions, and completion. If "done" depends on the model's judgment about whether it is done, there is no gate.
- **Not a one-time scaffold.** Without a maintenance loop it decays. The decay is invisible until the day someone notices nobody has read `AGENTS.md` in four months.
- **Not an evaluation harness.** The word is overloaded. SWE-bench-style "harness" means a benchmark runner. Different thing; do not let the vocabulary confuse a conversation with a client.

---

## 2. Three species — know which one you are building

"Harness" names at least three different animals, and picking the wrong one wastes months.

| | **Project harness** | **Harness runtime** | **Governance harness** |
|---|---|---|---|
| What it is | Files inside the product repo that instrument it for agent work | An engine that runs your process as version-controlled workflows | A contract layer defining a governed lifecycle before any tool exists |
| Unit of reuse | A repo template + an install skill | A workflow DAG | A schema + a lifecycle + valid/invalid fixtures |
| Enforcement centre | Conventions, tokens, tests, CI, PR evidence | Node permissions, gates, isolation, structured outputs | Actor policy, guards, evidence contracts, anti-self-certification |
| Strength | Concrete, low ceremony, proven in a shipping product | Deterministic orchestration, parallel isolation | Rigorous, provable, tool-agnostic |
| Failure mode | Rules live in prose with nothing checking them | Ceremony exceeds the task | Spec out-runs anything that runs it |

They are not competitors — they are three altitudes of one stack: **contracts → runtime → project instance**. This scaffold is a *project harness* with an opt-in governance layer (`.harness/`) and workflow files that a runtime can execute if you have one.

**Start with the project harness.** It is the only one of the three that pays back in week one.

---

## 3. The anatomy — eleven organs

Strip away the language and the same organs appear in every good harness. This is the checklist of what to include.

### 3.1 Entry points that route, never restate

One rule, one owner file. Everything else cites it.

The 2026 convention has settled: **`AGENTS.md` is the canonical file** — a plain-markdown convention (no formal spec, no frontmatter, nearest-file-wins for nested packages) read natively by Codex, Cursor, Copilot, Amp, Cline, Roo, OpenHands, Windsurf and others. Claude Code reads `CLAUDE.md` instead, so the bridge is a `CLAUDE.md` that imports `@AGENTS.md` and adds only Claude-specific mechanics.

Practical consequence for this scaffold: `AGENTS.md` and `.agents/` are canonical; `CLAUDE.md`, `.cursor/rules/*.mdc`, and `.github/copilot-instructions.md` are **generated** by `make harness-sync`, and CI fails if any of them drifted. That is the only way to be multi-tool without maintaining N copies of the same rule.

**Budget it.** Practitioner consensus lands between 60 and 200 lines, and the reason is not aesthetics: an instruction file too long to hold in your head is one agents skim. `scripts/gates/instruction-budget.sh` enforces it, because a budget nobody checks is a preference.

**Every rule traces to a real failure or an external constraint.** If you cannot name the failure, it is not a rule yet — it is a preference, and it belongs in `docs/`.

### 3.2 A declared authority chain

When two rules conflict the agent must know which wins without asking. Write the precedence order down. An undeclared hierarchy is resolved by the model at random, differently each time.

The default in `AGENTS.md`: law/security/accessibility → company policy → product design and accepted ADRs → project decisions and the active spec → platform conventions → skill defaults.

### 3.3 Path-scoped rules

The second convergent pattern across every major tool: rules that load only when matching files are touched. The frontmatter key differs by tool (`paths:`, `globs:`, `applyTo:`, `trigger:`); the semantics do not. Author once in `.agents/rules/` with `paths:` and generate the rest.

This matters more than it sounds. A repo-wide instruction file competes for attention on *every* request. A path-scoped rule costs nothing until it is relevant — which means you can afford to be specific.

### 3.4 Task engines (skills) with explicit boundaries

Skills are focused, repeatable procedures. Use the portable [Agent Skills](https://agentskills.io/specification) format — `SKILL.md` with six standard frontmatter fields — so one tree serves Claude Code, Codex, Cursor, Gemini CLI and OpenHands. Tool-specific extras belong in an overlay, not in the portable file; non-Claude clients hard-error on unknown frontmatter keys.

Two disciplines make skills composable:

- **Separate provenance.** *Workflow* skills (your team's procedures, authored here) and *capability* skills (imported framework know-how, pinned by hash in a lockfile) have different lifecycles. Do not mix them in one folder.
- **Draw the fence first.** Every skill opens with a *when to use / when NOT to use* table. A skill with no stated non-goal expands until it collides with its neighbours. The `review` (comment-only, read tools only) vs a fix-it lane is the canonical split — the moment a reviewer can push a fix, it stops being an independent review.

`description` is the only part loaded before the skill fires. It is the trigger, not the summary. Write it as *what* and *when*.

### 3.5 A single command surface

Humans and agents drive the harness through one vocabulary, not a pile of remembered incantations. `make check`, not "run vitest with these flags and also prettier and also tsc".

This removes a whole class of "the agent ran it slightly wrong" failures and gives you one place to change how something runs. In this scaffold the Makefile speaks verbs and `scripts/adapters/<stack>.sh` is the **only** file where a real toolchain command appears — which is exactly what makes the same harness serve React, React Native and Flutter.

### 3.6 Gates ordered deterministic → probabilistic → human

Cheap objective checks first, judgment second, people last. Never spend a model call on something a script can decide; never spend a person on something a model can.

There is a second ordering, by *when* rather than by cost:

| Rung | Mechanism | Catches |
|---|---|---|
| Prevent | git hook, `PreToolUse` hook | before it exists |
| Detect | `make check`, CI | before it merges |
| Judge | review skill / review agent | what scripts cannot see |
| Approve | named human | what nobody should decide alone |

Each rung catches what the cheaper one missed. Prevention is worth disproportionate investment: a pre-commit format check costs one second and removes an entire category of review comments forever.

### 3.7 Hooks — the part most harnesses skip

Instructions are advisory. An agent under pressure to finish will rationalise its way past prose. Hooks are not advisory: they run every time, with no thinking required, and a blocking hook stops the tool call.

The four worth shipping by default:

1. **Post-edit** — format and typecheck the file that just changed. *Success is silent, failures are verbose.* A hook that chatters on every edit is disabled within a day.
2. **Protected-path** — deny writes to `AGENTS.md`, `.agents/**`, workflows, ADRs. The agent may not rewrite its own constraints mid-task. Almost nobody guards this, and it is the single most damaging failure mode there is: an agent that cannot pass a gate quietly relaxing the gate.
3. **Stop gate** — refuse to end a run that changed source but left no evidence.
4. **Session start** — inject branch, active spec, and permission tier, so the agent does not begin by guessing.

The decision rule: *if something must happen every time and requires no thinking, it is a hook, not a sentence in an instruction file.*

### 3.8 The producer cannot self-certify

The strongest single governance idea, and the one that survives contact with every stack.

The agent that built the work must not be the sole authority that declares it done. Concretely, every important exit needs at least one of: a validator exit code, a review by a **different actor in a fresh context**, an inspection of the rendered artifact, or a named human approval.

**How much is each of those worth?** That is a separate question from who they name, and running them together is how "an agent ran a script" quietly becomes "a human approved this". Records carry an explicit `trust` rung, weakest to strongest:

| rung | what it means | what can produce one here |
| --- | --- | --- |
| `self_reported` | whoever wrote the record asserted it; nothing checked | `scripts/declare-intent.sh`, and any `human:` actor id passed to `scripts/emit-evidence.sh` |
| `deterministic_runner` | a program with a fixed output produced it; the run repeats | a gate run by a `runner:` actor in CI |
| `independent_reviewer` | a different actor than the producer, clean context, read-only | an `EvidenceRecord(governed_review)` that passes the validator |
| `authenticated_human` | a channel that **issues identity** vouched for a person | **nothing in this harness today** |
| `external_policy` | an authority outside this repository | **nothing in this harness today** |

The last two rows are the honest part. `scripts/declare-intent.sh` proves a *declaration was made*, not that a human made it — any agent that can run repository scripts can author one, including the agent whose change it authorises. It is bound to a branch, it carries a reason, and it expires, all of which make it a good audit trail and a genuine improvement on the `HARNESS_HUMAN_APPROVED=1` boolean it replaced. It is not authentication, and nothing in the harness may describe it as such. The surface policy gate therefore requires an **approval declaration**, not a human approval.

To get an approval a person actually gave, route it through something that issues identity — a GitHub required review, or a protected deployment environment — and label *that* `authenticated_human`. Wiring one up is not done; it is a named gap, not an implied capability.

And be clear about the limit of the mechanism itself: these records are files, and a file is not authenticated by a field inside it. An actor that can write the record can write any `trust` value. What the vocabulary buys is that the harness stops *calling* a self-reported declaration a human approval. It makes the claim explicit and checkable for consistency; it does not verify it.

Fresh context is doing real work in that sentence. A reviewer that remembers writing the code will defend it. `.harness/` enforces the rule literally — actor identity separation checked by a validator, with schema-valid-but-semantically-invalid fixtures proving the check actually fires — but the lightweight version (a separate review lane with no write tools) captures most of the value for none of the ceremony.

### 3.9 State and evidence that outlive the conversation

A fresh agent must reconstruct "where are we" from files, not chat history. Plans, decisions, approvals, artifacts, open questions and validation results live in a system of record. **If the only record of a decision is in a chat window, it does not exist.**

Three pieces do most of this work:

- **ADRs** (`docs/decisions/`, MADR format) — why the agent may not "improve" this. The *Confirmation* section is the sleeper feature: it says how anyone can check the decision is still honoured, which is what turns a record into a gate.
- **Specs** (`specs/`) — what we are building now, with `[NEEDS CLARIFICATION: …]` markers and a gate that refuses to let implementation start while any remain. Cheapest anti-hallucination device available: it converts "the agent guessed" into "the agent asked".
- **Memory** (`.agents/memory/`) — an index plus topic files, budgeted, holding only what could not be re-derived from the repo.

Plus a run trail (`.agents/runs/*.jsonl`) whose field names echo the OpenTelemetry GenAI conventions, so wiring real tracing later is a mapping rather than a rewrite.

### 3.10 Permissions scoped by lane

Blast radius should match trust. Read by default; earn write.

Three named tiers — `explore` (read-only, planning), `build` (edits and local commands, the default), `release` (push and deploy, behind approval) — swappable as config fragments. Two things to know:

- **Deny beats allow, absolutely.** A broad allow cannot carry a deny exception. Write the deny and narrow the allow.
- **Permission rules govern the agent's tool calls, not the processes it starts.** A script the agent runs can open any file the OS permits. Where an OS-level sandbox is available, turn it on; filesystem and network allowlists are the real boundary.

The branching model belongs here too. An agent with no stated convention invents
a different one each session, and long-lived branches become unreviewable before
they land. Write it down (`.agents/rules/git-flow.md`), then make the mechanical
half checkable — branch name, commit shape, and branch size are all greppable,
and the permission tiers already deny force-push and direct-to-main.

And isolate risky or parallel work: one worktree (or container) per agent, on its own branch. Isolation is what makes fan-out safe, and fan-out is most of the speed.

### 3.11 A governed learning loop

Repeated failures become **candidates**, not instant global rules. Each candidate records its evidence, the layer that should own it, and how it will be checked. Deterministic candidates ship with a positive and a negative fixture before promotion.

The routing table is the whole skill:

| The failure is… | Owner |
|---|---|
| a convention got wrong everywhere | a line in `AGENTS.md` |
| a constraint on some paths | a path-scoped rule |
| a procedure done inconsistently | a skill |
| something that must **never** happen | a hook or a gate script |
| a decision being relitigated | an ADR |
| a fact the agent could not know | memory |
| a rule broken again after its lesson | one rung up: memory → rule → test → gate |

Two rules keep the loop healthy. **Two occurrences minimum** — one-off mistakes become rules that fire forever on a problem that happened once. And **anti-churn**: only write when a run was actually steered wrong. "No changes needed" is a common and correct outcome; a retro that produces a diff every time trains people to ignore the diffs.

Seven more keep it honest over months rather than weeks:

- **Evidence, counted.** `make retro-evidence` counts what happened since the last retro — devlog corrections and unverified paths, incidents, gate results, commits — and `scripts/mine-sessions.py` finds what the person typed when correcting the agent in saved sessions — or, with `--usage`, where the tokens went: per session, the share read from the prompt cache, the largest tool outputs, and the files read most. A retro run from memory reviews the last two days.
- **Due by evidence, not only by calendar.** A week with work in it, a month regardless, repeated corrections, or any incident. Session start passes the reminder on; it never blocks. Run the first retros by hand, then schedule them to open a draft PR — a scheduled retro never merges.
- **Memory is pruned.** Entries are dated, sourced and confirmed; an agent verifies one before acting on it; the retro deletes what stopped being true. Team lessons live in the repo, not in one person's AI tool memory.
- **Every defect leaves a lesson, and a recurrence is the finding.** A bug fix is not done until `docs/quality/defects.md` records which part of the loop let it through (`spec`, `test`, `render`, `judgement`), what a sweep across every sibling path found, and where the lesson now lives — a lesson that must match the gap, so a `test` gap is closed by a check, not a sentence. A rule broken again after its lesson was recorded makes a retro due on its own, and the fix climbs a rung: memory → rule → test → gate (`harness-defect`, `make check-learning`).
- **Questions close into rules.** "Is this intended?" from a tester is a spec gap found by a person. It is logged in `docs/product/questions.md` and closes only into a `DEC-`, `INV-` or `REQ-` — where the implementer and the agent read — so the next screen fails a test instead of raising it again.
- **Name what nothing checked.** A spec-driven loop verifies what is written; it does not find what is not, and it does not see a screen the way a person does. Every PR carries a **Not verified** section, started from the human lane in `docs/quality/README.md`, and `make render-audit` measures the part of "looks right" that is geometry, so the person's time goes on the part that is judgement. Keeping recurrence prevention and new discovery apart matters: more spec helps the first and does almost nothing for the second.
- **Net zero.** The always-loaded budget is a ceiling; the health measure is the trend. `docs/retros.md` records the size at every retro, including the ones that changed nothing, so slow growth is visible before it reaches the ceiling.

---

## 4. The maturity ladder — do not over-build

The most common failure is applying product-CI ceremony to a one-page memo. Match enforcement to the cost of the failure it prevents.

| Rung | What exists | Add it when |
|---|---|---|
| **L0 Guidance** | reference examples, a checklist | always — it is free |
| **L1 Standardised** | canonical templates, tokens, output contracts, a command surface | more than one person or agent touches the code |
| **L2 Guarded** | validators, scanners, hooks, permission tiers, CI gates | a mistake would reach a user or another team |
| **L3 Orchestrated** | stateful workflows, approvals, isolation, evidence records | wrong order or self-certification would genuinely hurt — auth, payments, deletion, release, regulated work |
| **L4 Learning** | run telemetry, an eval set, write-back | you are running enough agent work that trends matter more than incidents |

**Choose the rung per surface, not per repo.** L3 for the payments flow and L0 for the marketing copy is not inconsistency — it is the design act. `harness.config.yaml` models this directly: each entry in `surfaces[]` carries its own `risk` and `level`.

This scaffold ships **L2 by default**, with L3 (`.harness/`) and L4 (`evals/`) present but switched off. That is deliberate. Ceremony you did not need is the fastest way to get a harness abandoned.

---

## 5. Build order for a new harness

1. **Name the species and the target rung per surface.** This decides everything downstream. Ten minutes here saves a month.
2. **Write the authority chain and the entry routers.** One owner file per rule; thin doors that cite it. Generate the tool variants; never hand-maintain two copies.
3. **Establish the concrete layer.** Tokens, component tiers, the command surface, and — if a backend is being built in parallel — a **stub mode**, so product work is never blocked on API readiness. One flag, one swap point, phased out by removing the flag from the pipeline rather than deleting the stubs.
4. **Make the top three or four rules checkable.** Not all of them. The ones you most care about. A grep beats a sentence; a hook beats a grep.
5. **Add workflow and state only where sequence has teeth.** Borrow the `intake → produce → validate → review → approve → close` spine, and only for the surfaces that warrant it.
6. **Instrument and evaluate.** A trace per run and five to ten baseline tasks. Report pass rate *with* cost and steps — a change that lifts pass rate while doubling spend is usually a bad trade, and the rate alone hides it.
7. **Make installation a skill.** Inventory before writing, phase-gated, safe to re-run, stops on failure, and emits an install report. That is what makes the harness transplantable instead of admired.

The through-line: **start concrete and cheap, make the few rules that matter enforceable, add orchestration only where sequence has teeth, and close the loop so it improves.** Every layer of ceremony earns its place by the cost of the failure it prevents.

---

## 6. Patterns to reuse, and patterns to avoid

**Reuse**

- Thin routers over one canonical rulebook, with generated tool views and a drift check.
- Workflow owns state, not the model.
- Fresh-context reviewers exchanging explicit artifacts instead of relying on conversation memory.
- Worktree or container isolation for concurrent and risky mutation.
- Deterministic-first gates and grep-able rule violations.
- Producer ≠ certifier, proved by fixtures that must be rejected.
- Stub-first development with a pipeline-level phase-out.
- A retrospective loop that routes each fix to the layer that owns it.
- Installation as a validated, re-runnable, phase-gated process.
- Budgets on instruction files, enforced.
- A gate that names its inputs, so a missing one aborts rather than dropping out of the output. "Nothing to report" and "I could not look" must not print the same.
- Permission declared with a scope, a branch and a reason, rather than exported as a boolean. A boolean has no expiry, so it authorises every change after the one it was set for.
- Hooks paired with a CI gate enforcing the same rule — local warns, CI blocks. A hook is one machine and one tool; it is the easiest enforcement in the harness to switch off, and nothing reports that it has been.
- A verdict bound to what it judged. A human grade on an eval rubric, or a review finding on a file, carries a digest of the bytes it saw, so rewording the rubric or changing the file marks it stale instead of leaving it silently applying to something else.
- Findings written in one fixed identity line (`[severity] category · path · claim`), so the same defect raised twice reads as one finding. Adopt the schema before there is history to structure; the history only accumulates if it was written that way.

**Avoid**

- Rules living only in prose with nothing checking them. This is the single most common residue in real harnesses, and it rots silently.
- Ceremony exceeding the task. Approval gates on typo fixes train people to approve without reading — worse than no approval.
- Spec out-running anything that runs it. Beautiful contracts with no runtime and no pilot project.
- Duplicated rules across entry files. They drift, and the agent obeys whichever it read last.
- Silent fallback on gate failure. Stop and report; never paper over.
- The agent editing its own constraints. Guard it mechanically, not by asking nicely.
- Gates that fire on correct work. False positives are how gates get disabled, and a disabled gate is worse than none because everyone still believes it is running.
- Counting an unjudged criterion as passed. Any suite with a human or model judge needs a third outcome — *ungraded* — distinct from pass and fail. The criterion that most needed judgement is exactly the one a two-state runner waves through.

---

## 7. One paragraph

A harness is an instruction graph plus an enforcement system plus a maintenance loop. It exists so that a fresh, unfamiliar agent behaves the way your best engineer would. The same organs recur across every good one: thin routing entry points over a single owned rulebook, generated per tool; a declared authority chain; path-scoped rules; bounded skills in a portable format; one command surface with the stack hidden behind an adapter; gates ordered deterministic → probabilistic → human, and prevent → detect → judge → approve; hooks for the things that must happen every time; a rule that the producer cannot certify its own work; durable state, specs, ADRs and evidence that outlive the conversation; permissions and isolation scoped by lane; and a governed learning loop that routes each repeated failure to the layer that owns it. The art is not adding all of them at once — it is matching the rung to the risk *per surface*, starting concrete, and making the few rules that truly matter checkable rather than merely written.
