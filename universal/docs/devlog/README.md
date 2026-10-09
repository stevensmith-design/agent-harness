# Devlog

One entry per PR, in the current month's file (`YYYY-MM.md`). Cheap, unbounded,
and almost never read directly — its job is to be *mineable* later.

This exists so that "why" never has to be written into a code comment or an
always-loaded rule file. Without somewhere cheap to put narrative, it ends up
in the expensive places.

```markdown
## 2026-08-22 · REQ-014 CSV export · #482

**Context** — why this was done now
**Decisions** — what was chosen along the way, and what was rejected
**Friction** — what was harder than expected, what surprised you
**Corrected** — what the person corrected, close to their words
**Left undone** — known gaps, deliberate deferrals
**Not verified** — changed but not exercised, and how you would exercise it
**New configuration** — variable and setting NAMES the next run will need
```

`/harness-wrapup` writes these. **Not verified** is the field that does not
exist anywhere else in the harness: the evidence records prove what ran, and
this is the only place that says what did not.

Write "nothing notable" rather than leaving a field blank — a blank field is
ambiguous between "nothing happened" and "nobody filled this in".

**No secrets, no PII, no credential values.** Same rules as anywhere else.

**Corrected** is what `/harness-retro` counts: the same correction in two entries
is a candidate rule. `scripts/retro-evidence.sh` reads month files only, so keep
entries in `YYYY-MM.md` with the date first in the heading.

Entries get promoted: devlog → `../incidents/` (only failures worth changing a
rule for) → a rule, a skill, or a hook. Leave a back-link when you promote.
