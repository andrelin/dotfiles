---
name: handling-dependency-updates
description: Read before working through a repo's dependency updates or security alerts - merging Renovate or Dependabot PRs, acting on the dependency dashboard, fixing Dependabot, code-scanning or secret-scanning alerts - even when asked only to "merge the Renovate PRs", or across every repo on an account.
---

# Handling dependency updates

Three steps: **collect** everything that's open, **decide** per repo what lands and how, then **do it** and
check the alerts actually closed.
This is not a plan file and needs no `writing-plans` setup. The decision is a table in chat that the user approves once.
Closing, bundling or referencing a bot PR is governed by the `dependency-bot-prs` skill. Read it as well.

## 1. Collect

Per repo, after resolving its work context (§ *Work contexts* decides whether you may merge at all):

| Source | Command |
| --- | --- |
| Repos | `gh repo list <owner> --no-archived --limit 200 --json name,visibility,defaultBranchRef` |
| Bot PRs | `gh pr list -R <repo> --json number,title,author,mergeable,statusCheckRollup` (Renovate is `app/renovate`, Dependabot `app/dependabot`) |
| Dashboard | the open issue titled *Dependency Dashboard*: read *Awaiting Schedule*, *Pending Status Checks*, *PR Edited (Blocked)*, *Rate-Limited*, *Repository Problems* |
| Dependabot alerts | `gh api 'repos/<repo>/dependabot/alerts?state=open&per_page=100'`, keeping the severity, package, manifest and `first_patched_version` |
| Code scanning | `gh api 'repos/<repo>/code-scanning/alerts?state=open'` (a 403 or 404 means it's off or has no analysis) |
| Secret scanning | `gh api 'repos/<repo>/secret-scanning/alerts?state=open'`. It needs the `admin:repo_hook` scope on public repos. Without it, say the check was skipped. |
| Merge setup | `gh api repos/<repo>` for the allowed merge methods. Branch protection, and with it `--auto`, is unavailable on free private repos. |

Script the sweep across repos into one file in the scratchpad. One call per repo per source is slow but complete.

## 2. Decide

Map every alert to what fixes it, then every bot PR to an action:

- **An alert covered by an open bot PR** is fixed by merging that PR. A Renovate `[SECURITY]` PR and a Dependabot PR
  for the same bump are duplicates: merge one, and the other bot closes its own.
- **A transitive alert with no PR** gets a lockfile refresh (`npm update`, `npm audit fix` without `--force`, `uv lock --upgrade-package`).
  Use an `overrides` / constraint entry only where the range can't reach the patched version.
- **An alert with no patched version** can't be fixed by a bump. Leave it open and report it. Dismissing it is the user's call.
- **A bot PR with failing CI** usually means the bump broke a test or a tool. Prove the cause by reproducing it
  locally at the new version. Fix it in your own PR to the default branch, and the bot rebases its PR onto the fix.
  Don't push the fix to the bot's branch, because Renovate stops managing a branch someone else edits.
- **A major bump** merges only after the project's tests, build and lint pass locally on its branch, since CI is often one thin check.
- **A dashboard item** waiting on a schedule or blocked by an edit gets created or reset by ticking its checkbox.
  Ticking edits the issue, so it needs approval like any other write.

Order: security fixes first, then the grouped non-major PR, then majors one at a time, because each merge can
conflict the next. Present the result as one table per repo (PR or alert → action → how it's verified). In the same
question, ask for every approval it needs, per `## Approvals` in the global `CLAUDE.md`.

## 3. Do it

- **Repos are independent:** fan them out to one agent each, with the full brief. Keep the repo with the hardest problem yourself.
- **Never force-push a bot's branch.** To get a conflicted PR rebased, tick `rebase-check` in the PR body
  (`gh pr edit --body-file`), comment `@dependabot rebase`, or wait for the bot. Then poll
  `gh pr view N --json mergeable,statusCheckRollup`.
- **Merge only on green CI** with the repo's allowed method (`gh pr merge N --squash`).
- **Verify by re-listing the alerts** after the merges. Fixed alerts close once GitHub rescans the default branch, so recheck after a few minutes.
- **Report per repo:** what merged, what you fixed and how you proved it, what's still open and why
  (no patched version, a major that broke and needs a decision, a skipped scope).
