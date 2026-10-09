# Quality — what the harness sees, and what only a person does

A harness verifies what is written. It does not find what nobody has written
yet, and it does not see a screen the way a person does. A green `make check`
that does not say so is a false green (PRINCIPLES D5, applied to testing).

## Two jobs that must not be mixed

| | Prevents recurrence | Finds something new |
|---|---|---|
| **What does it** | specs, registers, tests, gates | a person using the product; exploration |
| **Fed by** | the lessons in `defects.md`, the answers in `../product/questions.md` | the diff, and the list below |
| **Measure** | the same rule does not break twice | how many defects were found before release |

Writing more spec strengthens the first column and does almost nothing for the
second. Both are needed, and the loop between them is the point: every thing a
person finds becomes a lesson (the `defect` skill), and every question becomes a
rule (the `decisions` skill), so no one finds the same thing twice.

## The human lane — what the harness cannot see

Every PR's **Not verified** section starts from this list. Delete a line only
when something in the repo now checks it, and name that thing.

- **How it feels** — "hard to tell this is a button", "the hover effect clashes".
  There is no right answer in any spec; a person decides, and the decision goes
  to `decisions.md` or the design rules.
- **Visual detail on a real screen** — an agent reading a screenshot misses
  alignment, rhythm and near-misses a person sees at a glance.
- **Input methods** — Japanese/Chinese IME composition (Enter confirms the
  conversion; it must not submit), autocomplete, paste, touch versus mouse.
- **Environments CI does not run** — other browsers, the customer's OS, fonts,
  proxies, on-premises installs.
- **Order and combination** — upload, add, delete all, upload again; withdraw,
  then resubmit. The spec for each feature is correct; the sequence is not.
- **Anything not rendered** — a state no fixture puts on screen was not looked at.

## Making the human lane cheaper, not replacing it

- **Stress fixtures.** Keep one fixed seed with the extremes: the longest real
  name, three-digit counts, zero items, the deepest hierarchy, mixed Japanese and
  English, archived and deleted parents. Render the main screens with it on every
  run. Most layout breaks are content extremes, not taste, and this finds them
  before anyone opens the app.
- **Measure what can be measured.** `make render-audit` draws each page in
  `render-pages.txt` at phone and desktop width and measures tap targets, text
  size, text that spills or is clipped with no way to read it, overlapping
  controls, and sideways scroll. States it cannot reach — a "no results" shown
  before loading finished — are DOM facts an e2e test can assert. Do not spend a
  person's time finding what a measurement can. What the audit skips — content
  in containers that scroll sideways on purpose, anything under a fixed bar,
  states it was not told to reach — is still theirs.
- **A contact sheet for the person.** The same run writes every page's
  screenshots and findings to one `index.html`. The person's job becomes a
  two-minute look, not a search.
- **A brief, not "please test".** From the diff: what changed, which states in
  `../product/domain-rules.md` it touches, which lines above apply. Exploration
  with a direction finds more than exploration without one.

## What "good" looks like — so the agent does not have to guess

An agent has no idea what good looks like for this product. Left to guess, it
produces the average of everything it has seen: generic layouts, decoration in
place of hierarchy, and controls that ignore the basics, such as a 20px tap
target on a phone. Better prompting does not fix this. **Writing "good" down
does**, in three layers, from the most mechanical to the least:

| Layer | What it holds | Checked by |
|---|---|---|
| **Measured** | tap target ≥ 44px at phone width, text ≥ 12px, no spill, no silent clip, no overlap, no sideways scroll; token relationships | `make render-audit`, `make check-design`, `make check-tokens` |
| **Written** | the design system and its rules: `DESIGN.md`, `tokens.json`, the `ui-design-principles` rulebook | `ui-design-review` against the contact sheet |
| **Judged examples** | screens a person has marked good or bad, *with the reason*, in `examples/` — taste that no rule states | the reviewer compares against them; a person decides |

A person's judgement feeds the layers above it. When the same "this looks wrong"
comes up twice, it becomes a written rule. When a written rule can be measured, it
becomes a check. The `judgement` gap in `defects.md` is where that starts. Until a
judgement can move up a layer, record it as a judged example: a screenshot, *good*
or *bad*, and one sentence on why. Examples with reasons teach far more than
adjectives like "clean" or "modern".

## Where things go

| File | Holds |
|---|---|
| `defects.md` | each defect's gap, sweep and lesson — not its status |
| `render-pages.txt` | the screens `make render-audit` draws |
| `examples/` | judged screens — good or bad, and why |
| `../product/questions.md` | questions that must close into a rule |
| `../product/domain-rules.md` | the rules a sweep runs across |
