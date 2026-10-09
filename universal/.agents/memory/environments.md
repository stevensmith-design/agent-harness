---
name: environments
description: What each environment points at, who owns it, and what is unsafe to touch
type: reference
---

| Env | Points at | Owner | Agent may |
|---|---|---|---|
| local | stubs (`make dev-mock`) or dev API | — | anything |
| dev | `<url>` | `<team>` | read + deploy |
| staging | `<url>` | `<team>` | read; deploy behind approval |
| prod | `<url>` | `<team>` | **read-only. never deploy without a human approval.** |
