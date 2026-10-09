# Spec: export the current list view to CSV

Status: draft · Owner: A. Maintainer · Created: 2026-09-22

<!-- A filled-in spec, for reading before writing your first one. It is in
     specs/000-template/ so the clarity gate treats it as reference, not work. -->

## Problem

People reconcile our numbers against their own spreadsheets by retyping what
they see on screen. It takes them about twenty minutes a week each, and the
retyping introduces errors we then get asked to explain.

## Users and context

Operations staff, at the end of a reporting period, working from a filtered
list of a few hundred rows. They have the filters they want already applied and
do not want to re-specify them somewhere else.

## User stories

### US-1: Export what I am looking at

As an operations user, I want to download the rows currently shown, so that the
file matches the filters I already chose.

**Acceptance criteria** — each one testable, each one a fact you can check:

- [ ] Given a filtered list of 250 rows, when I choose Export, then the file
      holds those 250 rows and no others, in the order shown.
- [ ] Given a list of 0 rows, when I choose Export, then the control is disabled
      and the empty state says why.
- [ ] Given the export fails server-side, when the error returns, then the list
      is unchanged and an error message names a retry.
- [ ] Given a value containing a comma, a quote or a newline, when it is
      written, then the file parses back to the same value.

## Screen states

- Loading: the Export control shows a spinner and is not clickable; the list
  stays interactive.
- Empty (zero rows, no results): the control is disabled, with "Nothing to
  export — clear a filter to see rows" beside it.
- Error (the call failed, the input was refused): an inline message above the
  list, the control returns to its normal state, nothing is downloaded.
- Success: the file downloads and a confirmation names the row count.

## Data that persists

Nothing is stored. The file is generated per request and streamed; no export
history, no server-side copy. A failed export leaves no partial file.

## Roles and permissions

Anyone who can see the list can export it — the file contains exactly the
columns already on screen. Users without list access never reach the control,
and a direct request without access returns the same not-found the list does.

## States this touches

| State | What must happen |
|---|---|
| Archived rows hidden by the current filter | Absent from the file — the file matches the view |
| A row deleted while the export runs | The file may contain it; it is a snapshot, and says so in the confirmation |
| Session expired mid-request | No partial file; the sign-in prompt appears and the list is unchanged |

## Failure and recovery

A failed export never changes the list. The message says what to do — retry, or
narrow the filter if the export timed out — and retrying is safe because nothing
was written.

## Non-functional requirements

- Performance: 5,000 rows in under 10 seconds; larger requests are refused with
  a message naming the limit rather than timing out.
- Accessibility: the control is reachable and operable by keyboard, its disabled
  state is announced, and the confirmation is announced.
- Security / privacy: the file carries only columns the user can already see.
- Offline / failure behaviour: with no network, the control reports the failure;
  nothing is queued.

## Non-goals

- Scheduled or recurring exports.
- Any format other than CSV.
- Exporting rows the current filters exclude.

## Open questions

None open. (Resolved: the delimiter question closed into DEC-014, comma.)

## Success

Within a month, the weekly retyping is gone from the two teams that asked, and
no support request that period is about a mismatch between screen and
spreadsheet.
