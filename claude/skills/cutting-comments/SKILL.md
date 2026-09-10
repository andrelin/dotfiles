---
name: cutting-comments
description: Read after drafting any edit that adds comments, and before filing a comment as a finding in someone else's diff. Carries the standing rule - comments are a last resort, only a non-obvious why survives - and the cut-down pass that applies it to one specific diff.
---

# Cutting comments

`~/.claude/rules/writing-code.md` carries the one-line rule: a comment is a last resort, and only a
*non-obvious why* survives. This file is the standing rule in full, and the pass that applies it to a diff.

## The standing rule

Write code so that **reading the code explains the code** — intent carried by naming and structure, not prose.
Before writing a comment, try a rename, an extracted well-named function or local, or a restructure; if any of
those would carry the meaning, do that instead and drop the comment.
**Why:** comments drift from the code and restate what good names already say.

- Don't comment *what* the code does, or restate a function's name, signature, or type.
- Don't state domain knowledge the team already has.
- Keep a comment only for a *non-obvious why* a reader couldn't infer — a legal constraint, a workaround for
  external-library behaviour, a deliberate choice that looks wrong at first glance. One or two lines.
- No file or class header comments that merely narrate; no commented-out code.
- Never reference things outside the repo — local file paths, source documents, plan files, ticket numbers.
  They rot and mean nothing to the next reader.
- Test bodies follow the same bar: prefer self-evident Given/When/Then *structure* over `// Given` / `// When` /
  `// Then` scaffolding.

**Check the local convention first.** Some codebases deliberately run a more explanatory style — a teaching repo,
a library with a documented public surface. `git grep -c` the pattern before assuming the codebase wants it cut,
and honour any project rule that carves out a directory.

## The standing check

**Whenever a change adds comments, re-read them and cut** — after drafting your own edit as much as on review.
Treat the first draft of a comment as too long by default.

**Measure rather than eyeball:** count added comment lines against added lines of code, and be suspicious of a
block that dwarfs its change. The case that prompted this rule was 13 comment lines over a 1-line fix.

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

## Rebuttals and red flags

**Red flags:** a roadmap tense ("for now", "until we", "eventually"); a comment naming another layer, a ticket,
or a file that gets deleted; a comment block longer than the hunk it sits on; the same rationale appearing in
both the code and its test.

Every comment feels justified at the moment of writing it — that's why it got written, and that feeling is not
evidence. If you find yourself arguing to keep one, the answer to the argument is in
`~/.claude/docs/comment-excuses.md`.

## On review: check the file's existing convention first

Before filing a comment as a finding, check whether the pattern is **already dominant in the file being edited**
(`git grep -c` against the default branch).

If the author matched the file's existing convention, that's a separate decision for the team, not a defect in
their MR — say so. Otherwise the finding invites an easy rebuttal that discredits the rest of the review.
