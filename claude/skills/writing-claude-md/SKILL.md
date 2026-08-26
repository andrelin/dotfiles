---
name: writing-claude-md
description: How to write and maintain a CLAUDE.md - audience and style, when material belongs in a skill instead, and keeping personal context separable so the file stays shareable. Read before creating a CLAUDE.md, adding or reworking a section in one, or deciding whether a new rule should live in CLAUDE.md, a skill, or a reference doc.
---

# Writing CLAUDE.md files

Applies to every `CLAUDE.md`: the global one, project-level ones, and any a customer engagement carries.

## Audience: Claude on a fresh task, not a human onboarding

A `CLAUDE.md` is loaded into context automatically, every session, whether or not it's relevant.
That's the whole cost model — every line is paid for on every task, so it has to earn the space.

- **Terse, fact-dense.** State the rule, an optional one-line *why* (so Claude can judge edge cases), and how to apply.
  Skip teaching prose, motivation essays, and anything a competent reader already knows.
- **Bullets and tables over paragraphs.**
- **The *why* is what earns its keep.** A bare rule gets misapplied at the edges; one line of rationale lets the
  agent work out whether an unusual case is covered. But one line, not a paragraph.
- Don't restate what the code, the repo layout, or the tooling config already says.

## Prefer a skill over a CLAUDE.md section

**If material is only relevant to specific tasks, it should be a skill, not a section.**
A skill self-triggers from its `description` and costs nothing until it matches, so it beats both a `CLAUDE.md`
section (always loaded, relevant occasionally) and a plain doc (has to be remembered and linked, so it gets missed).

Decide with this:

| Material | Home |
| --- | --- |
| Needed on most tasks in this project — stack, layering, language idiom, naming | `CLAUDE.md` |
| Needed only when doing a particular kind of task — writing tests, reviewing, diagnosing, generating something | **a skill** |
| Pure reference facts with no procedure attached — inventories, tables, case studies | a doc the skill points at |

A `CLAUDE.md` section that opens "before doing X…" is a skill that hasn't been extracted yet.

When you do extract one, the `description` is the trigger: write it so it names the **task**, not the topic.
If a skill would need two unrelated triggers to be found, that's a sign it should be two skills.

### Front matter: stay on the portable six

Claude Code accepts many front-matter fields; only six are in the [Agent Skills](https://agentskills.io) spec:
`name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`.
**Use only these.** Anything else makes the skill Claude Code-only — uploading it to claude.ai (Cowork, cloud
sessions, the Skills API) then fails with a hard `Unexpected key(s) in SKILL.md frontmatter` error rather than
ignoring the field.

That list is a snapshot so the rule can be followed without fetching anything; the spec is the authority if the
two ever disagree. Being a field behind is safe in both directions — a field the spec added and this list lacks
just goes unused, and a field it dropped surfaces as the upload error above.

The tempting non-spec ones are `when_to_use` (a separate trigger field), `user-invocable: false` (hide from the
`/` menu) and `paths` (glob-gated auto-loading). Do without them:

- **All trigger text goes in `description`**, since `when_to_use` is off the table.
  Lead with the key use case — `description` is truncated at 1,536 characters in the skill listing.
- **A `description` that names the task precisely** does the job `paths` would, without suppressing the
  cross-cutting triggers a glob can't express.

Front matter is exempt from the markdown line-length rule — see `~/.claude/CLAUDE.md` § *Markdown line breaks*.

## Keep personal context out, or at least separable

Personal context is anything tied to one person: their team or role, what the agent may do on their behalf,
their personal files and trackers, their standing preferences.

**In a customer or company repo, none of it gets committed.** A `CLAUDE.md` checked into someone else's
repository is a shared file — personal working arrangements do not belong in a colleague's checkout, and on a
company repo the history is walked through in front of an audience.

Put it somewhere outside the repo that the agent still reads:

- **The `CLAUDE.md` at the root of the customer's tree**, above the individual repos and not itself in git.
  This is the normal home for it, and `~/.claude/CLAUDE.md` already directs the agent there before customer work.
- **`~/.claude/CLAUDE.md`** for anything that holds across every engagement rather than this one.

Neither is version-controlled with the customer's code, so nothing personal reaches their history.

**In a repo the user owns, it may be committed — but in one clearly-marked section**, not sprinkled through the
file. That's the difference between a file someone can adopt and one they'd have to audit line by line: gathered
in one place, they rewrite that section and keep the rest.

The same test applies to the rest of any `CLAUDE.md`: a sentence that only makes sense from one person's seat
("default to staying in our modules") either moves into that section, moves out of the repo, or gets rewritten
neutrally.

## Maintaining one

- **Correct a stale fact where it lives.** Measured numbers, file counts and inventories drift — when you notice,
  fix the line rather than adding a caveat next to it.
- **No pointers the next reader can't open** — local absolute paths, machine-local memory files, plan files that
  get deleted, ticket numbers. Inline the load-bearing content instead.
- **Prefer relative paths** so the file survives a differently-laid-out checkout.
