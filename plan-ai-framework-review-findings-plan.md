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

## Round 8

Lenses: scope, clarify, data flow, test matrix, consistency, work context. Opus reviewers and verifiers;
scoped to Tasks 8–10 (user decision after round 7).

### R8-1 · blocking · clarify

Task 9's toy run names the suite `sh test/run.sh`, but the initial commit holds only `README` and `old.txt` and no task
adds `test/run.sh`: the baseline exits 127 as a red baseline before task 1.

Fixed: Task 9's toy run commits `test/run.sh` (runs each `test/*/test_*.sh`, non-zero on the first failure); task 2's test in `test/b/`.

### R8-2 · blocking · clarify

Task 8's missing-CLI test needs `command -v glab` failing, but Task 2b's `glab` shim is first on `PATH` in Claude's
shell, so it always succeeds.

Fixed: Task 8's *One rule per group* test checks `glab --version` exits 127, naming the shim.

### R8-3 · major · scope

Task 8's search and `label list` lack the `-R` the create passes with several remotes; gh picks `upstream` or fails,
so the duplicate check is skipped or checks the wrong repo and labels come from the wrong repo; untested.

Fixed: Task 8 § *The guard decides*: one target rule for every gh and glab call (no `-R` with one remote, origin's with
several), all calls from the repo's root; the search names it; the multi-remote tests assert it on search, `label list` and create.

### R8-4 · major · scope

Task 8: company-elsewhere and customer repos on hosts neither CLI files on (Azure DevOps, Bitbucket) and Jira get a
drafted `!` line specified only as `gh` or `glab`; an executor emits `! gh issue create -R dev.azure.com/…`.

Fixed: Task 8 § *Filing*: a target neither CLI files on gets the title and body only, no command; a Bitbucket test, and
the Jira test asserts no `!` line.

### R8-5 · major · clarify

Task 8's search and `label list` lack the create's `-R` with a second remote; gh prefers `upstream`. Same defect as R8-3.

Fixed: with R8-3.

### R8-6 · major · clarify

Task 8 never names the body file; the likely guess `issue-draft-<n>.md` holds the interview answers and would be published.

Fixed: Task 8 § *Filing*: the body alone goes to `<scratchpad>/issue-body-<n>.md`, never the draft file;
the first test asserts `--body-file` names it.

### R8-7 · major · clarify

Task 8 double-quotes `--title "…"` with only `; | &`, backticks and `$(` banned: `$DOTFILES` expands, the filed title
differs from the heading, and the lookup fails.

Fixed: Task 8: every title in a command (search, create, `!` line) single-quoted with `'\''`, as for `ai plan`; the lookup
clause says so; the *Shell characters* test adds `$HOME isn't "expanded"`.

### R8-8 · major · clarify

Task 9: whether a retry starts from the failed attempt's tree or reverts first is unsaid; a revert on a resumed run
discards the leftovers the user left for that task.

Fixed: Task 9 § *Models*: each new attempt starts from the failed one's tree, told what failed; nothing is reverted.

### R8-9 · major · data flow

Task 8's search and `label list` lack origin's `-R` with several remotes: an upstream match offers a comment on the
wrong repo, upstream labels fail the create; the multi-remote test checks only the create. Same defect as R8-3.

Fixed: with R8-3.

### R8-10 · major · data flow

Task 8's titles sit in `--title "…"`, so `$PATH` expands and `"` ends the argument; the altered title never matches the
heading. Same defect as R8-7.

Fixed: with R8-7.

### R8-11 · major · data flow

Task 9's listing: exclude pathspecs resolve against the cwd, so from a subdirectory the plan file shows as untracked:
a fresh start refuses, a checkpoint stops; Task 5 requirement 9 inherits it.

Fixed: Task 9 § *The listing* uses `:(top,glob,exclude)`; the toy run is rerun from `test/` to the same end state.

### R8-12 · major · data flow

Task 9 runs the baseline after the branch and `Base:` exist: a red baseline leaves both, the rerun takes the resume
path and skips the baseline, and a user's test-fix commit joins the plan's range.

Fixed: Task 9's steps: baseline is step 3, before the branch (now step 4); the red-baseline test asserts no branch and no `Base:`.

### R8-13 · major · test matrix

Task 9 resume after an interrupt during task 1 (branch and `Base:`, no task ✅ DONE, no ref): "the ✅ DONE task that
comes last" is undefined; untested.

Fixed: Task 9 step 1: the last checkpoint is the last task with a ref, `HEAD^{tree}` with none; a resume variant seeded
with only the branch and `Base:`.

### R8-14 · major · test matrix

Task 9: "a task with nothing to stage stops the run" has no test; an implementer reporting success with no change gets ✅ DONE.

Fixed: Task 9 *Nothing to stage* test: told to change nothing → stops naming the task, nothing staged, row not ✅ DONE.

### R8-15 · major · test matrix

Task 9: of the three parallel-dispatch conditions, disjoint Files lists is untested.

Fixed: Task 9 *Overlapping Files* test: both tasks naming `README`, no interface → separate messages.

### R8-16 · major · test matrix

Task 8's draft-file lifecycle is untested: resume from the highest `<n>` unless `Ended:`, a new session starting over,
`Ended: drafted` and `Ended: not filed`; `/compact` can force compaction.

Fixed: Task 8's Interview test adds `/compact` and a new session; the Search match test asserts `Ended: not filed`, the
won't-work-on test `Ended: drafted`.

### R8-17 · major · consistency

Task 8's search and label reads lack the create's target rule with two remotes. Same defect as R8-3.

Fixed: with R8-3.

### R8-18 · major · work context

Task 8's search and `gh label list` run without `-R`; in a fork whose upstream is a customer's or third party's repo, an
upstream match drafts a comment on someone else's tracker. Same defect as R8-3.

Fixed: with R8-3.

### R8-19 · major · work context

Task 8 never says how the customer-tree root is found for `## Issues` or the marker; a guessed shared parent (`~/code`)
lets the guard allow `issue create` on every customer's repos there.

Fixed: Task 8 § *A `## Issues` section*: the root is the user's answer, never inferred; `$HOME` or a directory holding
another owner's repos is refused; the customer-tree test names `$HOME` first.

### R8-20 · major · work context

Task 8: "the level's bar on content" and the red flag "a public issue naming a customer" have no test that can fail;
`grep -Fxf` catches only verbatim lines.

Fixed: Task 8 *Content bar* test: an item naming `example--client` and `git.example.com` → the body file holds neither.

### R8-21 · major · work context

Task 8's Lookup test has the tester create `andrelin/issue-lookup-scratch`, file two issues and delete it: platform
writes on the user's account with no ask; `gh repo delete` needs the `delete_repo` scope.

Fixed: Task 8's Lookup test hands each step to the user as a `!` line, each asked for, naming `gh auth refresh -s delete_repo`.

### R8-22 · minor · scope

Task 8's assignees "only from those the repo already uses": no requirement, no read named, no test.

Fixed: Task 8 § *Labels*: no assignee unless the user names one.

### R8-23 · minor · scope

Refuted: the Jira bullet only proposes the section the customer rule already writes, then drafts, as § *Not in this plan* allows.

### R8-24 · minor · scope

Refuted: the "comment there instead?" match only drafts a `!` line; no platform write is built.

### R8-25 · minor · scope

Task 8: whether Claude writes a company `## Issues` into the repo's committed `CLAUDE.md`, on which branch, and that it
is a change to commit, is unsaid.

Fixed: Task 8: at company level Claude prints the section for the user to add in a change of their own, never writing
it; the company-elsewhere test names the answer and asserts `git status` unchanged.

### R8-26 · minor · scope

Refuted: a missing glab returns no issue, so the item keeps `(issue to file)`, the failure test's outcome.

### R8-27 · minor · scope

Refuted: only `issue create` is named, and the guard allows nothing else at customer level.

### R8-28 · minor · scope

Task 9's first step folds in Task 5's edits; Task 9's Files and the File map omit the three SKILL.md files; no word on
Task 5/5b's rows; "run their tests" ambiguous.

Fixed: Task 9's first step names the runnable tests and the PARTIAL row; its Files and the File map rows add the three SKILL.md files.

### R8-29 · minor · scope

Task 9's suite is "the command the plan names", but Task 5's `writing-plans` edits never ask a plan to name it, or where.

Fixed: Task 9 step 3 reads it from § *Global constraints*; Task 5's still-to-make list adds that rule to `writing-plans`.

### R8-30 · minor · scope

`/implementing-plans` with no argument or a missing file: unspecified, untested.

Fixed: Task 9 § *Start*: either → stop, listing the root's `plan-*.md`; a Refusal case.

### R8-31 · minor · scope

Nothing stops `ai` running inside a Claude session, which nests an interactive claude; `CLAUDECODE` reaches Claude's shell.

Fixed: Task 10: `CLAUDECODE` set → message, exit 2, `claude` never run; a test.

### R8-32 · minor · scope

Task 5 stays 🚧 PARTIAL until Task 10, but Task 10 doesn't say to run Task 5's remaining real-run tests or update its row.

Fixed: Task 10's last test runs them (e2e steps 2 and 4 count) and flips Task 5's row; the order line says so.

### R8-33 · minor · clarify

Task 9: a task's "scoped tests" undefined. Refuted as major: each task carries a **Tests** section and the toy tasks
each add a test; the pinned-failure test behaves the same under either reading.

Fixed: Task 9: scoped tests are the tests each task's **Tests** section names.

### R8-34 · minor · clarify

Task 9's pinned-failure test has no reachable pass and no stated end. Refuted as major: its assertions are checkable
at the first return to the fix loop; only the final state is missing.

Fixed: Task 9 *Pinned failure* ends as in *Failing task*: stopped naming task 1, nothing staged.

### R8-35 · minor · clarify

Task 8: the search runs before or after the last "anything to change?" turn is unsaid.

Fixed: Task 8 § *Search before filing*: ahead of the last turn, so a match is shown there.

### R8-36 · minor · clarify

Task 8's "*Proposed direction* (marked optional)": a heading labelled "(optional)" or an omittable section.

Fixed: Task 8 § *The issue's shape*: `##` headings named exactly so, *Proposed direction*'s first line `Optional:`; the first test asserts it.

### R8-37 · minor · clarify

Task 8's code-reference format and commit are unsaid; a local unpushed SHA in a public issue points nowhere.

Fixed: Task 8: path plus line at a commit origin has (`git branch -r --contains`); the first test checks it.

### R8-38 · minor · clarify

Task 8: what `**Tracker:** none` does is unsaid.

Fixed: Task 8 § *The guard decides*: `none` drafts, like any tracker not this repo's own.

### R8-39 · minor · clarify

Task 8: a company-elsewhere answer written into the committed `CLAUDE.md` or not; the tester's answer not given. Same defect as R8-25.

Fixed: with R8-25.

### R8-40 · minor · clarify

Task 8's lookup clause: legacy `(issue to file)` items without `Target:` are unhandled.

Fixed: Task 8's `maintaining-follow-up-trackers` clause: an item with no `Target:` is listed for the user, unchanged.

### R8-41 · minor · clarify

Task 8: no source for assignees. Same defect as R8-22.

Fixed: with R8-22.

### R8-42 · minor · clarify

Task 8: the personal scratch repos' origin is unnamed; with none, `can-file-issue` prints `none` and drafts.

Fixed: Task 8's *Filing tests* bullet: a personal scratch repo's origin is `git@github.com:andrelin/x.git` unless named.

### R8-43 · minor · clarify

Refuted: later tests depend on "that first one", and every other test answers "don't file".

### R8-44 · minor · clarify

Task 8's No-tracker test contradicts "every scratch-repo test tree holds its own tracker".

Fixed: Task 8: every scratch-repo test tree bar *No tracker*'s.

### R8-45 · minor · clarify

Task 8's Interview test: the draft file "unchanged" since when.

Fixed: byte-identical to its content before the second request.

### R8-46 · minor · clarify

Task 9: `Base:` present, branch missing is undefined.

Fixed: Task 9 step 1: stop and ask; a resume variant.

### R8-47 · minor · clarify

Task 9: one task of a parallel batch fails: whether the passing one is staged and the run stops is unsaid.

Fixed: Task 9 § *Checkpoint*: a batch is staged only when every task passes; otherwise the run stops with it unstaged.

### R8-48 · minor · clarify

Task 9: a full model ID → alias; Task 5 requirement 2 has the rule, Task 9 doesn't cite it.

Fixed: Task 9 § *Models* passes the Agent tool's alias, citing Task 5 requirement 2.

### R8-49 · minor · clarify

Task 9's first step: which Task 5 tests cover the still-to-make edits. Same defect as R8-28.

Fixed: with R8-28.

### R8-50 · minor · clarify

`ai implement ""`: whether empties are dropped before or after validation is unsaid.

Fixed: Task 10: empty args are dropped first; `ai implement ""` and `ai review plan ""` in the exit-2 list.

### R8-51 · minor · clarify

Task 10's spike checks a bare `/writing-plans` only; whether arguments reach the skill is untested.

Fixed: Task 10's spike passes `tidy the tip numbering` in a scratch repo, checks the skill loaded and the reply is about it, then exits.

### R8-52 · minor · clarify

Task 10's e2e "moved to in-flight" assumes an in-flight half.

Fixed: the e2e's scratch tracker is the backlog / in-flight pair.

### R8-53 · minor · data flow

Task 8: nothing says the reads and create share a cwd; `can-file-issue [dir]` invites checking repo B while the create
runs in A. Refuted as major: the guard line already runs in the repo the issue is for.

Fixed: with R8-3: every call from that repo's root, `can-file-issue` with no `[dir]`.

### R8-54 · minor · data flow

Task 8: after a timed-out create, `Ended:` has no "unknown" value. Refuted as major: no item is written, the rest needs
a timeout plus compaction, and the search would surface the new issue.

Fixed: Task 8: `Ended: unknown <issues URL>` for a create whose outcome is unknown.

### R8-55 · minor · data flow

Task 8: a create failing because the repo doesn't exist still drafts a `!` line and an item whose `Target:` never resolves.

Fixed: Task 8 § *A failed create*: not found → say the target looks wrong and ask first; the filing tests answer "keep it", as does Task 10's e2e.

### R8-56 · minor · data flow

Task 8's lookup `--search "<title>"` is fuzzy and capped at 100; qualifiers in the title can exclude it.

Fixed: the lookup clause uses gh `--search 'in:title "<title>"'` and glab `--in title`.

### R8-57 · minor · data flow

Task 8: on the user-files path the user may change the title after the item was written; the lookup never matches.

Fixed: Task 8 § *Filing*: the user is told the lookup matches the title exactly, so a changed title means reporting the number.

### R8-58 · minor · data flow

Task 9: nothing catches a subagent's own git write at personal level: a self-staged path bypasses the leftovers check, a
commit moves HEAD. Refuted as major: every brief says "no git writes"; what remains needs explicit disobedience.

Fixed: Task 9 § *Checkpoint*: before staging, `HEAD` unchanged and the index tree the last checkpoint's, else stop; *Subagent git* test.

### R8-59 · minor · data flow

Task 9's `-z` listing reads ambiguously in the Bash tool (NULs render as spaces).

Fixed: the listing pipes through `tr '\0' '\n'`.

### R8-60 · minor · data flow

Task 9: `Base:` present but branch gone undefined. Same defect as R8-46.

Fixed: with R8-46.

### R8-61 · minor · data flow

Task 9: an interrupt between `update-ref` and the ✅ DONE edit makes the resume compare against the previous ref, and
the named `git read-tree <ref>^2` drops the finished task's index.

Fixed: Task 9 step 1: a task with a ref matching the index becomes ✅ DONE first; a resume variant.

### R8-62 · minor · data flow

Task 9: a full model ID or variant vs the Agent tool's aliases: mapping unstated. Same defect as R8-48.

Fixed: with R8-48.

### R8-63 · minor · data flow

Task 10: `implement` / `review plan` don't check the file exists; a typo launches a session.

Fixed: Task 10: a named plan file that isn't a file → `ai: no such plan file: <f>`, exit 2; tests run in a temp dir with `p.md`.

### R8-64 · minor · data flow

Refuted: the e2e is gated on `andrelin/x` being absent, and `andrelin` is the user's own account.

### R8-65 · minor · test matrix

Task 9: no refusal test has a staged stray file. Refuted as major: "any entry" is the full listing, defined apart from
leftovers; the test gap is real but cheap.

Fixed: Task 9 step 2 says "staged or not"; a Refusal case with a staged stray file.

### R8-66 · minor · test matrix

Task 9: the branch-naming rule has no exact test; the toy plan's filename is never given.

Fixed: the toy plan is `plan-toy.md`, the branch `toy`.

### R8-67 · minor · test matrix

Task 9: the exclude line is tested only from absent.

Fixed: the company/customer resume variant: once, also when it was there before.

### R8-68 · minor · test matrix

Task 9: a plan with `Base:` but no branch — no spec, no test. Same defect as R8-46.

Fixed: with R8-46.

### R8-69 · minor · test matrix

Task 9's pinned-failure test's terminal outcome is unnamed. Same defect as R8-34.

Fixed: with R8-34.

### R8-70 · minor · test matrix

Task 9: "any deviation inline" untested.

Fixed: Task 9 *Deviation* test: a spec editing `README`'s line 3 of one → stops; "append it" → a deviation line, spec unchanged.

### R8-71 · minor · test matrix

Task 8's first test: "every acceptance criterion" and "every code reference" pass vacuously with none.

Fixed: at least one of each, the item being about code here.

### R8-72 · minor · test matrix

Task 8: *Proposed direction*'s literal heading unstated. Same defect as R8-36.

Fixed: with R8-36.

### R8-73 · minor · test matrix

Task 8: no negative test for a search hit on a different problem.

Fixed: Task 8 *No match* case: the first one's title words, a different problem → no "comment there instead?".

### R8-74 · minor · test matrix

Task 8: "never passing `-R`" with one remote is never asserted.

Fixed: Task 8's company GitHub test: no `-R` on the create, search or `label list`.

### R8-75 · minor · test matrix

Task 8: the "file it before the session ends" warning and `--body-file` are untested.

Fixed: Task 8's won't-work-on test asserts both, the path existing.

### R8-76 · minor · test matrix

Task 8: customer level with the marker on `github.com` is untested.

Fixed: Task 8 *One rule per group*: a third repo `example--client/c` on github.com → an unblocked `gh issue create`.

### R8-77 · minor · test matrix

Task 8's chore test doesn't assert the `ai plan '<title>'` line.

Fixed: it does now.

### R8-78 · minor · test matrix

Task 10: "the stub's whole output, compared exactly" contradicts shorthand expectations (`ai issue` → `sonnet`).

Fixed: Task 10's Tests: an expectation naming model and prompt is the whole output; one naming one checks that line.

### R8-79 · minor · test matrix

Task 10: an empty arg in the middle is untested.

Fixed: `ai issue a "" b` → `/writing-issues a b`.

### R8-80 · minor · test matrix

Task 10: `ai implement ""` and `ai review plan ""` unspecified. Same defect as R8-50.

Fixed: with R8-50.

### R8-81 · minor · test matrix

Task 10: "empty variable counts as unset" tested only for `AI_MODEL_PLAN`, not the others or `AI_CLAUDE=`.

Fixed: tests for `AI_MODEL_ISSUE=`, `AI_MODEL_IMPLEMENT=`, `AI_MODEL_REVIEW=` and `AI_CLAUDE=`.

### R8-82 · minor · test matrix

Task 10: no test for the Files edits; its Tests omit `bin/check-md-limits` on the touched docs.

Fixed: Task 10 *Files edits* test: limits on the tip, `tips.md` and `README.md`, the ShellCheck entry, the README and tips lines.

### R8-83 · minor · test matrix

Task 10's spike names no observable evidence that the first turn loads the skill. Same defect as R8-51.

Fixed: with R8-51.

### R8-84 · minor · consistency

Task 9's first step says to run the pending edits' tests, which need Tasks 8–10; neither Task 9 nor 10 flips Task 5's
row. Refuted as major: the order line says Task 5's real-run tests wait for 10, and its e2e exercises intake and
completion. Same defect as R8-32.

Fixed: with R8-28 and R8-32.

### R8-85 · minor · consistency

Task 8's Lookup test runs in an origin-less scratch repo, but `maintaining-follow-up-trackers` step 1 fetches and
checks `HEAD == origin/main`. Refuted as major: step 1 doesn't say to abort; a test-setup fix.

Fixed: the Lookup repo's origin is a local bare clone.

### R8-86 · minor · consistency

Task 9's Files and the File map omit the SKILL.md files the first step edits. Same defect as R8-28.

Fixed: with R8-28.

### R8-87 · minor · consistency

Task 10 "produces nothing later tasks use", but 6b copies its defaults and Task 5's tests drive `ai`.

Fixed: Task 10's Interfaces name both, to change together.

### R8-88 · minor · consistency

Task 8's Interview test is the first `example--client` test but doesn't mention the where-issues-live question; "both answers" ambiguous.

Fixed: it is named the first, the where-issues-live exchange comes first, and "both interview answers".

### R8-89 · minor · consistency

Task 8's first test files an existing backlog item, but the body only says how to write a new item; a duplicate results.

Fixed: Task 8 § *Two questions*: an issue filed from an existing item numbers that item, never a second; the first test asserts it.

### R8-90 · minor · consistency

Task 8: compaction resume and new-session restart have no test. Same defect as R8-16.

Fixed: with R8-16.

### R8-91 · minor · consistency

Task 9: "the next task" on resume when the remaining tasks are a parallel batch.

Fixed: Task 9 step 1: leftovers inside the Files list of any task not ✅ DONE go to its implementer.

### R8-92 · nit · scope

Task 8's skill is about 88 dense lines plus a table against aim ≤ 100. Refuted as minor: a skill's hard cap is 150,
blank lines and headings free; past 100 is advisory.

### R8-93 · nit · scope

Task 9's automatic opus retry is an escalation no requirement asks for. Refuted as minor: it replaces SDD's own
escalation, a substitution, not new scope.

### R8-94 · nit · scope

Refuted: Task 10 already calls the README lines "the missing".

### R8-95 · nit · clarify

Task 8's `Ended:` value for a drafted comment, a failed create handed over, an unknown outcome. Refuted as minor: any
`Ended:` ends the resume; only the label differs. Same root as R8-54.

### R8-96 · nit · clarify

Task 8's marker flow: draft now or wait for the `touch`; a tree outside `$HOME`. Refuted as minor: the tests settle
draft now plus the `touch` line; outside `$HOME` costs a wasted touch.

### R8-97 · nit · clarify

Task 9: a run where every task is already ✅ DONE. Refuted as minor: none left falls through to the hand-over.

### R8-98 · nit · clarify

Task 9: how a shared build directory is detected. Refuted as minor: the test shows the signal is § *Global constraints* text.

### R8-99 · nit · clarify

Task 10: "whole output, compared exactly" vs `ai issue` → `sonnet`. Refuted as minor: both readings give a working
test. Same defect as R8-78.

### R8-100 · nit · clarify

Task 8: quoting of `ai plan owner/repo#n`.

### R8-101 · nit · clarify

Task 9: renumbering after `1.11` moves; `1.1`'s `should_trigger`.

### R8-102 · nit · clarify

Task 8 § *The guard decides*: nested asides.

### R8-103 · nit · clarify

Task 8: "in the second repo" in the *One rule per group* test.

### R8-104 · nit · clarify

Task 10: `--model=x` and `--help`.

### R8-105 · nit · clarify

Refuted: `recipes_optional` is alphabetical, so glab goes right after gh.

### R8-106 · nit · data flow

Task 8's duplicate search `--state open` misses a recently closed duplicate. Refuted as minor: the search offers a
comment on live work; no requirement asks for closed duplicates.

### R8-107 · nit · data flow

Task 8's drafted `gh issue comment` has no `--body-file`.

### R8-108 · nit · data flow

Task 9: a suite failure pinned to two tasks. Refuted as minor: both go back on the natural reading.

### R8-109 · nit · data flow

Task 9: appending to `info/exclude` assumes `.git/info/` exists. Refuted as minor: the default template makes it, and
a missing one fails loudly.

### R8-110 · nit · data flow

Task 10: whitespace-only and newline args unspecified.

### R8-111 · nit · test matrix

Task 9: a red baseline from suite `false` must list failing tests, but `false` names none. Refuted as minor: that test
only asserts a red-baseline stop; listing failing tests is tested by *Red baseline*.

### R8-112 · nit · test matrix

Task 9: "a `model` on every Agent call" passes with a wrong value. Refuted as minor: *Failing task* asserts the value.

### R8-113 · nit · test matrix

Task 9: `implementing-plans.json` has one positive query and no negatives. Refuted as minor: Task 7 extends it, and
the flipped `writing-plans` query acts as a negative.

### R8-114 · nit · test matrix

Task 9: the ref name from a heading like `2b` is untested.

### R8-115 · nit · test matrix

Task 8: the No-tracker, Unsure and Shell-characters tests name no origin. Refuted as minor: those are filing tests, so
the absence check aborts on a real repo.

### R8-116 · nit · test matrix

Task 8 and 10: "fails on the network" vs gh's `Could not resolve to a Repository`.

### R8-117 · nit · consistency

Task 5 requirement 9 cites "Task 9 § *The listing*", a bold bullet, not a section. Refuted as minor: a text search finds it at once.

### R8-118 · nit · consistency

Task 8: `**Tracker:** none` behaviour unstated. Refuted as minor: the guard line drafts for any tracker but this
repo's, `none` included. Same defect as R8-38.

### R8-119 · nit · consistency

Task 8's Files: the third `writing-follow-up-items` section is buried mid-paragraph.

### R8-120 · nit · consistency

Task 8's Lookup test: `#<n>` vs Task 5's `andrelin/dotfiles#<n>` in headings.

### R8-121 · nit · consistency

The order line's "each builds on the one before" is not true for 8 after 5b.

### R8-122 · nit · consistency

Refuted: Task 10 owns the README catch-up lines and the File map agrees.

### R8-123 · nit · consistency

Task 8's Interfaces omit Task 3's denial and Task 5's use of `ai plan '<title>'`.

### R8-124 · nit · work context

Task 10's spike runs in this public repo and may create a `plan-*.md` past the first turn. Refuted as minor: the spike
stops at the first turn; an untracked plan file publishes nothing.

### R8-125 · nit · work context

Task 8: `brew unlink glab` leaves glab unlinked on abort.

## Round 9

Lenses: scope, clarify, data flow, test matrix, consistency, work context. Opus reviewers and verifiers;
scoped to Tasks 8–10 (user decision after round 7).

### R9-1 · major · scope

Task 10's spike and end-to-end steps name no one to run them: they need an interactive session, `-p` is forbidden and
`ai` exits 2 under `CLAUDECODE`, so an agent executor unsets it, swaps in `claude -p`, or marks them run.

Fixed: Task 8 § *Tests*: "The user runs each one" — every interactive or fresh-session test in Tasks 8–10 and Task 5's real runs runs in the
user's terminal; the executor gives setup, prompt and answers,
then checks the transcript (`~/.claude/projects/…/<session id>.jsonl`) and named files.
Task 10's spike and e2e cite it.

### R9-2 · major · scope

Task 5's runnable-now tests (re-evaluation, verification, no plan, exclude, tests after fixes, tampering, whose work,
this plan's review to `Done (plan):`, the six untested behaviours) belong to no task, yet Task 10 flips Task 5's row
only when none is unrun: the row can never flip.

Fixed: Task 9's first step runs every test Task 5 lists as runnable now (this plan's review counting once it ends in `Done (plan):`);
Task 5's status lists name their owners (Task 9's first step, Task 10's end).

### R9-3 · major · scope

Task 9's description promises "any part of one", but the body takes only a plan file, and a fresh start has no rule
for rows already ✅ DONE; on a plan with done tasks executors differ.

Fixed: Task 9 *Start*: task numbers after the plan file limit the run, and a ✅ DONE task is skipped on any start; a *Part of a plan* test.

### R9-4 · major · scope

Task 9: no path for a task or test needing the user or a fresh session (spike stops, by-hand tasks, fresh-session
pressure tests, `!` lines): a subagent fails twice and retries on opus, or simulates a fresh session in its own context
and reports a pass.

Fixed: Task 9 body: *Work only the user or a fresh session can do* never goes to a subagent; the run stops for the user before that task's batch;
a *By hand* test.

### R9-5 · major · scope

Task 9 *Pinned failure*'s second case puts `test/test_pair.sh` outside the toy suite's `test/*/test_*.sh` glob: the
suite passes, so the pinned-to-none stop has no test that can fail.

Fixed: Task 9 *Pinned failure*: `test/pair/test_pair.sh`, committed per the new variant rule.

### R9-6 · major · clarify

Task 9's override list doesn't name SDD 7.0.0 SKILL.md:282 ("Never dispatch multiple implementation subagents in
parallel"); an executor serialises and the toy run's "both in one message" fails.

Fixed: Task 9 § *Overridden in SDD 7.0.0* names the parallel ban (SKILL.md:282), replaced by the batch rule.

### R9-7 · major · clarify

Task 9 *The listing*: `git status --porcelain -z | tr '\0' '\n'` prints a staged rename as `R  b.sh` plus a bare
`a.sh` line, a phantom leftover; Task 5's completion test runs `git mv a.sh b.sh` in this toy repo.

Fixed: Task 9 *The listing* adds `--no-renames`, saying why.

### R9-8 · major · clarify

Task 9 *Pinned failure*: `test/test_pair.sh` outside the toy glob, can't fail. Same defect as R9-5.

Fixed: with R9-5.

### R9-9 · major · clarify

Task 9: a shared build directory reads as "dispatch in parallel, serialise the tests" in the body, but the *Shared
build directory* test expects separate dispatch messages.

Fixed: Task 9 Technique: a shared build directory means one task at a time, matching the test.

### R9-10 · major · clarify

Task 10: the executor can't run the interactive spike and e2e and `ai` refuses under `CLAUDECODE`; who runs them and
with what evidence is unsaid. Same defect as R9-1.

Fixed: with R9-1.

### R9-11 · major · clarify

Task 8, Jira at customer level: the customer rule writes the user's answer into `<tree>/CLAUDE.md`, the Jira rule
only proposes a section; the test says "proposes", leaving different files on disk.

Fixed: Task 8 Jira bullet: its section is set up as for any tracker (written at customer level, printed at company);
the second Jira test expects `CLAUDE.md` holding **Tracker:** `ABC`.

### R9-12 · major · data flow

Task 9 *The listing* after `tr`: a staged rename's old path is a line of its own, a made-up leftover that stops the run.
Same defect as R9-7.

Fixed: with R9-7.

### R9-13 · major · data flow

Task 9: nothing clears stale `refs/checkpoints/<branch>/*`; a restarted run (branch and `Base:` deleted) gets the same
branch name, resume's "last checkpoint" picks the old ref and offers `git read-tree <stale>^2`.

Fixed: Task 9 step 2: a fresh start stops and asks when `refs/checkpoints/<branch>/` holds an earlier run's ref, naming `git update-ref -d`;
a Refusal case.

### R9-14 · major · test matrix

Task 9 *Pinned failure*: `test/test_pair.sh` never runs under `test/*/test_*.sh`. Same defect as R9-5.

Fixed: with R9-5.

### R9-15 · major · test matrix

Task 9: variant fixtures (the suite-source `CLAUDE.md`, `test/c/test_c.sh`, `.gitignore`, `test_pair.sh`) aren't said
to be committed; untracked, the clean-tree check stops first, so the red-baseline cases pass for the wrong reason and
"plan wins" fails.

Fixed: Task 9 Tests: *Every variant below* starts from a fresh toy repo, its fixture files in the initial commit, the plan untracked.

### R9-16 · major · test matrix

Task 9 toy run: "run once from `test/`" with `/implementing-plans plan-toy.md`; relative to the cwd the plan doesn't
exist, and the branch and `Base:` already exist from the first run.

Fixed: Task 9 *Start*: the plan file is root-relative whatever the cwd;
Task 10's check resolves it against `git rev-parse --show-toplevel` (the cwd outside a repo), with a subdirectory test;
the toy run's second run is in a fresh repo from `test/` with the same argument.

### R9-17 · major · test matrix

Task 9 toy run: `--name-status` "shows" six kinds of entry, not exactly these; the test files are unnamed, and a staged
`plan-toy.md` passes.

Fixed: Task 9 toy run names `test/a/test_a.sh` and `test/b/test_b.sh` and expects exactly six `--name-status` lines, in order.

### R9-18 · major · test matrix

Task 8: "an item with no `Target:` is listed, unchanged" is untested; the Lookup test has no such item.

Fixed: Task 8 Lookup test: a third item with no `Target:` → listed, unchanged, no call holding its title.

### R9-19 · major · test matrix

Task 8: refusing a tree root holding another owner's repos is untested; only `$HOME` is.

Fixed: Task 8 customer scratch tree test: `<other>`, holding a repo with origin `andrelin/p`, is refused before `<tree>`.

### R9-20 · major · test matrix

Task 8's second Jira case: whether `<tree>/CLAUDE.md` exists afterwards is unsaid. Same defect as R9-11.

Fixed: with R9-11.

### R9-21 · major · test matrix

Task 8 *Content bar*: only the body file is checked; a title naming the customer or host is published unchecked.

Fixed: Task 8 *Content bar*: the create's `--title` value is checked too.

### R9-22 · major · consistency

`ai` refuses under `CLAUDECODE`, yet Task 10's spike and e2e and Task 5's real runs need an interactive terminal, and
the only precedent (Handover, Task 5 status) is headless `claude -p` by the agent. Same defect as R9-1.

Fixed: with R9-1.

### R9-23 · major · consistency

Task 10 flips Task 5's row only once none of its tests is unrun, but most have no owner. Same defect as R9-2.

Fixed: with R9-2.

### R9-24 · major · consistency

Task 9 reads the suite from § *Global constraints*, but the `writing-plans` edit saying a plan names it there has no
wording, location or form, only a mention in Task 5's status line.

Fixed: Task 9's first step adds the `writing-plans` § *Structure* sentence (`Suite: <command>` or `Suite: none`);
the baseline reads the `Suite:` line; the toy plan holds `Suite: sh test/run.sh`; Task 5's "Still to make" names the form.

### R9-25 · major · consistency

Task 9 overrides SDD's fix-loop escalation but not its breaker (7.0.0 SKILL.md:411-429), which at round 5 parks open
findings and marks the task complete: the second attempt, opus retry and stop never trigger.

Fixed: Task 9 § *Overridden in SDD 7.0.0* names the breaker (:411-429): a task still failing at round 5 is a failed attempt.

### R9-26 · minor · scope

Task 8 Lookup: `! gh auth refresh -s delete_repo` is never narrowed again; the scope stays for good.

Fixed: Task 8 Lookup: `! gh auth refresh -r delete_repo` after the delete.

### R9-27 · minor · scope

Task 9: checkpoint refs are deleted only after the completion commit; an abandoned run or declined commit leaves them.
Same defect as R9-13.

Fixed: with R9-13.

### R9-28 · minor · scope

Task 10: `ai`'s plan-file check is cwd-relative but hand-off lines name a root-relative plan; from a subdirectory
`ai implement plan-x.md` exits 2. Same defect as R9-16.

Fixed: with R9-16.

### R9-29 · minor · scope

Task 10 Interfaces: "change both together" for the four defaults; no test catches `bin/ai` and `skill-trigger-eval`
drifting.

Fixed: Task 10 Interfaces: both files write each default `${AI_MODEL_<STAGE>:-<default>}`; `test/test_ai.sh` compares their `grep -o` output.

### R9-30 · minor · scope

Task 9 says Task 5's completion test runs after its toy run; Task 10 lists it as its own end work.
Refuted: "after", not "right after"; the order line rules out a conflict.

### R9-31 · minor · scope

Task 8's body likely exceeds the skill's 100-line aim (about 10,300 characters); nothing says what may move to a doc.

Fixed: Task 8 Files: past 100 lines, the command forms and target rule move to `claude/docs/issue-commands.md`; a File map row.

### R9-32 · minor · scope

Task 8: "Claude never writes" the company `## Issues` section is a restriction no requirement asks for.
Refuted: a deliberate narrower choice pinned by a test; writing it mid-issue puts an unrelated change in the user's tree.

### R9-33 · minor · clarify

Task 9 and 10: the plan argument resolves against the root or the cwd; from `test/` the skill stops and `ai` exits 2.
Refuted as major: cwd resolution matches Task 10's check and works with `../plan-toy.md`; only the test's argument is
unstated. Same defect as R9-16.

Fixed: with R9-16.

### R9-34 · minor · clarify

Task 9 baseline: no fixed form for the suite in § *Global constraints*; a guess runs `bin/check-md-limits`.
Refuted as major: the fallback chain (plan, `CLAUDE.md`, ask) and the toy tests limit harm; only the form is missing.
Same defect as R9-24.

Fixed: with R9-24.

### R9-35 · minor · clarify

Task 8: whether a not-found search or `label list` triggers "target looks wrong" is unclear; the customer test
wrongly predicts a network failure.
Refuted as major: L2165 covers a failed search or label list (report, go ahead); only "on the network" is wrong.

Fixed: Task 8 customer test: the search and `label list` fail with `Could not resolve to a Repository`, not on the network.

### R9-36 · minor · clarify

Task 8: the code-reference format (permalink or `path:line @ sha`) is undefined, and in scratch repos
`git branch -r --contains` lists nothing, so the rule can't be met.
Refuted as major: the only checking test accepts any path, line and SHA, and origin/main satisfies it in real use.

Fixed: Task 8 *The issue's shape*: references are `<path>:<line> @ <short sha>`, `<path>` alone when origin has no such commit.

### R9-37 · minor · clarify

Task 8 lookup: a `"` in a title breaks `in:title "<title>"`; the *Shell characters* fixture has one.

Fixed: Task 8: a search string drops each `"` of the title (Files clause, shell-characters bullet); Lookup test `Say "hi"` → `in:title "Say hi"`.

### R9-38 · minor · clarify

Task 8: where `Target:` sits in an item is unsaid.

Fixed: Task 8 Files: `Target:` is its own line right below the heading.

### R9-39 · minor · clarify

Task 8: the `Ended:` value after a "comment there instead?" yes, or after a failed create plus `!` line, is undefined.

Fixed: Task 8: `Ended: drafted` also after a drafted comment or a failed create's `!` line; the *Search match* yes case expects it.

### R9-40 · minor · clarify

Task 8: the drafted comment's body file and glab form are unsaid.

Fixed: Task 8 *Search before filing*: the comment goes to `issue-body-<n>.md`,
drafted as `gh issue comment … --body-file` or `glab issue note … --message`; the test expects `--body-file`.

### R9-41 · minor · clarify

Task 8: the `!` line's target when the repo has no `origin` remote is undefined.

Fixed: Task 8 target rule: several remotes and no `origin` → ask; no remote → title and body only, no `Target:`; a *No remote* test.

### R9-42 · minor · clarify

Task 8: whether a `**Tracker:**` naming the current repo counts as "this repo's own issues" is unclear.

Fixed: Task 8 guard paragraph: this repo's own issues are `each repo's own` or a `host/owner/repo` naming its origin.

### R9-43 · minor · clarify

Task 8: how deep the other-owner scan of a proposed tree root goes is unsaid, and untested.

Fixed: Task 8: the refused root is one that is, or whose direct subdirectories are, a repo naming another owner; tested with R9-19.

### R9-44 · minor · clarify

Task 8 search: when to "ask the user for the tracker" instead of searching is unsaid.

Fixed: Task 8 search: on Jira, Azure DevOps or Bitbucket, no search; ask whether the tracker already holds one.

### R9-45 · minor · clarify

Task 8: how far up from a personal repo the `00-follow-ups-*` tracker is looked for is unsaid.

Fixed: Task 8: the tracker is a `00-follow-ups-*` file in the repo's root or a directory above it, up to `$HOME`.

### R9-46 · minor · clarify

Task 8's body may pass the 150 cap at 150 characters a line; what may move to a doc is unsaid. Same defect as R9-31.

Fixed: with R9-31.

### R9-47 · minor · clarify

Task 9: whether a re-review gets the whole task diff or a fix-only diff (7.0.0 SKILL.md:396) is unsaid.

Fixed: Task 9 Technique: a re-review gets the whole task's input re-captured, never a fix-only diff.

### R9-48 · minor · clarify

Task 9: how an **Interfaces** dependency is decided from prose, and what the implementer's path report is for.

Fixed: Task 9 Technique: a dependency is an **Interfaces** naming the other task or a path in its Files list, unsure → in order;
the path report goes in the final report, the listing decides staging.

### R9-49 · minor · clarify

Task 9 toy run: capturing task 1's `--cached` diff mid-run inside a parallel batch has no defined moment.

Fixed: Task 9 toy run: task 1's cached diff at the end equals `git diff HEAD refs/checkpoints/toy/1^2 -- <task-1 files>`.

### R9-50 · minor · clarify

Task 9: no body rule that a deviation stops the run, only a red flag; the *Deviation* test expects a stop.

Fixed: Task 9 *Keep the plan in sync*: a flagged deviation stops the run, the batch unstaged, the ruling in that task's section.

### R9-51 · minor · clarify

Task 10: "empty args dropped first" — all of argv or only the prompt args?

Fixed: Task 10: empty arguments after the stage are dropped, an empty stage is unknown; tests `ai review "" code` and `ai "" plan 12`.

### R9-52 · minor · data flow

Task 8 lookup takes the one issue whose title equals the item's, `--state all`, with no author bound: a generic title
on another author's closed issue writes the wrong `#n`.
Refuted as major: needs an exactly equal title while the user's own isn't filed, and the wrong number shows in the heading.

Fixed: Task 8 lookup clause: gh adds `--author @me`, glab checks `author.username` against `glab api user`;
the Lookup and skill-edit tests check `--author @me`.

### R9-53 · minor · data flow

Task 8: "a network error" is definite but nothing maps error text; `EOF` or `connection reset` read as definite →
`!` line → duplicate.
Refuted as major: L2186 already classes a timeout or dropped connection as unknown, which covers the cited texts.

Fixed: Task 8 *A failed create*: only pre-send failures, a missing repo, disabled issues or a missing CLI are definite;
any other error is unknown.

### R9-54 · minor · data flow

Task 8: the duplicate search's `--state open` misses a closed regression.
Refuted: the search serves "comment there instead?" on open issues; a regression gets a new issue.

### R9-55 · minor · data flow

Task 8: `in:title "<title>"` breaks on a `"`, and the item silently keeps `(issue to file)`. Same defect as R9-37.

Fixed: with R9-37.

### R9-56 · minor · data flow

Task 8: `gh label list` returns 30 by default; a valid label past that is dropped silently.

Fixed: Task 8 *Labels*: `gh label list --limit 1000`, `glab label list --per-page 100`.

### R9-57 · minor · data flow

Task 8: `Ended:` is written only after filing; compaction between a successful create and that write resumes the
interview, which may create again.

Fixed: Task 8: the draft file gains `Ended: unknown <issues URL>` just before a create, replaced once it returns.

### R9-58 · minor · data flow

Task 9 resolves the plan against the root, Task 10's `-f` against the cwd. Same defect as R9-16.

Fixed: with R9-16.

### R9-59 · minor · data flow

Task 9 baseline: a suite in a Bash call hits the 2-minute default timeout; a long suite reports as a red baseline
with no failing tests.

Fixed: Task 9 baseline: every suite run uses `timeout: 600000`; a timeout stops as a timeout, never as failing tests.

### R9-60 · minor · data flow

Task 9: gitignored files are invisible to the listing (an implementer's `.env` is never caught), and untracked suite
artifacts stop every batch.

Fixed: Task 9 checkpoint: untracked paths a suite run creates and gitignored paths a batch created are never leftovers or staged,
and are named in the final report; a *Suite artifacts* test.

### R9-61 · minor · test matrix

Task 9 *Pinned failure*: "existing test" is undefined, so a fixer loosening task 1's own new test may pass.
Refuted as major: the test is task 1's spec, so loosening it is a deviation the review fails; only the term is undefined.

Fixed: Task 9 Technique: an existing test is any test in the tree when the subagent starts, its own task's included.

### R9-62 · minor · test matrix

Task 9 *Resume*: no variant with an unstaged edit to a ✅ DONE task's file.

Fixed: Task 9 *Resume*: an unstaged edit to `a.sh` (task 1, ✅ DONE) → it stops naming it.

### R9-63 · minor · test matrix

Task 9 *Resume*: no ref plus a stray staged file → `git read-tree HEAD` is untested.

Fixed: Task 9 *Resume*: branch and `Base:` plus a staged stray file → it stops naming `git read-tree HEAD`.

### R9-64 · minor · test matrix

Task 9 toy run: the final message should hold exactly `ai review code plan-toy.md`.

Fixed: Task 9 toy run: the final message holds `ai review code plan-toy.md` exactly.

### R9-65 · minor · test matrix

Task 9: no assertions for no `sdd-workspace`/`task-brief`, no `isolation`, no `git add -A`, staging in plan order,
re-review via `re-review-prompt.md`, the opus retry naming what failed.

Fixed: Task 9 toy run asserts no `task-brief` or `sdd-workspace`, no `isolation`, no `git add -A`, `git add --` in plan order;
*Failing task* asserts re-review prompts and the opus prompt naming the failing test.

### R9-66 · minor · test matrix

Task 8 *Search match*: the request's wording is unnamed; a free-text search may miss the first issue.
Refuted as major: the first issue is the user's live pick; telling the tester to reuse its title words suffices.

Fixed: Task 8 *Search match*: the request reuses the first issue's title words.

### R9-67 · minor · test matrix

Task 8: the target rule covers one or several remotes, not zero. Refuted as major: L2181 gives title and body only for
a target neither CLI files on; only zero remotes is unstated. Same defect as R9-41.

Fixed: with R9-41.

### R9-68 · minor · test matrix

Task 8: the `Ended:` value after a "comment there instead?" yes. Same defect as R9-39.

Fixed: with R9-39.

### R9-69 · minor · test matrix

Task 8: "a timeout can't be forced" is doubtful; a non-routable host hangs.

Fixed: Task 8: the timed-out create is stated as an accepted gap, with no claim that it can't be forced.

### R9-70 · minor · test matrix

Task 8: no assertion for "no `--assignee`" or "no label create".

Fixed: Task 8 first test: no `--assignee` in the create, no `gh label create` in the transcript.

### R9-71 · minor · test matrix

Task 8: stripping a branch from the `ai plan` title is never exercised.

Fixed: Task 8 apostrophe test: an item `B2.3` with a 🐛 badge and branch `fix/cache` → `ai plan 'Fix the cache'`.

### R9-72 · minor · test matrix

Task 8: resuming "unless that file ends in `Ended:`" is untested.

Fixed: Task 8 won't-work-on test: `/compact` and "carry on" after `Ended: drafted` → no resumed interview.

### R9-73 · minor · test matrix

Task 8 Lookup's GitLab case runs before glab is installed and passes on command-not-found.
Refuted: the three asserts hold whether glab fails on the network or is missing.

### R9-74 · minor · test matrix

Task 8 *Shell characters*: no `&` in the input.

Fixed: Task 8 *Shell characters*: the title gains `& c`.

### R9-75 · minor · test matrix

Task 8: the failed-create tests don't assert the drafted `!` line.

Fixed: Task 8: the sync-script and company-GitLab tests expect the drafted `!` lines.

### R9-76 · minor · test matrix

Task 8: the `writing-follow-up-items` and `maintaining-follow-up-trackers` edits are checked only by check-md-limits.

Fixed: Task 8 Tests: a *Follow-up skill edits* `grep -cF` check per edited skill.

### R9-77 · minor · test matrix

Task 10: `ai review "" code` and `ai "" plan 12` are untested. Same defect as R9-51.

Fixed: with R9-51.

### R9-78 · minor · test matrix

Task 10: the `CLAUDECODE` message isn't compared exactly, and a set-but-empty `CLAUDECODE=` is undefined.

Fixed: Task 10: `CLAUDECODE` set, even empty, refuses; the test compares the message exactly for `=1` and `=`.

### R9-79 · minor · test matrix

Task 10: `ai implement .` (a directory) is untested.

Fixed: Task 10 test: `ai implement .` → `ai: no such plan file: .`.

### R9-80 · minor · test matrix

Task 10: exit-status pass-through through `exec` is untested.

Fixed: Task 10 test: a stub exiting 3 → `ai` exits 3.

### R9-81 · minor · test matrix

Task 10: the new tip's content is untested (the README is).

Fixed: Task 10 *Files edits* test: the tip file holds `export AI_MODEL_PLAN=` once and `ai plan`.

### R9-82 · minor · test matrix

Task 10: no test links the two copies of the four defaults. Same defect as R9-29.

Fixed: with R9-29.

### R9-83 · minor · test matrix

Task 10 e2e: the repo has no suite, so step 3 asks the suite question with no scripted answer.

Fixed: Task 10 e2e: the initial commit holds Task 9's `test/run.sh` and a `CLAUDE.md` naming `sh test/run.sh`.

### R9-84 · minor · consistency

Task 9: with `sdd-workspace` and `task-brief` dropped, where briefs, reports and deferred minors go is unsaid
(SDD 7.0.0 :136-139, :361, :473-480); minors may be dropped.

Fixed: Task 9 § *Overridden in SDD 7.0.0*: briefs, reports and review packages go to `<scratchpad>/impl-<task>-*.md`,
deferred minors to a `Deferred:` line the final report lists (:136-139, :361, :473-480).

### R9-85 · minor · consistency

Task 9 *Save points* runs `git stash` and restores only the index, leaving the toy tree reverted; Task 10 then runs
Task 5's completion tests in that repo, which stop for a setup reason.

Fixed: Task 9 *Save points* runs in a `cp -R` copy of the toy repo.

### R9-86 · minor · consistency

Task 5 requirement 4's pathspecs lack `top` though said to be "the same" as Task 9's; the built
`claude/skills/reviewing-in-rounds/SKILL.md:34` lacks it too.

Fixed: Task 5 requirement 4 gains `top`; Task 9's first step and Task 5's "Still to make" add it to `reviewing-in-rounds/SKILL.md:34`.

### R9-87 · minor · consistency

Task 9 flips `writing-plans.json` `1.11` into a near-miss though 6b dropped near-miss 16 for that reason.
Refuted: 6b's status plans the flip, user-approved; the eval scores only the first Skill or Read call.

### R9-88 · minor · consistency

Task 8 deletes every scratch tree after its last test, but Task 5's intake test at Task 10's end needs the customer
tree and its apostrophe item.

Fixed: Task 8 keeps the customer scratch tree for Task 5's intake test; Task 10's end deletes it.

### R9-89 · minor · consistency

Task 10 e2e step 1 ("a function that doubles a number") may be judged a chore or unsure, and Task 5's size gate offers
to skip the plan; the tester's answers aren't scripted.

Fixed: Task 10 e2e scripts the answers: yes to the task tracker at step 1, the plan at step 2.

### R9-90 · minor · consistency

`CLAUDE_CODE_SUBAGENT_MODEL(_FORCE)` exported in a shell changes subagent models in every stage; no task owns it.
Refuted: `model` is passed explicitly on every dispatch, and leaving `_FORCE` unset is a recorded decision.

### R9-91 · minor · work context

Task 8's first pressure test files a real public issue from the gitignored, customer-naming backlog; checks run only
after filing, and `grep -Fxf` matches whole lines, so a rephrased customer name is published.
Refuted as major: a leak needs three guards to fail at once (the user's pick, the last turn's full view, the red flags).

Fixed: Task 8 first test: the user checks the item names no customer or customer host before naming it.

### R9-92 · minor · work context

Task 8: the last turn asks only "anything to change?" then files; § *Approvals* wants an explicit go-ahead.

Fixed: Task 8: the last turn asks "anything to change, or file it?" and files only on an explicit yes; the tests quote it.

### R9-93 · minor · work context

Task 8: `! gh auth refresh -s delete_repo` keeps the scope for good. Same defect as R9-26.

Fixed: with R9-26.

### R9-94 · minor · work context

Task 8: the tester answers `$HOME` to prove refusal; a regression writes `$HOME/CLAUDE.md`, which loads in every later
session and cleanup misses.

Fixed: Task 8 customer tree test: `$HOME/CLAUDE.md` byte-identical before and after (or absent both times).

### R9-95 · minor · work context

Task 9's customer toy run uses `example-client/x`, a real account; use `example--client`.
Refuted: `example-client` stays for fixtures that never reach the network; Task 9's run is local git only.

### R9-96 · nit · scope

Task 10: extra arguments after the plan file are unspecified.

### R9-97 · nit · scope

Task 10's README catch-up lines are out of scope.
Refuted: they fix real README drift, per "docs ship with the change".

### R9-98 · nit · scope

Task 8 prints `ai plan`, which doesn't exist until Task 10.

### R9-99 · nit · clarify

Task 8: with glab unlinked, `can-file-issue` still prints glab: probe first or attempt the create?
Refuted as minor.

### R9-100 · nit · clarify

Task 9: do SDD's NEEDS_CONTEXT and DONE_WITH_CONCERNS count as "blocked"? Refuted as minor.

### R9-101 · nit · clarify

Task 9: `git add --` given matched leftovers or Files-list spans; gitignore check per span or per file.
Refuted as minor.

### R9-102 · nit · clarify

Task 9: listing the root's `plan-*.md` also lists review files. Refuted as minor.

### R9-103 · nit · clarify

Task 10: which argument is the plan file when more follow. Refuted as minor. Same defect as R9-96.

### R9-104 · nit · clarify

Task 10: `PATH=$emptydir` needs `bin/ai` to use builtins only before the exec; unstated. Refuted as minor.

### R9-105 · nit · clarify

Task 10 e2e baseline's "ask once" answer. Refuted as minor: the plan's suite command may not exist before its tasks
create it. Same defect as R9-83.

### R9-106 · nit · clarify

Task 8 Files: "beside gh (lines 45-48)".

### R9-107 · nit · clarify

Task 8: `<n>`'s start, and `<scratchpad>` in a session with none.

### R9-108 · nit · clarify

Task 8: `grep -Fxf`'s direction.

### R9-109 · nit · clarify

Task 9: the customer resume variant's origin is unnamed.

### R9-110 · nit · clarify

Task 8 *Tightening*: whether the fixture `CLAUDE.md` is committed.

### R9-111 · nit · clarify

Task 10: `--model=x` form.

### R9-112 · nit · clarify

Task 10: `CLAUDECODE=` empty. Same defect as R9-78.

### R9-113 · nit · clarify

Task 9: `1.11` removed when it becomes `2.11`?

### R9-114 · nit · data flow

Task 8: empty or failing `can-file-issue` or `level` output is undefined.
Refuted as minor: `can-file-issue` prints exactly gh, glab or none, and the guard decides the create itself.

### R9-115 · nit · data flow

Task 9: appending to `info/exclude` fails without `.git/info/`.
Refuted as minor: the default template creates it, and `--git-path` resolves to the common dir.

### R9-116 · nit · data flow

Task 8 and 10 fixtures fail as "repo not found", the tests still say network failure. Same defect as R9-35.

### R9-117 · nit · test matrix

Task 9 *Resume*: the seed doesn't say whether the session starts on `main` or `toy`.
Refuted as minor: both branches sit at the same commit; the outcome doesn't change.

### R9-118 · nit · test matrix

Task 9: the customer resume variant's origin is unnamed. Same defect as R9-109.

### R9-119 · nit · consistency

Task 5b is ✅ DONE while its requirement 1 waits on Task 9's first step; its "Still to make" is never cleared.
Refuted as minor: the row says the PR-number case is added in Task 9's first step.

### R9-120 · nit · consistency

Task 8's template double-quotes `ai plan "<title>"`.

### R9-121 · nit · consistency

Task 8: "this repo's own issues" vs the section's "each repo's own". Same defect as R9-42.

### R9-122 · nit · consistency

Task 5's status row "edits made" reads as done.

### R9-123 · nit · consistency

Task 8's Files entry mixes requirements into the file list.

### R9-124 · nit · consistency

Task 8: `example--client/x` is defined after its first use.

### R9-125 · nit · work context

Task 8 names the real `example-client` account's creation date.
Refuted: a public fact about a public account; no work-context bar covers it.
