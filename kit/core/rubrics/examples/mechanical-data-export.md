---
standard: data-export
title: "Data export conformance"
kind: mechanical
covers: tabular files that leave the team — CSV and spreadsheet exports for clients, finance, partners or other systems
default_severity: fix
derived_from:
  - "ISO 8601 (dates and times) and ISO 4217 (currency codes) — external standards that transfer between organisations"
  - "the export schema foundation file this harness declares for each recurring export"
status: prose
---

# Data export conformance

**Example of a MECHANICAL standard.** Every criterion resolves to something a script can read — an
encoding, a format, a column list, a pattern. A gate is writable today, so this surface starts at
**L2**, and no corpus is required first. That is what makes it mechanical.

It is also deliberately ordinary. Almost every team, in almost every domain, sends a spreadsheet to
someone — a client report, a finance handover, an import into another tool — and the failures below
happen in all of them.

## How it fails in practice

- **Shifted dates** — dates written in a local format or with a timezone dropped. What you see: the
  recipient's tool reads 03/04/2026 as the wrong month, or every date lands a day early.
- **Lost leading zeros** — identifiers exported as numbers. What you see: postcodes, account codes
  and phone numbers arrive with their leading zeros gone and no longer match anything.
- **Garbled characters** — the file is not UTF-8, or the encoding is not declared. What you see:
  names with accents or non-Latin scripts turn into symbols when the file is opened.
- **Moving columns** — columns renamed, reordered or added without notice. What you see: the
  recipient's import silently maps revenue into the wrong field.
- **Ambiguous money** — amounts with no currency, or with thousands separators baked into the text.
  What you see: `1,200` is read as one point two, or nobody can say whether it is yen or dollars.
- **Report furniture** — merged header rows, totals rows and notes inside the data. What you see: the
  file looks fine to a person and breaks every tool that tries to read it.

## What this protects

The people and systems downstream of an export, who cannot see how it was made and will act on what
it says. A wrong figure in a spreadsheet does not look wrong — it gets pasted into a board report or
imported into a ledger. The schema for each recurring export lives in this harness's foundations; this
rubric checks the file against it.

## Where it applies

- **Applies to:** CSV, TSV and spreadsheet files sent outside the team or into another system;
  scheduled report exports; data handed over at the end of a piece of work.
- **Does not apply to:** working spreadsheets that never leave the team; charts and slide tables
  meant only for people to read; one-off scratch analysis. Applying it there produces findings
  nobody needs to act on.

## Criteria

### utf8-declared
**Rule:** the file is UTF-8, and the encoding is stated wherever the format allows it.
**Severity:** fix
**Answers:** garbled-characters
**Meets:** a UTF-8 CSV whose export note states the encoding.
**Misses:** a Windows-1252 file that renders names correctly only on the machine that made it.

### dates-iso-8601
**Rule:** every date is `YYYY-MM-DD`, and every timestamp carries its offset.
**Severity:** blocking
**Answers:** shifted-dates
**Meets:** `2026-04-03`, `2026-04-03T09:30:00+09:00`.
**Misses:** 03/04/2026, or `2026-04-03 09:30` with no offset.

### identifiers-are-text
**Rule:** identifier columns declared in the schema are exported as text, preserving every character.
**Severity:** blocking
**Answers:** lost-leading-zeros
**Meets:** account code `004512` arrives as `004512`.
**Misses:** it arrives as `4512`.

### columns-match-schema
**Rule:** column names and order match the declared schema exactly; any change is a new schema version.
**Severity:** blocking
**Answers:** moving-columns
**Meets:** the header row is identical to schema version 3, which the file names.
**Misses:** `Revenue` has become `Revenue (JPY)` and moved one column left.

### money-is-unambiguous
**Rule:** amounts are plain numbers with a `.` decimal point and no separators, with an ISO 4217 currency code in its own column.
**Severity:** fix
**Answers:** ambiguous-money
**Meets:** `1200.50` beside `JPY`.
**Misses:** `¥1,200.50` in a single cell.

### one-header-row-no-furniture
**Rule:** exactly one header row, then data rows only — no merged cells, totals, notes or blank spacer rows.
**Severity:** fix
**Answers:** report-furniture
**Meets:** row 1 is the header; every following row is one record.
**Misses:** a title in row 1, a merged header across rows 2–3, and a totals row at the bottom.

---

**Why this is the easy case:** every criterion is a parse, a pattern match or a comparison against a
declared schema, so the rubric can become a gate in `scripts/gates/` the week it is written. That is
also why it is the *least* instructive of the three examples — read it for the shape, then read the
judgement example for the part that is hard.
