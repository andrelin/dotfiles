# The excuses for skipping the proof

The constraints are the `proving-causes` skill.
Read this only when the proof step is about to get skipped — under time pressure every row below feels like
pragmatism.

| Excuse | Reality |
| --- | --- |
| "It's flaky, just rerun it." | Unfalsifiable until you look. A rerun buys silence, not information. |
| "The cause is obvious from the stack trace." | The trace shows where it surfaced, not what put it there. Cheap to confirm; confirm it. |
| "No time to reproduce — the fix is small." | A small unverified fix costs a second round trip plus the credibility of the first. |
| "It went green." | One green run is one sample — see *a vanished symptom is not a fixed cause* in the skill. |
| "Same symptom as that other bug, so same cause." | Symptoms are many-to-one with causes. Resemblance is a hypothesis, not evidence. |
| "It only happens in CI, so I can't prove it locally." | Then narrow it in CI, one variable per run. "Can't reproduce" is a finding, not a licence. |
| "I'll ship the fix and watch whether it recurs." | Production is a slow test with no assertion. You won't be able to read the result. |
