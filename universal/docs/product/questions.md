# Open questions

Questions nobody can answer from the spec: *"Is it intended that an inactive
customer can be edited?"* · *"There are two buttons for editing a department —
is that on purpose?"* They come from testers, reviewers and agents, usually
after the code exists. Managed by the `decisions` skill.

## Why this is a register and not a ticket

A question closed in a ticket is answered once, for the person who asked. The
next screen raises it again, because the answer never reached the place the
implementer and the agent read. A question here **only closes into a rule**:
a `DEC-` in `decisions.md`, an `INV-` in `domain-rules.md`, or a `REQ-` in
`requirements.md`. That is what makes the next occurrence a test failure
instead of another question.

`make check-learning` reads this file.

| Status | Resolution must hold |
|---|---|
| `open` | `—` — and it is reported once it is older than `product.question_stale_days` |
| `decided` | at least one `DEC-`, `INV-` or `REQ-` that has a row in its register |
| `not-a-rule` | why no rule is needed — "tester misread the label" is an answer; "fine" is not |
| `duplicate` | the `Q-` it duplicates |

`Q-NNN` is monotonic: never reused, never renumbered.

| ID | Raised | By | Question | Status | Resolution |
|----|--------|----|----------|--------|------------|
