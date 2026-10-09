---
status: accepted
date: 2026-08-27
decision-makers: [Steven Smith]
consulted: [external review (Codex)]
informed: []
---

# 0001. Namespace every shipped skill with `harness-`

## Context and problem statement

The harness ships 24 skills. Seven carry names that are ordinary English words
for things a software team already does: `review`, `release`, `branch`, `spec`,
`requirements`, `verify`, `pr`. A universal installer cannot assume any of them
is free in someone else's repository.

The collision is not hypothetical and it is not currently handled. Today
`scripts/install.sh` detects collisions only at the TOP level of the tree — it
lists `.agents` as one entry. A target repo that already has
`.agents/skills/harness-review/` therefore trips the guard on `.agents` as a whole, and
`--force` overwrites their skill with ours without naming it. The person who
installed the harness loses a skill they wrote and finds out later, from
behaviour, not from a message.

This is cheap to decide now and expensive after adoption: once repos have
installed the harness and written cross-references against these names, a rename
is a migration for every one of them.

## Decision drivers

- A convention nobody can check is prose. This harness's recurring defect — found
  five times — is machinery that points at something nothing produces. A naming
  rule with no gate is the same defect in a new place.
- The collision must be impossible, not detected-and-worked-around. Detection
  logic is code that can be wrong; a namespace cannot collide.
- "Which of these skills came from the harness?" should be answerable by looking
  at the list.
- Vendored skills are pinned by content hash. Whatever is chosen must not break
  those pins.

## Considered options

- **A. Prefix all 24 with `harness-`.** `harness-review`, `harness-release`, …
- **B. Prefix only the seven generic names.** Leave `threat-model`, `api-design`,
  `adr`, `ui-design-*` as they are.
- **C. Install-time collision check with an alias rename.** Keep short names; at
  install, detect an existing skill and install ours as `review-harness`,
  recording the mapping.

## Decision outcome

**Option A.**

The decisive argument is enforceability, not aesthetics. Option A can be checked
by one line — every directory under `.agents/skills/` begins with `harness-` —
so the convention has a gate and the gate can be watched failing. Option B's rule
is "prefix when the name is a generic word another team might plausibly have
used", which is a judgement call: no gate can express it, so it would drift the
first time somebody adds a skill and disagrees about which side of the line it
falls on. That is precisely the shape of defect this harness exists to hunt, and
choosing it here would be choosing it knowingly.

Option C is worse than either. Skills cross-reference each other by name, so
installing under a different name requires a rewrite pass over the whole
instruction graph at install time — `AGENTS.md`, 24 `SKILL.md` files, the
`.claude/commands`, the rules. Its failure mode is a reference pointing at a
skill that does not exist: silent, and discovered only when an agent needs the
skill and does not find it. It trades a collision you can see for a dangling
reference you cannot.

The cost accepted: 22 directory renames (`harness-init` and `harness-retro`
already conform), a `name:` frontmatter change in each `SKILL.md`, and updated
cross-references. Names get longer at the agent-facing surface.

### Consequences

- Good: collisions become structurally impossible; provenance is visible in any
  skill listing; the convention has a one-line gate
  (`scripts/gates/skill-namespace.sh`) and six self-test cases.
- Bad: longer names; a one-off migration for anyone who installed a pre-1.15
  harness.
- **Vendored skills are exempt, and this correction matters.** The original
  version of this ADR accepted Option A partly on the claim that renaming would
  not disturb the vendored content pins, because `scripts/skills.sh hash_dir`
  hashes paths RELATIVE to the skill directory. That reasoning was right about
  the directory and wrong about the file: prefixing a skill also rewrites the
  `name:` line inside its `SKILL.md`, which changes the content, which breaks
  the pin. All four pins broke on the first attempt, and `make check` caught it
  within a minute of the rename.

  Vendoring means holding a copy of someone else's artifact, pinned so that an
  in-place edit is visible. Editing four of them to satisfy our own naming rule
  is the tail wagging the dog: it forks the harness's copies from
  their upstream by one line each, and the next `skills update` would silently
  re-clobber the rename. So `ia-review` and the three `ui-design-*` skills keep
  their upstream names and byte-identical content.

  This does not weaken the reason Option A was chosen. The exemption is a
  LOOKUP — a directory is exempt if and only if `skills-lock.json` lists it —
  not the judgement call ("is this name generic enough?") that disqualified
  Option B. The gate reads the lockfile and the rule stays mechanical.

## What was actually done

Applied in v1.15.0:

- 17 harness-authored skills under `.agents/skills/` renamed to `harness-*`
  (`harness-init` and `harness-retro` already conformed), plus the three
  `overlays/ai-product` skills, for 22 namespaced in total.
- 4 vendored skills left untouched; `make skills-verify` still green, 4 pinned.
- References rewritten for exactly two forms — `.agents/skills/<name>` and
  `.claude/skills/<name>`, with a boundary so a name never matches inside a
  longer one. A textual sweep would have been destructive: `pr` alone appears in
  228 tracked files, nearly all of them inside `print`, `product`, `proposal`,
  `approve`.
- `scripts/gates/skill-namespace.sh` added to `make check` and to both generated
  CI pipelines. It checks three things: the prefix on authored skills, that each
  skill's declared `name:` matches its directory, and — the one that earns its
  keep — that **every `.agents/skills/<x>` path referenced anywhere resolves**.
  Option C was rejected because its failure mode was "a reference pointing at a
  skill that does not exist"; doing the rename by hand has the identical failure
  mode, so the gate that enforces the convention also proves nothing was left
  behind.
- Six self-test cases, each proving the gate FAILS on the violation.

Not done, and deliberately: `.claude/skills/` symlinks are regenerated by
`make link-skills` and are not tracked, so a fresh clone builds them correctly.
