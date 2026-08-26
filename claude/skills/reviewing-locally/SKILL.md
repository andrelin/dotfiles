---
name: reviewing-locally
description: Set up a code review correctly on customer or company work - fetch the default branch, diff against it so the merge-base isn't stale, rebase the branch first when it's behind, and stay in the local clone rather than the hosting platform's API or web UI. Read before reviewing a branch, MR or PR, including before running the built-in /code-review, whose target and findings depend on the diff being set up right.
---

# Reviewing a branch locally, against a freshly fetched default branch

**Customer and company work only.** On personal projects, review however you like — the remote is yours.

## Works alongside `/code-review`, not instead of it

`/code-review` finds the bugs. This skill makes sure it's looking at the right diff, and that nothing it does
touches the remote. Run this setup **before** invoking it, and carry these constraints through the run:

- **The target is a local ref**, resolved against a freshly fetched default branch — not a PR fetched through the
  platform's API.
- **`--comment` and any other posting flag are off** unless the user has explicitly said the agent may write to the
  platform. On an engagement where the user owns the remote, findings come back in the conversation and the user
  posts them.
- If the project bans the platform CLI outright (`gh` / `glab` / `az`), that ban holds inside a `/code-review` run
  too. The clone has everything the review needs.

**Don't rely on this skill loading during a `/code-review` run** — invoking a skill by name loads that skill, not
this one. The constraints above are duplicated into `CLAUDE.md` for exactly that reason. A cloud run
(`/code-review ultra`) is further out of reach again: assume it carries neither local skills nor local `CLAUDE.md`,
and check what it is allowed to post before using it on an engagement where the user owns the remote.

## Set up the diff

1. **Fetch the default branch first:** `git fetch origin main`.
2. **Diff against it:** `git diff origin/main...HEAD` — the three-dot form, so you see the branch's own changes
   rather than everything that has landed on main since it forked.
3. **If the branch is behind, rebase it onto `origin/main` before reviewing** — only when it replays with zero
   conflicts. On any conflict, `git rebase --abort` and ask the user to rebase before the review continues.

**Why:** a diff against a stale merge-base shows changes that landed on the default branch as if the author made
them, which wastes review effort on code nobody in the MR wrote — and it hides conflicts the author still has to
resolve. Rebasing first is also what the author will have to do anyway, so a clean replay is information.

## Read it from the clone

`git diff`, `git log`, `git show`, `git blame` — everything a review needs is local, and reading it there means
the review can look at the surrounding code and the file's history, not just the changed hunks the web UI shows.
