# Fixtures

Every governance rule ships with an example it must **accept** and an example it
must **reject**. That pairing is the promotion test: a rule with no negative
fixture has never been proven to fire.

- `valid/` — must pass schema **and** semantic validation.
- `invalid/` — must be rejected. Files named `*.semantic.json` are deliberately
  schema-**valid** and fail only on a semantic rule; they exist to prove the
  validator catches what JSON Schema structurally cannot.

`make governance-check` runs both directions.
