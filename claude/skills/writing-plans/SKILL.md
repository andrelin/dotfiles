---
name: writing-plans
description: Read before writing or editing a plan file (PLAN-*.md, proposal.md, roadmap.md, migration.md), before handing one to an executor, and before referencing one from a durable doc. Covers the conventions these plans follow, not any plugin's plan format.
---

# Plan files

A "plan file" is any markdown document laying out work to be done — `PLAN-*.md`, `proposal.md`, `roadmap.md`,
`migration.md`. Identify it by content (numbered changes / sections / a backlog), not filename.

## Writing one

- **Specific enough to implement without ambiguity:** exact file paths, method signatures, env var names.
  This matters *more* when an agent implements the plan, not less: the executor is usually working in a fresh
  context that never saw the exploration behind the plan, and an agent that meets an ambiguity picks the most
  plausible reading and carries on where a human would stop and ask.
  Vagueness also hides the decisions the user is approving when they read the plan.
- **Don't transcribe what an agent can resolve.** Import statements, boilerplate and full file bodies are
  make-work when an agent implements the plan: it has the codebase and its tooling.
  Name the exact symbol or API where the choice isn't obvious — the wrong-package kind of mistake — and stop there.
- **Except when a human implements it: write the imports out in full.** Someone typing the code has no
  auto-import, so a bare symbol name costs them a lookup per line, and a guessed package is a compile error
  they have to debug rather than a squiggle the editor fixes.
  Give complete import statements — one symbol per line, never a wildcard
  (per `~/.claude/CLAUDE.md` § *Coding standards*).
  **Assume an agent executor unless the plan is explicitly for a person** — a colleague picking it up, a handover
  doc, or the user saying so. That case is rare; don't pay its cost by default.
- **Spell out the tests.** Every plan that changes code says which unit and integration tests to write, following
  the project's own test conventions. A plan without its test plan is incomplete.
- Terse and code-reference-heavy. No "what this code does" recaps — the reader has the codebase.

## Structure

Above the tasks:

- **Goal** — one sentence on what this builds.
- **Approach** — two or three sentences, enough that someone holding one task can tell whether their piece fits.
- **The spec or issue it argues from**, where there is one. A plan justifies itself against requirements, so the
  two travel together; the executor reads both.
- **Global constraints** — the project-wide requirements every task inherits: version floors, dependency limits,
  naming and copy rules, platform targets. Copy exact values rather than paraphrasing.
  Stated once here, they don't have to be repeated in — or forgotten by — each task.
- **Implementation status table**, for any non-trivial plan (see § *Keeping it in sync*).

Then map which files each task creates or modifies, before writing the tasks themselves.
That is where the decomposition is actually decided, and doing it up front surfaces two tasks fighting over the
same file while it's still cheap to fix.

### The shape on disk

```markdown
# <Feature> — plan
**Goal:** one sentence.
**Approach:** two or three sentences.
**Spec:** path or link, where there is one.

## Global constraints
- version floors, dependency limits, naming rules, platform targets — exact values

## Implementation status
| Task | Status |

## Task 1 · <name>
**Files:** created / modified (`path:line-range`) / test
**Interfaces:** consumes … | produces …
**Tests:** …
<the change itself>
```

## Sizing a task

A task is the smallest unit that carries its own test cycle and is worth a reviewer's gate.

- Fold setup, configuration, scaffolding and doc updates into the task whose deliverable needs them.
  Those are steps, not tasks.
- Split only where a reviewer could sensibly reject one task and approve its neighbour.
- Every task ends in something independently testable. A task nobody can run is a task nobody can review.

## What each task carries

- **Files** — exact paths, separated into created and modified, with line ranges (`src/Foo.kt:123-145`) where the
  change is local. Name the test file too.
- **Interfaces** — what this task consumes from earlier tasks, and what later tasks will rely on, with exact
  names and types.
  This is the load-bearing one for an agent executor: it sees its own task and the codebase, not the neighbouring
  tasks, so anything a neighbour depends on has to be written where it will actually be read.
- **The tests to write**, per § *Writing one*.

## Never write these

Each one hands a decision the plan was supposed to make back to the implementer, who will guess:

- `TBD`, `TODO`, "implement later", "fill in details".
- "Add appropriate error handling", "add validation", "handle edge cases" — appropriate how, which cases?
- "Write tests for the above", with nothing about what they assert.
- "Same as task 3." Tasks get read out of order and implemented in isolation. Say it again.
- A reference to a type, function or config key that no task defines and that isn't already in the codebase.

## Self-review before handing it over

Read the finished plan against the spec with fresh eyes — three passes, done yourself, not worth a subagent:

1. **Coverage.** Walk the spec's requirements and point at the task implementing each one.
   Add tasks for whatever you can't point at.
2. **Placeholders.** Search for the patterns above.
3. **Name and type consistency.** A helper called `clearLayers()` in task 3 and `clearFullLayers()` in task 7 is
   a bug the executor inherits. Check every symbol a later task consumes against what the earlier task produces.

Fix what you find inline and move on. Don't re-review.

## Keeping it in sync

- Plan files are the source of truth for what's done and what's left.
  **Update the plan in the same turn as the code change** — never let it drift behind the working tree.
- Mark status as work lands: `✅ DONE`, `🚧 PARTIAL`, `⏳ IN PROGRESS`, `⏳ PENDING`.
  Note deviations inline in the section they affect, not in a separate "changes vs plan" comment.
- Keep an "Implementation status" table near the top of any non-trivial plan.
- Don't batch up "I'll update the plan at the end" — by then the user has lost track of which section covers what.
- If a sub-feature is skipped or deferred, edit the section body to say so.
  Don't leave the original spec implying it shipped.

**Why:** a plan is a record of intent before work starts *and* a record of state after it lands.
A stale plan is worse than no plan.

## Plans are temporary

Deleted once the work ships. **Never reference one from anything that outlives it** — `CLAUDE.md`, READMEs,
memory, PR/MR descriptions. Inline the load-bearing content into the durable doc instead of linking to the plan.

Cross-references *between* plans are fine (shared lifecycle); links *from* durable docs *into* plans are not.

A long-lived personal tracker is **not** a plan file and is not covered by this — see the `writing-follow-ups`
skill for that distinction.
