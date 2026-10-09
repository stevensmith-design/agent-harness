# Architecture

Long-form structure and rationale. Rules that agents must follow live in
`.agents/rules/`; **decisions** live in `docs/decisions/` as ADRs. This folder is
for the explanatory middle — how the pieces fit, written once so nobody
re-derives it.

Suggested starting set:

- `01-folder-structure.md` — where each kind of code lives, and the naming
  consistency rule that ties route → screen → state → test together.
- `02-state-and-data.md` — how state flows, where side effects are allowed.
- `03-routing.md` — navigation and deep links.
- `04-design-system.md` — the token layer and the component tiers.

Each one states the convention, one example that follows it, and one that does
not. The counter-example is the part agents learn from.
