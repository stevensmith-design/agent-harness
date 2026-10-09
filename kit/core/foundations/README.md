# Foundations

**What the AI cannot safely invent.** The organ that carries the value, and the one most likely to be rushed.

The rule, stated in the constitution and repeated nowhere else: *if a foundation file you need does not exist, say so and stop.* Never fill the gap by inventing plausible detail about a real organisation. That failure looks exactly like success.

## What belongs here

Thin in code, thick in business. Typical files:

| File | Holds |
|---|---|
| `organisation.md` | What this org does, for whom, and the operating principles that constrain the work |
| `brand.md` | Voice, tone by channel, terminology, what may never be said — **and the derivation rationale** |
| `strategy.md` | Priorities, and what has been explicitly deprioritised |
| `product.md` | What is being built, for which users, doing which jobs |
| `clients` | Accounts and their context. Individuals' details never live in a committed file |
| `capacity.md` | What the team can actually absorb. Easy to forget and load-bearing — generating demand you cannot fulfil is a loss disguised as a win |
| `data-model.md` | The shape maintained by hand, deliberately small. A field nobody maintains is worse than a missing one: it looks like data and is not |

Delete what does not apply. **Thin is correct; empty is not.**

## Zones — optional, and only when something needs them

Most harnesses need one flat set of organisation-level foundations. That is the default and it is usually right.

**Where a harness genuinely holds context at more than one level**, use subdirectories rather than inventing a parallel structure:

```
foundations/
  organisation.md · brand.md · strategy.md      the default — company-wide, shared
  team/                                          how this team works. Shared with the team
  role/                                          what a function needs. Shared
  personal/                                      how one person works. NEVER COMMITTED
```

**None of these is required, and `doctor` does not ask for them.** Most working harnesses have no team, role or individual layer, and run real work well without one. **Levels above the organisation are a service offering, not an organ** — add one only when someone has actually produced content for it.

**A personal subdirectory is different in kind, not just in scope.** It is gitignored and enforced by `../scripts/gates/data-boundary.sh`: a file tracked under that path fails the check. Personal context is the material most likely to arrive through discovery and least likely to have had its privacy thought about — so the rule exists before the content does, which is the only order that works.

## Three rules

**Rationale, not just values.** "We chose this because X" is what lets a new surface be designed rather than guessed. Values without it are arbitrary, and every new surface reinvents them.

**Name your supersessions.** Where two sources disagree, say which wins and why, in the constitution's authority chain. A source that is authoritative and wrong is more dangerous than a missing one.

**Foundations vs. memory.** Would this still be true after we hand over and walk away? Then it is a foundation. Otherwise it is `../memory/`. A sharper test: a sentence that starts with a date is a record of an event → memory. A statement that holds whenever you read it → foundation.

## On overlay engagements

The default verdict is **adopt what already exists as canonical** — a pointer to the client's real file, never a copy. A copy is a second truth, and the two diverge with nothing to say which is stale. See `../../packs/_overlay.md`.
