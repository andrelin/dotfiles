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

`hooks/pre-commit` runs both helpers above when a commit could affect Claude Code's settings, and checks more:

- Touching `.gitsecret/paths/mapping.cfg` → runs `sync-claude-deny`, re-staging `.claude/settings.json`.
- Touching `.claude/settings.json` → runs `sort-claude-settings` and re-stages it.
- Any invisible Unicode or NUL byte in the staged copy of a file in Tip 24.9's default set, not only the ones being
  committed → blocks the commit.
- Adding or removing an alias, function or `bin/` script without staging anything under `tips/` → an advisory
  reminder that never blocks.

So no commit carries stale deny rules, shuffled settings arrays or hidden characters in agent-loaded files.
It also runs doctoc, markdownlint and the size limits on staged markdown, though only for files with no unstaged changes, since re-staging a
partially staged file would commit hunks you left out.
`init/12_git_hooks.sh` symlinks the hook into `.git/hooks/`.

## Tip 24.4: Shared config and skills in `~/.claude`

Everything under `claude/` is symlinked into `~/.claude/` by [init/52_claude.sh](../init/52_claude.sh),
so every machine that runs it gets the same Claude Code context from one place.
It runs by default everywhere; on Linux, WSL or RHEL, tick it by hand once if an older saved selection leaves it unticked,
as the old script was deselected there by default (one that had ticked it is migrated).
It links:

- `claude/CLAUDE.md` → `~/.claude/CLAUDE.md` — global instructions loaded into every session.
- `claude/skills/` → `~/.claude/skills/` — reusable skills, one directory per skill with a `SKILL.md`.
- `claude/rules/` → `~/.claude/rules/` — path-scoped rules that load only when a file matching their
  `paths:` glob is read, rather than on every session like `CLAUDE.md`.
- `claude/docs/` → `~/.claude/docs/` — reference material a skill, rule or `CLAUDE.md` line points at,
  loaded only when something sends you there.
- `claude/statusline-command.sh` → `~/.claude/statusline-command.sh` — the status line: working directory, then git
  branch and model, styled like the zsh prompt
  ([link/.omz-custom/andrelin.zsh-theme](../link/.omz-custom/andrelin.zsh-theme)), then the session's topic in bold
  (its `/rename` name, else the AI-generated title); each of the three drops to a new row when it doesn't fit,
  and the context and rate-limit bars come last. It refreshes every 2 seconds, so a resized window re-lays it out.
- `claude/hooks/` → `~/.claude/hooks/` — hook scripts; `work-context.sh` blocks Claude's commits, pushes and platform
  writes on customer work, which is only what `~/.claude-customers` lists — write it on each machine with customer work,
  one `host/owner`, directory or customer name per line (syntax: `claude/docs/customers-file.md`) — and names the context at session start (Tip 24.6).
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
Blank lines and headings never count. Beyond those, Claude-loaded files count line for line, since every line
costs tokens on every task; human-facing pages count content, so comments, badge blocks and a doctoc ToC are free.
`.md-baseline` pins a file at a length you have decided not to shorten — it fails only if it grows past that.
A `PostToolUse` hook runs it on any markdown you edit, the pre-commit hook covers staged files, and CI runs the
error-only form over the whole repo.

## Tip 24.6: `claude-settings-merge`

Registers the dotfiles-owned hook entries and deny rules in the machine-local `~/.claude/settings.json`, leaving
every other key and every other hook alone.

```sh
claude-settings-merge hooks ~/.claude/settings.json       # register the work-context guard
claude-settings-merge hardening ~/.claude/settings.json   # credential, rc-file, marker and customers-file deny rules; load AGENTS.md
```

Both are safe to repeat, `hardening` never overrides an `instructionFiles` you set, and `dotfiles` runs both.
`hardening` denies the checkout's `link/.ssh/keys` by its `$DOTFILES` path, `~/`-relative when under `$HOME`, replacing
an earlier checkout's rule; it skips only that rule, and keeps an old one, when `DOTFILES` is unset.
Exits 1 with the file untouched when `jq` (or, for `hooks`, `~/.claude/hooks/work-context.sh`) is missing, or the file isn't valid JSON.

From `bin/claude-settings-merge`.

## Tip 24.7: `skill-trigger-eval` — does a skill's description fire?

Scores how often a skill's description makes Claude load it, over the queries in `test/skill-triggers/<skill>.json`,
three headless runs each, with the `skill-creator` plugin's `run_eval`.

```sh
skill-trigger-eval writing-plans                                   # score the current description
skill-trigger-eval writing-plans --description "Read before …"     # score a candidate; the file is untouched
skill-trigger-eval writing-plans --model sonnet                    # override the model
```

Every query is three real `claude -p` runs, so a 20-query set costs 60 runs per description, made one at a time:
in parallel each run sees the others' copies of the candidate and mostly takes the wrong one.
Each run has every tool call blocked by a hook, so a query is scored on the tool it reaches for without ever acting,
and is killed with its tool shells once decided; Ctrl-C or a plain `kill` stops every run still going.
The skill is moved out of `claude/skills/` for the run, since the installed copy outcompetes the candidate, which
hides it from every session on the machine until the run ends; a run killed with `-9` leaves
`caches/.skill-trigger-eval-moved` naming where it went, and the next run refuses until it is put back, and leaves
its undecided `claude` runs going: `pkill -f 'claude -p .* --include-partial-messages'`.
A failed or hung `claude` run fails the whole score rather than counting as a miss. The `tuning-skill-descriptions`
skill says how to use the numbers.

From `bin/skill-trigger-eval`.

## Tip 24.8: `ai` — start a stage of the workflow

Carries a piece of work from issue to reviewed change, handing each stage an artifact rather than chat history.
Each command starts an interactive `claude` running that stage's skill. From the plan on, one session drives the
rest: it implements, iterates the plan at each `## Revisit`, and runs the final code review, stopping only for
your decisions; the other commands start or resume a stage on its own.

```sh
ai issue "login fails on Safari"     # /writing-issues, sonnet: interviews you, then files or drafts
ai plan 12                           # /writing-plans, opus: an issue number, title or plain words
ai implement plan-login.md           # /implementing-plans, opus: resumes a run; plan files resolve against the repo root
ai review code plan-login.md         # /reviewing-in-rounds, opus; `ai review plan <file>` reviews a plan
```

The models are suggestions: override one per call with `ai --model haiku issue`, before the stage, or per shell
with `export AI_MODEL_PLAN=sonnet` (also `AI_MODEL_ISSUE`, `AI_MODEL_REVIEW`, and `AI_MODEL_IMPLEMENT` for the
implementer subagents, default sonnet).
Run it from a terminal: inside a Claude session it refuses.

From `bin/ai`.

## Tip 24.9: `check-hidden-unicode` — invisible characters in agent-loaded files

Flags zero-width and invisible characters, bidirectional controls, variation selectors (bar the emoji selector) and
Unicode tag characters, which can hide instructions from a reviewer while an agent still reads them.
Ordinary non-ASCII text and emoji pass; a ZWJ sequence is flagged at its zero-width joiner.
It prints `<file>:<line>: U+<HEX> <NAME>` per hit and exits 1; with no files it scans everything tracked under
`claude/` and any `.claude/` plus every `CLAUDE.md` and `AGENTS.md`, vendored skills included.
A NUL byte, which marks a file that isn't UTF-8 text, and a Git LFS pointer, whose text it can't see, are reported too.
A symlink is followed: staged, to the staged file it points at, reported under that file's path; on disk, under the link's.
A hit in a vendored skill blocks its re-sync like any other; its `VENDORED.md` says what to do.
Exit 2 trumps 1: a named file is missing, a file can't be read, the arguments are wrong, bash 4 is missing or git or perl failed.

```sh
bin/check-hidden-unicode                    # the default set
bin/check-hidden-unicode claude/rules/a.md  # named files
bin/check-hidden-unicode --cached           # the staged blobs, as pre-commit sees them
```

`hooks/pre-commit` runs it with `--cached`, and CI runs it with no arguments on every push and pull request,
a pull request's tree scanned by the base branch's copy of the script where the base has one.

From `bin/check-hidden-unicode`.
