---
name: cutting-comments
description: Read after drafting any edit that adds comments, and before filing a comment as a finding in someone else's diff. Covers the cut-down pass over one specific diff; the standing rule it applies lives in CLAUDE.md.
---

# Cutting comments

The base rule is in `~/.claude/CLAUDE.md` (§ *Self-documenting code*): reading the code explains the code, and a
comment survives only for a *non-obvious why*. This is the pass that applies it to a specific diff.

**Check the local convention first.** Some codebases deliberately run a more explanatory comment style — a
frontend next to a terse backend, a teaching repo, a library with a documented public surface. Applying this bar
there is wrong. `git grep -c` the pattern before assuming the codebase wants it cut, and honour any project rule
that carves out a directory.

## The standing check

**Whenever a change adds comments, re-read them and cut.**
Applies to **writing** them as much as reviewing them: after drafting any edit that adds a comment, go back over
each one and ask what survives. Treat the first draft of a comment as too long by default.
The same pass runs on review, over someone else's diff.

**Measure rather than eyeball:** count added comment lines against added lines of code from the diff, and be
suspicious of a block that dwarfs its change. The case that prompted this rule was 13 comment lines over a
1-line fix.

## What to cut, in the order these actually show up

1. **A comment describing another layer's current state** — backend prose about what the frontend does, or vice
   versa. It drifts silently because nothing fails when the other side changes, and it's the line most likely to
   be false a year later.
2. **Restated domain knowledge** ("a PATCH is a full-object replace") — the team already knows.
3. **Narrated product decisions** — `// admins only for now, product wants to open this up later`.
   The tell is a roadmap tense ("for now", "until we", "eventually"): it describes a decision rather than the
   code, nothing fails when the decision changes, and it reads as a live commitment long after it stopped being
   one. The `if (user.isAdmin)` beside it already says what the code does.
4. **References the next reader cannot open** — `TASKS.md`, a ticket ID, a bare commit SHA, a plan file that gets
   deleted when the work ships.
5. **Rationale duplicated between production code and its test**, which creates two copies to keep in sync.

Keep the *non-obvious why* — typically one or two lines, e.g. why a guard covers a state transition rather than
an echo of it.

## The excuses, and what's actually true

Every comment feels justified at the moment of writing it — that's why it got written.
The cut-down pass exists because that feeling is not evidence.

| Excuse | Reality |
| --- | --- |
| "This one explains a real subtlety." | Then put it in the code. Try the rename or the extracted function; keep the comment only if neither works. |
| "The next reader won't have the context I have." | They'll have the code, the tests and the history. They won't have a comment that stayed true. |
| "It's only two lines." | Two lines that no test covers and no compiler checks. Cost is paid at every future read. |
| "The author asked for it in review." | A separate conversation. It doesn't make the comment true a year from now. |
| "I'll leave it — removing it isn't my change." | Expanding a wildcard import isn't your change either, and that one you do. Same reasoning. |

**Red flags:** a roadmap tense ("for now", "until we", "eventually"); a comment naming another layer, a ticket,
or a file that gets deleted; a comment block longer than the hunk it sits on; the same rationale appearing in
both the code and its test.

## On review: check the file's existing convention first

Before filing a comment as a finding, check whether the pattern is **already dominant in the file being edited**
(`git grep -c` against the default branch).

If the author matched the file's existing convention, that's a separate decision for the team, not a defect in
their MR — say so. Otherwise the finding invites an easy rebuttal that discredits the rest of the review.
