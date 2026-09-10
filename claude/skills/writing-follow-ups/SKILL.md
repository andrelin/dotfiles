---
name: writing-follow-ups
description: Read before a review or reorganise run on a personal follow-up tracker - conventionally follow-ups.md at the root of a project or customer tree - and before renumbering, deleting resolved items, merging or splitting them, or reconciling open MRs against it. Not for plan files.
---

# Writing follow-ups

How to maintain a **follow-up tracker** — conventionally `follow-ups.md` at the root of a project or customer
tree, holding cross-cutting items that belong to no single MR.
It is **not** a plan file: it outlives MRs and is never deleted, making it a standing exception to
*Plans are temporary* in the `writing-plans` skill.

**The tracker is the user's, not Claude's.** Its visible body is their own list of things not to forget, so keep
it clean and human-readable. Everything Claude needs in order to *maintain* it — last-reviewed date and SHA,
review mechanics, pointers to this skill — goes in an HTML comment, out of the rendered view, never in the body.

**Only the default branch counts.** An item is done only once its change has landed on `main`; that branch is the
single source of truth. A feature branch is noted in the heading but never counts as finished, however complete
it looks, so a 🔀 pending-merge item stays open until the code is verifiably on `main`.

## What belongs in it

Cross-cutting items that don't fit the MR you're writing: things another team owns, deferred cleanups,
architectural risks, open questions, pending-merge branches.
Not work already captured in a live plan file, or anything one in-flight MR fully resolves.

**It also registers every open MR the user owns**, each with its `!NNN` in the heading and the `MR / branch`
column, `(draft)` where applicable, removed once the MR merges or closes.
Mapping MRs from a screenshot or list: match each to a branch (`git log -1 origin/<branch>` by title) and record
the mapping in the top HTML comment so the next run can reconcile.

## Review-run workflow (what "review the follow-ups" means)

1. **Fetch the fresh default branch first**, from the worktree that's on `main`, and confirm `HEAD == origin/main`.
   Update the reviewed date and SHA in the tracker's top HTML comment.
2. **Check every item against main.** `git merge-base --is-ancestor origin/<branch> origin/main` says whether a
   branch merged, but verify the *code state on main*: content lands via squashed or renamed commits while the
   branch still shows commits ahead. Grep the real files.
3. **Delete resolved items outright** — don't check them off. The list is always just what's still open.
4. **Merge or split so each item is one MR or one conversation.** Same branch twice → merge; one item bundling
   independent changes → split, keeping a UI-wiring piece next to its backend item.
5. **Regroup by theme and renumber** `section.item` from scratch.

## Structure

- **Top HTML comment (Claude only):** the maintenance pointer to this skill + last-reviewed date/SHA.
  Invisible in the user's rendered view.
- **Per-item HTML comments (Claude only):** bookkeeping under an item's heading — a "verify on main" hint (which
  file or symbol to grep) and merge/split provenance ("don't re-split"). Invisible when rendered.
- **Header (user-facing):** one-line purpose, the "only the default branch counts" reminder, the badge legend and
  the "refer to items by number" note. No SHAs or review bookkeeping.
- **At-a-glance table:** `Ref | Item | Type | Next step | Branch`, one row per open item, so the tracker is
  skimmable without scrolling.
- **Themed sections** (`## N · Title`), each with items (`### N.M · Title <badge> <branch?>`).
- **Every item leads with a `→` line** stating the single concrete next step (merge / ask X / add dep / decide).
  Rich detail goes in bullets below it — skim the `→`, dive when acting.

## Common mistakes

- **Checking an item off instead of deleting it.** The list is what's still open; a done item is noise in it.
- **Trusting the branch name.** Content lands via squashes and renames — grep the files on `main` (step 2).
- **Treating a green feature branch as done.** Only the default branch counts, however finished the branch looks.
- **Putting review bookkeeping in the visible body.** SHAs, dates and merge provenance go in the HTML comments.
- **Treating item numbers as stable IDs.** Reassigned every run — cross-reference inside the tracker only.
- **Letting an item bundle several changes**, so the `→` next step can't be a single action.

## Conventions

- **Numbering is `section.item` (2.1, 5.4), reassigned every review run** — stable only while actively working
  an item. Keep issue-tracker refs (`#373`) visually distinct; they aren't item numbers.
- **Type badges:** 🔀 pending MR (branch ready) · 🐛 bug, no branch yet · 🧹 cleanup/refactor ·
  💬 needs a team decision first · 🔨 new build (other repo) ·
  👀 another dev's MR the user is to review (not theirs to implement).
- **Pending-merge items carry their branch name** in the heading — the only marker they need.
- **Cross-reference items by number** ("Couples to 5.4"), not by retyping the title.
- Terse and fact-dense, but keep the hard-won detail (root causes, guards, test names, `file:line`) — the tracker
  is also the memory of *why* each thing is the way it is.
- Markdown: semantic line breaks, 150-char cap (per `~/.claude/rules/markdown-limits.md`).
