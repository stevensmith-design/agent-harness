# Skills

Two kinds live here, and the difference matters:

- **Workflow skills** — how *this team* performs a repeatable task. Authored
  here, versioned with the repo. Everything currently in this folder.
- **Capability skills** — reusable framework or language know-how imported from
  elsewhere and pinned by hash in `skills-lock.json`. Do not hand-edit an
  imported skill; update the pin.

Portable [Agent Skills](https://agentskills.io/specification) format, so the same
tree serves Claude Code, Codex, Cursor, Gemini CLI and OpenHands.
`make link-skills` symlinks it into `.claude/skills/`; edit the copy here.

## Writing one

```
skill-name/
├── SKILL.md      # required — six-field frontmatter, under 200 lines
├── scripts/      # optional — executable helpers
├── references/   # optional — long docs, loaded only when needed
└── assets/       # optional — templates
```

Only these frontmatter keys are portable. Anything else breaks on upload to
non-Claude clients — put tool-specific behaviour in an overlay, not here:

`name` · `description` · `license` · `compatibility` · `metadata` · `allowed-tools`

`name` must equal the directory name. `description` must say **what** and
**when** — it is the only part loaded until the skill fires, so it is the
trigger. It is also loaded in every session whether the skill fires or not, so
it earns its length; `make retro-evidence` shows the total.

Put the steps that must not be skipped near the top. When a long session is
compacted, an invoked skill's body comes back only up to a cap (about 5,000
tokens in Claude Code), cut from the end. Long reference material belongs in
`references/`, read when needed.

## Boundary discipline

Every skill opens with a **when to use / when not to use** table. A skill with no
stated non-goal expands until it collides with its neighbours — the
`review` / `harness-retro` pair is the example to copy. Also state what the skill
owns, consumes, produces, may mutate, and hands off to.
