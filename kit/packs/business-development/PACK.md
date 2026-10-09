# Pack: Business development

**Status:** complete.

**This is the pack that proves the anatomy is not about code.** There is no source tree in it and every organ is present.

## The verbs

`pii-scan · secret-scan · dangling-refs · harness-content-split · budget` — and **a human reads it**, which is a verb, not a gap.

## The foundations — thick

Brand and voice spec (the pass/fail standard) · strategy and priorities · offerings · clients · capacity · market · the data model.

**Capacity is load-bearing and easy to forget.** Block every client-acquisition play on a capacity file, because generating demand a small team cannot fulfil is a loss disguised as a win.

**Name your supersessions.** A company brief assembled from public material often understates the business. When it does, the constitution should say so explicitly, and say which file wins.

## Starting rung: **L1**

Not because the team is non-technical — a business harness can run in git with pre-commit hooks — but because **the standard is a judgement nobody has written down yet.** Words like *distinctive* or *unmistakably ours* describe a quality a client recognises instantly and nobody has defined. A model cannot score itself against that, and the failure mode is invisible from the inside.

So the corpus comes first, and the first decision record captures the revisit trigger: *automate the conformance check once enough judged examples exist to calibrate one — the corpus is the prerequisite, not the CI config.*

## The prime directive matters more here than anywhere

In a business harness, **fluent, expected output is often a failure, not a partial success.** Say it outright: a polished paragraph of stock industry language scores worse than a rough one with a real, specific, slightly odd idea in it.

Write this before writing anything else. It is the rule that stops an agent optimising for smoothness.

## What this pack adds beyond core

- **Playbooks** as the procedure form: trigger · consumes · inputs · steps · output · checks · untrusted inputs · personal data · human gate · success metric. **Consumes** and **Human gate** are non-negotiable.
- **Playbooks are cheap and disposable; the context layer is the asset.** Effort goes to foundations. Bias toward a rough playbook that runs over a perfect one on paper.
- **Blast-radius classification that governs where to experiment** — start on the far-future end of the pipeline, where a bad output costs nothing. Never put an unproven play in the path of work that is already sold.
- **Personal data discipline.** Corporate client names are committable; individuals are IDs only. Never in a commit message, PR title, or branch name. **A green PII gate is not evidence a file is clean** — it catches emails and phone numbers and cannot catch a bare name. Codify before the first commit; history is not removable without a force-push.
- **Prose merge conflicts are semantic, not textual.** Two edits to a spec file will merge cleanly and leave it asserting two different things. Git reports success; nothing errors. When a file was touched on both sides, read the merged result end to end. `--ours`/`--theirs` on a foundation file is almost always wrong.
- **Bilingual split** where it applies: the work's outputs in the language they ship in and the client can validate; the operating docs in the language the operators use. Nuance in voice does not survive a round trip.
