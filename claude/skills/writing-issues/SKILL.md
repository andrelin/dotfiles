---
name: writing-issues
description: Read before writing, filing or drafting an issue or ticket for any task tracker - GitHub, GitLab, Jira, Azure Boards - and before deciding whether something belongs in the task tracker, the personal follow-up tracker, or both.
---

# Writing issues

One piece of work becomes an issue, a follow-up tracker item, or both, through a short interview.
Every `gh` and `glab` command form, the target rule and what to do when a call fails: `~/.claude/docs/issue-commands.md`,
read before the first search.

## Two questions, decided first

- **Does it belong in the project's task tracker?** Yes when other people need to see or act on it, or when it is a
  substantial unit of work — a bug or feature that will get its own plan or PR, or that someone (the user included,
  later) would search for — even on a personal repo nobody else reads. A reminder, a chore or a loose note does not.
  Unsure → ask, as one interview question.
- **Will the user work on it in any capacity — implement, review, chase, decide?** Then it also gets a follow-up
  tracker item; the follow-up tracker is the user's own and never shared.
- Issue only, item only, or both: the item carries the issue number in its heading (`writing-follow-up-items`) —
  `(issue to file)` in its place while the user still has to file it, replaced when they report the number or at the
  next tracker review. An issue filed from an existing item puts the number in that item's heading, never in a second item.
- Every `(issue to file)` item gets `Target: <host>/<project path>` on its own line right below the heading, origin's
  host and path (a GitLab path may hold subgroups), and its heading title is the drafted issue title verbatim.
  No remote → no `Target:` line.
- No tracker (a `00-follow-ups-*` file in the repo's root or a directory above it, up to `$HOME`) and an item is
  needed → ask whether to set one up (`setting-up-follow-up-trackers`).

## The interview

- **Interview before drafting,** in the brainstorming style: first read the code and the existing issues to answer
  what you can yourself, then ask the user one question at a time, multiple choice where the options are knowable,
  until every section below can be written without a guess — above all the acceptance criteria and what is out of scope.
- **Ask at least one question that challenges the premise:** is this the real problem, and is it this repo's to fix?
  Stop asking the moment that holds; a concise issue needs few answers.
- **The last turn shows the title and body** and asks only "anything to change, or file it?" — the user's last look,
  which matters most for a world-readable issue — and files only on an explicit yes.
- **The draft file:** after each answer, the draft and the answers so far go to `<scratchpad>/issue-draft-<n>.md`,
  `<n>` the next free number in the session, so a second issue never overwrites the first.
  A compacted session resumes from the highest `<n>` unless that file ends in an `Ended:` line; a new session starts over.
- **Its last line,** once the issue is filed, handed to the user or dropped:
  `Ended: <URL | drafted | not filed | unknown <issues URL>>` — `drafted` also after a drafted comment or a failed
  create's `!` line, `unknown` for a create whose outcome is unknown.
  Just before running a create, write `Ended: unknown <issues URL>`, replaced once the call returns, so a compaction
  mid-create never resumes into a second one.
- **The drafted body lives only in the scratchpad:** when the user files, the last turn says to file it before the session ends.
- **When the user will work on it, finish by printing the next stage's command** for a fresh session:
  `ai plan <owner/repo#n>` for an issue on `github.com`, `ai plan <issue URL>` on any other host, or
  `ai plan '<tracker item title>'` while the user has yet to file it, or when there is no issue at all.
  That title is the heading's only, with its `N.M ·` ref, status badge, branch and `(issue to file)` stripped (a ref
  like `B2.3` is reassigned by the next tracker review), single-quoted with each `'` written `'\''` so nothing
  expands in zsh: ``ai plan 'Fix `$(x)` "y"'``.

## Where the issue lives and who files it

A rule per group of repos, defaulting by level:

| Level and host | Home | Who files |
| --- | --- | --- |
| personal (the personal account, bar `uptime` repos) | that repo's GitHub issues | Claude, `gh issue create` |
| company, on `github.com` or a GitLab host | that repo's issues | Claude, with the tool `can-file-issue` prints |
| company elsewhere | that repo's `## Issues` section; none → ask | the user, from Claude's draft |
| customer | the `## Issues` section; none → ask | the user, from Claude's draft — unless a marker lets the guard allow it |

- **The guard decides, not the table:** `cd` to the root of the repo the issue is for and make every call there —
  `~/.claude/hooks/work-context.sh can-file-issue` with no `[dir]`, the search, `label list` and the create.
  The session-start line is only a hint: it was computed once, for the starting directory.
- **Claude files with the tool it prints,** and drafts when it prints `none`, or when the `## Issues` section says the
  user files or names a tracker other than this repo's own issues — this repo's own being `each repo's own`, or a
  `host/owner/repo` naming this repo's origin. A section can tighten the guard's answer, never loosen it.
- **A `## Issues` section sets the rule for every repo below it,** in a `CLAUDE.md` that loads for those repos — for a
  customer, the customer-tree root, machine-local like the marker, never inside their repo; for a company repo, that
  repo's own committed `CLAUDE.md`; never this public one. Its format, literally:

  ```markdown
  ## Issues

  - **Tracker:** <each repo's own | host/owner/repo | Jira project key | none>
  - **Files:** <Claude | the user, from Claude's draft>
  ```

- **No section at customer level:** ask, and write the user's answer into one so the next issue doesn't ask.
  The customer-tree root is the user's answer, never inferred; `$HOME`, or a directory that is, or whose direct
  subdirectories are, a repo whose origin names another owner, is refused and asked again.
- **No section at company level:** ask, then print the section for the user to add to the repo's `CLAUDE.md` in a
  change of their own; Claude never writes it.
- **Where a section says Claude files through `gh` or `glab`,** on `github.com` or a host whose name contains `gitlab`,
  ask the user to run `! touch <tree>/.claude-files-issues` once; below it the guard allows `issue create` to each repo's
  own issues. On any other host (GitHub Enterprise, Azure DevOps, a self-hosted GitLab without `gitlab` in its
  hostname) say the marker won't help, and draft.
  A tracker shared across repos stays draft-and-paste — a deliberate limit until a project needs more.
- **Jira, the first time one appears:** its section is set up as above — written at customer level, printed at company
  level — and the issue drafted for pasting. Filing through a Jira connector is out of scope: the guard sees Bash only.

## The issue's shape

Written for a reader who never saw the conversation:

- **A title under 70 characters** naming the problem.
- **The `##` sections, named exactly so, in this order:** *Problem* (observed versus expected), *Why it matters*,
  *Proposed direction* (its first line `Optional:`), *Acceptance criteria* as `- [ ]` checkboxes each a test could
  check, *Out of scope*.
- **Code references as `<path>:<line> @ <short sha>`,** a commit origin has (`git branch -r --contains <sha>` lists a
  branch); with none there, `<path>` alone.
- **English, and the level's bar on content** — a personal public repo's issues are world-readable.
  Never quote the follow-up tracker in the body.
- **Labels** only from those the repo already uses; never create one. No assignee unless the user names one.

## Red flags

- Filing on a customer tracker because the CLI is authenticated.
- Creating the marker yourself.
- A tracker item for an issue the user only reported for someone else.
- An issue body that quotes the follow-up tracker, or a public issue naming a customer.
- An interview question the code already answers.
- `gh repo create`, `git remote add` or a new label to get past a failed call.
