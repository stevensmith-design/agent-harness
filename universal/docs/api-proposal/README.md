# API proposals

Operations that have been proposed but not yet agreed or built, written from the
requirement that needs them. Output of the `api-design` skill.

Which side authors a proposal first — the side that consumes the contract or the
side that implements it — is a project decision. Nothing here assumes one.

`<resource>.yaml` — OpenAPI 3.x, resource-sliced, plus a rationale block naming
the requirement that needs it and what the consumer does today without it.

**Every operation carries an `operationId`, an `x-status` and an `x-req`** — `proposed` ·
`agreed` · `frozen` · `changed` · `superseded`. A single file-level `status:` is
retired: a handover is incremental, and one document holds operations agreed on
four different days. `make check-api` enforces this.

`AGREEMENTS.md` is the sign-off ledger — one row per review, naming the
operations it covered and where the consumer was told. `make check-agreements`
fails if an `agreed` or `frozen` operation changes shape without a new row.

A proposal is a request, not a decision. The owning team may change it. Keep the
matching stub aligned with whatever it becomes — proposal and stub drift apart
the moment they live in separate commits.

**Rules that are not shapes do not live here.** Once-per-user-per-day,
immutable-after-commit, what each `404` means: those go in
`docs/product/domain-rules.md`, which is also where it is written down whether
the client, the server, or both enforce them.

## No API surface

`make check-api` fails when a requirement in `specced`, `in-progress` or
`shipped` has no operation naming it. Most of the time that means the contract
has not been written yet. Sometimes it genuinely means the requirement has no
API surface at all — a copy change, a local-only setting, a build script.

List those here, one per line with a reason. The exemption is deliberately a
sentence someone has to write rather than a column in the requirement register:
the register belongs to the product lane, and a column only this gate reads
would be a second tracker growing inside the first.

<!-- - REQ-000 — reason -->
