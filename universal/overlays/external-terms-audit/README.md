# External terms audit overlay

For applications whose external APIs, SDKs, data providers, platforms, or
stores create meaningful contractual or policy risk.

## What it adds

| File | Does |
|---|---|
| `.agents/skills/harness-external-terms-audit/` | Read-only, evidence-based audit of external-service terms, API policies, data flows, storage, onward transfer, attribution, consent, deletion, age limits, and prohibited uses; renders Markdown or HTML reports |

The base harness already carries a short checkpoint for changes to an external
service or the data crossing its boundary. This overlay adds the comprehensive
whole-application audit and reporting workflow. It adds no always-on gate and
does not run during `make check`.

Use the full audit for an incident response, a client or legal report, a launch
with material third-party data flows, or a scheduled portfolio review. A normal
SDK call or feature change should use the base checkpoint and focused evidence,
not automatically trigger a whole-project audit.

The skill is read-only by default, retrieves the applicable official terms at
the time of each audit, distinguishes evidence gaps from suspected conflicts,
and avoids presenting its output as legal advice. Its examples use fictional
data and the package contains no organisation- or client-specific names.

## Apply

```bash
make overlay-apply NAME=external-terms-audit
make harness-sync && make harness-check
```

Then invoke `/harness-external-terms-audit` when the full audit is warranted.
