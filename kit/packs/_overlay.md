# The overlay motion

**Greenfield:** the work is yours, and the harness grows with it.

**Overlay:** the work already exists, belongs to someone else, and you are putting a harness over it and handing it back. This is the harder motion and the commercially valuable one, and its rules are different enough that applying greenfield habits will damage a client's work.

---

## 1 · Fitness comes first — as advice to the client

Assess `../scope/interview.md` §0 before anything else. On client work the recommendation carries more weight than anywhere else, because the client pays for the harness and inherits it. If the work is not structurable, not continuing, not decidable, or not receivable, **say so and name what would help** — structuring, research, or teaching.

**The client decides.** If they proceed, every weak condition goes into the architecture document as a named risk with a revisit trigger, so the handover can show whether the concern held.

## 2 · Adopt, do not create

The default verdict on every organ is **adopt the client's existing artifact as canonical**, not write a new one. New creation should trend toward zero.

Four verdicts per organ:

| Verdict | Meaning | When |
|---|---|---|
| **Adopt** | An existing file becomes the canonical source for this organ. The original is not touched. | Something real exists |
| **Review** | Apply the standard to it and report what would improve | It exists and the quality is in question |
| **Create** | Write it from a template, minimally | Nothing exists and this organ is load-bearing |
| **Skip** | Do not build it — it already lives somewhere else | It exists outside this repository |

**"Skip" means "exists elsewhere". It never means "absent."** Getting this backwards is how you end up building something the client already has, in parallel, competing for authority.

## 3 · Never infer a skip

You usually cannot tell from the material you were given whether an organ lives somewhere else or genuinely does not exist.

**Ask.** "Is this run anywhere else today?"

- **Yes, and here is where** → skip, and record the location
- **No** → create, minimally
- **Don't know** → the verdict stays open. Mark it *unverified* and do not close it by inference.

An unverified verdict recorded as verified is worse than an open one, because nobody comes back to it.

## 4 · Additive only

**Never modify** the client's existing deliverables — the work product itself. Those are the thing you were hired to serve, not to edit.

**Another tool's harness** — `.claude/`, `.cursor/`, `.codex/`, `.agent/`, `.github/copilot-instructions.md` — is a narrower and more specific case, and the blanket prohibition is wrong: these are exactly the files whose *rules* must be consolidated, or you have created a second rulebook competing with the one already loading into their sessions. The rule is therefore:

- **Never modify them silently, and never as a side effect of another task.** They are named in the write preview (§5) like everything else, and they need their own line of consent.
- **Never delete them.** Supersede in place: the file stays, its rules move to the constitution, and what remains is a pointer saying where the rule now lives.
- **Never touch the tool's own configuration** — settings, permissions, hooks, MCP config. Only the rules content.
- If the client says a tool's rules file is live and owned by someone else, **leave it entirely** and accept two rulebooks as a documented risk in the handoff.

Where the harness needs to name an existing artifact, it holds a **pointer**, not a copy. A copy is a second truth, and the two will diverge with nothing to tell you which is stale.

Where the harness needs to name an existing *deliverable*, it holds a pointer, not a copy. A copy is a second truth, and the two will diverge with nothing to tell you which is stale.

## 5 · Preview before writing

Show the full list — organ → verdict → path — with a total count, and get explicit consent before writing anything.

Organs left open are not written. Record each one with its reason, so the next person knows it was a decision rather than an oversight.

## 6 · Foundation first, harness second, never simultaneously

If the base is thin, the first phase builds the base. Harnessing a shape that does not exist yet produces a structure with nothing in it.

Where the base is thin, work in a reduced mode: stand up **one or two core organs minimally**, and put the rest on a named list of future candidates. Do not try to fill every organ at once.

## 7 · The handover is the deliverable

The engagement succeeds if the team keeps the harness working after you leave. That means:

- Handover in a form **the team's agents can read** — Markdown, not PDF.
- The **fitness assessment**: what was recommended, what the client decided, and the risks they accepted.
- Every surface's rung **and the trigger that would promote it**, so improvement does not require you.
- **What is deliberately not built, and why** — otherwise the next person builds it speculatively.
- Who runs the retro, and when.

Use `../core/contracts/handoff.md`.

## 8 · Advisor, not installer

**Scan, ask, recommend, link to the official instructions. Never install packages, wire credentials, or modify external configuration on someone's behalf.**

Treat it as a hard architectural boundary enforced at every level, not a preference. It matters most in exactly the situation overlay puts you in: inside someone else's repository, with their toolchain, their credentials, and their operational constraints — none of which you can see.

The discipline it produces is the useful part. **Report what you deliberately did not do:**

> *Scanned but did not wire up: the CRM integration, the analytics export, the deploy pipeline. Each needs a credential or a decision that is yours.*

A list of deliberate inaction is a denominator for the work you skipped. Without it, "I set up the harness" and "I set up the parts that needed no permission" are indistinguishable to the person receiving it.

## 9 · Declare what other tools own

Other review and automation tools may run on the same repository. Name the paths that are theirs, and treat the declaration as binding in both directions:

- **Outward** — a manifest of paths this harness will never write, so another tool's outputs are safe from it.
- **Inward** — a finding that recommends deleting or ignoring a protected path is discarded at synthesis, not surfaced. Otherwise your review becomes the thing that breaks their tool.

Ceding a namespace unilaterally is cheap and prevents a class of collision that is expensive to diagnose later.

## 10 · Keep the machinery out of the client's copy

Internal tool names, process names, and local paths belong in the operating instructions the agent reads — **never in the artifacts the client reads.** A deliverable that names your tooling is a deliverable that stops making sense the moment your tooling changes.
