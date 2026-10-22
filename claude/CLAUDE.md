# Global Instructions

## Identity

**This file is itself published**, from a personal-public repo: nothing customer-specific goes in it however the
request is phrased — their conventions belong in that customer's own tree.
Personal GitHub account `andrelin`; company org `uptimeconsulting`. The company is Uptime Consulting AS where a
legal name belongs, otherwise Uptime or Uptime Consulting; `uptimeconsulting` is a slug, never prose.

## Work contexts — who reads what you commit

Resolve from `git remote get-url origin`, first match wins, never from the directory path; both unknowns resolve upward,
so an unreadable remote is **customer** (an origin-less repo in a temp directory is **personal**) and undeterminable visibility is **public**.
Company org or an owner listed in `~/.claude-company-orgs` → **company**; another owner → **customer**; the personal account
with `uptime` in the repo name (case-insensitive) → **company**; otherwise **personal**, split by `gh repo view --json visibility`.

| Level | Bar on what you commit | History and remote |
| --- | --- | --- |
| personal private | not committing secrets | yours, push and merge included |
| personal public | world-readable forever: no customer names, hostnames, internal tooling, secrets | yours |
| company | also showcase quality: reviewed, green CI and a readable history before it reaches `main` | yours |
| customer | the client's codebase; their `CLAUDE.md` wins over this file | the user's |

**Where history and the remote are the user's** (customer) these are **forbidden**: `git commit`,
`commit --amend`, `cherry-pick`, `revert`, `push` in any form, opening or merging PRs, any conflicted rebase or
merge — `--abort` and hand back. `git add`, `restore`, `checkout`/`switch`, `stash`, `branch` (ref only), `fetch`,
inspection and a clean zero-conflict rebase or merge are fine; draft the message for the user to run.
`~/.claude/hooks/work-context.sh` enforces this list and reports the level at session start; a block is final — draft the command for the user.
At customer level the one platform write it allows is `issue create`, where `work-context.sh can-file-issue` prints a tool.

**An approval covers one action, not a policy** — it expires with the change in front of you, so ask again.
Before customer work read the `CLAUDE.md` at the root of that tree; how a level applies, why, and the guard's gaps: `~/.claude/docs/work-contexts.md`.

## Durable context lives in the repo

The user works from more than one machine, so machine-local Claude state (`~/.claude/projects/…/memory/`) silently
desyncs. On personal and company work durable project context goes in the repo, never in memory, including when the
user says "remember this" — bar one pointer memory recording this rule, so a fresh session finds it before it can
break it. Personal context is the exception, in a gitignored `CLAUDE.local.md`
(`~/.claude/docs/claude-local-md.md`); customer context stays outside the repos, in that customer's tree.
**No hardcoded absolute paths in repo-tracked files** — repos sit at different paths on different machines.

## Code review — locally, never through the platform

On customer work — including inside a `/code-review` run, which loads its own skill and not this file
— read the diff from the local clone, never the platform's API or web UI, and post nothing back (no `--comment`,
no inline comments) unless the user says so. Set up with `git fetch origin main && git diff origin/main...HEAD`.

## Language

Everything Claude writes is English: code, comments, commits, docs, plans, every part of a PR or MR — whatever
language colleagues are using in the thread, and however short the thing is.
Norwegian — Nynorsk, even when the user writes Bokmål — in conversation only, and only when the user leads;
quote a colleague's Bokmål verbatim rather than correcting it. Default to English when in doubt.

## Working on code

- **Every file ends with a trailing newline.** Tests, comments, imports, proving a cause and running the project's
  formatters are `~/.claude/rules/writing-code.md`, which loads when you open a source file.
- **Gradle:** `gradle`, not `./gradlew` (oh-my-zsh resolves the wrapper). **Docker** not running: ask the user to start it and wait; never launch it.
- **Dependabot and Renovate PRs:** never close one by hand or target one with `closes #N` — `dependency-bot-prs`.
  **Skills:** a personal skill shadows a same-named project one, and **where a plugin skill covers the same ground
  as a personal one, invoke the personal one** — `writing-plans` over `superpowers:writing-plans`,
  `reviewing-locally` over `superpowers:requesting-code-review`. § *Work contexts* outranks every skill, plugin
  ones included: read those for technique, never for what is allowed (`~/.claude/docs/skill-precedence.md`).
