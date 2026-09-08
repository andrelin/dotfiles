---
name: writing-claude-md
description: Read before creating a CLAUDE.md, before adding or reworking a section in one, and when deciding whether a new rule belongs in CLAUDE.md, a skill or a reference doc. Covers audience, the cost of a line that loads every session, and what must stay out of a shared repo.
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

## Keep personal context out — it goes in `CLAUDE.local.md`

Personal context is anything tied to one person: their team or role, what the agent may do on their behalf,
their personal files and trackers, their standing preferences.

**The default home is a `CLAUDE.local.md` beside the `CLAUDE.md`**, kept out of git.
Claude Code loads it automatically and appends it *after* the `CLAUDE.md` in the same directory, so the personal
half is the last thing read at that level and wins on any conflict.
Nothing personal reaches the history, and the shared file stays adoptable by anyone.

**How you keep it out of git depends on whose repo it is:**

- **A repo the user owns** — add `CLAUDE.local.md` to `.gitignore` and commit that line.
  It also tells the next person the convention exists.
- **A customer's or an employer's repo** — use `.git/info/exclude` instead.
  It ignores the file per-clone and is never committed, where editing their `.gitignore` would commit a personal
  filename into their history — the leak this whole section exists to prevent.
  Leaving it untracked and unignored is not the third option: it shows up in every `git status` and gets staged
  by accident.

That replaces the older habit of gathering personal context into a marked section of the committed file.
Reach for that only where no local file can be used at all, and then keep it to one clearly-marked section
rather than sprinkling it through.

**Where to put it when the project spans git worktrees.** A gitignored `CLAUDE.local.md` exists only in the
worktree that created it, so one per worktree means three copies drifting apart.
Two ways out, in order of preference:

- **Put it in a directory *above* the worktrees** — a customer or project tree root. Every `CLAUDE.md` and
  `CLAUDE.local.md` from the working directory upward is loaded, so one file there covers every worktree below it.
- **Import a home-directory file** from the local file: `@~/.claude/<project>-instructions.md`.
  Note that an import in a *project*-level file resolving outside the working directory triggers a one-time
  approval dialog; declining disables it permanently for that project.

**`~/.claude/CLAUDE.md`** stays the home for anything that holds across every project rather than this one.

The same test applies to the rest of any `CLAUDE.md`: a sentence that only makes sense from one person's seat
("default to staying in our modules") either moves to the local file, moves out of the repo, or gets rewritten
neutrally.

A shared `CLAUDE.md` that has a local counterpart should say so, in one line, so the next person creates theirs
instead of editing the shared file — and so the sections that refer back to it still read on their own.

## The excuses for adding a section

Every line here loads on every task in the project, forever. That cost is invisible at the moment of writing,
which is why the file grows.

| Excuse | Reality |
| --- | --- |
| "This is important, so it belongs in CLAUDE.md." | Importance isn't frequency. Important-but-occasional is a skill. |
| "The agent keeps forgetting, so I'll repeat it." | Repetition dilutes rather than reinforces. Find why the first statement didn't bind. |
| "It's only a few lines." | Multiplied by every session in the project's life. Skills cost nothing until they match. |
| "A skill might not trigger." | Then the `description` is wrong. Fix the trigger — that's cheaper than a permanent tax. |
| "I'll tidy it up later." | Nothing forces the tidy-up, and a stale rule is followed as confidently as a live one. |

## Maintaining one

- **Correct a stale fact where it lives.** Measured numbers, file counts and inventories drift — when you notice,
  fix the line rather than adding a caveat next to it.
- **No pointers the next reader can't open** — local absolute paths, machine-local memory files, plan files that
  get deleted, ticket numbers. Inline the load-bearing content instead.
- **Prefer relative paths** so the file survives a differently-laid-out checkout.
