---
name: maintaining-follow-up-trackers
description: Read before a review or reorganise run over a personal follow-up tracker - "review the follow-ups" - and before renumbering, deleting resolved items, merging or splitting them, moving one between the backlog and in-flight halves, or reconciling open PRs against them. Writing or rewording a single item is `writing-follow-up-items`; creating the files is `setting-up-follow-up-trackers`. Not for plan files.
---

# Maintaining a follow-up tracker

A review run reconciles the tracker against the code and leaves it holding only what is still open.
What an item looks like, and which half it belongs in, is `writing-follow-up-items`.

**Only the default branch counts.** An item is done only once its change has landed on `main`; that branch is the
single source of truth. A feature branch is noted in the heading but never counts as finished, however complete
it looks, so an item stays open until its code is verifiably on `main`.

**Keep the bookkeeping out of the visible body.** The reviewed date and SHA, the PR↔branch mapping and the
merge/split provenance go in the HTML comments; the body stays the user's own readable list.

## The run, in order

1. **Fetch the fresh default branch first**, from the worktree that's on `main`, and confirm `HEAD == origin/main`.
   Update the reviewed date and SHA in the top HTML comment.
2. **Check every item against main, part by part** — a merged PR can carry only some of one. `git merge-base
   --is-ancestor origin/<branch> origin/main` says whether a branch merged, but verify the *code state on main*:
   content lands via squashed or renamed commits while the branch shows commits ahead. Grep the real files.
   **Where the item carried a plan, always verify against the plan** — its tasks and per-task file lists are the
   written record of what the item's parts were, where the item body only summarises them.
3. **Delete items whose code is on `main`** (step 2) outright — don't check them off; the list is always just
   what is still open. **Partly landed is not done:** rewrite the item to cover only what is missing and move it
   to the backlog. Anything dropped on purpose rather than left behind is step 5's question, not a deletion here.
4. **Re-measure every branch's ahead/behind** against the fetched `origin/main` and correct the `→` lines; a
   "behind 5" from last week is the kind of stale fact that gets acted on.
5. **Sweep the pair for items in the wrong half.** In flight is a standing condition, so check each PR and plan
   is still active rather than that it once was. PR opened, or plan reviewed and ready → into the in-flight file.
   A plan still under review has not qualified; a plan deleted because its work shipped means the item is done, so
   verify it on `main` and delete it. **A closed PR or an abandoned plan is a question, not a decision:** the work
   was most likely dropped and the item deleted with it, but that is the user's call. Collect them and put both
   options to the user before the run finishes; the rest of the run carries on meanwhile.
6. **Merge or split so each item is one PR or one conversation.** Same branch twice → merge; one item bundling
   independent changes → split, keeping a UI-wiring piece next to its backend item.
7. **Regroup by theme and renumber** `<letter><section>.<item>` from scratch in both files, fixing references.

**Verify before you re-file.** A finding that has sat for a week may be unreachable, already fixed, or refuted by
the code as it stands — read the source before restating it, and say which items the run re-verified and which it
left alone.

**Every open PR the user owns has an item in the in-flight half** by the end of a run — the sweep is what
guarantees it, since writing one item can't know about the rest.
**Reconciling PRs from a screenshot or list:** match each to a branch (`git log -1 origin/<branch>` by title) and
record the mapping in the top HTML comment so the next run can pick it up.

## What the run rewrites above the sections

- **Top HTML comment (Claude only):** the pointer to these skills, the last-reviewed date and SHA, the PR↔branch
  mapping, and which sibling this file is. Invisible in the user's rendered view.
- **At-a-glance table:** rebuilt whenever items are deleted or renumbered — one row per open item, carrying ref,
  title, its type badge, and the facts that place it (PR number or plan file, issue number and branch in flight).
  **Carry the section headings into it** as bold rows (`| **2** | **Hit verification** | |`), grouping as it does.
  **No next-step column:** it restates the item's own `→` line, and the copy that isn't being acted on goes stale.
- **The in-flight heading**, rewritten whenever an item moves into that half:
  `F<n>.<m> · <PR ref> · <issue refs> · what it does · branch`, `(draft)` on the PR number, and `→ <PR ref>` where
  the branch is stacked on another PR rather than the default branch. An item in flight on a reviewed plan has
  neither PR nor branch: it names the plan file in their place, and gains the PR ref when one opens.

## Common mistakes

- **Checking an item off instead of deleting it.** The list is what's still open; a done item is noise in it.
- **Trusting the branch name, or a merge to have landed the whole item.** Content lands via squashes and
  renames, and a PR can merge a subset — grep the files on `main`, part by part (step 2).
- **Treating a green feature branch as done.** Only the default branch counts, however finished the branch looks.
- **Renumbering one file and not the other.** Cross-file references go stale silently; grep both after a renumber.
- **Putting review bookkeeping in the visible body.** SHAs, dates and merge provenance go in the HTML comments.
- **Treating refs as stable IDs.** `B2.3` is reassigned every run — cite the PR number in anything that has to
  survive, and cross-reference refs inside the tracker only.
- **Restating an old finding as fact.** Re-read the code; say plainly when a run did not.
- **Retiring a dropped item on your own.** A closed PR or abandoned plan is deleted or demoted only once the user
  has said which — it is the one point in a run that is not Claude's to decide.
- **Leaving an item in the wrong half.** In flight means an active PR, an active reviewed plan, or a meta item;
  anything else is backlog, however close to starting it feels.

Markdown: semantic line breaks, 150-char cap (per `~/.claude/rules/markdown-limits.md`).
