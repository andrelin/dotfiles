# The review log

What `reviewing-in-rounds` writes, and what a resumed session and `implementing-plans` parse.
The forms below are literal: change one and both parsers miss it.

## Files

| File | Holds |
| --- | --- |
| the plan, `plan-<stem>.md` at the repo root | a `## Review log (<kind>)` section per kind, `<kind>` being `plan` or `code` |
| `plan-<stem>-review-findings-<kind>.md` beside it | every round's verified findings in full, ids `R<round>-<n>` |
| `plan-review-<branch>.md` (`/` → `-`) | the log of a code review with no plan, and nothing else |

With no plan, the findings file is `plan-review-<branch>-review-findings-code.md`; reviewers never see a findings file.
At company and customer level, `/plan-*.md` is in `$(git rev-parse --git-path info/exclude)` before either is written.

## The log section

```text
## Review log (code)

| Round | Lenses | Blocking | Major | Minor | Nit | Fixed |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 6 | 0 | 2 | 3 | 1 | 5 |

Re-evaluation after round 15: continue as is — counts falling, no lens conflict.
Done (code): round 16; unfixed: R16-3, R16-4
```

- **One row per finished round:** how many lenses ran, its *verified* findings by severity — a test failure after its
  fixes included — and how many were fixed that round.
- **Below the table,** in the order they happened: `Re-evaluation after round <n>: <recommendation>`, a stop reading
  `Re-evaluation after round <n>: user decision needed — <question>`; `User decision after round <n>: <answer>`;
  `Note after round <n>: <text>`.
- **`Done (<kind>): round <n>; unfixed: <ids or none>`** is always the section's last line.
- A row with no round in the findings file — run by hand, or the file lost — is history: it counts, and is never
  re-checked.

## The findings file

A code review's file opens with `Leftovers before round 1: <paths, or none>`, the unstaged and untracked paths
when round 1 started, which completion compares against.
One `## Round <n>` heading per round, then one entry per verified finding:

```text
### R3-2 · major · test matrix
Spec 3 (60-character cap) has no test; a truncation that leaves a trailing dash passes.
Fixed: added a 70-character case to Task 1's tests.
```

A finding the verifier dropped or downgraded keeps its entry, with `Refuted:` and the written reason beside it.
`Fixed:` is written after the fix; an entry with no `Fixed:` line and no `Refuted:` is unfixed.

## Write order

1. The round's verified findings go into the findings file under `## Round <n>`.
2. The fixes, each entry getting its `Fixed:` line.
3. After code fixes, the project's tests; a failure is a `blocking` finding of the same round, fixed before step 4.
4. The round's log row.

## Resuming

Read the open section of the kind being run — one whose heading has no `, closed` — and the findings file.

- **The section ends in `user decision needed — <question>`** with no `User decision after` line: ask that question
  before anything else.
- **The findings file holds a round the log has no row for:** that round was interrupted after its reviewers ran.
  Apply its unfixed findings, write its row, then go on — never dispatch its reviewers again.
- **A re-evaluation is due** (the last row is round 3, 6, 9, … of a plan or 15, 20, 25, … of code, and no
  `Re-evaluation after` line names it): run it before the next round.
- **The section ends in `Done (<kind>):`:** say the run is finished and ask whether to start a fresh one.
- **No open section of this kind:** start at round 1 — a finished log of the other kind doesn't count.

## Closing

A fresh run after `Done (<kind>):` first closes the old one, on the day it does so:

- the heading becomes `## Review log (<kind>, closed <YYYY-MM-DD>)`;
- the findings file becomes `…-review-findings-<kind>-closed-<YYYY-MM-DD>.md`, `-<n>` before `.md` from the
  second close that day, `<n>` that close's count.

Resuming and every count ignore closed sections.
