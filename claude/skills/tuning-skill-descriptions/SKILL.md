---
name: tuning-skill-descriptions
description: Read before writing or changing any skill's description, even a one-word tweak, and when a skill fails to load where it should or loads where it shouldn't.
---

# Tuning skill descriptions

A description is the only thing that decides whether a skill loads, and a wording that reads well can still miss.
Measure it: `bin/skill-trigger-eval <skill>` scores the current description over the skill's eval set, and
`--description "<text>"` scores a candidate without touching the file. Tip 24.7 has the mechanics and the cost.

**Tune from a session that doesn't need the skill:** the run moves it out of `claude/skills/`, hiding it from every
session on the machine until it ends.

## The eval set first

`test/skill-triggers/<skill>.json`, a JSON array of `{"query": "...", "should_trigger": true|false}`:

- **About 10 should-fire queries,** each a substantive multi-step request, worded the way the user would ask. A
  one-step request triggers no skill whatever the description says, so it measures nothing.
- **About 10 near-misses** from neighbouring skills' ground — the requests most easily confused with this one
  (`writing-plans` against `writing-follow-up-items`). A near-miss set of unrelated tasks passes every description.
- **The user reviews the set once.** After that it is a regression suite: a real misfire seen later joins it.
- **Hold out every third query** of each kind before the first run. Write candidates from the other two thirds'
  results only, and report the held-out third's separately — tuning on what you then report proves nothing.

## The candidates

Score the current description first: that is the number to beat. Then propose two or three candidates, each:

- **Saying only when to read**, never what the skill says (`writing-agent-instructions`).
- **Pushy about *when*,** with an "even when …" clause for the trigger most likely missed.
- **Under 300 characters,** counted before it is written anywhere: `printf %s "$d" | wc -m`.

## Choosing

- **Keep the best should-fire rate whose near-miss false triggers don't rise.** A difference of one query is noise.
- **The bar** is `run_eval`'s own pass at 0.5: every should-fire query triggers in at least 2 of 3 runs, every
  near-miss in at most 1 of 3. Record the raw rates too.
- **Scores compare candidates with each other.** A candidate runs as a bare command, which pulls less than an
  installed skill, so a description that can't reach the bar is recorded with its scores, never forced.
- **Show the user before and after,** with both scores on both halves. Write it only on a yes, and put the scores
  in the commit message.

## A query that fails every run

Check the query before blaming the description: run it by hand in a scratch directory with
`claude -p "<query>" --output-format stream-json --verbose` and read which tool came first. Another skill taking it
makes it a near-miss mislabelled, or a sign of overlap to fix in that skill; a direct answer with no skill at all
usually means the query is too small.

## Never

- **`run_loop` or `improve_description`** from `skill-creator`: they rewrite toward what the skill does, and ask for
  pushiness about the content, against `writing-agent-instructions`.
- **A failed run read as a miss.** `skill-trigger-eval` exits 1 rather than score one; rerun, don't work around it.

## Red flags

- The candidate summarises the body.
- You are reading the held-out third's results while writing candidates.
- The near-miss set holds only tasks no one would confuse with the skill.
- You are about to call one query's difference an improvement.
