# Work contexts — the detail behind the four levels

The resolution order, the permission lists and the one-approval rule are in `~/.claude/CLAUDE.md`
§ *Work contexts*, because they have to be loaded before the first git command runs.
This file carries the reasoning and the edge cases.

## Why the levels nest

Each level keeps the ones above it with the audience substituted.
Level 2's bar is *safe for anyone*; at 3 and 4 the same bar binds with "anyone" narrowed to colleagues, or to the client.
A customer repo being private makes the reader smaller, not the care looser.

## Why the resolution order is what it is

- The company org is checked first because it is not the personal account and would otherwise fall to customer.
- The company name marker catches employer work that lives on the personal account instead of the org.
  Both are company work, so both get the company rules.
- Customer work is defined by *exclusion*, so the rule keeps working for a new customer with no edits.
- **Both unknowns resolve upward.** An unreadable remote is customer; a repo whose visibility you can't determine is public.
  Guessing low is the only guess that can't be taken back.
- **Never infer the level from the directory path.** Repo locations differ between machines — `~/src/foo` on one, `~/src/<group>/foo` on another.

## personal private — full autonomy

Commit, push, rebase, open PRs, merge PRs, full `gh` access.
Nothing leaves the user's own account, so the only bar is not committing secrets you'd rather not have in a history at all.

## personal public — full autonomy, but every commit is published

Same git permissions as private.
What changes is that the working tree and the **whole history** are world-readable and effectively permanent —
deleting a file later does not unpublish it.

Before committing, check the change carries none of:

- Customer names, their project names, internal tooling, hostnames or URLs.
- Secrets, tokens, keys — including in files that merely *look* like config.
- Anything from a customer tree that wandered in.

**Why:** the cost is asymmetric.
A missing rule costs a follow-up commit; a published one costs a history rewrite across every branch,
and every existing clone and fork keeps it anyway.

## company — personal freedom over the code, customer care over what is published

Demos, presentations, and teaching material.
The split is what an audience will see: **the code** is the user's to refactor and restructure as freely as any personal project,
but **the history and the remote** are part of the material and belong to the user.
That middle position is the whole category, not an exception to it.

**Why:** demo repos are walked through live in front of an audience, so anything committed is on screen.
Project context still belongs in the repo — that is the multi-machine rule — but the user's own personal context stays out.

## customer — user owns the remote, careful by default

These are the **user's own defaults** for client work, not rules imposed by any client.
They exist because someone else's codebase is the wrong place to be surprising.
An engagement's own `CLAUDE.md` sits closer to the work and overrides anything here, in either direction —
read it at the root of that customer's tree before starting.

- Claude prepares the working tree; the user composes history and does every remote write.
- The rule is about *effect on history*, not command names.
  A rebase or merge that mints new content during conflict resolution violates it just as much as `git commit`.
- Prefer the local clone over the hosting platform's CLI (`gh`, `glab`, `az`, …) for reads and writes.
  Everything needed for the work is in the clone, and the user drives the platform themselves.
- The user keeps per-engagement permission rules alongside the engagement's own config; they apply to every subdirectory.

**When in doubt, use these defaults.** Relax only once the remote confirms personal or company work.

## An approval covers one action, not a policy

When the user waives a rule — "skip the PR this time", "push it" — that applies to the change in front of them and expires with it.
Approving the *content* of the next change ("yes, remove that line") is not approval to deliver it the same way.
Ask again, every time, however recently they said yes and however similar the next one looks.
This binds hardest where a repo's own `CLAUDE.md` sets the rule being waived — that file governs, and a one-off exception does not amend it.
