---
name: writing-tests
description: Make every test able to fail for a real reason - the anti-patterns that pass forever regardless of behaviour (asserting a literal the author just typed, round-tripping through no logic, asserting a mock returns what it was told to return), what is worth testing instead, and the litmus test to apply before writing one. Read before writing or reviewing tests.
---

# Test actual logic, not literals

**A test must be able to fail for a real reason.**
Don't write tests that restate a hardcoded literal or assert a compile-time-guaranteed fact — they add noise and
pass forever regardless of behaviour.

**Why:** a test whose only failure mode is someone editing its own literal proves nothing. It inflates the suite,
slows every run, and dilutes the signal from tests that would actually catch a regression. Worse, it reads as
coverage — so the untested branch beside it looks tested.

## Anti-patterns — don't write these

- **Asserting a constant is non-empty or equals itself.**
  `assertThat(Colour.RED.label).isNotEmpty()` — the value is right there in the source, and a missing constructor
  argument is already a compile error.
- **Restating a literal mapping the author just typed.**
  Asserting `Colour.RED.label == "Red"` when that's a plain literal with no computation behind it.
  The test and the code are the same keystroke twice.
- **Round-tripping a value through no logic** — construct an object, read the field back, assert it matches.
  That tests the language, not the code.
- **Asserting a mock returned what you told it to return.**
  If the stub says `returns 42` and the assertion is `== 42`, the only thing under test is the mocking library.
  Assert on what the code *did* with it — the branch taken, the call made, the value derived.
- **Asserting on a value the test itself computed the same way the code does.** If a bug in the formula would be
  copied into the expectation, the test cannot see it. Hardcode the expected result instead.

## Do test

- **Computed / derived values** — anything where the output isn't visible in the input.
  A name resolved from an ISO code, a total, a formatted string, a mapped shape.
  Assert something the computation actually determines rather than something it echoes.
- **Branching and fallback logic** — each branch, and the default nobody remembers to exercise.
- **Wiring and regression guards** — a field that was once missing from a response, a route that was once
  unregistered. These *are* worth pinning even though they look trivial: they encode a bug that happened.
- **Validation and error paths.** Where the framework or schema doesn't backstop validation, these tests are the
  only line of defence — negative tests there are high-value logic tests, and this rule is not licence to skip
  them.
- **Boundaries** — empty, null, one, many, the off-by-one at each end.

## Litmus test before writing one

> *What real bug or regression would make this fail?*

If the only way it fails is someone editing the test's own literal, delete it.
If you can't name the bug it would catch, you're writing coverage, not a test.

The same question works on review: ask it of a test in someone else's diff before approving it.
