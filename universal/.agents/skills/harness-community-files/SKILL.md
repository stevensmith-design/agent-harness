---
name: harness-community-files
description: Add the community health files a public repository is missing — CODE_OF_CONDUCT, CONTRIBUTING, SECURITY, issue templates — from the harness's templates, asking the owner for every value. Use when make check-community reports gaps or the owner asks for them. Public repositories only.
license: MIT
metadata:
  harness.tier: product
allowed-tools: Read Glob Grep Bash(make check-community) Bash(./scripts/gates/community-files.sh) Bash(./scripts/community-files.sh:*) Bash(git remote get-url:*)
---

# harness-community-files

GitHub looks for seven files in a public repository. Leaving them off is easy,
and an outside contributor meets the gap first. This skill fills in the ones
that are missing. It never overwrites one the project has, never invents a
value, and never makes the owner's decisions for them.

| Use it when | Do not use it when |
|---|---|
| `make check-community` lists missing or unfinished files | `project.visibility` is `private`. Then there is nothing to do; say so and stop |
| The owner asks for a code of conduct, security policy or issue templates | The owner wants to rewrite a file they already have. That is an ordinary edit, not a scaffold |
| A repository is about to be made public | You would have to guess a contact address or a licence |

**Owns:** creating missing `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`, `SECURITY.md`
and `.github/ISSUE_TEMPLATE/*`, only through `scripts/community-files.sh`.
**Consumes:** `.harness/templates/community/`, `project.visibility`.
**Never:** overwrites or merges an existing file, writes a placeholder value
nobody gave, picks a licence, writes a README, or changes repository settings.

## 1 · See what is there

Run `make check-community`. If it prints nothing, the repository is private (or
`project.community_files: off`). Tell the owner and stop. Otherwise it checks 7
files and lists each as present, missing, or still holding `{{PLACEHOLDERS}}`.

Report that list to the owner as it is. A file the project already has is
**present**, even if it is short or you would write it differently. It is
theirs. Do not offer to replace or merge it.

The check sees only this repository. GitHub can also apply **default community
files** from the public `.github` repository of the account or organisation that
owns it. A project that relies on those defaults will see "missing" here. That
is expected, not a fault. If the owner wants to keep using the defaults, setting
`project.community_files: off` is their choice to make.

## 2 · Explain what each missing one is for

Only for the ones that are missing, in a sentence each. Many owners haven't met
them:

| File | What it is for |
|---|---|
| README | What the project is and how to start. The first thing anyone reads |
| LICENSE | Permission to use the code. **With no licence, nobody may legally reuse it**, even though they can see it |
| CODE_OF_CONDUCT | How people are expected to behave, and a private way to report someone who doesn't |
| CONTRIBUTING | How to propose a change, and which checks to run first |
| SECURITY | How to report a vulnerability privately, instead of in a public issue |
| Issue templates | Forms that ask reporters for what you need: version, steps, expected vs actual |
| PR template | What every pull request must say. The harness already ships one at `.github/pull_request_template.md` |

## 3 · The two decisions that are the owner's alone

- **LICENSE.** There is no template and no default. Ask which licence they want.
  `skills.allowed_licenses` in `harness.config.yaml` lists the licences this
  harness already accepts (MIT, Apache-2.0, BSD-3-Clause, BSD-2-Clause, ISC),
  which makes a reasonable menu, but the choice is theirs and "not yet" is an
  answer. Point them to GitHub's **Add file → Create new file → `LICENSE` →
  Choose a license template**, which fills in the full text, year and holder.
  Do not write licence text yourself.
- **README.** Only the owner can describe the project. If the check says the
  README is still the harness's own, tell them. Don't draft one unasked.

## 4 · Ask for every value, then scaffold

The templates need these values. Ask for each one the missing files use, and
only those:

- `PROJECT_NAME`: the name people know it by.
- `CONDUCT_CONTACT`: a **private** way to reach the maintainers, such as an
  email alias or a form URL. A GitHub profile with no email is not one.
- `SECURITY_CONTACT`: how to report a vulnerability privately. For example,
  "use GitHub's private vulnerability reporting (Security → Report a
  vulnerability)", or an email address.
- `REPOSITORY_URL`: `https://github.com/<owner>/<repo>`. You may suggest the
  value from `git remote get-url origin`, but the owner confirms it.

**Never fill one in yourself**, not from the git author, a profile, or another
file. If the owner doesn't give a value, leave it out. **A file is written only
when every value it needs was given.** Without `CONDUCT_CONTACT`, no code of
conduct is written, because one with no way to report would look finished. The
script reports `not written: needs CONDUCT_CONTACT` instead. The issue templates
need `REPOSITORY_URL` and are written or skipped together, so the set never ends
up with a broken `config.yml`.

Show the plan (the dry run lists what would be written and what would be skipped, and for which value), then write:

```bash
./scripts/community-files.sh scaffold --dry-run --set "PROJECT_NAME=…" --set "CONDUCT_CONTACT=…"
./scripts/community-files.sh scaffold           --set "PROJECT_NAME=…" --set "CONDUCT_CONTACT=…"
```

Call the script directly rather than `make community-files`, so values with
spaces stay one argument. The script skips every kind of file already present.
It refuses, writing nothing, if a destination path exists. It refuses on a
private repository. If it stops, report what it said. Do not work around it.

## 5 · Hand back

- Run `make check-community` again and show its output.
- List each file reported `not written: needs …` and the value it is waiting
  for. Re-run the scaffold with that `--set` once the owner has it.
- **If SECURITY.md points to private vulnerability reporting, tell the owner to
  turn it on themselves:** Settings → Code security → Private vulnerability
  reporting. It is a repository setting. This skill does not change settings,
  and the "Report a vulnerability" button doesn't exist until it is on.
- The new files are ordinary product files. Commit them on a branch and open a
  PR like any other change.

## Strictness

`project.community_files` decides what the check does on a public repository:
`warn` (default) reports and passes; `error` fails `make harness-check` until
every file is present and filled in; `off` silences it. Changing it is the
owner's call. Don't switch it to `error` to make a report go away.
