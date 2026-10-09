# `.harness/` — opt-in L3: orchestration + governance

Two things live here, and they answer different questions.

**`workflows/` + `lifecycle/` own sequence.** Which gate runs when, which are
deterministic vs AI vs human, what each hands to the next. The recurring lesson
from every orchestration engine: *the workflow, not the model, owns sequence,
state, permissions, and completion.* If "done" depends on the model's judgment
about whether it is done, you do not have a gate.

**`schemas/` + `fixtures/` own proof.** Each gate emits a durable record —
evidence, finding, approval, closure — validated against a schema. The rule that
makes this governance rather than paperwork:

> **The producer cannot self-certify.** The actor that produced the work may not
> be the sole authority that declares it finished.

Enforced by `scripts/validate_governance.py`, which checks JSON-Schema validity
*and* the semantic rules schema alone cannot express — namely actor identity
separation. A fixture that is schema-valid but violates a semantic rule lives in
`fixtures/invalid/*.semantic.json`; those exist to prove the validator actually
catches what the schema misses.

## Turn it on

```yaml
# harness.config.yaml
harness:
  level: L3
governance:
  enabled: true
```

```bash
make governance-check   # validate every fixture: valid must pass, invalid must fail
```

Needs Python 3 and `jsonschema`. It runs in its own CI job precisely because it
does not need your product toolchain — governance should not be able to break
because a Node version moved.

## When you actually need this

Not always. This rung earns its ceremony where a wrong order or a
self-certification would genuinely hurt: auth, payments, data deletion, release
config, anything regulated. For a low-risk UI change it is pure overhead — the
`bug` workflow deliberately omits the human approval node for that reason.

Every evidence and approval record carries a `trust` rung — `self_reported`,
`deterministic_runner`, `independent_reviewer`, `authenticated_human`,
`external_policy` — saying what the record is WORTH, which is not the same
question as who it names. `scripts/declare-intent.sh` emits `self_reported`,
and the validator refuses to let a `self_reported` record back an
`approvalClass=human` approval. Nothing here issues `authenticated_human`
today; that needs a channel that issues identity, and it is a named gap rather
than an implied capability.

Match the rung to the risk of the surface, not to the ambition of the harness.

## Without a workflow runtime

`lifecycle/feature.lifecycle.md` is the authoritative SOP whether or not any
engine runs the YAML. The validator runs standalone. You lose automation, not
governance.
