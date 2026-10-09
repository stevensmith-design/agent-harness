# Upstream harness feedback

Local drafts for lessons that may improve the source harness or pack. Preparing
a draft does not authorize sending it. Run `harness-upstream-feedback`; a person
reviews disclosure and destination before any external action.

Name drafts `YYYY-MM-DD-<slug>.md` and use this shape:

```markdown
# <finding>

Source harness or pack: <confirmed source, or unresolved>
Local evidence: <counts and dates; no product identifiers>

## Observed failure
<what the harness allowed or failed to make visible>

## Why it generalises
<why unrelated adopters could encounter it>

## Minimal synthetic reproduction
<invented inputs only; no copied product data or internal paths>

## Proposed change
<smallest owning-layer change, plus what must remain unchanged>

## Verification
- Rejection case: <what the improved harness must catch>
- Clean case: <what it must continue to allow>

## Disclosure review
- [ ] Synthetic or approved examples only
- [ ] No secrets, personal data, client identity, internal paths, or proprietary material
- [ ] Destination and contribution rules confirmed
- [ ] Human approved transmission separately
```
