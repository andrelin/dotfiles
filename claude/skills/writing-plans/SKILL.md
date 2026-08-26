---
name: writing-plans
description: Conventions for plan files - what makes one implementable without ambiguity, keeping it in sync with the code in the same turn, status marks, and the rule that plans are temporary and must never be referenced from anything that outlives them. Read before writing a plan file (PLAN-*.md, proposal.md, roadmap.md, migration.md), before editing one, and before referencing one from a durable doc.
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
