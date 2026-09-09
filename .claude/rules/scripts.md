---
paths:
  - "init/**"
  - "source/**"
  - "bin/**"
---

# Scripts in `init/`, `source/` and `bin/`

**Both are sourced, never executed.** `init_do` in `bin/dotfiles` runs `source`, and `source/*` is sourced by
`.zshrc` / `.bashrc`, so bail with `return`, never `exit` — an `exit` kills the whole `dotfiles` run, or the
user's shell. Helpers (`e_header`, `e_success`, `e_arrow`, `e_error`) come from `bin/dotfiles`, already in scope.

**The number is the contract.** `init/` runs once at setup and `source/` on every shell, both in filename order.
Consult `init/README.md` or `source/README.md` for the right range **before** creating or renaming a script —
a wrong number breaks dependency ordering, or hides the script from where the next reader looks.

**Platform targeting is by filename.** A marker (`_macos_`, `_linux_`, `_ubuntu_`, `_rhel_`, `_wsl_`,
`_personal_`) sets the **default** menu selection only; it never blocks a script the user ticks by hand, and WSL
is **not** Linux here. Add a code guard (`is_macos || return 1`) as a second defence, since the filename alone
enforces nothing. Which marker deselects where: `.claude/docs/script-platform-markers.md`.

**CI runs shellcheck.** `init/*.sh`, `source/*.sh` and the `bin/` scripts are checked with
`shellcheck -x -s bash --severity=warning`, listed in `.github/workflows/shellcheck.yml`.
Run it before handing the change over.
