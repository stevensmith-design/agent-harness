# Mock mode

Run the whole app against stubs, with no backend. This is how product work stops
being blocked on API readiness, and it is the single highest-leverage thing in
this harness for a project where the backend is being built in parallel.

```bash
make dev-mock
```

## How it works

One flag — `MOCK_MODE` — swaps every data-source implementation for a stub at
composition time. One flag, one switch point, no per-feature toggles scattered
through the code.

| Layer | Real | Mock |
|---|---|---|
| Data source | HTTP / SDK client | stub returning example data |
| Auth | real provider | stub that reports "already signed in" |
| Telemetry | real sink | no-op |

The auth stub matters more than it looks: if the startup auth check does not
pass, nothing else renders, so it is the first stub to write.

## Adding a stub

Use the `add-stub` skill, or by hand:

1. Define the interface in the product's terms, not the API's shape.
2. Implement the stub against it, returning realistic data — plausible values,
   one long string, one empty collection, one error case. A happy-path-only stub
   hides every layout and error bug until integration week.
3. Register it at the mock swap point.
4. Add a test asserting the swap happens when the flag is set.

## Phasing it out

**Remove the flag from the pipeline. Do not delete the stubs.** They keep earning
their place as test fakes and as offline dev mode. Production safety comes from
never setting `MOCK_MODE=true` in a production build — verify that in CI rather
than trusting convention.

## Release builds

Deliberately allow mock mode in release-configuration builds so QA can be handed
a working binary before the backend exists. That only stays safe because the
production pipeline never sets the flag — which is a CI assertion, not a comment.
