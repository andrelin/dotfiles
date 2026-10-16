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

`hooks/pre-commit` runs both helpers above when a commit could affect Claude Code's settings:

- Touching `.gitsecret/paths/mapping.cfg` → runs `sync-claude-deny`, re-staging `.claude/settings.json`.
- Touching `.claude/settings.json` → runs `sort-claude-settings` and re-stages it.
- Adding or removing an alias, function or `bin/` script without staging anything under `tips/` → an advisory
  reminder that never blocks.

So no commit carries stale deny rules or shuffled settings arrays. It does more besides — doctoc, markdownlint
and the size limits on staged markdown, though only for files with no unstaged changes, since re-staging a
partially staged file would commit hunks you left out — and `init/12_git_hooks.sh` symlinks it into `.git/hooks/`.

## Tip 24.4: Shared config and skills in `~/.claude`

Everything under `claude/` is symlinked into `~/.claude/` by [init/52_macos_claude.sh](../init/52_macos_claude.sh),
so every machine that runs it gets the same Claude Code context from one place.
The `_macos_` marker means it is not selected by default on Linux or WSL, where you tick it by hand:

- `claude/CLAUDE.md` → `~/.claude/CLAUDE.md` — global instructions loaded into every session.
- `claude/skills/` → `~/.claude/skills/` — reusable skills, one directory per skill with a `SKILL.md`.
- `claude/rules/` → `~/.claude/rules/` — path-scoped rules that load only when a file matching their
  `paths:` glob is read, rather than on every session like `CLAUDE.md`.
- `claude/docs/` → `~/.claude/docs/` — reference material a skill, rule or `CLAUDE.md` line points at,
  loaded only when something sends you there.
- `claude/statusline-command.sh` → `~/.claude/statusline-command.sh` — the status line: working directory, git
  branch and model on row 1, styled like the zsh prompt
  ([link/.omz-custom/andrelin.zsh-theme](../link/.omz-custom/andrelin.zsh-theme)); context and rate-limit bars
  on row 2.
- `claude/hooks/` → `~/.claude/hooks/` — hook scripts; `work-context.sh` blocks Claude's commits, pushes and
  platform writes on customer repos and names the work context at session start (Tip 24.6).
- `claude/shims/` → `~/.claude/shims/` — `git`, `gh`, `glab` and `az` shims, first on `PATH` in Claude Code only, so the
  guard sees aliases, functions and scripts too; waive it once with `! WORK_CONTEXT_WAIVE=1 git push` at the prompt.

Only these entries are linked; machine-local state (`projects/`, `sessions/`, `history.jsonl`) stays untouched,
and anything already at one of those paths is moved into `backups/` first.

Add a skill by creating `claude/skills/<name>/SKILL.md` with `name` and `description` front matter; because
`skills/` is linked as a directory, it appears in `~/.claude` immediately, with no need to re-run `dotfiles`.

## Tip 24.5: `check-md-limits` — markdown size limits

```bash
bin/check-md-limits                        # every tracked markdown file
bin/check-md-limits --no-warn              # errors only, as CI runs it
bin/check-md-limits --update-baseline F... # pin a long file at its current size
```

Fails on a line over 150 characters (front matter, code fences, table rows and URLs excepted) or a file over its
type's cap: 50 lines for a rule or project `CLAUDE.md`, 75 for the global one, 150 for a skill, 200 otherwise.
A skill's `description` is capped at 300 characters, since every session's skill list carries it.
Nearing a cap is a note, not a failure; a directory holding a `VENDORED.md` is skipped, and a plan file or follow-up tracker has no length cap.
Claude-loaded files count line for line, since every line costs tokens on every task; human-facing pages count
content, so comments, badge blocks and a doctoc ToC are free.
`.md-baseline` pins a file at a length you have decided not to shorten — it fails only if it grows past that.
A `PostToolUse` hook runs it on any markdown you edit, the pre-commit hook covers staged files, and CI runs the
error-only form over the whole repo.

## Tip 24.6: `claude-settings-merge`

Registers the dotfiles-owned hook entries and deny rules in the machine-local `~/.claude/settings.json`, leaving
every other key and every other hook alone.

```sh
claude-settings-merge hooks ~/.claude/settings.json       # register the work-context guard
claude-settings-merge hardening ~/.claude/settings.json   # credential, rc-file and marker deny rules; load AGENTS.md
```

Both are safe to repeat, `hardening` never overrides an `instructionFiles` you set, and `dotfiles` runs both.
`hardening` denies the checkout's `link/.ssh/keys` by its `$DOTFILES` path, and skips only that rule when `DOTFILES` is unset.
Exits 1 with the file untouched when `jq` (or, for `hooks`, `~/.claude/hooks/work-context.sh`) is missing, or the file isn't valid JSON.

From `bin/claude-settings-merge`.
