---
name: harness-add-stub
description: Add a stub implementation of a data source so the app runs with no backend, and register it in mock mode. Use when starting a feature before its API exists, or when a test needs a fake.
license: MIT
metadata:
  harness.tier: implementation
allowed-tools: Read Glob Grep Write Edit Bash(make:*)
---

# add-stub

**Produces:** an interface, a real implementation, a stub, and the test that
swaps them. **Never:** a stub on a production code path.

Decouples product progress from backend readiness, which is the single biggest
schedule risk on most projects — and gives tests their fakes for free.

| Use it when | Do not use it when |
|---|---|
| The API does not exist yet | The real endpoint is live and stable |
| You need deterministic data for a test | You want to skip writing the real client entirely |
| Demoing before integration | Production code paths — a stub must never ship enabled |

## Procedure

1. **Define the interface first**, in the product's own terms — not the API's
   shape. Letting the backend's response define your interface is how a
   temporary API becomes permanent architecture.
2. Write the real implementation and the stub against that one interface.
3. The stub returns realistic data: plausible values, at least one long string,
   one empty collection, and one error case. A stub that only returns the happy
   path hides every layout and error bug until integration week.
4. Register it wherever mock mode swaps implementations, guarded by the
   `MOCK_MODE` flag (see `docs/mock-mode.md`).
5. Add a test asserting the swap actually happens in mock mode. That test is what
   stops a stub from silently reaching production.
6. Run `make dev-mock` and confirm the feature works end to end with no backend.

## Rules

- One flag controls all stubs. Never scatter per-feature mock switches.
- Stubs stay in the tree after the real API lands — they are the test fakes and
  the offline dev mode. **Phase out by removing the flag from the pipeline, not
  by deleting the stubs.**
- Production safety is a pipeline property: never set `MOCK_MODE=true` in a
  production build. Verify that in CI rather than trusting convention.
- When building against a stub reveals the API shape you actually need, capture
  it with the `api-design` skill instead of waiting to be handed a contract.
