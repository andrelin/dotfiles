<!-- DOCTOC SKIP -->

# Sublime Text

Editor tips for Sublime Text. The shipped settings (preferences, key bindings, GitGutter config, snippets) live in `conf/sublime-text/` and are linked into Sublime's `Packages/User/` by `init/51_sublime_text.sh`.

## Tip 51.1: Package Control

The package manager. Install/remove/update packages from inside Sublime.

```
Cmd / Ctrl + Shift + P   Open the command palette
> Package Control: Install Package
> Package Control: Remove Package
> Package Control: List Packages
```

The package list this repo ships with is in `conf/sublime-text/Package Control.sublime-settings`; updating it there and re-running `dotfiles` keeps machines in sync.

## Tip 51.2: The `q` and `qq` Snippets

Custom snippets shipped via `conf/sublime-text/q.sublime-snippet` (and `qq.sublime-snippet`).

```
q  + Tab     # expands to the configured snippet
qq + Tab     # the alternative form
```

See the `.sublime-snippet` files for what each one inserts.
