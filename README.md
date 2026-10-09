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

**Requirements:** `bash`, `git` and `make`. Works on macOS and Linux (on Windows,
use WSL). The copy-one-folder option below also needs Node.js for `npx`.

### Both — clone the repository

```bash
git clone https://github.com/stevensmith-design/agent-harness.git
cd agent-harness
```

Or fork it first if you want your own GitHub copy to customise:

```bash
gh repo fork stevensmith-design/agent-harness --clone
```

### Just one — copy a single folder

Each folder is self-contained and installs from a plain copy; it does not need
this repository's git history.

```bash
npx degit stevensmith-design/agent-harness/universal universal-harness   # the universal harness
npx degit stevensmith-design/agent-harness/kit harness-kit                # the starter kit
```

No Node? A sparse clone gets one folder with git alone:

```bash
git clone --filter=blob:none --sparse https://github.com/stevensmith-design/agent-harness.git
cd agent-harness
git sparse-checkout set universal   # or: kit
```

In the install steps below, `universal/` and `kit/` mean wherever that folder
ended up — for example `universal-harness/` if you used `degit`.

## Install the universal harness into a project

```bash
cd universal
./scripts/install.sh <your-repo>     # refuses to overwrite your files; carries no .git
cd <your-repo>
git switch -c chore/install-harness  # gates refuse to run on the default branch
make setup                           # env, hooks and skill symlinks; installs no packages
make harness-init                    # fill in harness.config.yaml
make deps                            # only after /harness-dependency-intake approval
make check                           # must go green before you trust anything
```

Use the installer, not `cp -R`. A plain copy either nests the tree or drops
every dotfile, and it overwrites your `Makefile`, `README.md` and `CLAUDE.md`
without asking. `universal/HARNESS-MANIFEST.md` has the full checklist.

## Build a harness with the starter kit

```bash
cd kit
./detect.sh <target>...  # read-only: works out what kind of job this is
./install.sh <target>    # copies the core template; never overwrites, asks first
```

`detect.sh` resolves to one of four motions — `harness`, `overlay`, `scattered`,
`greenfield` — and fails closed, so ambiguous evidence routes to the motion that
writes least. Then open the target in your agent and say **"help me create a
harness for …"**. The entry skill is `harness-scope` (design one), followed by
`harness-build` (build it), or `harness-audit` (review one that already exists).
See [`kit/README.md`](kit/README.md) and [`kit/INSTALL.md`](kit/INSTALL.md).

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
