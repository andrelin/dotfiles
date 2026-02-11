# Dotfiles

![macOS](https://github.com/andrelin/dotfiles/actions/workflows/tests.yml/badge.svg?nameFilter=macOS)
![Ubuntu](https://github.com/andrelin/dotfiles/actions/workflows/tests.yml/badge.svg?nameFilter=Ubuntu)
![WSL](https://github.com/andrelin/dotfiles/actions/workflows/tests-wsl.yml/badge.svg)
![RHEL](https://github.com/andrelin/dotfiles/actions/workflows/tests.yml/badge.svg?nameFilter=RHEL)

My macOS / Ubuntu / WSL 2 / RHEL dotfiles.

Forked from https://github.com/runesto/dotfiles

## About this project

I finally decided that I wanted to be able to execute a single command to "bootstrap" a new system to pull down all of my dotfiles and configs, as well as install all the tools I commonly use. In addition, I wanted to be able to re-execute that command at any time to synchronize anything that might have changed. Finally, I wanted to make it easy to re-integrate changes back in, so that other machines could be updated.

That command is [dotfiles][dotfiles], and this is my "dotfiles" Git repo.

[dotfiles]: bin/dotfiles

## How the "dotfiles" command works

When [dotfiles][dotfiles] is run for the first time, it does a few things:

1. Git is installed if necessary (via APT on Ubuntu, already present on macOS).
1. This repo is cloned into your user directory, under `~/.dotfiles`.
1. Files in `/copy` are copied into `~/`. ([read more](#the-copy-step))
1. Files in `/link` are symlinked into `~/`. ([read more](#the-link-step))
1. You are prompted to choose scripts in `/init` to be executed. The installer auto-selects scripts based on OS (e.g., `_macos_` scripts are only selected on macOS). Scripts with `_personal_` in the filename are default unchecked.
1. Your chosen init scripts are executed (in alphanumeric order, hence the funky names). ([read more](#the-init-step))

On subsequent runs, step 1 is skipped, step 2 just updates the already-existing repo, and step 5 remembers what you selected the last time. The other steps are the same.

### Other subdirectories

- The `/backups` directory gets created when necessary. Any files in `~/` that would have been overwritten by files in `/copy` or `/link` get backed up there.
- The `/bin` directory contains executable shell scripts (including the [dotfiles][dotfiles] script) and symlinks to executable shell scripts. This directory is added to the path.
- The `/caches` directory contains cached files, used by some scripts or functions.
- The `/conf` directory stores app configuration files (Sublime Text, IntelliJ) that are linked into app-specific locations by dedicated init scripts.
- The `/source` directory contains files that are sourced whenever a new shell is opened (in alphanumeric order, hence the funky names).
- The `/test` directory contains unit tests for especially complicated bash functions.
- The `/vendor` directory contains third-party libraries (zsh plugins as git submodules).

### The "copy" step

Any file in the `/copy` subdirectory will be copied into `~/`. Sensitive information is managed via git-secrets, but files that may need local edits (like [copy/.gitconfig](copy/.gitconfig)) should be _copied_ rather than linked as a second line of defense. Because the file you'll be editing is no longer in `~/.dotfiles`, it's less likely to be accidentally committed into your public dotfiles repo.

### The "link" step

Any file in the `/link` subdirectory gets symlinked into `~/` with `ln -s`. Edit one or the other, and you change the file in both places. Don't link files containing sensitive data, or you might accidentally commit that data! If you're linking a directory that might contain sensitive data (like `~/.ssh`) add the sensitive files to your [.gitignore](.gitignore) file!

### The "init" step

Scripts in the `/init` subdirectory will be executed. A whole bunch of things will be installed, but _only_ if they aren't already.

#### macOS

- XCode Command Line Tools via [init/11_macos_xcode.sh](init/11_macos_xcode.sh)
- Homebrew via [init/20_homebrew.sh](init/20_homebrew.sh)
- Homebrew recipes via [init/31_homebrew_recipes.sh](init/31_homebrew_recipes.sh)
- Homebrew casks via [init/32_macos_homebrew_casks.sh](init/32_macos_homebrew_casks.sh)

#### Linux / WSL

- Flatpak (Linux desktop) via [init/21_linux_flatpak.sh](init/21_linux_flatpak.sh) and [init/34_linux_flatpak_apps.sh](init/34_linux_flatpak_apps.sh)
- Winget (WSL) via [init/22_wsl_winget.sh](init/22_wsl_winget.sh)
- Homebrew via [init/20_homebrew.sh](init/20_homebrew.sh)
- Homebrew recipes via [init/31_homebrew_recipes.sh](init/31_homebrew_recipes.sh)

#### All platforms

- SSH config and private keys via [init/10_ssh_private_keys.sh](init/10_ssh_private_keys.sh)
- Sublime Text settings via [init/51_sublime_text.sh](init/51_sublime_text.sh)

## Hacking my dotfiles

Because the [dotfiles][dotfiles] script is completely self-contained, you should be able to delete everything else from your dotfiles repo fork, and it will still work. The only thing it really cares about are the `/copy`, `/link` and `/init` subdirectories, which will be ignored if they are empty or don't exist.

If you modify things and notice a bug or an improvement, [file an issue](https://github.com/andrelin/dotfiles/issues) or [a pull request](https://github.com/andrelin/dotfiles/pulls) and let me know.

Also, before installing, be sure to [read my gently-worded note](#heed-this-critically-important-warning-before-you-install).

## Installation

### macOS Notes

You need to have [XCode](https://developer.apple.com/downloads/index.action?=xcode) or, at the very minimum, the [XCode Command Line Tools](https://developer.apple.com/downloads/index.action?=command%20line%20tools), which are available as a much smaller download.

The easiest way to install the XCode Command Line Tools is to open up a terminal, type `xcode-select --install` and follow the prompts.

### Ubuntu / WSL Notes

You should at least update/upgrade APT with `sudo apt-get -qq update && sudo apt-get -qq dist-upgrade` first.

### Heed this critically important warning before you install

**If you're not me, please _do not_ install dotfiles directly from this repo!**

Why? Because I often completely break this repo while updating. Which means that if I do that and you run the `dotfiles` command, your home directory will burst into flames, and you'll have to go buy a new computer. No, not really, but it will be very messy.

### Actual installation

1. [Read my gently-worded note](#heed-this-critically-important-warning-before-you-install)
1. Fork this repo
1. Open a terminal/shell and do this (change `andrelin` and `main` as appropriate):

#### Ubuntu / WSL

```sh
export DOTFILES_GH_USER=andrelin
export DOTFILES_GH_BRANCH=main
bash -c "$(wget -qO- https://raw.github.com/$DOTFILES_GH_USER/dotfiles/$DOTFILES_GH_BRANCH/bin/dotfiles)" && source ~/.zshrc
```

#### macOS

```sh
export DOTFILES_GH_USER=andrelin
export DOTFILES_GH_BRANCH=main
bash -c "$(curl -fsSL https://raw.github.com/$DOTFILES_GH_USER/dotfiles/$DOTFILES_GH_BRANCH/bin/dotfiles)" && source ~/.zshrc
```

Since you'll be using the [dotfiles][dotfiles] command on subsequent runs, you'll only have to set the `DOTFILES_GH_USER` variable for the initial install, but if you have a custom branch, you _will_ need to export `DOTFILES_GH_BRANCH` for subsequent runs.

There's a lot of stuff that requires admin access via `sudo`, so be warned that you might need to enter your password here or there.

### Actual installation (for me)

#### Ubuntu / WSL

```sh
bash -c "$(wget -qO- https://raw.github.com/andrelin/dotfiles/main/bin/dotfiles)" && source ~/.zshrc
```

#### macOS

```sh
bash -c "$(curl -fsSL https://raw.github.com/andrelin/dotfiles/main/bin/dotfiles)" && source ~/.zshrc
```

## Aliases and Functions

To keep things easy, the `~/.zshrc` and `~/.bashrc` files are very simple, and should never need to be modified. Instead, add your aliases, functions, settings, etc into one of the files in the `source` subdirectory, or add a new file. They're all automatically sourced when a new shell is opened. Take a look, I have [a lot of aliases and functions](source).

## Scripts

The `/bin` directory is added to `$PATH` and contains:

- [dotfiles][dotfiles] - (re)initialize dotfiles. It might ask for your password (for `sudo`).
- [eachdir](bin/eachdir) - run one or more commands in one or more directories.
- [isip](bin/isip) - list bound IP addresses, or check if a specific IP is bound.

The `src` function (defined in [.zshrc](link/.zshrc) and [.bashrc](link/.bashrc)) re-sources all files in `/source`, useful after making changes without opening a new shell.

## License

Copyright (c) 2021-2026 Andreas Lind-Johansen
Licensed under the MIT license.
