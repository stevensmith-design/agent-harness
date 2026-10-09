---
name: no-secrets
description: Never read, print, commit, or hardcode secret values. Applies to every file.
trigger: always
---

# Secrets

Prevents: a token pasted into a log, a test fixture, or a commit — which then
has to be rotated everywhere.

- `.env`, `.env.*`, credential files, service-account JSON, keystores: do not
  open, grep, summarize, or echo them. Read key names from a sample/schema only.
- Config goes in `.env.sample` as a placeholder with a comment. Real values are
  supplied by the operator or the secret manager.
- If a task genuinely needs a secret, stop and ask. Do not invent one, do not
  read it out of another process's environment.
- Never paste secret or personal data into chat, a prompt, a log, a run record,
  or an error. Report the field name and masked format only.
- Checked by `scripts/gates/secret-scan.sh`, run in `make check` and in CI.
