# Incidents

One file per event, `YYYY-MM-DD-<slug>.md`. Written **only when something broke**
— not per PR. Unbounded: the budget applies to what agents load every time, not
to the record.

```markdown
# What happened
# Timeline
# What we got wrong — the judgement, not just the symptom
# How it was found
# What would have caught it earlier
# What changed as a result   (link the rule, gate, or hook)
```

The third section is the one that matters. Symptom and root cause without the
**reasoning error** means the next person reasons the same way and is not
stopped. "The glob matched nothing" is a cause; "we assumed writing a rule meant
it was loaded" is the thing to prevent.

Link to this directory from rules, never to an individual file — links to files
rot as cases accumulate.
