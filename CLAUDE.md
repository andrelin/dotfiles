<!-- DOCTOC SKIP -->

# Dotfiles

Personal dotfiles for macOS, Ubuntu, WSL 2 and RHEL, installed by `bin/dotfiles`.
It copies `copy/` into `$HOME`, symlinks each top-level item of `link/` into `$HOME` (`link/.ssh` → `~/.ssh`),
then runs the `init/` scripts you select, once each.
`.zshrc` sources every `*.sh`/`*.zsh` in `source/` in filename order; `vendor/` holds the zsh plugin submodules.
The walkthrough is `docs/how-it-works.md`.

- **Never edit `.zshrc` or `.bashrc`** — aliases, functions and settings go in the right file in `source/`.
- A linked directory *is* the real one, so whatever another tool writes into `~/.ssh` appears in `link/.ssh`.
  Sensitive files there must be gitignored.

## This repo also holds the global Claude config

`claude/` is symlinked to `~/.claude/`, so "write it to the repo" and "write it to the global instructions" can
be the same edit. Pick by scope: a rule about *dotfiles* goes here, one about *how Claude works everywhere* goes
in `claude/CLAUDE.md`.
This is a **personal public** repo — everything committed is published, per the global § *Work contexts*.

## Conventions

- **Lead with macOS** where a command, shortcut or path differs by platform, with the Linux/WSL form after
  (`Cmd / Ctrl + X`, `pbcopy` before `xclip`); never drop the non-macOS variant.
- **Docs ship with the change.** A user-facing alias, function or script under `source/` or `bin/` updates its
  tip in the same commit, as do the READMEs and this file when a convention changes — the `writing-tips` skill.
- CI runs on `push` and fails hard. **No `continue-on-error`, no informational-only modes** — don't propose one.
- The Renovate dependency-dashboard issue is **#3**: working state, not a task. Leave it open.
