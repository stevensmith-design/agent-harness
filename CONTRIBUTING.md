# Contributing

Thanks for looking. Agent Harness is a one-person project, so small, focused changes are easiest to review.

The repository has two parts, and each has its own checks. Anything under `kit/` or `universal/` is copied into other people's projects by the installers, so nothing specific to this repository belongs there.

## Changing the harness kit (`kit/`)

Read [`kit/CONTRIBUTING.md`](kit/CONTRIBUTING.md). It covers skill frontmatter, the line budget, what `check-kit.sh` enforces, and which self-tests to run when.

## Changing the universal harness (`universal/`)

Work on a branch, not `main`. Then, from `universal/`:

```
make check            # product checks
make harness-check    # harness gates; fails on main by design
make gate-selftest    # proves every gate still rejects what it exists to reject
```

Add a case to `scripts/gate-selftest.sh` with every gate change: one input it must flag and one it must not. Add an entry to `universal/CHANGELOG.md` under *Unreleased* if installed repos would notice, and say what they need to copy.

## Sharing a lesson back

Both harnesses include an upstream-feedback procedure: `upstream-feedback` in the kit and `harness-upstream-feedback` in the universal harness. It turns a lesson from your own retro into a short, sanitised proposal. Post it with the **Harness lesson** issue form. Use synthetic examples only, never client or personal data.

## Pull requests

Fill in the template. Paste the real output of the checks you ran, and list what you couldn't check under **Not verified**.
