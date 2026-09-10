---
paths:
  - "init/**"
  - "source/**"
  - "bin/**"
---

# Scripts in `init/`, `source/` and `bin/`

**Both are sourced, never executed.** `init_do` in `bin/dotfiles` runs `source`, and `source/*` is sourced by
`.zshrc` / `.bashrc`, so bail with `return`, never `exit` — an `exit` kills the whole `dotfiles` run, or the
user's shell. Helpers (`e_header`, `e_success`, `e_arrow`, `e_error`) come from `bin/dotfiles`, already in scope,
and `src()` globs `*sh` in zsh but `*.sh` in bash, so a `source/*.zsh` file loads only under zsh.

**The number is the contract.** `init/` runs on every `dotfiles` invocation and `source/` on every shell, both in
filename order; the cache only pre-ticks the menu, so each script needs its own idempotence guard.
Consult `init/README.md` or `source/README.md` for the right range **before** creating or renaming one: a wrong
number breaks dependency ordering, or hides the script from where the next reader looks.

**Platform targeting is by filename, and only in `init/`.** A marker (`_macos_`, `_linux_`, `_ubuntu_`,
`_ubuntu_desktop_`, `_rhel_`, `_wsl_`, `_personal_`) sets the **default** menu selection in `init_files()`; it never
blocks a script the user ticks by hand, and nothing reads markers in `source/`. Add a code guard
(`is_macos || return 1`) as the real defence, since the filename alone enforces nothing.
Which marker deselects where, and why `_linux_` still fires on WSL: `.claude/docs/script-platform-markers.md`.

**Helpers stay cross-platform:** anything under `source/` or `bin/` runs on macOS, Ubuntu, WSL and RHEL unless its
filename marker says otherwise. **CI runs shellcheck** (`-x -s bash --severity=warning`) over globbed `init/*.sh`, `source/*.sh` and `test/*.sh`,
so a new script there needs no workflow edit, plus the `bin/` scripts, `hooks/pre-commit`, the linked
`.bashrc`/`.bash_profile` and `claude/statusline-command.sh`, listed individually in the workflow.
`source/*.zsh` is not checked: it is zsh, not bash. Run it before handing the change over.
