---
name: harness-threat-model
description: Work out what could go wrong before building it — trust boundaries, assets, attacker goals, and the controls that actually get implemented. Use before building anything handling money, personal data, credentials, uploads, or multi-tenant access, and when adding a new external integration.
license: MIT
metadata:
  harness.tier: planning
allowed-tools: Read Glob Grep Write Bash(ls:*) Bash(git log:*)
---

# threat-model

Cheap before you build, expensive after. Half an hour here routinely removes a
class of bug rather than an instance of one.

| Use it when | Do not use it when |
|---|---|
| Building auth, payments, uploads, sharing, or multi-tenancy | Changing copy, styling, or internal refactors |
| Adding an integration that receives external data | The threat model exists — read it, extend it if the surface changed |
| Handling personal, health, or financial data | You want a review of existing code — that is `/harness-security-review` |
| A pen-test or audit is coming | As a substitute for the always-on rules in `.agents/rules/security.md` |

**Produces:** `docs/security/threat-model-<feature>.md`, plus concrete acceptance
criteria added to the spec. A threat model that does not change the spec was a
writing exercise.

## 1. Draw the boundaries

What crosses from less-trusted to more-trusted? Browser → API, API → database,
your service → third party, webhook → you, user upload → your parser, one
tenant's data → another tenant's request. Name each boundary; every one is a
place a check belongs.

## 2. Name the assets and who wants them

Not "the system" — the specific things. Session tokens, payment methods, private
documents, the admin role, the ability to send email as you, the compute bill.
For each, say who benefits from getting it. "An attacker" is too vague to design
against; "a customer who wants another customer's invoices" is designable.

## 3. Walk the boundaries with STRIDE

At each boundary, ask the six. Skip fast where it doesn't apply — most rows are
"not applicable here" and that is a useful answer to have written down.

| | Question | Typical control |
|---|---|---|
| **S**poofing | Can someone claim to be another principal? | authn, signature verification, mTLS |
| **T**ampering | Can data be changed in transit or at rest? | integrity checks, TLS, immutable audit |
| **R**epudiation | Can someone deny doing it? | append-only log with actor + time |
| **I**nfo disclosure | Can data leak to the wrong party? | authz per object, field-level scoping, redaction |
| **D**enial of service | Can one caller degrade it for everyone? | rate limits, quotas, timeouts, payload caps |
| **E**levation | Can a user become an admin, or a tenant reach another? | deny-by-default authz, no client-supplied role |

## 4. Decide, and write the decision down

For each real threat: **mitigate** (build the control), **accept** (say who
accepted it and why), or **transfer** (say to whom — a provider, an insurer).
Accepting is legitimate; accepting *silently* is not.

## 5. Turn it into acceptance criteria

The output that matters. Each mitigation becomes a testable line in the spec:

> Given a user who does not own document D, when they request `/api/docs/D`,
> the response is 404 (not 403 — a 403 confirms the document exists).

Add an abuse case per boundary, and one negative test per control. A control
with no test is a control that will be refactored away in six months.

## 6. Record the residual

End with what is *not* covered and why. That list is what a future reviewer, an
auditor, or an incident responder actually needs, and it is the thing nobody
writes down.
