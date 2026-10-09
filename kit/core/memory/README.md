# Memory

**Facts about how the work goes that you would otherwise re-learn.**

Not rules — those are in the constitution or a surface's rules. Not foundations — those survive handover. Memory is the accumulated operational knowledge of running *this* harness: what broke and why, which approach was tried and abandoned, the non-obvious constraint someone hit at 2am.

**The test:** would this still be true after we hand over and walk away? Then it is a foundation, not memory.

## Zones — who owns it, and who may read it

| Zone | Holds | Owner | Shared |
|---|---|---|---|
| Default — this directory | How the work goes here: what broke, what was tried and abandoned | The harness | Yes |
| A **team** subdirectory | Rituals, working agreements, current priorities | The team | With the team |
| A **personal** subdirectory | How one person works, their constraints and context | The individual | **No — never committed** |

**Only the first is required.** Add the others when someone has content for them, not in anticipation.

**The privacy rule is not the directory — it is the gate.** `../scripts/gates/data-boundary.sh` fails on anything tracked under a personal path, so the protection survives someone forgetting the convention. An ignore rule is a convenience; a gate is the rule.

**Personal memory requires trust design, and the design is the point:** what gets stored, who can see it, how it is edited, how it is deleted. If those four questions have no answer for a given file, it does not belong in a shared repository yet.

## Writing it

**One file per topic, named so the directory listing reads as a table of contents** — `deploy-window.md`, not `notes-3.md`. Each file opens with one line saying what it covers. The listing is the index; a separate index file is one more thing that drifts.

Write after figuring out why something broke, after learning a non-obvious constraint, and after discovering an approach that does not work — that last one is the most valuable and the least often written. `../procedures/session-wrapup.md` is the usual moment.

**Every entry carries three things:** when it was learned, where from, and when it was last confirmed.

```
- Exports over 10k rows time out; split by month. (learned 2026-03-02, run 2026-03-02-export; confirmed 2026-05-14)
```

## Using it

- **Verify before acting.** Memory describes the past. When an entry names a file, a setting, a limit or a person's preference, check the current state before relying on it. If it no longer holds, correct the entry or delete it — a wrong memory is worse than none, because it is believed.
- **Foundations win.** If memory and a foundation disagree, the foundation is right and the memory entry is fixed.
- **On demand, never always-loaded.** Read the file a task touches, not the directory. A topic file past roughly a screen and a half gets condensed or split at retro.

## This directory, or the tool's own memory?

Most AI tools keep a memory of their own, per person and per machine. The two do different jobs:

| Goes here, in `memory/` | Stays in the tool's memory |
|---|---|
| Anything the rest of the team should know | One person's preferences for how the tool talks to them |
| Anything a reviewer should be able to read and correct | Temporary state: where a task was left, a working branch |
| Anything that should survive a handover | Nothing another person would need |

A lesson that lives only in one person's tool memory is lost to everyone else, and nobody can review it. When you catch one there, move it here.

## Keeping it healthy

The retro checks memory (`../procedures/harness-retro.md` §6): entries not confirmed in a long while, duplicates, entries that contradict a foundation, and entries that have become rules — those move to the file that owns them. Memory is a destination in the ratchet's routing table (§3), which is what stops operational lore being promoted into rules that fire forever.
