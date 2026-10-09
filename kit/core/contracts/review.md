# Contract: Review

A review **reports and stops.** It does not produce the corrected artifact and it does not approve. Merging those is how an agent ends up signing its own work.

## Required

- **What was examined**, with its denominator — "14 of 14 files", never "the files"
- **Findings**, each with: severity · location · the evidence · the proposed change with before/after
- **What was checked and found clean** — as valuable as the findings, and what makes a null review credible
- **Confidence**, and what would raise it
- **An identity line per finding**, so reviews can be compared to each other — see `../learning/reviews/README.md`. The structured half is normative; the prose beneath it is the argument.
- **Classification of each finding**, for the ratchet:
  - *existing rule missed* — the rule is fine; it was not applied
  - *one-off decision* — apply it here, systematise nothing
  - *candidate rule* — stage it in `learning/candidates.md`

## State what the review is for — before judging anything

Criteria with no stated purpose float free: applied to the wrong work they manufacture false findings, and applied cautiously they shrink into a checklist nobody reads. So a review says what it is judging **for** before it judges. Where a rubric applies, these come from the rubric; where none does, write them for this review.

- **The failures it is looking for** — named, and taken from real rejections, corrections or incidents where they exist. Describe what you would *see*, not a category: *"totals do not match the source system"*, not *"data quality issues"*. **This is the highest-signal part of a review, because it is what review actually finds.**
- **What is at stake** — one or two sentences on who is affected when this work is wrong, and how.
- **The boundary** — what this review covers, and the near misses it deliberately does not.

**The test that shows this is load-bearing:** imagine the same review pointed at work just outside the boundary. If every finding would still apply, the purpose statement is decoration and the findings are generic.

## Never

- Approve. Approval is a separate contract, by a different person.
- Apply the changes, unless the review was explicitly invoked in a mutating mode.
- Report a finding you could not verify without saying so.

**A review that reports nothing after looking hard is a legitimate outcome. A review that did not look is not, and manufactured findings are worse than either.**

The distinction is the denominator: "examined 14 of 14, nothing found" is a result. "Nothing found" alone is indistinguishable from not looking, which is why the first required field exists.
