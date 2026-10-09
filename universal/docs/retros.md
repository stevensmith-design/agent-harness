# Retro log

One row per `/harness-retro`, appended at the bottom — **including the retros that
changed nothing.** A retro with no row did not happen, as far as the next one can
tell.

`scripts/retro-evidence.sh` reads this table: the last date is where the next
evidence window starts, and the always-loaded column is how slow growth shows up
before it reaches the budget. Keep the date first and the line count a plain number.

**Turned down** is the harness's own do-not-re-propose list. Read it before
proposing a harness change; reopening one means saying what has changed since.
Product ideas that were turned down live in `product/decisions.md`.

| Date | Trigger | Always-loaded lines | Findings | Changed (PR) | Turned down, and why |
|---|---|---|---|---|---|
