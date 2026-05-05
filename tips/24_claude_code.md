<!-- DOCTOC SKIP -->

# Claude Code Integration

This repo has small helpers that keep Claude Code's settings in sync with `git secret` and stay diff-clean. They run automatically via the pre-commit hook; you can also invoke them directly.

## Tip 24.1: `sync-claude-deny`

Reads tracked paths from `.gitsecret/paths/mapping.cfg` and adds them to Claude Code's `permissions.deny` list in `.claude/settings.json`. Prevents Claude from accidentally reading or editing secret files.

```sh
sync-claude-deny             # update settings.json in place
sync-claude-deny --check     # exit non-zero if settings.json would change (CI / hook use)
```

From `bin/sync-claude-deny`.

## Tip 24.2: `sort-claude-settings`

Sorts arrays in `.claude/settings.json` so `git diff` is stable across runs (no order churn).

```sh
sort-claude-settings         # rewrite settings.json with sorted arrays
```

From `bin/sort-claude-settings`.

## Tip 24.3: Pre-Commit Automation for Claude Code

`hooks/pre-commit` runs both helpers above automatically when you commit changes that could affect Claude Code's settings:

- Touching `.gitsecret/paths/mapping.cfg` → runs `sync-claude-deny` and re-stages the resulting `.claude/settings.json`.
- Touching `.claude/settings.json` → runs `sort-claude-settings` and re-stages it.

So you never end up with stale deny rules or shuffled settings arrays in commits. The hook does other things too (e.g. doctoc + markdownlint on staged markdown) — see `hooks/pre-commit` for the whole picture. Symlinked into `.git/hooks/pre-commit` by `init/12_git_hooks.sh`.
