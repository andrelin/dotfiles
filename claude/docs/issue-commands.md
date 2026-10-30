# Issue commands

The `gh`, `glab` and `fj` forms the `writing-issues` skill uses, and the one target rule they share.
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

Ahead of the last turn, so a match is shown there, with the target rule:

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
