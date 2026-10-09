# Capability skills — a vetted catalog

Two kinds of skill live in this harness, and the difference is the point:

- **Workflow skills** (`.agents/skills/`, authored here) — how *this team* works.
  22 of them; they are the harness.
- **Capability skills** (vendored, pinned in `skills-lock.json`) — reusable
  framework, language, or domain know-how someone else maintains better than you
  would. You import these the way you import a dependency. Four ship vendored:
  the design suite, below.

## The design suite (vendored, four skills)

`ui-design-system` · `ui-design-principles` · `ui-design-review` · `ia-review`

They exist because the harness had the enforcement without the thing enforced:
`design.tokens_path` was set by `harness-init` without checking anything was
there, a rule said "use tokens from that path", a gate grepped for raw hex — and
nothing in the harness helped you create a token layer. Config that points at
something nothing produces reads as enforcement to anyone skimming. That is the
same failure the `surfaces:` block had.

| Skill | Owns | Runs when |
|---|---|---|
| `ui-design-system` | `DESIGN.md` + `tokens.json` — create, extract, audit, drift | before substantial UI work, and when screens stop cohering |
| `ui-design-principles` | the build-time guardrail | while a screen is being written |
| `ui-design-review` | per-screen and per-PR visual + code review | when a screen is finished |
| `ia-review` | navigation, hierarchy, labelling, progressive disclosure | when structure is designed or users get lost |

**The validator is harness-owned.** `scripts/validate-tokens.py` computes the
relationships between tokens — contrast pairs, semantic distinctness, neutral-ramp
derivation, type-scale ratios, elevation monotonicity. It backs both the
`ui-design-system` skill and `make check-design`, so the skill and the gate can
never disagree about what a coherent system is. There is one copy and no
discovery step: if it is missing, the gate fails rather than degrading.

Vendored from a non-git source, so they are pinned by **content hash** rather than
commit SHA. `make skills-verify` still fails on an in-place edit — which is what
stops a vendored copy silently drifting from the library it came from.

```bash
make skills-add REPO=supabase/agent-skills SKILL=skills/supabase-postgres-best-practices
make skills-vendored  # what is vendored, its licence, its pin
make skills-verify    # content still matches the pin
make skills-update    # re-pin deliberately, then read the diff
```

`make skills-add` quarantines a candidate first: portable frontmatter and
agent-trust scans must pass before the skill enters `.agents/skills/`. Bundled
skills have no immutable upstream path, so `make skills-update` deliberately
refuses them rather than pretending it knows where to fetch a replacement.
Review and import a bundled source explicitly, then update its content hash.

## Read this before importing anything

**Licence is the live hazard, not quality.** The strongest capability libraries
in this ecosystem carry real licensing problems, and the vendor libraries with
impeccable licensing contain almost nothing generic. Specifically:

- **Trail of Bits' skills are CC BY-SA 4.0** — copyleft, and not a software
  licence at all. Their `property-based-testing` and `sharp-edges` are the best
  in their categories, and vendoring-then-modifying them plausibly attaches
  ShareAlike to your derivative. `make check` refuses them by default.
- **`vercel-labs/agent-skills` has no LICENSE file** at the repo root. Four of
  its nine skills declare `license: MIT` in frontmatter; five declare nothing.
  Only the four are safely vendorable.
- **Anthropic's `docx` / `pdf` / `pptx` / `xlsx` are source-available, not open
  source.** Their README says so. Do not redistribute them.

The gate records and checks this so the decision is explicit. Widening
`skills.allowed_licenses` should be a decision you can point at.

**Pin to a commit, not a branch.** The popular `npx skills` CLI writes a
`skills-lock.json` too, but its hash is a change *detector* — `skills update`
re-clones the default branch and rewrites it, and its ref handling takes
branches and tags, not commit SHAs. `make skills-add` records the commit SHA and
a content hash of what it actually wrote, so two checkouts of your tree get
byte-identical skills.

**A vendored skill is instructions your agents follow.** An upstream edit
changes agent behaviour in your repo. Read the diff on every update with the
same attention you would give a dependency that ships executable code — because
functionally, this one does. The trust gate also rejects install/privilege
instructions, prompt-override shapes, coercive activation language, and runtime
downloads unless one exact reviewed line is allowlisted with a reason.

## The shortlist

Verified 2026-08-22: contents, licence, and size checked at the repo, not from
an index. Community indexes were wrong about at least one skill's existence.

### Closes a gap this harness has

| Skill | Source | Licence | Size | Why |
|---|---|---|---|---|
| `supabase-postgres-best-practices` | `supabase/agent-skills` | MIT | 160K | **The database gap, closed.** 33 atomic Postgres rules — schema design, index selection, RLS, locking, pooling, EXPLAIN — each with wrong-SQL/right-SQL. Generic Postgres despite the name; its own description says "Postgres running anywhere". Best single capability skill in the ecosystem. |
| `accessibility` | `addyosmani/web-quality-skills` | MIT | 44K | **The a11y gap, closed.** WCAG 2.2 plus concrete HTML wrong/right patterns, framework-neutral. The only credible public option — see the warning below about the alternative. |
| `webapp-testing` | `anthropics/skills` | Apache-2.0 | 44K | E2E with Playwright against a local app. Clean licence, small, no runtime deps. Covers the integration layer. |

### Worth it for the right stack

| Skill | Source | Licence | Size | When |
|---|---|---|---|---|
| `vercel-react-best-practices` | `vercel-labs/agent-skills` | MIT | 424K | React/Next. 40+ atomic perf rules. Largest item here but the densest frontend knowledge available. |
| `vercel-composition-patterns` | `vercel-labs/agent-skills` | MIT | 88K | React architecture: compound components, render props, React 19 changes. |
| `django-access-review` | `getsentry/skills` | Apache-2.0 | 36K | Django. IDOR and broken-access-control review for views, DRF viewsets, tenant isolation. |
| `django-perf-review` | `getsentry/skills` | Apache-2.0 | 20K | Django. N+1 and queryset performance. |
| all 13 `dart-*` | `dart-lang/skills` | BSD-3-Clause | 180K | Dart. The cleanest library in the ecosystem — every skill one ~120-line file, no scripts, no network. |
| 10 `flutter-*` | `flutter/skills` | BSD-3-Clause | 130K | Flutter. Widget tests, integration tests, layered architecture, responsive layout. Read-only upstream. |
| `angular-developer` | `angular/skills` | MIT (frontmatter) | 252K | Angular. ~30 reference files including testing fundamentals and ARIA. |
| `mcp-builder` | `anthropics/skills` | Apache-2.0 | 156K | Only if you author MCP servers. |

### Written here, because nothing suitable existed

| Skill | Licence | Size | Why |
|---|---|---|---|
| `writing-tests` | MIT | 48K | **The unit-testing gap, closed.** Language-agnostic: what is worth testing, the shape of a good test, the mocking decision, determinism, reading a failure, and adding tests to code that has none. Ships in `.agents/skills/`; also published standalone so other projects can vendor it without the CC BY-SA problem. |

### Good, but licence-blocked by default

| Skill | Source | Licence | Why you might still want it |
|---|---|---|---|
| `property-based-testing` | `trailofbits/skills` | **CC-BY-SA-4.0** | The strongest testing skill anywhere. Six languages, and uniquely teaches how to *review* a property test and read a shrunk counterexample. |
| `sharp-edges` | `trailofbits/skills` | **CC-BY-SA-4.0** | Per-language footguns plus crypto/auth/config API critique. Would directly upgrade `api-design`. |
| `modern-python` | `trailofbits/skills` | **CC-BY-SA-4.0** | uv, ruff, ty, pytest, PEP 723. The only credible Python capability skill that exists. |

Get a decision on CC BY-SA before importing these. If your harness output is a
client deliverable, that decision is not yours alone to make.

## Do not import

- **`web-design-guidelines`** (`vercel-labs`) — an 8K stub with **no local
  content**. Its body instructs the agent to WebFetch its rulebook from a
  different repo at activation time. No licence, nothing to pin, silent
  breakage offline. It has an attractive description and 27k-star provenance
  and it is empty. If you want those guidelines, vendor
  `vercel-labs/web-interface-guidelines/command.md` directly.
- **Whole cloud vendor libraries** — `google/skills` (169 skills, 8.1M),
  `aws/agent-toolkit-for-aws` (152, 19M), `datadog-labs` (41, 1.5M). Product
  documentation in skill clothing, with no generic residue.
- **`addyosmani/agent-skills`** — a well-made library that duplicates this
  harness's own 15 workflow skills almost one for one. Importing it would mean
  importing your own harness.
- **Community mega-indexes as a source.** Use `VoltAgent/awesome-agent-skills`
  or `officialskills.sh` for *discovery*, then verify at the repo. The best
  index is sponsored and was wrong about at least one skill's existence;
  install counts on skills.sh are telemetry volume, not a quality signal.

## Where the ecosystem actually stands

The genuinely good capability skills are concentrated in four repos — Supabase
for Postgres, Trail of Bits for security and testing, Vercel for React, Addy
Osmani for web quality — and three of the four have a licence problem. That
asymmetry is worth knowing before you plan around imports.

One hole is now filled — `writing-tests` above exists because the best public
option is CC BY-SA and therefore unusable for anyone vendoring into a commercial
or permissively-licensed project. It is MIT and self-contained for exactly that
reason.

The remaining hole: **anything first-party for Go, Rust, Python, Django or
Rails.** Trail of Bits' `modern-python` is the only credible Python option and
carries the same licence problem. That is the next thing worth writing.
