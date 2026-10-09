# Threat models

One per feature that warranted one: `threat-model-<feature>.md`, produced by the
`/harness-threat-model` skill.

A threat model here is not a document to admire. Its output is the acceptance
criteria it added to the spec and the negative tests those became. If you can't
point at the tests, the model didn't land.

Each one ends with a **residual risk** section — what is deliberately not
covered and who accepted it. That section is what an incident responder or an
auditor actually reads.
