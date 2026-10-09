# What to assert

The assertion is the test. Everything else is setup.

## Assert the specific thing

A weak assertion passes while the behaviour is wrong:

```js
expect(result).toBeTruthy();              // passes for {}, "0", [], 1, "error"
expect(items.length).toBeGreaterThan(0);  // passes for the wrong items
expect(() => f()).toThrow();              // passes for a typo that throws TypeError
```

Tighten each one:

```js
expect(result).toEqual({ status: "archived", archivedAt: FIXED_NOW });
expect(items.map(i => i.id)).toEqual(["a", "c"]);   // exact, and ordered
expect(() => f()).toThrow(InviteExpiredError);      // the error you meant
```

Exact equality on a whole object is usually better than field-by-field: it
catches the field you *didn't* think to check, including one that appeared
because someone widened a serialiser.

## Write the expected value literally

```python
# bad — recomputes with the same logic, agrees with the code even when wrong
assert invoice.total == sum(l.qty * l.price for l in lines)

# good — a number a human worked out
assert invoice.total == 1247
```

If the literal is tedious to produce, that is a sign the test case is too big.
Shrink the input until the expectation is something you can state.

## Test errors as carefully as successes

Error paths are where the untested bugs live, because nobody exercises them by
hand. For each one, assert three things: **the right error type**, **something
about the message or code** that a caller would switch on, and **that the state
did not change**.

```python
with pytest.raises(InsufficientFunds) as exc:
    account.withdraw(500)
assert exc.value.code == "insufficient_funds"
assert account.balance == 100          # ← the one people forget
```

That last line is the real test. A failed operation that leaves a half-mutated
object is a far worse bug than the failure itself.

## Cover the boundaries, not the middle

For any input with a range, three tests beat thirty:

- **Empty / zero / none** — the empty list, the zero amount, the absent value
- **One** — the singular case, which is where pluralisation and "first item"
  logic breaks
- **Many** — enough to expose ordering and pagination

Then add the specific edges the domain has: the maximum, the negative, the
duplicate, the unicode name, the string that is entirely whitespace, the
integer that is a string.

## Think in properties

Sometimes you cannot state the expected output, but you can state something that
must always hold:

- Round-trip: `decode(encode(x)) == x` for any `x`
- Invariant: sorting changes order but never membership or length
- Idempotence: applying it twice equals applying it once
- Symmetry: `a.compare(b) == -b.compare(a)`
- Conservation: money out of one account equals money into the other

You can assert these against a handful of hand-written cases without any special
library, and they catch a class of bug that example-based tests miss. If your
language has a property-testing library, these are exactly what it automates.

## Table-driven tests

When the same logic has many cases, one test per case is noise. A table keeps
each case visible and each failure attributable:

```go
tests := []struct {
    name string; input string; want Duration; wantErr bool
}{
    {"plain seconds",  "30s",  30 * time.Second, false},
    {"mixed units",    "1h30m", 90 * time.Minute, false},
    {"zero",           "0s",   0, false},
    {"negative",       "-5s",  0, true},
    {"missing unit",   "30",   0, true},
    {"empty",          "",     0, true},
}
for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) { /* ... */ })
}
```

The name field is doing real work: a failure says `parse/missing_unit`, not
`parse #4`. Keep the table flat — once a case needs its own conditional branch
inside the loop body, it wants to be its own test.

## What not to assert

- **Log output**, unless the log *is* the product. Strings change; tests that
  pin them get updated reflexively.
- **That a private method was called.** Test the behaviour that uses it.
- **Formatting of an error message** a human reads. Assert the code, not the prose.
- **Wall-clock duration.** Assert the outcome, not the speed, unless performance
  is the requirement — and then use a benchmark, not a test.
