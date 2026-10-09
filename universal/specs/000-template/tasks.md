# Tasks: <feature name>

Spec: `./spec.md` · Plan: `./plan.md`

`[P]` = independent of the other `[P]` tasks; safe to run in parallel agents or
worktrees. Everything else is sequential.

A task that cannot state how it will be verified is not a task yet.

- [ ] T1 — <outcome>
      files: `<paths>`
      verify: `<command or observation>`
- [ ] T2 [P] — <outcome>
      files: `<paths>`
      verify: `<command or observation>`
- [ ] T3 [P] — <outcome>
      files: `<paths>`
      verify: `<command or observation>`
- [ ] T4 — depends on T2, T3 — <outcome>
      files: `<paths>`
      verify: `<command or observation>`

## Done when

- [ ] Every acceptance criterion in `spec.md` has a passing test
- [ ] `make check` passes
- [ ] `make verify` passes (or N/A, stated why)
- [ ] Independent review passed — reviewer ≠ producer
