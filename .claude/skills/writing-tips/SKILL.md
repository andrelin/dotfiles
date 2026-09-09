---
name: writing-tips
description: Read before adding, renumbering, restyling or removing a tip, before adding a tips file, and whenever changing a user-facing alias, function or script under source/ or bin/. Covers which decade file a tip belongs in, the heading shape the `tips` shell function parses, how stable per-file numbering is and that renumbering is confirmed with the user first, the style bar for bundled-tool vs repo-feature tips, and the same-commit sync rule.
---

# Writing tips

`TIPS.md` at the repo root is a GitHub landing index.
The content lives in `tips/<NN>_<name>.md`, one file per category, read by the `tips` shell function
(`source/46_tips.sh`).

## Which file — decade meanings

The file-prefix decade is also a "section" for `tips Nx` queries:

- `1x` — Terminal: general tricks + standalone CLI tools (jq, fzf, ag, gh, direnv, git-secret, nvm, …)
- `2x` — Repo features: custom aliases/functions/scripts shipped by this repo
- `3x` — Zsh ecosystem: oh-my-zsh + vendor plugins
- `4x` — Infrastructure tooling: kubernetes, kafka. **Optional installs**, never auto-installed — a project may
  provide them, or install them locally through the `recipes_optional` prompt in `init/31_homebrew_recipes.sh`.
  The tips live here regardless of install state, so each leads with its install command.
- `5x` — IDEs and editors
- `6x` — Web tools: bookmark-style references for useful web pages (no install)

New decades are reserved for clear new categories; slot a new tool into the most-similar existing file, and when
in doubt group it and split later. Only when a file looks too long: `.claude/docs/tips-file-sizing.md`.

## Numbering and heading shape

**The heading shape is required — the `tips` function parses it.** `## Tip <FILE>.<N>: <Title>`, e.g. `## Tip 22.3`.
In files that group tips under H2 group headers, tips are demoted to H3 so the structure stays hierarchical
(see `tips/51_intellij_usage.md`); the function handles either level.

Per-file counters. **Numbers are stable by default, not frozen.**
Append new tips at the end rather than inserting, and don't reshuffle numbering as a side effect of an unrelated
edit — a number the user has learned should keep meaning the same tip.
Gaps from removed tips are fine, and not worth closing on their own.

**Confirm with the user before renumbering anything.** It happens from time to time, but it is their call every
time, never a tidy-up done in passing: say which numbers change to which, and wait.
This holds even when a split makes renumbering unavoidable — confirming the split is not confirming what the
numbers become, so put both in front of them. Once agreed:

- Renumber the **whole file** so the result is contiguous, rather than patching individual numbers.
- Update `TIPS.md` and every cross-reference in the same commit. After a renumber the old numbers point at
  different tips, which is the genuinely harmful outcome.

A tip not yet pushed to `origin/main` is "first version" and can be renumbered without asking — nobody has seen it.

## Style

**Bundled-tool tips** (1x, 3x, 4x, partial 5x): one-line description, then 1–3 *canonical* commands chosen for
**highest value AND maximum stability** (`jq '.field'`, `gh pr create`, not flag-heavy advanced patterns), then a
link to upstream docs. Never duplicate upstream's full reference — that is where drift happens.

**Repo-feature tips** (2x): task-oriented — a workflow or use case, not a function-by-function listing.
Some duplication of source-code comments is accepted for the discoverability win.

**Commands and shortcuts are the focus, prose minimal**; less prose is less drift.
Repo features grow in place; bundled tools grow by adding tools, not by accreting tips inside one tool's section.

## Keep in sync — same commit, not a follow-up

Tips that drift out of date are worse than no tips.
Any change to a user-facing alias, function or script updates its tip **in the same commit**:

- **Adding** one under `source/` or `bin/` → add or extend a tip in the matching 2x file.
- **Renaming or changing the signature** → update every reference in `tips/`.
- **Removing** one → remove or rewrite the tip; don't leave dangling commands.
- **Adding external tooling** under `init/` → slot it into the most-similar 1x/3x/4x/5x file.
- **Adding or renaming a tips file** → update its line in `TIPS.md`.

Two backstops exist, because this is the easiest rule to forget: a `PostToolUse` hook in `.claude/settings.json`
reminds at edit time, and `hooks/pre-commit` warns when a commit changes a definition and stages nothing under
`tips/`. Neither decides for you — a change with no user-facing surface still needs no tip.
