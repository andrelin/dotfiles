---
name: dependency-bot-prs
description: Read before closing, bundling, superseding or referencing a Dependabot or Renovate PR, before writing a commit or PR description that mentions one, and before touching the Renovate dependency dashboard issue.
---

# Dependabot and Renovate PRs — let the bots close their own

Never close a Dependabot or Renovate PR manually, and never write `closes #N` / `fixes #N` / `resolves #N`
targeting one in a commit or PR description — those auto-close the bot PR on merge.

**Why:** the bots run their own state machine. When a bumped dependency lands on the default branch by any path,
they detect it and close the obsolete PR themselves, updating the dependency dashboard at the same time.
Closing by hand short-circuits that bookkeeping, and the dashboard then disagrees with reality.

**The excuses:** "the PR is obsolete anyway" — the bot works that out itself, and closing first is what breaks
the bookkeeping. "A closing keyword is just documentation" — it isn't, it fires on merge.
"I'll close it and let the bot reopen if it matters" — it won't; a hand-closed PR reads as a human decision to
decline the bump, and the bot respects that.

**How to apply:**

- When bundling several bot PRs into one human PR, land it and stop.
  List the bot PR numbers ("supersedes #12, #13") — but never with a closing keyword.
- The Renovate dashboard issue is working state, not a task to close. Leave it alone.
- If a bot PR genuinely has to go (the dependency is being dropped, not bumped), that's the user's call to make
  and the user's action to take — surface it rather than closing it.
