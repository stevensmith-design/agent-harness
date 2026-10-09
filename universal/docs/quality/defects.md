# Defect lessons

**Not a bug tracker.** Status, assignee and discussion stay in the tracker. This
file holds one thing the tracker never does: **what each defect taught, and
where that lesson now lives.** Managed by the `defect` skill.

A fix without a lesson prevents one instance. A lesson written to the right
place prevents the class — and when the same rule breaks twice, the second row
is evidence that the first lesson did not hold. `make check-learning` reads this
file and `make retro-evidence` counts it.

## Columns

- **Ref** — the tracker key, or `—`.
- **Rule** — the `INV-`, `DEC-`, `REQ-` or `Q-` the defect broke, or `none`
  when no rule existed. Recurrence is counted by this column, so reuse the ID.
- **Gap** — which part of the loop let it through. One of:

  | Gap | Meaning | The lesson must be |
  |---|---|---|
  | `spec` | nothing said what should happen | a `DEC-`, `INV-`, `REQ-` or `Q-` — decide it, or ask |
  | `test` | a rule existed; nothing checked it | a test, gate or scanner — a path that exists |
  | `render` | only visible when drawn: long, many, none, overflow, overlap | a fixture or visual check (a path), or `human-lane` |
  | `judgement` | a person's call — "unclear", "feels wrong" | a `DEC-`, a design rule, or `human-lane` |

- **Sweep** — the rule applied to every other path, not just this one:
  `12 paths · 2 found (DEF-014, DEF-015)`, or `n/a — <why one path is all there is>`.
- **Lesson** — where the lesson now lives. Never `none`: if nothing is worth
  keeping, it was not a defect.

A recurring rule may not record the same lesson twice — the first one did not
hold, so write a stronger one (memory → rule → test → gate).

`DEF-NNN` is monotonic: never reused, never renumbered.

| ID | Date | Ref | Rule | Gap | Sweep | Lesson |
|----|------|-----|------|-----|-------|--------|
