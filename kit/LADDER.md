# The maturity ladder

Five rungs. **A rung is chosen per surface, not per harness** — product UI can sit at L2 while the deck lane sits at L1, deliberately, in the same harness.

The rule that matters: **a trigger promotes a surface, not ambition.** Enforcement depth is earned. Over-harnessing a light lane produces bureaucracy nobody follows, and a lane that nobody follows is worse than an unharnessed one, because its green ticks are load-bearing in people's heads.

---

| Rung | What exists | Trigger to leave it |
|---|---|---|
| **L0 · Ad hoc** | Nothing written down. AI is used; results vary by who is at the keyboard. | Anyone makes the same correction **twice**. |
| **L1 · Standardised** | Constitution, foundations, surfaces classified, procedures and contracts written, a human gate on everything, and a corpus accumulating judged examples. No automated checks. | A class of failure appears that **a script could have caught** — and the corpus is large enough to say what the rule actually is. |
| **L2 · Guarded** | Deterministic gates with self-tests, doctor, protected paths, one command surface, local = CI. | Repeated multi-step work that a **human keeps sequencing by hand**. |
| **L3 · Orchestrated** | Engine-executed workflows, durable pauses, approvals as logged state transitions, isolation per run. | You **cannot tell whether a harness change helped**. |
| **L4 · Learning** | Evals over the judged corpus, telemetry, harness health metrics, model-evolution review. | — |

---

## The corpus gate

**You cannot build an L2 check for a standard you have not defined, and you cannot define a soft standard without a judged corpus.**

This is the single most consequential rule on this page, because it looks like a limitation and is actually the design.

A business team can rightly choose conventions and human review over CI, deliberately, and write down why: automating a brand-conformance check before the standard is defined would encode current guesses as rules, and the standard is a judgement a model cannot score itself against anyway. The revisit trigger is the corpus, not the calendar.

So the starting rung is **not** a function of how technical the team is. It is a function of whether the standard is scorable yet:

| The standard is… | Start at | Because |
|---|---|---|
| Already mechanical (compiles, passes, matches a schema or a format) | **L2** | The check is writable today |
| Mechanical in part (the format is deterministic; the craft is not) | **L2 for the mechanical part, L1 for the rest** | Split the surface rather than averaging the rung |
| A judgement nobody has yet written down (on-brand, surprising, well-argued) | **L1** | Build the corpus first. The check comes from the corpus |

A team of engineers writing marketing copy still starts that surface at L1. A non-technical team shipping structured data can start at L2.

---

## Migrate on adopt, never before

The corpus gate says a surface earns its automation. The same rule applies one level down, to an individual rule — and getting it wrong in the eager direction is the commoner mistake.

**A rule stays prose until someone adopts it. Adoption is when it earns a check.**

A library of rules you have not adopted is reference material: opinions in readable form, deliberately not machine-parsed. Formalising them in advance looks like diligence and costs three real things:

- It **inflates** every rule with a structure duplicating what the prose already says.
- It **locks in identifiers** the adopting team should be free to rename — and a finding cites the identifier, so renaming later breaks traceability.
- It **implies machine-checkability** for a rule that may need adapting first. That is a commitment, and **you do not make a commitment on someone else's behalf.**

The third is the real argument. A schema is a promise about what can be checked; promising it for a rule nobody has agreed to is how a library fills with checks that have never run.

So the audit rule follows: **an unadopted rule in prose form is not a defect.** An *adopted* rule with nothing checking it is — that is a wish sitting in the position of a mechanism, and `PRINCIPLES.md` A9 covers it.

**The artifact this happens to is the rubric** — `core/rubrics/`. It starts as prose, and gains machine-readable criteria on adoption. That is what makes this rule concrete rather than a principle nothing instantiates.


## Model evolution runs the ladder backwards

As models improve, some scaffolding becomes dead code. A rung is not a permanent achievement — a check that exists only to prevent a failure the model no longer makes is now cost with no benefit, and it is one more green tick that means nothing.

The retro asks this once a quarter: **what in here is now unnecessary?** Removing it is a legitimate and under-used outcome.
