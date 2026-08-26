<!-- DOCTOC SKIP -->

# Dotfiles

Personal dotfiles for macOS, Ubuntu, WSL 2, and RHEL.

## Repo-only context (multi-machine constraint)

The global § *Durable context lives in the repo* governs here: durable context goes into `CLAUDE.md`, `tips/`
or `docs/` — never into machine-local Claude state, which desyncs silently between the user's machines.
Two things specific to this repo:

- **This repo is where the global rules themselves live** (`claude/CLAUDE.md`, `claude/skills/`), so "write it to
  the repo" and "write it to the global instructions" can be the same edit here. Pick by scope: a rule about
  *dotfiles* goes in this file, a rule about *how Claude works everywhere* goes in `claude/CLAUDE.md`.
- **No hardcoded absolute paths in repo-tracked files** — use repo-root-relative paths or
  `"$(git rev-parse --show-toplevel)/…"`, since the repo is checked out at different paths on different machines.

## Primary platform

The user runs macOS day-to-day; Ubuntu, WSL 2 and RHEL are secondary but still in occasional use.
When tips and docs cover commands, keyboard shortcuts or paths that differ between platforms, **lead with macOS**
and include the Linux/WSL variant after — `Cmd / Ctrl + X`, `pbcopy` before `xclip`,
`Cmd + N (Alt + Insert on Linux/WSL)`.
Never drop the non-macOS variant; the user works on those systems often enough to need the right command.
Cross-platform helpers in `source/` and `bin/` should still work everywhere.

## Script conventions

Init and source scripts follow strict numbering conventions. **Always** consult the README in each directory before creating or renaming scripts:

- `init/README.md` — numbered by dependency order (10s prerequisites, 20s package managers, 30s packages, etc.)
- `source/README.md` — numbered by category (01–09 core, 10–19 languages, 20–29 tools, etc.)

Placing a script in the wrong range will break dependency ordering or make the codebase harder to navigate.

## OS detection

Scripts use filename conventions and code guards for platform targeting:

- `_macos_` in filename → auto-deselected on non-macOS
- `_linux_` in filename → auto-deselected on non-Linux (Ubuntu, RHEL)
- `_ubuntu_`, `_ubuntu_desktop_`, `_rhel_` in filename → auto-deselected off that specific distro
- `_wsl_` in filename → auto-deselected on non-WSL
- `_personal_` in filename → default unchecked
- Code guards (`is_macos || return 1`, etc.) are a second defense

The marker names are exactly the `is_*` checks `get_os` iterates in `bin/dotfiles`.
A marker only sets the **default** selection in the menu; it never blocks a script the user ticks by hand.

WSL is **not** considered Linux for file selection purposes — it has its own scripts.

## How it works

The main entry point is `bin/dotfiles`. It processes three directories in order:

1. **`copy/`** — files are copied into `$HOME` (used for files that may need local edits, as a second line of defense alongside git-secrets)
2. **`link/`** — each top-level item is symlinked into `$HOME` (`link/.ssh` → `~/.ssh`, `link/.zshrc` → `~/.zshrc`).
   Sensitive files in linked directories must be gitignored.
3. **`init/`** — scripts are run once (selected interactively, cached in `caches/init/selected`)

Shell startup: `.zshrc` (or `.bashrc`) sources every `*.sh`/`*.zsh` file in `source/` in filename order via the
`src` function.
Never modify `.zshrc` or `.bashrc` directly — add aliases, functions and settings to the appropriate file in
`source/` instead.

Because `link/` items are symlinked as-is, directories like `link/.ssh` become the actual `~/.ssh`.
Files written there by other tools (e.g. 1Password) appear in the repo but are gitignored.

`vendor/` contains git submodules (zsh plugins) sourced by `source/99_zsh-modules.zsh`.

## App configuration

`conf/` stores app settings that are linked into app-specific locations by dedicated init scripts (not by the `do_stuff` handler):

- `conf/sublime-text/` — linked by `init/51_sublime_text.sh` into Sublime Text's `Packages/User/`
- `conf/intellij/` — linked by `init/50_macos_intellij.sh`

**Note:** `conf/` is unrelated to the old `config/` / `do_stuff config` feature from the upstream fork,
which was removed years ago. Do not confuse them.

## Markdown conventions

Every markdown file either carries doctoc start/end markers or a `<!-- DOCTOC SKIP -->` comment at the top —
never a silent default. doctoc requires the **uppercase** form.
Rule of thumb: markers when a file has more than 5 H2/H3 headings, otherwise SKIP.

**`claude/` and `.claude/` are exempt** — `hooks/pre-commit` and `.github/workflows/markdown.yml` both exclude
them. A ToC is a navigation aid for humans browsing on GitHub, and nothing under either is read that way; both are
context loaded by an agent, where a ToC is noise.
Don't add `<!-- DOCTOC SKIP -->` there — markdownlint still covers them.

The pre-commit hook runs doctoc + `markdownlint-cli2 --fix` on staged markdown;
both tools are installed by `init/34_npm_globals.sh` when `dotfiles` runs.

## Tips system

`TIPS.md` at the repo root is a GitHub landing index; the content lives in `tips/<NN>_<name>.md`,
one file per category, read by the `tips` shell function (`source/46_tips.sh`).

**Any change to a user-facing alias, function or script under `source/` or `bin/` updates its tip in the same
commit** — decade meanings, the heading shape the `tips` function parses, numbering stability and the style bar
are the `writing-tips` skill.
That same-commit rule also covers `README.md`, `init/README.md`, `source/README.md` and this file when conventions
change: docs are part of the change, not a follow-up.

## Documentation site

`website/` is a Docusaurus site rendering the repo's docs to GitHub Pages at `https://dotfiles.lindjo.no`.
It is build-time tooling, not part of the `dotfiles` install flow.
Source-of-truth docs are edited in their canonical locations and gathered into `website/docs-generated/`
(gitignored) at build time — never edit a generated copy.
Registering new paths, MDX pitfalls and the deploy trigger are the `docs-site` skill.

## Dependabot and Renovate PRs

The rule is global (§ *Dependabot and Renovate PRs*) and detailed in the `dependency-bot-prs` skill.
Repo-specific: **the Renovate dependency-dashboard issue here is #3** — working state, not a task. Leave it open.

## CI philosophy

This repo has no PRs and a single user — pushes go straight to main, and the production environment is whatever
is on the user's machine. CI exists to surface "this needs your attention" promptly, not to gate merges.

Therefore: every workflow runs on `push`, fails hard on any violation, and never uses `continue-on-error` or
informational-only modes.
Scheduled runs supplement push runs to catch drift while the repo is idle (e.g. external link rot).
Don't add soft-fail modes when proposing new CI.

## Infrastructure tooling is optional

Kubernetes and Kafka tooling (`tips/40_kubernetes_cli.md`, `tips/41_kafka_cli.md`, `recipes_optional` in
`init/31_homebrew_recipes.sh`) is not auto-installed.
The current machine reaches these via a customer VDI; future projects may install them locally via the
optional-recipes prompt.
Tips for these tools live in the repo regardless of install state, and each tip leads with its install command.
