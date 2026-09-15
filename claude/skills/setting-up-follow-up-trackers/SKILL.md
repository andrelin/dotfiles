---
name: setting-up-follow-up-trackers
description: Read before creating a follow-up tracker in a project or customer tree, before splitting a single tracker file into the backlog / in-flight pair, and before changing what is fixed once per tree - the file names, the ref letters, the host's PR sigil and the user-facing header. Adding an item is `writing-follow-up-items`; the periodic review run, which owns the top comment and the at-a-glance table, is `maintaining-follow-up-trackers`.
---

# Setting up a follow-up tracker

The layer decided once per tree: what the files are called, how their refs read, and the header each carries.
The reasoning lives here rather than in the tracker, so it isn't relitigated at every review run.
What a run rewrites every time — the top HTML comment, the at-a-glance table, the in-flight heading — is
`maintaining-follow-up-trackers`.

## Naming the pair

`00-follow-ups-backlog.md` and `00-follow-ups-in-flight.md`, at the root of the tree.

Name the halves **symmetrically, sharing a prefix**, so they sort next to each other and neither reads as the
leftover of the other.
`backlog` / `in-flight` says what is inside without knowing the split rule, where a bare `follow-ups.md` beside
`follow-ups-prs.md` does not — the second name only makes sense once you know the first excludes PRs.
The numeric prefix (`00-`) sorts the pair to the top of the directory, worth the two ugly characters on a tree the
user opens daily.

**One file is fine for a tree with little in flight.** Split it when the in-flight items start crowding out the
rest: the two halves are read at different moments, and the point of the split is that "what is waiting on me
today" stops burying "what still needs doing".

## Choosing the ref letters

`B2.3` in the backlog, `F1.1` in flight by default, on sections too (`## F2 ·`, `§B4`), so a reference says which
list it is with no qualifying sentence after it.
The letter has to be decodable from the file it appears in: `B` and `F` are, where an `M` for "merge request" is
not — a prefix nobody can decode is a footnote waiting to happen.

## The header each file carries

One-line purpose, the pointer to the sibling file, the "only the default branch counts" reminder, the badge
legend, and one line saying how items are numbered and which id to cite.
No SHAs or review bookkeeping — that lives in the top HTML comment, which the review run owns.

## The host's word for a PR

The skills say PR throughout whatever the host calls it.
The tracker itself uses the host's own word and sigil — GitLab merge request `!412`, GitHub pull request `#412`,
a Gerrit change number — consistently within one tree.
Where the host numbers PRs and issues in one space, as GitHub does, an unqualified `#412` is ambiguous: write
`PR #412` against `issue #373`, or keep whatever prefix the repo's own commit log already uses.

Markdown: semantic line breaks, 150-char cap (per `~/.claude/rules/markdown-limits.md`).
