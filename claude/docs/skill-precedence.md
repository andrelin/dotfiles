# Skill precedence — what shadows what, and what merely adds

The one-line rule is in `~/.claude/CLAUDE.md` § *Working on code*.
This file is the detail, and matters mainly when adding or naming a skill.

| Source | Where | Against a same-named skill elsewhere |
| --- | --- | --- |
| **Personal** | `~/.claude/skills/` — this repo's `claude/skills/` | **shadows** the project's, which then does not appear at all |
| **Project** | a repo's own `.claude/skills/` | loses to a personal skill of the same name |
| **Plugin** | namespaced `plugin:skill` | never collides — it loads alongside |

**A name added to `claude/skills/` is claimed in every repo the user ever opens**, and a shadowed project skill fails silently:
it simply isn't listed, which reads as "the repo didn't define one".
So name a personal skill for the general method, and leave the obvious project-level names free —
a repo that wants its own `writing-tests` or `deploy` should be able to have one.

**Where a plugin skill covers the same ground as a personal one, invoke the personal one.**
It carries this user's conventions and the permission rules; a plugin skill knows neither.
Read a plugin skill for technique, never for what is allowed.

**§ *Work contexts* outranks every skill**, whoever wrote it.
A skill's steps do not become permitted by being written down: if a step pushes, or opens, merges or closes an MR,
it is out of reach on company and customer work — draft the commands and the message, and hand back.
What a skill may do to *local* history is whatever that section's own list allows.
Plugin skills that walk a branch to completion or run a red/green/commit loop will propose exactly these steps,
so expect it rather than being surprised by it.
