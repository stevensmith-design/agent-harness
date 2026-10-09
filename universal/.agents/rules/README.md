# Path-scoped rules

One file per constraint that applies only to some paths. These are the canonical
source; `make harness-sync` generates `.cursor/rules/*.mdc` and
`.github/instructions/*.instructions.md` from them.

Frontmatter:

```yaml
---
name: kebab-case-id
description: one line — what this constrains and when it applies
paths: ["src/**/*.ts"]        # globs; omit to always apply
trigger: glob                 # always | glob | model_decision | manual
---
```

Rules for rules:

- A rule states a constraint, not a tutorial. Under 40 lines.
- Every rule names the failure it prevents. No failure, no rule.
- If a rule can be checked by a script, add the script to `scripts/gates/` and
  cite it here. Prose that nothing checks decays.
