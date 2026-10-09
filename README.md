# Harness Lab

<p align="center"><img src="assets/harness.jpg" alt="A climber on a rope and harness, while small workers build the wall beside them" width="720"></p>

Two agent harnesses, free to use.

A harness is everything around the model: the context, rules, procedures,
contracts, gates, evidence and feedback loops that make AI work inside one
particular team's way of working. The model is one input, and increasingly a
commodity. The harness is the part that is yours.

## Which one do you want?

**Building websites, apps or prototypes with AI agents? Use the universal
harness.** It drops into your code repository, ready to go, and keeps agents
working to a standard: specs before code, checks that must pass before work
counts as done, protected files they cannot quietly change, and reviews that
catch what looks right but is not. Works with Claude Code, Cursor and Copilot,
on any stack.

**Want a solid AI working environment for yourself or your team, whatever the
work? Start with the harness kit.** Instead of handing you a fixed setup, it
builds one around how you already work — design, marketing, business
development, project work, code, or something it has not seen before. Describe your work, or point it at the docs, prompts,
Slack or Notion you already have, and it designs a harness that fits that.

Not sure? If the work lives in a code repository, start with the universal
harness. For everything else, start with the kit.

| | **Universal harness** — [`universal/`](universal/) | **Harness starter kit** — [`kit/`](kit/) |
|---|---|---|
| **What it is** | A complete, ready-to-install harness for software projects, on any stack | A *constructor* that designs and builds a harness around your own team or workspace |
| **Use it when** | You are building software and want a working harness in your repo today | Your work is not (only) software — design, marketing, business development — or you want a harness shaped around how your team already works |
| **You end up with** | Rules, skills, gates, hooks and CI in your repository, checked by `make check` | A harness designed from a conversation or from the material you already have (docs, prompts, Slack, Notion, a repo) |
| **Start here** | [`universal/README.md`](universal/README.md) | [`kit/README.md`](kit/README.md) |

The two are kept apart on purpose. The kit is not a harness; it is the thing that
builds them, so the assumptions of one project do not travel into the next. The
kit's dev pack uses the universal harness as its reference implementation.

## Get them

**You need:** `bash`, `git` and `make` (macOS or Linux; on Windows, use WSL).
The one-command download below also needs [Node.js](https://nodejs.org).

Every grey box below is one step — use its copy button, paste it into your
terminal, and run it.

### Option 1 — get both

```bash
git clone https://github.com/stevensmith-design/agent-harness.git
```

This makes an `agent-harness` folder containing `universal/` and `kit/`.

Want your own GitHub copy to customise? Fork it instead:

```bash
gh repo fork stevensmith-design/agent-harness --clone
```

### Option 2 — get just the universal harness

```bash
npx degit stevensmith-design/agent-harness/universal universal-harness
```

This makes a `universal-harness` folder. No Node.js? Use git instead:

```bash
git clone --filter=blob:none --sparse https://github.com/stevensmith-design/agent-harness.git universal-harness-repo && git -C universal-harness-repo sparse-checkout set universal
```

That puts it in `universal-harness-repo/universal`.

### Option 3 — get just the harness kit

```bash
npx degit stevensmith-design/agent-harness/kit harness-kit
```

This makes a `harness-kit` folder. No Node.js? Use git instead:

```bash
git clone --filter=blob:none --sparse https://github.com/stevensmith-design/agent-harness.git harness-kit-repo && git -C harness-kit-repo sparse-checkout set kit
```

That puts it in `harness-kit-repo/kit`.

## Install the universal harness into your project

**1. Tell your terminal where your project is.** Replace the path with your
own project folder, then run it:

```bash
PROJECT=~/path/to/your-project
```

**2. From inside the universal harness folder** (`universal-harness`, or
`agent-harness/universal` if you cloned both), copy the harness in:

```bash
./scripts/install.sh "$PROJECT"
```

It refuses to overwrite your files and tells you what clashed, so nothing is
lost. Use this script, not `cp -R` — a plain copy drops the hidden folders that
make up most of the harness.

**3. Set it up in your project** — run in the same terminal:

```bash
cd "$PROJECT"
git switch -c chore/install-harness
make setup
make harness-init
```

`make setup` prepares hooks and skill links but installs no packages.
`make harness-init` walks you through `harness.config.yaml`. The harness's
checks refuse to run on your main branch, which is why it starts a new one.

**4. Check it works:**

```bash
make check
```

This must pass before you trust anything else. When your project needs
packages installed, run `make deps` — but only after the
`/harness-dependency-intake` skill has approved them. The full checklist is in
[`universal/HARNESS-MANIFEST.md`](universal/HARNESS-MANIFEST.md).

## Build a harness with the kit

**1. Tell your terminal where the harness should go** — your team's folder,
workspace or repository. Replace the path, then run it:

```bash
TARGET=~/path/to/your-work
```

**2. From inside the kit folder** (`harness-kit`, or `agent-harness/kit` if you
cloned both), see what kind of job this is. This only reads; it changes
nothing:

```bash
./detect.sh "$TARGET"
```

**3. Copy in the starting template.** It shows you the list of files and asks
before writing anything, and never overwrites:

```bash
./install.sh "$TARGET"
```

**4. Open that folder in your AI agent** (Claude Code, Cursor and similar) and
say:

> help me create a harness for …

From there the kit's `harness-scope` skill designs it with you and
`harness-build` builds it. Already have a harness? Say *"review my existing harness"* and
`harness-audit` reviews it. More in [`kit/README.md`](kit/README.md) and
[`kit/INSTALL.md`](kit/INSTALL.md).

## Also here

[`eval/routing/`](eval/routing/) — an eval of the kit itself: given the sentence a
person actually opens with, does the right kit skill claim it? Kept outside
`kit/` so it never ships into your project.

## Notes

- `.claude/skills/` and `.claude/rules/` are **generated symlinks** created by
  `make setup` from the real sources in `.agents/`. They are not committed:
  archive extraction turns symlinks into text files containing their target.
- Built `.skill` artifacts are build outputs, not source. Rebuild them with
  `make harness-package` in `universal/`.
- Found a problem or have a lesson worth sharing back? Open an issue. Both
  harnesses include an upstream-feedback procedure that drafts a sanitised
  proposal for you to post.

## Licence

MIT — see [`LICENSE`](LICENSE). It covers everything in this repository,
including `kit/` and `universal/`.

`universal/` deliberately has no `LICENSE` file of its own. Its installer copies
the whole folder into your project, so a licence file there would either collide
with your project's own licence and stop the install, or quietly label your
project MIT.
