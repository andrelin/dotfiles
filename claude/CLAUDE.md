# Global Instructions

## Identity — with § *Language* and the Gradle line, the only person-specific values here

Personal GitHub account `andrelin`; company org `uptimeconsulting`, plus any repo whose name contains `uptime` on
the personal account. The company is Uptime Consulting AS where a legal name belongs, otherwise Uptime or Uptime
Consulting; `uptimeconsulting` is a slug for URLs and remote matching, never prose.

## Work contexts — who reads what you commit

Resolve from `git remote get-url origin`, first match wins, never from the directory path. Both unknowns resolve
upward: an unreadable remote is **customer**, undeterminable visibility is **public**.
Company org or company marker → **company**; other owner → **customer**; otherwise **personal**, split by
`gh repo view --json visibility`.

| Level | Bar on what you commit | History and remote |
| --- | --- | --- |
| personal private | none beyond not committing secrets | full autonomy, including push and merge |
| personal public | world-readable forever — no customer names, hostnames, internal tooling, secrets | full autonomy |
| company | also safe for colleagues and a live audience | the user's |
| customer | the client's own codebase; their `CLAUDE.md` wins over this file | the user's |

**Where history and the remote are the user's** (company and customer), these are **forbidden**: `git commit`,
`commit --amend`, `cherry-pick`, `revert`, `push` in any form, opening or merging PRs, and any conflicted rebase or
merge — `--abort` and hand back. `git add`, `restore`, `checkout`/`switch`, `stash`, `branch`, `fetch`, inspection
and a clean zero-conflict rebase or merge are fine; draft the commit message and PR body for the user to run.

**An approval covers one action, not a policy.** It expires with the change in front of you — ask again.

Before customer work, read the `CLAUDE.md` at the root of that customer's tree.
Unsure how a level applies, or why: `~/.claude/docs/work-contexts.md`.

## Durable context lives in the repo

The user works from more than one machine, so machine-local Claude state (`~/.claude/projects/…/memory/`)
silently desyncs. On personal and company work durable project context goes in the repo, never in memory,
including when the user says "remember this". Personal context is the exception — a gitignored `CLAUDE.local.md`
(`~/.claude/docs/claude-local-md.md`) — and customer context stays outside the repos, in the customer tree.
**No hardcoded absolute paths in repo-tracked files** — repos sit at different paths on different machines.

## Code review — locally, never through the platform

On company and customer work — including inside a `/code-review` run, which loads its own skill and not this
file — read the diff from the local clone, never the platform's API or web UI, and post nothing back unless the
user says so. Set up with `git fetch origin main && git diff origin/main...HEAD`; rest: `reviewing-locally`.

## Language

Everything Claude writes is English: code, comments, commits, docs, plans, every part of a PR or MR.
Norwegian — Nynorsk, even when the user writes Bokmål — in conversation only, and only when the user leads.

## Working on code

- **Tests for every change**, each able to fail for a real reason — the `writing-tests` skill.
- **Comments are a last resort.** A rename or an extracted function beats one; keep only a non-obvious *why*, never
  a restatement of the code or a reference to anything outside the repo — the `cutting-comments` skill.
- **Never use star imports.** Expand any you touch, including ones you didn't add.
- **Every file ends with a trailing newline.**
- **Hold every cause as a hypothesis** until you reproduce or measure it — the `proving-causes` skill.
- **Run the project's own formatters and linters** in their fixing form before handing over, found from its
  config (`package.json`, Gradle tasks, `.pre-commit-config.yaml`, `.husky/`, `biome.json`, `ruff.toml`).
  Never run one the project doesn't configure; say so rather than silently skipping a broken one.
- **Gradle:** call `gradle`, not `./gradlew` — the oh-my-zsh plugin resolves the wrapper.
- **Docker:** if it isn't running, ask the user to start it and wait; never launch it yourself.
- **Dependabot and Renovate PRs:** never close one by hand or target one with `closes #N` — `dependency-bot-prs`.
- **Skills:** a personal skill shadows a same-named project one; § *Work contexts* outranks every skill, plugin
  ones included — read those for technique, never for what is allowed (`~/.claude/docs/skill-precedence.md`).
