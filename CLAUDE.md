<!-- DOCTOC SKIP -->

# Dotfiles

Personal dotfiles for macOS, Ubuntu, WSL 2, and RHEL.

## File conventions

Every file written or edited in this repo must end with a trailing newline (POSIX-style — final `\n` after the last visible line). Applies to all file types: shell scripts, markdown, config, etc.

## Primary platform

The user runs macOS day-to-day; Ubuntu, WSL 2, and RHEL are secondary but still in use occasionally. When tips and docs cover commands, keyboard shortcuts, or paths that differ between platforms, **lead with macOS** and include the Linux/WSL variant after — e.g. `Cmd / Ctrl + X` (macOS first), `pbcopy` before `xclip`, `Cmd + N (Alt + Insert on Linux/WSL)`. Never drop the non-macOS variant; the user occasionally works on those systems and needs to find the right command. Cross-platform helpers in `source/` and `bin/` should still work everywhere.

## Script conventions

Init and source scripts follow strict numbering conventions. **Always** consult the README in each directory before creating or renaming scripts:

- `init/README.md` — numbered by dependency order (10s prerequisites, 20s package managers, 30s packages, etc.)
- `source/README.md` — numbered by category (01–09 core, 10–19 languages, 20–29 tools, etc.)

Placing a script in the wrong range will break dependency ordering or make the codebase harder to navigate.

## OS detection

Scripts use filename conventions and code guards for platform targeting:

- `_macos_` in filename → auto-deselected on non-macOS
- `_linux_` in filename → auto-deselected on non-Linux (Ubuntu, RHEL)
- `_wsl_` in filename → auto-deselected on non-WSL
- `_personal_` in filename → default unchecked
- Code guards (`is_macos || return 1`, etc.) are a second defense

WSL is **not** considered Linux for file selection purposes — it has its own scripts.

## How it works

The main entry point is `bin/dotfiles`. It processes three directories in order:

1. **`copy/`** — files are copied into `$HOME` (used for files that may need local edits, as a second line of defense alongside git-secrets)
2. **`link/`** — each top-level item is symlinked into `$HOME` (e.g., `link/.ssh` → `~/.ssh`, `link/.zshrc` → `~/.zshrc`). Sensitive files in linked directories must be gitignored.
3. **`init/`** — scripts are run once (selected interactively, cached in `caches/init/selected`)

Shell startup: `.zshrc` (or `.bashrc`) sources every `*.sh`/`*.zsh` file in `source/` in filename order via the `src` function. Never modify `.zshrc` or `.bashrc` directly — add aliases, functions, and settings to the appropriate file in `source/` instead.

Because `link/` items are symlinked as-is, directories like `link/.ssh` become the actual `~/.ssh`. Files written there by other tools (e.g., 1Password) appear in the repo but are gitignored.

`vendor/` contains git submodules (zsh plugins) sourced by `source/99_zsh-modules.zsh`.

## App configuration

`conf/` stores app settings that are linked into app-specific locations by dedicated init scripts (not by the `do_stuff` handler):

- `conf/sublime-text/` — linked by `init/51_sublime_text.sh` into Sublime Text's `Packages/User/`
- `conf/intellij/` — linked by `init/50_macos_intellij.sh`

**Note:** `conf/` is unrelated to the old `config/` / `do_stuff config` feature from the upstream fork, which was removed years ago. Do not confuse them.

## Tips system

`TIPS.md` at repo root is a GitHub landing index. The actual content lives in `tips/<NN>_<name>.md`, one file per category, read by the `tips` shell function (`source/46_tips.sh`).

**Decade meanings** — the file-prefix decade is also a "section" for `tips Nx` queries:

- `1x` — Terminal: general tricks + standalone CLI tools (jq, fzf, ag, gh, direnv, git-secret, nvm, …)
- `2x` — Repo features: custom aliases/functions/scripts shipped by this repo
- `3x` — Zsh ecosystem: oh-my-zsh + vendor plugins
- `4x` — Infrastructure tooling: kubernetes, kafka — **optional installs**, not on every machine
- `5x` — IDEs and editors
- `6x` — Web tools: bookmark-style references for useful web pages (no install)

New decades are reserved for clear new categories — don't reach for a new one casually.

**Numbering** — `## Tip <FILE>.<N>: <Title>`, e.g. `## Tip 22.3`. In files that group tips under H2 group headers, tips are demoted to H3 (`### Tip <FILE>.<N>: <Title>`) so the structure is hierarchical — see `tips/50_intellij.md` for the pattern. The `tips` function handles either H2 or H3 tips. Per-file counters, **append-only**: never renumber within a file. Gaps from removed tips are fine; reusing numbers is not. The heading shape is required (parsed by the `tips` function). *Exception:* tips that haven't been pushed to `origin/main` yet are "first version" and may be renumbered freely — local commits don't lock the numbering. Once a tip is on `origin/main`, its number is permanent.

**Style — bundled-tool tips** (1x, 3x, 4x, partial 5x): one-line description, then 1–3 *canonical* commands chosen for **highest value AND maximum stability** (e.g. `jq '.field'`, `gh pr create`, not flag-heavy advanced patterns), then link out to upstream docs. Never duplicate upstream's full reference — that's where drift happens.

**Style — repo-feature tips** (2x): task-oriented (a workflow or use case), not a function-by-function listing. Some duplication of source-code comments is accepted for the discoverability win; tips stay short and command-focused.

**Brevity rule** — commands/shortcuts are the focus, prose minimal. Less prose = less drift.

**Growth model** — repo features grow in place (already plenty of headroom). Bundled tools rarely grow per-tool; growth happens by adding new tools, not by accreting tips inside an existing tool's section.

**Sizing rule for bundled-tool files** — group similar tools (text-processing, project-workflow CLIs, etc.) to avoid both over-large files *and* many tiny files. Aim for 2–4 tools per shared file. Slot a new tool into the most-similar existing file; spin up a new file only when no current grouping fits or a tool's content has clearly outgrown a single tip. When in doubt, group; split later.

**Keep in sync (important)** — tips that drift out of date are worse than no tips. Any change to a user-facing alias, function, or script must update its tip in the same commit:

- **Adding** a new alias/function/script under `source/` or `bin/` → add or extend a tip in the matching 2x file.
- **Renaming or changing the signature** of an existing one → update every reference in `tips/`.
- **Removing** one → remove or rewrite the tip; don't leave dangling commands.
- **Adding external tooling** under `init/` → slot it into the most-similar 1x/3x/4x/5x file.

Same applies to `README.md`, `init/README.md`, `source/README.md`, and `CLAUDE.md` itself when conventions change. Treat docs as part of the change, not a follow-up.

**doctoc / markdownlint** — every markdown file in the repo either has doctoc start/end markers or a `<!-- DOCTOC SKIP -->` comment at the top — never silent default. doctoc requires the **uppercase** form. Rule of thumb: use markers when a file has more than 5 H2/H3 headings; otherwise SKIP. The pre-commit hook auto-runs doctoc + markdownlint-cli2 on staged markdown; both tools are installed by `init/34_npm_globals.sh` when `dotfiles` runs.

## Documentation site

`website/` is a Docusaurus site that renders the repo's docs to GitHub Pages, served from the custom domain `https://dotfiles.lindjo.no`. It is build-time tooling, not part of the `dotfiles` install flow.

- **Source of truth stays put.** `README.md`, `TIPS.md`, `tips/*.md`, `init/README.md`, and `source/README.md` are edited in their canonical locations. `website/scripts/gather-docs.ts` copies them into `website/docs-generated/` (gitignored) at build time, adding front-matter and rewriting links.
- **Link-rewrite conventions.** The gather script rewrites repo-internal links (e.g. `bin/foo`, `init/12_git_hooks.sh`, `.gitignore`) to `https://github.com/andrelin/dotfiles/blob/main/...` URLs so they work on the rendered site. If you add a new top-level directory or root-level file that's referenced from any gathered doc, add it to `SOURCE_DIRS` or `ROOT_FILES` in `website/scripts/gather-docs.ts` — otherwise the build will report broken links.
- **MDX gotcha.** Docusaurus parses markdown as MDX, which treats `<...>` as JSX. The gather script rewrites autolinks (`<https://example.com>` → `[url](url)`); inline `<placeholder>` text inside fenced code blocks is fine. If you write new MDX-incompatible markdown outside code blocks, extend the rewrites.
- **Deploy.** `.github/workflows/deploy-docs.yml` builds and publishes on push to main when any of the source-of-truth docs or `website/` itself changes.

## CI philosophy

This repo has no PRs and a single user — pushes go straight to main, and the production environment is whatever's on the user's machine. CI exists to surface "this needs your attention" promptly, not to gate merges.

Therefore: every workflow runs on `push`, fails hard on any violation, and never uses `continue-on-error` or informational-only modes. Scheduled runs supplement push runs to catch drift while the repo is idle (e.g. external link rot). Don't add soft-fail modes when proposing new CI.

## Infrastructure tooling is optional

Kubernetes and Kafka tooling (`tips/40_kubernetes_cli.md`, `tips/41_kafka_cli.md`, `recipes_optional` in `init/31_homebrew_recipes.sh`) is not auto-installed. The current machine accesses these via a customer VDI; future projects may install them locally via the optional-recipes prompt. Tips for these tools live in the repo regardless of install state, and each tip leads with its install command before usage.
