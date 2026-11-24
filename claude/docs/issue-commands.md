# Issue commands

The `gh`, `glab` and `fj` forms the `writing-issues` and `managing-roadmaps` skills use, and the one target rule they share.
Every call runs from the root of the repo the issue is for, after `~/.claude/hooks/work-context.sh can-file-issue`.

## The target rule, for every gh, glab and fj call

**Count the remotes with `git remote` before the first call** — the search and the label list too, not only the
create: a second remote such as `upstream` can make a bare call answer for the wrong repo.

- **One remote:** no `-R`.
- **More than one:** origin's target — gh `-R <owner>/<repo>` on `github.com` and `-R <host>/<owner>/<repo>`
  elsewhere, glab `GITLAB_HOST=<host>` plus `-R <project path>` — which the guard still checks on the create.
- **fj, always:** `-H <host>` before the subcommand, the host as `fj auth list` prints it (with its port, if it has
  one), and `--repo <owner>/<repo>` after it where the subcommand takes
  `--repo`; `issue edit`, `issue comment` and `repo labels` take the repo positionally, as in § *Labels*. fj otherwise derives the
  API address from the remote URL, which breaks on an SSH remote with a port, such as `ssh://git@host:2222/…`.
- **Several remotes and no `origin`:** ask which.
- **No remote:** nothing to file on — the title and body only, no command, and an item gets no `Target:` line.

## Quoting

- **Keep `;`, `|`, `&`, backticks and `$(` out of titles and any other inline argument,** bar the `$(cat <path>)` the
  glab form needs: the guard splits commands without honouring quotes, so they can cause a false block.
  This holds when the user asks for their title kept exactly: say why, and offer the closest title without them.
- **Every title in a command** — the search, the create, a drafted `!` line — is single-quoted, each `'` written
  `'\''`, so `$` and `"` stay literal: `$HOME isn't "expanded"` becomes `'$HOME isn'\''t "expanded"'`.
  A search string also drops each `"` of the title.

## Search before filing

Ahead of the last turn, so a match is shown there, with the target rule. `<title>` is the draft's exact title,
searched once it is drafted, never keywords of your own: GitHub misses `check_missing_cards` against
`check_missing_cards.py`. A tracker heading already naming an issue for this problem is checked with
`gh issue view <n>` (`glab issue view`, `fj issue view`), never assumed missing.

- `gh issue list --state open --limit 10 --search '<title>'`
- `glab issue list --per-page 10 --search '<title>'`
- `fj -H <host> issue search --repo <owner>/<repo> '<title>'`
- On a tracker no CLI here reads (Jira, Azure DevOps, Bitbucket), no search: ask the user whether it already holds one.

**A match** is a result whose title and body, once read, describe the same problem as the draft's *Problem*; sharing
words is not a match, and no match files without asking.
On a match, show it and ask "comment there instead?". On a yes, write the comment to `<scratchpad>/issue-body-<n>.md`
and draft it for the user at every level, filing nothing, since a comment is a platform write no requirement needs:

- `! gh issue comment <number> -R <target> --body-file <path>`
- `! GITLAB_HOST=<host> glab issue note <number> -R <project path> --message "$(cat <path>)"`
- `! fj -H <host> issue comment <owner>/<repo>#<number> --body-file <path>`

On a no, file as planned.

## Labels

`gh label list --limit 1000` or `glab label list --per-page 100`, with the target rule; pass only labels it lists.
`fj issue create` takes no labels: list them with `fj -H <host> repo labels <owner>/<repo> view`, file, then add each
with `fj -H <host> issue edit <owner>/<repo>#<n> labels --add <label>`.
A failed search or `label list` is reported and filing still goes ahead, with no `--label`.
**Never create a repo, remote or label to make filing work.**

## Roadmaps

For the `managing-roadmaps` skill, with the target rule; `<epic>`, `<phase>`, `<n>` and `<m>` are issue numbers, and `<ref>` is `<owner>/<repo>#<n>`.
Forgejo has no sub-issues, so there an epic *depends on* its phases.
`fj` has no JSON: it reads plain text, with each `<ref>` in full, because a bare `#<n>` target fails and a bare `<n>` needs a clone's remote.

### Setting up labels

Creating labels is a platform write: on the user's approval only, one call per label from the set `kind/epic`, `kind/feature`, `kind/chore`,
`kind/idea`, `area/<name>`, and for `labels` status mode `status/in-progress` and `status/in-review`.

- `gh label create 'kind/epic' --color 0e8a16`
- `fj -H <host> repo labels <owner>/<repo> create 'kind/epic' 0e8a16 --exclusive` — for the `kind/` and `status/` scopes,
  so Forgejo keeps one per issue
- An existing Forgejo label becomes exclusive with `fj -H <host> repo labels <owner>/<repo> edit 'kind/epic' --exclusive true`

GitHub labels are flat: the agent keeps one `kind/` and one `status/` label itself.

### Epics and phases

- `gh issue create --title '…' --body-file <path> --label kind/epic --label area/<name>` — the epic
- `gh issue create --title '…' --body-file <path> --label kind/feature --parent <epic>` — a phase, linked on creation
- `gh issue edit <epic> --add-sub-issue <n>` — an existing issue
- Forgejo: `fj issue create` takes no labels, so create, then `fj -H <host> issue edit <owner>/<repo>#<n> labels --add 'kind/epic'`;
  link with `fj -H <host> issue depend add <owner>/<repo>#<epic> <owner>/<repo>#<phase>` — the epic depends on the phase

`fj issue depend add` refuses `#<n>` as a target, accepts a bare number only inside a clone,
and accepts an issue depending on itself, so check the numbers.
Adding a dependency that closes a cycle fails with a `500`; `depend remove` works but reports `unexpected status code 201`.

### An epic's phases

- `gh issue view <epic> --json subIssues --jq '.subIssues.nodes[] | "#\(.number) \(.state) \(.title)"'`
- `gh api --paginate repos/<owner>/<repo>/issues/<epic>/sub_issues --jq '.[].number' | wc -l` — when the count matters,
  since `subIssuesSummary` lags after a re-parent; without `--paginate` the REST list stops at 30
- `fj -H <host> issue depend list <owner>/<repo>#<epic>` — one `#<n> <title> (open)` or `(closed)` line per phase, so state needs no per-phase call;
  `No dependencies.` when none.
  Piped, `fj` writes these lines as plain text, with or without `--style minimal` (checked with `cat -v`);
  only `repo labels` output carries colour codes, and `--style minimal` doesn't remove them, so strip them with `sed` before matching there

### Dependencies and ready work

- `gh issue edit <n> --add-blocked-by <m>`, read back with `gh issue view <n> --json blockedBy --jq '.blockedBy.nodes[] | "#\(.number) \(.state)"'`
- `fj -H <host> issue depend add <owner>/<repo>#<n> <owner>/<repo>#<m>` — `<n>` depends on `<m>`;
  `fj -H <host> issue block list <owner>/<repo>#<m>` lists what `<m>` blocks
- Ready work on GitHub, as one call (the search index lags a few seconds after an edit):
  `gh issue list --state open --search '-is:blocked -label:kind/epic -label:kind/idea' --json number,title,labels,assignees`
- Ready work on Forgejo has no blocked filter, so take the open issues, drop the epics and ideas, and check each candidate:
  `fj -H <host> issue search --repo <owner>/<repo> --state open --all`,
  then the same with `--labels kind/epic` and `--labels kind/idea` to learn what to drop,
  then `fj -H <host> issue depend list <owner>/<repo>#<n>` per candidate: it is ready when no line ends in `(open)`.
  Search prints `#<n>: <title> (by <user>)` per issue and no labels.
  Without `--all` it returns 25 issues a page under a `Page X out of N pages in total` header,
  so read every page with `-p <page>` until `X` passes `N`.
  `--labels` takes several labels as AND, not OR, and silently ignores an unknown one, so list the labels first
  and skip the drop search for a `kind/` label the repo doesn't have, since it would return every issue.
  Forgejo also refuses to close an issue with an open dependency, so a blocked phase can't be closed out of order.

### Labels and milestones

- `gh issue edit <n> --add-label kind/idea --remove-label kind/chore` swaps one label in one call; `--remove-label` alone removes one
- `fj -H <host> issue edit <owner>/<repo>#<n> labels --add kind/idea` — Forgejo drops the other label of an exclusive scope itself;
  `labels --rm <label>` removes one, and an unknown label fails with `doesn't exist`
- A milestone on GitHub, with its due date: `gh api repos/<owner>/<repo>/milestones -f title='v1' -f due_on=2026-12-31T12:00:00Z`;
  send noon UTC, since `2026-12-31T00:00:00Z` came back as the 30th.
  Set it with `gh issue edit <n> --milestone 'v1'` and unset it with `gh issue edit <n> --remove-milestone`
- A milestone on Forgejo, with no due date: `fj -H <host> milestone --repo <owner>/<repo> create --state open 'v1'`,
  set with `fj -H <host> issue edit <owner>/<repo>#<n> milestone 'v1'` and unset with `milestone --unset`;
  it never rejects a duplicate title, and `issue view` doesn't print the milestone, so check with `issue search --milestones 'v1'`

### Status

Derived status needs only the assignee and a linked open PR; the default stores nothing.

- `gh issue view <n> --json state,assignees,closedByPullRequestsReferences` — an open PR whose body says `Closes #<n>`
  appears there before it merges, though not in the first seconds after it opens
- `fj -H <host> issue view <owner>/<repo>#<n> assignees` and plain `issue view` for open or closed;
  neither `issue view` nor a `Closes` line in a PR body names a PR, so Forgejo shows a linked PR only when someone ran
  `fj -H <host> pr block add --pr <owner>/<repo>#<pr> <owner>/<repo>#<n>`,
  after which `issue depend list` shows `#<pr> <title> (open)`, then `(merged)`
- Without that link an assignee alone means in progress on Forgejo.
  With it the issue can't close until the PR is merged or closed, and the ready-work check reads it as blocked
- `labels` mode swaps the `status/*` label as in § *Labels and milestones*:
  `--add-label status/in-review --remove-label status/in-progress` on GitHub
- `project` mode is GitHub only: Forgejo has no projects API, so it falls back to `labels`.
  `gh issue view <n> --json projectItems` gives the project's title and Status but no number, so find the number from the title:
  `gh project list --owner <owner> --format json --jq '.projects[] | "\(.number) \(.title)"'`,
  then `gh project item-add <number> --owner <owner> --url <issue url>` and
  `gh project item-edit <number> --owner <owner> --url <issue url> --field Status --value 'In Progress'`
- Setting a project's Status to `Done` closed the issue in the scratch run, so set it only when the issue should close

### Closing

- A PR body line `Closes #<phase>` (or `Closes <owner>/<repo>#<phase>`) closes the phase when the PR merges into the default branch, on GitHub;
  on Forgejo `fj -H <host> pr merge <owner>/<repo>#<pr> --method squash` closed the phase for both forms
- `gh issue close <epic> --comment '…'` closes at once, even with an open sub-issue, so check `An epic's phases` first
- `fj -H <host> issue close <owner>/<repo>#<epic> --with-msg '…'` refuses while a phase is open, yet posts the comment anyway;
  close the phases, then the epic

## Claude files

Write the body alone to `<scratchpad>/issue-body-<n>.md`, `<n>` its draft's — never the draft file, which holds the
answers, and never inline — then run, with the target rule:

- `gh issue create --title '…' --body-file <path>`
- `glab issue create --title '…' --description "$(cat <path>)" --yes` — `--yes` skips glab's prompts with no TTY
- `fj -H <host> issue create --repo <owner>/<repo> '…' --body-file <path> --no-template` — the title is positional;
  a repo that requires a template fails, so re-run with `--template <name>` from `fj … issue templates --repo …`

and report the URL.

## The user files

Give the title and body inline, plus the command, saying the path lasts only this session and that the tracker lookup
matches the title exactly, so a changed title means reporting the number:

- `! gh issue create -R <owner/repo> --title '…' --body-file <path>` — `-R <host>/<owner>/<repo>` off `github.com`
- `! GITLAB_HOST=<host> glab issue create -R <project path> --title '…' --description "$(cat <path>)" --yes`
- `! fj -H <host> issue create --repo <owner>/<repo> '…' --body-file <path> --no-template`, or `--template <name>`

**In these `!` lines the target is always named:** the bare `owner/repo` on `github.com`, never with a `github.com/`
prefix; `<host>/<owner>/<repo>` (gh), `GITLAB_HOST=<host>` (glab) or `-H <host>` with `--repo` (fj) anywhere else — a bare `owner/repo` resolves to
`github.com` or glab's default host, not to the cwd's remote.
A target no CLI here files on (Azure DevOps, Bitbucket, Jira) gets the title and body only, no command.

## A failed create

- **Failed before the request went out** — DNS, connection refused, auth — or a repo that doesn't exist, issues
  disabled, a missing CLI: report it with its error, never as filed. A missing CLI is always a draft.
- **A repo not found** (gh's `Could not resolve to a Repository`, glab's or fj's `404`): say the target looks wrong and ask
  before giving the `!` line or writing the item. The user keeping that target ("keep it") goes on as *Otherwise*.
- **Any other error** — a timeout, a dropped connection, `EOF`, a reset — leaves the outcome unknown: say so, give the
  repo's issues URL to check, and neither re-run the create nor write an item until the user reports.
- **Otherwise** give the user's `!` line as above and, when the user will work on it, write an `(issue to file)`
  tracker item with `Target:` set, since no number can come back.
