# Project memory — index

Durable facts a fresh agent could not derive from the code. **Index only**: one
line per topic file, under 200 lines / 25 KB total. Long notes go in their own
file next to this one.

Do not record: anything re-derivable from the repo, anything already in
`AGENTS.md` or an ADR, or transient task state.

**Each entry in a topic file says when it was learned, where from, and when it was
last confirmed** — `(learned 2026-03-02, PR #412; confirmed 2026-05-14)`.
**Verify before acting:** memory describes the past, so check the file, setting or
service an entry names before relying on it. An ADR or `AGENTS.md` wins any
disagreement. `/harness-retro` prunes what stopped being true.

**Here, or in the AI tool's own memory?** Tool memory is per person and per
machine: fine for how someone likes to work, wrong for anything the team needs,
because nobody else can read or review it. A team lesson found there moves here.

- [Glossary](glossary.md) — domain terms this codebase uses in a non-obvious way.
- [Environments](environments.md) — what dev / staging / prod actually point at, and who owns them.

<!-- Add lines here as topics appear. Written by the /harness-retro skill. -->
