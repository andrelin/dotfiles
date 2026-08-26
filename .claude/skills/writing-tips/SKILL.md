---
name: writing-tips
description: Conventions for this repo's tips system - which decade file a new tip belongs in, the required heading shape the `tips` shell function parses, how stable per-file numbering is and the rule that renumbering is confirmed with the user first, the style bar for bundled-tool vs repo-feature tips, and the rule that a user-facing alias/function/script change updates its tip in the same commit. Read before adding, renumbering, restyling or removing a tip, before adding a new tips file, and whenever changing an alias, function or script under source/ or bin/.
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
- `4x` — Infrastructure tooling: kubernetes, kafka — **optional installs**, not on every machine
- `5x` — IDEs and editors
- `6x` — Web tools: bookmark-style references for useful web pages (no install)

New decades are reserved for clear new categories — don't reach for a new one casually.

**Sizing rule for bundled-tool files** — group similar tools (text-processing, project-workflow CLIs) to avoid
both over-large files *and* many tiny files.

**Size by length, not by tool count.** A shared file wants to be around 50 lines; up to ~75 is comfortable.
Past that, check whether it should split — the question is whether the tools still read as one grouping, not
how many there are.

**A single-tool file may run past the soft cap: its length follows the tool.** `tips/30_zsh.md` (107 lines) is
correct as it stands — breaking one tool across files costs more than the length does.

**Hard cap: 150 lines, no exemption.** Past that a file stops being skimmable, and `tips` prints a wall.
A single-tool file that reaches it splits along a seam in the tool itself.
Find that seam in the content — the existing H2 groups usually show where it is — rather than cutting at the
halfway mark.
Rename both halves so neither keeps the old undifferentiated name, and cross-link them from each other's intro
so neither is a dead end.

The one split so far: the IntelliJ tips hit 199 lines and divided into `50_intellij_config.md` and
`51_intellij_usage.md`, pushing Sublime Text to `52`.
Configuration-versus-usage was the seam that fitted *that* tool; don't assume it fits the next one.

Slot a new tool into the most-similar existing file; spin up a new file only when no current grouping fits,
or a tool's content has clearly outgrown a single tip.
When in doubt, group; split later.

## Numbering and heading shape

**The heading shape is required — the `tips` function parses it.**
`## Tip <FILE>.<N>: <Title>`, e.g. `## Tip 22.3`.
In files that group tips under H2 group headers, tips are demoted to H3 (`### Tip <FILE>.<N>: <Title>`) so the
structure stays hierarchical — see `tips/51_intellij_usage.md` for the pattern.
The function handles either H2 or H3 tips.

Per-file counters. **Numbers are stable by default, not frozen.**
Append new tips at the end rather than inserting, and don't reshuffle numbering as a side effect of an unrelated
edit — a number the user has learned should keep meaning the same tip.
Gaps left by removed tips are fine and not worth closing on their own.

**Confirm with the user before renumbering anything.** Renumbering is fine and happens from time to time — but
it is the user's call every time, never a tidy-up done in passing.
Say which numbers change to which before touching the files, and wait.

This holds even when a split makes renumbering unavoidable: confirming the split is not the same as confirming
what the numbers become, so put both in front of the user.

Once agreed:

- Renumber the **whole file** so the result is contiguous, rather than patching individual numbers.
- Update `TIPS.md` and every cross-reference in the same commit — after a renumber the old numbers point at
  different tips, which is the genuinely harmful outcome.

A tip not yet pushed to `origin/main` is "first version" and can be renumbered without asking — nobody has seen
it yet.

## Style

**Bundled-tool tips** (1x, 3x, 4x, partial 5x): one-line description, then 1–3 *canonical* commands chosen for
**highest value AND maximum stability** (e.g. `jq '.field'`, `gh pr create`, not flag-heavy advanced patterns),
then link out to upstream docs.
Never duplicate upstream's full reference — that's where drift happens.

**Repo-feature tips** (2x): task-oriented (a workflow or use case), not a function-by-function listing.
Some duplication of source-code comments is accepted for the discoverability win; tips stay short and
command-focused.

**Brevity rule** — commands and shortcuts are the focus, prose minimal. Less prose = less drift.

**Growth model** — repo features grow in place (plenty of headroom).
Bundled tools rarely grow per-tool; growth happens by adding new tools, not by accreting tips inside an existing
tool's section.

## Keep in sync — same commit, not a follow-up

Tips that drift out of date are worse than no tips.
Any change to a user-facing alias, function or script updates its tip **in the same commit**:

- **Adding** one under `source/` or `bin/` → add or extend a tip in the matching 2x file.
- **Renaming or changing the signature** → update every reference in `tips/`.
- **Removing** one → remove or rewrite the tip; don't leave dangling commands.
- **Adding external tooling** under `init/` → slot it into the most-similar 1x/3x/4x/5x file.

Adding or renaming a tips file also means updating its line in `TIPS.md`.

**Two backstops exist, because this rule is the easiest one to forget.** Neither decides for you — a change with
no user-facing surface still needs no tip:

- A `PostToolUse` hook in `.claude/settings.json` fires after any Edit/Write under `source/` or `bin/` and
  reminds Claude at edit time, while the change is still in hand.
- `hooks/pre-commit` warns at commit time when a commit adds or removes an alias, function or `bin/` script and
  stages nothing under `tips/`. Advisory — it never blocks the commit.
