# Security policy

Agent Harness is a one-person project, maintained on a best-effort basis. There's no SLA. The harnesses are guardrails for agent work, not a security product, so please don't rely on them as your only safeguard.

## Reporting a problem

Please report privately, not in a public issue. Use GitHub's private vulnerability reporting: **Security → Report a vulnerability** on this repository. I'll reply as soon as I can.

In scope:

- a way to get past a gate, or make one pass without checking anything,
- a hook that fails open: it errors, times out or is skipped, and the action goes ahead,
- installer behaviour that overwrites a file in the target project, or copies files that shouldn't leave this repository (a `.env`, a declared intent, local paths),
- a secret or personal-data scanner that misses something it claims to catch.

Use fake values in your report, never real secrets or client data.

Ordinary bugs, and false positives that block correct work, are welcome as normal issues.

## Supported versions

Only the latest commit on `main`.
