# Validator computed-relationship catalog

The full list of relationships `scripts/validate-tokens.py` computes. SKILL.md keeps the invocation
and the one-line caveat; this file is the detail it points at. The validator is **frozen** — its
behaviour is locked by `tests/run.sh` (30/30 fixtures); a change lands as a new `pass/` + `fail/`
fixture pair first, then the code.

## What it computes

- **Contrast pairs** — body-on-canvas, body-on-card, muted-on-canvas, **CTA-label-on-CTA**,
  **badge/count-label-on-accent** (small text → full 4.5:1, assessed only when a badge fill role is
  declared).
- **Primary ↔ disabled distance** — **derived from the disabled-opacity when no explicit disabled
  token exists** (2:1 is reported as a project heuristic/WARN, not a WCAG failure) · semantic-colour
  mutual distinctness · **selection ≠ action** distance (deltaE threshold is advisory; rendered
  non-colour channels decide).
- **Saturated support-accent permission** with hue/chroma/temperature relationship metrics
  (advisory; requires a declared palette job but never bans a hue from distance alone).
- **Neutral ramp** derived from the brand hue (low chroma, not dead-gray, not off-hue).
- **Background ↔ card value step** (1.05–1.12) · tinted tile/well/chip/callout separation against
  plausible grounds (advisory until actual placement is rendered) · type-scale ratios · radius scale
  sanity.
- **Elevation ramp monotonicity** (+ opacity-fall hint) · 60/30/10 budget hint · dark-mode
  preservation.

## Exit codes and coverage

Exit `0` = no broken relationships (WARN/INFO allowed); `1` = at least one FAIL; `2` = bad input.
It always reports a coverage ratio (`N/4 required relationships assessed`); `--strict` makes missing
required coverage a FAIL rather than a silent SKIP (use it for greenfield Create gating).

The `--json` output carries an **additive `coverage` object** (headline ratio unchanged, also still
present as the `coverage/summary` item): `{required_assessed, required_total, ratio,
per_relationship: [{relationship, assessed}]}` — so a consumer can see *which* of the four required
relationships were assessed vs skipped, not just the count.

It is **project-agnostic** — it flattens whatever schema the project's `tokens.json` uses and reports
SKIP for any role it cannot resolve rather than guessing. It is deterministic and CI-gradeable, so
the math costs no prompt load. It **requires only Python 3.x and the standard library** — no
`pip install`, no external packages.

## What it is not

A PASS means the token *relationships* cohere — it is not visual sign-off. It cannot see layout,
rhythm, imagery, or whether the aesthetic is any good. It is the floor, not the ceiling; the
five-question coherence test (`references/mode-coherence.md`) and `ui-design-review` are the judgment
on top.
