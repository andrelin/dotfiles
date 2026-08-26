# Global Instructions

Shared Claude Code rules, tracked in dotfiles so every machine gets the same context.
Symlinked to `~/.claude/CLAUDE.md` by `init/52_macos_claude.sh`.

**The repo holding this file is level 2 — personal public** (see § *Work contexts*), so the publish bar applies
to the file itself: no customer names, internal tooling, hostnames or project specifics.
Customer-specific conventions belong in that customer's own tree, never here.

## Identity — the values a fork replaces

Every person-specific value lives in this one table; the rest of the file is generic and works unchanged.
Two sections are also person-specific: § *Norwegian vs English* and § *Gradle* — rewrite or drop those.

| Value | This user | Used for |
| --- | --- | --- |
| Personal GitHub account | `andrelin` | resolving personal work |
| Company GitHub org | `uptimeconsulting` | resolving company work — exact owner match |
| Company repo marker | repo name contains `uptime`, case-insensitive | company repos that live on the personal account |
| Company name, legal | Uptime Consulting AS | where a formal name is wanted |
| Company name, everyday | Uptime · Uptime Consulting | prose, commit messages, chat |

**Match the register when writing the company name.** `Uptime` in ordinary prose and chat, `Uptime Consulting`
when the fuller name reads better, `Uptime Consulting AS` only where a legal name belongs.
`uptimeconsulting` is the org slug — it appears in URLs and remote matching, never in prose.

## Work contexts — four levels of care

Four levels of escalating care, about **who can read what you commit**; the git-permission rules ride along.
Each level keeps the ones above it with the audience substituted — level 2's bar is *safe for anyone*, and at 3
and 4 the same bar still binds with "anyone" narrowed to colleagues, or to the client.
A customer repo being private makes the reader smaller, not the care looser.

**Never infer the level from the directory path** — repo locations differ between machines
(`~/src/foo` on one, `~/src/<group>/foo` on another).

**Resolve in this order**, first match wins, from `git remote get-url origin` and § *Identity*:

1. The owner is the company org → **company**.
2. The owner is not the personal account, or the remote can't be read → **customer**.
3. The repo name contains the company marker → **company**.
4. Otherwise personal — `gh repo view --json visibility` decides **personal public** vs **personal private**.

Rule 1 comes first because the company org is not the personal account and would otherwise fall to customer.
Rule 3 catches employer work that lives on the personal account instead of the org — both are company work,
so both get the company rules.

Customer work is defined by *exclusion*, so this keeps working for new customers with no edits here.
**Both unknowns resolve upward**: an unreadable remote is customer, and a repo whose visibility you can't
determine is public. Guessing low is the only guess that can't be taken back.

| Level | Who reads what you commit | What it adds |
| --- | --- | --- |
| 1 · **personal private** | the user | nothing — full autonomy |
| 2 · **personal public** | anyone, forever | everything committed must be safe to publish |
| 3 · **company** | colleagues, and an audience watching live | must also be safe for other developers; user owns history and remote |
| 4 · **customer** | the client, in their own codebase | careful by default; user owns the remote; the engagement's rules win |

**An approval covers one action, not a policy.** When the user waives a rule — "skip the PR this time",
"push it" — that applies to the change in front of them and expires with it.
Approving the *content* of the next change ("yes, remove that line") is not approval to deliver it the same way.
Ask again, every time, however recently they said yes and however similar the next one looks.
This binds hardest where a repo's own `CLAUDE.md` sets the rule being waived — that file governs, and a one-off
exception does not amend it.

**Before starting customer work, read the `CLAUDE.md` at the root of that customer's tree** (the directory containing their repos).
It carries the engagement's conventions, permission rules, and any per-team docs. This file defers to it on every conflict.

### personal private — full autonomy

Everything is allowed: commit, push, rebase, open PRs, merge PRs, full `gh` access.
Nothing leaves the user's own account, so the only bar is not committing secrets you'd rather not have in a
history at all.

### personal public — full autonomy, but every commit is published

Same git permissions as private: commit, push, rebase, merge, full `gh` access.
What changes is that the working tree and the **whole history** are world-readable and effectively permanent —
deleting a file later does not unpublish it.

Before committing, check the change carries none of:

- Customer names, their project names, internal tooling, hostnames or URLs.
- Secrets, tokens, keys — including in files that merely *look* like config.
- Anything from a customer tree that wandered in.

**Why:** the cost is asymmetric. A missing rule costs a follow-up commit; a published one costs a history
rewrite across every branch, and every existing clone and fork keeps it anyway.

### company — personal freedom over the code, customer care over what is published

Demos, presentations, and teaching material.
The split is what an audience will see: **the code** is the user's to refactor and restructure as freely as any
personal project, but **the history and the remote** are part of the material and belong to the user.
So it takes the personal rules for editing and the customer rules for publishing — that middle position is the
whole category, not an exception to it.

Everything an audience sees is composed by the user:

- **Forbidden:** `git commit`, `commit --amend`, `cherry-pick`, `merge`, `revert`, any conflicted rebase, `git push` (any form), opening/merging PRs.
- **Allowed:** `git add`, `restore`, `checkout`/`switch`, `stash`, `branch` (ref only), `fetch`, all inspection,
  and a clean zero-conflict `git rebase origin/main`.
- **Be helpful:** draft the commit message and PR body; explain the manual steps. The rule forbids *running* the command, not offering the text.
- **Personal context stays out of the repo**, for the same reason — see § *Durable context lives in the repo*.

**Why:** demo repos are walked through live in front of an audience, so anything committed is on screen.
Project context still belongs in the repo (that is the multi-machine rule); it is the user's own material that
stays out.

### customer — user owns the remote, careful by default

These are the **user's own defaults** for client work, not rules imposed by any client.
They exist because someone else's codebase is the wrong place to be surprising.
An engagement's own `CLAUDE.md` sits closer to the work and overrides anything here, in either direction.

**The same forbidden / allowed / be-helpful lists as *company* above apply here** — including that
`git add`, `restore`, `checkout`/`switch`, `stash`, `branch` (ref only), `fetch` and all inspection are **safe**,
and that a clean zero-conflict `git rebase origin/main` is allowed. "Careful" governs history and the remote,
not ordinary working-tree commands. On top of that:

- Claude prepares the working tree; the user composes history and does every remote write.
- The rule is about *effect on history*, not command names —
  a rebase that mints new commit content during conflict resolution violates it just as much as `git commit`.
  On any conflict: `git rebase --abort` and hand back to the user.
- Prefer the local clone over the hosting platform's CLI (`gh`, `glab`, `az`, …) for reads and writes.
  Everything needed for the work is in the clone, and the user drives the platform themselves.
- Review code locally, never through a web UI — see § *Code review* below for the mechanics.
- The user keeps per-engagement permission rules alongside the engagement's own config; they apply to every subdirectory.

**When in doubt, use these defaults.** If the context is ambiguous or the remote is unreadable, take this reading and relax only once
the remote confirms personal or company work.

## Durable context lives in the repo — personal and company work

The user works on **every** personal and company project from **more than one machine**.
Anything saved to local Claude state (`~/.claude/projects/.../memory/`, settings outside the repo)
lives on one machine and silently desyncs from every other.

**Rule: all durable context goes in the repository.**
Project rules, conventions, workflow preferences, gotchas — into `CLAUDE.md`, `docs/`, `.claude/skills/`, or `plans/`.
Never use personal memory as the system of record for these projects.

**This covers *project* context, not *personal* context.** On a company repo the history is walked through in
front of an audience, so anything tied to the user personally — their role, standing preferences, what the agent
may do on their behalf — stays out of the commit and goes in `~/.claude/CLAUDE.md` or a `CLAUDE.md` above the
repo. Details: the `writing-claude-md` skill.

- When you'd otherwise write a memory file, write to the repo instead.
- If the user asks you to "remember" something, default to a repo edit; keep it local only if they explicitly say so.
- The one exception is a single pointer memory recording this rule, so a fresh session discovers the convention before it can violate it.
- **No hardcoded absolute paths in repo-tracked files.**
  Machines lay repos out differently (`~/src/foo` vs `~/src/<group>/foo`),
  so use repo-root-relative paths or `"$(git rev-parse --show-toplevel)/…"`.

**Does not apply to customer work.** Customer material stays on the machine authorised to hold it, so there is nothing to sync;
customer context deliberately lives *outside* the repos, in the customer tree. Don't "fix" that by moving it into a repo.

## Code review — locally, never through the platform

**Customer and company work only.** On personal projects, review however you like — the remote is yours.

Two constraints, binding on **any** review however it was started — including a `/code-review` run:

- Read the diff from the local clone, never through the hosting platform's API or web UI.
- Post nothing to the platform (no `--comment`, no inline PR comments) unless the user has said so explicitly.
  Findings come back in the conversation; the user posts them.

Set the diff up first: `git fetch origin main`, then `git diff origin/main...HEAD` — the three-dot form, so you
see the branch's own changes rather than a stale merge-base. If the branch is behind, rebase it onto `origin/main`
before reviewing; on any conflict, `git rebase --abort` and hand back.

**Why these four lines are here and not only in the skill:** invoking `/code-review` loads that skill, not this
one, so anything a review must not get wrong has to be in always-loaded context. The rationale, and the rest of
the procedure, are the `reviewing-locally` skill.

## Norwegian vs English — what language goes where

**Everything Claude writes is English.**
Code, comments, commit messages, docs, READMEs, plans, notes, one-off checklists,
and every part of a PR/MR — title, description, diff, inline review comments and replies.
This holds regardless of what language colleagues are using in the thread,
and regardless of how small or informal the thing is.

**Norwegian only for the conversation with the user, and only when they lead.**
Two triggers, both about the chat itself — never about a file, a commit, or anything posted to a platform:

- The user asks for Norwegian → answer in Norwegian.
- The user writes to Claude in Norwegian → answer in Norwegian.

**Norwegian means Nynorsk**, including when the user writes Bokmål — match the language, not the written standard.
When quoting a colleague's Bokmål back, quote it verbatim; never "correct" it into Nynorsk.

**Default to English when in doubt.** An explicit request overrides this section.

## Coding standards

- Always write automatic unit and integration tests for all code changes (mention this in plans).
- **Every test must be able to fail for a real reason.** Before writing one, ask what bug or regression would make
  it fail; if the only answer is "someone edits the test's own literal", don't write it. Details, anti-patterns
  and what to test instead: the `writing-tests` skill.
- **Never use star (wildcard) imports.** Import every symbol on its own line.
  When editing a file that already has a `*` import — even one you didn't add — expand it as part of the edit.
  Applies to Kotlin, Java, and any language with a star-import form.
- Every file written or edited must end with a **trailing newline** (POSIX-style — a final `\n` after the last visible line).
  Applies to all file types: source, shell scripts, markdown, config.

## Self-documenting code — comments are a last resort

Write code so that **reading the code explains the code**. Carry intent through naming and structure —
well-named functions and locals, small focused functions, idiomatic use of the language — not prose.

A comment is a **last resort**, reached for only after genuinely failing to express the thing in the code itself.
Before writing one, try a rename, an extracted well-named function or local, or a restructure.
If any of those would carry the meaning, do that instead and drop the comment.

**Why:** comments drift from the code and restate what good names already say;
a near-comment-free codebase signals that the code itself is the documentation.

**Rules:**

- Don't comment *what* the code does, or restate a function's name, signature, or type.
- Don't state domain knowledge the team already has.
- When tempted to explain a step, prefer extracting a well-named function or local —
  the comment survives only if no code change could have conveyed the same thing.
- Keep a comment only for a *non-obvious why* a reader couldn't infer:
  a compliance or legal constraint, a workaround for external-library behaviour,
  or a deliberate choice that looks wrong at first glance. Keep those to one or two lines.
- No file or class header comments that merely narrate; no commented-out code.
- Never reference things outside the repo (local file paths, source documents, plan files, ticket numbers) —
  they rot and mean nothing to the next reader.
- Test bodies follow the same bar: prefer self-evident Given/When/Then *structure* over
  `// Given` / `// When` / `// Then` scaffolding.

Applying this to a specific diff — what to cut first, and when a comment is *not* a review finding —
is the `cutting-comments` skill.

## Prove causes, don't assume them

Theorizing candidate causes is cheap and good — but hold every one as a *hypothesis* until an experiment or measurement confirms it.
Reproduce it, measure it, or force it to happen on demand.
Conclude, scope, and ship a fix only on **proven cause + proven effect** — never on "probably".

**Why:** plausible ≠ confirmed. Assuming wastes effort and risks shipping a wrong or mis-scoped fix.

## Plan files stay in sync

Two rules that bind whenever a plan file is in play, so they live here rather than only in the skill:

- **Update the plan in the same turn as the code change** — never let it drift behind the working tree.
- **Plan files are temporary.** Never reference one from anything that outlives it — `CLAUDE.md`, READMEs,
  memory, PR/MR descriptions. Inline the load-bearing content into the durable doc instead.

Conventions for writing and maintaining one — status marks, the implementation-status table, spelling out the
tests — are the `writing-plans` skill.

## Always run the project's formatters and linters

After changing code, run whatever formatters and linters that project configures, and make sure they pass **for what you changed**.
This is part of finishing the change, not an optional extra.
If a run surfaces pre-existing failures in code you didn't touch, report them — don't silently fix unrelated files, and don't let them
block handing over your own work.

**Which tools** is a per-project fact — never assume, and never skip because you don't know.
Find them from the project's own configuration: `package.json` scripts and any `lint-staged` block,
Gradle tasks (`spotlessApply`, `ktlintFormat`), `.pre-commit-config.yaml`, `Makefile` targets,
`biome.json` / `.eslintrc*` / `.prettierrc*` / `.stylelintrc*` / `ruff.toml`, or the pre-commit hooks in `.husky/`.

- Run the **fixing** form where one exists (`--fix`, `--write`, `…Apply`), not just the checking form.
- **A pre-commit hook is not a substitute.** Where the user owns commits (company and customer work), the hook fires on *their* commit —
  so run the same tools yourself first, or you hand over a diff that rewrites itself under them.
- Only run tools the project actually configures. Running one it doesn't either fails outright or reformats the whole tree.
- If a configured formatter is broken or unavailable, **say so** rather than silently skipping it,
  and keep the edit consistent with the surrounding style by hand.

## Gradle

**Use `gradle` directly** — the oh-my-zsh Gradle plugin resolves the wrapper automatically, so don't call `./gradlew`.
Confirm it found the wrapper on first use.

## Docker — ask the user to start it

If a task needs Docker (testcontainer-backed tests, local containers) and it isn't running, **ask the user to start it** —
don't launch Docker Desktop / colima yourself.
It takes them ~2 seconds. Wait for confirmation, re-check `docker info`, continue.

**Why:** launching Docker programmatically is slow and unreliable.

## Dependabot and Renovate PRs — let the bots close their own

Never close one by hand, and never write `closes #N` / `fixes #N` / `resolves #N` targeting one — the bots run
their own state machine and close their PRs themselves. Details: the `dependency-bot-prs` skill.

## Markdown line breaks — semantic wrapping, 150-char cap

Use **semantic line breaks** in any markdown file: start a new line at each sentence boundary, not mid-sentence.
Hard cap 150 characters — only wrap mid-sentence when a single sentence exceeds it, and prefer a clause boundary (after a comma or em-dash).
Never wrap inside code fences, URLs, or table cells.

**YAML front matter is exempt from the cap**, and from semantic line breaks.
A wrapped value becomes a different YAML structure — a line break inside `description:` either parses as a new key
or folds into a scalar — so every value stays on one line however long it runs.
Applies to the whole block between the opening and closing `---`, in `SKILL.md` and anywhere else front matter
appears. The body below the closing `---` follows the normal rule.

**Why:** long lines force horizontal scrolling in editors and terminals, but mid-sentence wraps fragment reading flow.
One sentence per line gives diff-friendly history — changing one sentence is a one-line diff.

**How to apply:** end each sentence with a newline in new markdown; reflow any paragraph you touch in existing files.
Find offenders with `awk '{ if (length($0) > 150) print NR": "length($0) }' file.md`.
`awk` counts bytes, so a line with multi-byte characters (`—`, `→`, emoji, accented letters)
may report >150 while being ≤150 characters — that's fine, the cap is on characters.
