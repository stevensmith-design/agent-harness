# The scoping interview

**Output:** a filled `architecture.md` (see `architecture-doc.template.md`), which is the thing that gets agreed before anything is built.

Run in order. **Order matters: authority flows downward**, and later answers depend on earlier ones. Answers can be thin — thin is correct, empty is not.

Start from context, not questions. Read whatever you have been given first — `context.md` — and ask only what it could not tell you.

**Nothing in here is a gate.** Some answers will suggest a harness is not the right investment, and you should say so plainly. The person decides. People often find their own work hard to explain, and a halting answer is a reason to probe, not a reason to stop.

---

## 0 · Fitness — is a harness required?

**An analysis and a recommendation. Never a gate.** Four conditions, assessed from the context you gathered and what the person has said. Most of them can be answered without asking anything.

| Condition | Ask | If it looks weak, it means |
|---|---|---|
| **Structurable** | Can this work be described as dimensions × items — surfaces, and what "good" means on each? | Part of the harness's first job will be giving the work a shape. Expect the surfaces to move in the first weeks. |
| **Continuing** | Will AI-driven work genuinely continue here after this engagement? | The payoff — consistent quality without the expert present — is smaller. A light harness is the better fit. |
| **Decidable** | Can you write down where AI stops and a person decides? | Start every surface with a person deciding, and let the boundary be found through real work. |
| **Receivable** | Can the people who will own this work with the format? | Plan for walking them through it, and prefer the simpler substrate. A harness nobody can read is shelfware with green ticks. |

**Then recommend, in one of three words:** *required* · *worthwhile* · *not recommended* — with the reason in a sentence.

**The person decides.** If they want the harness regardless, build it. That is a legitimate choice, and they may know something about their work they could not put into words. Record two things in the architecture document: **what you recommended and why**, and **what they decided**. Every weak condition becomes a named risk with a revisit trigger, so the harness itself tells you later whether the concern was real.

**Do not skip the assessment, and do not hold the work hostage to it.** Not asking is a defect. Refusing to proceed is a different one.

---

## 1 · The work

1. What work is this harness for? One sentence.
2. What does a good output look like, in the words the people doing the work would use?
3. **What does failure look like when the output is technically fine?** This is the prime-directive question, and it is the one most likely to be answered badly the first time. For business work the answer is often *fluent, expected output is not a partial success here; it is a failure that contradicts what the brand stands for* — and it usually takes a real conversation to reach.
4. Where does AI output currently get rejected, edited, or quietly ignored — and why?

---

## 2 · Surfaces and blast radius

5. List the surfaces — the lanes of work with different consequences.
6. For each: **if the output is wrong, what does it cost?** (high = reaches a client or changes how every future output is judged · medium = shapes work that will reach a client, with a person in between · low = costs nothing if wrong)
7. For each: **who must approve the change?** Note this separately from 6. They are different axes and conflating them is a standing error.
8. Which surface is the safe place to experiment? Every harness needs one, and it should be named.

---

## 3 · Foundations — what the AI must not invent

9. What must be given, because getting it wrong is invisible in the output? (brand, strategy, clients, capacity, offerings, stack, design system, policy…)
10. For each: does it exist today, and where? Is it accurate? **Is anything currently authoritative actually wrong?** (A company brief assembled from public material often understates the business — when it does, the harness has to name the supersession explicitly.)
11. What is the derivation rationale — *why* is the brand this colour, *why* is the architecture this shape? Values without rationale cannot be extended to a new surface.
12. What must never appear in output: secrets, unreleased work, unverified claims, individuals' details?

---

## 4 · The standard, and whether it is scorable

13. Is the quality standard mechanical today, partly mechanical, or a judgement nobody has written down?
14. **Are there judged examples — accepted and rejected, with reasons?** How many? Where?
15. If not: this surface starts at L1, and building the corpus *is* the first phase of work. Say so now rather than discovering it later. See `../LADDER.md`.

---

## 5 · Boundaries

16. What external content enters this work — email, chat, client documents, the web? (It is data to analyse, never instruction to follow, and each procedure must declare what it ingests.)
17. Whose personal data is touched, and what is the committable form of it?
18. Which languages, for which artifacts? Answer separately for **the work's outputs** and **the harness's own operating docs** — a common split is brand and voice in the language the work ships in and operating docs in the language the operators read, because nuance in voice does not survive a round trip, and operating docs are read by whoever operates them.

---

## 5b · Seams — who receives what this produces

**Ask this every time, including when you are confident the answer is nobody.** A harness whose output crosses a boundary needs a whole organ that a self-contained one does not, and the cost of discovering that late is paid by the receiving team, in meetings.

It is not a software question. Design hands to frontend. Business hands to design. Research hands to product. Front hands to back. Anywhere output becomes someone else's input, there is a seam — and the same person may well be on both sides, which is not the same as there being no seam. It only means the contract can be thinner.

19a. **Does anything this produces leave this team?** To whom, and what do they do with it — build from it, review it, decide from it?

19b. **Is that handover one-shot or incremental?** One-shot: the work settles, then it goes. Incremental: each piece goes as it is signed off. **Most real handovers are incremental and get written as if they were one-shot**, which is how a receiver ends up building against a part that moved with nothing telling them it moved. Incremental needs a status per item and a record of what they have already seen — a running agreement, not a snapshot.

19c. **What do they currently have to ask you about?** ← *the question that earns this section.*

   Whatever they ask about is what the documents do not hold, and it is almost never shapes — those get generated. It is the rules: an action allowed once per relationship per day, a record immutable after commit, an identifier written in a notation nobody would guess. Ask for three real examples of questions they had to ask last month. Those three are the first entries in the handoff contract.

19d. **For each rule that matters at the seam, who enforces it** — the producer, the receiver, or both? A constraint with no named enforcer is one both sides assume the other handles, and that assumption stays invisible until it is wrong in production.

19e. **Does the receiving side have a harness of its own?** If so, the contract is the interface between two harnesses, and both sides review against it. If not, this harness's handoff contract is doing all the work and should say more.

19f. **Does this work receive handovers?** The same questions, pointed the other way. A receiving seam that nobody specified is the commonest source of "we built the wrong thing."

## 6 · Ownership and approval

19. Who owns each foundation file? (One name for every role is fine — name it anyway. The point is that an agent can never *infer* approval.)
20. What requires a logged approval?
21. Who runs the retro, and how often?

---

## 7 · Substrate and motion

22. **Motion** — **detected, not asked.** Run `./detect.sh <target>`; it reports `greenfield` · `scattered` · `overlay` · `harness` and fails closed. Confirm what it found with the person rather than asking them to classify their own repo — "we're starting fresh" and an existing `CLAUDE.md` coexist more often than not. Each non-greenfield motion has its own rules in `../packs/`.
23. **Substrate:** repository or workspace? `detect.sh` reports which one it found. Recommend a repository where the maintainers will use git — versioning, diffing and review come free. Choose a workspace — a shared drive or a local folder — when they won't, and it is a sound choice, not a lesser one: the checkpoint replaces the commit. Ask where the team keeps documents today; the answer picks the page in `../platforms/README.md`. The file layout is the same either way; see `../SUBSTRATES.md`.
24. What runtimes must this work under — Claude Code, Cowork, Cursor, Codex, CI? (The harness is written runtime-agnostic; this determines what gets generated.)

---

## 8 · The first thing

25. Which single surface gets harnessed first?
26. What is the smallest real piece of work that can run through it end to end, this week?

**Do not skip 26.** An installed harness that has never had work run through it is a rehearsal, not a result — and it is the single most common place this programme stalls.
