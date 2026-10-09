# Permission tiers

Blast radius should match how much the step is trusted. Three named tiers,
swapped with `make tier-explore | tier-build | tier-release`; the active one is
copied to `.claude/settings.json`.

| Tier | Can | Use for |
|---|---|---|
| `explore` | read, search, plan. No writes, no network mutation. | reconnaissance, review, answering questions about the code |
| `build` | edit source, run build/test/lint, install from the package registry | normal implementation work — **the default** |
| `release` | everything in `build` plus push, tag, and deploy | release runs. Switching to it is `make tier-release` — a command, not an authorisation. Nothing in the harness checks who ran it |

Two things to know:

- **Deny beats allow, absolutely.** A broad allow cannot carry a deny exception;
  write the deny and narrow the allow instead.
- Permission rules govern the agent's tool calls, not the processes it starts.
  A script the agent runs can still open any file the OS lets it. Where your
  agent supports an OS-level sandbox, turn it on — the `sandbox` block in
  `build.settings.json` is the shape.
