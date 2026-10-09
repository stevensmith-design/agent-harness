---
name: harness-migration
description: Plan and apply a database schema or data migration safely — expand/contract phasing, a tested rollback, and a batched backfill. Use when changing schema, backfilling data, or renaming or dropping a column or table.
license: MIT
metadata:
  harness.tier: implementation
  harness.destructive: "true"
allowed-tools: Read Glob Grep Write Edit Bash(make:*) Bash(./scripts/:*) Bash(git:*)
---

# migration

The one operation in a normal week with no undo button. Everything here exists
because the alternative is restoring from a backup while people watch.

| Use it when | Do not use it when |
|---|---|
| Changing schema on a table with real data | Creating a brand-new table nothing reads yet — just write it |
| Backfilling or transforming existing rows | Seeding local dev data |
| Renaming or dropping a column or table | You are mid-incident — stabilise first |
| Adding an index to a large live table | The change is in application code only |

**Produces:** a migration file, a rollback plan, and a written record of what
was verified. **Never:** runs against production without a person saying so in
that turn.

## 1. Classify it first — this decides everything after

| Class | Examples | Risk |
|---|---|---|
| **Additive** | new nullable column, new table, new index (concurrently) | low — deploy freely |
| **Widening** | relaxing a constraint, growing a type | low, but the old code must still work |
| **Backfill** | populating a new column from existing rows | medium — volume and locks |
| **Narrowing** | adding NOT NULL, tightening a type, unique constraint | high — fails on existing bad data |
| **Destructive** | dropping a column or table, renaming | **irreversible** — expand/contract, never in one step |

If it is narrowing or destructive, stop and phase it. Everything below assumes
you have.

## 2. Expand → migrate → contract

Never rename. Never drop in the same deploy that stopped writing. Three deploys:

1. **Expand** — add the new column/table. Write to both old and new. Old code
   still works, because nothing has been taken away.
2. **Migrate** — backfill in batches. Switch reads to the new shape. Verify
   under real traffic for at least a full business cycle.
3. **Contract** — a separate, later migration drops the old column. This is the
   one you can't undo, so it goes last, alone, and after you are sure.

A rename is an expand/contract with a copy in the middle. There is no shortcut,
and every shortcut is the outage.

## 3. Write the rollback before the migration

Not after. If the rollback is "restore from backup", write that down explicitly
along with how long a restore takes and what data would be lost in the window.
A migration whose rollback nobody has thought about is a migration nobody can
safely stop.

## 4. Backfills are batched, resumable, idempotent

- Batch it (a few thousand rows), commit per batch, sleep between batches.
- Make it resumable from where it stopped — it will be interrupted.
- Make re-running it harmless. It will be re-run.
- Never wrap a whole-table backfill in one transaction. It holds locks for its
  entire duration, and its entire duration is longer than you think.
- Run it as a job, not inside the schema migration. Schema migrations must be
  fast; anything slow blocks deploys and holds locks.

## 5. Test at realistic volume

`make migrate` against an empty dev database proves the syntax parses and
nothing else. Before it goes near production: run it against a copy with
production-like row counts, time it, and check the query plan for the locks it
takes. A migration that takes 40ms on 100 rows can take 40 minutes on 10 million
and hold a table lock throughout.

## 6. Apply

```bash
make migrate-status   # where are we now?
make migrate          # apply
make migrate-status   # confirm
```

Production is a human decision, in that turn, with the rollback plan open. An
agent may prepare a production migration and must not run one on its own
initiative. `make db-reset` refuses to run against a non-local `DATABASE_URL`,
which is a floor, not permission to be casual.

## 7. Record it

`./scripts/emit-evidence.sh check "<actor>" pass "migration <name>: <rows>, <duration>, verified on copy"`
and note in the PR: the class, the phase, the timing on the copy, and the
rollback. Those four facts are what the next person needs at 3am.
