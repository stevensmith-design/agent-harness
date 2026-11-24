# Community file templates

Starting points for the community health files GitHub looks for in a public
repository. **Nothing here is active.** Installing the harness copies this folder
to `.harness/templates/community/`, where GitHub ignores it; a project gets these
files only when its owner asks for them.

- Read by `scripts/community-files.sh scaffold` (run through the
  `harness-community-files` skill), which copies a template only where the
  project has no file of that kind, fills in the values the owner gave, and
  leaves every other `{{PLACEHOLDER}}` as it is.
- Checked by `scripts/gates/community-files.sh`, only when
  `project.visibility: public`.

Placeholders, each supplied by the owner and never guessed:

| Placeholder | Used in | What goes there |
|---|---|---|
| `{{PROJECT_NAME}}` | CODE_OF_CONDUCT, CONTRIBUTING, SECURITY | The name people know the project by |
| `{{CONDUCT_CONTACT}}` | CODE_OF_CONDUCT | A private way to report conduct problems: an email address or a form URL |
| `{{SECURITY_CONTACT}}` | SECURITY | How to report a vulnerability privately |
| `{{REPOSITORY_URL}}` | issue template config | e.g. `https://github.com/<owner>/<repo>` |

There is deliberately no LICENSE and no README template. The licence is the
owner's decision, and its text should come from the licence itself, not from a
harness. A README describes the project, which only its owner can write.
