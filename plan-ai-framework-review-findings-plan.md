<!-- DOCTOC SKIP -->

# Review findings (plan) · AI framework

Rounds 1 to 5 ran by hand ahead of Task 5 and kept no findings file; their rows in the plan's log are history.
Line numbers are the round's `reviewed-plan.md` copy, which drops the review log.

## Round 6

Lenses: scope, clarify, data flow, test matrix, consistency, work context. Opus reviewers and verifiers.

### R6-1 · minor · work context

Task 3's manual check still reads a file under `link/.ssh/keys/` to probe the deny rule; if the rule doesn't follow the
link, a private key enters the transcript. Strike it or probe a planted dummy file.
Fixed: Task 3's manual check probes a planted dummy `link/.ssh/keys/deny-probe`, never a real key.

### R6-2 · minor · work context

Refuted: the `example-client/x` fixtures in Tasks 2, 2b, 9 and 11 never reach the platform; Task 8's rule is scoped to
its own filing tests.

### R6-3 · minor · work context

Task 9's save points leave `refs/checkpoints/*` in a customer clone with no one named to delete them, and the customer
toy run doesn't check for them.
Fixed: Task 5 req 9 deletes `refs/checkpoints/<branch>/*` after the commit; Task 9's customer run checks the refs, Task 5's completion their removal.

### R6-4 · nit · work context

Task 4's `diagnosing-superpowers` row implies filing upstream from personal work; the guard blocks it at every level.
Refuted as minor: the safe outcome is a draft. Downgraded to nit.

### R6-5 · minor · work context

Task M writes `CLAUDE.local.md` and `.claude/settings.local.json` into another repo without resolving its level.
Fixed: Task M resolves the repo's level and checks both files are ignored first; anything else → stop and ask.

### R6-6 · nit · work context

Refuted: "Kari" is a placeholder fixture author, not a person.

### R6-7 · nit · work context

Refuted: the private-repo description in Task M and § Findings names nothing.

### R6-8 · nit · work context

Task 1's level rule 3 omits `~/.claude-company-orgs`, which the built guard reads; no as-built note.

### R6-9 · major · scope

No step chains the four stages on one piece of work, though the Goal promises it and every plan must end with an
end-to-end verification step; the `ai implement` and `ai plan` hand-off lines and an intake plan reaching
`implementing-plans` are never checked.
Fixed: Task 10's Tests end with a four-stage end-to-end test in a scratch repo, naming what each hand-off must produce.

### R6-10 · minor · scope

Task 12's CI step runs in `markdown.yml`, whose `paths:` miss non-markdown files under `claude/` and `.claude/`.
Refuted as major: the attack's targets are markdown, already covered, and pre-commit backstops. `**/AGENTS.md` is
already matched by `**.md`.
Fixed: Task 12 adds `claude/**`, `.claude/**` and its own script and test to `markdown.yml`'s `paths:`.

### R6-11 · minor · scope

Task 12's pre-commit wiring "beside its `check-md-limits` call, over staged files" reads two ways (only `md_files`, or
every staged file).
Fixed: Task 12: pre-commit runs `--cached` over every staged default-set path (`--diff-filter=ACMR`), markdown or not.

### R6-12 · minor · scope

Task 11 names only `tests.yml`'s three legs; `tests-wsl.yml` is separate, installs no jq, and has its own error scan.
Fixed: Task 11 names `tests-wsl.yml` (no `jq`, own error scan) in its check and its CI test.

### R6-13 · minor · scope

Refuted: `init/52_macos_claude.sh` never calls the `claude` CLI and works without it installed.

### R6-14 · minor · scope

No task owns clearing Task 9's `refs/checkpoints/*`; the commit runs in Task 5's review session, which doesn't.
Fixed: with R6-3.

### R6-15 · minor · scope

Task 9 has no behaviour for a repo with no test suite.
Fixed: Task 9's suite is the plan's command, else `CLAUDE.md`'s, else ask once; no suite → reported, run continues; tested.

### R6-16 · minor · scope

Task 8's `maintaining-follow-up-trackers` search clause appears in no test.
Fixed: Task 8 adds a Lookup test: an `(issue to file)` item matching the first test's issue gains its number; a near-title doesn't.

### R6-17 · minor · scope

Task 7 widens the research's ask (score the four stage skills' what-and-when form) to user-reviewed eval sets for all 17.
Fixed: Task 7 narrows the eval sets and scoring to the four stage skills; the rest get the audit only.

### R6-18 · nit · scope

Task 3b's "real-settings merge pending" note is stale; the live settings already hold its matcher and deny rules.
Refuted as minor: no step can be dropped silently.

### R6-19 · minor · scope

The file map omits Task 9's `test/skill-triggers/writing-plans.json`, Task 12's tip, index and ShellCheck edits, and
Task 3b's files.
Fixed: with R6-78.

### R6-20 · nit · scope

The handover's "Task 6b is built and 🚧. Task 5b's skill is committed, ⏳" contradicts the table; line 121 is redundant.

### R6-21 · nit · scope

Task 10 doesn't rule out passing other `claude` flags through.

### R6-22 · major · test matrix

Task 5 req 4: the only diff-input test has both tasks staged; untracked and unstaged files are untested.
Fixed: Task 5's diff-input test adds an unstaged edit and an untracked file, both named in round 1.

### R6-23 · major · test matrix

Task 5: the exact closed names and the same-day `-2` suffix are untested; a missing `-2` overwrites a findings file.
Fixed: Task 5 adds a Closed names test: two same-day closes give `…-closed-<date>.md` and `…-closed-<date>-2.md`.

### R6-24 · major · test matrix

Task 5: the no-plan code review (`plan-review-<branch>.md`, `/` → `-`) has no test.
Fixed: Task 5 adds a No plan test on branch `feat/x` naming both files.

### R6-25 · major · test matrix

Task 5 req 8: re-evaluation is tested only at round 15, not repeating at 20 nor skipped when 15 finishes the review.
Fixed: Task 5's re-evaluation test adds round 20 and a round 15 that finishes with no re-evaluation line.

### R6-26 · minor · test matrix

Task 5: the exclude at company and customer level is untested in this skill. Refuted as major: in the main flow
`writing-plans` and `implementing-plans` write it, and Task 9's customer toy run asserts it.
Fixed: Task 5 adds an Exclude test at customer level.

### R6-27 · major · test matrix

Task 5 req 9: one commit per task, an out-of-list fix with the last task, commit only on a yes, and a customer-level
draft are untested.
Fixed: Task 5's completion test adds per-task commits, the out-of-list fix, the no answer, and the customer draft.

### R6-28 · major · test matrix

Task 5 intake: only `owner/repo#n` is tested, not a tracker ref resolved to its heading or an issue-less
`plan-<slug>.md`.
Fixed: Task 5's intake test adds tracker refs with and without an issue, and an unknown ref.

### R6-29 · minor · test matrix

Task 5 req 5: a refutation stored beside its finding, and unsupported findings dropped, are untested.
Fixed: Task 5 adds a Verification test: dropped or downgraded findings keep their refutation; unsupported ones appear only as dropped.

### R6-30 · minor · test matrix

Task 5 req 8: no test seeds a "stop" recommendation to check it goes to the user.
Fixed: Task 5's re-evaluation test seeds wording-only majors and expects a `user decision needed` stop.

### R6-31 · minor · test matrix

Task 5 test tampering plants only a deletion, not a loosened assertion.
Fixed: Task 5's test-tampering test adds a loosened assertion.

### R6-32 · minor · test matrix

Task 5 names: a nested `plan-*.md`, and a stem already starting `plan-`, are untested.
Fixed: Task 5's whose-work test adds an untracked `docs/plan-x.md` → `plan-x.md`, never `plan-plan-x.md`.

### R6-33 · minor · test matrix

Task 5 req 1's code-review evidence (a `Base:` line; commits all by the user's email) is untested.
Fixed: Task 5's whose-work test adds the `Base:` and all-own-commits code-review cases and a foreign-commit one that asks.

### R6-34 · minor · test matrix

Task 5 req 9: `filing-learnings` before "done" is unchecked.
Fixed: Task 5's completion test checks `filing-learnings` is invoked before the done report.

### R6-35 · minor · test matrix

Task 5: a log row with no round in the findings file counting as history is untested.
Fixed: Task 5 adds a History rows test, met by this plan's rows 1–5 and Round 6.

### R6-36 · major · test matrix

Task 8's customer tests don't say whether a `## Issues` section exists, so the "none → ask" turn and the write-back are
untestable.
Fixed: Task 8 fixes the customer scratch tree: the first test starts with no `## Issues`, asks, and writes it to `<tree>/CLAUDE.md`.

### R6-37 · minor · test matrix

Task 8: a customer section saying Claude files, with no marker, is untested. Refuted as major: the guard blocks it.
Fixed: Task 8 adds a section-says-Claude-files, no-marker test → draft plus the `! touch` line.

### R6-38 · minor · test matrix

Task 8: the "company elsewhere" draft is untested. Refuted as major: same path as the customer tests; host covered by
R6-44.
Fixed: Task 8 adds a company-elsewhere test on `ghe.example.com`.

### R6-39 · major · test matrix

Task 8: "on a match, comment instead" can't fail; every filing target is a nonexistent repo.
Fixed: Task 8 adds a Search match test against the first test's real issue.

### R6-40 · major · test matrix

Task 8: no test checks the issue's shape (title under 70, five sections, checkboxes, path and line at a commit).
Fixed: Task 8's first pressure test checks the filed issue's title, headings, checkboxes and code references.

### R6-41 · major · test matrix

Task 8: no test asserts the printed `ai plan …` line in its three forms.
Fixed: Task 8 asserts the printed line for a github.com issue and an `(issue to file)` item; the URL form is stated as having no live test.

### R6-42 · minor · test matrix

Task 8: the scratchpad draft checkpoint is untested. Refuted as major: it matters only on mid-interview compaction.
Fixed: Task 8's interview test checks the newest `issue-draft-<n>.md` after the second answer.

### R6-43 · major · test matrix

Task 8: the `Target:` line and the `(issue to file)` lookup edits to the tracker skills are untested.
Fixed: Task 8's Lookup test covers the tracker-skill edit; the `Target:` values are exact in the existing tests.

### R6-44 · major · test matrix

Task 8: the `brew unlink glab` draft test doesn't require `GITLAB_HOST=gitlab.example.com`.
Fixed: Task 8's `brew unlink glab` test requires the `GITLAB_HOST=gitlab.example.com` line.

### R6-45 · major · test matrix

Task 8: the flaky-test interview fixture is unspecified, so "asks which test" and "doesn't ask what the code answers"
can contradict.
Fixed: Task 8's interview fixture is two passing tests and no CI history, with the expected and forbidden questions named.

### R6-46 · minor · test matrix

Task 8: "no tracker → ask" has no test.
Fixed: Task 8 adds a No tracker test.

### R6-47 · minor · test matrix

Task 8: "unsure → ask", `-R <origin>` with several remotes, labels only from `label list`, shell characters kept out of
titles, and glab `--yes` are untested.
Fixed: Task 8 adds Unsure, Shell characters, several-remotes, no-label and `--yes` tests.

### R6-48 · minor · test matrix

Task 8: "at most a few questions" is not a bar a test can fail.
Fixed: Task 8's first pressure test bar is at most five questions.

### R6-49 · major · test matrix

Task 9's refusal test covers only "no review log", not rows without `Done (plan):`, a closed section, or `Done (code):`.
Fixed: Task 9's refusal tests add rows without `Done (plan):`, a closed section and a code-only log.

### R6-50 · minor · test matrix

Task 9: the `Base:` value is never asserted. Refuted as major: the branch is found by the resume test, and a missing
line surfaces in Task 5's diff input.
Fixed: Task 9's personal toy run asserts the `Base:` line equals the initial commit's SHA, after a blank line.

### R6-51 · major · test matrix

Task 9: resuming with leftover unstaged or untracked paths is untested.
Fixed: Task 9's resume test adds an in-list and an out-of-list untracked file.

### R6-52 · major · test matrix

Task 9: `model` on every dispatch, the opus retry and the stopped-part-way output are untested.
Fixed: Task 9 checks `model` on every Agent call and adds a Failing task test for the opus retry and the stopped-part-way output.

### R6-53 · minor · test matrix

Task 9: the flip's rerun names no bar. Refuted as major: Task 6b § Bar is the bar; Task 9 just doesn't cite it.
Fixed: with R6-77.

### R6-54 · minor · test matrix

Task 9's clean-tree check isn't tested with an untracked stray or a modified backlog.
Fixed: Task 9's refusal tests add an untracked stray (stops) and a modified backlog (doesn't).

### R6-55 · minor · test matrix

Task 9's toy plan has only new files; staging a modified or deleted path is never exercised.
Fixed: Task 9's toy plan edits `README` and deletes `old.txt`; the run checks `A`, `M` and `D` staged.

### R6-56 · minor · test matrix

Task 9: no duplicate exclude on resume, `filing-learnings`, the refs in the final report, and the implementer prompt
wording are untested.
Fixed: Task 9's toy run checks `filing-learnings`, the refs in the report and the prompt wording; resume checks one exclude line.

### R6-57 · minor · test matrix

Task 9: no test runs two dependent tasks from a fresh start and checks they go one at a time. Refuted as stated (the
resume run dispatches one task); reframed.
Fixed: Task 9 adds a Sequential, fresh test: separate dispatches, task 2 after task 1 is staged.

### R6-58 · minor · test matrix

Task 9's baseline assumes a test suite exists.
Fixed: with R6-15.

### R6-59 · major · test matrix

Task 10: `ai --model haiku review code` sets no variable, so "the flag beats the variable" can't fail.
Fixed: Task 10's test sets `AI_MODEL_REVIEW=sonnet` beside `--model haiku`.

### R6-60 · major · test matrix

Task 10: only `AI_MODEL_PLAN` is overridden; a misspelt `AI_MODEL_ISSUE`, `_IMPLEMENT` or `_REVIEW` passes.
Fixed: Task 10 tests each `AI_MODEL_*` variable.

### R6-61 · minor · test matrix

Task 10: empty-value cases are unspecified and `ai review code p.md` is untested.
Fixed: Task 10: an empty variable counts as unset, `--model ""` is usage; both tested, as is `ai review code p.md`.

### R6-62 · minor · test matrix

Task 10: "usage on stderr" passes on any stderr.
Fixed: Task 10 pins the usage line and tests stderr's first line equals it.

### R6-63 · major · test matrix

Task 12: one fixture per class misses off-by-one range ends, U+202E among them.
Fixed: Task 12 tests every range's ends and their outside neighbours.

### R6-64 · major · test matrix

Task 12: U+FEFF away from byte 0 is never planted.
Fixed: Task 12 tests U+FEFF mid-line 1 and at the start of line 2.

### R6-65 · major · test matrix

Task 12: the default file set is tested only by the `unslop` exclusion; a set that scans nothing passes.
Fixed: Task 12 adds a default-set test in a temp repo naming exactly the four tracked default-set files.

### R6-66 · major · test matrix

Task 12: the `hooks/pre-commit` integration has no test, and CI is no backstop for non-markdown files.
Fixed: Task 12 adds a pre-commit test, and `markdown.yml` now triggers on `claude/**` and `.claude/**`.

### R6-67 · nit · test matrix

Task 12's grep/perl fallback. Refuted as minor: the macOS CI leg already runs the perl path.

### R6-68 · minor · test matrix

Task 12's output format (name, hex case, several hits, missing file) is unpinned.
Fixed: Task 12 pins the output line, hex case, `<NAME>`, one line per hit and the missing-file exit 2.

### R6-69 · minor · test matrix

Task 11's "not doubled" case is ambiguous and the empty `menu_selects` case unnamed.
Fixed: Task 11 names the four `menu_selects` cases, the empty one included.

### R6-70 · nit · test matrix

Task 11: `init_files()` calling the migration isn't automated. Refuted as minor: the manual check fails without it.

### R6-71 · minor · test matrix

Task 7's "every skill has an eval set" lists no skills and no mechanical check.
Fixed: Task 7 names the four stage skills and an `ls test/skill-triggers/` check (with R6-17).

### R6-72 · minor · test matrix

Task 4: only the table is checked; the other doc edits have no check.
Fixed: Task 4 adds a `grep -F` check for each of its other doc edits.

### R6-73 · nit · test matrix

Task 4's `ls … | tail -1` sorts lexically.

### R6-74 · minor · test matrix

Task M names no expected `jq` output and no restore check.
Fixed: Task M names the expected `jq` content and a `diff` restore check.

### R6-75 · minor · test matrix

Refuted: the shim has one code path for every tool, and the guard tests cover glab and az.

### R6-76 · nit · test matrix

Task 3's deny entries are asserted by count. Refuted as minor: Task 3 is done and the count catches a dropped entry.

### R6-77 · minor · consistency

Task 9's `1.11` flip names no expected score and no action on a fail, and no trigger eval checks `implementing-plans`
loads on it. Refuted as major: the plan states the user's decision, and `1.11` already scores 0/3 for `writing-plans`.
Fixed: Task 9 adds `implementing-plans.json` with `1.11` as `1.1`, names 6b § Bar for the flipped query, and a miss is recorded for Task 7.

### R6-78 · major · consistency

The file map omits Task 12's `shellcheck.yml`, tip and `tips.md` edits and Task 9's `writing-plans.json`; Tasks 10 and
12 edit the same `tips.md` entry and ShellCheck list, so a parallel run collides.
Fixed: the file map lists every task's files (3b, 4, 9, 12 added) and says Tasks 10 and 12 never run in parallel.

### R6-79 · minor · consistency

Task 9 step 3 drops Task 5's "after a blank line" for `Base:`, and never points at `review-log.md`.
Fixed: Task 9 step 3 writes `Base:` per Task 5's interface: its own line, after a blank line.

### R6-80 · minor · consistency

Task 5's "Still to run, all needing Tasks 8–10" includes cases that need no later task.
Fixed: Task 5's status splits the remaining tests into those needing Tasks 8–10 and those runnable now.

### R6-81 · minor · consistency

Task 3's "Status, 2026-10-16" still says the merge is pending, against the table.
Fixed: Task 3's status note records the 2026-10-16 merge and the 2026-10-19 marker check.

### R6-82 · nit · consistency

Task 2's hook JSON shows the pre-3b matcher. Refuted as minor: Task 3b states the change and tests it.

### R6-83 · minor · consistency

The plan says superpowers 6.4.1; 7.0.0 is installed; Task 4's "On 6.4.1" and Task 9's "in 6.4.1" and the deferral are
stale.
Fixed: § Findings records 7.0.0 installed from the official marketplace, Tasks 4 and 9 cite 7.0.0, and the upgrade deferral is removed.

### R6-84 · minor · consistency

Task 12's file set covers scripts and JSON its CI trigger never runs on.
Fixed: with R6-10.

### R6-85 · nit · consistency

Refuted: the handover sentence is a dated snapshot, corrected just below.

### R6-86 · nit · consistency

Task 1's Marker bullet "passes at `company` or `customer` when…" predates company passing every write.

### R6-87 · nit · consistency

Task 2 says `work-contexts.md` stays under its 100-line aim; it is 111.

### R6-88 · nit · consistency

Refuted: both descriptions of `1.11` match the query, named by id.

### R6-89 · nit · consistency

The checkpoints decision says "the user commits at the end"; Task 5 req 9 has Claude commit on a yes.

### R6-90 · major · clarify

How paths come out of a prose Files list is undefined (Task 5 req 9, Task 9 checkpoint).
Fixed: Task 5's `writing-plans` edits define the Files-list form once; Task 5 req 9 and Task 9 point to it.

### R6-91 · major · clarify

Task 9: "an implementer fails twice" has no definition of failure, and no test.
Fixed: Task 9 defines a failed attempt (blocked report, or review or tests failing after the fix loop) and tests it.

### R6-92 · major · clarify

Task 10's spike: interactive or headless `claude`, which sets every stage's prompt form.
Fixed: Task 10's spike and stages run interactive `claude`, never `-p`.

### R6-93 · minor · clarify

Task 8's "the host is always explicit" invites a `github.com/` prefix. Refuted as major: the next sentence defines the
bare form.
Fixed: Task 8's `!` lines name the bare `owner/repo` on `github.com`, never a `github.com/` prefix, and the host elsewhere.

### R6-94 · major · clarify

Task 8's `-R <origin's owner/repo>` exception ignores the host; on GitLab it files on glab's default host.
Fixed: Task 8 passes origin's target with its host off `github.com`: gh `-R <host>/<owner>/<repo>`, glab `GITLAB_HOST=<host>` plus `-R`; tested.

### R6-95 · minor · clarify

Task 8's first pressure test leaves the item to publish to the executor. Refuted as major: the last turn shows it.
Fixed: Task 8's first pressure test has the user name the item.

### R6-96 · major · clarify

Task 12's pre-commit file set reads two ways; whether fixtures are committed or generated is unstated.
Fixed: Task 12 fixes the pre-commit set (with R6-11) and generates fixtures in a `mktemp -d`, never committed.

### R6-97 · major · clarify

Task 12's `markdown.yml` trigger misses non-markdown files the interface promises to cover.
Fixed: with R6-10.

### R6-98 · minor · clarify

Task 12: grep or perl, and what `<name>` means.
Fixed: Task 12 matches with perl alone and defines `<NAME>` as `charnames::viacode`.

### R6-99 · minor · clarify

Task 12: the tip and index edits have no content, and Tip 24.4 is the symlink map.
Fixed: Task 12's tip is a new one at the end of Tip 24's file with named content, plus a `tips.md` name; Tip 24.4 is no longer used.

### R6-100 · minor · clarify

Refuted: "beats" and "at least as well" don't conflict; a tie keeps the old description.

### R6-101 · minor · clarify

Task 7 names no `--model` for scoring.
Fixed: Task 7 scores with `skill-trigger-eval`'s default model per skill.

### R6-102 · minor · clarify

Refuted: Task 7 explicitly orders the what-and-when candidate as a measurement.

### R6-103 · minor · clarify

Task 9 doesn't say whether the baseline runs on resume.
Fixed: Task 9's baseline runs on a fresh start and on resume.

### R6-104 · minor · clarify

Task 9's `git update-ref -d` has no owner. Same as R6-14.
Fixed: with R6-3.

### R6-105 · nit · clarify

Task 9: `git stash create` printing nothing. Refuted as minor: rare, since staged work makes the index differ.

### R6-106 · minor · clarify

Refuted: `1.11` is the last `1.x`; the next free `2.n` is 2.11; no renumbering.

### R6-107 · minor · clarify

Task 9: "no order between them" names no source.
Fixed: Task 9 defines no order: neither task's Interfaces consumes the other's, and the plan's order line doesn't sequence them.

### R6-108 · nit · clarify

Task 5 intake tool and slug rule. Refuted as minor: the intake is written and the branch derives from the file it wrote.

### R6-109 · nit · clarify

Task 10 argument edge cases. Refuted as minor: usage covers `-h`; only `--model=x` is open.

### R6-110 · minor · clarify

Task 11: where `renamed_init_scripts` sits relative to the `source` guard.
Fixed: Task 11 places `renamed_init_scripts` with the function above the `source` guard.

### R6-111 · nit · clarify

Task 11 tip sentence order. Downgraded: wording.

### R6-112 · nit · clarify

Task 11's `git grep` includes this plan. Downgraded: the plan is temporary.

### R6-113 · minor · clarify

Task 4's rewrite leaves `writing-agent-instructions`' role out.
Fixed: Task 4's paragraph rewrite keeps `writing-agent-instructions`' part, and its test greps for it.

### R6-114 · nit · clarify

Task 4's company-work sentence. Downgraded: the global rule already decides it.

### R6-115 · minor · clarify

Task 4's Files omit `claude/CLAUDE.md`, whose `reviewing-locally` line goes stale.
Fixed: Task 4's Files add `claude/CLAUDE.md` § Working on code, line count unchanged.

### R6-116 · minor · clarify

Task M: by hand or by the executor; step 2 needs the interactive menu.
Fixed: Task M says the user runs every step and the menu is interactive.

### R6-117 · nit · clarify

Task 9's `example-client/x`. Downgraded: no fetch, and pushes are blocked.

### R6-118 · nit · clarify

Stale line numbers in Task 11 (`tests.yml:150`, `bin/dotfiles:323-325`).

### R6-119 · nit · clarify

Refuted: Task 4 finds anchors by quoted text.

### R6-120 · major · data flow

Task 5 req 9's `git diff --cached --name-only` drops a rename's deletion; Task 11 is a rename. Reproduced.
Fixed: Task 5 req 9 uses `--no-renames`, with a `git mv` completion test.

### R6-121 · major · data flow

Two skills parse an undefined Files-list format. Same root as R6-90.
Fixed: with R6-90.

### R6-122 · major · data flow

Task 9 stages and checks only the paths the implementer reports; an unreported edit is neither staged nor stopped.
Fixed: Task 9 checks every path in `git status --porcelain`, reported or not, against the Files list; tested with an unreported edit.

### R6-123 · minor · data flow

Task 9 resume doesn't check the index against the checkpoint. Refuted as major: a `restore --staged` surfaces as an
out-of-list path; only a full stash slips past.
Fixed: Task 9 resume compares the index's tree with the last checkpoint's and stops naming the restore; tested.

### R6-124 · minor · data flow

Task 9's test-suite source, no-suite case, slow suite and batch attribution. Refuted as major: routine and recoverable.
Fixed: Task 9 pins a failing suite after a parallel batch by each task's scoped tests, else stops (source and no-suite with R6-15).

### R6-125 · major · data flow

Task 8 escapes only `"` in `ai plan "<title>"`; backticks and `$(…)` in a heading run in zsh.
Fixed: Task 8 prints the `ai plan` title in single quotes with `'` as `'\''`.

### R6-126 · major · data flow

Task 8 comments on a search match with no "anything to change?" turn.
Fixed: Task 8 asks "comment there instead?" before commenting on a match.

### R6-127 · major · data flow

Task 8's `(issue to file)` lookup takes the first fuzzy match; `issue list` defaults to open and 30.
Fixed: Task 8's lookup uses `--state all --limit 100` / `--all --per-page 100` and takes only one exact title match; several → ask.

### R6-128 · minor · data flow

Task 12's `grep -nP` "where available". Refuted as major: the macOS leg's fixtures would fail it.
Fixed: with R6-98.

### R6-129 · major · data flow

Task 12's CI trigger. Same as R6-97.
Fixed: with R6-10.

### R6-130 · minor · data flow

Task 7's eval volume has no budget, retry or resume. Refuted as major: 6b states the size, and a failure is
per-skill re-runnable.
Fixed: Task 7 re-runs a failed skill once, then records and skips it; narrowed to four skills with R6-17.

### R6-131 · minor · data flow

Task 7's audit paste needs a scrub line. Refuted as major: § Global constraints already forbids it.
Fixed: Task 7: nothing from the audit is recorded that § Global constraints bars.

### R6-132 · minor · data flow

Task 8's fixed `issue-draft.md` name; a second draft overwrites the first.
Fixed: Task 8 numbers drafts `issue-draft-<n>.md`; compaction resumes from the highest.

### R6-133 · minor · data flow

Task 8: a create that timed out may have succeeded; re-search before the `!` line.
Fixed: Task 8 re-searches after a timeout or dropped connection before giving the `!` line.

### R6-134 · minor · data flow

Task 9: `git stash create` empty → `update-ref` exits 128. Reproduced.
Fixed: Task 9: an empty `git stash create` gives that task no ref, and the report says so.

### R6-135 · minor · data flow

Task 9's refs have no cleanup owner. Same as R6-14.
Fixed: with R6-3.

### R6-136 · minor · data flow

Task 9's `Base:` goes stale after a rebase or merge between sessions.
Fixed: Task 9 resume stops and asks when `Base:` isn't an ancestor of `HEAD`; tested.

### R6-137 · minor · data flow

Task 9: a new gitignored file is left out of the reviewer's input.
Fixed: Task 9 stops on a gitignored Files-list path; tested.

### R6-138 · minor · data flow

Task 5 intake and Task 8: no rule for a heading matching nothing or several items.
Fixed: Task 5 intake asks on a ref or heading matching none or several items; Task 8's lookup asks on several (R6-127).

### R6-139 · minor · data flow

Task 12: a missing path exits 0 under perl; pre-commit should pass `--diff-filter=ACMR`.
Fixed: Task 12: a missing file exits 2; pre-commit passes `--diff-filter=ACMR`.

### R6-140 · minor · data flow

Task 12 pre-commit checks the working tree, not the staged blob.
Fixed: Task 12 adds `--cached` (staged blobs), used by pre-commit and tested.

### R6-141 · minor · data flow

Task 10: an empty `AI_MODEL_*=` or `--model ""` passes an empty model.
Fixed: with R6-61.

### R6-142 · minor · data flow

Task 4's version pick; read `installPath` from `installed_plugins.json`.
Fixed: Task 4's check reads `installPath` from `installed_plugins.json`.

### R6-143 · nit · data flow

Task 11's both-names case. Downgraded: covered in substance.

### R6-144 · nit · data flow

Task 8's unquoted `<path>` in `$(cat <path>)`.

### R6-145 · nit · data flow

"Every review" regenerating `reviewed-plan.md`: once per run or per round.

## Round 7

Lenses: scope, clarify, data flow, test matrix, consistency, work context. Opus reviewers and verifiers.

### R7-1 · minor · work context

Task 1's level rules and its as-built note omit `~/.claude-company-orgs`; Task M's classifier text calls listed owners
customer. Refuted as major: Task 1 is built and its own tests cover the lookup; Task M's wording errs stricter.

Fixed: Task 1's rule 3 and a new as-built bullet name `~/.claude-company-orgs`; Task M's environment text lists those owners as company.

### R7-2 · nit · work context

Global constraints say `example-client` for fixtures while Task 8 says live sessions use `example--client`. Refuted as
major: none of the cited live sessions reaches the network; only wording for future tasks remains.

### R7-3 · minor · work context

Task 4's `writing-skills` and `diagnosing-superpowers` rows read as fine at personal level, but an upstream issue or a
fork-to-parent PR is a third-party target the guard blocks at every level.

Fixed: Task 4's `writing-skills` and `diagnosing-superpowers` rows say to draft the upstream PR or issue, which the guard blocks at every level.

### R7-4 · minor · work context

Task 5 req 9 with no plan offers a commit on whatever branch is checked out, `main` included, with no default-branch
check against the company bar.

Fixed: Task 5 req 9: with no plan on the default branch at company level no commit is offered; Completion test added.

### R7-5 · minor · work context

Task 5b req 1 covers a branch only though the interface accepts an MR or PR number; no test with a number.

Fixed: Task 5b req 1 fetches a PR or MR number's head ref into `FETCH_HEAD`; a *By number* test, built in Task 9's first step.

### R7-6 · minor · work context

Task 8's first pressure test files a real public issue from the gitignored tracker; nothing checks the body quotes
nothing from it beyond the title.

Fixed: Task 8's first pressure test asserts no non-empty body line is also a tracker-item line, bar the title.

### R7-7 · nit · work context

Task 10's end-to-end step 1 lacks Task 8's absence check for `andrelin/x`.

### R7-8 · minor · scope

The file map row "`test/skill-triggers/*.json`, the rest | 7" and Task 6b's "(Task 7 writes the rest)" contradict
Task 7's four-stage-skills scope. Refuted as major: Task 7's own text and test are explicit.

Fixed: File map row and Task 6b's Files now name only the stage skills' eval sets Task 7 writes.

### R7-9 · major · scope

Task 7's "fix findings that fit the global constraints" is unbounded and clashes with `tuning-skill-descriptions`, which
needs an eval set before any description change, while non-stage skills get the audit only; body rewrites and renames
aren't ruled out.

Fixed: Task 7 fixes in place only limit breaches, broken references, front matter and stage-skill descriptions; *Bounded fixes* test.

### R7-10 · minor · scope

Refuted: `1.11` already scores 0/3 for `writing-plans`, which meets the flipped bar, so Task 9 needs no description edit.

### R7-11 · major · scope

No task closes out this plan: nothing folds § Findings and decisions and the four-stage workflow into a durable doc and
deletes the plan and its findings file, as `writing-plans` § Plans are temporary requires.

Fixed: New Task 13 folds the decisions into `claude/docs/staged-workflow.md` and `work-contexts.md` and deletes both plan files, last.

### R7-12 · minor · scope

`README.md` § Scripts lists `bin/` scripts; Tasks 10 and 12 don't add `ai` or `check-hidden-unicode`, and
`claude-settings-merge` and `skill-trigger-eval` are already missing.

Fixed: Tasks 10 and 12 add `README.md` § *Scripts* lines for `ai`, `check-hidden-unicode` and the two missing scripts.

### R7-13 · minor · scope

Task 12's hook passes staged paths, so it must copy the default-set filter; run `bin/check-hidden-unicode --cached` with
no paths instead.

Fixed: Task 12's hook runs `bin/check-hidden-unicode --cached` with no paths, the default set defined only in the script.

### R7-14 · minor · scope

Task 12 misses variation selectors (U+FE00–U+FE0E, U+E0100–U+E01EF), U+2061–U+2064, U+180E and U+00AD; keep U+FE0F
passing.

Fixed: Task 12 flags U+2061–U+2064, U+180E, U+00AD and variation selectors U+FE00–U+FE0E and U+E0100–U+E01EF, U+FE0F passing; tests added.

### R7-15 · minor · scope

Task 8's "comment there instead?" yes path is a platform write no requirement asks for and is untested; say why.

Fixed: Task 8's yes to "comment there instead?" now drafts the comment as a `!` line at every level and files nothing.

### R7-16 · minor · scope

Task 10's end-to-end step 1 lacks the absence check. Same as R7-7.

Fixed: with R7-21.

### R7-17 · minor · scope

Refuted: the `claude/CLAUDE.md` line is a general rule pointing at the precedence doc, which names both counterparts.

### R7-18 · nit · scope

The handover's opening sentence is stale against the table.

### R7-19 · minor · test matrix

Task 12: `viacode` is undef for U+E0000, so the name field is unspecified. Refuted as major: the hit is still flagged
with exit 1, code point and line.

Fixed: Task 12 prints `(no name)` where `viacode` is undefined; U+E0000 test added.

### R7-20 · major · test matrix

Task 12 pre-commit: no test stages no default-set path, and none stages an out-of-set file holding U+200B (exit 0).

Fixed: Task 12 pre-commit test: only an out-of-set `docs/d.md` with U+200B staged → 0.

### R7-21 · major · test matrix

Task 10 end-to-end step 4 expects "one commit"; Task 5 req 9 makes one per task with disjoint Files lists.

Fixed: Task 10 end-to-end step 4 expects the commits Task 5's requirement 9 prescribes; step 1 gains Task 8's absence check.

### R7-22 · major · test matrix

Task 9's toy run never says where the suite command comes from; plan-named against `CLAUDE.md`-named is untested.

Fixed: Task 9's toy plan names its suite in § *Global constraints*; *Suite source* test covers plan against `CLAUDE.md`.

### R7-23 · major · test matrix

Task 9's rule pinning a batch's suite failure by rerunning scoped tests has no test.

Fixed: Task 9 *Pinned failure* test: a pinned suite failure sends the task back to its fix loop, an unpinned one stops.

### R7-24 · major · test matrix

Task 8's lookup with several equal titles, and the glab `--all --per-page 100` path, are untested.

Fixed: Task 8 *Lookup* adds a glab `--all --per-page 100` case and a two-equal-titles case in a tester-made private repo.

### R7-25 · major · test matrix

Task 8's search match answered yes is untested at every level.

Fixed: Task 8 *Search match* adds the yes answer (a drafted comment, no call).

### R7-26 · major · test matrix

Task 8's printed `ai plan` line: stripping and `'\''` quoting are never exercised.

Fixed: Task 8 adds an apostrophe-title test with the exact printed `ai plan '…'\''…'` line, stripped of ref, badge, branch and `(issue to file)`.

### R7-27 · major · test matrix

Task 5's verification test passes vacuously if nothing is dropped; nothing seeds a refutable or unsupported finding.

Fixed: Task 5 *Verification* seeds a safe-but-suspicious `rm -rf -- "${tmp:?}"/*` and fails when nothing is dropped or downgraded.

### R7-28 · major · test matrix

Task 5 req 8's "change a lens" outcome and a severity-scale change going to the user are never run.

Fixed: Task 5 *Re-evaluation* adds a change-a-lens seed and a severity-scale seed that stops for the user.

### R7-29 · major · test matrix

Task 5's `writing-plans` edits untested: the exclude at company and customer, intake by glab, URL and heading text, a
Jira key, and "more than one match → ask". (The handover step is covered by Task 10's end-to-end.)

Fixed: Task 5 intake tests add heading text, a duplicate heading, a GitHub URL, a glab URL and a Jira key; *Exclude* covers `/writing-plans`.

### R7-30 · major · test matrix

Task 5 req 4's merge-base fallback and "ask" path are untested; every Task 5 test has a `Base:` line.

Fixed: Task 5 *Diff input* adds a merge-base case against a local bare origin and an ask case with no origin.

### R7-31 · minor · test matrix

Task 5 req 9: overlapping lists, the plan-less commit, ref deletion after a drafted commit, and `plan-*` never staged
are untested.

Fixed: Task 5 *Completion* adds overlapping lists, a plan-less commit, ref deletion after a drafted commit and no `plan-*` staged.

### R7-32 · minor · test matrix

Task 5: no case asserts rounds 16–19 log no re-evaluation.

Fixed: Task 5 *Re-evaluation* adds a seed with 15 rows asserting no `Re-evaluation after round 16:` line.

### R7-33 · minor · test matrix

Task 5: a third same-day close is undefined.

Fixed: Task 5 close names take `-<n>` for the nth close that day; *Closed names* runs three closes.

### R7-34 · minor · test matrix

Task 5's exclude test covers customer only, with no company case and no negative case at personal.

Fixed: Task 5 *Exclude* covers customer and company origins and an unchanged exclude file at personal.

### R7-35 · minor · test matrix

Task 5 req 3's transcript check covers reviewers only, not verifiers, the re-evaluation or the fixer.

Fixed: Task 5's real-run check covers verifier, re-evaluation and fixer transcripts too.

### R7-36 · minor · test matrix

Task 5 req 2's explicit `model` has no named test.

Fixed: Task 5 *Reviewer prompts* asserts `model` on every reviewer and verifier Agent call.

### R7-37 · minor · test matrix

Task 4: `check-md-limits` passes a 101–200-line doc, and "claude/CLAUDE.md line count unchanged" has no test.

Fixed: Task 4 tests `wc -l` ≤ 100 for the doc and an unchanged `claude/CLAUDE.md` line count.

### R7-38 · minor · test matrix

Task 4: several doc edits have no check, and `grep -F` can't count four bullets.

Fixed: Task 4 tests grep the counts, below-table and paragraph edits, and count the four bullets with `awk`.

### R7-39 · minor · test matrix

Task 9 untested: an opus session's failing task, an empty `git stash create`, an unstaged in-list file on resume,
order-line sequencing, a shared build directory, company and personal exclude. Refuted in part: the branch name and
customer exclude are covered.

Fixed: Task 9 adds opus-session, unstaged-resume, shared-build and company and personal exclude tests; empty stash and order line cut.

### R7-40 · minor · test matrix

Task 9's failing-task test doesn't say the impossible test is added by the task, not pre-existing.

Fixed: Task 9 *Failing task* says the impossible test is one the task's spec adds.

### R7-41 · minor · test matrix

Task 8 untested: a second draft, a timeout then re-search, a succeeding `label list`, multi-remote `-R` on github.com,
the non-`gitlab` marker message, the Jira section step, `glab` in recipes_optional.

Fixed: Task 8 adds second-draft, `label list`, multi-remote, non-`gitlab` marker, Jira-section and recipe tests; timeouts per R7-97.

### R7-42 · minor · test matrix

Task 8's Interview test sits above the bullet that governs the customer-tree tests below it.

Fixed: Task 8's customer scratch tree bullet now precedes the Interview test, with tester cleanup.

### R7-43 · minor · test matrix

Task 10's end-to-end lacks the absence check. Same as R7-7.

Fixed: with R7-21.

### R7-44 · minor · test matrix

Task 10: `ai --model haiku` alone, a repeated `--model`, `ai plan ""` unspecified; stub assertions should be exact.

Fixed: Task 10 drops empty args, takes `--model` once, exits 2 on `ai --model haiku` and a repeat; stub output compared exactly.

### R7-45 · minor · test matrix

Task 11's init-selection test lacks new-before-old and order preservation.

Fixed: Task 11's init-selection test adds new-before-old and an order-kept case.

### R7-46 · minor · test matrix

Task 12 omits neighbours U+205F, U+2061, U+2065, U+FEFE, U+FF00, U+DFFFF; a missing file plus a hit, `--cached` on an
unindexed file and names with spaces are unspecified.

Fixed: Task 12 adds the named neighbours, a missing file plus a hit, `--cached` on an untracked file and a name with a space.

### R7-47 · minor · test matrix

Task 7's `unslop` decision and re-run-once rule are checked by no test.

Fixed: Task 7 *Recorded decisions* test checks the `unslop` choice and every re-run's exit status.

### R7-48 · nit · test matrix

A create against a nonexistent repo fails with "Could not resolve to a Repository", not on the network.

### R7-49 · major · consistency

Task 9 consumes Task 5's Files-list form, `--no-renames` pathspecs and checkpoint-ref cleanup, which Task 5's status
says are still to make; the handover and order line never say to make them before Task 9.

Fixed: Task 9 starts by making the edits Task 5's status lists (now including Task 5b's PR number); the order line, handover and status table say so.

### R7-50 · major · consistency

Task 8 prints a stripped title, but Task 5's intake resolves by heading text, and no Task 5 intake test passes a
stripped title.

Fixed: Task 5 intake matches heading text exactly after `writing-issues`' stripping; intake test passes Task 8's printed line.

### R7-51 · major · consistency

Task 9 gates parallel dispatch on "the plan's order line", which nothing defines.

Fixed: Task 9's parallel condition drops the order line, keeping only the Interfaces check.

### R7-52 · nit · consistency

The order line says M after 3 though M checks 3b. Refuted as minor: both are done.

### R7-53 · nit · consistency

Task 6b and 9 give opposite rationales for `1.11`. Refuted as minor: the user's decision supersedes 6b's in the same
note.

### R7-54 · minor · consistency

Task 5's Files list doesn't name § What each task carries, where the pending Files-list form goes; line numbers stale.

Fixed: Task 5's Files list names sections, § *What each task carries* included, instead of stale line numbers.

### R7-55 · minor · consistency

Task 10's end-to-end "one commit". Same as R7-21.

Fixed: with R7-21.

### R7-56 · nit · consistency

The file map is off against done tasks' Files lists. Refuted as minor: no conflict possible now.

### R7-57 · nit · consistency

The handover heading date. Refuted as minor: a dated snapshot.

### R7-58 · minor · consistency

Tasks 8, 10 and 11 say to record results "in the status table" though results live in each task's section.

Fixed: Tasks 8, 10 and 11 record results in a status note in the task.

### R7-59 · nit · consistency

Task 11's tip line numbers. Refuted as minor: anchored on quoted text.

### R7-60 · nit · consistency

Task 7's Interfaces say "none".

### R7-61 · nit · consistency

Task 1's level list split by a paragraph.

### R7-62 · nit · consistency

Task 1's marker bullet stale.

### R7-63 · nit · consistency

Refuted: Task 6b's two assertion counts are dated.

### R7-64 · nit · consistency

"The user commits at the end" against Task 5 req 9.

### R7-65 · major · clarify

Task 9's checkpoint reads plain `git status --porcelain`, which collapses a new directory to one `?? test/` entry, so a
task creating one stops falsely. Reproduced. Same root as R7-94.

Fixed: with R7-93.

### R7-66 · minor · clarify

Task 9 after a parallel batch: which Files list the out-of-list check uses. Refuted as major: lists are disjoint and
staging one at a time implies per task. Same root as R7-93.

Fixed: with R7-93.

### R7-67 · minor · clarify

Task 8's printed title against intake matching. Refuted as major: a contains-match is natural, and a miss asks. Same root
as R7-50.

Fixed: with R7-50.

### R7-68 · minor · clarify

Task 5 req 9 with lists partly overlapping is unspecified. Refuted as major: the commit is offered and declinable.

Fixed: Task 5 req 9: one commit per task only when every pair of lists is disjoint, else one commit of all.

### R7-69 · major · clarify

Task 4's "on company work only the brainstorming and using-git-worktrees rows apply" contradicts its own
`diagnosing-superpowers` and execution rows.

Fixed: Task 4's second below-table sentence: on company work every row applies except `finishing-a-development-branch`.

### R7-70 · minor · clarify

Task 8's lookup test gives no repo or origin for the scratch tracker. Refuted as major: no stall is established.

Fixed: Task 8 *Lookup* runs in an origin-less scratch repo.

### R7-71 · minor · clarify

Task 11's "every other reference git grep finds" literally includes the migration map and its fixtures. Refuted as
major: the Files entry spells them out.

Fixed: Task 11 excludes the migration map entry and the test fixtures from the references to update.

### R7-72 · minor · clarify

Task 9 overrides SDD's fix-loop escalation without saying whether its rounds 4–5 still run.

Fixed: Task 9: SDD's five fix rounds still run, rounds 4–5 on the same model, the opus retry the only escalation.

### R7-73 · minor · clarify

Task 9: "the last checkpoint" undefined; a colliding branch with no `Base:` is taken as a resume. Same root as R7-96.

Fixed: with R7-96.

### R7-74 · nit · clarify

Task 9's `<task>` ref segment. Refuted as minor: the tests pin the number form.

### R7-75 · nit · clarify

Task 9's branch start point. Refuted as minor: `switch -c` starts at HEAD.

### R7-76 · minor · clarify

Task 9's toy plan names no suite, so the run asks mid-test. Same as R7-22.

Fixed: with R7-22.

### R7-77 · minor · clarify

Task 12: who filters staged paths. Same as R7-13.

Fixed: with R7-13.

### R7-78 · minor · clarify

Task 12: no name rule for U+E0000. Same as R7-19.

Fixed: with R7-19.

### R7-79 · minor · clarify

Task 12 with `--cached`: "doesn't exist" on disk or in the index.

Fixed: Task 12: with `--cached`, a file not in the index is the missing case; the others are still checked, exit 2.

### R7-80 · nit · clarify

Task 8's `Target:` markup. Refuted as minor: the executor defines it once for both sides.

### R7-81 · nit · clarify

Task 8's `-R` forms. Refuted as minor: both valid; the reason is given.

### R7-82 · minor · clarify

Task 8's filing-time search leaves `--state` and the match rule to judgement.

Fixed: Task 8's search is `--state open` limited to 10, and a match is one describing the draft's *Problem*; no match files unasked.

### R7-83 · minor · clarify

Task 8's Interview test placement and scratch-tree cleanup. Same root as R7-42.

Fixed: with R7-42.

### R7-84 · minor · clarify

The Files-list form: a span naming a directory without `/` matches nothing in the `--name-only` intersection, dropping
files from the commit.

Fixed: Task 5's Files-list form: a span naming a directory covers its paths with or without a trailing `/`.

### R7-85 · nit · clarify

Task 7's what-and-when candidate. Refuted as minor: framed as a measurement only.

### R7-86 · nit · clarify

Task 7's `unslop` decision owner. Refuted as minor: the executor decides and records.

### R7-87 · nit · clarify

Refuted: Task 10's `--help`, `--model=x` and `--` are each an unknown stage, so usage and exit 2.

### R7-88 · nit · clarify

Task 9's model alias. Refuted as minor: the Agent tool takes aliases only.

### R7-89 · nit · clarify

Refuted: `reviewing-in-rounds` is the right counterpart of `requesting-code-review`.

### R7-90 · nit · clarify

Task 4's anchor clause position.

### R7-91 · nit · clarify

Task M step 1's bullet order.

### R7-92 · nit · clarify

Refuted: the handover sentence is dated.

### R7-93 · major · data flow

Task 9's checkpoint check also lists paths earlier tasks staged, so task 2's checkpoint stops on task 1's files, and a
batch's other tasks trip it too. Reproduced.

Fixed: Task 9 defines one listing (`--porcelain -z --untracked-files=all`, excludes) whose unstaged and untracked entries are checked.

### R7-94 · major · data flow

A new untracked directory is one porcelain entry; use `--untracked-files=all` and `-z`. Reproduced. Same root as R7-65.

Fixed: with R7-93.

### R7-95 · major · data flow

Task 9's baseline on resume runs with an interrupted task's leftovers, so a test written first makes every resume stop.

Fixed: Task 9 skips the baseline on resume and says so in the final report.

### R7-96 · major · data flow

Task 9: a branch that exists with no `Base:` line is unhandled.

Fixed: Task 9 resume: a branch that exists with no `Base:` line stops and asks; test added.

### R7-97 · major · data flow

Task 8's re-search after a timeout can report the older matched issue as filed, or miss an unindexed create and
duplicate it.

Fixed: Task 8: after a timeout the outcome is reported unknown with the issues URL to check, no re-search or item.

### R7-98 · minor · data flow

Nothing makes an `(issue to file)` item's heading equal the filed title, so the exact lookup never matches. Refuted as
major: it fails visibly.

Fixed: Task 8 makes an `(issue to file)` item's heading title the drafted title verbatim; test asserts it.

### R7-99 · major · data flow

Headings use bare `issue #373`; in a tree-root tracker spanning repos, intake reads the wrong repo's #373; nothing says
`Target:` survives numbering.

Fixed: Task 8 keeps `Target:` once numbered; Task 5 intake reads the issue from `Target:`, asking in a multi-repo tree without one; tests added.

### R7-100 · major · data flow

Task 5 req 9 stages the fixer's reported paths; an unreported out-of-list fix is never staged or reported.

Fixed: Task 5 req 9 stages leftovers new since round 1 from Task 9's listing, not the fixer's report; new-directory test added.

### R7-101 · major · data flow

Task 8's drafted glab `!` line omits `--yes`, which glab needs with no TTY.

Fixed: Task 8's drafted glab `!` line holds `--yes`, and the missing-CLI test asserts it.

### R7-102 · minor · data flow

Task 12: undefined name for unassigned code points. Same as R7-19.

Fixed: with R7-19.

### R7-103 · minor · data flow

Task 12 flags U+200D, so ZWJ emoji fail, contradicting "Emoji … pass".

Fixed: Task 12 says a ZWJ sequence is flagged at its U+200D; test added.

### R7-104 · minor · data flow

Task 12: no behaviour for malformed UTF-8 or binary input; `charnames` on the RHEL leg unverified.

Fixed: Task 12 matches UTF-8 byte sequences so malformed bytes can't stop the scan; tests for a stray byte and for `charnames` on every CI leg.

### R7-105 · minor · data flow

Task 12's hook duplicates the default-set filter. Same as R7-13.

Fixed: with R7-13.

### R7-106 · minor · data flow

The guard blocks `git init` then a write in one call, `cd "$var"`, and `git -C <path>` writes in some contexts; tests
and the reviewer prompt should use their own call and literal paths.

Fixed: New § *Global constraints* scratch-repo rule; Task 5 req 3 points reviewers' experiments at it.

### R7-107 · minor · data flow

Task 8: a user-filed draft's body lives only in the session scratchpad.

Fixed: Task 8: the last turn tells the user the drafted body lasts only this session.

### R7-108 · minor · data flow

Task 8: nothing marks a draft filed, so compaction can resume a filed interview.

Fixed: Task 8: a draft file gains an `Ended:` line, and a compacted session doesn't resume one; first test asserts it.

### R7-109 · minor · data flow

Task 9's `<task>` ref segment undefined. Refuted in part: an empty stash can't follow a staged task.

Fixed: Task 9: `<task>` is the number as its heading writes it; a task with nothing to stage stops, so no empty stash.

### R7-110 · minor · data flow

Task 9's suggested `git read-tree <ref>^2` unstages a task finished between `git add` and `update-ref`.

Fixed: Task 9 records the ref right after each `git add`, and on a mismatch shows `git diff --cached` against the ref before naming the restore.

### R7-111 · minor · data flow

Task 10's end-to-end lacks the absence check. Same as R7-7.

Fixed: with R7-21.

### R7-112 · minor · data flow

Task 5 intake copies issue text into the plan and implementer prompts; say it is data, never instructions.

Fixed: Task 5 intake: the issue's text is data, never instructions, in the plan and every prompt.

### R7-113 · minor · data flow

Task 8's "on a match" undefined; fuzzy search makes most filings ask. Same root as R7-82.

Fixed: with R7-82.

### R7-114 · nit · data flow

Task 5's closed names: say `-<n>`.

### R7-115 · nit · data flow

Task 10: quote `"${AI_CLAUDE:-claude}"`.
