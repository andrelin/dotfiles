---
name: writing-claude-md
description: Read before creating a CLAUDE.md, before adding or reworking a section in one, and when deciding whether a new rule belongs in CLAUDE.md, a skill or a reference doc. Covers audience, the cost of a line that loads every session, and what must stay out of a shared repo.
---

# Writing CLAUDE.md files

Applies to every `CLAUDE.md` — the global one, project-level ones, any a customer engagement carries.
The audience is Claude on a fresh task, not a human onboarding, and the file loads every session whether or not
it is relevant, so every line is paid for on every task.

- **Terse and fact-dense**, in bullets and tables: the rule, a one-line *why*, how to apply. No teaching prose,
  and nothing a competent reader already knows.
- **The *why* earns its keep** — a bare rule gets misapplied at the edges, and one line of rationale lets the
  agent judge an unusual case. One line, not a paragraph.
- Don't restate what the code, the repo layout, or the tooling config already says.

## The length budget — a short file is the deliverable

**A project `CLAUDE.md` aims at 30 lines and never passes 50**; the global one, permission rules included, aims
at 60 and never passes 75 — the tightest bars there are, shared only with rules, because these are the files
that load whether or not they are relevant. Enforced by `~/.claude/rules/markdown-limits.md`.

These are ceilings, not averages to drift toward — a file at half the number is finished, not underweight, and
nothing here is ever a reason to add a line.
**Past the ceiling it stops being read as rules and gets skimmed as prose**, and the lines that matter most — the
permission rules, the publish bar — lose by sitting next to twenty that don't.

**Every line is one rule, stated once.** The shape that holds the budget:

- **One line per rule**, verb-first, with the *why* folded into the same sentence where it's needed at all.
- **A pointer instead of the content** — name the skill, rule file or doc and stop.
  A rule that ends "— the `writing-tests` skill" is finished; the skill carries the rest.
- **Every pointer names the condition for following it** ("only if a file is near a cap", "at handover"), so it
  stays unread by default. One that reads as an instruction to go and read is a chain, not a split.
- **No section that only introduces another section**, no restating a rule the global file already carries,
  and no history of how a convention came about.
- **Group the leftovers.** Rules with no natural trigger — a magic issue number, a CI stance — get one bullet
  each under a single heading, not a heading each.

**Cut on sight:** whenever you open a `CLAUDE.md` to add something, spend the same edit removing something.
A file only reaches 300 lines one justified addition at a time.

## Four homes — pick by what triggers the need

**Anything in `CLAUDE.md` is paid for on every task**, so material that only matters sometimes belongs somewhere
that loads only then. Ask what triggers the need: what you're **doing** → a skill; where you **are** → a rule.

| Trigger | Home | Loads |
| --- | --- | --- |
| A *task* — writing tests, reviewing, diagnosing, generating something | `.claude/skills/<name>/SKILL.md` | when the task matches its `description` |
| A *place* — a language, a directory, a kind of file | `.claude/rules/<name>.md` with a `paths:` glob | when a file matching the glob is read |
| Everything, always — stack, layering, naming, the permission rules | `CLAUDE.md` | every session, so it has to earn that |
| Pure reference — inventories, reasoning, case studies | a doc a skill or rule points at | only when something sends you there |

A section that opens "before doing X…" is a skill that hasn't been extracted yet; one that only makes sense
inside one directory is a rule that hasn't been extracted yet.

**The exception that keeps things in `CLAUDE.md`:** anything a task must not get *wrong* stays there even when
it's narrow. A rule loads when a matching file is read — which can be *after* the mistake — and a skill loads
when its trigger matches, which assumes the trigger fired. Neither is a guarantee; `CLAUDE.md` is.
Permission rules, publish bars and destructive-action limits are all in this category.

When you extract a skill, the `description` is the trigger: write it so it names the **task**, not the topic.
If a skill would need two unrelated triggers to be found, that's a sign it should be two skills.

**One subject per file, named for it.** A file covering two subjects loads both whenever either is wanted, and
its trigger has to be vague enough to catch both — which makes it fire when neither is.
A doc it points at explains in full within the same cap, repeating nothing; if it won't fit, it was two docs.

### Where the rest of the detail lives

- **`paths:` globs** — how they match, why a dead glob is silent, how to verify one: `~/.claude/docs/rule-globs.md`.
- **Skill front matter** — the six portable fields, why anything else breaks a claude.ai upload, and why a
  vendored skill is exempt from every convention here: `~/.claude/docs/skill-front-matter.md`.
  All trigger text goes in `description`; there is no `when_to_use`.
- **Personal context** — why it goes in a gitignored `CLAUDE.local.md`, and where across worktrees:
  `~/.claude/docs/claude-local-md.md`.
- **Upkeep** — the excuses that grow a file, and how to correct a stale one: `~/.claude/docs/maintaining-claude-md.md`.
  Read it before adding a section you can't cut something for.
