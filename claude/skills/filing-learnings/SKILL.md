---
name: filing-learnings
description: Read when closing out a task that cost a detour - a wrong assumption, an undocumented convention, a correction the user had to repeat - before reporting it done.
---

# Filing learnings

A detour is worth one line in a file that loads next time, so the next session doesn't take it.
**The user decides whether it is written**: the close-out proposes, it never files.

## The close-out, in this order

1. **The report** of the task, as usual.
2. **The proposal** — at most one per task, as the last thing in the message, in this shape:

   > **Learning:** `<the exact line, as it would appear in the file>`
   > **Goes in:** `<path>`, under `<section>`.
   > **Cut to pay for it:** `<the line it replaces or removes>` (a `CLAUDE.md` only).
   > Write it?

3. **The write**, only after a yes — the line as approved, and the cut in the same edit.

"Please remember this" gets the proposal too: it asks for the learning to be kept, not for your wording,
destination or cut. Several candidates from one task: propose the one that cost the most, and drop the rest.

## The line

One line, verb-first, with the *why* folded in where needed: the shape of a `CLAUDE.md` rule in
`writing-agent-instructions`. A learning that needs a section is a skill, rule or doc — propose that file
instead, in one line saying what it would hold.

## Where it goes

First pick the home by what triggers the need, with `writing-agent-instructions`' four homes. Then the place,
by `~/.claude/hooks/work-context.sh level` or by kind:

| Level, or kind of learning | Where it goes |
| --- | --- |
| personal, company | the repo |
| customer | the customer tree's `CLAUDE.md` *outside* the repo, never their repo |
| personal-only context, any level | `CLAUDE.local.md` |
| how Claude works everywhere, any level | `claude/` in the dotfiles, nothing customer-identifying |

A kind row wins over a level row: a company-level learning about how Claude works everywhere goes to `claude/`.
**Never `~/.claude/projects/*/memory/`** — it doesn't follow the user to another machine.

## The cut

Adding to a `CLAUDE.md` means removing from it, per **Cut on sight** in `writing-agent-instructions`
§ *The length budget*: a line the new one supersedes, a duplicate of the global file, a rule no longer true.
Name it in the proposal. Found nothing to cut? Say so in that slot, and the user weighs the line knowing it.

## Skip it when

- The learning is already in a file that loads here — the detour was not reading it, and that's no new line.
- It only matters to this conversation, or to this one task.
- The task went as planned. No detour, no proposal.

## Red flags — excuses to file anyway

- "It might help someday."
- "The user seemed annoyed."
- "The file has room."
- "They said remember it, so I already have a yes."

Each one is a reason to drop the proposal, or to ask instead of writing.
