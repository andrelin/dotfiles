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
1. On a fresh Mac, Homebrew and its bash are installed and the script restarts under that bash: everything after
   this needs bash 5.0 or newer, and macOS only ships 3.2. ([read more](installation.md))
1. Files in `/copy` are copied into `~/`, except on RHEL, which runs only the link and init steps.
   ([read more](#the-copy-step))
1. Files in `/link` are symlinked into `~/`. ([read more](#the-link-step))
1. You are prompted to choose scripts in `/init`. The installer auto-selects by OS (`_macos_` scripts only on
   macOS); `_personal_` scripts are default unchecked, and your choice is remembered in `caches/init/selected`.
1. Your chosen init scripts are sourced, in alphanumeric order. ([read more](#the-init-step))

On subsequent runs step 1 is skipped, step 2 updates the existing repo, step 3 is skipped once Homebrew's bash is
the one running, and step 6 remembers your last selection.

## Other subdirectories

- The `/backups` directory is created when needed: anything in `~/` that `/copy` or `/link` would overwrite goes there.
- The `/bin` directory contains executable shell scripts (including [dotfiles][dotfiles]) and symlinks to them, and is added to `$PATH`.
- The `/caches` directory contains cached files used by some scripts or functions.
- The `/claude` directory holds shared Claude Code config — `CLAUDE.md`, `skills/`, `rules/`, `docs/`, `hooks/`, `shims/` and
  the statusline script — symlinked into `~/.claude/` by [init/52_macos_claude.sh](../init/52_macos_claude.sh),
  leaving machine-local state (sessions, history) alone. `settings.json` stays machine-local too; the script only
  points its `statusLine` at the linked script and, through `bin/claude-settings-merge`, registers the two hook
  entries for the work-context guard in `hooks/work-context.sh`, and a `PostToolUse` one for `hooks/watch-main-ci.sh`
  that after a push to a default branch or a PR merge tells Claude to watch that branch's CI to green. Its `hardening` call adds deny rules: `Read` of
  credential files (`~/.ssh` keys, `~/.aws/credentials`, `~/.kube/config`, git, GnuPG and `gh` credentials, this repo's
  revealed `~/.ssh` files, and the checkout's `link/.ssh/keys` by its `$DOTFILES` path), `Edit`
  of the shell rc files, and creating the `.claude-files-issues` marker, so issue filing stays the user's opt-in.
  The `Read` rules also cover Bash's `cat`, `head`, `tail`, `sed` and `<`, but not `grep -r` over a parent directory
  or an interpreter (Python, Node) opening the file itself. The marker rules cover the Write and Edit tools, shell
  redirects and `touch`; `cp` or `mv` from a script and interpreters get past them, and only the guard hook backs
  that up. It also loads a repo's `AGENTS.md` beside any `CLAUDE.md` (why: `claude/docs/claude-local-md.md`).
  Static rules can't follow each repo's git-secret list, so the guard hook keeps revealed git-secret files from Claude
  in any repo: a `Read`, `Grep`, file write or shell word naming a path `.gitsecret/paths/mapping.cfg` lists, and
  `git secret reveal`, `cat` and `changes`. A `Grep` over a whole directory and interpreters opening a file get past it.
- The `/conf` directory stores app configuration (Sublime Text, IntelliJ), linked into place by dedicated init scripts.
- The `/docs` directory holds the guide pages split out of the README — this one and the [installation guide](installation.md).
- The `/hooks` directory contains git hooks that are symlinked into `.git/hooks/` by [init/12_git_hooks.sh](../init/12_git_hooks.sh).
- The `/renovate` directory holds the shared Renovate presets my other repos extend ([renovate/README.md](../renovate/README.md)).
- The `/source` directory contains files sourced whenever a new shell opens, in alphanumeric order.
- The `/test` directory contains unit tests for especially complicated bash functions, and the checks on the `/renovate` presets.
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

Any file in the `/link` subdirectory gets symlinked into `~/` with `ln -sf`.
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
- Node.js versions via [init/33_node_versions.sh](../init/33_node_versions.sh): the two latest LTS lines
  plus the latest release, the same rule as the JDKs

### Linux / WSL

- Flatpak (Linux desktop) via [init/21_linux_flatpak.sh](../init/21_linux_flatpak.sh) and
  [init/32_linux_flatpak_apps.sh](../init/32_linux_flatpak_apps.sh)
- Winget (WSL) via [init/22_wsl_winget.sh](../init/22_wsl_winget.sh) and
  [init/32_wsl_winget_apps.sh](../init/32_wsl_winget_apps.sh)
- Homebrew via [init/20_homebrew.sh](../init/20_homebrew.sh)
- Homebrew recipes via [init/31_homebrew_recipes.sh](../init/31_homebrew_recipes.sh)
- Node.js versions via [init/33_node_versions.sh](../init/33_node_versions.sh): the two latest LTS lines
  plus the latest release, the same rule as the JDKs

### All platforms

- SSH config and private keys via [init/10_ssh_private_keys.sh](../init/10_ssh_private_keys.sh)
- Git hooks (symlinked from `/hooks`) via [init/12_git_hooks.sh](../init/12_git_hooks.sh)
- Sublime Text settings via [init/51_sublime_text.sh](../init/51_sublime_text.sh)
- Strict line breaks in every registered Obsidian vault (macOS and Linux) via
  [init/54_obsidian.sh](../init/54_obsidian.sh)

[dotfiles]: ../bin/dotfiles
