# `paths:` globs — how they match, and how they fail

A rule file's `paths:` list decides when it loads. The budget those files live under is
`~/.claude/rules/markdown-limits.md`; this is the matching behaviour.

`paths:` accepts globs; a rule without one loads unconditionally, like a `CLAUDE.md` section.

- **A glob that never matches produces no rule and no error.** Nothing tells you the rule is dead.
- **Prefer the `**/`-prefixed form** (`**/frontend/**` over `frontend/**`). It matches the same files and
  survives a git worktree, or a session started from a parent directory rather than the repo root.
  **The exception is a generic directory name** — `bin`, `conf`, `docs`, `test`. Prefixed, those match every
  vendored copy in the tree, so anchor them at the repo root and accept the worktree limitation.
- **Beware a directory name that's also a package name.** `**/database/**` matches every module's internals,
  not the top-level directory you meant.
- **Verify by opening a file the rule should cover and asking which rules loaded.** Ask it that way — asking
  "is `<phrase>` in your context" under-reports and will claim a loaded rule is absent.
  Check a file it should *not* cover too: an over-broad glob is the quieter failure.
