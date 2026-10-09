# Reviews

One dated file per review: `YYYY-MM-DD-<lens>.md`, written against `../../contracts/review.md`.

## Findings must be machine-readable

Prose findings cannot be compared across reviews, and comparing them is the point — see `../../scripts/review-staleness.sh`. So every finding carries one identity line:

```
- [P1] category · path · one-line claim
```

- **severity** — `P1` blocker · `P2` should fix · `P3` note
- **category** — a short kebab slug (`dead-config`, `false-green`, `data-boundary`, `coherence`)
- **path** — the file the finding is anchored to, or `-` where it has none

Everything else — evidence, the proposed change, what was checked and found clean — is prose beneath it. **The identity line is the normative part; the prose is the argument.** Neither couples to the other's layout.

The reason for the split: an agent queries the structured half deterministically, a human reads the prose half for the story.

## Why the same finding twice is a finding about you

`review-staleness.sh` compares the two most recent reviews on `(category, path)` and reports the overlap. Above 70% the correct response is **not** to fix faster — it is to write down why these findings keep surviving.

A finding that recurs across three reviews is not telling you about the code any more. It is telling you the team has decided, without saying so, not to act on it. Record that as a lesson or mark it deferred with a reason. An open finding nobody intends to close is a slow leak in the credibility of every other finding in the file.
