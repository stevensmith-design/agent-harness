# Determinism

A test that fails one run in fifty is not "mostly working". It is a failing test
plus a habit of re-running CI — and once that habit exists, real failures get
re-run too.

## Time

Never call the clock inside code under test. Inject it.

```go
type Clock interface{ Now() time.Time }
type FixedClock struct{ T time.Time }
func (c FixedClock) Now() time.Time { return c.T }

svc := NewService(repo, FixedClock{T: time.Date(2026, 8, 22, 9, 0, 0, 0, time.UTC)})
```

Now you can assert exact timestamps, test "expires after 30 days" without
waiting, and cross a DST boundary or a leap day on purpose.

**Never `sleep()` in a test.** It is either too short (flaky) or too long (slow),
and usually both on different machines. If you are waiting for something, wait
for the *condition*:

```js
await waitFor(() => expect(queue.processed).toBe(1), { timeout: 2000 });
```

**Test the boundaries deliberately.** Midnight, month end, 29 February, the DST
transition in the relevant zone, and the moment an expiry lands exactly on
`now`. Those are where date bugs live, and a frozen clock is what makes them
testable at all.

## Randomness

Inject the generator, or seed it and record the seed in the failure message so a
flake is reproducible:

```python
def test_shuffle_preserves_membership():
    rng = random.Random(20260822)      # fixed seed, in the test
    result = shuffle_deck(deck, rng)
    assert sorted(result) == sorted(deck)
```

For anything generating IDs, tokens, or ordering, the code must accept the source
rather than reaching for a global.

## Ordering and shared state

Tests must pass in any order, and in parallel. Two rules get you there:

- **Each test creates what it needs.** No relying on a fixture another test set up.
- **Each test leaves nothing behind.** Unique names per test (`user-${uuid}`),
  transactional rollback, or a fresh temp directory.

If your suite fails when shuffled, that is a real bug in the suite. Most runners
can shuffle — turn it on in CI so the failure surfaces on your terms.

## Concurrency

Do not assert on how long something takes. Assert on what is true when it
finishes. For code that is genuinely concurrent, prefer testing the
deterministic parts separately, and use a barrier or a completion signal rather
than a delay.

Race conditions rarely reproduce under a debugger. If you suspect one, run the
test a few hundred times in a loop with the race detector on — many languages
have one (`-race`, ThreadSanitizer, `pytest-randomly`).

## Filesystem and network

- Filesystem: a fresh temp directory per test, removed afterwards. Never a path
  under the repo, never a fixed `/tmp/test-output`.
- Network: no real calls in a unit test, ever. In integration tests, hit a local
  container you control, not a shared staging environment — someone else's
  deploy should never turn your suite red.
- Ports: bind to port 0 and read back what you got, rather than hardcoding 8080
  and colliding with a parallel worker.

## Locale and environment

Number formatting, string sorting, upper-casing, and date parsing are all
locale-sensitive. Pin the locale and the timezone in test setup, or you get a
suite that passes for you and fails for a colleague in another region — and the
Turkish dotless-i will eventually break your case-insensitive comparison.
