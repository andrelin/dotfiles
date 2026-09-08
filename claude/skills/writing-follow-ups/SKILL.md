---
name: writing-follow-ups
description: Read before a review or reorganise run on a personal follow-up tracker - conventionally follow-ups.md at the root of a project or customer tree - and before renumbering, deleting resolved items, merging or splitting them, or reconciling open MRs against it. Not for plan files.
---

# Writing follow-ups

How to maintain a **follow-up tracker** — conventionally `follow-ups.md` at the root of a project or customer tree,
holding cross-cutting items that don't belong to any one MR.
It is **not** a plan file — it outlives MRs and is never deleted
(see the *Plan files are temporary* rule in `~/.claude/CLAUDE.md`, from which this file is a standing exception).

**The tracker is the user's, not Claude's.**
Its visible body is the user's own list of things to not forget — keep it clean and human-readable.
Anything Claude needs to *maintain* the tracker (last-reviewed date/SHA, review mechanics, pointers to this file)
goes in the **HTML comment at the top of the tracker** — out of the user's rendered view — or here in this how-to,
never in the visible body.
Small trigger/pointer comments that keep Claude from forgetting to consult the right doc are welcome,
as long as they stay out of the user's way (i.e. an HTML comment).

**Only the default branch counts.**
An item is solved/implemented only once it has landed on the default branch (`main`) —
that branch is the single source of truth for "done".
A feature branch is noted in the tracker (with its branch name in the heading) but **never** counts as finished,
no matter how complete the branch looks.
So an item is deleted only when its change is verifiably on `main`, and a 🔀 pending-merge item stays open until then.

## What belongs in it

Cross-cutting / out-of-lane items that don't fit one MR you're currently writing:
things another team owns, deferred cleanups, architectural risks, open questions for the team,
and pending-merge branches worth tracking.
Not: work already captured in a live plan file, or anything a single in-flight MR fully resolves.

**Also registers every open MR the user owns.**
Each open MR gets an item (or maps onto an existing one) with its `!NNN` in the heading + `MR / branch` table column,
`(draft)` where applicable.
When an MR **merges** (lands on the default branch) or is **closed**, remove its item — same delete-when-done rule.
When mapping MRs from a screenshot/list, match each to a branch (`git log -1 origin/<branch>` by title)
and note the mapping in the top HTML comment so the next run can reconcile.

## Review-run workflow (what "review the follow-ups" means)

1. **Fetch the fresh default branch first.**
   Use the worktree that's on `main` (check `git -C <dir> rev-parse --abbrev-ref HEAD`); `git fetch origin main`;
   confirm `HEAD == origin/main`.
   Update the reviewed date and main SHA in the tracker's top HTML comment.
2. **Check every item against main.**
   For pending-merge branches, `git merge-base --is-ancestor origin/<branch> origin/main` tells you if it merged —
   but verify the *actual code state on main*, because content can land via a squashed/renamed commit
   while the branch still shows commits ahead. Grep the real files; don't trust the branch name.
3. **Delete resolved items outright** — don't check them off. The list is always just what's still open.
4. **Merge / split so each item = one MR or one conversation.**
   Two items that are the same branch → merge.
   One item bundling several independent changes → split (and put a UI-wiring piece next to its backend item).
5. **Regroup by theme and renumber.** Related items share a section; renumber `section.item` from scratch each run.

## Structure

- **Top HTML comment (Claude only):** the maintenance pointer to this skill + last-reviewed date/SHA.
  Invisible in the user's rendered view.
- **Per-item HTML comments (Claude only):** attach bookkeeping to an item as an `<!-- … -->` comment right under its
  heading — most usefully a "verify on main" hint (which file/symbol to grep to tell if it landed)
  and merge/split provenance ("don't re-split"). Invisible when rendered, so it never clutters the user's list.
- **Header (user-facing):** one-line purpose, the "only the default branch counts" reminder, the badge legend,
  and the "refer to items by number" note. No SHAs or review bookkeeping.
- **At-a-glance table:** `Ref | Item | Type | Next step | Branch` — one row per open item,
  so the whole tracker is skimmable without scrolling.
- **Themed sections** (`## N · Title`), each with items (`### N.M · Title <badge> <branch?>`).
- **Every item leads with a `→` line** stating the single concrete next step (merge / ask X / add dep / decide).
  Rich detail goes in bullets below it — skim the `→`, dive when acting.

## Common mistakes

- **Checking an item off instead of deleting it.** The list is what's still open; a done item is noise in it.
- **Trusting the branch name.** Content lands via squashes and renames — grep the files on `main` (step 2).
- **Treating a green feature branch as done.** Only the default branch counts, however finished the branch looks.
- **Putting review bookkeeping in the visible body.** SHAs, dates and merge provenance go in the HTML comments.
- **Treating item numbers as stable IDs.** They're reassigned every run — cross-reference within the tracker,
  never from outside it.
- **Letting an item bundle several changes.** One item = one MR or one conversation, or the `→` next step can't
  be a single action.

## Conventions

- **Numbering is `section.item` (2.1, 5.4), reassigned every review run.**
  Stable only while actively working an item, never a permanent ID.
  Keep issue-tracker refs (`#373`) visually distinct — they're not item numbers.
- **Type badges:** 🔀 pending MR (branch ready) · 🐛 bug, no branch yet · 🧹 cleanup/refactor ·
  💬 needs a team decision first · 🔨 new build (other repo) ·
  👀 another dev's MR the user is to review (not theirs to implement).
- **Pending-merge items carry their branch name** in the heading — that's the only marker they need,
  since the "only the default branch counts" rule governs when they're deleted.
- **Cross-reference items by number** ("Couples to 5.4"), not by retyping the title.
- Terse and fact-dense, but keep the hard-won detail (root causes, guards, test names, file:line) —
  this tracker is also the memory of *why* each thing is the way it is.
- Markdown: semantic line breaks, 150-char cap (per `~/.claude/CLAUDE.md`).
