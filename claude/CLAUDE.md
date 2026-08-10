<!-- DOCTOC SKIP -->

# Global Instructions

Shared Claude Code rules, tracked in dotfiles so every machine gets the same context.
Symlinked to `~/.claude/CLAUDE.md` by `init/52_claude.sh`.

**This repo is public.** Keep customer names, internal tooling, hostnames, and project specifics out of this file.
Customer-specific conventions belong in that customer's own tree, never here.

## Work contexts — resolve by git remote, not by path

Three kinds of work, with different rules. **Never infer the context from the directory path** —
repo locations differ between machines (`~/src/foo` on one, `~/src/<group>/foo` on another).

**Forking this file?** Everything here is generic except the two values below — set them to your own and the rest works unchanged.

- **Personal account/org:** `andrelin`
- **Company marker:** the repo name contains `uptime`

Resolve with `git remote get-url origin`:

| Remote | Context | Git permissions |
| --- | --- | --- |
| the personal account, name matches the company marker | **company** — demos and presentations for an employer | user owns the remote |
| the personal account, anything else | **personal** | full autonomy |
| any other host or organisation | **customer** — consulting engagement | user owns the remote, careful by default |
| no remote, or can't determine | **assume customer** | the most careful reading |

Customer work is defined by *exclusion*, so this keeps working for new customers with no edits here.

**Before starting customer work, read the `CLAUDE.md` at the root of that customer's tree** (the directory containing their repos).
It carries the engagement's conventions, permission rules, and any per-team docs. This file defers to it on every conflict.

### personal — full autonomy

Everything is allowed: commit, push, rebase, open PRs, merge PRs, full `gh` access.
Host is GitHub. No "user owns the remote" restriction applies here.

### company — same as personal, plus the remote is the user's

Demos, presentations, and teaching material. Treat the code like a personal project — same freedom to refactor and restructure —
**except** the user owns the git history and the remote:

- **Forbidden:** `git commit`, `commit --amend`, `cherry-pick`, `merge`, `revert`, any conflicted rebase, `git push` (any form), opening/merging PRs.
- **Allowed:** `git add`, `restore`, `checkout`/`switch`, `stash`, `branch` (ref only), `fetch`, all inspection,
  and a clean zero-conflict `git rebase origin/main`.
- **Be helpful:** draft the commit message and PR body; explain the manual steps. The rule forbids *running* the command, not offering the text.

**Why:** demo repos are walked through live in front of an audience — the history is part of the material, so the user composes it deliberately.

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
- Review code locally against a freshly fetched default branch rather than through a web UI.
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

- When you'd otherwise write a memory file, write to the repo instead.
- If the user asks you to "remember" something, default to a repo edit; keep it local only if they explicitly say so.
- The one exception is a single pointer memory recording this rule, so a fresh session discovers the convention before it can violate it.
- **No hardcoded absolute paths in repo-tracked files.**
  Machines lay repos out differently (`~/src/foo` vs `~/src/<group>/foo`),
  so use repo-root-relative paths or `"$(git rev-parse --show-toplevel)/…"`.

**Does not apply to customer work.** Customer material stays on the machine authorised to hold it, so there is nothing to sync;
customer context deliberately lives *outside* the repos, in the customer tree. Don't "fix" that by moving it into a repo.

## Norwegian vs English — what language goes where

**English** for everything that lands in a repository: code, comments, commit messages, docs, READMEs, PR/MR titles and descriptions.

**Norwegian (Nynorsk)** for human-to-human chat: Slack/Teams drafts, informal notes, anything the user sends a colleague directly.

**PRs/MRs are a mix** — title, description and diff are English, but inline comments and replies may be Norwegian if a colleague started in Norwegian.

When drafting Norwegian, write **Nynorsk**. When reading or summarising Norwegian *from colleagues*, expect Bokmål and quote it back accurately —
don't "correct" a colleague's Bokmål into Nynorsk. An explicit request for the other language overrides this. If unsure which fits, ask.

## Coding standards

- Always write automatic unit and integration tests for all code changes (mention this in plans).
- Plans must be specific enough to implement without ambiguity: exact file paths, method signatures, env var names.
- Always write code plans with import statements.
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

## Prove causes, don't assume them

Theorizing candidate causes is cheap and good — but hold every one as a *hypothesis* until an experiment or measurement confirms it.
Reproduce it, measure it, or force it to happen on demand.
Conclude, scope, and ship a fix only on **proven cause + proven effect** — never on "probably".

**Why:** plausible ≠ confirmed. Assuming wastes effort and risks shipping a wrong or mis-scoped fix.

## Plan files stay in sync

A "plan file" is any markdown document laying out work to be done — `PLAN-*.md`, `proposal.md`, `roadmap.md`, `migration.md`.
Identify it by content (numbered changes / sections / a backlog), not filename.

- Plan files are the source of truth for what's done and what's left.
  **Update the plan in the same turn as the code change** — never let it drift behind the working tree.
- Mark status as work lands: `✅ DONE`, `🚧 PARTIAL`, `⏳ IN PROGRESS`, `⏳ PENDING`.
  Note deviations inline in the section, not in a separate "changes vs plan" comment.
- Keep an "Implementation status" table near the top of any non-trivial plan.
- Don't batch up "I'll update the plan at the end" — by then the user has lost track of which section covers what.
- If a sub-feature is skipped or deferred, edit the section body to say so. Don't leave the original spec implying it shipped.

**Why:** plans are a record of intent before work starts *and* a record of state after it lands. A stale plan is worse than no plan.

**Plan files are temporary** — deleted once the work ships.
Never reference one from anything that outlives it: `CLAUDE.md`, READMEs, memory, PR/MR descriptions.
Inline the load-bearing content into the durable doc instead of linking to the plan.
Cross-references *between* plans are fine (shared lifecycle); links *from* durable docs *into* plans are not.

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

Never close a Dependabot or Renovate PR manually,
and never write `closes #N` / `fixes #N` / `resolves #N` targeting one in a commit or PR description — those auto-close the bot PR on merge.

**Why:** the bots run their own state machine.
When a bumped dependency lands on the default branch by any path, they detect it and close the obsolete PR themselves,
updating the dependency dashboard at the same time.
Closing by hand short-circuits that bookkeeping.

**How to apply:** when bundling several bot PRs into one human PR, land it and stop;
list the bot PR numbers ("supersedes #12, #13") but never with closing keywords.
Same for the Renovate dashboard issue — it's working state, not a task to close.

## Markdown line breaks — semantic wrapping, 150-char cap

Use **semantic line breaks** in any markdown file: start a new line at each sentence boundary, not mid-sentence.
Hard cap 150 characters — only wrap mid-sentence when a single sentence exceeds it, and prefer a clause boundary (after a comma or em-dash).
Never wrap inside code fences, URLs, or table cells.

**Why:** long lines force horizontal scrolling in editors and terminals, but mid-sentence wraps fragment reading flow.
One sentence per line gives diff-friendly history — changing one sentence is a one-line diff.

**How to apply:** end each sentence with a newline in new markdown; reflow any paragraph you touch in existing files.
Find offenders with `awk '{ if (length($0) > 150) print NR": "length($0) }' file.md`.
`awk` counts bytes, so a line with multi-byte characters (`—`, `→`, emoji, accented letters)
may report >150 while being ≤150 characters — that's fine, the cap is on characters.
