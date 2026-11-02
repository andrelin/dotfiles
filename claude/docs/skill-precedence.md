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
The shadowing runs only while the personal skill exists: with it missing — `bin/skill-trigger-eval` moves one out for a run —
the same-named plugin skill answers the slash command silently (`/writing-plans` ran `superpowers:writing-plans`).
A run that reads like the plugin's is checked for a missing personal skill.

## The `superpowers` plugin, specifically

**Use it.** The counts here are against superpowers 7.0.0.
It has 15 skills: the 9 in the table below need adapting at customer level, and these 6 never write history or a remote:
`dispatching-parallel-agents`, `requesting-code-review` (at most a local worktree; it never writes history or a remote),
`systematic-debugging`, `test-driven-development`, `verification-before-completion`, `using-superpowers`
(its `references/codex-tools.md` commits and pushes, but only as Codex instructions, which never load in Claude Code).

| Skill | On customer work |
| --- | --- |
| `brainstorming` | Add `/plan-*.md` to the exclude file first, then write the spec as `plan-<slug>-spec.md`, not the plugin's path; don't commit it. |
| `writing-plans` | Use the personal `writing-plans`; never follow the plugin's commit steps. |
| `executing-plans`, `subagent-driven-development` | Use the personal `implementing-plans`; see below the table. |
| `using-git-worktrees` | Worktrees and branches are fine. Ignore `.worktrees` via `$(git rev-parse --git-path info/exclude)`, never `.gitignore`. |
| `finishing-a-development-branch` | A clean local merge into base, its `git pull` included, is fine; on any conflict `--abort` and hand back; stop before push or PR. |
| `writing-skills` | Its "commit and push to your fork" step is personal-only; draft a PR to the upstream repo for the user at any level. |
| `receiving-code-review` | Draft the *GitHub Thread Replies* (`gh api …/replies`) for the user and post nothing, per the global § *Code review*. |
| `diagnosing-superpowers` | Never file an upstream issue from a company or customer session, scrubbed or not; from a personal one, draft it. |

`brainstorming`'s spec is a plan file, but never input to `implementing-plans`.
`executing-plans` and `subagent-driven-development` are replaced by the personal `implementing-plans` *at every level*:
it keeps their loop and checkpoints in the index instead of committing, and the commit waits for the user.
On company work the rows don't apply, since company keeps personal-level rights, bar drafting an upstream PR or issue
(`writing-skills`, `diagnosing-superpowers`), which holds at every level.
`finishing-a-development-branch` there pushes and opens the PR but merges into `main` only after `/code-review` at least and green CI
— never a push straight to `main`.

Personal counterparts of `superpowers:requesting-code-review`: `reviewing-in-rounds` for the user's own work and
`reviewing-for-feedback` for someone else's, with `reviewing-locally` as their customer setup.
`tuning-skill-descriptions` owns trigger wording, `writing-agent-instructions` decides where an instruction lives,
its length budget and its front matter, and `superpowers:writing-skills` stays the one for testing a skill.

**§ *Work contexts* outranks every skill**, whoever wrote it — a step is not permitted by being written down.
So on **personal and company work every part of all of this is fine**, push included
— except that the workflow skills commit only after the user's yes, and company work reaches `main` only reviewed and green.
On **customer work** stop where the branch-finishing skill would push or open an MR: draft the
commands and the message, hand back, and take any other option in its menu.
On customer work the only local history a skill may write is a clean, zero-conflict merge or rebase; on a conflict, `--abort` and hand back.
The work-context hook blocks the forbidden steps on customer targets regardless, never on a third-party one, which it rates company,
so the table is about *adapting* a skill rather than failing.

## Overlaps that both fire

- `proving-causes` and `superpowers:systematic-debugging` are complementary: process versus the evidence bar.
- `writing-tests` and `superpowers:test-driven-development` are complementary: when to write a test versus which tests are worth keeping.
- `reviewing-locally` and `reviewing-for-feedback` both fire on a colleague's customer branch:
  `reviewing-for-feedback` runs the review and takes only `reviewing-locally`'s fetch step and no-posting rule, never its rebase or a checkout.
  `reviewing-in-rounds`, on the user's own work, takes only its fetch step, never its rebase, which a tree with uncommitted work can't take.
- `tuning-skill-descriptions` and `skill-creator` (seen as `skill-creator:skill-creator` and `anthropic-skills:skill-creator`)
  both fire on a description change: the personal skill wins,
  and `skill-creator` is read only for `run_eval.py`, never its pushy-summary advice or `run_loop`.
