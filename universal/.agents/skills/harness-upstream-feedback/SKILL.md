---
name: harness-upstream-feedback
description: Turn a locally verified harness lesson into a minimal, sanitized proposal for the source harness or pack. Use after a harness retro confirms the lesson applies beyond one project, or when a person explicitly asks to prepare feedback for the harness source. Produces a local draft only; it never posts or opens an issue.
license: MIT
metadata:
  harness.tier: maintenance
allowed-tools: Read Glob Grep Write Edit
---

# upstream-feedback

Carries reusable learning back to a source harness without carrying the
project, its people, or its secrets with it.

| Use it when | Do not use it when |
|---|---|
| A local retro has verified a harness-level lesson | A product bug merely happened while the harness was installed |
| The same gap could affect unrelated adopters | The finding is supported by one speculative occurrence |
| A person asks for a sanitized upstream proposal | You have permission only to prepare, not transmit, feedback |

**Produces:** `docs/upstream-feedback/YYYY-MM-DD-<slug>.md`.

**Never:** changes the source harness, opens an issue, sends a message, or
publishes a draft. Those are separate external actions requiring explicit
human authorization at the time of transmission.

## Eligibility

Start from a completed local `harness-retro`, not raw frustration. The finding
must have:

- evidence that the local harness did not already handle it;
- a reason it generalises beyond this product;
- a proposed owning layer and a way to verify the improvement;
- the source harness or pack supplied by a person or recorded provenance.

Do not assume the product repository's Git remote is the harness source. If the
source is unknown, mark it unresolved and prepare no destination-specific text.

## Minimise before writing

Use the smallest synthetic reproduction that preserves the failure. Remove:

- names, email addresses, account identifiers, customer text, analytics rows,
  screenshots, chat excerpts, and other identifiable or private data;
- secrets, environment values, internal URLs, repository paths, branch names,
  hostnames, and infrastructure details;
- proprietary code, product strategy, unreleased features, and contractual
  material;
- unrelated logs and full files where one invented example proves the point.

Do not open a sensitive file in order to redact it. Work only from the already
approved retro evidence. If sanitising the finding would make it untestable,
stop and report that it cannot safely travel upstream.

## Write the local proposal

Copy the structure in `docs/upstream-feedback/README.md`. Keep observation,
inference, and proposal separate. State the narrow change, what should remain
unchanged, and one rejection test plus one clean test where the source supports
deterministic checks.

The draft must stand alone without links into this product. Use synthetic names
and paths. Attribute external material only when its licence and disclosure are
clear; otherwise describe the abstract failure.

## Human gate

Before the draft leaves the repository, a person must verify:

1. the lesson is genuinely reusable;
2. every example is synthetic or approved for disclosure;
3. no secret, personal data, client identity, internal path, or proprietary
   detail remains;
4. the destination and its contribution rules are correct;
5. the proposed change does not silently broaden the source harness.

After that review, stop. Posting still requires a new explicit instruction.

## Done

- A sanitized local proposal exists, or the reason it cannot safely be shared
  is reported.
- The local fix remains recorded locally; upstream feedback is not a substitute
  for repairing this project.
- Nothing was transmitted and no external state changed.
