# Dotfiles

Personal dotfiles for macOS, Ubuntu, WSL 2, and RHEL.

## Script conventions

Init and source scripts follow strict numbering conventions. **Always** consult the README in each directory before creating or renaming scripts:

- `init/README.md` — numbered by dependency order (10s prerequisites, 20s package managers, 30s packages, etc.)
- `source/README.md` — numbered by category (01–09 core, 10–19 languages, 20–29 tools, etc.)

Placing a script in the wrong range will break dependency ordering or make the codebase harder to navigate.

## OS detection

Scripts use filename conventions and code guards for platform targeting:

- `_macos_` in filename → auto-deselected on non-macOS
- `_linux_` in filename → auto-deselected on non-Linux (Ubuntu, RHEL)
- `_wsl_` in filename → auto-deselected on non-WSL
- `_personal_` in filename → default unchecked
- Code guards (`is_macos || return 1`, etc.) are a second defense

WSL is **not** considered Linux for file selection purposes — it has its own scripts.

## How it works

The main entry point is `bin/dotfiles`. It processes three directories in order:

1. **`copy/`** — files are copied into `$HOME` (used for files that may need local edits, as a second line of defense alongside git-secrets)
2. **`link/`** — each top-level item is symlinked into `$HOME` (e.g., `link/.ssh` → `~/.ssh`, `link/.zshrc` → `~/.zshrc`). Sensitive files in linked directories must be gitignored.
3. **`init/`** — scripts are run once (selected interactively, cached in `caches/init/selected`)

Shell startup: `.zshrc` (or `.bashrc`) sources every `*.sh`/`*.zsh` file in `source/` in filename order via the `src` function. Never modify `.zshrc` or `.bashrc` directly — add aliases, functions, and settings to the appropriate file in `source/` instead.

Because `link/` items are symlinked as-is, directories like `link/.ssh` become the actual `~/.ssh`. Files written there by other tools (e.g., 1Password) appear in the repo but are gitignored.

`vendor/` contains git submodules (zsh plugins) sourced by `source/99_zsh-modules.zsh`.

## App configuration

`conf/` stores app settings that are linked into app-specific locations by dedicated init scripts (not by the `do_stuff` handler):

- `conf/sublime-text/` — linked by `init/51_sublime_text.sh` into Sublime Text's `Packages/User/`
- `conf/intellij/` — linked by `init/50_macos_intellij.sh`
