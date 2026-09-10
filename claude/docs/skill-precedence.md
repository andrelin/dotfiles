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

## The `superpowers` plugin, specifically

**Use it.** Twelve of its fourteen skills never touch git at all — `test-driven-development`,
`systematic-debugging`, `brainstorming`, `dispatching-parallel-agents`, `verification-before-completion` and the
rest are technique the personal skills don't cover, and nothing here discourages reaching for them.

Only two carry anything to watch, and only one of those reaches a remote:

| Skill | What to watch |
| --- | --- |
| `superpowers:finishing-a-development-branch` | its final step is `git push -u origin <branch>` and then opening a PR/MR |
| `superpowers:writing-plans` | commits between steps, and uses its own plan format |

Two personal skills cover the same ground and carry this user's conventions, so on a collision invoke those:
`writing-plans` rather than `superpowers:writing-plans`, and `reviewing-locally` rather than
`superpowers:requesting-code-review`, whose findings must not reach the platform on company or customer work.

**§ *Work contexts* outranks every skill**, whoever wrote it — a step is not permitted by being written down.
So on **personal work every part of all of this is fine**, push included.
On **company and customer work** stop where the branch-finishing skill would push or open an MR: draft the
commands and the message, hand back, and take any other option in its menu.
What a skill may do to *local* history — its merges, or the commit step in `superpowers:writing-plans` — is
whatever that section's own list allows.
