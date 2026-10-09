---
name: harness-writing-tests
description: Write tests that actually catch defects — decide what is worth testing, make a test fail before it passes, choose the right level and the right test double, and keep it deterministic. Use when writing or reviewing tests in any language, when a test suite is slow, flaky, or passes while bugs ship, or when adding tests to code that has none.
license: MIT
compatibility: Language-agnostic. Examples use pseudocode plus short snippets in JavaScript, Python, Dart and Go; the rules apply to any language and any test framework.
metadata:
  version: 1.0.0
  author: Universal Harness
  harness.tier: implementation
allowed-tools: Read Glob Grep Write Edit Bash(make test) Bash(make check)
---

# writing-tests

Most test suites are large and prove very little. They pass, they run in CI, and
bugs ship anyway. The cause is almost never "we didn't write enough tests" — it
is that the tests assert the wrong things, could never have failed, or are so
coupled to the implementation that they must be rewritten whenever the code
changes, which means they get rewritten to pass.

| Use it when | Do not use it when |
|---|---|
| Writing tests for new behaviour | Running an existing suite — that is `verify` |
| Adding tests to untested code | Debugging one failing test with an obvious cause |
| A suite is slow, flaky, or passes while bugs ship | You want end-to-end browser automation specifically |
| Reviewing someone else's tests | Deciding release readiness — tests are input, not the decision |

**Produces:** tests. **Not** a coverage report, and not a strategy document.

---

## The one rule everything else serves

> **A test you have never seen fail is not a test. It is a comment that costs
> CPU time.**

Before you trust any test, make it fail on purpose. Break the assertion, or
break the code it covers, and watch it go red for the reason you expect. Then
put it back.

This takes ten seconds and it catches the whole category of tests that pass
unconditionally: an assertion inside a callback that never runs, an `await` that
was forgotten so the test ends before the check, a mock that swallows the call
being asserted, a filter that leaves the collection empty so "every item is
valid" is vacuously true.

Writing the test *first* — before the code — gets this for free, which is the
strongest practical argument for doing it. But test-first is a means to this
end, not the end. Written-after is fine if you actually verify the failure.

---

## What is worth testing

Not everything. A test costs you forever: it must be read, maintained, and
believed. Spend that cost where a defect would hurt.

| Test it | Because |
|---|---|
| Branching logic, especially conditions with `&&`, `||`, negation | This is where off-by-one reasoning lives |
| Boundaries — empty, one, many, first, last, max, zero, negative | Almost every real bug is at an edge |
| Error and failure paths | Nobody exercises these by hand, so nobody notices they are broken |
| Anything you got wrong once | A regression test is the cheapest test to justify |
| Public contracts other code depends on | Changing them silently is the expensive mistake |
| Data transformation and parsing | Easy to get subtly wrong, easy to assert exactly |

| Don't test it | Because |
|---|---|
| The framework, the language, or the standard library | Their maintainers already did |
| Getters, setters, and pass-through delegation | A test that mirrors one line of code just duplicates it |
| Private helpers, directly | Test them through the public behaviour that uses them; otherwise you cannot refactor |
| Exact log strings, or that a mock was called | See "asserting the implementation" below |
| Generated code | Test the generator once, not its output |

If you cannot say what defect a test would catch, do not write it.

---

## The shape of a good test

**One reason to fail.** A test with fifteen assertions tells you about the first
broken one and hides the rest. Split by *scenario*, not by method.

**A name that states the behaviour**, so a red CI log is readable without
opening the file:

```
✗ rejects an invite that expired before it was opened
✗ returns an empty page rather than an error when the offset is past the end
```

not `test_invite_2` or `testHandler`. If you cannot name the behaviour, you have
not decided what you are testing.

**Arrange, act, assert — visibly separated.** Three blocks, in that order, with
the act being one line. When the act needs five lines of setup inline, that
setup belongs in arrange, and the fact that it's awkward is telling you the API
is awkward.

**Assert on the observable outcome, not the journey.** The return value, the
state afterwards, the message emitted, the error raised. Not which internal
methods were called on the way.

**No logic in the test.** No loops, conditionals, or arithmetic that recomputes
the expected value — a test that calculates its expectation the same way the
code does will agree with the code even when both are wrong. Write the expected
value literally. `expect(total).toBe(1247)`, not
`expect(total).toBe(items.reduce(sum))`.

---

## The mocking decision

Over-mocking is the most common way a suite becomes worthless. Two rules resolve
most cases:

> **Never mock the thing under test.** If you find yourself mocking a method on
> the object you are testing, you are testing your mock.

> **Mock what you don't own and can't control.** Network, clock, filesystem,
> randomness, third-party SDKs, payment providers. Not your own value objects,
> not your own pure functions, not your own data structures.

**Asserting the implementation** is the failure mode to watch for. This test
passes forever and catches nothing:

```js
// bad — asserts that code was written, not that it works
await service.archiveProject(id);
expect(repo.findById).toHaveBeenCalledWith(id);
expect(repo.save).toHaveBeenCalled();
```

Rewrite it to assert the outcome:

```js
// good — asserts what a caller would actually observe
await service.archiveProject(id);
const project = await repo.findById(id);
expect(project.status).toBe("archived");
expect(project.archivedAt).toEqual(FIXED_NOW);
```

The rule of thumb: **if a pure refactor breaks the test, the test was asserting
the implementation.** Renaming a private method, extracting a helper, or
reordering two independent calls should never turn a suite red.

Prefer a **fake** over a mock where one is cheap — an in-memory repository, a
stub clock, a local temp directory. Fakes let you assert real state instead of
recorded calls, and they do not go stale when the interface changes.
`references/test-doubles.md` has the full taxonomy and when each earns its place.

---

## Levels, and what each is for

| Level | Answers | Cost | Use it for |
|---|---|---|---|
| Unit | "Is this logic right?" | milliseconds | branching, boundaries, transformation, error paths |
| Integration | "Do these pieces agree?" | seconds | your code against a real database, real queries, real serialisation |
| End-to-end | "Does the product work?" | minutes, flaky | a handful of critical user journeys, nothing more |

The useful heuristic is not a ratio. It is: **push each test to the cheapest
level that could still catch the defect.** Most logic bugs are catchable at unit
level and belong there. Anything involving a real query, a real migration, or a
real serialisation boundary is not — a mocked database proves your mock agrees
with itself.

End-to-end tests are where suites go to die: slow, flaky, and expensive to
diagnose. Keep a small number covering journeys where failure is unacceptable,
and resist adding one for every feature.

---

## Determinism

A flaky test is worse than no test. It trains the team to re-run CI, and once
that habit exists, a real failure gets re-run too.

Five sources of nondeterminism, and the fix for each:

- **Time** — inject the clock. Never `now()` inside code under test, never
  `sleep()` in a test. Freeze it, and assert exact timestamps.
- **Randomness** — inject the generator or seed it. A test that passes 99 times
  in 100 is a failing test you have not noticed.
- **Ordering** — never depend on test execution order, and never share mutable
  state between tests. Each test creates what it needs and leaves nothing
  behind. If your suite fails when run in a different order, it has a real bug.
- **Concurrency** — do not assert on timing. Wait for a condition, with a
  timeout, not for a duration.
- **External state** — network, real clocks, the actual filesystem, a shared
  database. Isolate, or accept the flake.

`references/determinism.md` covers each with concrete patterns.

---

## Anti-patterns worth naming

Each of these looks like a test and is not:

- **The test that cannot fail.** Vacuous truth over an empty collection; an
  assertion after an early return; a forgotten `await`. Prove failure first.
- **Assertion-free test.** Calls the code, asserts nothing, passes unless
  something throws. Sometimes deliberate as a smoke test — say so in the name.
- **The mirror test.** Recomputes the expected value using the same logic as the
  code. Agrees with the code even when both are wrong.
- **The snapshot nobody reads.** A large approved blob, updated reflexively when
  it changes. Snapshot small, meaningful output or don't snapshot.
- **The quarantined flake.** Skipped "temporarily" months ago. Either fix it or
  delete it — a permanently skipped test is a lie about your coverage.
- **The coverage-driven test.** Written to move a percentage, asserting nothing
  meaningful. Coverage tells you what is *definitely untested*; it says nothing
  about what is tested well.
- **The setup monolith.** A 200-line fixture shared by every test, where nobody
  can tell which part any given test depends on. Build what each test needs.

---

## Reading a failure

When a test goes red, read the message before touching the code. A good failure
names the expected value, the actual value, and the case. If it doesn't, improve
the assertion before debugging — you will need that message again.

Then ask, in order: **Is the test wrong, or is the code wrong?** Genuinely ask
it. The reflex to "fix" the test is how a suite stops catching anything. If the
test encodes a requirement, the code is wrong. If the requirement changed, the
test change should be as deliberate as any other requirement change, and it
belongs in the PR description.

**Never** weaken an assertion, add a retry, or skip a test to get to green.
That is not a fix; it is deleting the evidence.

---

## Adding tests to code that has none

Do not start by writing unit tests — untested code is usually untestable code,
and you will spend a week refactoring before anything passes.

Start with a **characterization test**: pin the current behaviour, whatever it
is, including behaviour you suspect is wrong. Now you have a safety net. Then
refactor to create a seam, then write the real tests, then fix the bug you found
while pinning. `references/legacy-code.md` covers the seam techniques.

---

## Depth

- `references/test-doubles.md` — stub, fake, spy, mock: what each is for, and the failure each causes when misused
- `references/determinism.md` — time, randomness, ordering, concurrency, IO
- `references/what-to-assert.md` — assertion quality, error and exception testing, thinking in properties
- `references/legacy-code.md` — characterization tests and seams
- `references/reviewing-tests.md` — judging someone else's tests, including your own from last month
