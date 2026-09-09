---
paths:
  - "conf/**"
---

# `conf/` — app settings linked by their own init script

`conf/` holds app settings that a dedicated `init/` script links into an app-specific location.
The `do_stuff` copy/link/init handlers in `bin/dotfiles` never touch it, so a new subdirectory needs its own init script to reach anything.

- `conf/sublime-text/` — linked by `init/51_sublime_text.sh` into Sublime Text's `Packages/User/`.
- `conf/intellij/` — linked by `init/50_macos_intellij.sh`.

**`conf/` is unrelated to the old `config/` / `do_stuff config` feature** from the upstream fork, which was removed years ago.
Don't confuse them, and don't reintroduce the old handler when adding a new app.
