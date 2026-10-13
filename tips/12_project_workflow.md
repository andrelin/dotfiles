<!-- DOCTOC SKIP -->

# Project Workflow

CLIs you set up per-project — `gh` for GitHub, `git-secret` for encrypted files, `direnv` for per-dir env, `fnm` for Node versions.

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

## Tip 12.4: fnm — Fast Node Manager

Install and switch between Node.js versions per project. Opening a shell in, or entering, a directory with a
`.nvmrc`, `.node-version` or `package.json` `engines` field (here or in a parent) switches automatically.
Any other directory switches back to the default, which also undoes a manual `fnm use`.
`dotfiles` keeps the two latest LTS lines and the latest release installed, with the newest LTS as the default.

```sh
fnm install --lts                     # install latest LTS
fnm use 22                            # switch to Node 22 in this shell
fnm list                              # list installed versions
fnm default 22                        # version new shells start with
echo "22" > .nvmrc                    # pin Node version per project
```

Docs: <https://github.com/Schniz/fnm>
