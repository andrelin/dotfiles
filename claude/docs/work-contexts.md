# Work contexts — the detail behind the four levels

The resolution order and the permission lists are in `~/.claude/CLAUDE.md` § *Work contexts*,
and the one-approval rule in § *Approvals*, both loaded before any git command.
This file carries the reasoning and the edge cases.

## Why the levels nest

Each level keeps the ones above it with the audience substituted.
Level 2's bar is *safe for anyone*. Level 3 keeps it whole, since a live audience is anyone, and adds showcase
quality; at 4 the same bar binds with "anyone" narrowed to the client.
A customer repo being private makes the reader smaller, not the care looser.

## Why the resolution order is what it is

- **Customer work is defined by inclusion,** in `~/.claude-customers`: defining it by exclusion blocked every unrelated
  folder and unknown owner, and the user has customer work rarely and lists it when it starts. The file's entry forms,
  how names match and when an unresolvable target fails closed: `~/.claude/docs/customers-file.md`.
- The company name marker lifts personal-account repos with `uptime` in the name from personal to company.
- Unknown visibility is public: guessing low is the only guess that can't be taken back.
- Repo locations differ between machines, so the level comes from the remote, bar three path-based rules: listed
  customer directories and names, the scratch carve-out and the `.claude-files-issues` marker.

## personal private — full autonomy

Commit, push, rebase, open PRs, merge PRs, full `gh` access.
Nothing leaves the user's own account, so the only bar is not committing secrets you'd rather not have in a history at all.

## personal public — full autonomy, but every commit is published

Same git permissions as private.
What changes is that the working tree and the **whole history** are world-readable and effectively permanent —
deleting a file later does not unpublish it.

Before committing, check the change carries none of:

- Customer names, their project names, internal tooling, hostnames or URLs.
- Secrets, tokens, keys — including in files that merely *look* like config.
- Anything from a customer tree that wandered in.

**Why:** the cost is asymmetric.
A missing rule costs a follow-up commit; a published one costs a history rewrite across every branch,
and every existing clone and fork keeps it anyway.

## company — full autonomy, held to a colleague's and an audience's eye

Demos, presentations, teaching material, and experiments with AI-driven development.
Same git and platform permissions as personal: commit, push, open and merge PRs, write to the tracker.
What it adds is a higher bar than personal public's, since anything committed may be walked through live in front
of colleagues or an audience:

- every change reaches `main` reviewed (`/code-review` at least) and with CI green — never pushed straight to `main`;
- the history reads as a story: one purpose per commit, no "fix typo" or "wip" left behind;
- code, tests and docs are the kind you would want on a slide, not merely working.

**Why:** the employer wants AI-driven development explored, which needs the agent to own the whole loop, history
and remote included. Tighten a single repo through its own `CLAUDE.md` where that proves wrong.
Project context still belongs in the repo — that is the multi-machine rule — but the user's own personal context stays out.

## customer — user owns the remote, careful by default

These are the **user's own defaults** for client work, not rules imposed by any client.
They exist because someone else's codebase is the wrong place to be surprising.
An engagement's own `CLAUDE.md` sits closer to the work and overrides anything here, in either direction —
read it at the root of that customer's tree before starting.

- Claude prepares the working tree; the user composes history and does every remote write — bar `issue create` where
  the guard allows it; issue reads through the CLI are fine.
- The rule is about *effect on history*, not command names.
  A rebase or merge that mints new content during conflict resolution violates it just as much as `git commit`.
- Prefer the local clone over the hosting platform's CLI (`gh`, `glab`, `az`, …) for reads and writes.
  Everything needed for the work is in the clone, and the user drives the platform themselves.
- The user keeps per-engagement permission rules alongside the engagement's own config; they apply to every subdirectory.

**Apply these only where `~/.claude-customers` lists the work.** Anything unlisted is the user's own, bar a target
the guard can't resolve while the file lists anything (`~/.claude/docs/customers-file.md`).

## An approval covers one action, not a policy

When the user waives a rule — "skip the PR this time", "push it" — that applies to the change in front of them and expires with it.
Approving the *content* of the next change ("yes, remove that line") is not approval to deliver it the same way.
Ask again, every time, however recently they said yes and however similar the next one looks.
This binds hardest where a repo's own `CLAUDE.md` sets the rule being waived — that file governs, and a one-off exception does not amend it.

## Enforcement — what the guard blocks, and what it can't see

`~/.claude/hooks/work-context.sh` is a `PreToolUse` hook on the shell and file-writing tools, registered by `bin/claude-settings-merge`.

- **It blocks at customer level only:** the forbidden git list, and every `gh`, `glab` or Azure DevOps `az` call off its read allowlist.
  It doesn't check `fj` at all: no customer uses Forgejo yet.
- **Strictest target wins,** so personal and company (§ *company*) block only a write that could reach customer: origin,
  `upstream`, `github` and `gh-resolved` remotes, push URLs, named targets — a personal fork's `gh pr create` to a listed customer's parent.
- **Exit 2,** because it beats allow rules and every permission mode, bypass included; a crash blocks too.
  The user's one-off waiver is `! WORK_CONTEXT_WAIVE=1 <command>`, which the shims honour and the guard blocks Claude from setting.
- **Shims** in `~/.claude/shims`, first on `PATH` in Claude Code only (session-start writes it to `CLAUDE_ENV_FILE`,
  since the Bash tool's shell snapshot is taken before `CLAUDECODE` is set), check the real argv that aliases, functions and scripts pass.
- **`issue create`** is allowed at customer level only to origin's own issues, below a `.claude-files-issues` marker
  in an ancestor of the repo under `$HOME`, for `gh` and `glab` only — `can-file-issue` never offers `fj` for customer work;
  only the user creates the marker, and the guard blocks Claude's writes to it.
- **Revealed git-secret files, at every level:** a `Read`, `Grep` `path`, file write or shell word naming a path the
  nearest `.gitsecret/paths/mapping.cfg` lists, and `git secret reveal|cat|changes`; not a `Grep` over a directory or an interpreter opening one.
- **Accepted gaps:** a script calling `/usr/bin/git` by absolute path, past the shims; a GraphQL mutation sent from a file;
  `GH_REPO=x; export GH_REPO`; a script or an interpreter (`python3 -c`) writing the marker or the customers file; a git alias's arguments past its
  first word; `curl` writes, which it never parses; every `fj` call; a script that sets `HOME` elsewhere before a git write,
  which the shims then judge against that home's customers file; a `git clone` and a write in the new clone in one
  call, or a `git worktree add` and a write in the new worktree, where the directory doesn't exist yet when the hook
  runs, or a `git config` that picks a push target and the push in one call, so only the shims judge the write;
  and a script, a tool outside its list, `xargs` given the name on stdin, a glob not starting with a dot, a name
  held in a variable (`rm ~/$f`) or built by a command substitution, or a copy or sync of a folder into `$HOME`,
  removing or overwriting the customers file.
  More broadly, the guard is built for the plain forms Claude would issue: an evasion form (a glob, brace list,
  zsh alternation, `eval` prefix, glued redirection or `find` predicate) or a name or URL its matching rules don't
  anticipate may slip past, and is a gap by design rather than a bug to chase.
  A separator inside quotes blocks falsely, failing safe.
  Hooks don't run before the workspace-trust prompt is accepted, in `claude -p --bare`, or in cloud routines.
- Use literal paths, never shell variables, in the cd or git -C that precedes a git write:
  the work-context guard can't expand variables, and while any customer is listed it blocks the command as an
  unknown directory, along with everything else in that call.
- **The prose still binds where no hook sees:** what goes *into* a commit, MCP tools, the platforms' web UIs.
