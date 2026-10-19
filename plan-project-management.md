<!-- DOCTOC SKIP -->

# Project-management toolkit — plan

**Goal:** a project-management toolkit — scripts, skills and scheduled runs — that works across personal, company
and customer projects, automates as much as each project's permission structure allows, and is tailored per project
by one config file rather than by forking the toolkit.

**Approach:** facts come from deterministic scripts (`bin/pm`), never from the model's memory; skills write the
narrative and the drafts on top of those facts, citing an issue, PR or commit for every claim. Every action that
writes to a tracker has a *tier* — `auto`, `draft`, `suggest` or `off` — set per project in a `.claude-pm.json` the
user writes, and clamped by a ceiling from the work-context level, so a project's config can tighten what Claude may
do but never loosen it past what the level allows. Every write passes one gate, `pm preflight`, before the skill
runs `gh` or `glab`. Unattended runs go through Desktop scheduled tasks, where the work-context guard and the local
trackers are both in reach.

**Spec:** the user's request of 2026-10-16 — "a project management tool kit that can be used for a wide variety of
different actual projects, including my personal ones. Ideally as automated as possible, but its very important that
they can be tailored to work for my various projects and permission structures" — and the research in
`claude/docs/best-practices/automation.md`.

**Status: ready to implement — review round 14 (2026-10-16) came back with nothing load-bearing, after 13 rounds
folded in.**

## Depends on

`plan-ai-framework.md`, being implemented in parallel by another session; its Tasks 0–2b are done (status as of
2026-10-16 — check its table before starting). This plan needs:

- Task 1's `work-context.sh level` and `can-file-issue`, and its guard (done), which Tasks 1 and 8 below extend;
- Task 3's deny rules and `bin/claude-settings-merge` (merged into the real settings; its marker check is
  pending), which Task 8 extends;
- Task 3b (git-secret, in progress), which is changing `work-context.sh` — the `pre_tool_use` fast path, the
  `Write`/`Edit` basename branch, the PreToolUse matcher — plus `test_work_context.sh`, `bin/claude-settings-merge`
  and its test, `work-contexts.md` and `how-it-works.md`. Task 1 here starts only after 3b lands, and builds its
  `names_protected` and `basename_protected` changes on 3b's version of those spots;
- Task 8's `writing-issues`, the `(issue to file)` tracker convention and its `Target:` line (pending), which
  Tasks 6 and 8b build on;
- Task 6b's `tuning-skill-descriptions` (pending): every skill here passes it before it is marked `✅ DONE`, and is
  `🚧 PARTIAL` until then.

Don't edit `plan-ai-framework.md` while that session runs, nor a file a pending framework task still modifies:
`work-context.sh`, `test_work_context.sh`, `bin/claude-settings-merge` and its test until framework Task 3b lands,
and `writing-issues`, `writing-follow-up-items` and `maintaining-follow-up-trackers` until framework Task 8 lands.
Line numbers below are approximate and drift; find the code by the symbol named. A change this plan needs on the
framework side goes to the user to hand over.

## Decisions — answered by the user on 2026-10-16

1. **One config replaces the marker.** `.claude-pm.json` is the one per-tree policy file, and its
   `tiers.issue_create` replaces `.claude-files-issues`: the guard reads it, and only the user writes it, as with
   the marker today.
2. **JSON, not YAML.** The guard and scripts already require `jq`, and YAML would add a parser dependency to a
   bash 3.2 hook. The cost is no comments; a `"notes"` field takes their place.
3. **Company is ceilinged like personal.** Every tier may reach `auto` at company level and defaults to it; the user
   tightens a single repo through its config. Only customer level keeps the strict ceiling: `issue_create` and
   vocabulary labels may reach `auto`, everything else `draft` at most, whatever the config says.
   `close` may reach `auto` at personal and company level too (decided 2026-10-16), only through `pm close-check`
   (Task 4), which rules out duplicate chains and cycles; at customer level it stays `off`.
   Company level is no longer guarded at all: the user gave it personal-level rights on 2026-10-16, in
   `claude/CLAUDE.md` § *Work contexts* and in `plan-ai-framework.md` Task 1.
4. **Cloud routines and GitHub Actions** are allowed on personal and company repos, at the tiers the config allows.
   Customer systems never get one, since a routine acts as the user with no permission prompt and outside the local
   guard. Building one is out of scope here (§ *Not in this plan*).
5. **Jira and Linear:** `draft` only — the exact text to paste — until a project needs more.

## Global constraints

- Everything in `plan-ai-framework.md` § *Global constraints*: personal public repo, no customer names or hosts in a
  tracked file, no hardcoded absolute paths, markdown limits, ShellCheck list, tests in `test/test_*.sh`.
- **`bin/pm` is bash 5** like the rest of `bin/`. The guard never calls `bin/pm`: the config merge and clamp live in
  one jq filter, `claude/hooks/pm-config.jq`, which both run (Task 1), so the guard stays bash 3.2.
  The filter stays jq 1.6-compatible, since the RHEL 9 CI container ships 1.6: no `if … then … end` without
  `else`, no `pick`, `abs` or other 1.7-only builtins.
- **`pm` finds its collaborators:** `wc=${PM_WORK_CONTEXT:-$HOME/.claude/hooks/work-context.sh}`, the filter beside
  it (`${wc%/*}/pm-config.jq`), and calls `${PM_GH:-gh}` and `${PM_GLAB:-glab}`; tests point all of them
  at the checkout or a stub, so CI needs no `~/.claude`. **`pm` itself never writes to a tracker** — it only reads —
  so these variables can't route a write past the guard: the skill runs the write, through the guard.
- **Never delete anything, at any tier.** Close is automatic only at personal and company level, only at tier
  `auto`, and only after `pm close-check` passes (Task 4); at customer level it is always the user's.
  There is no transition tier: a Jira or Linear status change is a `draft` for the user.
- **jq always runs with `</dev/null`** in `pm` and in the guard, since `jq -n` with no file arguments reads stdin;
  before the filter, each config file is checked with `jq empty -- "$f"`, so a parse error names the file on
  jq 1.6 too.
- **Every write goes through `pm preflight`** (Task 1b), which applies the rules below and prints the exact target
  arguments; a skill never builds `-R`, the marker or the footer itself, and calls `pm audit` after each write.
- **Every bot-written text carries the config's `limits.footer`** — issue bodies, comments, close comments, release
  notes; a label carries no text. **Keyed comments** (preflight `--key`) carry `<!-- pm:<job>:<key> -->`: at
  personal and company level an existing one is updated in place (Task 1b); at customer level it means skip and
  report, since edit and comment are blocked there. Task 4's close comment carries a marker too, from `--marker`,
  which prints it without the lookup: a close never updates in place.
- **Every write runs in the repo it targets:** `cd <dir> && gh …`, `dir` being the one preflight was given — at
  customer level `argv` is empty, so `gh` and the guard both resolve the target from the cwd.
- **Handed context:** a skill handed a job name, run id, `dir` and `pm` path (a scheduled template hands all four
  over, Task 7) uses them instead of starting its own run: every `pm` call through that path with `dir` passed
  explicitly, every write in `dir`, `pm audit <handed job> write`. Bare `pm`, the cwd and the skill's own job name
  only when run interactively. Paths are quoted in every shell call.
- **Writes name their target explicitly** (`-R <owner>/<repo>`, with `GH_HOST` or `GITLAB_HOST` from the host part),
  taken from `tracker.repo`, never inferred — **except at customer level**, where the guard allows only origin's own
  issues and blocks any `-R`: there the write omits `-R`, and preflight refuses it unless origin equals `tracker.repo`.
- **No private content into a public target:** before any write to a public repo (`gh repo view --json visibility`,
  `glab repo view -F json` for GitLab; unknown counts as public), preflight runs the text through `pm redact-check`.
- **Unattended output** that isn't written at `auto` goes to
  `${XDG_STATE_HOME:-$HOME/.local/state}/claude-pm/drafts/<YYYY-MM-DD>-<task>.md`, never to a tracker — `<task>`
  being the installed task's name (Task 7), so two installs of one job never share a file; an interactive run
  that drafts uses `<job>` instead.
- **Dates:** `pm` takes "now" from `PM_NOW` (epoch seconds) when set, does arithmetic in epoch seconds, formats with
  bash 5 `printf '%(…)T'`, and parses git's with `%ct` and tracker timestamps with jq `fromdateiso8601` after
  normalising them — fractional seconds stripped (`sub("\\.[0-9]+"; "")`) and a `±HH:MM` offset applied to reach
  `Z` — since glab and the GitLab API return `….123Z` or offsets that `fromdateiso8601` rejects; never `date -d` or
  `date -j`, which split by platform. Tests set `TZ=Europe/Oslo` and `PM_NOW`; the RHEL 9 CI job installs
  `tzdata` if `redhat/ubi9` lacks the zone.
- **Test fixtures are never named `.claude-pm.json` in the checkout**, since Task 1 makes that name unwritable: they
  live as `test/fixtures/pm/*.json` and each test copies them into a temp tree under the real name.
- **Skill tests are pressure tests** per `superpowers:writing-skills`, run by hand and recorded in the status table;
  script tests are in `test/test_pm.sh` with stubbed `gh`/`glab`, and run in CI. A pressure test's config is placed
  by the user as setup — `! cp test/fixtures/pm/<f>.json <scratch-tree>/.claude-pm.json` — since Claude can't
  write that name from Task 1 on; redact fixtures go in a scratch tree file under `$HOME`, never the real
  `~/.claude-pm.json`. The user removes each scratch config after the test (`! rm …`), since one left under `$HOME`
  becomes a trusted tree file once Task 8 lands.

## Implementation status

| Task | Status | Notes |
| --- | --- | --- |
| 1 · `pm config`: the per-project config and its resolver | ⏳ PENDING | |
| 1b · The write gate: `pm preflight`, `pm audit`, `pm find-marker` | ⏳ PENDING | |
| 2 · `pm status`: deterministic facts across one repo or a tree | ⏳ PENDING | |
| 3 · `reporting-status` skill: standups and status reports | ⏳ PENDING | |
| 4 · `triaging-issues` skill and `pm close-check` | ⏳ PENDING | |
| 5 · `drafting-release-notes` skill | ⏳ PENDING | |
| 6 · `pm reconcile`: issues against the follow-up tracker | ⏳ PENDING | |
| 7 · Scheduled runs and heartbeat | ⏳ PENDING | spike first |
| 8 · Guard integration: tiers in the work-context guard | ⏳ PENDING | needs framework Tasks 3 and 8; lands with 8b |
| 8b · `writing-issues` goes through the write gate | ⏳ PENDING | needs framework Task 8 |
| 9 · `recording-decisions` skill: decision log | ⏳ PENDING | |

Order: 1 → 1b → 2, then 3, 4, 5, 7 and 9 in any order; 6, 8 and 8b after framework Tasks 3 and 8, with 8 and 8b in
one change, so the guard never drops the marker while `writing-issues` still relies on it. Task 4's customer-level
label writes and Task 7's customer runs wait for Task 8; everything else in them works at personal and company
level first.

## Findings and decisions

From the research (`claude/docs/best-practices/automation.md`, with sources):

- **Facts from scripts.** LLM status summaries fabricate and omit; ccpm's `status`, `standup` and `blocked` are plain
  bash for that reason. `pm status` is that layer here.
- **Writes through a gate, rehearsed first.** gh-aw splits a read-only agent from a write job with per-type caps,
  label allowlists and a target allowlist, and offers a staged mode that previews every write. Here the gate is
  `pm preflight` plus the guard (Task 8), and `draft` *is* staged mode.
- **Auto-close only behind a script gate.** Anthropic's own duplicate bot built circular duplicate chains and went
  silently dead for months. Here a close happens only where `pm close-check` proves the canonical issue is open and
  not itself a duplicate, and Task 7's heartbeat catches a job that has gone quiet.
- **Desktop scheduled tasks** run locally, with a per-task permission mode, where the guard, the hooks and the
  gitignored trackers all apply; a missed run fires once on wake, so every scheduled prompt checks how late it is.
- **Least noise:** caps per run, one rolling digest instead of new items, skip anything a person already labelled or
  assigned.

From review rounds 1 and 2:

- **A tracked config can't be trusted to loosen the guard.** A client can commit a `.claude-pm.json`, and a
  `git pull` brings it in; so the guard reads only files outside the repo, as it does the marker (Task 8), and where
  the directory itself is customer level `pm config` takes its tiers, vocabulary, tracker and limits from the same
  files.
- **A redact list in a public repo publishes what it protects**, so `redact` is refused in any git-tracked file.
- **One write gate** (`pm preflight`) rather than each skill re-implementing target, redact, marker and cap checks.

## File map

| File | Task |
| --- | --- |
| `bin/pm` (new), `test/test_pm.sh` (new), `test/fixtures/pm/` (new) | 1, 1b, 2, 4, 6, 7, 8 |
| `claude/hooks/pm-config.jq` (new) — merge and clamp | 1, 8 |
| `claude/docs/pm-config.md` (new) — the config reference | 1, 1b |
| `claude/hooks/work-context.sh` — `level --url`, `host-kind`, `.claude-pm.json` protection (1); tiers (8) | 1, 8 |
| `test/test_work_context.sh` | 1, 8 |
| `claude/skills/reporting-status/SKILL.md` (new) | 3 |
| `claude/skills/triaging-issues/SKILL.md` (new) | 4 |
| `claude/skills/drafting-release-notes/SKILL.md` (new) | 5 |
| `claude/skills/maintaining-follow-up-trackers/SKILL.md` | 6 |
| `claude/pm-schedules/` templates (new) | 7 |
| `bin/claude-settings-merge`, its test | 8 |
| `claude/docs/work-contexts.md`, `claude/CLAUDE.md`, `docs/how-it-works.md` | 8 |
| `claude/skills/writing-issues/SKILL.md` (from framework Task 8) | 8b |
| `claude/skills/recording-decisions/SKILL.md` (new) | 9 |
| `tips/24_claude_code.md`, `tips.md` | 1, 1b, 2, 7 |
| `.github/workflows/shellcheck.yml`, `.claude/rules/scripts.md` | 1 |

## Task 1 · `pm config`: the per-project config and its resolver

**Files:** created `bin/pm` (subcommands `config`, `redact-check`), `claude/hooks/pm-config.jq`,
`test/test_pm.sh`, `test/fixtures/pm/`, `claude/docs/pm-config.md`; modified `claude/hooks/work-context.sh`
(`level --url`, `host-kind`, `.claude-pm.json` protection), `test/test_work_context.sh`,
`.github/workflows/shellcheck.yml` (add `bin/pm` to its
list, and `.claude/rules/scripts.md` if that list is described there), `tips/24_claude_code.md` and `tips.md` (a
`pm config` / `redact-check` tip, per `writing-tips`).

**Interfaces:**

- `pm config [dir]` prints the effective config as JSON, exit 0; exit 1 on invalid JSON or an invalid value anywhere
  in the chain, naming the file. Every later task reads its settings through this, never the files directly.
  The output adds `"level"` (the clamping level) and `"sources"` (the files merged, farthest first).
- `pm redact-check [dir] < text` exits 1 and prints each matching `redact` entry when the text contains one
  (case-insensitive, fixed-string), else 0.
- `work-context.sh level --url <url>` prints the level of a remote URL, a bash 3.2 wrapper over `url_class`.
- **`.claude-pm.json` is protected from Task 1 on,** so no config Claude wrote can exist when Task 8 starts trusting
  tree files. Two helpers replace every literal check of the marker name in `work-context.sh` that *protects* it —
  not `has_marker`'s `-e $p/$MARKER`, the opt-in, which Task 8 alone changes:
  `names_protected <string>` (contains `$MARKER` or `.claude-pm.json`) for the substring checks — the
  `pre_tool_use` fast path (after 3b it is `segment_relevant "$CMD" || secret_relevant "$CMD" || exit 0`, so
  `segment_relevant` covers it), `segment_relevant` itself, `no_jq_path` — and
  `basename_protected <path>` (basename equals either name) in place of `basename_is_marker`. So a `Write`, an
  `Edit`, a redirect or a `cp` onto `.claude-pm.json` is blocked at every level. The marker only had to exist, but
  the config's *content* is what Task 8 trusts, so for both names the segment check also denies in-place editors
  when any word's basename is protected: `sed`, `perl` or `ruby` with a short-option cluster containing `i` (`-i`,
  `-i.bak`, `-pi`, `-pie`) or, for `sed`, `--in-place[=…]`; `truncate`; and `dd` whose `of=` operand, with `of=`
  stripped, has a protected basename. Any other command that writes the file stays an accepted gap, listed in
  `work-contexts.md` (Task 8). A `cp` *from* the file is denied too; fail-safe, and `pm-config.md` says so. `deny_marker`'s message for the new
  name is generic — "only the user writes `.claude-pm.json`: show them the content and ask them to save it to
  `<path>` themselves" — never an opt-in line, since Claude may have been writing any key. `pm-config.md` says the
  same.
- `work-context.sh host-kind <host>` prints `github` for `github.com`, `gitlab` where `is_gitlab_host` holds, else
  `none` — by host alone, never through `can-file-issue`, which depends on the opt-in and would loop after Task 8.
- The filter's one call form, which Task 8's guard uses verbatim:
  `jq -n --arg level <L> --arg origin <host/path> --arg origin_kind <github|gitlab|none> --argjson guard_files <json
  array of paths> -f pm-config.jq <file>…`, files farthest first, read with `reduce inputs` and `input_filename`
  (both in jq 1.6). `origin` is empty when there is none. `level` is `personal`, `company`, `customer` or empty;
  empty merges, defaults and validates without clamping. At `customer`, `tiers`, `vocabulary`, `tracker` and `limits` come
  only from files listed in `guard_files`. Each file must hold exactly one JSON object. `pm` rejects an empty or
  whitespace-only file before the filter (exit 1), since `jq empty` passes one and `reduce inputs` never sees it;
  the guard treats one as no opt-in.
  Errors are `error("<file>: <reason>")`, which `pm` turns into exit 1. Relative
  `follow_ups` paths resolve against `input_filename`'s directory.
- **`pm config` runs it twice:** pass 1 with `level` empty, to learn the merged `tracker`; `pm` then computes the
  level (§ *Level*) and runs pass 2 with it. When the directory's own level is not customer and only the tracker
  clamp made it customer, `guard_files` is the whole chain — the guard enforces nothing there, the ceiling still
  clamps the tiers, and the tracker that set the level is kept. `pm`, not the filter, finds the files, computes
  `guard_files`, and runs
  the git-tracked `redact` check (`git ls-files --error-unmatch`).

**The file:** `.claude-pm.json`, found in `~/.claude-pm.json`, every ancestor directory between `$HOME` and the repo,
and the repo's toplevel; a file above `$HOME` is ignored. Paths are compared canonically (`cd -P … && pwd -P`).
**For a directory that isn't in a repo** (a tree root, for Tasks 2, 6 and 9), the chain is `~/.claude-pm.json` plus
every ancestor down to and including `dir`, and the level is the strictest of the repos up to three levels below
(`pm`'s repo discovery: git repos at depth ≤ 3 below `dir`, not descending into a repo once found; Task 1 builds
it and Task 2 reuses it), or `customer` when there are none. `guard_files` follow the same rule as for a repo: the files
strictly below `$HOME` when that level came from the repos below (or the default), the whole chain when only the
tracker clamp made it customer.
A company or customer tree keeps one at its root, outside every repo; a personal repo may commit its own.
Merge: objects deep-merge with the nearer file winning (jq `*`), `redact` is the union of every file's list, other
arrays are replaced by the nearer file.
**When the directory itself is customer level**, `tiers`, `vocabulary`, `tracker` and `limits` come only from the files the
guard reads — strict ancestors of the toplevel, strictly below `$HOME` (Task 8) —
so a client-committed toplevel file or a home file can't make `pm config`
promise a write the guard then blocks; the other keys merge from the whole chain.
A **git-tracked** file holding a non-empty `redact` is an error (exit 1): names to keep out live only in files
outside repos. A personal public repo has no tree file above it, so its redact names belong in `~/.claude-pm.json`,
which is machine-local and set up per machine — `pm-config.md` says so. Shape (full reference in `pm-config.md`):

```json
{
  "tracker": {"kind": "github", "repo": "github.com/owner/name"},
  "follow_ups": {"backlog": "00-follow-ups-backlog.md", "in_flight": "00-follow-ups-in-flight.md"},
  "tiers": {"issue_create": "auto", "label": "suggest", "comment": "draft", "close": "draft", "release_notes": "draft"},
  "vocabulary": {"labels": ["bug", "feature", "chore"], "priority": ["p1", "p2", "p3"]},
  "limits": {"max_writes_per_run": 3, "footer": "Drafted with Claude"},
  "schedule": {"standup": "weekdays 08:30", "grooming": "mon 09:00"},
  "decisions_dir": "docs/adr",
  "redact": ["<name to keep out of public trackers>"],
  "notes": "free text for the user"
}
```

`tracker.kind` is `github`, `gitlab`, `jira`, `linear`, `local` or `none`. `tracker.repo` is
`<host>/<project path>`; a GitLab path may hold subgroups. **With no `tracker`,** it defaults from origin by
`origin_kind` (`work-context.sh host-kind`), with origin's `<host>/<path>` as `repo`; no origin, or kind `none`, →
`none`. The output always shows the resolved `tracker`, so writes still name it.
`follow_ups` may also be a string, a single-file tree. Missing `limits.max_writes_per_run` defaults to 3, `footer`
to `Drafted with Claude`, `decisions_dir` to `docs/adr`. `schedule` values match
`weekdays|daily|<mon..sun>[,<mon..sun>…] HH:MM`, local time; anything else is an error.

**Tiers:** ordered `off < suggest < draft < auto`. `suggest` prints a proposal in the conversation; `draft` writes
the exact text to a file, a draft release or the drafts directory (§ *Global constraints*); `auto` performs the write.
Any other value is an error.

**Level:** the directory's (`work-context.sh level <dir>`), made stricter by `tracker.repo`'s
(`work-context.sh level --url https://<tracker.repo>`) only when `tracker.kind` is `github` or `gitlab` — a Jira or
Linear host says nothing about who owns the work. So a personal notes repo that tracks a customer repo clamps at
customer.

| Tier | Personal / company default and ceiling | Customer default | Customer ceiling |
| --- | --- | --- | --- |
| `issue_create` | `auto` | `off` | `draft`; `auto` from Task 8 |
| `label` | `auto` | `off` | `draft`; `auto` from Task 8 |
| `comment` | `auto` | `draft` | `draft` |
| `close` | `auto` | `off` | `off` |
| `release_notes` | `auto` (still a draft release, Task 5) | `draft` | `draft` |

The customer defaults keep marker parity: a customer tree with no file files nothing. Until Task 8 teaches the guard
the config, the customer ceiling for `issue_create` and `label` is `draft`, so preflight never promises a write the
guard would block; Task 8 raises it to `auto` in `pm-config.jq` and its golden files. With `tracker.kind` `jira`,
`linear`, `local` or `none`, every write tier clamps to `draft`.

**Tests** (`test/test_pm.sh`, fixtures copied into a temp `$HOME`):

- a personal repo with no file → every tier `auto`, `level: personal`, `tracker` from origin;
- a repo with no origin and no file, under `WORK_CONTEXT_SCRATCH_DIRS` (personal level) → `tracker.kind: none`,
  every write tier `draft`;
- a tree file plus a repo file → merged, the repo's keys winning, `redact` the union, `sources` in order;
- a customer repo whose tree config sets `comment: auto` → `draft`, `close: auto` → `off`; with no file →
  `issue_create: off`; a customer toplevel file with `label: auto` and no tree file → `label: off`; a customer tree
  file with `label: auto` and `issue_create: auto` → both `draft` (the pre-Task-8 ceiling);
- a company repo with no file → `close: auto`;
- a personal repo whose `tracker.repo` is a customer GitHub URL → `level: customer`, that `tracker.repo` kept;
- a customer repo whose toplevel file sets another `tracker` → ignored, the tree file's or origin's used; one
  setting `limits.max_writes_per_run: 50` → ignored, the tree file's or the default used;
- an empty `.claude-pm.json`, and one holding two objects → exit 1 naming it; a `jira` tracker on a customer
  host → `level: personal`, `comment: draft`;
- invalid JSON in an ancestor → exit 1 naming it; `tiers.label: "yes"` → exit 1; `schedule.standup: "8am"` → exit 1;
- a git-tracked `.claude-pm.json` with a `redact` entry → exit 1; the same file untracked → merged;
- a file above `$HOME` is ignored;
- `pm redact-check` with a planted name in mixed case → exit 1 printing it; a name only in `~/.claude-pm.json`
  catches text from a personal repo; clean text → exit 0;
- every fixture's output matches a committed golden file (`test/fixtures/pm/expected-*.json`, compared with
  `jq -S`), so each CI job — jq 1.6 on RHEL included — checks the filter against the same answer. Before comparing,
  the test replaces the canonical temp root with `<root>` in every string (`sources`, `follow_ups`), with
  `split($root) | join("<root>")`, which jq 1.6 has; the golden files hold `<root>/…`;
- a tree root that isn't a repo, with a customer repo below it → `level: customer`, its tree file merged;
- `test_work_context.sh`: `level --url` on the URL fixtures `level` already uses → the same levels; `host-kind` on
  `github.com`, `gitlab.com`, a self-hosted `gitlab.example.com` and `bitbucket.org`; exit 2 for a `Write` of
  `.claude-pm.json`, a shell redirect (`echo {} > <tree>/.claude-pm.json`) and `cp x <tree>/.claude-pm.json`, at
  personal and customer level; exit 2 for `sed -i 's/draft/auto/' <tree>/.claude-pm.json`, `perl -pi -e …` on it,
  `truncate -s0` on it, `sed --in-place=.bak …` on it, `dd of=<tree>/.claude-pm.json` and, from inside the tree,
  `dd of=.claude-pm.json`; a write to `x.claude-pm.json.bak` passes the basename
  check; `deny_marker`'s message
  for `.claude-pm.json` holds neither `touch` nor `issue_create`; the existing marker-protection tests still pass.

## Task 1b · The write gate: `pm preflight`, `pm audit`, `pm find-marker`

**Files:** `bin/pm` (subcommands `preflight`, `audit`, `find-marker`), `test/test_pm.sh`, `claude/docs/pm-config.md`,
`tips/24_claude_code.md` (the `pm preflight` line).

**Interfaces:**

- `pm audit <job> run [dir]` starts a run: it appends a `run` line and prints the new run id
  (`<epoch>-<pid>`). Every writing skill starts one, interactive or scheduled, with its own job name — `triage`,
  `release`, `issues` — unless a template handed it a run id.
- `pm audit <job> write --run <id> --action <a> --target <t> [--url <u>] [--tier <x>] [dir]` appends a `write` line.
  Lines go to `${XDG_STATE_HOME:-$HOME/.local/state}/claude-pm/audit.jsonl` as
  `{"ts","host","job","dir","event","run","repo","action","target","url","tier"}`, `ts` ISO 8601 in UTC with a `Z`
  (`printf '%(%Y-%m-%dT%H:%M:%SZ)T'` under `TZ=UTC`), so `fromdateiso8601` reads it back directly, `host`
  `${HOSTNAME%%.*}` and `dir` the canonical directory the run was started for.
- `pm find-marker <job>:<key> [dir]` prints the URL of the comment carrying `<!-- pm:<job>:<key> -->` (comments
  only, never issue bodies), exit 0; exit 1 when none; exit 2 when the tracker kind isn't `github`; exit 4 when `gh`
  itself fails, which preflight turns into exit 1. It searches
  `gh issue list -R <repo> --state all -L 200 --search "sort:updated-desc" --json number,url,body,comments`.
  Accepted limit: a marker on an older issue, or past the comments `gh` returns per issue, is missed — a duplicate
  comment, or in `close-check` a missed back-link.
  **Updating in place:** the comment id is the `#issuecomment-<id>` suffix of `existing`, and the update is
  `cd <dir> && gh api -X PATCH repos/<owner>/<repo>/issues/comments/<id> -F body=@<f>`, `f` holding the text with
  marker and footer; it counts as one `comment` write in the audit log.
  GitLab has no comments in `glab issue list -O json`, so marker-dependent actions there stay below `auto`.
- `pm preflight <action> --run <id> [--key <job>:<key> | --marker <job>:<key>] [--text-file <f>] [dir]`, `action`
  one of `issue_create`,
  `label`, `comment`, `close`, `release_notes`. Checks in this order, the first that fails deciding the exit:
  0. at customer level with `--key`: run `find-marker` first (a read the guard allows) — found → exit 1 ("marker
     exists", the skill skips and reports); not found or exit 2 → go on; exit 4 → exit 1. Without this step a
     customer comment, capped at `draft`, would stop at check 1 and be drafted again on every run;
  1. the clamped tier is below `auto` → exit 3; `close` on a tracker other than `github` → exit 3 too;
  2. at customer level, origin differs from `tracker.repo`, compared case-insensitively → exit 3 (draft, so a
     notes repo tracking a customer repo keeps its output);
  3. this run's `write` lines have reached `max_writes_per_run` → exit 1;
  4. the target is public and `--text-file` is missing, or `redact-check` on it fails → exit 1. The skill puts
     *everything* the write sends in that file — title, body, comment, label values, release notes;
  5. with `--key` (personal and company): `find-marker` exits 2 → exit 3; found → `existing` set, exit 0 to update
     in place; exit 4 → exit 1, as in check 0. `--key` is passed only for marker-keyed writes (comments, digests), never for
     `issue_create` or `label`, so GitLab keeps those at `auto`. `--marker` prints the marker with no lookup.

  It prints JSON in every case:
  `{"tier","argv":["-R","owner/repo"],"env":{"GH_HOST":"…"},"marker":"<!-- … -->","footer":"…","existing":url|null}`
  — `argv` empty at customer level, `marker` `null` without `--key` or `--marker`, `existing` `null` without
  `--key`. Exit 0 means write at `auto`; exit 3 means suggest or draft at `tier` (at `off`, do nothing and say so);
  exit 1
  means refuse, with the reason on stderr. A draft bound for a public target is still run through `redact-check` by
  the skill before it is written.

**Tests:** `pm audit` appends well-formed lines (`jq -e` on each) and prints distinct run ids; `find-marker` against
a stub `PM_GH` finds a marker in a comment, exits 1 on none, 2 on a `gitlab` tracker and 4 when the stub exits 1
(and `preflight --key` then exits 1); `preflight close` on a `gitlab` tracker at `close: auto` → exit 3;
`preflight` → exit 0 with
`-R` at personal `auto`; a customer tree at `label: auto` → exit 3 with `tier: draft` (the pre-Task-8 ceiling);
exit 3 at `suggest`, even with the cap reached and a redact hit; exit 1 once the run has
`max_writes_per_run` writes; exit 1 on a redact hit for a public stub repo, also when it is only in the title line,
and exit 0 for a private one; a public stub repo with no `--text-file` → exit 1; `existing`
filled when the marker is found at personal level; at customer level `--key` with the marker present → exit 1,
absent → exit 3 (draft); `--key` on a GitLab tracker → exit 3.

## Task 2 · `pm status`: deterministic facts across one repo or a tree

**Files:** `bin/pm` (subcommand `status`), `test/test_pm.sh`, `test/fixtures/pm/`, `tips/24_claude_code.md` (the
`pm status` line).

**Interfaces:** `pm status [--since <YYYY-MM-DD>] [--json] [dir]` — for a repo, or for every git repo up to three
levels below a directory (a customer tree, `~/src`). No model call, ever; reads only, so it runs at every level and
needs no tier. `--since` takes a `YYYY-MM-DD` date only (anything else → exit 1), meaning 00:00 local, and defaults
to the previous working day (Friday on a Saturday, Sunday or Monday). `pm` turns it into the epoch of local midnight — jq's
`strptime("%Y-%m-%d") | mktime` gives UTC midnight, corrected by the offset from `printf '%(%z)T' <that epoch>`
(the offset *at* that midnight, not now, so a Monday after a DST switch is right) — and passes git `--since=@<epoch>`,
never the bare date, which git reads as that date at the current time of day. The `gh`/`glab` search gets the date. Timestamps print as
`%Y-%m-%dT%H:%M:%S%z` (`+0200`). Without `--json`
it prints the same facts as text, one per line. The JSON shape, which Tasks 3 and 7 consume:

```json
{
  "since": "2026-10-15T00:00:00+0200",
  "repos": [{
    "path": "…", "level": "personal", "tracker": "github.com/owner/name",
    "commits": [{"sha": "…", "subject": "…", "author": "…", "date": "…"}],
    "branches": [{"name": "…", "ahead": 2, "last_commit": "…"}],
    "follow_ups": [{"file": "…", "ref": "B2.3", "heading": "…", "issue": "#373", "pr": "#412"}],
    "plans": [{"file": "plan-x.md", "rows": [{"task": "…", "status": "⏳ PENDING"}]}],
    "issues": {"opened": [], "closed": [], "assigned": []},
    "prs": {"opened": [], "merged": []},
    "skipped": [{"source": "tracker", "reason": "…"}]
  }],
  "heartbeats": [{"job": "standup", "dir": "…", "last": "…", "stale": false}]
}
```

Issue and PR entries are `{"number", "title", "url", "date"}`. A branch's `ahead` counts its commits not on
origin's default branch (`git rev-list --count origin/HEAD..<branch>`); with no `origin/HEAD`, it tries
`origin/main` then `origin/master`, and with none of them `ahead` is `null`. In a tree, a repo whose `pm config` exits 1
is reported with only a `skipped` entry naming the error, and the run goes on. `follow_ups` lists the in-flight file's `###`
items; `plans` reads every root `plan-*.md`'s first table whose header starts `| Task | Status`. `issues` and `prs`
come from `gh`/`glab` for `github` and `gitlab` trackers; for any other kind, or when the call fails, they are
`null` and `skipped` says why. `heartbeats` comes from Task 7 (an empty list until then): every installed job whose
`dir` is the given directory or below it.

**Tests:** fixture repos built in a temp dir with known commits, a tracker file and a plan → exact JSON (dates pinned
with `GIT_COMMITTER_DATE`, compared after `jq -S`); a tree of two repos → both reported; a stub `PM_GH` that exits 1
→ git facts still present, `issues: null`, one `skipped` entry; a `jira` tracker → `skipped` without calling the stub;
`--since` default with `PM_NOW` on a Monday → the Friday.

## Task 3 · `reporting-status` skill: standups and status reports

**Files:** `claude/skills/reporting-status/SKILL.md`, aim ≤ 80 lines.

Runs `pm status --json <dir>` (handed context per § *Global constraints* when scheduled), then writes the
narrative: a standup (yesterday, today, blocked), a weekly report
(`--since` the date seven days back, computed by the skill), or a client status report.
Every claim cites a fact from the JSON by SHA, issue or PR link;
anything the facts don't support is left out, not guessed. A report for anyone but the user is piped through
`pm redact-check` and is written to a file or the conversation — never posted, at any tier.

**Tests** (pressure tests): given a fixture `pm status` JSON, every issue, PR and SHA in the report appears in the
JSON; a planted `redact` name in a commit subject is flagged by `pm redact-check` before a report bound for a
public target is written.

## Task 4 · `triaging-issues` skill and `pm close-check`

**Files:** `claude/skills/triaging-issues/SKILL.md`, aim ≤ 80 lines; `bin/pm` (subcommand `close-check`);
`test/test_pm.sh`.

Starts a run (`pm audit triage run <dir>`), unless a template handed it a job name, run id, `dir` and `pm` path
(§ *Global constraints*, *Handed context*),
then suggests labels from `vocabulary.labels` and `vocabulary.priority` only,
and duplicate *candidates* — each with an open canonical issue and the reason it looks the same. Each label write
goes through `pm preflight label --run <id> --text-file <f> <dir>` (`f` holding the label values):
on exit 0 it runs, in `dir`, `gh issue edit <n> <argv> --add-label <v>` (or
`glab issue update <n> <argv> --label <v>`), with the printed `env`, and calls `pm audit … write`;
on exit 3 it prints the suggestion. It skips any
issue that already has a label or an assignee, and never comments at customer level. Until Task 8 lands, customer
labels clamp to `draft` (Task 1's ceiling), so there the skill only suggests.

**Closing a duplicate** is GitHub-only (preflight exits 3 and `close-check` exits 1 on any other tracker), at tier
`close: auto` only, and only when
`pm preflight close --run <id> --marker dedupe:<canonical> --text-file <f>` (`f` holding the close comment) exits
0 and
`pm close-check <issue> <canonical> [dir]` (no model call) exits 0. It exits 1, naming the reason, unless
all of these hold:

- the canonical is open, was opened before the duplicate, and carries neither a `pm:dedupe` marker nor a
  `duplicate` label;
- no issue's comments carry `<!-- pm:dedupe:<issue> -->`, naming the duplicate as *its* canonical — closing it would
  orphan that link (the same 200-issue search as `find-marker`);
- the duplicate's timeline (`gh api repos/<owner>/<repo>/issues/<n>/timeline --paginate`) has no `reopened` event at
  all — the bot never reopens, and runs act as the user's own account, so a bot actor can't be told apart.

The cap is preflight's. The close is `gh issue close <n> <argv> --duplicate-of <canonical> --comment <text>`, its
text on one line with no `;`, `|`, `&`, `$(` or backticks (the guard splits on those, as framework Task 8 notes), the
comment carrying `<!-- pm:dedupe:<canonical> -->` and a link to the canonical, so a person can reopen it and the next
run sees why it was closed; the text is single-quoted, so `<` and `>` aren't read as redirects. It is one `close`
action and one audit line. Any other close stays a suggestion.

**Tests:** in `test/test_pm.sh`, against a stub `PM_GH` printing fixture JSON: a closed canonical, a canonical that
is itself a duplicate, a two-issue cycle, a canonical newer than the duplicate, a duplicate another issue points to,
and a reopened duplicate each exit 1 with their reason; a clean pair exits 0. Pressure tests for the skill: with a
planted vocabulary, suggestions use only its labels; at `suggest` no write happens; a customer fixture (after
Task 8) yields only writes the guard allows, with no blocked call in the transcript. Manual check, recorded in the
status table: one `label: auto` run in a personal scratch repo on the real `gh`.

## Task 5 · `drafting-release-notes` skill

**Files:** `claude/skills/drafting-release-notes/SKILL.md`, aim ≤ 60 lines.

From merged PRs and commits since the last tag (`git describe --tags --abbrev=0`; all history when there is no tag),
grouped by the project's `vocabulary.labels`, ungrouped last. Below `auto` it writes a file. At `auto` (after
`pm audit release run`, via `pm preflight release_notes --run <id> --text-file <notes>`) it needs the new tag's
name from the user —
it asks, and writes a file if none is given — and runs
`gh release create <tag> <argv> --draft --target <sha> --notes-file <f>`; `glab release create` has
no draft, so GitLab stays a file. Never a published release, at any tier. Dependency-bot PRs are summarised per
`dependency-bot-prs`.

**Tests** (pressure test): a fixture repo with a tag and three later merges → a draft naming all three, with their
links; a repo with no tag → all history; at `auto` with no tag name given → a file, no release.

## Task 6 · `pm reconcile`: issues against the follow-up tracker

**Needs** `plan-ai-framework.md` Task 8 landed: it adds the `Target:` line, and an `(issue to file)` title search to
`maintaining-follow-up-trackers` step 2, which this task's step replaces.

**Files:** `bin/pm` (subcommand `reconcile`), `test/test_pm.sh`; `claude/skills/maintaining-follow-up-trackers/SKILL.md`,
one step that runs it, replacing framework Task 8's per-item `issue list --search` clause.

**Interfaces:** `pm reconcile [--json] [dir]`, reading `follow_ups` and `tracker` from `pm config`. An item's
references come from its `###` heading, per `writing-follow-up-items`: `issue #N` and `PR #N` on GitHub, `#N` and
`!N` on GitLab, a bare `#N` taken as an issue; `(issue to file)` marks an item with no number yet. An item's repo is
its `Target: <host>/<project path>` line (framework Task 8) when it has one, else `tracker.repo` — a tree-root tracker
spans several repos. Facts only, one line (or JSON object) per mismatch, with its class:

- `closed-issue` — an item whose issue is closed;
- `filed` — an `(issue to file)` item whose title equals an issue's title in its repo, compared case-insensitively
  after stripping `(issue to file)`, the ref (`B2.3`), the badge and surrounding quotes;
- `untracked` — an open issue assigned to the user, in any repo Task 2's discovery finds below the tracker's
  directory, with no item naming it;
- `merged-pr` — an in-flight item whose PR is merged.

The skill proposes the edits; the user confirms.

**Tests:** a fixture tracker pair and a stub `PM_GH` printing fixture issues and PRs → each class reported once,
and a matching item not reported; an item with a `Target:` line → looked up in that repo; a GitLab-kind fixture with
`!N` → `merged-pr` found.

## Task 7 · Scheduled runs and heartbeat

**Files:** `claude/pm-schedules/` (one prompt template per job: `standup.md` runs `reporting-status`;
`grooming.md` runs `triaging-issues`, and once Task 6 has landed also `pm reconcile`, whose output goes into the
drafts file for the user), `bin/pm`
(subcommands `schedule-check`, `schedule-install`), `test/test_pm.sh`, `tips/24_claude_code.md` (the
`pm schedule-install` line).

Not `claude/scheduled-tasks/`: every top-level entry of `claude/` is linked into `~/.claude/`, and Desktop writes
its own tasks into `~/.claude/scheduled-tasks/`, which would land them in this public repo. `schedule-install`
copies a template into place instead.

**Spike first**, recorded in this section before the rest is built: how Desktop scheduled tasks pick up a prompt
from a file; whether their permission mode can be set from one; and whether the PreToolUse hooks and
`~/.claude/settings.json` deny rules fire inside a scheduled task — check that the work-context guard blocks
`git push` in one run on a customer-level fixture; that `gh` resolves there, checked with `command -v gh` in a
Bash call of its own, since environment changes don't carry from one Bash call to the next; and how a `schedule`
value (`mon,wed 09:00`) maps onto Desktop's own schedule format. `pm` needs no `PATH`: the template hands the skill
`{{pm}}`, and the skills call the path they were given (bare `pm` only when run interactively). If `gh` doesn't
resolve, `schedule-install` refuses for every job until the user decides how to fix it; the template never gains a
`PATH` line, which could put the real `gh` ahead of `~/.claude/shims`. With no `schedule.<job>` in the config,
`schedule-install` and `schedule-check` exit 1.
If the guard doesn't fire, scheduled tasks are not used at
customer level, and `schedule-install` refuses there.

**Interfaces:**

- `pm schedule-install <job> [dir]` copies `<repo>/claude/pm-schedules/<job>.md`, `<repo>` found relative to
  `bin/pm` itself (`${BASH_SOURCE[0]%/*}/..`), into Desktop's task location as the task
  `<job>-<first 8 hex of sha1 of the canonical dir>` (`sha1sum`, else `shasum`, which macOS has),
  so two installs of one job coexist, with the schedule from the config.
  It substitutes the template's placeholders in the copy: `{{dir}}` (the canonical `dir`), `{{job}}`,
  `{{task}}` and `{{pm}}` (the canonical path of `bin/pm` itself).
  The copy lives outside the repo, so absolute paths are fine there; the template in the repo holds only placeholders.
  It records `{job, dir, task, schedule, installed_at}`
  in `${XDG_STATE_HOME:-$HOME/.local/state}/claude-pm/installed.json`, replacing an entry with the same `task`.
- `pm schedule-check <job> [dir]` prints how many minutes the run is late against the schedule's last expected fire,
  exit 0; exit 3 when more than 360. Every template runs it first and, on 3, still appends its `run` line (a late
  run is still a heartbeat) and reports only; on 1 (the job's `schedule` gone from the config) it stops and reports,
  appending no `run` line, so the heartbeat flags it. A run up to 10 minutes *before* a fire counts as that fire, in case
  Desktop fires early. Each expected fire's epoch is UTC midnight of its date + HH:MM − the local offset at that
  epoch (`printf '%(%z)T'`), so DST switch days are right.
- **Stale:** a `(job, dir)` recorded in `installed.json` on this machine with no `run` line for that `job` and `dir`
  in the audit log (Task 1b) at or after the second-most-recent expected fire — two fires missed in a row, whatever
  the gap between them (so a `weekdays` job is not stale on a Monday morning). Only installed jobs are checked, since
  the log is per machine. A job installed but never run is stale once two expected fires have passed since
  `installed_at`. `pm status` fills `heartbeats`
  from this. Until Task 8 lands, `schedule-install` refuses at customer level, whatever the spike found; if Task 8
  lands before Task 7, Task 7 applies the lift by the spike's result itself.

Each template passes `{{dir}}` explicitly to every `{{pm}}` call, since the scheduled task's cwd is not
guaranteed. It starts with `{{pm}} schedule-check {{job}} {{dir}}`, then `{{pm}} audit {{job}} run {{dir}}`, runs at the tier
`pm preflight` allows, and hands the skill it invokes the job name, run id, `dir` and `{{pm}}`; the skill runs its
writes in `dir` and every `pm` call through that path. It
prints its non-`auto` output, which the template writes to the drafts file (`…-{{task}}.md`); `pm audit` runs once
per write. `grooming` is installed per repo, not on a tree root. Writes made under a
template's run carry the template's job name (`grooming`), not the skill's.

**Tests:** `schedule-check` with `PM_NOW` on a fixture schedule → minutes late, and exit 3 past six hours; a fixture
log and `installed.json` → a daily job that missed two fires flagged, one that missed one not; a `weekdays 08:30`
job at `PM_NOW` Monday 07:00 with its last run Friday 08:30 not flagged; a job not in `installed.json` ignored;
`standup` installed for two trees, one live and one silent → only the silent one flagged; `schedule-install` for
the same job in two dirs → two tasks with distinct names, each copy with its own `{{dir}}`, its own draft path
(`…-{{task}}.md` substituted) and no placeholder left; a run 5 minutes before its fire → not late.

## Task 8 · Guard integration: tiers in the work-context guard

**Needs** Task 1 here (the filter) and `plan-ai-framework.md` Tasks 3 (deny rules, `bin/claude-settings-merge`) and
8 (`writing-issues`) landed first, and **lands in one change with Task 8b**: framework Task 8 builds `writing-issues`
and its pressure test on the marker, which this task stops reading.

**Files:** `claude/hooks/work-context.sh`, `test/test_work_context.sh`, `bin/claude-settings-merge` and its test,
`claude/hooks/pm-config.jq`, `test/fixtures/pm/expected-*.json`, `test/test_pm.sh`, `bin/pm` (`schedule-install`),
`claude/CLAUDE.md` § *Work contexts*, `claude/docs/work-contexts.md`, `docs/how-it-works.md` — the docs ship with the
guard change.

**`schedule-install` at customer level:** Task 8 lifts Task 7's refusal only if Task 7's spike recorded that the
guard fires inside a scheduled task; otherwise the refusal stays, and this section says so.

The guard blocks nothing at company level (`plan-ai-framework.md` Task 1), so these rules bind at customer level
only; at company the tiers are enforced by `pm preflight` alone.

**Which files the guard reads:** only `.claude-pm.json` files in strict ancestors of the repo toplevel, strictly
below `$HOME`, exactly where `has_marker` looks — never the toplevel, never `~/.claude-pm.json`. A file inside a repo
can't raise a tier the guard checks. It runs Task 1's call form with the filter at
`${BASH_SOURCE[0]%/*}/pm-config.jq`, `level` `customer`, `origin` as `<host>/<path>` — `parse_url` keeps the path
local today and sets only `U_HOST`, `U_OWNER`, `U_REPO`, so it gains a `U_PATH` (the full project path, subgroups
kept, `.git` stripped) that `pm` reproduces for the same scp and ssh forms — `origin_kind` from `is_gitlab_host` (no subprocess of
itself), and `guard_files` set to every file it passes, farthest first, with
`</dev/null`. With no tree files it skips the call: no opt-in.
**jq missing, a filter error or invalid JSON in a tree file count as no opt-in:** the call
exits 2 with a message naming the file. The header comment's "`level` and `check-argv` use only builtins and git"
becomes "… and jq, for the tree config only"; check with the framework plan's Task 2b shim that it doesn't rely on
the old promise.

**What it allows,** beyond framework Task 1, with every other condition of `marker_ok` unchanged (origin the only
remote, no `-R`/`--repo`/`GH_REPO`, host variables naming origin's host):

- `gh issue create` / `glab issue create` where the clamped `tiers.issue_create` is `auto`, replacing the marker
  (decision 1);
- a label write, where `tiers.label` is `auto`, checked as an **allowlist**: after `gh issue edit` every argument is
  either a numeric issue number or `--add-label <v>` / `--add-label=<v>`; after `glab issue update`, a numeric issue
  number or `-l <v>`, `-l<v>`, `--label <v>` or `--label=<v>`. Anything else denies — `-u`, `-u<v>`, `--unlabel`,
  `--remove-label`, `--title`, a URL, `-R` included. Values split on commas, every one in `vocabulary.labels` ∪
  `vocabulary.priority`, and at least one is required, so the check can't pass vacuously. This is a dedicated
  parse of the argv, not `check_platform`'s option loop, which skips unknown options and their
  attached values.

**The marker:** the guard stops reading `.claude-files-issues`. The manual step lists each tree that has one
(`find ~ \( -name node_modules -o -name .git -o -name Library \) -prune -o -name .claude-files-issues -print`) and
tells the user to run, per tree, `! f=<tree>/.claude-pm.json; if [ -e "$f" ]; then jq '.tiers.issue_create="auto"'
"$f" > "$f.tmp" && mv "$f.tmp" "$f"; else printf '{"tiers":{"issue_create":"auto"}}\n' > "$f"; fi`, merging into
any config written since Task 1; only then does the user remove the marker.

**Protecting the file:** the guard-side protection landed in Task 1 (`names_protected`). Task 8 raises the customer
ceiling for `issue_create` and `label` to `auto` in `pm-config.jq` and updates its golden files. The hardening
subcommand adds `Edit(~/**/.claude-pm.json)` and `Bash(touch *.claude-pm.json*)` beside the old rules.

**Docs:** `claude/CLAUDE.md`'s "the one platform write it allows is `issue create`" becomes issue create and
vocabulary labels, under the tree's config; `work-contexts.md` and `how-it-works.md` say the config, not the marker,
opts a tree in. `work-contexts.md` lists the accepted gaps: any command outside the listed writers and editors
that writes `.claude-pm.json` — interpreters, scripts, `rsync`, `curl -o`, `patch`, `tar x`, `vim -c` (Task 1) —
and a superproject's committed toplevel `.claude-pm.json` being a strict ancestor of a submodule's
toplevel, so the guard reads it there — the same gap `has_marker` has today.

**Tests:** this task *replaces* Task 1b's customer "`label: auto` → exit 3, `tier: draft`" test and Task 1's
"both `draft`" golden file with the `auto` forms below. The marker tests rerun against the config form (a tree file
with `issue_create: auto`); a repo-toplevel
`.claude-pm.json` with `issue_create: auto` in a customer fixture → `gh issue create` exits 2; a marker alone → exit 2;
an invalid tree file → `issue create` exits 2; jq absent from `PATH` → `work-context.sh check-argv <dir> gh issue
create …` exits 2 (through `check-argv`, since `pre-tool-use` already blocks without jq); a label inside the
vocabulary passes, via gh and via glab;
exit 2 for a label outside it, an out-of-vocabulary value inside a comma list, `--remove-label`, `--title` alongside
`--add-label`, a URL issue argument, and `-R`; for glab, a label outside the vocabulary via `--label` and via
`--label=`, `-lbad`, `--unlabel`, `-u x`, `-ux`, and `glab issue update 5` with no label → exit 2;
`pm config` on a customer tree at `label: auto` → `auto` now, against Task 1's `draft`; `pm preflight label` there
→ exit 0 with empty `argv` when origin matches `tracker.repo`, exit 3 (check 2) when it doesn't; `claude-settings-merge`'s
test sees both new deny rules.

## Task 8b · `writing-issues` goes through the write gate

**Needs** `plan-ai-framework.md` Task 8 (`writing-issues`) landed, and Tasks 1b and 8 here.

**Files:** `claude/skills/writing-issues/SKILL.md`.

`writing-issues` files through the gate like every other write: `pm audit issues run`, then
`pm preflight issue_create --run <id> --text-file <f>` (title and body); on exit 0 it runs `gh`/`glab issue create`
with the printed `argv` and `env` and calls `pm audit … write`. A `## Issues` section saying `**Files:** the user`
still turns an exit 0 into a draft — a section can only tighten. On exit 3 it drafts the issue and gives the user's
`!` line, as framework Task 8 does, adding an `(issue to file)` item only when the user will work on it. So a
personal repo at `issue_create: draft` no longer files on its own. It reads the target from `pm config`'s `tracker`;
when the **Tracker:** line of the `## Issues` section in the loading `CLAUDE.md` names a different tracker, it
drafts instead — the section can only tighten, and `pm config`'s tracker may only be the origin default.
Its "ask the user to run `! touch <tree>/.claude-files-issues`" instruction becomes Task 8's merge-or-create line,
and its marker-based pressure test sets up a tree config instead. Its *comment instead* path, on a matching issue,
goes through the gate too: `pm preflight comment --run <id> --key issues:<n> --text-file <f>`, so a second comment
on the same issue updates the first (Task 1b's PATCH); on exit 3 it drafts the comment.

**Tests:** a pressure test in a customer fixture with a tree config at `issue_create: auto` → it files through the
config's tracker, with no `-R`; at personal `issue_create: draft` → a draft and the `!` line, no `gh` call; at
company `auto` under a `**Files:** the user` section → a draft, no `gh` call; a customer tree config with no
`tracker` and a section naming Jira → a draft, no `gh` call; a personal repo at `comment: draft` with a matching
issue → a drafted comment, no `gh issue comment`.

## Task 9 · `recording-decisions` skill: decision log

**Files:** `claude/skills/recording-decisions/SKILL.md`, aim ≤ 60 lines.

Captures a decision made in the session — context, options, choice, consequences — as a short ADR in the
config's `decisions_dir` (`docs/adr/` by default, relative to the repo toplevel, numbered `NNNN-<slug>.md`),
or — for a customer tree, where Claude can't commit, and for a directory that isn't in a repo — as an item in the
tree's follow-up tracker, never an issue. Shown to the user and written only on a yes.

**Tests** (pressure test): the user settles a design question → the skill proposes an ADR in `decisions_dir`; in a
customer fixture → a tracker item instead.

## Not in this plan

- **Estimation and roadmap roll-ups:** lowest value for a solo consultant; revisit once `pm status` exists.
- **Jira and Linear write adapters:** `draft` only until a project needs more (decision 5).
- **GitLab auto-close and marker search:** `glab issue list` carries no comments; closes and marker-keyed writes
  there stay below `auto` until a project needs the notes API.
- **A dependency-PR digest:** the bots' own dashboards and the `dependency-bot-prs` skill cover it today.
- **Cloud routines and GitHub Actions** (decision 4): allowed, but none is built here; a later plan adds one once the
  Desktop jobs have run for a while, reusing `pm` and the templates.
