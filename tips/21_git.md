<!-- DOCTOC SKIP -->

# Git

Custom git workflow helpers and repo-history diagnostics shipped via `source/41_git.sh`.

## Tip 21.1: Workflow Helpers

```sh
merge-from-branch main          # rebase current branch onto main, then push
rebase-onto-branch main         # interactive rebase onto main, then force-push-with-lease
rebase-cur                      # interactive rebase the commits unique to the current branch
rebase-cur-onto-branch main     # combination of the two above
gpc                             # git push -u origin <current-branch>
gpfc                            # gpc but with --force-with-lease (safe force-push)
```

Use `gpc` for first-push of a new branch, `gpfc` after rebases. `merge-from-branch` is the "I want main's latest changes in my feature branch" shortcut.

## Tip 21.2: Repo Diagnostics

Pure-git analysis of the current repo's history. Run any of these in any git repo for a quick health read.

```sh
git_most_changed_files          # files churned the most — likely hotspots
git_bugs_cluster                # files frequently changed in bug-fix commits
git_who_built_this              # contribution attribution by lines authored
git_momentum                    # commits per week trend
git_firefighting                # ratio of bug-fix commits to total
```

Treat them as a bundle: when joining a new repo or auditing one, run them in sequence to get a feel for hotspots, ownership, pace, and quality patterns.
