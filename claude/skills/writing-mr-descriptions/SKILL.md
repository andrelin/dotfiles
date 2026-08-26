---
name: writing-mr-descriptions
description: Shape, calibration and recurring smells for merge/pull request titles and descriptions, with a worked example. Read before writing or revising an MR or PR title or description, including a draft pasted into chat for the user to copy.
---

# Writing MR titles and descriptions

These are guidelines, not a template: they describe what a good description does, so apply judgement rather than filling in slots.
"MR" throughout means merge request or pull request — the advice is the same on GitLab and GitHub.

Language and title style: English, and match the form dominant in the repo's recent `git log`
(per `~/.claude/CLAUDE.md` § *Norwegian vs English*).

**Always carry the issue number in the title when the work has one.** Read `git log` to see which form the repo
uses — `<type> #<n>: <subject>` and a trailing `(#<n>)` are both common — and match it.
Never use a closing keyword (`closes` / `fixes` / `resolves`) — see `~/.claude/CLAUDE.md` § *Dependabot and Renovate PRs*
for why that matters around bot MRs.

**Never write bare angle brackets in a description.** GitLab and GitHub both render raw HTML, so placeholders like
`<id>`, `<title>` or `<name>` are parsed as tags — `<title>` in particular swallows the following markup and dumps
the rest of the list out as visible `</li>` text.
Use a concrete example in backticks (`` `2.1 – Title` ``) instead of a bracketed placeholder.

## Shape: why first, then what

Open with the **why** — what was wrong, missing or painful in *this* code. Then the **what**, framed as how it answers that why.

A reviewer who reads the change first has to reconstruct the motivation backwards, and after merge it's the motivation,
not the diff, that's been lost. So the why earns its place even when the what is obvious.

Not a mandate. A one-line fix ("bump X to 2.1, CVE") doesn't need two paragraphs, and some MRs are all why with a trivial what.

## Calibration

- **Length follows the change, not a quota.** Most MRs land in a few lines. A genuinely multi-part change can be longer —
  but if it keeps growing, that's usually the MR being too big, not the description being too thin.
- **Bullets when the change has distinct pieces**; prose when it's one idea. Reaching for many bullets is a signal to check
  whether the MR should be split.
- **Depth is set by what the diff doesn't show.** Include what a reviewer would otherwise have to reconstruct: why a second
  file is in the MR, why a structure looks unlike what it replaced, where behaviour or coverage moved to. Skip what reading
  the diff answers immediately.

## Smells — these have all had to be cut from real drafts

- **Shared knowledge as motivation** — "database tests are slow", "duplication is bad". Everyone here knows; it buries the
  part specific to this change. State what's true of *this* code and let the principle be assumed.
- **Who asked for it, or where it was discussed** — no Slack, no "X's ask", no colleague names attached to decisions.
  The MR has to stand alone for someone who wasn't in the room, and it outlives the conversation.
- **What the MR doesn't do** — "no production change needed", "no API changes". The diff shows absence.
  Worth an exception when behaviour or coverage moved *elsewhere* and would otherwise look lost.
- **Metrics** — runtime, test counts, line counts — unless the number is the point of the change.
- **Design-rationale essays and pre-emptive defences** — why an assertion style or naming was chosen, argued before anyone
  objected. If a reviewer asks, answer in the thread.
- **File-by-file narration**, and boilerplate headers with nothing under them.

## Before posting

Delete any sentence that wouldn't change where a reviewer looks or what they'd push back on. If removing it loses nothing, it was padding.
Then check it still reads for someone who wasn't in the conversation.

## Worked example

> **test: run order transition tests without a database**
>
> The transition tests start a database container for logic that is only a
> status check plus a repository call, so the suite pays for a database it
> doesn't use.
>
> OrderServiceTransitionTest now builds the service from mockk repositories:
>
> - the shared rules are parameterized over every transition and status, with
>   the terminal split derived from Status.isTerminal, so a new status or
>   transition is covered without touching a test body
> - assertions check what the service decides — target status, updatedBy, and
>   that a terminal order is rejected before anything is written — instead of
>   reading the row back
> - updateStatus and findStatusForUpdate move down to OrderRepositoryTest, the
>   only place left exercising that SQL

The why names the concrete waste in this test, not the general principle. Each bullet covers something the diff doesn't
explain on its own: why so few test methods cover so many cases, why the assertions changed shape, why a second file is here.
