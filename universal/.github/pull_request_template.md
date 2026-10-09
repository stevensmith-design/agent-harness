## What and why

<!-- One paragraph. Link the spec: specs/REQ-NNN-<slug>/spec.md -->

## Changes

<!-- Bullet the substantive changes. Not a file list — a change list. -->

## How this was verified

<!-- REQUIRED. Commands you actually ran and what they printed.
     "make check" alone is not enough for user-visible change — add "make verify",
     a screenshot, or a recording. CI fails if this section is empty. -->

- [ ] `make check` passes
- [ ] `make verify` passes (or N/A — say why)
- [ ] New behaviour has a test that fails without the change

## Not verified

<!-- REQUIRED. What this change could break that no check above could see.
     Start from the human lane in docs/quality/README.md: how it feels, visual
     detail, input methods (IME), environments CI does not run, sequences of
     actions, states no fixture renders. Tell the person who explores it where
     to look. "Nothing: <why>" is an answer; an empty section fails CI. -->

## Blast radius

<!-- What else could this break? Which surfaces from harness.config.yaml does it touch? -->

## Review focus

<!-- Where should the reviewer actually look? -->

## Harness changes

<!-- If this PR touches AGENTS.md, .agents/, workflows, or ADRs, say why here and
     add the line: harness-change: intentional -->

## Related

<!-- Issue / ticket / ADR -->
