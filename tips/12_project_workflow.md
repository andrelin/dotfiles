<!-- DOCTOC SKIP -->

# Project Workflow

CLIs you set up per-project — `gh` for GitHub, `git-secret` for encrypted files, `direnv` for per-dir env, `nvm` for Node versions.

## Tip 12.1: gh — GitHub CLI

Manage repos, PRs, and issues from the terminal.

```sh
gh repo clone owner/name              # clone a repo
gh pr create                          # open PR for current branch
gh pr list                            # list PRs in current repo
gh pr checkout 123                    # check out PR #123 locally
gh issue create                       # open an issue
gh run watch                          # follow a running workflow
```

Docs: <https://cli.github.com/manual/>

## Tip 12.2: git-secret — Encrypted Files in Git

Encrypts sensitive files with GPG so they can be safely committed.

```sh
git secret init                       # one-time per repo
git secret tell you@example.com       # add a recipient (must have public GPG key)
git secret add path/to/secret.json    # mark file as a secret
git secret hide                       # encrypt all tracked secrets → .secret files
git secret reveal                     # decrypt all .secret files
```

Cross-link: see Tip 24.1 / 24.3 — this repo's pre-commit hook auto-syncs `git secret`'s tracked paths into Claude Code's deny rules.

Docs: <https://git-secret.io/>

## Tip 12.3: direnv — Per-Directory Environment

Auto-loads environment variables when you `cd` into a project, unloads when you leave.

```sh
echo 'export FOO=bar' > .envrc
direnv allow                          # one-time approval per .envrc change
```

Now `FOO` is set whenever you're inside that directory tree.

For projects with only a plain `.env` file, use direnv's stdlib `dotenv` helper:

```sh
echo 'dotenv' > .envrc                # also: 'dotenv .env.local'
direnv allow
```

This is the preferred path over the omz `dotenv` plugin, which doesn't unload on cd-out (vars leak between projects).

Docs: <https://direnv.net/>

## Tip 12.4: nvm — Node Version Manager

Install and switch between Node.js versions per project.

```sh
nvm install --lts                     # install latest LTS
nvm use 20                            # switch to Node 20 in this shell
nvm ls                                # list installed versions
echo "20" > .nvmrc                    # pin Node version per project
nvm use                               # picks up .nvmrc automatically
```

Docs: <https://github.com/nvm-sh/nvm>
