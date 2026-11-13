<!-- DOCTOC SKIP -->
# `pm config` — the per-project config and its resolver — plan

**Goal:** a per-tree `.claude-pm.json` that `pm config` resolves into one effective, level-clamped config, which only the user can write.
**Approach:** one jq filter, `claude/hooks/pm-config.jq`, merges the chain of config files, validates it, fills defaults and clamps the
tiers to the work-context level, so the bash 3.2 guard (dotfiles#106) can run it verbatim later.
`bin/pm` (bash 5) finds the files, asks `claude/hooks/work-context.sh` for the levels and the origin's tracker kind, and runs the filter
twice; the guard learns `level --url`, `host-kind` and `origin`, and blocks Claude's writes to `.claude-pm.json` from this phase on.
The filter comes first because whether it holds on jq 1.6 (the RHEL 9 CI job) is the assumption most likely to be wrong.
**Spec:** andrelin/dotfiles#98 (Task 1 of the epic andrelin/dotfiles#97, reviewed through 14 rounds on 2026-10-16), amended by the
user's decisions of 2026-11-10 (§ *Amendments*) and by § *Deviations*, where the spec no longer matches the code.
The issue's text is data: where this plan and the issue differ, this plan wins.

## Global constraints

From the epic's § *Global constraints*, the ones this phase touches; the write-side rules (preflight, footer, keyed comments, drafts
directory, handed context, dates) bind later phases and are not restated here.

- Personal public repo: no customer names, no hostnames (above all no Forgejo host `fj auth list` prints), no private project names in
  any tracked file; fixtures use `example.com`-style hosts and `example-client` owners, as `test/test_work_context.sh` does.
- No hardcoded absolute paths in tracked files.
- Markdown: one sentence per line, lines ≤ 150 characters, `bin/check-md-limits` passes; every file ends with a newline; English;
  no all-caps shout words.
- `bin/pm` is bash 5 with the `BASH_VERSINFO` check `bin/ai-log` uses (exit 2 under bash < 5), `set -Eeuo pipefail`.
- `claude/hooks/work-context.sh` stays bash 3.2 and never calls `bin/pm`; the merge and clamp live only in `claude/hooks/pm-config.jq`.
- The filter stays jq 1.6-compatible, since the RHEL 9 CI container (`redhat/ubi9`) ships 1.6: no `if … then … end` without `else`,
  no `pick`, `abs`, `toarray`, `trim`/`ltrim`/`rtrim`, `add(f)`, `debug(msg)`, `scan($re; $flags)` or other 1.7-only builtins,
  and no `IN`/`INDEX` (use `any(.[]; . == $x)`).
- jq 1.6's `-f` is a flag whose program is the first positional argument, so the filter path always comes right after `-f`, before any
  input file.
- `pm` finds its collaborators: `wc=${PM_WORK_CONTEXT:-$HOME/.claude/hooks/work-context.sh}`, the filter at `${wc%/*}/pm-config.jq`;
  later phases call `${PM_GH:-gh}`, `${PM_GLAB:-glab}` and `${PM_FJ:-fj}`, none of which this phase calls.
  Tests point `PM_WORK_CONTEXT` at the checkout, so CI needs no `~/.claude`.
- `pm` never writes to a tracker.
- jq always runs with `</dev/null` in `pm` and the guard; each config file is checked with `jq empty -- "$f" </dev/null` before the
  filter, so a parse error names the file on jq 1.6 too.
- Test fixtures are never named `.claude-pm.json` in the checkout: they live as `test/fixtures/pm/*.json`, and each test copies them
  into a temp tree under the real name (Task 2 makes that name unwritable for Claude).
- Script tests live in `test/test_pm.sh` and `test/test_work_context.sh`, run by CI's `for t in test/test_*.sh` loop on macOS, Ubuntu,
  RHEL 9 and WSL; the guard's tests run it under `/bin/bash` as today.
- ShellCheck: `bin/pm` is added to the explicit list in `.github/workflows/shellcheck.yml`; `test/*.sh` and `claude/hooks/*.sh` are
  globbed already.
- Tests follow `~/.claude/skills/writing-tests/SKILL.md`: each assertion must be able to fail for a real reason; goldens are hand-checked
  answers, never the filter's output pasted in unread.

Suite: `export DOTFILES="$PWD"; failed=0; for t in test/test_*.sh; do bash "$t" || failed=1; done; (( ! failed ))`
(from the worktree root, with Homebrew's bash 5 first on `PATH`, as CI's *Run tests* step does).

## Approvals

All answered yes by the user on 2026-11-10, in one question.

- `implementing-plans` cuts branch `98-pm-config` (the plan file's name) in this plan's own worktree,
  set up detached at `origin/main` on 2026-11-10 — yes, 2026-11-10.
- Stage each approved task on that branch and commit per task, messages ending with the attribution line — yes, 2026-11-10.
- Push `98-pm-config` with `git push -u origin 98-pm-config`: after Task 3, to get the RHEL 9 (jq 1.6) CI verdict the
  § *Revisit* waits on, at each session end (`Work in progress: Tasks …`), and before the PR — yes, 2026-11-10.
- Open a PR from `98-pm-config` to `main` titled for dotfiles#98, its body per `writing-mr-descriptions` — yes, 2026-11-10.
  Opened 2026-11-10 as draft PR andrelin/dotfiles#110 after Tasks 1-3 (no closing keyword); update that PR, never open another,
  and once the final code review says `Done (code):`, ask the user before marking it ready for review.
- How the branch lands: squash merge, merged by the user — yes, 2026-11-10.
- Closing dotfiles#98: `Closes #98` in the PR body if dotfiles#96's change to `writing-mr-descriptions` has landed by then, else the
  user closes it after the merge — yes, 2026-11-10.
- The plan is untracked, so no `git rm -f` commit; it is deleted once the work is on `main` and logged — yes, 2026-11-10.
  Superseded on 2026-11-10: the session-end save committed both plan files to the branch, so before the squash merge they need
  the `git rm -f` commit (§ *Landing* of the session-end save), which needs the user's yes; ask for it with the merge.
- By-hand step for the end-to-end check: the user places a scratch config (`! cp test/fixtures/pm/<f>.json <scratch-repo>/.claude-pm.json`)
  and removes it afterwards (`! rm <scratch-repo>/.claude-pm.json`), because only the user writes that file;
  the live guard enforces that only once this change is merged and `~/.dotfiles` is pulled — yes, 2026-11-10.
- Optional: run the filter cases under jq 1.6 in `redhat/ubi9` with Docker, only if Docker is already running — yes, 2026-11-10.
- Tool permissions: `bash test/test_pm.sh`, `bash test/test_work_context.sh`, the Suite line, `shellcheck -x -s bash --severity=warning`,
  `bin/check-md-limits`, `jq` — yes, 2026-11-10.

## Implementation status

| Task | Status |
| --- | --- |
| Task 1 · the filter `pm-config.jq` | ✅ DONE |
| Task 2 · the guard protects `.claude-pm.json` | ✅ DONE |
| Task 3 · the guard's `level --url` and `host-kind` | ✅ DONE |
| Revisit · jq 1.6 verdict | 🔄 IN PROGRESS — verdict in (holds); Tasks 4–6 still to detail |
| Task 4 · `pm config` for a repo (sketch) | ⏳ PENDING |
| Task 5 · `pm config` for a tree root (sketch) | ⏳ PENDING |
| Task 6 · `pm redact-check` and the docs (sketch) | ⏳ PENDING |
| End-to-end verification | ⏳ PENDING |
| Final code review | ⏳ PENDING |

Base: b61ac88e0dfb3a9698523ed73fecdaa6427dae8c

## Amendments — the user's decisions of 2026-11-10

- **Forgejo is a tracker kind.** `tracker.kind` adds `forgejo`, driven by `fj`; `origin_kind` adds `forgejo`.
  `work-context.sh host-kind <host>` prints `forgejo` for a host `fj auth list` holds a login for (Task 3, § *Why host-kind asks fj*).
- **The level clamp by `tracker.repo`** applies to `github`, `gitlab` and `forgejo`: a code host's URL says who owns the work.
- **Roadmap settings:** `"roadmap": {"status": "derived" | "labels" | "project"}`, default `derived`; any other value is an error,
  and any other key under `roadmap` is ignored with a warning (Deviation 14).
  `project` is valid in a file whatever the tracker; on a `forgejo` tracker the output's `roadmap.status` is `labels` and `adjustments`
  says why (Forgejo has no projects API).
  This plan extends that to every kind but `github` (§ *Decisions for the user*, 1).
- Every `plan-ai-framework.md` dependency has landed and that file no longer exists; the spec's references to it are history.

## The tiers, per level and tracker kind

Ordered `off < suggest < draft < auto`; any other value is an error.

| Tier | Personal / company default and ceiling | Customer default | Customer ceiling, `github` / `gitlab` | Customer ceiling, `forgejo` |
| --- | --- | --- | --- | --- |
| `issue_create` | `auto` | `off` | `draft`; `auto` from dotfiles#106 | `draft`, also after dotfiles#106 |
| `label` | `auto` | `off` | `draft`; `auto` from dotfiles#106 | `draft`, also after dotfiles#106 |
| `comment` | `auto` | `draft` | `draft` | `draft` |
| `close` | `auto` | `off` | `off` | `off` |
| `release_notes` | `auto` (still a draft release, dotfiles#103) | `draft` | `draft` | `draft` |

- The `forgejo` customer ceiling stays `draft` because the guard doesn't check `fj` at all and `can-file-issue` never offers `fj` for
  customer work (`claude/docs/work-contexts.md` § *Enforcement*): an `auto` there would be a write nothing blocks.
- With `tracker.kind` `jira`, `linear`, `local` or `none`, every tier's ceiling is `draft` at every level; the customer defaults still
  apply below it.
- Personal and company `forgejo` match `github`; a later phase that can't do something on Forgejo (dotfiles#102's close-check, boards)
  keeps itself below `auto` there, as the epic says, rather than the filter.
- With `level` empty the filter applies no ceiling and uses the personal defaults.

## Deviations — where the spec no longer matches the code

Each is recorded here and in the task it affects; none is a silent change.

1. **`basename_is_marker` no longer exists.** `basename_is_protected` (`work-context.sh:1581-1608`) already checks
   `.claude-files-issues` and `.claude-customers`, in any letter case, through globs, brace lists and zsh alternations.
   The spec's `basename_protected` helper is therefore this function with a third name in its loop (Task 2).
2. **`names_protected` isn't needed.** `segment_relevant` (`:2073-2092`) already treats any word holding `.claude-` (and its quoted
   spellings) as relevant, which covers `.claude-pm.json`; the `pre_tool_use` fast path is the
   `segment_relevant "$CMD" || secret_relevant "$CMD" || exit 0` the spec anticipated.
   Only `no_jq_path` (`:1436-1455`) checks names literally, so it gains one line (Task 2).
3. **`deny_marker` is now `deny_protected`** (`:1373-1386`), with branches for a glob, the customers file and the marker;
   `deny_home` (`:1388-1392`) names both files.
   The config gets its own branch, and the glob and home messages name it too (Task 2).
4. **Most in-place editors are covered already.** `sed`, `gsed`, `awk`, `gawk` with `-i…`/`--in-place…` check every word;
   `perl`, `dd`, `truncate` sit in the all-words list, so any word naming the file blocks.
   Two gaps remain, verified on 2026-11-10 for the marker too: `ruby -i … <file>` passes, and `dd of=<name>` with no slash passes
   (its basename is `of=<name>`); Task 2 closes both, for all three names.
5. **`cp` from a protected file is allowed today, deliberately:** `test_work_context.sh` asserts `cp $custs /tmp/backup` exits 0
   (`cp` writes only its last operand).
   The spec said a `cp` from `.claude-pm.json` is denied; this plan keeps it allowed, for all names (§ *Decisions for the user*, 2).
6. **`host-kind` recognises Forgejo** by `fj` logins (user decision of 2026-11-10); the spec had `github`, `gitlab` or `none`.
7. **The accepted-gaps list exists already.** `work-contexts.md` § *Enforcement* lists "a script or an interpreter writing the marker
   or the customers file"; the spec deferred the config's gap entry to dotfiles#106, but Task 2 extends that sentence now.
8. **`.claude/rules/scripts.md` lists no `bin/` script by name** (it says the workflow lists them individually), so it needs no edit.
9. **Tips:** `tips/25_ai_framework.md` now exists, for tools that measure the workflow; `pm` still belongs in
   `tips/24_claude_code.md`, as Tip 24.10 after the current 24.9, and in `tips.md`'s line for file 24.
10. **The `fj` stub exists:** `test_work_context.sh:545-549` builds one logged in to `forgejo.example.com` and `forge.example.net`;
    Task 3 reuses it.
11. **The RHEL 9 job already installs `jq`** (1.6 on `ubi9`); this phase does no date arithmetic, so the epic's `tzdata` note doesn't apply.
12. **The epic's collaborator variables** name only `PM_GH` and `PM_GLAB`; Forgejo adds `PM_FJ` for later phases.
13. **The spec's chain for a repo outside `$HOME`** is unstated; this plan takes `~/.claude-pm.json` plus the toplevel's file, with no
    guard files (Task 4).
14. **Unknown keys** are unstated in the spec; the user decided to warn, not fail (§ *Decisions*, 4).
    An unknown top-level key, tier name, or key under `tracker`, `limits`, `follow_ups`, `vocabulary` or `roadmap` is ignored and listed in
    the output's `warnings` as `"<file>: unknown key <key path>"`, which `pm config` also prints on stderr, so a typo stays visible
    and a machine with older dotfiles keeps working.
    A known key with an invalid value is still an error naming the file.
15. **`adjustments`** is new: the spec only said `pm config` "reports" the Forgejo `project` resolve; the output carries a list of every
    value the filter changed from what a file asked (Task 1).
16. **`tracker` is replaced whole, not deep-merged.** The spec's plain deep merge would let a nearer file's `kind` pair with a farther
    file's `repo`, an unvalidated mix; the nearer `tracker` wins entire and the merged result is validated again (Task 1).
17. **`work-context.sh origin`** is new: `bin/pm` needs origin as `<host>/<path>`, and the repo's one-parser rule keeps that in the guard;
    it resolves an SSH host alias to the real host first (§ *Decisions*, 3; Task 3).

## Decisions — answered by the user on 2026-11-10: 1 (a), 2 (a), 3, 4

1. **`roadmap.status: project` on trackers other than GitHub and Forgejo.**
   GitLab, Jira, Linear, `local` and `none` have no GitHub-style project either, and dotfiles#96's skill covers only GitHub and Forgejo.
   Options: (a) resolve `project` to `labels` on every kind but `github`, reported in `adjustments`; (b) resolve it only on `forgejo` and
   pass `project` through elsewhere; (c) make `project` an error on any kind but `github` and `forgejo`.
   Recommended: (a), one rule a skill can trust, and the file stays valid if the tracker changes.
   The plan is written for (a).
2. **A `cp` from `.claude-pm.json`.** The spec denies it "fail-safe"; the guard today allows a copy *from* the marker or the customers
   file, pinned by a test, because a copy's source is only read.
   Options: (a) keep it allowed for all three names, as the code does; (b) deny a `cp` naming the config anywhere, a special case for one name.
   Recommended: (a), since reading the config leaks nothing the guard protects and (b) would make `pm`-adjacent scripting awkward.
   The plan is written for (a).
3. **SSH host aliases in `origin`** (review finding R3-1).
   The guard supports clones through an alias (`git@github.com-work:owner/x.git`, or a dotless one), but printing the alias host verbatim gave
   `host-kind` `none` for an aliased GitHub clone (every tier `draft`) and a failing default `repo` for a dotless alias containing `gitlab`.
   The user decided: for an scp-form or `ssh://` origin, `origin` resolves the alias with `ssh -G <host>`, taking its `hostname` line,
   which is the host git's own SSH connects to; local, no network; an `https://` origin is used as is.
   Cost: one `ssh -G` per call; dotfiles#106 decides whether the guard caches it.
4. **Unknown keys in `.claude-pm.json`.** The user decided: warn, don't fail — the key is ignored and listed in `warnings`, and a known key
   with an invalid value is still an error (Deviation 14).

## Why host-kind asks fj

- `forgejo_host` (`work-context.sh:2303-2311`) already decides "this is a Forgejo instance" from `fj auth list`, for `can-file-issue`
  and `session-start`; reusing it keeps one definition of a Forgejo host.
- It reads only `fj`'s logins, never the marker or `.claude-pm.json`, so after dotfiles#106 makes the opt-in read the config, whose
  default tracker reads `host-kind`, there is still no loop; `can-file-issue` stays out of `host-kind`, as the spec required.
- A Forgejo host `fj` has no login for can't be written by `fj` anyway, so `none` (every tier `draft`) is the right answer there.
- Rejected: a hostname heuristic (`*forgejo*`, `codeberg.org`), which misses self-hosted instances and could print a private host into
  a test; and config-only `forgejo`, which leaves every Forgejo repo without a file at `draft`.
- Cost: `host-kind` on a non-GitHub, non-GitLab host spawns `fj`, so its output depends on the machine's logins; tests stub `fj`.

## Files by task

| Task | Creates | Modifies |
| --- | --- | --- |
| 1 | `claude/hooks/pm-config.jq`, `test/test_pm.sh`, `test/fixtures/pm/` | — |
| 2 | — | `claude/hooks/work-context.sh`, `test/test_work_context.sh`, `claude/docs/work-contexts.md` |
| 3 | — | `claude/hooks/work-context.sh` (`parse_url` too), `test/test_work_context.sh` |
| 4 | `bin/pm`, `claude/docs/pm-config.md` | `test/test_pm.sh`, `test/fixtures/pm/`, `shellcheck.yml`, `tips/24_claude_code.md`, `tips.md` |
| 5 | — | `bin/pm`, `test/test_pm.sh`, `test/fixtures/pm/`, `claude/docs/pm-config.md` |
| 6 | — | `bin/pm`, `test/test_pm.sh`, `claude/docs/pm-config.md`, `tips/24_claude_code.md` |

Tasks 2 and 3 both edit `work-context.sh` and its test, in different functions; they run in order, never in parallel.

## Task 1 · dotfiles#98: the filter `claude/hooks/pm-config.jq`

**Files:** created `claude/hooks/pm-config.jq` (mode 644), `test/test_pm.sh` (mode 644, like its neighbours),
`test/fixtures/pm/*.json` (inputs) and `test/fixtures/pm/expected-*.json` (goldens).

**Interfaces:** consumes nothing. Produces, for Task 4 and dotfiles#106 verbatim, the one call form:

```sh
jq -n --arg level <personal|company|customer|""> --arg origin <host/path|""> \
  --arg origin_kind <github|gitlab|forgejo|none> --argjson guard_files '<JSON array of paths>' \
  -f pm-config.jq <file>… </dev/null
```

Files farthest first, as canonical absolute paths; `guard_files` holds paths spelled exactly as the file arguments.
Exit 0 with the effective config on stdout; any invalid input is `error("<file>: <reason>")`, which jq reports with exit 5.
With no files at all (`-n` and none given) it prints the defaults.
The output, every key always present unless noted:

```json
{
  "level": "<the level argument>",
  "sources": ["<every file argument, farthest first>"],
  "tracker": {"kind": "github", "repo": "github.com/owner/name"},
  "follow_ups": {"backlog": "<abs path>", "in_flight": "<abs path>"},
  "tiers": {"issue_create": "auto", "label": "auto", "comment": "auto", "close": "auto", "release_notes": "auto"},
  "vocabulary": {"labels": [], "priority": []},
  "limits": {"max_writes_per_run": 3, "footer": "Drafted with Claude"},
  "schedule": {},
  "decisions_dir": "docs/adr",
  "roadmap": {"status": "derived"},
  "redact": [],
  "notes": "<only when a file sets it>",
  "adjustments": ["tiers.comment: auto -> draft (customer ceiling)"],
  "warnings": ["<file>: unknown key tiers.lable"]
}
```

`follow_ups` is absent when no file sets it, and a string (one absolute path) when the nearest file gives one.
`tracker.repo` is `""` for `none` and `local`, and whatever the file gave for `jira` and `linear`.
`adjustments` lists, as `"<key path>: <asked> -> <result> (<reason>)"`, each tier a file asked for above its ceiling and the
`roadmap.status` resolve; values filled from defaults are never listed. Reasons: `customer ceiling`, `tracker kind <kind>`,
`no projects on <kind>`.
`warnings` is always present, empty by default: one `"<file>: unknown key <key path>"` per ignored unknown key (Deviation 14).
It stays apart from `adjustments`, which lists values the filter changed; `pm config` prints each warning on stderr (Task 4).

**The change:**

- Read with `reduce inputs as $o (…)` and `input_filename`; a file seen twice in a row holds more than one value → error; a value that
  isn't an object → error.
- Validate each file on its own, before merging, so every error names the file that holds the bad value: the keys and values of the
  spec's § *The file* plus `roadmap`, `tiers` values, `tracker.kind` among
  `github|gitlab|forgejo|jira|linear|local|none`, `tracker.repo` for the three code-host kinds `<host>/<path>` with a dot in the host and
  at least two path segments (`github.com/owner/name`; `owner/name` is an error, since `level --url https://<repo>` would read `owner` as the host),
  `limits.max_writes_per_run` a non-negative integer, `footer` a string, `schedule` values matching
  `^(weekdays|daily|(mon|tue|wed|thu|fri|sat|sun)(,(mon|tue|wed|thu|fri|sat|sun))*) ([01][0-9]|2[0-3]):[0-5][0-9]$`, `redact` an
  array of non-empty strings, `vocabulary.labels`/`priority` arrays of strings, `follow_ups` a string or an object of strings.
  An unknown key is not an error: drop it from that file before merging and add it to `warnings` (Deviation 14).
- Resolve each file's relative `follow_ups` paths against its own directory before merging.
- Merge farthest first with `*` (objects deep-merge, the nearer file wins, other arrays replaced); `redact` is the union of every
  file's list, deduplicated, in first-seen order.
  `follow_ups` objects deep-merge like any object, and only when the two forms differ (a string and an object) does the nearer replace the farther.
  `tracker` is the exception: a nearer file's `tracker` replaces the farther one whole (Deviation 16),
  so a tree file `{kind: jira, repo: ACME}` over a repo file `{kind: github}` is a Jira tracker, never a mixed one.
- At `level` `customer`, `tiers`, `vocabulary`, `tracker` and `limits` come only from files in `guard_files`; every other key merges
  from all files.
- With no `tracker` after the merge: `origin_kind` `github`/`gitlab`/`forgejo` and a non-empty `origin` → that kind with `repo: $origin`;
  otherwise `{"kind": "none", "repo": ""}`.
  A `tracker` with a code-host kind and no `repo` takes `$origin` when `origin_kind` equals that kind, else it is an error naming the
  nearest file that sets `tracker`.
  The merged `tracker` is validated again after the merge, with the same rules as for a single file.
- Defaults as in the output above; tier defaults per § *The tiers*.
- Clamp each tier to the lowest of the level ceiling and the tracker-kind ceiling (§ *The tiers*), recording `adjustments`; no clamp with
  `level` empty.
- Resolve `roadmap.status` `project` to `labels` on any tracker kind but `github` (Decision 1), recording it in `adjustments`, at every
  level.

**Tests** (`test/test_pm.sh`; source `test/helper.sh` as `test_ai_log.sh` does, `assert` and `e_header` from it; a temp root
canonicalised with `cd -P`, fixtures copied into it under their real name; the filter called with the form above): they prove

- the merge: the nearer file wins per key, `redact` is the union, other arrays are replaced, `sources` keeps the order;
  a nearer `tracker` replaces the farther one whole (a tree `{kind: jira, repo: ACME}` over a repo `{kind: github}` is Jira with `ACME`),
  a kind-only nearer `tracker` over a farther one with a `repo` takes `$origin`, not the old `repo`;
  `follow_ups` objects deep-merge (a repo file setting only `backlog` keeps the tree's `in_flight`), and a nearer string replaces a farther object;
- each level's defaults and ceilings from § *The tiers*, both columns of the customer ceiling, the tracker-kind ceiling at personal
  level, and no clamp with `level` empty;
- the customer restriction: a tier, `tracker` or `limits` from a file outside `guard_files` is ignored, while `redact` and `roadmap`
  from it still merge;
- the tracker default from `origin`/`origin_kind` for each kind, `none` without an origin, and a code-host `tracker` without `repo`;
- `roadmap.status` default, each valid value, the `project` resolve on `forgejo` and kept on `github`, and an invalid value;
- `adjustments` lists an asked-for clamp and the resolve, and stays empty for defaults;
- relative `follow_ups` resolve against their own file's directory, the string form included;
- each validation error exits non-zero with the offending file's path on stderr: a non-object, two objects in one file, `tiers.label: "yes"`,
  `schedule.standup: "8am"`, a bad `roadmap.status`, a code-host `tracker.repo` of `owner/name`;
- an unknown key (a top-level one and a misspelt tier name) exits 0, is absent from the output and is named with its file in `warnings`,
  while a known key with an invalid value still exits non-zero; `warnings` is empty otherwise;
- every case's output equals its golden `test/fixtures/pm/expected-<case>.json` under `jq -S`, after replacing the temp root with
  `<root>` in every string (`split($root) | join("<root>")`, which jq 1.6 has).

**Deviations in how, found while implementing** (points the plan left open; none changes the call form, output shape or error form):

- A zero-byte file yields no value under `-n`, so the filter can't see it: it is skipped and missing from `sources`.
  Task 4's `bin/pm` rejects empty and whitespace-only files before the filter, so `sources` still holds every file `pm` passes.
- `$origin` is validated once, up front, with the `tracker.repo` rule whenever `origin_kind` is a code host and `origin` is non-empty,
  failing as `pm-config: origin <value>: …`, even when a file's own `tracker.repo` means the origin goes unused.
- A `follow_ups` object left empty once its unknown keys are stripped is dropped, so the key stays absent.
- At `customer` level with a `jira`, `linear`, `local` or `none` tracker the two ceilings tie at `draft`; the reason recorded is
  `customer ceiling`.
- Also errors: a `tracker` without `kind`, an empty `decisions_dir` or `follow_ups` path, a non-absolute file argument, and an invalid
  `level`, `origin_kind` or `guard_files`; the code-host `repo` pattern allows a `:port` on the host.
- A file outside `guard_files` at customer level is validated whole before its restricted keys are dropped, and the drop is silent
  (`warnings` lists only unknown keys).
- jq 1.6: the suite passes in `redhat/ubi9` with its packaged jq 1.6 (with `diffutils` added, since `test/helper.sh`'s `assert` calls `diff`).

Deferred: (minor) no test pins the `:port` allowance in a code-host `repo` (`git.example.com:2222/o/r` is accepted by hand).
Deferred: (nit) no assertion that a `linear` tracker's `repo` passes through; only Jira's `ACME` is pinned, in goldens.
Deferred: (nit) a file passed again non-adjacently (`a b a`) is accepted and listed twice in `sources`, as the plan's "twice in a row"
allows; Task 4's `bin/pm` must never pass a repeat.

## Task 2 · dotfiles#98: the guard protects `.claude-pm.json`

**Files:** modified `claude/hooks/work-context.sh` (constants `:18-19`, `deny_protected` `:1373-1386`, `deny_home` `:1388-1392`,
`no_jq_path` `:1436-1455`, `basename_is_protected` `:1581-1608`, `check_protected_segment` `:1781-1868`),
`test/test_work_context.sh` (a new `e_header "pm config guard"` section after the customers-file guard, about `:760`),
`claude/docs/work-contexts.md` (§ *Enforcement*, `:117-125`).

**Interfaces:** consumes nothing. Produces: from this task on, Claude can't write a file named `.claude-pm.json` (any letter case)
through `Write`, `Edit`, `MultiEdit`, `NotebookEdit`, a redirection or a known file-writing command, at every level — the property
dotfiles#106 relies on when it starts trusting tree files.

**The change** (Deviations 1–5, 7):

- Add `PM_CONFIG=.claude-pm.json` beside `MARKER` and `CUSTOMERS`, and add it to `basename_is_protected`'s name loop.
- `no_jq_path`: deny a call naming `$PM_CONFIG`, as it does for the other two.
- `deny_protected`: a branch for the config, worded "Only the user writes .claude-pm.json: show them the content and ask them to save it
  to `<path>` themselves." — never `touch`, never a tier name, since Claude may have been writing any key; the glob branch and
  `deny_home` name the config beside the other two files.
- `check_protected_segment`: add `ruby` to the `sed|gsed|awk|gawk` in-place group; for `dd` and `gdd`, also check each `of=` operand with
  `of=` stripped, so `dd of=<name>` from inside the tree is caught for all three names.
- `work-contexts.md` § *Enforcement*: the config joins the files only the user writes, and the accepted-gaps sentence on scripts and
  interpreters names it.

**Tests** prove, for `.claude-pm.json` at personal and at customer level (`$P` and `$C`): a `Write`, an `Edit` and a `Write` through a
symlink exit 2; a redirect, `cp x <tree>/.claude-pm.json`, `sed -i`, `sed --in-place=.bak`, `perl -pi -e`, `ruby -i`, `truncate -s0`,
`dd of=<tree>/.claude-pm.json` and, from inside the tree, `dd of=.claude-pm.json` exit 2; `dd of=.claude-files-issues` from inside its
tree now exits 2; `x.claude-pm.json.bak` and `cat`/`cp` *from* the config pass; a mixed-case `.Claude-PM.json` is blocked; without
jq a call naming it exits 2; the denial for the config holds neither `touch` nor `issue_create`; the existing marker and customers-file
cases still pass unchanged (none is loosened).

Deferred: (minor) `dd of=/abs/path/<name>` is denied by the whole-word check first, so the message names the path with its `of=` prefix;
for the marker that hands the user a broken `! touch of=/path/.claude-files-issues` (an old flaw the new `dd` case could fix cheaply by
checking the stripped operand first).
Deferred: (nit) `work-contexts.md`'s accepted-gaps clause on names held in a variable still names only the customers file, though `rm $f`
is equally a gap for the config; the file is now 104 lines against the advisory 100.
Deferred: (nit) the test's `ln -s` to `pm-link` lacks `-f`, and its no-jq pass case duplicates the existing one at about `:490`.

## Task 3 · dotfiles#98: the guard's `level --url`, `host-kind` and `origin`

**Files:** modified `claude/hooks/work-context.sh` (usage comment `:12-13`, `parse_url` `:217-258` gaining `U_PATH`, a `host_kind` function
in the can-file-issue section after `forgejo_listed` `:2313-2324`, an alias-resolving helper beside it, `main` `:2409-2420` and its usage
line), `test/test_work_context.sh` (the `level: URL forms` loop `:80-101`, and beside the `fj` stub `:545-562`).

**Interfaces:** produces, for Task 4 and dotfiles#106:

- `work-context.sh level --url <url>` prints `personal`, `company` or `customer` for a remote URL — `url_class`, so an unparseable URL is
  `company`; exit 64 without a URL.
- `work-context.sh host-kind <host>` prints `github` for `github.com` (any case), `gitlab` where `is_gitlab_host` holds, `forgejo` where
  `forgejo_host` holds, else `none`, checked in that order; the argument goes through `host_only`, so a `host:port` works; exit 64
  without one; never calls `can_file_issue`, the marker or any config (§ *Why host-kind asks fj*).
- `work-context.sh origin [dir]` prints origin's `<host>/<path>`: the full project path with GitLab subgroups kept and `.git` stripped,
  from the forms `parse_url` handles (scp, `ssh://` with a port, Azure DevOps); `parse_url` gains `U_PATH` for it.
  Exit 1 with nothing printed when `dir` has no origin or an unparseable one.
- For an scp-form or `ssh://` origin, `origin` first resolves the host as an SSH alias (Decision 3): the `hostname` line of
  `ssh -G <host>`, falling back to the host as written when `ssh` is missing, fails or prints no `hostname`; an `https://` origin is used as is.
  Only `origin` resolves: `level` keeps `host_alias`.
  The environment variable `WORK_CONTEXT_SSH_CONFIG`, when set, adds `-F "$WORK_CONTEXT_SSH_CONFIG"` to that call, for tests only.
  Cost: one `ssh -G` per `origin` call; dotfiles#106 decides whether the guard caches it.

**Tests** prove: `level --url` gives the same level as `level` for every URL in the `level: URL forms` fixture list, and `customer` for a
listed Forgejo owner (`https://forgejo.example.com/example-client/x`); `host-kind` on `github.com`, `GitHub.com`, `gitlab.com`,
`gitlab.example.com`, `bitbucket.org`, and with the stub `fj` on `PATH` `forgejo.example.com` → `forgejo`, `forge.example.net:2222` →
`forgejo`, `git.example.org` → `none`; without the stub `forgejo.example.com` → `none`; both subcommands exit 64 without an argument;
`origin` prints the hand-checked `<host>/<path>` for each parseable URL in the `level: URL forms` list (`gitlab.com/example-client/group/sub/repo`
for the subgroup one, the port stripped from the `ssh://` one, the Azure DevOps ones as `parse_url` normalises them), and exits 1 printing
nothing in a repo with no origin;
alias cases, with `WORK_CONTEXT_SSH_CONFIG` pointing at a scratch SSH config in the temp dir, never the real `~/.ssh/config`:
`git@github.com-work:example-client/x.git` with `Host github.com-work` / `HostName github.com` prints `github.com/example-client/x`
and `host-kind github.com` then gives `github`; a dotless `Host ghwork` and an `ssh://` form resolve the same way;
a host the config doesn't list prints as written; an `https://` origin prints as written whatever the config says.

Deviation in how (found in review): `ssh -G` prints `hostname` lowercased (OpenSSH 10.3), so an scp or `ssh://` origin's host comes out
lowercased whenever ssh runs, while an `https://` one keeps its case; and `ssh -G` runs the user's `Match exec` commands, so a slow one
stalls `origin` (local, no network, but not free of side effects).
Implementer's choices, accepted in review: an empty argument counts as given (`level --url ""` → `company`, `host-kind ""` → `none`;
only a missing one exits 64); `git://` is used as is, `git+ssh://` and `ssh+git://` resolve like `ssh://`; Azure DevOps keeps
`parse_url`'s forms (`ssh.dev.azure.com/<org>/<project>/<repo>`, `dev.azure.com/<org>/<project>/_git/<repo>`).

Deferred: (minor) pin the lowercasing with a test (an uppercase scp host comes out lowercased) and a sentence in `ssh_hostname`'s comment,
which should also mention `Match exec`.
Deferred: (minor) untested boundaries, each checked by hand: a host starting with `-` (set with `git config remote.origin.url`), `git+ssh://`
resolving versus `git://` as written, `origin` given a subdirectory and a path with spaces, `level --url` ignoring extra arguments.
Deferred: (nit) `customer_entry`'s `local U_HOST U_OWNER U_REPO` should also localise `U_PATH`.
Deferred: (nit) the "without fj" `host-kind` tests inherit the developer's `PATH`, so a machine with `fj` runs the real one; and an IPv6
origin parses its host as `[` (in `parse_url`, older than this task).

## Revisit · does the filter hold on jq 1.6, and does its call form stand?

Push after Task 3 and read the RHEL 9 job of the `Tests` workflow (or run `test/test_pm.sh` in `redhat/ubi9` if Docker is already up).
Deviation (from Task 1): Task 1's reviewers already ran `test/test_pm.sh` in `redhat/ubi9` on jq 1.6, 203 checks passing with no change
to the call form, error form or output shape; the CI job remains the check of record.
`ubi9` lacks `diffutils`, so `test/helper.sh`'s `assert` prints no diff there on a failure; the RHEL 9 job installs it (`tests.yml`).
Verdict, 2026-11-10: after Task 3, `test/test_pm.sh` (203) and `test/test_work_context.sh` (909) pass in `redhat/ubi9` with jq 1.6, bash 5.1
and CI's prerequisites, on a copy of the tree made its own repo; nothing forced a change to the call form, error form or output shape.
Deviation: no push after Task 3, since checkpoints live in the index until a session end; the Docker run stood in for the CI job,
which the session-end push and the PR still run.
Remaining: detail Tasks 4–6 from their sketches and the spec (a plan agent, then `reviewing-in-rounds plan`), before Task 4.
If a jq 1.6 difference forced a change to the call form, the error form or the output shape, fold it into Task 4 and the interfaces
above before detailing Task 4; then detail Tasks 4–6 from these sketches and the spec.

## Task 4 · dotfiles#98: `pm config` for a repo

Sketch: `bin/pm` (bash 5, mode 755) with `config [dir]` for a directory inside a git repo: build the chain (`~/.claude-pm.json`, each
ancestor strictly between `$HOME` and the toplevel, the toplevel; canonical paths via `cd -P … && pwd -P`; a file above or outside
`$HOME` ignored; Deviation 13 for a repo outside `$HOME`), reject an empty or whitespace-only file and run `jq empty --` on each (exit 1
naming it), refuse a git-tracked file with a non-empty `redact` (`git ls-files --error-unmatch`), get `origin` from `work-context.sh origin`
(an SSH alias already resolved there) and `origin_kind` from `host-kind` on its host, never parsing a URL itself, run pass 1 with `level` empty,
compute the level (`level <dir>` made stricter by `level --url https://<tracker.repo>` for the three code-host kinds),
compute `guard_files` (strict ancestors of the toplevel strictly below `$HOME` when the directory itself is customer;
the whole chain otherwise, including when only the tracker made it customer), run pass 2, print it, with each of its `warnings` also on stderr.
Exit codes 0, 1 (invalid config), 2 (usage, bash < 5, no jq), 3 (internal).
Tests are the spec's `pm config` cases through real temp trees with `PM_WORK_CONTEXT` and a temp `HOME`, plus a Forgejo origin via the
`fj` stub, an aliased GitHub origin (`git@github.com-work:…`, with `WORK_CONTEXT_SSH_CONFIG` on a scratch config) giving `tracker` `github`,
and an unknown key giving exit 0 with the warning on stderr.
Deviation (from Task 1): the filter can't see a zero-byte file and only catches a repeat passed twice in a row, so `pm` must reject empty
and whitespace-only files (already above) and never pass a file twice; the filter itself validates `origin` and fails as
`pm-config: origin …`, which `pm` reports as exit 1 like any invalid config.
Deviation (from Task 3): `origin`'s host is lowercased when it came through `ssh -G` and kept as written for `https://`, so `pm` never
compares it with `tracker.repo` or anything else case-sensitively.
Also: add `bin/pm` to `shellcheck.yml`, create `claude/docs/pm-config.md` (the full reference, read `writing-agent-instructions` first),
add Tip 24.10 and `pm` to `tips.md`'s line for file 24, per `writing-tips`.

## Task 5 · dotfiles#98: `pm config` for a tree root that isn't a repo

Sketch: the chain is `~/.claude-pm.json` plus every ancestor down to and including `dir`; repo discovery finds git repos at depth ≤ 3
below `dir` without descending into one once found, as a function dotfiles#100 (`pm status`) reuses; the level is the strictest level of
the repos found below `dir`, or `customer` when there are none (never `level <dir>`, which gives a non-repo directory `company`),
then made stricter by the tracker clamp as for a repo.
`guard_files` are the chain's files strictly below `$HOME` (so `dir`'s own file is one) when the level came from the repos below or the default,
and the whole chain when only the tracker clamp made it customer.
Tests: a tree root with a customer repo below → `customer` and its tree file merged; with personal repos only → `personal`; with none →
`customer`; a repo at depth 4 is not counted.
`pm-config.md` gains the tree-root rule.

## Task 6 · dotfiles#98: `pm redact-check`

Sketch: `pm redact-check [dir] < text` resolves `redact` through the same code path as `pm config` and exits 1 printing each entry the
text contains (case-insensitive, fixed-string), else 0; an invalid config is exit 1 with its error, told apart by stderr.
Tests: a planted name in mixed case → exit 1 printing it; a name only in `~/.claude-pm.json` catches text from a personal repo; clean
text → 0.
`pm-config.md` says redact names live only outside repos, so a personal public repo's go in the machine-local `~/.claude-pm.json`;
Tip 24.10 gains `redact-check`.

## End-to-end verification

- Run the Suite line, `shellcheck -x -s bash --severity=warning bin/pm claude/hooks/work-context.sh test/test_pm.sh
  test/test_work_context.sh`, and `bin/check-md-limits`.
- In this repo, `PM_WORK_CONTEXT="$PWD/claude/hooks/work-context.sh" bin/pm config` prints `level: personal`,
  `tracker: {"kind": "github", "repo": "github.com/andrelin/dotfiles"}`, every tier `auto` and `roadmap.status: derived`.
- With the user's scratch config in place (§ *Approvals*), `pm config` in that scratch repo merges it; then a `Write` of
  `.claude-pm.json` there is checked by piping a synthetic PreToolUse JSON for a `Write` of `<scratch-repo>/.claude-pm.json` into
  `/bin/bash claude/hooks/work-context.sh pre-tool-use`, run from the worktree: it must exit 2 with the config's message.
  Never use the real `Write` tool for this: the live hook is the `~/.dotfiles` checkout's, which lacks Task 2 until the PR merges.
- Confirm the PR's CI is green on macOS, Ubuntu, RHEL 9 and WSL.

## Review log (plan)

| Round | Lenses | Blocking | Major | Minor | Nit | Fixed |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 5 | 0 | 3 | 8 | 11 | 3 |
| 2 | 5 | 0 | 4 | 13 | 13 | 4 |
| 3 | 5 | 0 | 1 | 11 | 10 | 1 |
| 4 | 5 | 0 | 0 | 22 | 10 | 0 |

User decision after round 3: SSH aliases resolve with `ssh -G`; unknown keys warn, never fail.
Re-evaluation after round 3: continue as is — majors 3, 4, 1, none recurring; round 4 reviews the new `ssh -G` and `warnings` surface.
Done (plan): round 4; unfixed: R4-1, R4-2
