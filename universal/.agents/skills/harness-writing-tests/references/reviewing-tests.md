# Reviewing tests

Test code gets reviewed less carefully than production code, which is backwards:
a bad test is worse than no test, because it reports safety that does not exist.

Review tests with the same attention as the code they cover — and apply this to
your own tests from a month ago, where you no longer remember what you meant.

## The three questions

Ask these in order. Most review comments are downstream of one of them.

### 1. Could this test fail?

Read the assertion and construct the input that would break it. If you cannot,
the test proves nothing. Watch for:

- An assertion inside a callback, loop, or `.then()` that may never execute
- A missing `await`, so the test finishes before the check runs
- A collection that is empty, making `every(...)` vacuously true
- A mock configured so the asserted call cannot happen
- `expect(x).toBeDefined()` on something that is always defined

The fastest check is to ask the author: *"Did you see it fail?"* If the answer
is no, that is the review comment.

### 2. Would a pure refactor break it?

Mentally rename a private method, extract a helper, reorder two independent
calls. If the test goes red, it is asserting the implementation and will be a
tax on every future change — including the change that would have fixed a real
bug, which is now expensive enough to defer.

The signal is assertions about *calls* rather than *outcomes*.

### 3. Does the failure message tell me what is wrong?

Imagine it red in CI at 5pm on a Friday, with no context. Does the test name say
what behaviour broke? Does the assertion print the expected and actual values?
If diagnosing it requires opening the file, the test costs more than it should.

## Smells, and what each usually means

| Smell | Usually means |
|---|---|
| Test is longer than the code it tests | The unit under test does too much |
| More than three mocks | Too many collaborators; a design signal |
| A comment explaining what the test does | The name should have |
| `sleep()` anywhere | A race condition, not yet understood |
| A shared fixture nobody dares change | Coupling; nobody knows what depends on what |
| Conditional logic in the test | Two tests wearing one coat |
| `.skip` or `.only` committed | `.only` silently disables the rest of the file — always a blocker |
| Assertions on log strings | Pinning prose that will change |
| A snapshot larger than a screen | Nobody reads it; it will be updated reflexively |
| Only happy paths | The error branches are untested, and that is where bugs live |

## What is missing

The hardest part of reviewing tests is noticing the case nobody wrote. Walk the
diff's branches and ask which are covered:

- Every `if` has both sides tested?
- Every `catch` is reached by a test?
- Every early return?
- Empty, one, many?
- What happens when the dependency fails — not returns an error, *throws*?

A concrete technique: change one operator in the source (`<` to `<=`, `&&` to
`||`, delete a `!`) and re-run. If nothing goes red, that branch is unguarded.
This is mutation testing done by hand, and it takes a minute.

## When a test changed in this PR

A modified test deserves more scrutiny than a new one, because it can quietly
delete coverage. For each change, ask:

- Did the **requirement** change, or did the test get bent to fit the code?
- Did an assertion get **weaker** — exact equality to `toBeTruthy`, a specific
  error to a bare `toThrow`, a count removed?
- Was a case **deleted**? If so, why is it no longer worth checking?

A requirement change is fine and should be stated in the PR description. A test
weakened to go green is the thing this review exists to catch.

## Verdict

Blocking:

- A test that cannot fail
- `.only` committed
- A weakened assertion or deleted case with no stated reason
- A new error path with no test
- A skipped test with no linked issue

Advisory: naming, structure, duplication, over-mocking that is not yet causing
harm. Say so, and let it merge.
