# Promote findings — the self-improving loop

Run this after every review, in every mode — **and over every external review report the
project receives** (impeccable critiques, designer feedback files, other agents' or LLMs'
audits). External reports count as reviews: every rationale in them either maps to an
existing rule (bucket 1) or gets logged (buckets 2–4), *including the reasoning behind
recommendations you disagree with* — the rationale may encode a real failure mode even when
the prescription is wrong. Classifying lessons prevents the same blind spot recurring; it does
not mean every finding should become a shared rule.

Classify each finding into one of four buckets. **A review is read-only unless the user explicitly
authorizes persistence.** Project-level learning may be proposed during a review, but changing
DESIGN.md, tokens, exceptions, candidates, changelogs, snapshots, or shared skills is a write and
needs authorization. Shared rules.md and scan.sh are the substrate every project inherits — an
unreviewed edit there propagates a mistake everywhere. Candidates are *reported first* and logged
only when the user authorizes the logging step.

| Bucket | What it is | Action | Approval |
|--------|-----------|--------|----------|
| **1. Rule existed** | Finding maps to a rule already in rules.md / checklist / DESIGN.md. The gate worked. | Report only. No change. | — |
| **2. Project decision** | A project-specific value or rule (a token, a surface choice, a scan-exception). Not generalizable. | Propose the exact `DESIGN.md` / `tokens.json` / `scan-exceptions.conf` change. Apply only after authorization and representative-screen validation. | Required for writes. |
| **3. Candidate pattern** | A *generalizable* rule that might belong in shared rules.md. | Report it. With authorization, use the project's configured candidate log. **Do not edit rules.md.** | Required for logging and again before promotion. |
| **4. Scanner / validator candidate** | A mechanically detectable pattern that might become a `scan.sh` check, or a token *relationship* that might become a `validate-tokens.py` check. | Report the candidate and test cases. With authorization, log it. **Do not edit `scan.sh` or `validate-tokens.py`.** | Required for logging; promotion also requires fixtures. |

**Candidates file.** Use the project's configured review-candidate log; do not assume a `docs/`
path. Each entry: date,
finding, evidence label, bucket (3 or 4), and the exact proposed change (rules.md section +
one-liner, or scan.sh regex + fixtures). It sits there until the owner approves. Approved
candidates then follow the **growth rule** — promote a rule as a one-liner into an *existing*
rules.md section, plus one pointer line in quick-rules.md and (if reviewable) the checklist;
a new section requires a genuinely new domain. Scanner candidates land as a new check only
after their fixtures pass. The changelog records the promotion at that point, not at logging
time.

**Changelog** (the project's configured review changelog) — one line when a *project decision* is applied
or an *approved* candidate is promoted: date, finding, where it landed. This is the audit
trail, continuing the lineage from `ui-design-feedback-v0.1.md`.

A review that surfaces only *rule-existed* items is the system maturing. A review that
surfaces *candidates* is the system showing where it's still blind — log them so they aren't
lost, but never edit the shared files on your own authority.

**Keep the two rules.md copies in sync.** `.agents/skills/ui-design-principles/references/rules.md` is canonical;
`.agents/skills/ui-design-review/references/rules.md` is a byte-identical review-time mirror. After any approved
edit to the canonical rules.md, re-copy it to the review skill and any configured installation mirrors so no copy
drifts. (These skills package separately, so do not link the copies — a
cross-skill symlink breaks on unpack. Keep the manual re-copy, or use a build/check script.)

Report at the end of the review:

```
### This cycle
- [rule-existed] <finding> -> gate held, no change
- [project] <finding> -> proposed DESIGN.md decision; [not written | authorized and applied]
- [candidate:rule] <finding> -> [reported | authorized and logged], awaiting promotion approval
- [candidate:scanner] <finding> -> [reported | authorized and logged] with proposed fixtures
```
