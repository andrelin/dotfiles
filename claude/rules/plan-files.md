---
paths:
  - "**/PLAN*.md"
  - "**/plan.md"
  - "**/plans/**"
  - "**/proposal.md"
  - "**/roadmap.md"
  - "**/migration.md"
  - "**/CLAUDE.md"
  - "**/README.md"
---

# Plan files

**Update the plan in the same turn as the code change.** Never let it drift behind the working tree, and never
batch the update for the end — by then the user has lost track of which section covers what.

**Plan files are temporary.** Never reference one from anything that outlives it — `CLAUDE.md`, a README, memory,
a PR description.
That second half is why this rule loads on those files too, not only on a plan. Inline the load-bearing content into the durable doc instead.
Cross-references *between* plans are fine; links *from* durable docs *into* plans are not.

Writing one, sizing a task, and the handover checklist: the `writing-plans` skill.
