---
name: proving-causes
description: Read before any non-trivial debugging, root-cause or reproduction task - a flaky test, an intermittent failure, a failing pipeline - and before shipping or scoping a fix on a cause you have not proven. Covers the traps, not a prescribed method.
---

# Proving causes — constraints and traps

**Deliberately not a prescribed method** — how to investigate depends on the problem. This is what holds whatever
the bug, on top of the base rule in `~/.claude/rules/writing-code.md`: hold every candidate cause as a
hypothesis until an experiment or measurement confirms it, and ship only on proven cause and effect.

## The trap is that a wrong cause is *plausible*

Theorising causes is good and cheap. **Accepting one without proof is the trap** — and it's the easiest trap to
fall into, because the wrong answer sounds reasonable. Three shapes that keep recurring:

- **"It's transient, just rerun it."** Often a real condition that only fires under a particular state — a cold
  cache, an empty table. Blaming flakiness ends the investigation before it starts, and is unfalsifiable.
- **"X is what tips it over."** A mechanism that fits the evidence isn't the mechanism. Build a probe that adds
  exactly X and see whether it reproduces; often it doesn't.
- **"The similar-looking case must be affected too."** Scoping by resemblance instead of measurement. Measure
  each candidate before widening a fix; most aren't affected, and a needlessly broad fix costs more than the bug.

Reproduce it, measure it, or force it to happen on demand. Don't conclude, scope, or ship on "probably".

If you catch yourself arguing that the proof step can be skipped this once — it's flaky, the trace is obvious,
there's no time — the answer to that argument is in `~/.claude/docs/cause-excuses.md`.

## Red flags — stop and get proof

- You're about to write "should fix" or "likely caused by" in a summary.
- You changed more than one thing since the last observation.
- The fix is drafted and the reproduction still isn't.
- You're widening the fix to files you haven't measured.
- You're comparing two numbers you didn't take the same way.

Each means the same thing: you have a hypothesis, and you were about to spend it as a conclusion.

## Reproduce before you fix

A fix for a bug you never reproduced is unverifiable — you can't tell a real fix from a coincidence, or either
from luck when the failure is intermittent. Getting it to happen **on demand** is usually the hard part, and the
part that makes everything after it cheap.
If you can't, say so and treat the fix as provisional rather than presenting it as done.

## When CI or the remote is gated, work locally first

On work where the user owns the remote you can't push or trigger pipelines, so every CI result is a slow
round-trip through them. **Reproduce and measure locally** wherever the problem allows, decide as much as you can
before asking for a run, and when you do need one, prepare the job for the user and read back what they paste.
A local approximation giving the same signal in two minutes beats a faithful pipeline run costing twenty.

## Trap: don't mix measurements

**Never compare or subtract across incompatible measurements.** Two numbers both claiming to be "memory used" or
"time taken" often measure different things, and the difference between them is an artifact you just invented.
Check what each includes before putting them in one sentence; if you can't, take a single measurement covering
both sides instead of reconciling two.

## Trap: a vanished symptom is not a fixed cause

Especially with anything intermittent: at a 1-in-20 failure rate a green run proves nothing, and neither do five.
Decide up front what evidence would count — a forced reproduction that now passes, a measurement that moved, the
mechanism ruled out — and hold the fix to that, not to the absence of the symptom.

## Keep the search narrow and recorded

- Change one variable at a time, or you learn nothing from the result.
- Keep a running note of what you ruled out and *how*, so you don't re-test it later and the write-up has its
  evidence to hand.

## When you're done

Strip the temporary scaffolding — probe jobs, samplers, forced flags, debug logging — back out of the repo.
The findings belong in a doc or the MR description, not left behind in the pipeline.
