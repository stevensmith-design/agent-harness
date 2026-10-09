# Rubrics — the articulated standard

**The artifact between the corpus and the gate.**

Judged examples in `../learning/corpus/` show what good and bad look like. Gates in `../scripts/gates/` mechanically reject specific violations. A rubric is what sits between: **the standard, written down, in a form a reviewer can apply and a gate can eventually be derived from.**

Without it the ladder has a missing rung. `../../LADDER.md` argues that a rule stays prose until someone adopts it, and then earns a check — but that argument needs an artifact that can *exist in both states*. This is it.

---

## This directory is a method, not a library

**The kit does not ship a rubric library, deliberately.** A library covers the domains someone thought of, and the next domain you walk into is the one it does not cover. What ships instead is:

- **the method** — how to write a rubric that holds up, below
- **`_TEMPLATE.md`** — the shape
- **`examples/`** — three worked examples, chosen to cover three **kinds of standard**, not three domains

That last distinction is the whole design. A dozen rubrics for one domain teach you that domain. Three rubrics across mechanical, structural and judgement standards teach you the **method**, which is what you need when the work is something nobody has written a rubric for.

## Which kind of standard is this?

Ask before writing anything. It decides the rubric's shape, the rung it starts at, and whether a gate is even reachable — and it maps onto the classification `../../LADDER.md` already uses.

| Kind | The standard is | Starting rung | Example |
|---|---|---|---|
| **Mechanical** | Measurable now. A number, a format, a pattern | **L2** — the check is writable today | `examples/mechanical-data-export.md` |
| **Structural** | Not about quality but about **shape**: a required field, an owner, a date, a link that resolves | **L2**, and usually the cheapest one available | `examples/structural-commitment-register.md` |
| **Judgement** | Real, and nobody has written it down yet. "On brand", "persuasive", "well-argued" | **L1** — the corpus comes first; the check is derived from it later, or never | `examples/judgement-brand-voice.md` |

**Most first rubrics in a new domain are judgement rubrics, and that is correct.** Writing a mechanical check for a standard you have not defined encodes today's guesses as permanent rules.

---

## Writing one

Four sections, written in this order. The order is the method: each section is the raw material for the next.

### 1 · How it fails in practice — write this first

List the failures this rubric exists to catch, **taken from what has actually gone wrong here**: work that was sent back, corrections someone made by hand after the agent finished, an incident, a complaint. Three to seven. Name each one, then describe what you would *see* — *"the export opens with every date shifted by a day"*, not *"date handling issues"*.

Starting here is deliberate. Failures are the easiest thing to source, because people remember them, and they are the most useful thing a reviewer can hold. **A rubric that starts from ideals produces a style guide. A rubric that starts from failures produces a standard.**

If you cannot list a single real failure, stop. That is not a signal to invent some — it is the corpus gate telling you this work has not run long enough to have a standard yet.

### 2 · What this protects

One short paragraph: **what is at stake when this goes wrong, and for whom.** Not a definition of the topic. If the paragraph would read the same in any organisation, it is not grounded yet — name the foundation files and corpus entries it draws on.

### 3 · Where it applies — and where it does not

- **Applies to** — the concrete kinds of work this rubric is pointed at.
- **Does not apply to** — the near misses: work that looks similar, where applying this rubric would produce false findings.

**The test that proves this section is load-bearing:** point the rubric at something from the *does not apply* list and read the criteria. If every one of them still fires, the boundary is decoration — the criteria are generic, and they belong in a broader rubric or nowhere.

### 4 · Criteria — each one answers a failure

Each criterion gets a stable `id`, a one-sentence **rule**, a **severity**, a concrete **meets** and **misses** example, and the failure it **answers** from section 1, named in kebab-case.

- **Every criterion answers a named failure.** A criterion that answers none is gold-plating. A failure that no criterion answers is a gap. Both are visible at a glance, which is the point of the field.
- **The `id` is stable.** Findings cite it, so renaming one later breaks the trail.
- **The misses example is the real test.** If you cannot write a concrete one, it is not a criterion yet.
- **Five to nine criteria.** A rubric nobody gets to the end of is not applied.

### Severity

`blocking` — the work does not ship · `fix` — correct before the next review · `note` — worth knowing, no action required.

**Use `blocking` sparingly.** When everything blocks, a deadline arrives and the whole rubric gets waived at once.

---

## Adopting a rubric

**A rubric starts as prose. It becomes machine-readable when a team adopts it** — when it governs real work here and the team accepts its criterion ids.

Before adoption it is reference material: an opinion in readable form. Formalising it early costs three things:

1. It **duplicates** the prose in a second structure that has to be kept in step.
2. It **fixes ids** the adopting team should be free to rename — and findings cite ids.
3. It **promises checkability** for criteria that may need adapting first — a commitment made on someone else's behalf.

So: **an unadopted rubric in prose is not a defect. An adopted rubric with nothing checking it is** — a wish sitting where a mechanism belongs (`../../PRINCIPLES.md` A9).

On adoption, change `status` and add the criteria to the frontmatter, each naming **what checks it**:

```yaml
status: adopted
adopted: 2026-09-01
approved_by: <person>
criteria:
  - id: stable-kebab-id
    severity: fix
    rule: "One sentence"
    checked_by: scripts/gates/<gate>.sh   # or: reviewer
```

`checked_by` is the field that keeps a rubric honest. A criterion checked by `reviewer` is legitimate. A criterion that names a gate which does not exist is exactly the defect `../scripts/gates/dead-config.sh` exists to find.

**Every criterion keeps its prose in the body.** The frontmatter is what gets checked; the body is why. Neither depends on the other's layout.

---

## Deriving a rubric for a domain the kit has never seen

The universal path. No domain library required.

1. **Name the kind of standard** (table above). It decides everything downstream.
2. **Harvest, do not invent.** Pull failures from what already exists: the foundations, rejected examples in the corpus, and the corrections a person made by hand. **A rubric written from general knowledge of a domain is a checklist; a rubric written from this team's rejections is a standard.**
3. **Write the failures first**, then the boundary, then the criteria that answer them.
4. **Cap it** at five to nine criteria.
5. **Leave it in prose.** It has not been adopted yet.
6. **Apply it to one real piece of work before writing a second rubric.** The commonest failure here is writing a set of rubrics nobody has applied once.

If step 2 comes up empty — no foundations, no rejections, no corrections — **that is not a signal to invent. It is the corpus gate telling you this surface is at L0 and needs real work to run through it first.**
