---
id: first-contact
surface: harness
status: live
owner: {{OWNER}}
description: The first session in an unconfigured harness. Routes by what the user actually opened with — build intent, learning, incidental work — rather than running a questionnaire. Use when the session hook reports FIRST CONTACT.
---

# First contact

**The first session in an unconfigured harness.** The session-start hook detects the state and points here; this file decides what to do about it.

The state is real: `mode: template`, placeholders unfilled, no foundations, `runs/` empty. A harness in that state **enforces nothing** — every surface pattern matches a placeholder, so every gate passes over an empty set, and the green tick is load-bearing while checking nothing.

But that fact does not tell you what to *do*, because it depends entirely on why the person is here.

---

## Route by what they actually said

Read their opening message before deciding anything. **Do not open with a questionnaire.**

| They opened with | What it is | Route |
|---|---|---|
| *"I'm building an app for X"* · *"we need a landing page for Y"* · a feature request | **Build intent, arriving with context** | §1 — harvest, configure minimally, then work |
| *"teach me about this harness"* · *"what is this"* · *"how does this work"* | **Learn intent** | §2 — orient. Configure nothing unasked |
| *"fix this bug"* · a concrete task in an existing codebase | **Work intent, harness incidental** | §3 — one sentence of honesty, do the task, offer after |
| *"hello"* · nothing · unclear | **No intent yet** | §4 — ask, once, with two options |

---

## §1 · Build intent

**Their opening line is the first foundation input. Harvest it; do not ask it back.**

*"I'm creating a scheduling app for dental clinics in Japan"* already answers: what the work is, who it serves, the market, almost certainly the language of the interface, and a strong hint at the stack. Asking a person to repeat what they just told you is the fastest way to get a harness switched off in its first five minutes.

So:

1. **Write down what they said**, in `foundations/`, in their words. Mark what you inferred as inferred.
2. **Ask only what you cannot infer and actually need now.** Usually two or three things, and one of them is always the prime directive: *what does a bad version of this look like, if it's technically working?* That question is worth asking properly. It rarely lands the first time and it is the rule that stops the agent optimising for fluency.
3. **Configure the minimum**: `name`, `owner`, the one surface they are actually working on, and the constitution's prime directive. Leave the rest as template.
4. **Do the work they asked for.**
5. **Record it** — `runs/`, and the result in `learning/corpus/`, accepted or rejected, with the reason.

**Minimum viable configuration is the point.** You do not need every foundation before writing a line of code. You need: what the work is, what must never be invented, one classified surface, and the prime directive. Everything else is earned by the ratchet, from real failures, later.

**Fitness still applies — as a judgement, not a form, and never as a gate.** (The four conditions are in the kit's scoping interview, §0.) For someone building their own thing, all four conditions are usually met and reciting them is bureaucracy. Reach the conclusion silently and move on. For a client engagement, or where any condition looks shaky, say so plainly and recommend — then the person decides, and a weak condition is recorded as a risk rather than a reason to stop.

## §2 · Learn intent

They want to understand it, not install it. **Configure nothing.**

Explain in this order, concretely, against *this* repo:

1. **What a harness is for** — one sentence: it makes AI output consistent for this particular work, and it improves by mechanism rather than by someone remembering.
2. **The state right now** — unconfigured, and what that means: the gates are green and checking nothing.
3. **What is here** — walk `AGENTS.md`, `foundations/`, `config/surfaces.tsv`, `learning/corpus/`. Four files, not eighteen organs. Depth on request.
4. **The one idea worth landing** — the ratchet. Every correction made twice becomes a rule with a check behind it, and that is what separates a harness from a folder of instructions.
5. **Then offer**, once: *"Want me to configure it for something you're actually working on? It's about ten minutes and the first real task can go through it."*

Take no as an answer. A harness explained is a legitimate outcome for a session.

## §3 · Work intent, harness incidental

They want a task done and do not care about any of this yet.

**One sentence, then get on with it:** *"Heads up — this harness isn't configured yet, so its checks aren't actually enforcing anything. I'll do this now and we can set it up after if it's useful."*

Do the task. Do it well. **Then** offer, once, using what just happened as the argument — a real correction they made is worth more than any explanation of the ratchet.

## §4 · No intent yet

Ask once, and give two doors, not an open question:

> *This harness is set up but not configured yet. Two ways to start: tell me what you're working on and I'll configure it around that as we go — or I can walk you through what's here first. Either is fine.*

---

## What not to do — all four are the same mistake

**Do not generate plausible foundations.** This is the worst thing an eager agent does at first contact. *"I'm building an app for dentists"* → six hundred invented words of brand voice, an invented user segment, an invented positioning statement. That is the exact failure the harness exists to prevent, committed in the harness's own first act — and it is worse here than anywhere else, because everything downstream will be judged against it. **If you do not know it, the file does not exist yet. Say so.**

**Do not scaffold speculatively.** Do not fill every organ because the template has a slot for it. An empty file that looks filled is worse than a missing one.

**Do not set `mode: instance` until the config is real.** That flag is what makes `doctor` start failing on placeholders. Flipping it early to get a green tree removes the only signal that anything is unfinished.

**Do not run the whole interview at someone who asked for one thing.** The kit's scoping interview is for a scoping engagement. At first contact it is a source of questions, not a script.

---

## Stops when
- The person said no to the offer in §2 or §3. Take no as an answer.
- A foundation the route needs cannot be written from what the person actually said. If you do not know it, the file does not exist yet — say so, and generate nothing.
- `mode: instance` is being reached for while the configuration is still placeholders. It stays `template` until the configuration is real.

## Escalates when
- Any of the four fitness conditions looks shaky, or this is a client engagement rather than someone's own work. Say so plainly and recommend; the person decides, and a weak condition becomes a recorded risk rather than a reason to stop.
- The opening message identifies no route. Ask once, with two doors (§4), rather than guessing one.
- What was asked for could only be answered by inventing a foundation. That answer is the owner's to supply.

## Safe to re-run when
- Always, and it stops itself: the session-start hook points here only while `mode: template`. A second run against a harness configured since has nothing to do — read `harness.yaml` and `foundations/` before starting, rather than asking again what has already been answered.


## Done when

Whichever route ran, the session ends with **one of these true**, and it is said plainly:

- Configured and one real piece of work has been through it — `runs/` has an entry and `learning/corpus/` has its first judgement.
- Configured, no work yet — and the next concrete step named.
- Explained, not configured — deliberately, with the offer left open.
- Task done, harness untouched — and the honesty about that stated once, not laboured.

**What is never true at the end:** that it was configured by inventing what nobody said.
