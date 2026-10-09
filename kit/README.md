# Harness Starter Kit

**v0.14.0** — **Harnessify anything.**

Tell it about your work, or point it at where your work already lives — a folder, a repository, your Slack or Notion — and it builds a harness around how your team actually works.

A harness is everything around the AI model: the context, rules, workflows, reviews and feedback loops that make AI output right for *your* work, not just fluent. Models are becoming a commodity. The harness is the part that is yours.

---

## How it works

1. **Tell it about your work, or show it where the work lives.** A conversation, a few folders, a repo, a Slack workspace, a Notion space — any mix. It reads what it is given and asks only for what it cannot find.
2. **It tells you whether a harness is worth it.** An honest recommendation with the reason. You decide.
3. **It shows you what it found and a design.** What already exists, what is missing, and where your own material disagrees with itself.
4. **You agree, and it gets built.** Around your types of work, your standards and your people — nothing invented to fill a gap.

Start by saying **"help me create a harness for …"** or **"turn this into a harness"**. That is the whole interface.

## Two ways in

| You have… | You get |
|---|---|
| **An idea of the work, and nothing set up** | A harness designed from the conversation, around that specific use case |
| **A workspace, repo or tools full of material** — prompts, guidelines, templates, a `CLAUDE.md`, pinned Slack messages, Notion pages | That material organised into a working harness, with its contradictions surfaced and your existing work adopted rather than rewritten |
| **A harness already** — built with the kit or not | An independent audit of what it enforces, what it only claims to, and what to improve |

Building software and want a harness today? The **universal harness** (`universal/` alongside this kit) is a ready-made development harness. Install it directly — the kit's dev pack uses it as its reference.

---

## What you get

**Consistent quality without the expert in the room.** The harness carries the rules, the facts AI must not make up, and what a polished-but-wrong result looks like — so the output holds up when the person who knows best is not watching.

**Your rules, found and reconciled.** Most teams already have their rules — scattered across instruction files, docs and chat threads that have never been read side by side. They usually disagree, and nobody knows. The kit finds those conflicts and turns each one into a decision someone makes, instead of an agent picking whichever file it loaded.

**The right amount of checking, not bureaucracy.** Each type of work gets the checking it has earned. Things a script can verify are checked automatically. Things only judgement can assess get a person, and a growing set of examples of good and rejected work — until there are enough to automate. A marketing lane and a codebase can live in one harness at different levels, on purpose.

**It gets better with use, and stays lean.** Each session ends with a short note of what worked and what was corrected. When enough has happened, a retro counts the evidence, turns every correction made twice into a rule with a check behind it, prunes memory that stopped being true, and holds the context loaded into every session flat. It proposes; a person approves. Improvement happens by mechanism, not by someone remembering.

**Reusable lessons can travel without the project travelling with them.** An
optional upstream-feedback procedure turns a retro-confirmed harness lesson
into a synthetic, disclosure-reviewed local proposal for the source kit, pack,
or template. It never sends or posts anything automatically.

**Checks that actually check.** A harness full of green ticks that verify nothing is worse than no harness. Every gate in the kit ships with a test that proves it can fail, and a check that finds configuration nothing reads.

**External capabilities enter through quarantine.** Skills, plugins, packages
and templates are treated as instructions or executable code, not as harmless
attachments. The generated harness includes a capability-intake procedure,
portable metadata and instruction-trust scans, provenance and content pins,
sensitive-read blocking, and a rule that an authorised human—not an agent—runs
the approved install.

**Any kind of work.** Software, design, business development, marketing, client delivery — and every domain nobody has catalogued yet. Where a ready-made pack exists it is a shortcut; where none does, the kit derives what it needs from your context. Your domain is never "not supported".

**Fits where your team already works.** A git repository, a shared Google Drive or SharePoint folder, or a folder on one computer — the same layout either way, with a checkpoint that stands in for the commit where there isn't one. Your knowledge can stay in Notion, Confluence or Slack; the kit guides the connections. One instruction source read by Claude Code, Codex, Cursor, Windsurf and Copilot.

**Honest about whether you need it.** The kit will tell you when a harness looks like more than your work needs. It will still build one if you want it — and record the concern so the harness can prove it wrong.

---

## Why it works

**One anatomy for any kind of work.** Software, design, business development, client delivery — with code or without it — a harness needs the same parts. Only three things vary:

1. **What "check" means** for this work
2. **What the AI must not invent** — thin in code, thick in business
3. **Whether the quality standard can be scored yet**

The kit asks exactly those three things, so it works for domains it has never seen.

**Examples before automation.** You cannot write a reliable check for a standard nobody has defined, and you cannot define a judgement-based standard without examples of work that was accepted and rejected. So the kit starts judgement-heavy work with a person deciding and a collection of examples, and automates only when the examples show what the rule actually is. It never hard-codes today's guesses as permanent rules. [`LADDER.md`](LADDER.md) has the full argument.

**Adopt before creating.** A rule someone wrote after a real failure is worth more than anything written from first principles. The kit keeps what you have and builds around it.

---

## Quick start

**In Claude Desktop, Cowork or Claude Code:** connect this kit folder alongside your work and say *"help me create a harness for …"*. The `harness-scope` skill takes it from there — see [`INSTALL.md`](INSTALL.md) for where the skills go.

**From a terminal:**

```bash
./detect.sh <folder-or-repo> [<another> …]   # read-only: what's already there?
./install.sh <target>                        # copies the template; never overwrites
```

## What's inside

```
skills/         harness-scope · harness-build · harness-audit
scope/          context gathering, the scoping interview, the architecture document
core/           the domain-empty template: every part a harness needs
packs/          domain shortcuts — dev · design · business-development · marketing · project
                plus how to handle existing material, someone else's work, and new domains
ANATOMY.md      the eighteen parts every harness has
LADDER.md       how much checking each type of work has earned
PRINCIPLES.md   the review rubric
SUBSTRATES.md   repository or shared folder
```

## Go deeper

| To… | Read |
|---|---|
| Understand what a harness is made of | [`ANATOMY.md`](ANATOMY.md) |
| See how context is gathered from folders, repos and tools | [`scope/context.md`](scope/context.md) |
| Decide how much enforcement each type of work needs | [`LADDER.md`](LADDER.md) |
| Choose between a repository and a shared folder | [`SUBSTRATES.md`](SUBSTRATES.md) |
| Set up in Google Drive, Microsoft 365, Notion, Confluence or Slack | [`platforms/README.md`](platforms/README.md) |
| Turn an existing workspace into a harness | [`packs/_scattered.md`](packs/_scattered.md) |
| Put a harness over someone else's work | [`packs/_overlay.md`](packs/_overlay.md) |
| Install and run it | [`INSTALL.md`](INSTALL.md) |
| Try it and record what happened | [`TRIAL.md`](TRIAL.md) |
| Change the kit itself | [`CONTRIBUTING.md`](CONTRIBUTING.md) |
