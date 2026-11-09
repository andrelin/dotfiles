<!-- DOCTOC SKIP -->

# Review findings (code)

Leftovers before round 1: none

## Round 1

### R1-1 · major · correctness

Task 14's with-rule pass, "restating, or naming what it lacks", can't fail on the baseline, which also named what it lacked.

Fixed: the record states the criterion that can fail, no choice between options named only by id: 3 of 3 fail without the rule, 3 of 3 pass with it.

### R1-2 · major · correctness

One sample per arm, the rule's loading unverified.

Fixed: three samples per arm, verbatim questions, a load check quoting the rule.

### R1-3 · major · the change as a whole

The lookup-first and say-what-is-missing bullets change what Task 14 delivers and its pass test, labelled "how, not
what"; `implementing-plans` sends such a deviation to the user.

Fixed: the user kept them (2026-11-05).

### R1-4 · major · the change as a whole

The restate, options and id-beside bullets have no run that can fail: opus restated without the rule whenever the content was readable.

Fixed: the user ships them, and the choice line now asks for what each option costs or risks (2026-11-05).

### R1-5 · minor · tests, correctness, plan conformance

With-rule questions paraphrased; the realistic case (after a summary, file readable, rule loaded) unrun.

Fixed: quoted, and that case run: it read the file and restated each option.

### R1-6 · minor · tests

The "keep it a summary" bar unchecked.

Fixed: the record gives each question's length, two to four sentences.

### R1-7 · minor · tests, the change as a whole

`AskUserQuestion`, review-log and subagent channels untested; `AskUserQuestion` can't run headless.

Fixed: recorded as resting on the wording, with the verifier's check.

### R1-8 · minor · the change as a whole

A session started before the file existed, and its subagents, run without the rule; unsaid.

Fixed: recorded in Task 14.

### R1-9 · minor · plan conformance

The yes/no and information carve-out is an unrecorded deviation.

Fixed: recorded in Task 14.

### R1-10 · minor · docs

`tips/24_claude_code.md` says every rule is path-scoped.

Fixed: the line names rules with no `paths:`.

### R1-11 · minor · fit, docs

`writing-agent-instructions` § *Four homes* has no row for an always-loaded rule.

Fixed: a row added.

### R1-12 · nit · fit

Skill named bare; "the user asks for more" read as fact; "only the ids survive" stated as always true.

Fixed: reworded.

### R1-13 · nit · several

Line 9 could fold into line 8; "frontmatter" split; labels of other files could go stale; trivial follow-ups padded;
`review-log.md` doesn't say a question may wrap; lines 12-13 longer than the neighbours'.

Refuted: subagents don't load the rule (a verifier's run showed they do in a fresh session); the review-log format
breaks (nothing parses it); "task number" clashes with the Forgejo rule; "no lookup possible" uncovered; the
subagent-draft example widens scope; the Tests bullet's superseded methods.

## Round 2

### R2-1 · minor · tests

The "costs or risks" line had no check that can fail (downgraded from major: a per-option cost check now fails 3 of 3
without the rule and passes 3 of 3 with it).

Fixed: recorded in Task 14 with quotes.

### R2-2 · minor · tests, plan conformance

The recorded passes predated the shipped wording.

Fixed: a load check and four runs on the final text, recorded.

### R2-3 · minor · tests

No length record or bar.

Fixed: both arms' word counts recorded, 383–408 without the rule and 430–470 with it.

### R2-4 · minor · tests

With-rule outputs paraphrased.

Fixed: quoted in Task 14.

### R2-5 · minor · tests

The scenario prompt lived only in a temp directory.

Fixed: `test/scenarios/asking-questions/` holds it, the fixture, and how to run and judge it.

### R2-6 · minor · tests

The yes/no bullet has no test.

Fixed: recorded as resting on the wording; it loosens the rule.

### R2-7 · minor · correctness, docs, fit

`writing-agent-instructions`' exception paragraph said only `CLAUDE.md` is a guarantee, against the new row.

Fixed: a rule with `paths:` is the one that can load late; a rule with no `paths:` is a guarantee; the lead line names it.

### R2-8 · minor · correctness

The lookup bullet ignored a brief that forbids opening a file.

Fixed: "unless your brief forbids opening it", and the say-what-is-missing bullet covers "can't look it up".

### R2-9 · minor · the change as a whole

A rule-conforming logged question can't fit `review-log.md`'s one-line stop.

Fixed: the line stays short; options and costs go in the findings file.

### R2-10 · minor · the change as a whole

`markdown-limits.md` justified the rule budget by "loads on a bare path match".

Fixed: the reason covers a rule with no `paths:`.

### R2-11 · nit · several

"On its own budget" read as cheaper; the rule wrapped at a colon under 150.

Fixed: "so it too has to earn that"; joined. Unfixed: the "Four homes" heading over five rows (refuted by two
verifiers: a pathless rule is still the rule home).

Refuted: verb-first bullets, the bare-id example's place, the tip naming two files, the subagent-draft example, a
`/code-review` loading gap (Task 7's open item), "say what is missing" needing more, a back-pointer in `review-log.md`.
