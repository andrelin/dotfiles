<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [How the `dotfiles` command works](#how-the-dotfiles-command-works)
  - [Other subdirectories](#other-subdirectories)
  - [The "copy" step](#the-copy-step)
  - [The "link" step](#the-link-step)
  - [The "init" step](#the-init-step)
    - [macOS](#macos)
    - [Linux / WSL](#linux--wsl)
    - [All platforms](#all-platforms)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# How the `dotfiles` command works

When [dotfiles][dotfiles] is run for the first time, it does a few things:

1. Git is installed if necessary (via APT on Ubuntu, already present on macOS).
1. This repo is cloned into your user directory, under `~/.dotfiles`.
1. Files in `/copy` are copied into `~/`. ([read more](#the-copy-step))
1. Files in `/link` are symlinked into `~/`. ([read more](#the-link-step))
1. You are prompted to choose scripts in `/init` to be executed. The installer auto-selects by OS (`_macos_`
   scripts only on macOS); `_personal_` scripts are default unchecked.
1. Your chosen init scripts are executed (in alphanumeric order, hence the funky names). ([read more](#the-init-step))

On subsequent runs step 1 is skipped, step 2 updates the existing repo, and step 5 remembers your last selection.

## Other subdirectories

- The `/backups` directory is created when needed: anything in `~/` that `/copy` or `/link` would overwrite goes there.
- The `/bin` directory contains executable shell scripts (including [dotfiles][dotfiles]) and symlinks to them, and is added to `$PATH`.
- The `/caches` directory contains cached files used by some scripts or functions.
- The `/claude` directory holds shared Claude Code config — `CLAUDE.md`, `skills/`, `rules/`, `docs/` and the
  statusline script — symlinked into `~/.claude/` by [init/52_macos_claude.sh](../init/52_macos_claude.sh),
  leaving machine-local state (sessions, history) alone.
- The `/conf` directory stores app configuration (Sublime Text, IntelliJ), linked into place by dedicated init scripts.
- The `/docs` directory holds the guide pages split out of the README — this one and the [installation guide](installation.md).
- The `/hooks` directory contains git hooks that are symlinked into `.git/hooks/` by [init/12_git_hooks.sh](../init/12_git_hooks.sh).
- The `/source` directory contains files sourced whenever a new shell opens, in alphanumeric order.
- The `/test` directory contains unit tests for especially complicated bash functions.
- The `/vendor` directory contains third-party libraries (zsh plugins as git submodules).
- The `/website` directory is a Docusaurus site rendering the README, these guide pages and the tips for GitHub
  Pages, deployed by [.github/workflows/deploy-docs.yml](../.github/workflows/deploy-docs.yml).
  `cd website && npm install && npm start` to develop locally.

## The "copy" step

Any file in the `/copy` subdirectory will be copied into `~/`.
Sensitive information is managed via git-secrets, but files that may need local edits
(like [copy/.gitconfig](../copy/.gitconfig)) should be _copied_ rather than linked as a second line of defense.
Because the file you'll be editing is no longer in `~/.dotfiles`, it's less likely to be accidentally committed
into your public dotfiles repo.

## The "link" step

Any file in the `/link` subdirectory gets symlinked into `~/` with `ln -s`.
Edit one or the other, and you change the file in both places.
Don't link files containing sensitive data, or you might accidentally commit that data!
If you're linking a directory that might contain sensitive data (like `~/.ssh`) add the sensitive files to your
[.gitignore](../.gitignore) file!

## The "init" step

Scripts in the `/init` subdirectory will be executed. A whole bunch of things will be installed, but _only_ if they aren't already.

### macOS

- XCode Command Line Tools via [init/11_macos_xcode.sh](../init/11_macos_xcode.sh)
- Homebrew via [init/20_homebrew.sh](../init/20_homebrew.sh)
- Homebrew recipes via [init/31_homebrew_recipes.sh](../init/31_homebrew_recipes.sh)
- Homebrew casks via [init/32_macos_homebrew_casks.sh](../init/32_macos_homebrew_casks.sh)

### Linux / WSL

- Flatpak (Linux desktop) via [init/21_linux_flatpak.sh](../init/21_linux_flatpak.sh) and
  [init/32_linux_flatpak_apps.sh](../init/32_linux_flatpak_apps.sh)
- Winget (WSL) via [init/22_wsl_winget.sh](../init/22_wsl_winget.sh) and
  [init/32_wsl_winget_apps.sh](../init/32_wsl_winget_apps.sh)
- Homebrew via [init/20_homebrew.sh](../init/20_homebrew.sh)
- Homebrew recipes via [init/31_homebrew_recipes.sh](../init/31_homebrew_recipes.sh)

### All platforms

- SSH config and private keys via [init/10_ssh_private_keys.sh](../init/10_ssh_private_keys.sh)
- Git hooks (symlinked from `/hooks`) via [init/12_git_hooks.sh](../init/12_git_hooks.sh)
- Sublime Text settings via [init/51_sublime_text.sh](../init/51_sublime_text.sh)

[dotfiles]: ../bin/dotfiles
