---
name: harness-scope
description: The entry point for making a harness. Use whenever someone says "help me create a harness for X", "build me a harness", "set up a harness for our team", "turn this repo / workspace / folder into a harness", "I want a harness for marketing / product / biz dev / this codebase", or asks how to start one. Gathers context from whatever it is given (a description, folders, files, repositories, Slack, Notion or other tools), recommends whether a harness is required, then designs one around that environment and produces the architecture document. Always run this before harness-build, including when the request sounds like it is asking to build.
license: MIT
allowed-tools: Read, Glob, Grep, Write, Bash(./detect.sh:*), Bash(./scripts/doctor.sh:*), Bash(ls:*), Bash(find:*)
metadata:
  harness.entry: "true"
---

# harness-scope

**Produces:** a filled architecture document. **Never:** builds anything.

## Read first — not optional

**These paths are relative to the kit.** Find it in this order, and **look before you ask**: a
**connected folder** holding `ANATOMY.md`, `LADDER.md`, `core/` and `packs/` — this is how Claude
Desktop and Cowork carry the kit, and it needs no configuration; then **`$HARNESS_KIT`**, where a
shell exists to have exported it; then ask for the path.

**Do not treat an unset `$HARNESS_KIT` as "no kit".** Nothing can set an environment variable in
Claude Desktop, so a skill that only looks there designs a harness from general intuition while
reporting no problem — exactly the failure this table exists to prevent.

This skill is a procedure. **The knowledge it operates on lives in the kit's theory files, and without them you are designing a harness from general intuition** — which is exactly the re-explaining this kit exists to remove.

| Read | For |
|---|---|
| `ANATOMY.md` | What a harness is made of. The eighteen organs, and the boundary test for each. **A harness missing one is not lighter — it has a hole where a failure gets through**, so the interview exists to find out which organs this work needs and in what form |
| `LADDER.md` | How much enforcement is justified, and the **corpus gate** — you cannot check a standard nobody has written down, so the starting rung follows from whether the standard is scorable, never from how technical the team is |
| `SUBSTRATES.md` | Repository or workspace, and which hosts must read it |
| `scope/context.md` | **How to gather context from wherever it lives** — folders, files, repositories, collaboration tools, conversation |
| `platforms/README.md` | **When the harness will not live in a repository**, or the team's knowledge sits in Google Drive, Microsoft 365, Notion, Confluence or Slack — where the files go, the checkpoint, and guided connector setup |
| `packs/<domain>/PACK.md` | What varies in this domain — the verbs, the foundations, the starting rung. **Only if a pack exists for it.** Five do; there are not five domains |
| `packs/_deriving.md` | **When no pack exists for the domain they named — the normal case.** Derives the same three variables from their context. Nothing downstream can tell the difference, because `harness-build` consumes the variables, not the file |
| `packs/_scattered.md` | **If they brought material that is theirs** and nothing organises it |
| `packs/_overlay.md` | **If the work already exists and belongs to someone else.** Read before anything else in that case |

Read the first four every time. They are short, and they are the difference between designing a harness and describing one.

| Use it when | Do not use it when |
|---|---|
| Someone asks for a harness, in any wording — including "build me one" | The architecture document is already agreed — use `harness-build` |
| Someone wants an existing repo, folder or workspace turned into a harness | You are adding one rule to a harness that exists |
| A harness exists but nobody agreed what it was for | Mid-engagement. Finish, then re-scope |

## Speak plainly

The kit's vocabulary is for the kit. **The person hears plain words** unless they ask for the machinery.

| Inside the kit | To the person |
|---|---|
| motion (greenfield · scattered · overlay) | "you're starting fresh" · "you've already got material" · "this belongs to someone else" |
| organs · anatomy | "the parts a harness needs" |
| surface | "a type of work" |
| foundations | "the facts AI must not make up" |
| prime directive | "what a polished-but-wrong result looks like" |
| rung L1 · L2 | "a person checks it" · "it's checked automatically" |
| corpus · corpus gate | "examples of good and rejected work" · "we need examples before we can automate the check" |

The flow, in the words to use: **tell me about your work or show me where it lives → I'll look at what's there and tell you whether a harness is worth it → I'll show you what I found and a design → you agree, and it gets built.**

## 0 · Gather context — before designing anything

You cannot design a harness for an environment you have not seen. **Where the context lives is not known in advance**, so find out what you have been given before asking for anything. Follow `scope/context.md`.

1. **Inventory what you can reach.** Connected folders, attached files, repositories, and any collaboration tools the host has connected — Slack, Notion, Google Drive, Confluence, Figma, Linear, whatever is there. List it back in a sentence.
2. **Run `./detect.sh` over every folder or repository** — one call can take several targets. It is read-only and decides how to treat each one:

| It reports | In plain words | Read |
|---|---|---|
| `greenfield` | Nothing here yet. Design from the conversation and the other sources | this skill, then the domain pack **or** `packs/_deriving.md` |
| `scattered` | Their material exists and nothing organises it. **The commonest real state** | `packs/_scattered.md` |
| `overlay` | Another tool's harness is present. It is not yours to restructure | `packs/_overlay.md` |
| `harness` | A kit harness is already here | **Stop.** Run its `doctor.sh`, then `harness-audit` — do not scaffold |

It also reports `SUBSTRATE`. **A folder with no git is a normal home, not a problem to fix** — follow `platforms/README.md` for where the files go and how the checkpoint replaces the commit, and never push someone toward git they did not ask for.

**It fails closed**: ambiguous evidence resolves toward the motion that writes least. **Do not ask the person which applies** — people say "we're starting fresh" with a `CLAUDE.md` sitting in the repo. Detect, then confirm what you found.

3. **Read the collaboration tools yourself.** `detect.sh` sees files only. Search and read the channels, pages and documents the person points at, plus anything titled like guidelines, process, brand, templates or decisions. **Read-only, always** — never post, edit or react. Connector tools are deliberately not pre-granted above, so each read asks and the person sees what is being looked at.
4. **Ask once for what is missing**: where the work lives, where the rules live, where decisions happen, and where examples of good and rejected work are. **"I don't know" is an answer** — carry on with what you have and mark the gap.

## 0b · The first sixty seconds

Almost every engagement opens with a variant of **"help me create a harness for X"** or **"turn this into a harness."**

**Do not answer it with a questionnaire.** The interview below is a source of questions, not a script to administer, and opening with "question one of four" is how a person decides this is a process rather than a conversation.

**What they said is already data. Harvest it.** *"Help me create a harness for our marketing team"* has told you the domain, that the standard is almost certainly a judgement nobody has written down, and roughly who will use it. Asking any of that back is the fastest way to lose the room.

**Whatever domain they name is in scope.** If a pack exists you read it; if none does you derive the same three variables from their context — `packs/_deriving.md`. Never tell someone their domain is not covered, and never let a *sketch* pack stand in for their context: `project/PACK.md` and `marketing/PACK.md` are inference, not evidence, and reading one as though it were derived is worse than having no pack at all.

So the first move is three things, in one reply:

1. **Reflect what you found and inferred**, and mark inference as inference. *"So — marketing output, judged on whether it sounds like you rather than anything measurable, and your tone rules live in two places that disagree."*
2. **Ask the two or three things you genuinely cannot infer.** Almost always: what does a polished-but-wrong version look like, what must never be made up, and who decides.
3. **Name what happens next**, briefly, so they know this has a shape.

**Then hand off.** When the architecture document is agreed, move to `harness-build` yourself. The person should never have to know the kit has phases, or which skill owns which one.

## 1 · Fitness — recommend, never gate

Assess `scope/interview.md` §0 from the context and the conversation: **structurable · continuing · decidable · receivable.** Most of it needs no questions.

**Give a recommendation, not a verdict:** *required*, *worthwhile*, or *not recommended*, with one sentence of reason. If all four are plainly met, say so in a clause and move on. If one looks weak, say that clearly — it is the conversation worth having, because a harness over work that cannot use it will pass its own checks and change nothing while its green ticks become load-bearing in people's heads.

**Then the person decides.** Many people struggle to explain their own work, and some want the harness regardless. Both are fine. If they proceed, proceed properly: every weak condition becomes a named risk with a revisit trigger in the architecture document.

**Record the recommendation and the decision either way.** Not assessing is a defect. Refusing to continue is a different one.

## 2 · Interview

Work through `scope/interview.md` in order, **skipping anything the context already answered.** Authority flows downward and later answers depend on earlier ones.

Three questions carry most of the value, and none of them can be answered from documents alone:

- **§1.3 — what failure looks like when the output is technically fine.** The prime directive. Expect the first answer to be wrong; the real one takes a conversation. Without it an agent optimises for fluency, which in a judgement domain is the failure itself.
- **§2.6/2.7 — blast radius and approval tier, recorded separately.** Conflating them is a standing error. A draft can be low risk and still need a human before it is sent.
- **§4 — is the standard scorable, and does a judged corpus exist?** This sets the rung, and it is about the standard, never about how technical the team is.

**Where an answer is missing, mark it missing.** Do not fill a gap with plausible detail about a real organisation — that is the exact failure the harness exists to prevent, committed by the person building it.

## 3 · Write the architecture document

Fill `scope/architecture-doc.template.md`. Every section, including the empty ones — an empty section is information. §0 records the context examined, so anyone can see what the design was based on and what it was not.

§10, **what would change this plan**, is the section most often skipped and the one that keeps the document alive. Each rung needs its promotion trigger.

## 4 · Present and stop

Read it back in plain words. Get agreement on scope, types of work, how each is checked, and ownership **before** anything is built.

The architecture document stands alone as a deliverable. It has value even if no harness follows.

## Failure handling

Stop and report. Never infer an answer to a question that was not asked, never describe the contents of a source you could not access, and never hide a weak fitness condition — state it as a risk, then respect the decision.
