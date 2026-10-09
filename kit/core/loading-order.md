# Always-loaded contract

**Budget: 60 lines.**

The files below load into **every** session. `scripts/check-budget.sh` sums them and fails when the total exceeds the budget.

## Always loaded

- `AGENTS.md`

## Rationale

A budget on one file is gameable, and gets gamed without anyone deciding to: content moves out of the constitution into another file that also loads every time, the budget goes green, and the attention cost is unchanged. **The budget belongs to the set, not the file.**

Add a file here only when it genuinely loads on every task, and expect the budget to be spent — it does not grow to accommodate the addition. That is the forcing function.

**Net zero.** The budget is a ceiling; the health measure is the trend. Every addition to the always-loaded set pays for itself with a removal of the same size in the same change, so across retros the total stays flat or shrinks. `learning/retros.md` records the size at each retro, which is what makes slow growth visible before it reaches the ceiling.

Everything else loads on demand, when the procedure or rule that needs it fires.

## Tier 2 — on demand

Listed for orientation. **Not counted** against the budget, and the parser reads only the section above.

- `foundations/` — when generating anything
- `config/surfaces.tsv` — when deciding risk or approval
- `contracts/` — at a gate
- `procedures/` — when one runs
- `learning/corpus/` — before generating, and when judging
- `read-first.md` — at the start of a task, to know which of the above it needs
- `decisions/log.md` — before suggesting a change to how the work runs
- `memory/` — the topic file a task touches, verified before it is relied on
