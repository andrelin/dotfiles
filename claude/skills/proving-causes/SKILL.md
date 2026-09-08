---
name: proving-causes
description: Read before any non-trivial debugging, root-cause or reproduction task - a flaky test, an intermittent failure, a failing pipeline - and before shipping or scoping a fix on a cause you have not proven. Covers the traps, not a prescribed method.
---

# Proving causes — constraints and traps

**Deliberately not a prescribed method.** How to investigate depends on the problem, and over-fitting to one
recipe limits you. This is only the stuff that reliably holds, whatever the bug.

The base rule is in `~/.claude/CLAUDE.md` (§ *Prove causes, don't assume them*): hold every candidate cause as a
hypothesis until an experiment or measurement confirms it, and ship a fix only on proven cause + proven effect.

## The trap is that a wrong cause is *plausible*

Theorising causes is good and cheap. **Accepting one without proof is the trap** — and it's the easiest trap to
fall into, because the wrong answer sounds reasonable. Three shapes that keep recurring:

- **"It's transient, just rerun it."** Sometimes true; often a real, reproducible condition that only fires under
  a particular state (a cold cache, an empty table, a slow morning). Blaming flakiness ends the investigation
  before it starts, and it's unfalsifiable unless you go looking.
- **"X is what tips it over."** A mechanism that fits the evidence isn't the mechanism. The check is cheap: build
  a probe that adds exactly X and see whether it reproduces. Often it doesn't.
- **"The similar-looking case must be affected too."** Scoping by resemblance — same framework, similar size,
  looks heavy — instead of by measurement. Measure each candidate before widening a fix; most of them usually
  aren't affected, and a needlessly broad fix costs more than the bug.

Reproduce it, measure it, or force it to happen on demand. Don't conclude, scope, or ship on "probably".

## The excuses, and what's actually true

These are what it sounds like from the inside when the proof step is about to get skipped.
Under time pressure they all feel like pragmatism.

| Excuse | Reality |
| --- | --- |
| "It's flaky, just rerun it." | Unfalsifiable until you look. A rerun buys silence, not information. |
| "The cause is obvious from the stack trace." | The trace shows where it surfaced, not what put it there. Cheap to confirm; confirm it. |
| "No time to reproduce — the fix is small." | A small unverified fix costs a second round trip plus the credibility of the first. |
| "It went green." | See § *A vanished symptom is not a fixed cause*. One green run is one sample. |
| "Same symptom as that other bug, so same cause." | Symptoms are many-to-one with causes. Resemblance is a hypothesis, not evidence. |
| "It only happens in CI, so I can't prove it locally." | Then narrow it in CI, one variable per run. "Can't reproduce" is a finding, not a licence. |
| "I'll ship the fix and watch whether it recurs." | Production is a slow test with no assertion. You won't be able to read the result. |

## Red flags — stop and get proof

- You're about to write "should fix" or "likely caused by" in a summary.
- You changed more than one thing since the last observation.
- The fix is drafted and the reproduction still isn't.
- You're widening the fix to files you haven't measured.
- You're comparing two numbers you didn't take the same way.

Each means the same thing: you have a hypothesis, and you were about to spend it as a conclusion.

## Reproduce before you fix

A fix for a bug you never reproduced is unverifiable — you can't tell a real fix from a coincidence, and with an
intermittent failure you can't tell either from luck. Getting it to happen **on demand** is usually the hard part
of the work and the part that makes everything after it cheap.

If you can't reproduce it, say so and treat the fix as provisional rather than presenting it as done.

## When CI or the remote is gated, work locally first

On work where the user owns the remote, you can't push or trigger pipelines, so every CI result is a slow
round-trip through them. Whenever the problem allows it: **reproduce and measure locally**, decide as much as you
can before asking for a run, and when you do need one, prepare the job or working tree for the user to run and
read back what they paste.

A local approximation that gives the same signal in two minutes beats a faithful pipeline run that costs twenty.

## Trap: don't mix measurements

**Never compare or subtract across incompatible measurements.** Two numbers that both claim to be "memory used",
"time taken" or "rows affected" are often measuring different things, and the difference between them is an
artifact you just invented.

Check what each number includes before putting them in the same sentence — and if you can't establish that, take
one measurement that covers both sides instead of reconciling two.

## Trap: a vanished symptom is not a fixed cause

Especially with anything intermittent. If the failure rate was 1-in-20, a green run proves nothing; neither does
five. Decide up front what evidence would count — a forced reproduction that now passes, a measurement that moved,
the mechanism ruled out — and hold the fix to that rather than to the absence of the symptom.

## Keep the search narrow and recorded

- Change one variable at a time, or you learn nothing from the result.
- Keep a running note of what you ruled out and *how*, so you don't re-test it three steps later, and so the
  eventual write-up has its evidence to hand.

## When you're done

Strip the temporary scaffolding you added — probe jobs, samplers, forced flags, debug logging — back out of the
repo. The findings belong in a doc or the MR description, not left behind in the pipeline.
