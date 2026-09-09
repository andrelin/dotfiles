---
name: writing-plans
description: Read before writing or editing a plan file (PLAN-*.md, proposal.md, roadmap.md, migration.md), before handing one to an executor, and before referencing one from a durable doc. Covers the conventions these plans follow, not any plugin's plan format.
---

# Plan files

Any markdown document laying out work to be done — `PLAN-*.md`, `proposal.md`, `roadmap.md`, `migration.md`.
Identify one by content (numbered changes, sections, a backlog), not by filename.

## Writing one

- **Specific enough to implement without ambiguity:** exact file paths, method signatures, env var names.
  This matters *more* when an agent implements it: the executor works in a fresh context that never saw the
  exploration behind the plan, and meets an ambiguity by picking the most plausible reading and carrying on,
  where a human would stop and ask. Vagueness also hides the decisions the user is approving when they read it.
- **Don't transcribe what an agent can resolve** — imports, boilerplate, full file bodies; it has the codebase.
  Name the exact symbol or API only where the choice isn't obvious, the wrong-package kind of mistake.
- **Except when a human implements it: write the imports out in full**, one symbol per line, never a wildcard —
  they have no auto-import, so a bare symbol costs a lookup per line and a guessed package is a compile error.
  **Assume an agent executor unless the plan is explicitly for a person**; that case is rare, so don't pay for it by default.
- **Spell out the tests.** Every plan that changes code says which unit and integration tests to write, following
  the project's conventions. A plan without its test plan is incomplete.
- Terse and code-reference-heavy. No "what this code does" recaps — the reader has the codebase.

## Structure

Above the tasks: **Goal** (one sentence), **Approach** (two or three, enough that someone holding one task can
tell whether their piece fits), **the spec it argues from**, and **global constraints** — the project-wide
requirements every task inherits (version floors, dependency limits, naming rules, platform targets), as exact
values. Stated once there, they aren't repeated in, or forgotten by, each task.
Any non-trivial plan also carries an implementation status table.

Then map which files each task creates or modifies **before** writing the tasks: that is where the decomposition
is decided, and doing it up front surfaces two tasks fighting over one file while it's cheap to fix.
Creating the file from scratch? The skeleton is `~/.claude/docs/plan-file-template.md`.

## Sizing a task

A task is the smallest unit that carries its own test cycle and is worth a reviewer's gate.
Fold setup, configuration, scaffolding and doc updates into the task whose deliverable needs them — steps, not tasks.

- Split only where a reviewer could sensibly reject one task and approve its neighbour.
- Every task ends in something independently testable. A task nobody can run is a task nobody can review.

## What each task carries

- **Files** — exact paths, split into created and modified, with line ranges (`src/Foo.kt:123-145`) where the
  change is local. Name the test file too.
- **Interfaces** — what this task consumes from earlier tasks and what later ones will rely on, exact names and
  types. Load-bearing for an agent executor: it sees its own task and the codebase, not the neighbouring tasks,
  so anything a neighbour depends on has to be written where it will actually be read.
- **The tests to write**, per § *Writing one*.

## Before handing it over

At handover, and not before, run the placeholder patterns and three-pass self-review in
`~/.claude/docs/plan-handover-checklist.md` — each is a decision the plan should have made, left for a guess.

## Keeping it in sync

A plan records intent before work starts *and* state after it lands, so a stale plan is worse than no plan.

- **Update the plan in the same turn as the code change** — never let it drift behind the working tree, and never
  batch it for the end, by which point the user has lost track of which section covers what.
- Mark status as work lands (`✅ DONE`, `🚧 PARTIAL`, `⏳ IN PROGRESS`, `⏳ PENDING`) in the status table, and
  note deviations inline in the section they affect.
- If a sub-feature is skipped or deferred, edit the section body to say so, rather than leaving the spec implying it shipped.

## Plans are temporary

Deleted once the work ships. **Never reference one from anything that outlives it** — `CLAUDE.md`, READMEs,
memory, PR/MR descriptions — inline the load-bearing content into the durable doc instead.
Cross-references *between* plans are fine (shared lifecycle); links *from* durable docs *into* plans are not.
A long-lived personal tracker is **not** a plan file — that is `writing-follow-ups`.
