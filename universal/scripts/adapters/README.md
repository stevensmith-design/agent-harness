# Stack adapters

An adapter is the **only** place a real toolchain command appears. Everything
else in the harness — the Makefile, the gates, CI, the skills — speaks in verbs.

Select one in `harness.config.yaml` (`harness.adapter`).

## The verb contract

Define a `cmd_<verb>` bash function for each verb your stack supports. A verb
you do not define is skipped with a warning, not an error — so a partially
filled adapter still runs end to end.

For the generic adapter, a check that genuinely does not apply may be declared
in `harness.config.yaml` as `none: <reason>` (quote the YAML value). This reports
N/A and does not create NOT VERIFIED evidence. Leave it `unconfigured` until the
real command or the reason for absence is known.

| Verb | Must | Notes |
|---|---|---|
| `deps` | install dependencies | idempotent |
| `dev` | run the app against real services | |
| `dev_mock` | run the app against stubs, no backend | sets `MOCK_MODE=true` |
| `lint` | static analysis | non-zero on violation |
| `format` | rewrite files to canonical format | |
| `format_check` | verify formatting, change nothing | non-zero on drift |
| `typecheck` | type checking | omit for dynamically typed stacks |
| `test` | run the test suite | |
| `coverage` | tests with coverage | |
| `codegen` | run code generation | omit if none |
| `build` | production build | |
| `verify` | prove the app actually starts/serves | the evidence recipe |

## Check the project, not the harness

The harness installs its own scripts into the project root, so a tool pointed
at `.` lints them as if the project had written them. Point tools at
`project_targets <ext...>` from `lib.sh` (the project's top-level code without
the harness's folders), or rely on an ignore file the harness ships, as the
Prettier adapters do with `.prettierignore`.

## Writing a new adapter

Copy `generic.sh`, fill in the verbs, save as `<name>.sh`, set
`harness.adapter: <name>`. Then run `make check` — a green run on a fresh
clone is the adapter's acceptance test.
