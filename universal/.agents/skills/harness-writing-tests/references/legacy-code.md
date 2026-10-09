# Testing code that has none

Untested code is usually untestable code: the logic you want to check is
entangled with a database call, a clock, and a network request. Trying to write
a clean unit test first means a week of refactoring with no safety net — which
is the exact situation where refactoring goes wrong.

Do it in the other order.

## 1. Pin the current behaviour first

A **characterization test** asserts what the code *does*, not what it should do.
You are building a net, not judging the code.

```python
def test_characterize_pricing():
    # Not necessarily correct. This is what it does TODAY, 2026-08-22.
    assert calculate_price(qty=3, tier="pro", coupon=None) == 2970
    assert calculate_price(qty=3, tier="pro", coupon="HALF") == 1485
    assert calculate_price(qty=0, tier="pro", coupon="HALF") == 0
```

If you do not know the expected value, run it and record what comes out. Assert
that. When it looks wrong, **write it down in a comment and leave it passing** —
you are not fixing behaviour yet, and changing it now means you can no longer
tell a refactoring mistake from an intentional change.

## 2. Find a seam

A seam is a place you can change behaviour without editing the code around it.
In order of preference:

**Parameter seam** — the cleanest. Add an argument with a default, so every
existing caller is unaffected:

```python
def process_order(order, clock=datetime.utcnow, gateway=None):
    gateway = gateway or StripeGateway()
```

**Constructor seam** — move dependencies to `__init__` and default them. Same
idea, one level up.

**Subclass-and-override** — when you cannot change the signature, extract the
awkward call into a method and override it in a test subclass. Ugly, and
entirely legitimate as a stepping stone.

**Environment seam** — a flag or env var that swaps an implementation. Last
resort: it is invisible at the call site, which is exactly what makes it easy to
forget.

## 3. Extract the logic you actually want to test

Once there is a seam, pull the decision-making out of the I/O:

```python
# before: one function, untestable
def send_renewal_reminders():
    for sub in db.query("SELECT * FROM subscriptions"):
        if sub.expires_at - datetime.utcnow() < timedelta(days=7) and sub.active:
            mailer.send(sub.email, render_template("renewal"))

# after: a pure decision, and a thin shell around it
def needs_reminder(sub, now):                     # ← unit-testable, no I/O
    return sub.active and sub.expires_at - now < timedelta(days=7)

def send_renewal_reminders(db, mailer, now):      # ← thin, integration-tested
    for sub in db.active_subscriptions():
        if needs_reminder(sub, now):
            mailer.send(sub.email, render_template("renewal"))
```

`needs_reminder` now takes ten fast unit tests covering every boundary. The
shell needs one or two integration tests, because there is almost nothing left
in it to get wrong.

## 4. Now fix the bug

With the net in place, change behaviour deliberately. The characterization test
that encoded the wrong behaviour is the one you now update — and that update is
the visible record of the fix. Put it in the PR description.

## Order of attack

You cannot test everything, so choose by where a defect costs most:

1. **Where you are about to change something.** Test-then-change is the whole point.
2. **Where bugs keep recurring.** Check the git log; the same file appearing in
   fix commits repeatedly is telling you something.
3. **Where the money or the data is.** Payments, permissions, deletion.
4. **Everything else.** Probably never, and that is fine.

Resist a "add tests to legacy code" project with no change attached. Tests
written far from any change tend to pin the wrong things, and nobody reads them.
