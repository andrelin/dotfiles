<!-- DOCTOC SKIP -->

# Project-management toolkit — plan

**Goal:** a project-management toolkit — scripts, skills and scheduled runs — that works across personal, company
and customer projects, automates as much as each project's permission structure allows, and is tailored per project
by one config file rather than by forking the toolkit.

**Approach:** facts come from deterministic scripts (`bin/pm`), never from the model's memory; skills write the
narrative and the drafts on top of those facts, citing an issue, PR or commit for every claim. Every action that
writes to a tracker has a *tier* — `auto`, `draft`, `suggest` or `off` — set per project in a `.claude-pm.json` the
user writes, and clamped by a ceiling from the work-context level, so a project's config can tighten what Claude may
do but never loosen it past what the level allows. Unattended runs go through Desktop scheduled tasks, where the
work-context guard and the local trackers are both in reach.

**Spec:** the user's request of 2026-10-16 — "a project management tool kit that can be used for a wide variety of
different actual projects, including my personal ones. Ideally as automated as possible, but its very important that
they can be tailored to work for my various projects and permission structures" — and the research in
`claude/docs/best-practices/automation.md`.

**Status: decisions answered; not yet reviewed.**

## Depends on

`plan-ai-framework.md`, which must land first for:

- Task 1's `work-context.sh level` and `can-file-issue`, and its guard, which this plan extends in Task 8 below;
- Task 3's deny rules, which gain the config file in Task 8;
- Task 8's `writing-issues` and the `(issue to file)` tracker convention;
- Task 6b's `tuning-skill-descriptions`, which every skill here goes through.

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
   guard.
5. **Jira and Linear:** `draft` only — the exact text to paste — until a project needs more.

## Global constraints

- Everything in `plan-ai-framework.md` § *Global constraints*: personal public repo, no customer names or hosts in a
  tracked file, no hardcoded absolute paths, markdown limits, ShellCheck list, tests in `test/test_*.sh`.
- **`bin/pm` is bash 5** like the rest of `bin/`; any part the guard calls stays bash 3.2-compatible.
- **Never delete anything, at any tier.** Close and transition are automatic only at personal and company level,
  only at tier `auto`, and only after `pm close-check` passes (Task 4); at customer level they are always the user's.
- **Every bot-written item carries a marker** `<!-- pm:<job>:<key> -->`, and the attribution line from the config's
  `footer`; writes search for the marker first and update in place.
- **Writes name their target explicitly** (`-R <host>/<owner>/<repo>`), taken from the config, never inferred.
- **No private content into a public target:** before any write to a public repo, the text is checked against the
  config chain's `redact` lists.

## Implementation status

| Task | Status | Notes |
| --- | --- | --- |
| 1 · `pm config`: the per-project config and its resolver | ⏳ PENDING | |
| 2 · `pm status`: deterministic facts across one repo or a tree | ⏳ PENDING | |
| 3 · `reporting-status` skill: standups and status reports | ⏳ PENDING | |
| 4 · `triaging-issues` skill: labels and duplicate candidates | ⏳ PENDING | |
| 5 · `drafting-release-notes` skill | ⏳ PENDING | |
| 6 · `pm reconcile`: issues against the follow-up tracker | ⏳ PENDING | |
| 7 · Scheduled runs, audit log and heartbeat | ⏳ PENDING | |
| 8 · Guard integration: tiers in the work-context guard | ⏳ PENDING | |
| 9 · `recording-decisions` skill: decision log | ⏳ PENDING | |

Order: 1 → 2 → 3, then 8 (the tiers the writing skills need), then 4, 5, 6, 7, 9 in any order.

## Findings and decisions

From the research (`claude/docs/best-practices/automation.md`, with sources):

- **Facts from scripts.** LLM status summaries fabricate and omit; ccpm's `status`, `standup` and `blocked` are plain
  bash for that reason. `pm status` is that layer here.
- **Writes through a gate, rehearsed first.** gh-aw splits a read-only agent from a write job with per-type caps,
  label allowlists and a target allowlist, and offers a staged mode that previews every write. Here the gate is the
  guard (Task 8) plus the tier, and `draft` *is* staged mode.
- **Auto-close only behind a script gate.** Anthropic's own duplicate bot built circular duplicate chains and went
  silently dead for months. Here a close happens only where `pm close-check` proves the canonical issue is open and
  not itself a duplicate, and Task 7's heartbeat catches a job that has gone quiet.
- **Desktop scheduled tasks** run locally, with a per-task permission mode, where the guard, the hooks and the
  gitignored trackers all apply; a missed run fires once on wake, so every scheduled prompt checks how late it is.
- **Least noise:** caps per run, one rolling digest instead of new items, skip anything a person already labelled or
  assigned.

## File map

| File | Task |
| --- | --- |
| `bin/pm` (new), `test/test_pm.sh` (new) | 1, 2, 6, 7 |
| `claude/docs/pm-config.md` (new) — the config reference | 1 |
| `claude/skills/reporting-status/SKILL.md` (new) | 3 |
| `claude/skills/triaging-issues/SKILL.md` (new) | 4 |
| `claude/skills/drafting-release-notes/SKILL.md` (new) | 5 |
| `claude/skills/maintaining-follow-up-trackers/SKILL.md` | 6 |
| `claude/pm-schedules/` templates (new) | 7 |
| `claude/hooks/work-context.sh`, `test/test_work_context.sh`, `claude/docs/work-contexts.md` | 8 |
| `bin/claude-settings-merge`, its test | 8 |
| `claude/skills/recording-decisions/SKILL.md` (new) | 9 |
| `tips/24_claude_code.md`, `tips.md`, `.github/workflows/shellcheck.yml` | 1, 2, 7 |

## Task 1 · `pm config`: the per-project config and its resolver

**Files:** created `bin/pm` (subcommand `config`), `test/test_pm.sh`, `claude/docs/pm-config.md`.

**Interfaces:** `pm config [dir]` prints the effective config as JSON, exit 0; exit 1 on invalid JSON anywhere in
the chain, naming the file. Every later task reads its settings through this, never the files directly.

**The file:** `.claude-pm.json`, found in the repo's toplevel and in every ancestor up to `$HOME`. Nearer files
override farther ones key by key; a personal repo may commit its own, a company or customer tree keeps one at its
root, outside every repo. Shape (full reference in `pm-config.md`):

```json
{
  "tracker": {"kind": "github", "repo": "github.com/owner/name"},
  "follow_ups": "00-follow-ups-backlog.md",
  "tiers": {"issue_create": "auto", "label": "suggest", "comment": "draft", "close": "draft", "release_notes": "draft"},
  "vocabulary": {"labels": ["bug", "feature", "chore"], "priority": ["p1", "p2", "p3"]},
  "limits": {"max_writes_per_run": 3, "footer": "Drafted with Claude"},
  "schedule": {"standup": "weekdays 08:30", "grooming": "mon 09:00"},
  "redact": ["<name to keep out of public trackers>"],
  "notes": "free text for the user"
}
```

`tracker.kind` is `github`, `gitlab`, `jira`, `linear`, `local` or `none`.

**Clamping:** the level's ceiling wins over any tier. Personal and company: any tier, defaulting to `auto`.
Customer: `issue_create` and `label` may reach `auto` (subject to Task 8's guard), everything else `draft` at most.
`close` is `off` at customer level whatever the config says. Missing keys take the level's defaults, which `pm-config.md` lists.

**Tests:** a personal repo with no file → personal defaults; a tree file plus a repo file → merged, the repo's keys
winning; a customer repo whose config sets `comment: auto` → `draft`, and `close: auto` → `off`; a company repo
with no file → `close: auto`; invalid JSON in an ancestor → exit 1 naming it;
a file above `$HOME` is ignored.

## Task 2 · `pm status`: deterministic facts across one repo or a tree

**Files:** `bin/pm` (subcommand `status`), `test/test_pm.sh`.

**Interfaces:** `pm status [--since <date|ref>] [--json] [dir]` — for a repo, or for every repo below a directory
(a customer tree, `~/src`): commits since the date, branches with unmerged work, the follow-up tracker's in-flight
items, plan files and their status tables, and — where the tracker is reachable — issues opened, closed and
assigned, and PRs or MRs opened and merged. Each fact carries its link or SHA. No model call, ever.
Reads only: it runs at every level and needs no tier.

**Tests:** fixture repos with known commits and a tracker file → exact JSON; a tree of two repos → both reported;
an unreachable tracker → the git facts still print, plus a line saying the tracker was skipped and why.

## Task 3 · `reporting-status` skill: standups and status reports

**Files:** `claude/skills/reporting-status/SKILL.md`, aim ≤ 80 lines.

Runs `pm status`, then writes the narrative: a standup (yesterday, today, blocked), a weekly report, or a client
status report. Every claim cites a fact from the JSON; anything the facts don't support is left out, not guessed.
A report for anyone but the user goes through the `redact` check and is written to a file or the conversation —
never posted, at any tier.

**Tests:** given a fixture `pm status` JSON, the report's every issue, PR and SHA appears in the JSON; a planted
`redact` name in a commit message is flagged before a report bound for a public target is written.

## Task 4 · `triaging-issues` skill: labels and duplicate candidates

**Files:** `claude/skills/triaging-issues/SKILL.md`, aim ≤ 80 lines.

Suggests labels from the config's `vocabulary` only, and duplicate *candidates* — each with an open canonical issue
and the reason it looks the same. Applies labels only at tier `auto`, up to `max_writes_per_run`, skipping any issue
a person has labelled or assigned; otherwise prints the suggestions. Never comments at `auto` at customer level.

**Closing a duplicate** happens at tier `close: auto` only, and only when `pm close-check <issue> <canonical>`
(a `bin/pm` subcommand, no model call) exits 0. It exits 1, naming the reason, unless all of these hold:

- the canonical is open, was opened before the duplicate, and carries no duplicate marker or `duplicate` label;
- no open issue names the duplicate as *its* canonical — closing it would orphan that link;
- the duplicate has never been reopened by a person (its timeline has no `reopened` event from a non-bot actor);
- the run has made fewer than `max_writes_per_run` closes.

The close carries a comment with the marker `<!-- pm:dedupe:<canonical> -->` and a link to the canonical, so a
person can reopen it and the next run sees why it was closed. Any other close stays a suggestion.

**Tests:** in a personal scratch repo on the real `gh`, with a planted vocabulary: suggestions use only its labels; at
`suggest` no write happens; a customer fixture yields suggestions only, and no blocked call in the transcript.
`pm close-check` against a stubbed `gh`: a closed canonical, a canonical that is itself a duplicate, a two-issue cycle,
a canonical newer than the duplicate, a duplicate another issue points to, and a person-reopened duplicate each exit 1
with their reason; a clean pair exits 0.

## Task 5 · `drafting-release-notes` skill

**Files:** `claude/skills/drafting-release-notes/SKILL.md`, aim ≤ 60 lines.

From merged PRs and commits since the last tag (`git describe --tags --abbrev=0`), grouped by the project's labels,
written to a file or a draft release — never published. Dependency-bot PRs are summarised per `dependency-bot-prs`.

**Tests:** a fixture repo with a tag and three later merges → a draft naming all three, with their links.

## Task 6 · `pm reconcile`: issues against the follow-up tracker

**Files:** `bin/pm` (subcommand `reconcile`); `claude/skills/maintaining-follow-up-trackers/SKILL.md`, one step
that runs it.

Facts only: tracker items whose issue is closed, `(issue to file)` items whose title now matches an issue, issues
assigned to the user with no item, and merged PRs whose item is still open. The skill proposes the edits; the user
confirms.

**Tests:** fixture tracker and fixture issue list (a stubbed `gh` that prints JSON) → each mismatch class reported.

## Task 7 · Scheduled runs, audit log and heartbeat

**Files:** `claude/pm-schedules/` (one prompt template per job), `bin/pm` (subcommands `audit`,
`schedule-check` and `schedule-install`).

Not `claude/scheduled-tasks/`: every top-level entry of `claude/` is linked into `~/.claude/`, and Desktop writes
its own tasks into `~/.claude/scheduled-tasks/`, which would land them in this public repo. `schedule-install`
copies a template into place instead.

Desktop scheduled tasks run the jobs the config's `schedule` names. Each prompt starts by checking how late it is
(more than 6 hours → report only), runs at the tier the config allows, and appends one JSON line per run and per
write to a machine-local audit log (`${XDG_STATE_HOME:-$HOME/.local/state}/claude-pm/audit.jsonl`). `pm status` flags
a job whose last heartbeat is older than twice its interval. Spike first: confirm how Desktop scheduled tasks pick
up a prompt from a file, and whether their permission mode can be set from one; record both.

**Tests:** `pm audit` appends well-formed lines; `schedule-check` flags a stale heartbeat in a fixture log.

## Task 8 · Guard integration: tiers in the work-context guard

**Files:** `claude/hooks/work-context.sh`, `test/test_work_context.sh`, `bin/claude-settings-merge` and its test,
`claude/docs/work-contexts.md`.

The guard learns two things beyond `plan-ai-framework.md`'s Task 1: it reads `pm config` for the repo, allowing
`issue create` where `tiers.issue_create` is `auto` (replacing the marker, decision 1), and
`gh issue edit --add-label` / `glab issue update --label` with only labels from `vocabulary` where `tiers.label` is
`auto`. Writing `.claude-pm.json` joins the marker's user-only protection: the guard blocks it at every level, and
Task 3's deny rules gain `Edit(~/**/.claude-pm.json)`.
The guard blocks nothing at company level (`plan-ai-framework.md` Task 1), so these tier rules bind at customer
level only; at company the tiers are enforced by the skills and `pm config` alone.

**Tests:** the marker tests rerun against the config form; a label outside the vocabulary exits 2; a `Write` of
`.claude-pm.json` exits 2.

## Task 9 · `recording-decisions` skill: decision log

**Files:** `claude/skills/recording-decisions/SKILL.md`, aim ≤ 60 lines.

Captures a decision made in the session — context, options, choice, consequences — as a short ADR in the project's
decision folder (`docs/adr/` by default, configurable), or, for a customer tree that keeps none, in the tracker.
Shown to the user and written only on a yes.

**Tests:** a pressure test where the user settles a design question → the skill proposes an ADR in the right place.

## Not in this plan

- **Estimation and roadmap roll-ups:** lowest value for a solo consultant; revisit once `pm status` exists.
- **Jira and Linear write adapters:** `draft` only until a project needs more (decision 5).
- **A dependency-PR digest:** the bots' own dashboards and the `dependency-bot-prs` skill cover it today.
