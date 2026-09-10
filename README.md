# <img src="website/static/img/logo-dot-files.svg" alt="" class="title-logo" width="56" /> Dotfiles

![macOS](https://github.com/andrelin/dotfiles/actions/workflows/tests.yml/badge.svg?nameFilter=macOS)
![Ubuntu](https://github.com/andrelin/dotfiles/actions/workflows/tests.yml/badge.svg?nameFilter=Ubuntu)
![WSL](https://github.com/andrelin/dotfiles/actions/workflows/tests-wsl.yml/badge.svg)
![RHEL](https://github.com/andrelin/dotfiles/actions/workflows/tests.yml/badge.svg?nameFilter=RHEL)

My macOS / Ubuntu / WSL 2 / RHEL dotfiles.

Browseable docs: <https://dotfiles.lindjo.no>

Forked from <https://github.com/runesto/dotfiles>

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [About this project](#about-this-project)
- [How the "dotfiles" command works](#how-the-dotfiles-command-works)
- [Hacking my dotfiles](#hacking-my-dotfiles)
- [Installation](#installation)
- [Aliases and Functions](#aliases-and-functions)
- [Scripts](#scripts)
- [Tips](#tips)
- [License](#license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## About this project

I finally decided that I wanted to be able to execute a single command to "bootstrap" a new system to pull down
all of my dotfiles and configs, as well as install all the tools I commonly use.
In addition, I wanted to be able to re-execute that command at any time to synchronize anything that might have changed.
Finally, I wanted to make it easy to re-integrate changes back in, so that other machines could be updated.

That command is [dotfiles][dotfiles], and this is my "dotfiles" Git repo.

[dotfiles]: bin/dotfiles

## How the "dotfiles" command works

The three steps — `copy/`, `link/`, `init/` — what each subdirectory is for, and which init scripts run on which
platform: **[the full walkthrough](docs/how-it-works.md)**.

## Hacking my dotfiles

Because the [dotfiles][dotfiles] script is completely self-contained, you should be able to delete everything
else from your dotfiles repo fork, and it will still work.
The only thing it really cares about are the `/copy`, `/link` and `/init` subdirectories, which will be ignored
if they are empty or don't exist.

If you modify things and notice a bug or an improvement, [file an issue](https://github.com/andrelin/dotfiles/issues)
or [a pull request](https://github.com/andrelin/dotfiles/pulls) and let me know.

Also, before installing, be sure to [read my gently-worded note](docs/installation.md#heed-this-critically-important-warning-before-you-install).

## Installation

Prerequisites per platform, the warning to read first, and the one-line install:
**[the installation guide](docs/installation.md)**.

## Aliases and Functions

To keep things easy, the `~/.zshrc` and `~/.bashrc` files are very simple, and should never need to be modified.
Instead, add your aliases, functions, settings, etc into one of the files in the `source` subdirectory, or add a
new file. They're all automatically sourced when a new shell is opened.
Take a look, I have [a lot of aliases and functions](source).

## Scripts

The `/bin` directory is added to `$PATH` and contains:

- [dotfiles][dotfiles] - (re)initialize dotfiles. It might ask for your password (for `sudo`).
- [eachdir](bin/eachdir) - run one or more commands in one or more directories.
- [isip](bin/isip) - list bound IP addresses, or check if a specific IP is bound.
- [sync-claude-deny](bin/sync-claude-deny) - sync git-secret paths into Claude Code deny rules. Use `--check` to verify without modifying.
- [sort-claude-settings](bin/sort-claude-settings) - sort arrays in Claude Code settings files for deterministic output.
- [check-md-limits](bin/check-md-limits) - enforce the markdown line-length and file-length limits. Run by the pre-commit hook and CI.

The `src` function (defined in [.zshrc](link/.zshrc) and [.bashrc](link/.bashrc)) re-sources the files in
`/source` — every `*sh` under zsh, `*.sh` only under bash — useful after a change without opening a new shell.

## Tips

A growing index of terminal tricks, repo features and bundled-tool basics lives in [TIPS.md](TIPS.md), with one
file per category under [tips/](tips/).
Run `tips` in a shell to print them all, `tips <FILE>` (e.g. `tips 22`) for one section, `tips <FILE>.<N>`
(e.g. `tips 22.3`) for a single tip, `tips <D>x` for a whole decade, `tips -l` to list titles, or `tips -h` for usage.

## License

Copyright © 2022-2026 Andreas Lind-Johansen
Licensed under the [MIT license](LICENSE).
