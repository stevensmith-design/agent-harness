# Test doubles

Five kinds, often all called "mocks", which is why teams argue past each other.
The distinction matters because three of them assert on *state* and two assert
on *interaction*, and interaction assertions are the ones that rot.

| Kind | What it is | Assert on |
|---|---|---|
| **Dummy** | A value passed to satisfy a signature, never used | nothing |
| **Stub** | Returns canned answers | state afterwards |
| **Fake** | A real working implementation, simplified | state afterwards |
| **Spy** | Records what happened, still does the real thing | either |
| **Mock** | Pre-programmed with expectations, fails if they are not met | interaction |

## Prefer a fake

A fake is a real implementation with the expensive part removed: an in-memory
repository backed by a dict, a clock you advance by hand, a queue that is a
list. It costs more to write once and then pays back on every test that uses it.

```python
class InMemoryInviteRepo:
    def __init__(self): self._rows = {}
    def save(self, invite): self._rows[invite.id] = invite
    def find(self, id): return self._rows.get(id)
    def find_pending_for(self, email):
        return [i for i in self._rows.values()
                if i.email == email and i.status == "pending"]
```

Now a test can assert what is *true afterwards* rather than what was *called*:

```python
service.accept_invite(invite.id, user)
assert repo.find(invite.id).status == "accepted"
assert repo.find_pending_for(user.email) == []
```

That test survives renaming `save`, extracting a helper, or reordering the
writes. The mock-based equivalent does not.

## When a mock is the right answer

Use a mock when **the interaction is the behaviour** and there is no observable
state to check:

- "Sends exactly one email, to the invitee, not the inviter."
- "Does not call the payment provider twice for one idempotency key."
- "Retries three times, then gives up."

In each case the point *is* the call. Assert the call, and assert it precisely —
including the arguments and the count. A bare `expect(send).toHaveBeenCalled()`
would pass if you emailed the wrong person eleven times.

## The rules

**Never mock the thing under test.** Mocking a method on your subject means you
are testing the mock. If you feel the need, the class is doing two jobs — split
it.

**Mock at the boundary you own.** Wrap the third-party SDK in your own thin
interface and fake *that*. Mocking the vendor's client directly couples every
test to their API shape, and their next major version breaks a hundred tests
that have nothing to do with the change.

**Don't mock value objects.** Constructing a real `Money(1250, "JPY")` is
cheaper and more honest than mocking one.

**One mock per test, ideally.** Three or more mocked collaborators usually means
the unit under test is orchestrating too much. That is a design signal, not a
testing problem.

## Contract tests: the fake's honesty check

A fake can drift from the real thing, and then your tests pass while production
fails. Guard it with one test suite run against **both** implementations:

```js
function repositoryContract(makeRepo) {
  test("returns null for an id that was never saved", async () => {
    expect(await makeRepo().find("missing")).toBeNull();
  });
  test("overwrites on a second save of the same id", async () => {
    const repo = makeRepo();
    await repo.save({ id: "a", n: 1 });
    await repo.save({ id: "a", n: 2 });
    expect((await repo.find("a")).n).toBe(2);
  });
}

describe("in-memory", () => repositoryContract(() => new InMemoryRepo()));
describe("postgres",  () => repositoryContract(() => new PostgresRepo(testDb)));
```

The in-memory version runs everywhere in milliseconds; the Postgres version runs
in integration CI. When they disagree, you have found the drift before your
users did.
