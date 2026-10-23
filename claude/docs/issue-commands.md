# Issue commands

The `gh` and `glab` forms the `writing-issues` skill uses, and the one target rule they share.
Every call runs from the root of the repo the issue is for, after `~/.claude/hooks/work-context.sh can-file-issue`.

## The target rule, for every gh and glab call

- **One remote:** no `-R`.
- **More than one:** origin's target — gh `-R <owner>/<repo>` on `github.com` and `-R <host>/<owner>/<repo>`
  elsewhere, glab `GITLAB_HOST=<host>` plus `-R <project path>` — which the guard still checks on the create.
- **Several remotes and no `origin`:** ask which.
- **No remote:** nothing to file on — the title and body only, no command, and an item gets no `Target:` line.

## Quoting

- **Keep `;`, `|`, `&`, backticks and `$(` out of titles and any other inline argument,** bar the `$(cat <path>)` the
  glab form needs: the guard splits commands without honouring quotes, so they can cause a false block.
- **Every title in a command** — the search, the create, a drafted `!` line — is single-quoted, each `'` written
  `'\''`, so `$` and `"` stay literal: `$HOME isn't "expanded"` becomes `'$HOME isn'\''t "expanded"'`.
  A search string also drops each `"` of the title.

## Search before filing

Ahead of the last turn, so a match is shown there, with the target rule:

- `gh issue list --state open --limit 10 --search '<title>'`
- `glab issue list --per-page 10 --search '<title>'`
- On a tracker neither CLI reads (Jira, Azure DevOps, Bitbucket), no search: ask the user whether it already holds one.

**A match** is a result whose title and body, once read, describe the same problem as the draft's *Problem*; sharing
words is not a match, and no match files without asking.
On a match, show it and ask "comment there instead?". On a yes, write the comment to `<scratchpad>/issue-body-<n>.md`
and draft it for the user at every level, filing nothing, since a comment is a platform write no requirement needs:

- `! gh issue comment <number> -R <target> --body-file <path>`
- `! GITLAB_HOST=<host> glab issue note <number> -R <project path> --message "$(cat <path>)"`

On a no, file as planned.

## Labels

`gh label list --limit 1000` or `glab label list --per-page 100`, with the target rule; pass only labels it lists.
A failed search or `label list` is reported and filing still goes ahead, with no `--label`.
**Never create a repo, remote or label to make filing work.**

## Claude files

Write the body alone to `<scratchpad>/issue-body-<n>.md`, `<n>` its draft's — never the draft file, which holds the
answers, and never inline — then run, with the target rule:

- `gh issue create --title '…' --body-file <path>`
- `glab issue create --title '…' --description "$(cat <path>)" --yes` — `--yes` skips glab's prompts with no TTY

and report the URL.

## The user files

Give the title and body inline, plus the command, saying the path lasts only this session and that the tracker lookup
matches the title exactly, so a changed title means reporting the number:

- `! gh issue create -R <owner/repo> --title '…' --body-file <path>` — `-R <host>/<owner>/<repo>` off `github.com`
- `! GITLAB_HOST=<host> glab issue create -R <project path> --title '…' --description "$(cat <path>)" --yes`

**In these `!` lines the target is always named:** the bare `owner/repo` on `github.com`, never with a `github.com/`
prefix; `<host>/<owner>/<repo>` (gh) or `GITLAB_HOST=<host>` (glab) anywhere else — a bare `owner/repo` resolves to
`github.com` or glab's default host, not to the cwd's remote.
A target neither CLI files on (Azure DevOps, Bitbucket, Jira) gets the title and body only, no command.

## A failed create

- **Failed before the request went out** — DNS, connection refused, auth — or a repo that doesn't exist, issues
  disabled, a missing CLI: report it with its error, never as filed. A missing CLI is always a draft.
- **A repo not found** (gh's `Could not resolve to a Repository`, glab's `404`): say the target looks wrong and ask
  before giving the `!` line or writing the item.
- **Any other error** — a timeout, a dropped connection, `EOF`, a reset — leaves the outcome unknown: say so, give the
  repo's issues URL to check, and neither re-run the create nor write an item until the user reports.
- **Otherwise** give the user's `!` line as above and, when the user will work on it, write an `(issue to file)`
  tracker item with `Target:` set, since no number can come back.
