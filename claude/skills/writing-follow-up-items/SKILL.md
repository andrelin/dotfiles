---
name: writing-follow-up-items
description: Read before adding an item to a personal follow-up tracker or rewording one - capturing something that belongs to no single PR, choosing which half of the backlog / in-flight pair it goes in, and giving it its heading, issue reference, next-step line and badge. The periodic review run over a whole tracker is `maintaining-follow-up-trackers`; creating the files is `setting-up-follow-up-trackers`. Not for plan files.
---

# Writing a follow-up item

A **follow-up tracker** sits at the root of a project or customer tree and holds cross-cutting items that belong
to no single PR.
It is **not** a plan file: it outlives PRs and is never deleted, making it a standing exception to
*Plans are temporary* in the `writing-plans` skill.

**The tracker is the user's, not Claude's.** Its visible body is their own list of things not to forget, so keep
it clean and human-readable. Everything Claude needs in order to *maintain* it — last-reviewed date and SHA,
review mechanics, pointers to these skills — goes in an HTML comment, out of the rendered view, never in the body.

## What belongs in it

Cross-cutting items that don't fit the PR you're writing: things another team owns, deferred cleanups,
architectural risks, open questions, pending-merge branches — but not work already captured in a live plan file,
or anything one in-flight PR fully resolves. **Both halves keep numbered themed sections**; what differs between
them is only how an item is identified.

## Which half it goes in

| File | Holds |
| --- | --- |
| `00-follow-ups-backlog.md` | everything not in flight — bugs, cleanups, decisions, hand-offs |
| `00-follow-ups-in-flight.md` | every open PR and every review-ready plan, one item each, plus meta items |

- **In flight means a PR, a review-ready plan, or a meta item.** A plan counts once written, independently
  reviewed per `writing-plans` and ready to implement as it stands; an unreviewed draft is backlog. A **meta
  item** is work on the tracker itself, such as a handover triage, in its own section saying why it has no PR.
- **In flight is a standing condition, not a stage reached.** An item moves in the day it qualifies and stays only
  while that PR or plan stays active. A closed PR or abandoned plan usually means the work was dropped and the
  item goes with it — but **ask the user** whether it is deleted or returns to the backlog; never pick silently.
- **An in-flight item names its PR in the heading**, or its plan file where the plan is what put it there, with
  `(draft)` where applicable and the PR it is stacked on when it does not target the default branch.
- **Only the default branch counts**: an item stays open however finished its branch looks, and names that branch.

## Issue and PR references

**A known issue or ticket number goes in the item's heading, in either half** — beside the PR reference, or alone
where there is no PR yet. It is the one id that outlives the branch, the PR and the item number.
One issue routinely spans several PRs and one PR can answer several issues, so put the reference on **every** item
that serves it. An issue that is merely *context* ("shipped by #442") stays in the body — a heading reference
means *this item is that issue*.
**Import a current issue's content; record a stale one's number only.** Where the issue still describes what is
wanted, fold its substance into the item — acceptance criteria, constraints, who asked — so the item stands alone.
Where it predates the current design, keep the number, don't restate wording that has been overtaken, and note in
the item that the issue is stale. Decide which by reading the issue against the code as it stands.

## The shape of a section and an item

- **Themed sections** (`## N · Title`) open with a **one- or two-line introduction** naming what ties the items
  together and why it is one theme — what the user reads returning cold — then the items
  (`### N.M · Title <badge> <branch?>`).
- **Every item leads with a `→` line** stating the single concrete next step (merge / ask X / add dep / decide),
  then bullets below it — skim the `→`, dive when acting. Those bullets follow one compact shape:
  **what the problem is · why it is a problem · how we might solve it**, a sentence each, all three always present.
  Where the fix isn't known, the third names the move that would settle it — the measurement, the person to ask,
  the code to read — never nothing. Detail earns its place by bearing on one of the three.
- **A settled decision or a trap already paid for gets one line, so it isn't relitigated or rediscovered** —
  *"decided: X, not Y"*, *"`forUpdate` is a no-op here"*. State the conclusion, never the history: what was tried
  in what order, who said what when, how the code got this way.
- **Never bundle several changes into one item**, or the `→` next step can't be a single action.
- **Per-item HTML comments (Claude only):** a "verify on main" hint (which file to grep), merge/split provenance.

## Conventions

- **Refs are `<letter><section>.<item>`** — by default `B2.3` in the backlog, `F1.1` in flight — and are
  reassigned every review run, so cross-reference them inside the tracker only ("Couples to B5.4"). **Cite the PR
  number** in anything that has to survive a run, or the plan file while an item has no PR. Say which where a
  host shares one number space (`PR #412`, `issue #373`).
- **Type badges, in both halves:** 🐛 bug · 🧹 cleanup/refactor · 💬 needs a team decision first ·
  🔨 new build (other repo) · 👀 another dev's PR the user is to review, not theirs to implement.
- **🔀 marks an in-flight item pending merge** — PR open, out of draft, waiting to land; a plan or draft has none.
- Terse and fact-dense, but keep the hard-won detail (root causes, guards, test names, `file:line`) — the tracker
  is also the memory of *why* each thing matters. That is the why of the **problem**, not a retelling of the past.
- Markdown: semantic line breaks, 150-char cap (per `~/.claude/rules/markdown-limits.md`).
