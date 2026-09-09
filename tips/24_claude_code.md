<!-- DOCTOC SKIP -->

# Claude Code Integration

This repo has small helpers that keep Claude Code's settings in sync with `git secret` and stay diff-clean.
They run automatically via the pre-commit hook; you can also invoke them directly.

## Tip 24.1: `sync-claude-deny`

Reads tracked paths from `.gitsecret/paths/mapping.cfg` and adds them to Claude Code's `permissions.deny` list in `.claude/settings.json`.
Prevents Claude from accidentally reading or editing secret files.

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

### `check-md-limits` — size limits on agent-loaded markdown

```bash
bin/check-md-limits                        # every tracked markdown file
bin/check-md-limits --no-warn              # errors only, as CI runs it
bin/check-md-limits --update-baseline F... # pin a long file at its current size
```

Fails on any line over 150 characters (front matter, code fences, table rows and URLs excepted) and any file over
its type's cap — 50 lines for a rule or project `CLAUDE.md`, 75 for the global one, 100 for a skill, 150
otherwise, each with a lower line to aim under. It notes a file nearing its cap without blocking, and skips any directory holding a `VENDORED.md`.
`.md-baseline` pins files that were already long when the limits landed: a pinned file warns only if it grows
past its recorded size, and `--update-baseline` lowers a pin but never raises one.
Claude-loaded files (`CLAUDE.md`, `SKILL.md`, `claude/`, `.claude/`) count line for line — every one costs tokens;
human-facing pages count content, so comments, badge blocks and the doctoc ToC are free.
A `PostToolUse` hook runs it on any markdown you edit, so a violation surfaces while the change is in hand.
The pre-commit hook runs it over staged markdown; CI runs the error-only form over the whole repo.

`hooks/pre-commit` runs both helpers above automatically when you commit changes that could affect Claude Code's settings:

- Touching `.gitsecret/paths/mapping.cfg` → runs `sync-claude-deny` and re-stages the resulting `.claude/settings.json`.
- Touching `.claude/settings.json` → runs `sort-claude-settings` and re-stages it.
- Adding or removing an alias, function or `bin/` script without staging anything under `tips/` → prints an advisory reminder (never blocks).

So you never end up with stale deny rules or shuffled settings arrays in commits.
The hook does other things too (e.g. doctoc + markdownlint on staged markdown) — see `hooks/pre-commit` for the whole picture.
Symlinked into `.git/hooks/pre-commit` by `init/12_git_hooks.sh`.

## Tip 24.4: Shared config and skills in `~/.claude`

Everything under `claude/` is symlinked into `~/.claude/` by [init/52_macos_claude.sh](../init/52_macos_claude.sh),
so every machine gets the same Claude Code context from one place:

- `claude/CLAUDE.md` → `~/.claude/CLAUDE.md` — global instructions loaded into every session.
- `claude/skills/` → `~/.claude/skills/` — reusable skills, one directory per skill with a `SKILL.md`.
- `claude/rules/` → `~/.claude/rules/` — path-scoped rules that load only when a file matching their
  `paths:` glob is read, rather than on every session like `CLAUDE.md`.
- `claude/docs/` → `~/.claude/docs/` — reference material a skill, rule or `CLAUDE.md` line points at,
  loaded only when something sends you there.
- `claude/statusline-command.sh` → `~/.claude/statusline-command.sh` — the status line.
  Row 1 is the working directory and git branch, styled like the zsh prompt
  ([link/.omz-custom/andrelin.zsh-theme](../link/.omz-custom/andrelin.zsh-theme)), then the model;
  row 2 is the context and rate-limit bars.

Only these entries are linked; machine-local state (`projects/`, `sessions/`, `history.jsonl`) stays untouched.
Anything already at one of those paths is moved into `backups/` first, and the run tells you so.

Add a skill by creating `claude/skills/<name>/SKILL.md` with `name` and `description` front-matter.
Because `skills/` is linked as a directory, it shows up in `~/.claude` immediately — no need to re-run `dotfiles`.
