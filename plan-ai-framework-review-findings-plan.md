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
