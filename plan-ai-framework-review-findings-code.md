<!-- DOCTOC SKIP -->

# Review findings (code)

Leftovers before round 1: none

## Round 1

### R1-1 · minor · correctness and failure modes

claude/docs/session-end-save.md:21: Step 2 says to expand the `<stem>-review-findings-*.md` glob with `ls` or `git ls-files`.
Neither is safe. `git ls-files <glob>` (without `--others`) lists only tracked files, so it silently misses untracked
findings files. `ls` fails on a pattern that matches nothing, the same way `git add` does: zsh's nomatch prints 'no
matches found' and exits 1. This is the exact failure the sentence is meant to avoid. Scenario: Verified in a scratch
repo. Take a personal-level plan whose review files are untracked, which the next sentence says should be added. A
session end that follows the `git ls-files` option prints nothing for `plan-x-review-findings-*.md`, so the findings
files are never staged or pushed. A resume on another machine then lacks the review logs, and nothing reports it. Taking
the `ls` option when no findings file exists yet gives `(eval):1: no matches found`, exit 1. That breaks an `&&` chain
into the add and commit.
Refuted: Downgraded from major by the verifier. Partly refuted, so downgraded. The sentences after step 2 pair the tools
with the levels: personal adds untracked files (so `ls`), company adds only tracked ones (so `git ls-files`, which is
right there). A careful reader does not use `git ls-files` at personal level. An `ls` that matches nothing prints an
error the agent sees, so it is not silent loss. The files also stay on the local machine. What stands: the doc offers
the two tools as interchangeable, and in zsh a no-match `ls` exits 1 and breaks an `&&` chain. That is real but cheap to
fix.
Fixed: in round 1's fixes.

### R1-2 · minor · correctness and failure modes

claude/skills/reviewing-in-rounds/SKILL.md:96: The landing sequence is: Completion commits (with the plan never staged),
step 5 flips the plan's `Final code review` row, then `ai-log record`, then a `git rm` commit of the tracked plan
(writing-plans:124, staged-workflow.md:66, session-end-save.md:22). By then the tracked plan always has unstaged local
modifications, and `git rm` refuses a file with local modifications. No doc says to use `-f` or `--cached`, or to
discard the edits first. At personal level, every plan the session-end save commits becomes tracked and hits this.
Scenario: Verified: after `echo b >> plan-x.md` on a tracked plan, `git rm plan-x.md` exits 1 with 'error: the following
file has local modifications: plan-x.md (use --cached to keep the file, or -f to force removal)'. This run's Task 13
`git rm` commit hits this right after step 5's row flip.
Fixed: in round 1's fixes.

### R1-3 · minor · correctness and failure modes

claude/docs/session-end-save.md:22: `git rm` of the plan before the squash merge is now the only thing that keeps a
session-end-committed plan (and its review files) off `main`. That step lives only in writing-plans § Plans are
temporary (past its first 100 lines) and in two docs' prose. No workflow step owns it: reviewing-in-rounds' Completion,
implementing-plans and the landing rule do not name it. Scenario: Take a personal public repo and a plan that was
untracked until a session end committed it. An agent lands the branch per implementing-plans:133 ('lands by a
squash-merged PR') without re-reading writing-plans. The plan, its quotes of the user and its review logs are squashed
onto the published `main`.
Fixed: in round 1's fixes.

### R1-4 · minor · correctness and failure modes

bin/ai-log:149: `ai-log level`, which the session-end save now uses as its gate, treats any origin other than
github.com/andrelin, github.com/uptimeconsulting or a line in `$AI_LOG_DIR/allow` as customer. The allow file lives in
the log clone, so a machine without the clone treats every company Forgejo repo as customer. `level` does not run
`require_clone` and gives no hint why. Scenario: Company work on a Forgejo host (which the global CLAUDE.md expects) on
a machine where `~/.ai-framework-log` isn't cloned yet: `ai-log level` prints `customer`. The session end then commits
and pushes nothing, contrary to the user's standing 'Commit and push the branch' rule, and the report shows it only as
customer level.
Fixed: in round 1's fixes.

### R1-5 · minor · correctness and failure modes

bin/ai-log:474: `add_words` splits plan, heading and branch words with `tr -cs '[:alnum:]' '\n'`. On macOS
(multibyte-aware BSD tr), non-ASCII letters count as alnum. On Linux (GNU tr, byte-wise), they do not. So company-level
redaction terms differ by platform, and on Linux a non-ASCII word is split. A fragment is then redacted mid-word,
leaving the leading letter(s) in the stored text. Scenario: Linux, company level, a plan `plan-ørsta-kommune.md`: GNU tr
yields the term `rsta` and drops `ø`. An introspection saying 'Ørsta' is stored as 'Ø[repo]', while macOS stores
'[repo]'. The output differs across the two supported platforms, and part of the name leaks.
Fixed: in round 1's fixes.

### R1-6 · minor · correctness and failure modes

bin/ai-log:627: `add_remote_terms` adds the repo name and owner segments with `add_term ... 2 0`, which never skips
generic words. A repo whose name is a common workflow word turns every use of that word in the introspection into a
placeholder. The evidence the summary asks for is then garbled. Scenario: Personal repo `andrelin/review` (or `tasks`,
`plan`, `ai`): the note 'review rounds ran 3 times (review 3 rounds)' is stored as '[repo] rounds ran 3 times ([repo] 3
rounds)', and 'ai-log' becomes '[repo]-log'. That defeats Task 15d's cut-candidate reading.
Fixed: in round 1's fixes.

### R1-7 · minor · correctness and failure modes

bin/ai-log:784: `plan_key` hashes only the origin and the plan's basename. A later plan that reuses a basename
(writing-plans allows `plan-<slug>.md` with no issue number) continues the earlier plan's chain. Its window starts at
the old plan's last `window.end` rather than at its own first appearance. Record's 'this plan, every entry together'
summary, and so the introspection, sums the old plan's tokens, rounds and majors in. Scenario: `plan-login.md` lands and
is deleted. Months later a new `plan-login.md` is written in the same repo. Its first `ai-log record` shows 'windows:
N+1' and totals that include the old plan's numbers, and the introspection judges the framework on mixed data.
Fixed: in round 1's fixes.

### R1-8 · minor · correctness and failure modes

claude/rules/writing-code.md:13: Task 16's glob list still misses common extensions of the languages it adds: `.hpp`,
`.cc` and `.cxx` (C++), `.mjs`, `.cjs`, `.mts` and `.cts` (JS/TS), and `.razor` and `.cshtml` (C#). A rule glob that
never matches fails silently (claude/docs/rule-globs.md). This repeats the original C# report for those files. Scenario:
Opening `src/foo.cc` or `include/foo.hpp` in a C++ project that uses Google style, or `Pages/Index.razor` in a .NET
project, does not load writing-code.md. Its tests, formatter and proving-causes rules are absent with no sign.
Fixed: in round 1's fixes.

### R1-9 · minor · correctness and failure modes

bin/check-md-limits:110: Front matter is recognised only when every line is YAML-shaped with no blank line. Front matter
with a blank line (valid YAML) is not recognised, so its lines count toward the length cap. The old code marked any
leading `---`…`---` block as fenced. Now a `# comment` line inside such an unrecognised block counts as a free heading,
and every other line counts as body. Scenario: Verified: a rule whose `paths:` block has 40 globs and one blank line
after `paths:`, with a 25-line body, fails with 'is 68 lines, over the hard cap of 50'. Without the blank line it
passes, although Claude never sees the block either way.
Fixed: in round 1's fixes.

### R1-10 · nit · correctness and failure modes

claude/CLAUDE.md:76: The new example form `dotfiles#42` is not a reference GitHub or Forgejo autolinks: they take `#42`
in the same repo or `owner/repo#42`. Text Claude writes per this rule in PR bodies, issues and comments carries an
unlinked, ambiguous reference where the bare `#42` it forbids would have linked. Scenario: A PR body on
andrelin/dotfiles saying 'follows dotfiles#42 (shell startup time)' renders as plain text with no link to the issue and
no cross-reference on the issue's timeline.

### R1-11 · nit · correctness and failure modes

claude/docs/staged-workflow.md:9: The Plan row names the hand-over as `plan-<n>-<slug>.md`. writing-plans:25 also allows
`plan-<slug>.md` when there is no issue, which `bin/ai` and `implementing-plans` accept. Scenario: A reader changing
`bin/ai` from this doc could assume a plan always carries an issue number and parse for one, breaking issue-less plans.

### R1-12 · major · tests

test/test_ai_log.sh:776: Task 15b's Tests section puts its skill checks in test/test_ai_log.sh: the step is one list
item after the commit step, and `grep -c 'ai-log record <plan-file>'` on claude/skills/reviewing-in-rounds/SKILL.md
prints 1. The Files-edits block (lines 776-780) covers only the tip file, tips.md, README.md and shellcheck.yml. No test
checks reviewing-in-rounds/SKILL.md step 7 or the work-contexts.md approval text. The grep passes by hand today (prints
1). Scenario: A later edit to reviewing-in-rounds drops or duplicates step 7, or moves it before the commit step. The
suite stays green and CI's check-md-limits passes, so plans stop being logged, or get logged twice, with nothing
failing. This is a spec requirement with no test that can fail. Fix: add the two greps, plus an order check of step 7
after step 6, next to lines 778-780.
Fixed: in round 1's fixes.

### R1-13 · minor · tests

claude/docs/session-end-save.md:10: Task 17's Files-edits checks are not in the suite: `grep -c` on the doc for `ai-log level`,
`Work in progress: Tasks` and `ai-log record <plan-file>`, and on implementing-plans/SKILL.md for `session-end-save.md`.
Each passes today (counts 1, 2, 1 and 1). No committed test guards them. The plan does not mark them 'by the session'
the way the resume scenario is. Scenario: An edit removes the pointer to session-end-save.md from implementing-plans, or
rewords the doc so it names `work-context.sh level` instead of `ai-log level`. That reopens the gap where a customer
repo not yet in ~/.claude-customers gets committed and pushed, and nothing fails.
Fixed: in round 1's fixes.

### R1-14 · nit · tests

claude/rules/writing-code.md:13: Task 16's new globs (`**/*.cs`, `**/*.go` and the rest) are checked only by a one-off
headless `claude -p` run. No test in the suite asserts the rule's `paths:` list holds them. A cheap test could grep each
glob, or run a glob match over sample file names. Scenario: A later trim of the paths list (for example to keep the rule
under its 30-line aim) drops `**/*.cs`. The rule silently stops loading for C# again, which is the exact bug the user
reported, and the suite and CI stay green.
Refuted: Downgraded from minor by the verifier. Downgraded. The plan names a one-off headless `claude -p` load check as
this task's test, and it ran (Result, 2026-11-09), so no requirement is missed. The stated scenario, trimming `paths:`
to keep the rule under its 30-line aim, is undercut by this same diff: count_lines now leaves front matter out, so the
`paths:` list no longer counts toward the aim and there is no length reason to trim it. A glob grep would still be a
cheap guard, but it's an extra, not a gap.

### R1-15 · minor · tests

test/test_ai_log.sh:302: The exit-1 requirement is 'a given `<commit>` no newer than the window's start'. Only one case
tests it: a commit before the plan's first appearance with no earlier entry. Untested: a commit no newer than an earlier
entry's `window.end` (the `after` path), and the boundary of a commit whose time equals the start. The assertions also
check only `rc`, not the 'no newer' message, so the die at bin/ai-log:873 cannot be told apart from the other exit-1
paths. Scenario: With an earlier entry present, a regression that computes `start_ts` from the wrong entry, or flips `<`
to `<=`, would let a stale commit record an empty or overlapping window, or reject a valid one. The test still passes,
because C0 precedes first_app either way.
Fixed: in round 1's fixes.

### R1-16 · minor · tests

test/test_ai_log.sh:760: For an unlisted origin (example-org) and a non-allowlisted host's uptimeconsulting, the spec
says 'So does…' the listed-customer case: the same line, exit 0, nothing in AI_LOG_DIR changed, with and without
--dry-run. The tests assert only the output and rc of a plain `record`. There is no --dry-run run and no check that the
log clone's HEAD, status and files are unchanged. Only the listed-customer loop (lines 732-739) covers those. Scenario:
A regression where the allowlist gate prints the deferral line but still writes or commits (or a --dry-run that prints
the entry's JSON) for an unlisted customer repo would pass. That is the forbidden-write path this gate exists to block.
Fixed: in round 1's fixes.

### R1-17 · minor · tests

test/test_ai_log.sh:433: The bash-older-than-5 test is wrapped in an `if` that runs only when /bin/bash is below 5. On
Linux CI it is skipped silently, with no skip message, so the 'a bash older than 5 exits 2' deviation is enforced only
on a Mac. Scenario: A change that breaks the early version check (for example a bash-5-only construct parsed before the
check) passes CI on Ubuntu and is caught only if someone runs the suite on macOS.
Refuted: Dropped by the verifier. Refuted. .github/workflows/tests.yml has a matrix entry `name: macOS`, and its loop
`for t in test/test_*.sh` runs test_ai_log.sh there. The macOS runner's /bin/bash is 3.2, so the guarded block runs and
its assertions are enforced in CI on every push. The silent skip happens only on the Linux and WSL jobs, where no bash
below 5 exists to test.

### R1-18 · nit · tests

test/test_check_md_limits.sh:440: The thematic-break and unclosed-`---` tests cover a block with no headings. The diff
removed the old `$fenced{0..j}` marking of a leading `---` block. As a result, `# ...` lines inside a non-front-matter
`---…---` block now count as free headings, where they used to count. That behaviour change has no test either way. The
removed assertion 'a # line in front matter still counts' had guarded the old behaviour; its replacement is justified by
the spec, but nothing pins the new meaning. Scenario: A file opens with `---`, a blank line, then many `# x` lines and a
closing `---`. It used to be counted in full and now isn't. Neither the intended nor the accidental outcome is pinned,
so a further change to the splice/fence logic can shift counts unnoticed.
Refuted: Downgraded from minor by the verifier. Downgraded. The behaviour change is real: the removed block marked lines
0..j of any leading `---…---` block as fenced, and now a block with a blank line is not front matter, so `# x` lines in
it are free headings. But the new result is the correct one: such lines render as headings between thematic breaks,
which the checker already treats as free everywhere else. The failure scenario is a vague future drift on a rare file
shape, and no requirement covers it. A pinning test would be nice, not needed.

### R1-19 · nit · tests

test/test_check_md_limits.sh:432: 'the same lines as body still count' does not use the same lines. The front-matter
case uses `k$i: v` keys, while the body case pipes `# c` through sed into `- c`. The assertion therefore does not show
that the identical text is excluded only because of its position (already listed in Task 16's Deferred). Scenario: A
count_lines change that treats `kN: v`-shaped body lines as free (for example a YAML-looking-line exemption leaking
outside front matter) would not be caught by this pair.
Refuted: Dropped by the verifier. Already settled. Task 16's Deferred line records 'the body-vs-front-matter test uses
different lines', so it goes to Task 13's issue with the run's other open items. Re-filing it here only duplicates a
known, accepted item.

### R1-20 · nit · tests

bin/check-md-limits:232: The count_lines front-matter detection duplicates long_lines' (line 381), with one fewer regex
(no `^\s+[\w.-]+\s*:`, which `^\s+\S` subsumes). No test ties the two together, for example front matter with a quoted
key `"a b": v` or `'k': v` that both must accept (already listed in Task 16's Deferred). Scenario: If one copy is edited
and the other is not, a file could have its front matter exempt from line length but counted toward file length, or the
reverse, and no test would catch it.
Refuted: Dropped by the verifier. Already settled. Task 16's Deferred line records 'the front-matter test exists in both
count_lines and long_lines', so it goes to Task 13's issue. The dropped regex is subsumed by `^\s+\S`, as the finding
itself says, so the two copies accept the same lines today. Re-filing it only duplicates a known item.

### R1-21 · major · security and work context

bin/ai-log:308: At personal level, MCP tool names are stored verbatim in `tools` (both per session and in totals). That
holds even when the tool belongs to a plugin the allowlist hides. `rn_tool` only folds `mcp__*` at company level. Plugin
skills and agent types from a non-allowlisted plugin, by contrast, become `_other_plugin` at every level. Task 15 §
Framework (plan review R7-39) hides such plugins because "a machine-wide plugin can name a customer's tooling". Its MCP
tools reach the entry under the plugin's own name, which defeats that rule. The same goes for a user-scope MCP server
named for a customer. Scenario: A machine-wide plugin `acme-internal` from a customer marketplace exposes an MCP server.
A personal-repo session calls `mcp__plugin_acme-internal_jira__search`. `framework.plugins` hides it as `plugins_other: 1`,
but `sessions[].tools` and `totals.tools` store `mcp__plugin_acme-internal_jira__search`. `record` commits and pushes
that to the log repo, which by the 2026-11-05 decision must be "free of customer details". No test covers it:
test/test_ai_log.sh:131 asserts that the MCP name is kept at personal level.
Fixed: in round 1's fixes.

### R1-22 · minor · security and work context

bin/ai-log:1071: Nothing checks the finished entry JSON against the `~/.claude-customers` terms that `note` builds. The
free-text guard for `record` rests only on `okname` (a character class that allows `/ : @ .`) plus per-field folding. A
tool, skill, agent-type, model or slash-command name holding a customer term reaches the pushed entry unless its own
fold catches it. Running the existing term list over the entry, and refusing or warning on a hit, would catch it
mechanically. Today only the one-off real-data grep of Task 15 does that. Scenario: At personal level, the user invokes
a user-scope custom agent `acme-reviewer` (`subagent_type`), or a slash command `/acme-deploy` from a machine-local
command. `rn_agent` and `rn_skill` keep these names at personal level, so `agents: {"acme-reviewer/default": 1}` or
`skills: {"acme-deploy": 1}` is committed and pushed. `acme` is listed in `~/.claude-customers`, yet nothing in `record`
checks for it.
Fixed: in round 1's fixes.

### R1-23 · minor · security and work context

bin/ai-log:258: At company level, model ids are not narrowed: the agent `model` and `message.model` pass through
`okname`, which allows `:` and `/`. A cloud provider ARN or inference-profile id, with its account number and region,
would therefore be stored and pushed. The plan defers this, but it is a real path for a company identifier to reach the
entry. Scenario: A company session runs through Bedrock with Agent `model:
"arn:aws:bedrock:eu-north-1:123456789012:inference-profile/eu.anthropic.claude-opus"`.
`agents` stores `general-purpose/arn:aws:bedrock:eu-north-1:123456789012:...`, and the log repo receives the account id.
Fixed: in round 1's fixes.

### R1-24 · minor · security and work context

bin/ai-log:650: At company level, `note` finds the plan only as a `*.md` under the repo root whose basename hashes to
the entry's `plan_key`. When no file matches, the plan's file-name and heading words are silently not redacted, with no
warning and no refusal. This happens when the plan was moved, deleted, or given to `record` as an absolute path outside
the repo, or when `note` runs in another checkout of the repo. Task 15b requires those words to be redacted at company
level. Scenario: At company level, `record` was given `/Users/x/plans/plan-acme-migration.md`, a plan outside the repo
root. Later, `ai-log note <id>` receives an introspection that mentions "acme migration". `find "$root"` finds no file
hashing to `plan_key`, so `acme` and `migration` stay in `entries/<id>.md`, which is committed and pushed. Exit 0, with
no warning.
Fixed: in round 1's fixes.

### R1-25 · minor · security and work context

bin/ai-log:1027: At company level, `repo`, `plan` and `plan_key` are stored as unsalted 12-hex SHA-256 values of
guessable inputs (`repo` plus `owner/name`, or the plan's basename). Anyone who can read the log repo can confirm a
guessed engagement name offline, so the hash hides less than the plan's "names hashed" (R6-33) implies. A per-clone
secret salt, kept out of the log repo, would close this. Scenario: A reader of `andrelin/ai-framework-log` computes `h12
repo uptimeconsulting/acme-portal`
for a list of candidate client names and matches one entry's `repo`. That reveals which client the company entry is for.
Fixed: in round 1's fixes.

### R1-26 · minor · security and work context

claude/docs/session-end-save.md:140: On a personal public repo, step 2 adds even an untracked plan and its
review-findings files and then pushes the branch (step 5). The stated reason is that the plan "never reaches `main`". On
GitHub, though, a pushed branch and the PR's commit list stay world-readable after a squash merge and a branch delete.
The personal-public bar ("world-readable forever: no customer names, hostnames, internal tooling") therefore applies to
plan text and review logs that were never written to that bar. The doc neither says this nor asks for a check before the
push. Scenario: A plan in a personal public repo, untracked by design, quotes a machine-local path or the name of an
internal tool in its review findings. A session end runs `git add` on it, commits `Work in progress: Tasks 3`, and runs
`git push -u origin feature`. The text is public in the PR's commits after the squash merge, although the doc's reason
suggests it never leaves the branch.
Fixed: in round 1's fixes.

### R1-27 · nit · security and work context

bin/ai-log:153: The `allow` file that upgrades a non-GitHub company origin out of customer level is read from the log
clone, which `record` updates with `git pull --ff-only` from the remote. A line pushed to the log repo from another
machine therefore changes, on every machine, which repos are recorded and which get session-end commits and pushes
(`ai-log level`). That is intended, but it is not documented as a trust point: neither the tip nor session-end-save.md
says that a write to the log repo widens where commits and pushes happen. Scenario: A mistaken `allow` line
`git.example.com/client-org`, added on one machine and pushed, makes `ai-log level` print `company` for that customer's
repos on every machine after the next pull. That holds whenever work-context.sh also resolves them as company (not yet
listed in `~/.claude-customers`). Session ends there would then commit and push.

### R1-28 · major · plan conformance

test/test_ai_log.sh:776: Task 15b's Tests say they go "in `test/test_ai_log.sh`" and include *The skill*: the step is
one list item after the commit step, `grep -c 'ai-log record <plan-file>'` on
`claude/skills/reviewing-in-rounds/SKILL.md` prints 1, and `bin/check-md-limits` passes on the skill and on
`work-contexts.md`. The test file has none of these. Its § Files edits checks only the tip, `tips.md`, `README.md` and
the ShellCheck list. The global constraint also says every test goes in `test/test_*.sh`. Scenario: Suppose a later edit
drops or rewords step 7 of § Completion of a code review, or `work-contexts.md` grows past its cap. The suite still
passes, so the trigger that writes every plan's log entry and introspection can disappear with no failing test. That is
a requirement with no test that can fail. The step is correct today: I checked by hand that the count is 1, that it sits
at counted line 75, and that check-md-limits passes.
Refuted: Partly refuted, but the finding stands. The check-md-limits part is already enforced:
.github/workflows/markdown.yml runs `bin/check-md-limits --no-warn` over every .md file, and hooks/pre-commit runs it
too, so a cap overrun on the skill or on work-contexts.md would fail CI. The rest holds. Task 15b's Tests (plan line
3751) say "in `test/test_ai_log.sh`" and list *The skill*: the step is one list item after the commit step, and `grep -c 'ai-log record <plan-file>'`
on the skill prints 1. test/test_ai_log.sh:776-780 has only Task 15's Files-edits asserts. Nothing in it greps
reviewing-in-rounds/SKILL.md, so if the trigger step is dropped or reworded, no test fails. That is a requirement with
no test that can fail, which is major.
Fixed: in round 1's fixes.

### R1-29 · minor · plan conformance

claude/skills/implementing-plans/SKILL.md:101: The diff adds the bullet "A plan's `git mv` runs in the session: auto
mode blocks it in a subagent as destructive, so that can only copy." It came in commit 5b563f3. No task's Files list or
Change asks for it, and the plan never records it as a filed learning or a deviation. The Handover records only the
`writing-plans` learning (06f51fa) as riding on the branch. The wording is also unclear: "so that can only copy" has no
clear subject. Scenario: This is a change to a workflow skill that no task covers and the plan does not record. Plan
conformance needs every change outside a task to be recorded. Task 17's Files list governs the edits to
`implementing-plans`, and this line is not among them. A reader of the plan cannot tell where it came from, and Task
13's fold or issue will not carry it.
Fixed: in round 1's fixes.

### R1-30 · minor · plan conformance

claude/CLAUDE.md:76: The adopted § Approvals line uses `dotfiles#42 (shell startup time)` as its example. In this repo,
Issue #42 is a real, closed Dependabot PR titled "chore(deps): bump webpack-dev-server from 5.2.5 to 5.2.6 in /website". The
user asked for a neutral example that says where the issue lives and gives a short title. This one gives a title that is
wrong for the item it names. Scenario: Someone who follows the example, or checks it with `gh issue view 42`, finds a
Dependabot PR whose title is not "shell startup time". So the example breaks its own rule (repo plus the item's real
short title), and in a published global file. Use a number that does not exist yet, or #42's real title.
Fixed: in round 1's fixes.

### R1-31 · minor · plan conformance

test/test_ai_log.sh:764: Task 15's customer-level tests say an origin `git@github.com:example-org/app.git` with no
`~/.claude-customers`, and `git.example.com/uptimeconsulting` without an `allow` line, "give the same" result as a
listed customer: the one line, exit 0, nothing in `AI_LOG_DIR` changed or committed, with and without `--dry-run`. For
those origins the test checks only stdout and exit code, only without `--dry-run`, and never checks that the log clone
is unchanged. The `git.example.com` origin is checked only through `ai-log level`, never through `record`. Scenario:
Suppose a regression in the origin allowlist gate made `record` commit an entry for an unlisted owner, or for another
host's uptimeconsulting, after printing the deferral line. These tests would still pass, and an unlisted customer repo,
which resolves as company, would have its counts pushed.
Fixed: in round 1's fixes.

### R1-32 · minor · plan conformance

claude/docs/session-end-save.md:1: Task 17's Tests (*Files edits*) name `grep -c` checks on the doc: at least 1 each for
`ai-log level`, `Work in progress: Tasks` and `ai-log record <plan-file>`. They also name one on the skill: 1 for
`session-end-save.md`. They add `bin/check-md-limits` on both. None of these is in any `test/test_*.sh`, although the
global constraint puts every test there. Task 16's rule-glob additions in `writing-code.md` likewise have no automated
check. Scenario: Suppose a later trim of the skill moves or drops the pointer to `session-end-save.md`, or moves it past
counted line 100 (it sits at 99–100 today), or rewords the doc's commit message. The suite stays green, so the
session-end save, the user's standing rule, silently stops being followed. I checked by hand that each grep holds today.
Refuted: Partly refuted. The check-md-limits checks on the doc and the skill are covered by CI (markdown.yml runs over
every .md) and by the pre-commit hook. The grep checks are not: at least 1 each in session-end-save.md, and 1 for
`session-end-save.md` in the skill. No test_*.sh file holds them, although the global constraint (plan line 44) says
every test goes in test/test_*.sh. A dropped pointer would leave the suite green. Task 17's Tests, unlike Task 15b's, do
not name a test file, and the result records them as run by the session, so this stays minor.
Fixed: in round 1's fixes.

### R1-33 · nit · plan conformance

claude/skills/implementing-plans/SKILL.md:386: The listing sentence was reworded from "so a staged rename is a `D` and
an `A`" to "so a rename is a `D` and an `A`". Task 9's spec (plan line 2780) says "a staged rename", and no task in this
run asks for this sentence to change. It is a drive-by reword made while trimming lines for the session-end paragraph.
Scenario: The meaning narrows slightly: `--no-renames` matters for a staged rename, since an unstaged one is already a
deletion plus an untracked file. The text has drifted from the plan's wording of the rule with no recorded deviation.

### R1-34 · major · the change as a whole

claude/skills/reviewing-in-rounds/SKILL.md:98: Step 7 runs `ai-log record` and the introspection only "once the commit
has run". Task 17 makes it possible for every task to be committed already by session-end commits, and then the final
review's Completion has nothing to commit. In that case the plan never gets its one introspection or its final entry.
The plan's requirement (Task 15 spec: "After every plan we should have a short introspection"; Task 15b: introspection
"once per plan after its final commit") assumed that the final review always commits. Task 17 broke that assumption, and
step 7 still rests on it. Scenario: A run limited to the plan's last tasks finishes them and prints a part-way report
that asks nothing. That counts as a session end, so the WIP commit takes every checkpointed task. The next `ai implement plan-x.md`
finds every task done and runs the final review. The review reaches Done with no fixes, so Completion steps 1-2 stage
nothing, no commit is offered or run, and step 7 never fires. session-end-save.md:31 told that session to skip the
introspection, so none is ever written. Steps 2-4 also don't say what an empty pathspec set means: offer an empty
commit, or skip.
Refuted: Not refuted. reviewing-in-rounds Completion step 1 stages only the paths the fixes changed. Step 7 fires only
'once the commit has run', and 'A declined commit records nothing'. session-end-save.md step 6 says to skip the
introspection because it 'comes once per plan after its final commit'. Take a plan whose tasks were all committed by
session-end commits, followed by a final review with no fixes: nothing is staged, no commit runs, and no step covers an
empty pathspec set. So the plan never gets the introspection Task 15/15b require (reviewed plan lines 3482, 3491). The
path is plausible: a run scoped to the last tasks ends part-way and the save commits them.
Fixed: in round 1's fixes.

### R1-35 · minor · the change as a whole

claude/docs/session-end-save.md:22: At personal level, the session end commits untracked plans and review-findings files
and pushes them. The stated reason, "never reaches `main`", reads as if that keeps them private. In a personal public
repo the pushed branch, and GitHub's PR refs after a squash merge, publish them for good. Nothing checks them against
the personal-public bar first: no customer names, hostnames or internal tooling. Plans in other personal repos have so
far been local only. Scenario: In a personal public repo, a plan's review findings quote a machine-local path or a
hostname from the session. At the first session end it is `git add`ed, committed and pushed to `origin/<branch>`. It is
world-readable at once, and it stays reachable through the PR's refs after the squash merge drops it from `main`.
Fixed: in round 1's fixes.

### R1-36 · minor · the change as a whole

claude/CLAUDE.md:76: The adopted line "Name issues and PRs with their repo and a short title: dotfiles#42 (...), never a
bare #42" conflicts with skills that still prescribe bare numbers. writing-mr-descriptions:34 says to match the repo's
`<type> #<n>: <subject>` or trailing `(#<n>)` title convention. writing-follow-up-items:80 gives `PR #412`, `issue #373`.
The repo CLAUDE.md:31 names the dashboard issue as "**#3**". Also, `dotfiles#42` is not GitHub autolink syntax (that
needs `owner/repo#42`), so following the rule in a PR body turns a working link into plain text. Scenario: A PR
description or a squash title written under writing-mr-descriptions follows the repo's `(#<n>)` convention and breaks
the global rule. Or it follows the global rule as `dotfiles#42` and the reference is no longer a link on GitHub.
Fixed: in round 1's fixes.

### R1-37 · minor · the change as a whole

claude/docs/session-end-save.md:24: The session-end commit runs the repo's pre-commit hook. In this repo the hook runs
doctoc, `markdownlint-cli2 --fix` and `git add` over every staged markdown file, plan files included. So the save can
rewrite the plan, adding a doctoc ToC since plans carry no `DOCTOC SKIP`, or fail on a lint error. The doc only handles
a failed commit by unstaging, so nothing is saved or pushed and another machine can't resume. Nothing in the doc or the
tests covers a hook on this path. Scenario: An untracked plan has a markdownlint error that `--fix` can't repair, or it
trips check-md-limits' 150-character line rule. At the session end the commit fails. Step 3 unstages the plan files and
stops. The checkpoints never reach origin, though the user asked for "Commit and push the branch".
Refuted: Partly refuted, but the finding stands. The plan in this repo carries '`<!-- DOCTOC SKIP -->`', so the 'adds a
doctoc ToC' scenario does not apply to it. The failure path is real, though. .git/hooks/pre-commit runs over every
tracked or staged .md outside claude/: it fails when the doctoc markers are missing, runs markdownlint --fix with a git
add, and runs bin/check-md-limits. A plan that fails any of these makes step 3 unstage and stop, so the push never
happens. The doc does report that failure, which keeps this minor.
Fixed: in round 1's fixes.

### R1-38 · minor · the change as a whole

claude/skills/writing-plans/SKILL.md:122: The tracked-plan delete is "a `git rm` commit on the branch". With Task 17,
every personal-level plan becomes tracked at its first session end. The final review then modifies the tracked plan (the
status-row flip, the review log) and never commits it, because Completion excludes plan-*. Plain `git rm` refuses a file
with local modifications, and no doc says to use `-f`, or to `git rm --cached` plus delete. Scenario: A personal plan
was committed by a session end. The final review appends its log and flips `Final code review`. The executor runs `git rm plan-x.md`
before the merge and gets "error: the following file has local modifications". It stops, or improvises a force that
loses the review log without the user deciding.
Fixed: in round 1's fixes.

### R1-39 · minor · the change as a whole

test/test_ai_log.sh:1: Nothing in the suite would fail if the wiring between the tasks broke. The Task 15b "The skill"
test (`grep -c 'ai-log record <plan-file>'` on reviewing-in-rounds prints 1) and the Task 17 file-edit greps (`ai-log level`,
`Work in progress: Tasks`, `session-end-save.md` in the skill) were one-off checks by the session. So a later edit could
drop step 7 or the session-end pointer, or push the pointer past counted line 100 (it sits at exactly 100 now), and CI
would stay green. Scenario: A trim of implementing-plans adds one line above § Finish. The session-end trigger and
pointer move to counted lines 100-101, past the first-100 rule that Task 16/17 require. Or a reword drops `ai-log record <plan-file>`
from step 7. The suite passes either way.
Fixed: in round 1's fixes.

### R1-40 · nit · the change as a whole

.github/workflows/markdown.yml:45: The CI comment says "A pin can only be removed by the file shrinking under its warn
line". Since Task 16, a skill's pin is also dropped because skills have no warn line. The comment is now stale, and the
plan's Task 17 test still says "the skill no more than its pin", a pin that no longer exists. Scenario: A maintainer
reading the baseline step after a skill pin disappears looks for a shrink that never happened.

### R1-41 · nit · the change as a whole

claude/docs/work-contexts.md:135: "the workflow skills never commit on their own, bar one exception" is followed
straight away by a second commit path: reviewing-in-rounds running `ai-log`, which commits and pushes to the log repo on
a standing yes. Strictly that is two exceptions, even though the second commits in another repo. Scenario: A reader
counting the exceptions as an allowlist finds two after being told there is one.

### R1-42 · minor · fit with the surrounding code

bin/ai-log:116: `normalize_origin` re-implements URL parsing that `claude/hooks/work-context.sh` already has as
`parse_url` (line 218), but without the guard's Azure DevOps handling (the `v3/` strip and the `ssh.dev.azure.com` /
`vs-ssh.visualstudio.com` to `dev.azure.com` mapping). The two copies have already drifted. Scenario: I ran the
function: a company repo with origin `git@ssh.dev.azure.com:v3/Org/Proj/Repo` normalises to
`ssh.dev.azure.com/v3/org/proj/repo`, so its host/owner is `ssh.dev.azure.com/v3`. An `allow` line `dev.azure.com/org`
(the form customers-file.md uses for Azure) never matches, so `record` treats the repo as customer and logs nothing. The
https clone of the same repo gives `dev.azure.com/org/...`, so it gets a different `<id>` and `plan_key`. That breaks
Task 15's requirement that ssh and https origins give the same id.
Fixed: in round 1's fixes.

### R1-43 · minor · fit with the surrounding code

bin/ai-log:524: `add_customer_line` is a second parser for `~/.claude-customers`, written by hand to follow the guard's
`customer_entry` / `load_customers` in work-context.sh. Only a comment ties the two together. The script has no shared
helper and no test that checks the two parsers classify a line the same way. Scenario: A new entry form added to the
guard's parser (customers-file.md is still changing) is matched by the guard but not by ai-log. A customer name written
in that form then survives `ai-log note` redaction and is pushed to the log repo.
Refuted: Dropped by the verifier. The failure scenario doesn't hold. add_customer_line's own contract
(bin/ai-log:524-525) is that a line matching none of the known forms "is a name, so it is redacted whole". If the guard
gains a new entry form that ai-log doesn't know, ai-log redacts that whole line, which over-redacts rather than letting
a customer name through to the log repo. The duplication is real, but no concrete failure follows from it.

### R1-44 · minor · fit with the surrounding code

claude/docs/staged-workflow.md:73: The doc says Done is "no `blocking` or `major` left", not "only nits", because
waiting for nits costs a round per minor fix. `reviewing-in-rounds/SKILL.md:70`, which the doc names as the rule's home,
also requires a code review's minors to be fixed before Done. Scenario: Someone changing the review loop reads
staged-workflow.md, as CLAUDE.md:22 tells them to. They conclude a code review can end with open minors and drop the
minor-fix requirement from the skill, or a reviewer stops a code round with minors unfixed.
Fixed: in round 1's fixes.

### R1-45 · minor · fit with the surrounding code

claude/rules/writing-code.md:13: The new globs cover `.c`, `.cpp` and `.h` but not the other common C/C++ and JS
extensions: `.cc`, `.hpp`, `.cxx`, `.mjs`, `.cjs`. Task 16's ruling was "C# plus the common languages", and a glob that
never matches fails silently (rule-globs.md). Scenario: Opening `foo.cc` or `foo.hpp` in a C++ project, or `x.mjs` in a
Node one, does not load the rule. That is the same silent miss the user reported for `.cs`.
Fixed: in round 1's fixes.

### R1-46 · nit · fit with the surrounding code

bin/ai-log:4: The header comment uses the plan's own vocabulary ("This slice stores counts only"), which narrates the
build history instead of describing the script. It also says no message text is stored, yet the same header describes
`note`, which writes the redacted introspection to `entries/<id>.md`. Scenario: After the plan is deleted, a reader has
no referent for "this slice". The "counts only" claim then contradicts `note` a few lines below.

### R1-47 · nit · fit with the surrounding code

claude/CLAUDE.md:74: The adopted bullet "Name issues and PRs with their repo and a short title" sits directly after the
Forgejo bullet, which still says "name the work by its issue and PR numbers". Two adjacent bullets now cover how to name
issues, and the Forgejo one reads as if a bare number is enough. Scenario: In this 75-line-capped file, someone reading
only the Forgejo bullet writes "#53". The one-line merge ("name the work by its issue and PR, per the next bullet") is
cheaper than keeping both.

### R1-48 · nit · fit with the surrounding code

claude/docs/staged-workflow.md:9: The stage table names the plan file `plan-<n>-<slug>.md`, but
`writing-plans/SKILL.md:25`, which defines it, uses `plan-<issue-number>-<slug>.md` or `plan-<slug>.md` with no issue.
The doc drops the no-issue form, and `<n>` doesn't say it is the issue number. Scenario: A reader of the why-doc assumes
every plan carries a number and writes `plan-1-foo.md` for an issue-less plan, which does not match the skill's naming.

### R1-49 · nit · fit with the surrounding code

claude/docs/session-end-save.md:3: The pointer cites `implementing-plans/SKILL.md` § *Finish*, but the section heading
is "Finish with the final review, in this run". Elsewhere the repo cites sections by their heading's leading words in
italics, which here would be "Finish with the final review"; the bare *Finish* reads as SDD's own § *Finish*, which that
skill lists as overridden. Scenario: A reader looks up "§ Finish" and lands on superpowers' overridden § Finish instead
of the skill's own section.

### R1-50 · minor · docs ship with the change

claude/CLAUDE.md:76: The adopted convention "Name issues and PRs with their repo and a short title … never a bare #42"
left in place the rules that still tell Claude to write bare numbers: writing-plans/SKILL.md:79 (`## Task 2 · #53: …` in
task headings), setting-up-follow-up-trackers/SKILL.md:44-47 (`PR #412` against `issue #373`) and
writing-follow-up-items/SKILL.md:48,80 ("shipped by #442", `PR #412`). None of them was updated or scoped as an
exception. Scenario: A session writing a plan task heading or a follow-up tracker item has two loaded instructions that
conflict: the global file says never a bare #N and the skill's template shows one. The output depends on which one wins,
which breaks the requirement that a changed convention updates every rule that states it.
Refuted: Downgraded from major by the verifier. Partly stands. The diff adds 'never a bare #42' to claude/CLAUDE.md:76
and removes '(#53, PR #112)' from the Forgejo bullet. Untouched templates still show bare numbers:
writing-plans/SKILL.md:79 '## Task 2 · #53: …', setting-up-follow-up-trackers/SKILL.md:44-47 'write `PR #412` against
`issue #373`' and writing-follow-up-items/SKILL.md:48,80. So two loaded instructions do conflict. Downgraded because the
outcome is a cheap style slip. The bare numbers are in-repo references inside a plan or tracker, so the repo is implied,
and the number still resolves. Nothing is lost or wrong.
Fixed: in round 1's fixes.

### R1-51 · major · docs ship with the change

claude/docs/skill-precedence.md:44-47: The new landing rule (a branch holding session-end commits lands by a
squash-merged PR, never a fast-forward) appears only in implementing-plans § Finish, session-end-save.md and
staged-workflow.md. It is missing from the docs read when a branch actually lands: skill-precedence.md's
`finishing-a-development-branch` row and company sentence, and reviewing-in-rounds § Completion, which runs the final
commits. Scenario: After the final review, a later session lands the branch with superpowers'
`finishing-a-development-branch` and picks 'merge back locally', which skill-precedence.md allows at personal level and
on a clean merge. The `Work in progress: Tasks …` commits and the per-task commits then reach main by fast-forward,
which is exactly what the rule forbids.
Fixed: in round 1's fixes.

### R1-52 · minor · docs ship with the change

claude/docs/work-contexts.md:85-91: The approvals paragraph names the session-end commit as the one exception but says
nothing about its push of the work branch. It also says `ai-log` runs only from `reviewing-in-rounds` after a plan's
commit, but session-end-save.md step 6 also runs `ai-log record`, which commits and pushes to the log repo, at every
session end. Scenario: A reader checking what the workflow writes without asking (the purpose of this section) concludes
that `implementing-plans` only commits locally and that the log repo is written once per plan. In fact every session end
pushes the branch to origin and pushes a log entry.
Fixed: in round 1's fixes.

### R1-53 · minor · docs ship with the change

tips/24_claude_code.md:88: Tip 24.5 still says "Nearing a cap is a note, not a failure". After Task 16 a skill has no
aim, so `check-md-limits` never prints a note for one: a 249-line SKILL.md is silent and 251 fails. Its "its first 100
lines hold all the task needs" also sits in the description's sentence and reads as being about the description. Both
were recorded as Deferred in Task 16 but are still unfixed in the diff. Scenario: A user reads the tip, expects an
advisory before a skill hits 250, gets none, and the first sign is a hard CI failure.
Fixed: in round 1's fixes.

### R1-54 · minor · docs ship with the change

claude/docs/markdown-limits.md:48: The doc says a skill's pin "is ignored and `--update-baseline` drops it".
bin/check-md-limits:513-516 keeps the pin for a skill over 250 (the SKIP branch), and the DROP message at :526 calls 250
the skill's "warn line", although the same doc says a skill has no warn point. Scenario: With a skill pinned in
.md-baseline and grown past 250, `--update-baseline` prints SKIP and keeps the pin, contradicting the doc. For a skill
under 250, the DROP message talks about a 'warn line of 250' that the docs say does not exist.
Fixed: in round 1's fixes.

### R1-55 · minor · docs ship with the change

tips.md:56: The tips index says `ai-log` "records how a plan fared, counts only", and README.md:82 describes it only as
recording counts. Since Task 15b, `ai-log note` also stores a redacted prose introspection in the private repo, and
`ai-log level` is a third subcommand. Neither entry mentions them. Scenario: A reader of the index or README believes no
prose leaves the machine, while `note` commits and pushes a redacted introspection to andrelin/ai-framework-log after
every plan.
Fixed: in round 1's fixes.

### R1-56 · minor · docs ship with the change

tips/25_ai_framework.md:18-25: Tip 25.1 does not mention that `ai-log` needs bash 5 and jq (bin/ai-log:29-33 exits 2 on
an older bash). It also presents `record` as run 'after the commit' only, although implementing-plans now runs it at
every session end too (session-end-save.md step 6), with the introspection skipped. Scenario: On a stock macOS shell
where `env bash` resolves to /bin/bash 3.2, `ai-log record plan-foo.md` exits 2 with a bash-version message the tip
never warned about. A reader also cannot tell why there are several entries per plan.
Fixed: in round 1's fixes.

### R1-57 · nit · docs ship with the change

bin/ai-log:2-6: The header comment says "This slice stores counts only … no prompt, question, message … text", but the
same script's `note` subcommand (described a few lines below) stores a redacted prose introspection. Scenario: A
maintainer reading the header assumes the log repo holds no prose and misjudges what the redaction code protects.

### R1-58 · nit · docs ship with the change

claude/docs/staged-workflow.md:64: "The branch lands by a squash-merged PR, never a fast-forward" is stated
unconditionally. session-end-save.md and implementing-plans say it holds for a branch with session-end commits, and
customer-level branches never get them. Separately, line 257 points to `work-contexts.md` for the redaction, but the
redaction details are in tip 25 and bin/ai-log, not in work-contexts.md. (The first point is in Task 13's Deferred
list.) Scenario: A reader of the why-doc concludes that every workflow branch, customer ones included, must land by
squash PR, which customer level forbids Claude to open.

### R1-59 · nit · docs ship with the change

claude/rules/markdown-limits.md:31: The rule still says "A file over its warn line can be pinned" and "Past the aim,
look for the seam" with no carve-out for skills, which now have neither an aim nor a pin. Scenario: A writer pins an
over-long SKILL.md as the rule suggests. The checker then ignores the pin without saying so.

## Round 2

### R2-1 · major · correctness and failure modes

test/test_workflow_docs.sh:1: The only test that guards Task 17's and Task 15b's skill and doc wording (the session-end
pointer within counted line 100, `ai-log record <plan-file>` appearing once, the landing rule, the `git rm -f`, the
writing-code.md globs and the ls-files pathspec) is untracked. It is in no task's Files list and the plan never mentions
it. Scenario: reviewing-in-rounds Completion step 1 stages only the leftovers that were not leftovers before round 1,
and a leftover from before then 'stays unstaged'. Step 2 builds its pathspecs from the Files lists. So the commit, and
then the squash-merged PR, can leave this file out. CI then has no test that fails if someone drops the session-end
pointer or the single record step. Tasks 17 and 15b's requirements would land with no test that can fail.
Fixed: in round 2's fixes.

### R2-2 · major · correctness and failure modes

claude/docs/session-end-save.md:285: The ls-files pathspecs `'<stem>.md' '<stem>-review-findings-*.md'` are relative to
the cwd, and so are the ones in § Landing (line 320). The plan sits at the repo root, and implementing-plans explicitly
supports running from a subdirectory ('the path from git rev-parse --show-toplevel whatever the cwd'). Scenario:
Reproduced in a scratch repo. With plan-x.md and plan-x-review-findings-code.md at the root and the session in `sub/`,
the step-2 command lists nothing. At personal level the session-end commit then silently leaves the plan out, so another
machine resumes without it. Worse, the Landing `git rm -f` pipeline removes nothing, so the tracked plan reaches the
default branch in the squash merge. Fix: use `':(top)<stem>.md'` and the same `:(top)` prefix on the findings pathspec,
or run the step from `git rev-parse --show-toplevel`.
Fixed: in round 2's fixes.

### R2-3 · minor · correctness and failure modes

claude/docs/session-end-save.md:320: The Landing pipeline `git ls-files -z … | xargs -0 git rm -f --` relies on the
prose 'skipped when that lists nothing'. As written it does not skip on Linux: GNU xargs runs its command once even when
the input is empty. The same applies to step 2's `xargs -0 git add --` (line 285). Scenario: On Ubuntu, WSL or RHEL,
with no tracked plan file, the pipeline runs `git rm -f --`. That fails with 'fatal: No pathspec was given' (exit 128),
and an agent that pastes the command reports a failed landing step. macOS xargs does not run on empty input, which I
verified here, so this only shows up off macOS. Using `xargs -0 -r` makes both platforms behave the same way. The `git add --`
case exits 0 with a hint, so it is harmless but noisy.
Fixed: in round 2's fixes.

### R2-4 · minor · correctness and failure modes

bin/ai-log:772: refuse_customer_terms tests every string and key in the entry against every ~/.claude-customers term as
a whole word. That includes free English warning text ('git pull in the log clone failed…'), lens headings ('The change
as a whole', 'Docs ship with the change') and model and tool names. A listed abbreviation that is also an ordinary
English word therefore blocks every record. Scenario: ~/.claude-customers lists a short abbreviation that equals a word
in a warning or lens heading (for example `docs`, or a two-letter one such as `in` or `as`). Every `ai-log record` then
exits 1 with 'nothing was written', at every session end and every Completion, for every plan. It is reported, but the
log stops filling until the user works out why. The check should cover only the name-carrying fields (tools, skills,
agents, models, plugins), not warnings or lens names, which the script itself controls.
Fixed: in round 2's fixes.

### R2-5 · minor · correctness and failure modes

test/test_workflow_docs.sh:91: The test does its scratch-repo writes with `git -C "$repo" init` and `git -C "$repo" add`.
The plan's Global constraints forbid exactly this for scratch repos in tests: 'git init in a Bash call of its own, then
literal paths, never `cd "$var"` or `git -C <path>` for a write', because the guard blocks some such writes. Scenario: A
session or verifier that runs this test's commands through the guarded Bash tool, as the constraint anticipates, can
have the `git -C` add blocked. It also departs from the convention every other test follows. It passes today only
because the guard sees `bash test/…`, not the inner commands.
Fixed: in round 2's fixes.

### R2-6 · minor · correctness and failure modes

test/test_workflow_docs.sh:36: counted_line treats any line starting with `#` as free and only skips front matter opened
by a bare `---`. bin/check-md-limits counts differently: a heading is `^ {0,3}#{1,6}(\s|$)` outside a fence, a `#` line
inside a fence counts, and front matter must look like YAML. Scenario: The pointer sits at counted lines 99–100, right
at the boundary. If a `#` comment line inside a code fence is added above it, the checker counts that line but this test
does not. The test then reports the pointer as within the first 100 lines when the checker's count puts it at 101, so
the guard on the 'everything needed in the first 100 lines' rule passes wrongly.
Fixed: in round 2's fixes.

### R2-7 · nit · correctness and failure modes

claude/CLAUDE.md:76: The adopted line ends 'titles and links keep theirs'. It does not say whose numbers those are or
which titles (commit, PR or issue) are meant. It also sits beside the Forgejo bullet, which still says 'name the work by
its issue and PR numbers'. Scenario: A reader cannot tell whether a commit message's `closes #12`, or a PR title, must
also become `repo#12 (title)`. Different sessions will apply the rule inconsistently. Naming the exempt cases explicitly
would fix it, for example: 'commit and PR titles and URLs keep the bare form'.

### R2-8 · nit · correctness and failure modes

claude/docs/work-contexts.md:471: This says `reviewing-in-rounds` and the save run `ai-log` 'at every level but
customer'. reviewing-in-rounds step 7 (SKILL.md:99) says the step runs 'at every level', and relies on `ai-log` printing
its deferral line at customer level. Scenario: An agent reading work-contexts.md at customer level skips step 7, while
one reading the skill runs it. The outcome is the same, since nothing is recorded either way, but the two docs disagree
on when the step runs.

### R2-9 · major · tests

test/test_workflow_docs.sh:1: The new doc-guard test is untracked (`??` in git status) while every other change is
staged, and no task's Files list names it. It holds the only checks on writing-code.md's new globs, the session-end
save's pathspec and `git rm -f` wording, and the landing rule in reviewing-in-rounds, implementing-plans and
skill-precedence. Scenario: The final commits stage the run's files and keep untracked ones out ("keeping the user's own
uncommitted edits out"), so test_workflow_docs.sh never reaches the PR or CI. Dropping a glob such as `**/*.cs` from
writing-code.md, or the `never a fast-forward` line from a skill, would then pass CI on main.
Refuted: Not refuted. `git status` shows `?? test/test_workflow_docs.sh` while every sibling change is staged, and a
grep of the reviewed plan finds no mention of test_workflow_docs.sh in any task's Files list. CI runs `for t in test/test_*.sh`,
so an untracked file never runs there. Its writing-code.md glob loop, the `git rm -f` and `never a fast-forward` greps
on reviewing-in-rounds, implementing-plans, skill-precedence and writing-plans, and the ls-files pathspec experiment
exist nowhere else in the suite. test_ai_log.sh covers only part of the session-end-save checks. A stage-only commit
(plan line 65: keep the user's own uncommitted edits out) would leave those requirements without a test that can fail.
Fixed: in round 2's fixes.

### R2-10 · minor · tests

test/test_workflow_docs.sh:86: The pathspec test runs its own copy of the `git ls-files ... | xargs -0 git add --`
command instead of the one in session-end-save.md, so it checks a literal it restates. Its only link to the doc is the
`--others --cached` substring count at line 48. Scenario: Change session-end-save.md step 2 to an unquoted glob, or drop
`--exclude-standard` or the quotes around `'<stem>-review-findings-*.md'`, and keep the substring `--others --cached`.
Both test_workflow_docs.sh and the suite still pass, while the doc's command now aborts under zsh when nothing matches,
or misses untracked plan files.
Fixed: in round 2's fixes.

### R2-11 · minor · tests

claude/docs/session-end-save.md:57: Nothing tests the landing step's `git ls-files -z -- ... | xargs -0 git rm -f --` or
its "skipped when that lists nothing". The same goes for step 3's failed-commit recovery and the company-level "drop
`--others`" variant of step 2. Task 17's resume scenario was run by hand once and is not in the suite. Scenario: With
GNU xargs on Linux, empty input still runs `git rm -f --` with no path, which exits 128. A later edit that drops the
skip clause, or a company-level save that keeps `--others` and pushes an excluded plan, would not fail any test.
Fixed: in round 2's fixes.

### R2-12 · nit · tests

test/test_check_md_limits.sh:442: The body-vs-front-matter pair uses different lines. The front-matter case uses `k$i: v`
keys, but the 'same lines as body' case uses `- c` list items. So the claim "the same lines as body still count" is not
what is tested. The plan's Task 16 Deferred line notes this but leaves it unfixed. Scenario: A count_lines regression
that skipped YAML-shaped `key: value` body lines (for example, front-matter detection that no longer requires the
opening `---`) would leave 'the same lines as body still count' green, because that case has no `key: value` lines.
Refuted: Downgraded from minor by the verifier. Downgraded. The mismatch is real: the front-matter case uses `kN: v`
keys and the 'same lines as body' case uses `- c` items, so the test name overclaims. The stated failure scenario is
mostly caught elsewhere, though. 'a lone leading --- with no closer is still counted' (120 `k: v` body lines, expects
NOTE) fails if count_lines skips `key: value` body lines. 'a blank line after the opening ---' covers detection that no
longer needs a well-formed opener. What is left is the test's name and pairing, which is wording.

### R2-13 · minor · tests

bin/ai-log (ERR trap); test/test_ai_log.sh:466: Exit 3 is tested only with a stub jq that fails before anything is
written. Two paths have no test: the ERR trap's after-write message, and a jq failure inside a `while ... < <(jq ...)`
loop, which the plan's Deferred line says does not reach exit 3. Scenario: If jq fails inside a process-substitution
loop during `record`, the loop sees an empty stream and an entry with missing counts is committed with exit 0. No
assertion can catch this.
Fixed: in round 2's fixes.

### R2-14 · nit · tests

test/test_ai_log.sh:1025: The same doc assertions are duplicated across test_ai_log.sh and test_workflow_docs.sh with
different strictness. For `ai-log level` in session-end-save.md, one requires exactly 1 occurrence and the other at
least 1 (the plan says at least 1). The two counted-line awks also define a heading differently (`^#` vs `^#+` followed by a space), and
both differ from check-md-limits, which counts `#` lines inside fences. Scenario: A second mention of `ai-log level` in
session-end-save.md fails test_ai_log.sh while test_workflow_docs.sh passes. If a fenced `# comment` sits before the
pointer, test_workflow_docs.sh can report the pointer within the first 100 counted lines while check-md-limits counts it
at 101.

### R2-15 · nit · tests

claude/skills/reviewing-in-rounds/SKILL.md:95: The new 'Nothing staged' branch (no commit offered) and step 7's 'or when
there was nothing to commit' are guarded only by phrase greps. No test checks that step 7 still comes after step 4 in
that case, or that the 'Nothing staged' line is in step 4. Scenario: Moving the 'Nothing staged' sentence out of step 4,
or rewording it, leaves every assertion green. The ord_of check only follows 'run it only on a yes' and 'After the
commit runs'.

### R2-16 · major · security and work context

claude/docs/session-end-save.md:24-34: On a personal public repo, the session-end save pushes every checkpointed task's
code before the final code review has run its Security and work context lens. Step 2's world-readable check covers only
the plan files, not the committed index. Before Task 17 nothing left the machine until the final review, which is the
only review that applies this lens (task reviews do not). So this moves publication ahead of the one check that enforces
the personal-public bar. Scenario: In a public repo such as andrelin/dotfiles, a task adds a test fixture with a real
hostname or a token-shaped string, and its task review (spec, tests, fit) passes. The user says "wrap up". The save
commits `Work in progress: Tasks 3` and runs `git push -u origin <branch>`. The final review later finds and fixes the
leak and the PR is squash-merged, but the WIP commit stays fetchable by sha from the pushed branch and from GitHub's
`refs/pull/N/head` indefinitely. That breaks the personal-public bar ("world-readable forever: no customer names,
hostnames, internal tooling, secrets"). A fix is to apply the step-2 bar to `git diff --cached <Base:>` too, or to skip
the push on a public repo until the final review.
Fixed: in round 2's fixes.

### R2-17 · minor · security and work context

bin/ai-log:351-356, 342-347, 348-350: At personal level, three kinds of name go into the pushed entry unchanged:
user-scope MCP server/tool names (`rn_tool` keeps any `mcp__<server>__…` that is not a plugin), custom agent types
(`rn_agent`) and unknown skill or slash-command names (`rn_skill`, class builtin). Machine-wide plugins are folded to
`other` because "a machine-wide plugin can name a customer's tooling" (plan review R7-39). A user-scope MCP server,
`~/.claude/agents/*` or `~/.claude/commands/*` is just as machine-wide, but none of them is folded. The only backstop is
`refuse_customer_terms`, which catches a name only once it is listed in `~/.claude-customers`. Scenario: The user has a
user-scope MCP server `acmecorp-jira`, configured for a customer engagement and loaded in every session, and its tools
are called during a session in a personal repo. `ai-log record` stores `tools: {"mcp__acmecorp-jira__search": 2}` and
pushes it to `andrelin/ai-framework-log`. This breaks the Task 15 decision that the log is "still free of customer
details". The refusal does not fire unless `~/.claude-customers` lists exactly that word (the run-together `acmecorp` is
a known gap).
Not fixed: Task 15's spec keeps names at personal level (plan review R6-33); the tip names the gap and the customers-file refusal.

### R2-18 · minor · security and work context

bin/ai-log:108-112, 853-854, 1113-1114: At company level the hashed `repo`, `plan`, `plan_key` and `id` are unsalted
unless the optional `~/.ai-log-salt` exists, and nothing creates it or warns when it is missing. Hashes of a guessable
repo or plan name (`h12 repo uptimeconsulting/<engagement>`) can then be confirmed by anyone who can read the log repo,
which defeats the purpose of hashing company names (plan review R6-33). Scenario: A machine without `~/.ai-log-salt`
records a company plan `plan-acme-migration.md` in `uptimeconsulting/acme-portal`. A collaborator later given read
access to the log repo, or GitHub support, computes `sha256("repo\nuptimeconsulting/acme-portal\n")[0:12]` and matches
it to the entry, confirming the engagement. A fix is to warn on stderr, or in `warnings`, when a company-level record
runs without a salt.
Not fixed: the user ruled the salt out ("Remove it").

### R2-19 · nit · security and work context

claude/skills/writing-plans/SKILL.md:122-124: The new delete rule tells the agent to put a tracked plan in a `git rm -f`
commit on the branch before it merges, with no customer carve-out. At customer level `git commit` is forbidden and the
step should be drafted for the user. In reviewing-in-rounds step 8 the same instruction is scoped to branches with
session-end commits, which never exist at customer level, but writing-plans states it generally. Scenario: A customer
repo tracks its plan files. The last task lands and the agent follows writing-plans: it runs `git rm -f plan-x.md`,
which is allowed, then `git commit`, which work-context.sh blocks. The run hits a guard block instead of drafting the
commit as § Work contexts requires.
Refuted: Downgraded from minor by the verifier. Downgraded to nit. No forbidden write can happen: work-context.sh blocks
`git commit` at customer level, and that block is final. The global CLAUDE.md also says § Work contexts outranks every
skill and tells the agent to draft the commit. The reviewing-in-rounds Completion step that runs this delete says
"Customer: draft it for the user". So the only cost is that the general sentence in writing-plans leaves out the
customer case: a wording gap that can lead to one blocked call, not a security failure.

### R2-20 · nit · security and work context

claude/skills/reviewing-in-rounds/SKILL.md:99-102: Step 7 says the standing yes covers `record` and `note` "at every
level". work-contexts.md says the same runs "at every level but customer", and "at customer level nothing is recorded
and nothing leaves the machine". The behaviour is safe because `ai-log` gates itself, but the skill's wording suggests a
write is approved at customer level. Scenario: A reader or a future editor of the skill takes "at every level" as
approval to run a log write in customer sessions, for example after a later change that lets `note` run with folded
names (follow-up 15c), with no separate customer-level approval.

### R2-21 · major · plan conformance

claude/skills/reviewing-in-rounds/SKILL.md:95: reviewing-in-rounds has more changes than the plan allows. The user
approved one skill line for Task 15b ("Yes, one line is fine"), and Task 17 says "`reviewing-in-rounds` is unchanged".
The diff adds three things: a step-4 clause "Nothing staged ... offer and run no commit"; a step-7 clause "or when there
was nothing to commit" (line 99); and a new step 8 "Landing" (lines 103-104), in which the skill makes a `git rm -f`
commit without offering it first. The plan records no deviation or user ruling for any of these. Scenario: This breaks
the user's limit on skill changes in § Approvals, which allows only the 15b line plus implementing-plans as the second
skill change. Step 8 also breaks work-contexts.md:85, which says "reviewing-in-rounds commits only after the user's
yes". Example: on a personal or company branch with session-end commits and a tracked plan, the skill now commits the
plan's removal without asking, even when the plan's `## Approvals` does not cover that commit.
Refuted: Not refuted. The reviewed plan says the user approved one line for Task 15b ("Yes, one line is fine"). Task 17
says outright that Completion "commits what is left ... and `reviewing-in-rounds` is unchanged", and that the landing
rule goes in implementing-plans. The diff adds three things to reviewing-in-rounds: step 4's "Nothing staged" clause,
step 7's "or when there was nothing to commit", and a new step 8 "Landing" that prescribes a `git rm -f` commit. Unlike
step 4, step 8 never says to offer that commit first. work-contexts.md:87 still says "`reviewing-in-rounds` commits only
after the user's yes". The plan records no deviation or ruling for any of this.
Fixed: in round 2's fixes.

### R2-22 · nit · plan conformance

bin/ai-log:110: The diff adds AI_LOG_SALT, which changes Task 15's interface. When `~/.ai-log-salt` exists, h12k mixes
the salt into the company-level `id`, `plan_key`, `repo` and `plan` (lines ~853-854 and ~1113-1114). Task 15's
Interfaces define `<id>` and `plan_key` as a sha256 over the origin, the plan basename and the sha only. The plan
records no deviation or ruling, and test_ai_log.sh has no test for the salt (grep -i salt finds nothing), including the
new exit 2 for an empty or unreadable salt file. Scenario: Machine A has a salt file and machine B does not. B's
company-level session-end `record` cannot find A's entries under the same plan_key, so its window starts at the plan's
first appearance and overlaps A's windows. Tokens are then counted twice in the per-plan summary that Task 15b's
introspection reads. A future regression in h12k, such as note's build_terms hashing without the salt, would also pass
the suite.
Refuted: Downgraded from minor by the verifier. Partly refuted. The salt is tested: test_ai_log.sh:933-977 covers a salt
changing the company hashes, the same salt giving the same hashes, exit 2 for an empty salt file and for one that cannot
be read, no salt when the file is missing, and note refusing with the wrong salt. The cross-machine scenario needs the
salt on one machine only. The ai-log header (lines 30-32) warns against exactly that: "copy it to every machine that
records the same company repos, or their entries stop chaining". What remains is that the plan's Interfaces don't
mention the salt and no deviation is recorded. That is wording in the plan.

### R2-23 · nit · plan conformance

bin/ai-log:1159: The diff adds two exit-1 cases that Task 15/15b's interface does not list and the plan does not record
as deviations. First, `record` (with or without --dry-run) refuses any entry that has a ~/.claude-customers term in a
tool, skill, agent or model name. Second, `note` at company level exits 1 when no markdown file in the repo hashes to
the entry's plan_key (line 712). Both are tested, but the Interfaces list of exit codes is now incomplete. Scenario:
Task 17's session end and Task 15b's step treat a nonzero exit as "goes in the report". A reader of the plan's
interface, or Task 15d, would not expect a customer-term refusal, or a note failure after the plan file has moved.
Refuted: Downgraded from minor by the verifier. Downgraded. Both exit-1 cases are documented in the script's header
(bin/ai-log:23-27), and both are tested. Every caller in the plan (Task 15b's step, Task 17's save) handles any nonzero
exit the same way: it goes in the report. So an incomplete exit list in the plan's Interfaces changes nothing anyone
does. Only the missing deviation note remains, and Task 13 deletes the plan anyway.

### R2-24 · minor · plan conformance

test/test_workflow_docs.sh:1: The new test file is untracked and is not in any task's Files list. Completion's pathspecs
are each task's Files list intersected with the staged paths, so this file is never staged or committed. The Task 17 and
15b grep tests it carries (the session-end doc's strings, the single `ai-log record <plan-file>`, the pointer within
counted line 100, the glob pins) would then never reach CI. It also uses `git -C "$repo"` for init and add (lines 83 and
92), against the plan's global constraint for scratch repos in tests. Scenario: After the final review's per-task
commits and the squash merge, `git ls-files test/test_workflow_docs.sh` prints nothing. A later edit that drops the
session-end pointer from implementing-plans passes CI.
Fixed: in round 2's fixes.

### R2-25 · minor · plan conformance

claude/CLAUDE.md:76: The adopted line differs from what the user approved. § Approvals (2026-11-09) adopts "Name issues
and PRs with their repo and a short title", and the only change the user sanctioned was making the example neutral. The
diff narrows the line to "In chat and reports", drops "short", and adds "titles and links keep theirs", whose meaning is
unclear. None of this is recorded. Scenario: Commit messages, PR descriptions and issue bodies fall outside "chat and
reports", so a bare #900 is still allowed there. The adopted rule did not make that exception.
Fixed: in round 2's fixes.

### R2-26 · minor · plan conformance

claude/skills/writing-plans/SKILL.md:124: writing-plans, skill-precedence.md and staged-workflow.md now all say that a
tracked plan is removed with a `git rm -f` commit owned by reviewing-in-rounds Completion. writing-plans is not in any
Files list of this run's tasks. skill-precedence.md's Task 17 entry covers only "its line on checkpoints in the index",
but the diff also adds a landing clause to the finishing-a-development-branch row and a new paragraph (line 51). Task 13
assigns the `git rm` commit to the run's session, not to the skill. None of this is recorded. Scenario: The durable docs
describe a skill behaviour (Completion makes the `git rm -f` commit) that rests only on the unapproved step 8 in
reviewing-in-rounds. Dropping that step to restore the approved scope leaves three docs pointing at a step that no
longer exists.
Fixed: in round 2's fixes.

### R2-27 · minor · plan conformance

bin/ai-log:276: The plan's `Deferred:` lines list items the diff now fixes. Task 15 says "model ids aren't narrowed at
company level", but okmodel now narrows them. Task 16 says "`--update-baseline` keeps a pin on a skill over 250 and
calls 250 a warn line" and "Nearing a cap is a note no longer holds", but the checker now drops the pin and the tip is
rewritten. In the reviewed plan these lines are unchanged. (The working copy of the plan was not checked.) Scenario:
Task 13 files every `Deferred:` line into the follow-up issue before deleting the plan. That issue would then carry work
that is already done, and the session would have to triage it later.
Fixed: in round 2's fixes.

### R2-28 · nit · plan conformance

claude/rules/writing-code.md:8: Task 16 names exactly `**/*.cs`, go, rs, rb, swift, c, cpp, h, php, scala and gradle.
The diff also adds mjs, cjs, mts, cts, razor, cshtml, cc, cxx and hpp. No deviation is recorded, although the user's "C#
plus the common languages" probably covers them. Scenario: The plan's Change list and the rule's `paths:` no longer
match, so someone checking the task against its spec finds globs it does not name.

### R2-29 · nit · plan conformance

claude/skills/reviewing-in-rounds/SKILL.md:101: Step 7 says the standing yes covers `record` and `note` "at every
level". The work-contexts.md paragraph that Task 15b added says "at every level but customer", and nothing is recorded
at customer level. The two descriptions disagree. Scenario: A reader of the skill alone could expect a customer-level
entry or a customer-level `note`. `ai-log` prints only its deferral line there.
Refuted: Dropped by the verifier. The skill step repeats, word for word, the sentence Task 15b's Change prescribes
("covers `record` and `note` writing to their private log repo, at every level"). It says what the user's standing yes
covers, not that something is recorded at every level. The next clause and ai-log's customer deferral line say what
happens at customer level, and work-contexts.md states the outcome. The two descriptions don't contradict each other,
and the skill conforms to the plan.

### R2-30 · minor · the change as a whole

claude/skills/reviewing-in-rounds/SKILL.md:103-104: Completion step 8 adds a second commit that the workflow makes on
its own: the tracked plan's `git rm -f` commit. It has no approval gate and no level branch. Step 4 offers its commit
and runs it only on a yes, and drafts it at customer level. Step 8 just says the plan "goes in a `git rm -f` commit".
work-contexts.md:85 still says the workflow skills never commit on their own "bar one exception", meaning the
session-end commit. Scenario: Company-level run with a tracked plan (a session end committed it): the final review runs
step 8 and commits the deletion without the yes that step 4 and global § Approvals require (an approval covers what it
names). If a customer repo tracks a plan, the skill's text tells Claude to commit there. The guard then blocks it, but
nothing in the step says to draft the commit for the user instead. Both docs now contradict each other about how many
commits the workflow makes on its own.
Refuted: Downgraded from major by the verifier. Downgraded. The customer half is refuted: step 8 applies only to 'a
branch holding session-end commits', and session-end-save.md commits nothing at customer level. writing-plans also
excludes plan-*.md at company and customer level, so the workflow never produces a tracked plan there. The company half
needs a plan someone tracked by hand. The git rm commit runs only as part of Landing, which the user chooses and
performs ('I open and squash-merge it'). The user approved this exact design in the plan ('Commit it on the branch',
R11-15, given as 'since a tracked plan is git rm'ed on the branch before the squash merge'). What remains is real but
cheap: step 8 has no explicit offer/yes gate, unlike step 4, and work-contexts.md:85 ('never commit on their own, bar
one exception') now contradicts it.
Fixed: in round 2's fixes.

### R2-31 · minor · the change as a whole

claude/docs/session-end-save.md:20-24 (with hooks/pre-commit:36-47 and claude/skills/writing-plans/SKILL.md:25): At
personal level the session-end save adds an untracked plan, but in this repo the pre-commit hook rejects any tracked .md
outside claude/ that lacks a doctoc marker. writing-plans never adds `<!-- DOCTOC SKIP -->` to a new plan. So the first
commit attempt always fails, and step 3's retry commits without the plan files. Scenario: A new personal plan here
(`plan-foo.md`, no marker) reaches a session end. The commit fails on the doctoc check, the retry commits only the
checkpoints, and the push carries no plan. Another machine that runs `git switch && git pull` has nothing to resume
from. That breaks the save's stated purpose: "another [machine resumes] from the last session end's push". The failure
is reported, so this is a silent loss of function rather than lost data.
Fixed: in round 2's fixes.

### R2-32 · minor · the change as a whole

plan-ai-framework.md Task 16 Deferred: line (reviewed-plan.md:3870) and Task 17 Tests (reviewed-plan.md:3966-3967): Plan
text went stale once the code proved the old assumption wrong. Task 16's Deferred line still lists "`--update-baseline`
keeps a pin on a skill over 250 and calls 250 a 'warn line'" and the tip's "Nearing a cap is a note". The working tree
has fixed both: bin/check-md-limits:521-526 drops a skill's pin even over the cap and says "aim", and
tips/24_claude_code.md was reworded. Task 17's Tests still say "the skill no more than its pin", but the pin no longer
exists. Scenario: Task 13 copies every open `Deferred:` line into its GitHub issue before the plan is deleted. The issue
would then carry two items that are already fixed and a test condition that can no longer be checked.
Fixed: in round 2's fixes.

### R2-33 · minor · the change as a whole

plan-ai-framework.md § Implementation status, rows 15b and 13 (reviewed-plan.md:178, 183): These items are not yet
handled; they are named in the plan, not dropped: Task 15b's end-to-end check (a real `ai-log record` and `note` pushed
after the final commit), Task 13's issue carrying every `Deferred:` line, 15c, 15d, the Revisit, Task 17's accepted gap
and Task M, and Task 13's `git rm`. reviewing-in-rounds step 7 is the only path that creates the first real entry. No
test exercises `record` together with `note` against the real ~/.ai-framework-log, so the integration stays unproven
until this review's Completion runs. Scenario: If the final review's Completion skips step 7, or step 7 fails (for
example bash 3.2 on PATH, which exits 2), Task 15b is marked DONE while its end-to-end requirement never ran. The plan
is then deleted and the requirement disappears with it.
Refuted: Dropped by the verifier. No defect. The plan tracks the pending end-to-end run explicitly (row 15b: 'the
end-to-end run is the final review's step'). reviewing-in-rounds step 7 makes `ai-log record` mandatory after the
commit, and any failure goes into the report. The scenario relies on Completion skipping a required step, so it is
speculative. The other items are listed as pending, not lost.

### R2-34 · nit · the change as a whole

.github/workflows/markdown.yml:45-46: The comment says "A pin can only be removed by the file shrinking under its warn
line". That is no longer true: a skill now has no warn line, and `--update-baseline` drops its pin whatever its length,
as the implementing-plans pin was in .md-baseline. Scenario: Someone reading the CI step to work out why a skill's pin
disappeared is told it can only happen by the file shrinking, and goes looking for a bug that isn't there.

### R2-35 · nit · the change as a whole

claude/docs/session-end-save.md:23: "At company level drop `--others`: the plan is excluded there" gives a reason that
would make dropping `--others` pointless. With `--exclude-standard`, an excluded plan is never listed by `--others`
anyway. The flag only matters for a company plan that is untracked but not excluded, which the stated reason doesn't
cover. Scenario: A reader assumes `--exclude-standard` alone keeps the plan out and treats the instruction as optional.
The rule only holds because of the flag, not for the reason given.

### R2-36 · minor · fit with the surrounding code

bin/ai-log:136: `normalize_origin` copies the guard's `parse_url` (claude/hooks/work-context.sh:218); its own comment
says it reads URLs "as the guard's parse_url reads it". The copy has already drifted. It leaves out `host_alias`, the
rule that maps an SSH alias such as `github.com-work`, or a dotless alias, to the real host, and it accepts local-path
origins that `parse_url` rejects. ORIGIN feeds `plan_key` and `id` (line 853) and the allowlist's host/owner. Scenario:
Machine A's clone has origin `git@github.com:andrelin/dotfiles.git` and machine B's has
`git@github.com-personal:andrelin/dotfiles.git`, a common multi-account SSH alias. The two normalize to
`github.com/andrelin/dotfiles` and `github.com-personal/andrelin/dotfiles`, so `h12k "$ORIGIN" "$bn"` gives two
plan_keys. The same plan's entries stop chaining across machines, and each summary shows only its own machine's windows.
Exposing the guard's parse (a `work-context.sh` subcommand that prints host/owner/repo) would avoid a second parser.
Refuted: Not refuted. normalize_origin (bin/ai-log:136) has no host_alias step, while parse_url in
claude/hooks/work-context.sh does (lines 246-247, host_alias at 399). Take an origin
`git@github.com-personal:andrelin/dotfiles.git`. The guard maps the alias and reports personal, so compute_level returns
before the allowlist, but ORIGIN keeps `github.com-personal/andrelin/dotfiles`. That gives a different plan_key/id from
a clone on another machine that uses plain github.com. A company repo behind an alias is worse off: the guard says
company, hostowner `github.com-work/uptimeconsulting` misses the built-in list, and LEVEL falls to customer, so nothing
is recorded. The scenario holds. The lens is about fit, so minor stays.
Fixed: in round 2's fixes.

### R2-37 · minor · fit with the surrounding code

bin/check-md-limits:231: The front-matter detection is now written twice in Perl: once in `count_lines`, and once in
`long_lines` (around line 383). The new copy's comment, "Same test as long_lines", records the duplication instead of
sharing the code, and the two copies already differ in form: `long_lines` has an extra `^\s+[\w.-]+\s*:` arm and handles
blank lines differently. The plan's Task 16 `Deferred:` line notes this, but it is still unresolved. Scenario: A later
fix to what counts as front matter, for example accepting a YAML block scalar line, gets applied to only one copy. A
file's front matter would then be skipped for line length but counted toward the length cap (or the reverse), so the
line-length check and the length cap disagree about the same file.
Refuted: Not refuted. count_lines (around line 228) and long_lines (around line 383) both carry their own Perl
front-matter detection, and the comment says "Same test as long_lines" instead of sharing code. They behave the same
today: the extra `^\s+[\w.-]+\s*:` arm is already covered by `^\s+\S`, and both handle blank lines the same way. So
nothing is wrong now. The risk is drift when a later fix lands in only one copy, which is real and cheap to live with.
Fixed: in round 2's fixes.

### R2-38 · nit · fit with the surrounding code

bin/check-md-limits:391: The rewritten comment says "hence the blank-line test above", but the blank-line test comes
right after the comment, below it. The sentence it replaced ("Real front matter is an unbroken block") no longer holds.
The new wording reads as a trace of the edit rather than a description of the code. Scenario: A reader looks above line
391 for a blank-line test and finds only the `for my $j` loop header.

### R2-39 · nit · fit with the surrounding code

bin/check-md-limits:165: "A skill has no aim" is encoded as `echo "250 250"`, and the code infers it from `warn == hard`
at lines 521 and 545. Everywhere else in the script, warn is the aim. The sentinel is implicit, and the SKIP message is
now copied into two branches (521-524 and 525-526). The DROP message also hardcodes "a skill", although the test is only
`warn == hard`. Scenario: Someone later gives another file type equal numbers, for example a 50/50 rule. That type
silently loses its pins, and `--update-baseline` prints "is a skill with no aim" for a file that is not a skill.
Refuted: Partly answered: the comment on limits_for (line 155-156) documents "equal numbers mean no aim", so the
sentinel is not entirely implicit. The rest stands. SKILL.md is the only type with warn == hard, yet the DROP message
hardcodes "is a skill with no aim", and the SKIP line is copied into both branches. Wording and structure only, so nit.

### R2-40 · nit · fit with the surrounding code

bin/ai-log:1216: `refuse_customer_terms` reuses `add_customer_line` by setting the global `TERMS_FILE` and resetting it
to an empty string afterwards; `add_term` (line 514) reads it as `${TERMS_FILE:-$TMP/terms}`. The idiomatic form is
`local TERMS_FILE=...`, which bash scopes dynamically. The customers-file read loop is also a copy of the one in
`build_terms` (line 695), where one helper would do. Scenario: An early return or a `die` inside the loop leaves
TERMS_FILE set, and a later `add_term` in the same process writes note's redaction terms into `cterms` instead of
`$TMP/terms`. The two loops can also drift apart, for example if one gains the readable-file check and the other does
not.
Refuted: The failure scenario does not hold. die exits the process, so no later add_term runs. A return inside
add_customer_line comes back to the loop, and the loop still reaches `TERMS_FILE=""`. What remains is the style point
(`local TERMS_FILE` would be the idiomatic form) and a three-line read loop copied from build_terms (line 695). Nit.

### R2-41 · nit · fit with the surrounding code

test/test_workflow_docs.sh:45: The file defines a `count` helper, but uses it only in lines 45-61. Lines 62-69 call
`grep -cF` directly, and line 62 uses `grep -cE` for a plain fixed string. Two assertion forms sit side by side: `$([[
$(count …) -ge 1 ]] && echo yes)`
against "yes", and the raw count against "1". Scenario: A reader extending the test has to choose between two idioms.
With `-E`, a future needle containing `.` or `(` would be read as a regex and could match text it shouldn't.

### R2-42 · nit · fit with the surrounding code

claude/CLAUDE.md:76: The adopted line ends with "titles and links keep theirs", which is unclear. It is also placed
under § Working on code, among coding conventions, even though it governs chat and reports. The bullet just above it
still says "you name the work by its issue and PR numbers", which the new line silently qualifies. Scenario: A session
reads "titles and links keep theirs" and cannot tell whether an MR title or a link label may keep a bare `#900`. The
user's ask was only to "say where the issue lives … and give a short title".

### R2-43 · nit · fit with the surrounding code

claude/docs/work-contexts.md:86: In the same paragraph, line 86 names the sibling doc bare (`session-end-save.md`) while
line 93 uses `~/.claude/docs/staged-workflow.md`. `staged-workflow.md` also names its siblings bare
(`session-end-save.md`, `work-contexts.md`, `review-lenses.md`, `implementing-plans-reference.md`). The surrounding docs
consistently use the `~/.claude/docs/…` form (for example `customers-file.md`, `markdown-limits.md`,
`implementing-plans-reference.md`). This is already a `Deferred:` line in Task 13. Scenario: A session reading
`work-contexts.md` from another repo's cwd tries to open `session-end-save.md` relative to that cwd, and finds nothing.

### R2-44 · nit · fit with the surrounding code

claude/skills/implementing-plans/SKILL.md:145: The red flag's reality column now reads "Only the session-end commit
exists." That is wrong at customer level, where nothing is committed. It also no longer answers the excuse it pairs with
(a checkpoint commit). This is already a `Deferred:` line in Task 17. Scenario: At customer level an agent reads that a
session-end commit "exists" and takes it as permission to commit, while `session-end-save.md` § At customer level says
nothing is committed.

### R2-45 · nit · fit with the surrounding code

claude/rules/writing-code.md:45: The `.editorconfig` with `dotnet format` insertion pushes this bullet line to exactly
150 characters, while the rest of the bullet wraps at about 118. The edit did not rewrap the paragraph. Scenario: The
next example added to the formatter list takes the line past the 150-character limit, and `bin/check-md-limits` fails on
a one-word edit.
Refuted: Confirmed. Line 45 of claude/rules/writing-code.md is exactly 150 characters, which is MAX_LINE_CHARS=150 in
bin/check-md-limits, and the lines around it run 107-115. It passes today, so this is a nit.

### R2-46 · nit · fit with the surrounding code

tips/24_claude_code.md:87: "a skill has no aim, so no note (250 passes, 251 fails): its first 100 lines hold the task" —
after the description clause, "its first 100 lines" reads as the description's. This is noted in Task 16's `Deferred:`
line and is still unresolved. Scenario: A tips reader takes the 100-line placement rule to apply to a skill's
description rather than its body.

### R2-47 · nit · docs ship with the change

claude/docs/work-contexts.md:85-87: The doc says the workflow skills never commit on their own "bar one exception", the
session-end commit, and that `reviewing-in-rounds` "commits only after the user's yes". The diff adds a second commit
that neither the doc nor `skill-precedence.md:196` mentions: the tracked plan's `git rm -f` commit before landing
(reviewing-in-rounds Completion step 8, `session-end-save.md` § Landing). Neither file says whether that commit needs a
yes, or who opens and squash-merges the PR. Scenario: At personal level with a tracked plan, a future run follows
Completion step 8 and makes the `git rm -f` commit without asking, because no yes is required there. work-contexts.md
says it only commits after a yes and has a single exception, so the doc no longer describes what the skills do. A reader
auditing approvals from this doc misses one commit.
Refuted: Downgraded from minor by the verifier. Partly refuted. The doc's general rule already covers the `git rm -f`
commit. work-contexts.md says `reviewing-in-rounds` "commits only after the user's yes", skill-precedence.md:60 says the
workflow skills commit only after the user's yes, and landing needs a PR and a merge that each need their own approval
under § Approvals. The scenario that a run commits without asking "because no yes is required there" is inferred from
silence: nothing in step 8 or § Landing waives the yes. What remains is that the doc does not name this commit and step
8 does not repeat that it needs a yes. That is wording, not a wrong description. Also, skill-precedence.md:196 does not
exist; the file is much shorter than that.

### R2-48 · minor · docs ship with the change

bin/ai-log:24-31 (vs plan Task 15 Interfaces / Result, and claude/docs/staged-workflow.md): The build added behaviour
that Task 15's spec does not have, and no Deviation line records it: `AI_LOG_SALT` (default `~/.ai-log-salt`) salts the
company-level `repo`, `plan`, `plan_key` and `id` hashes; a new exit 1 refuses an entry whose names hold a
`~/.claude-customers` term; another exit 1 fires when `note` at company level can't find the plan; and an unreadable or
empty salt file exits 2. The tip and the script header describe all of this. The plan's `<id>` and exit-code interface
does not, and staged-workflow.md doesn't mention the salt either. Scenario: At company level, an id computed as the plan
specifies (sha256 over origin, basename and sha) doesn't match a recorded entry once a salt file exists. A second
machine without the salt starts a new chain, which the tip warns about but no durable decision doc explains. When Task
13 deletes the plan, the reason for the salt is lost and the plan's spec stays wrong until then. This breaks the rule
that a deviation in a task's interface is recorded in that task.
Fixed: in round 2's fixes.

### R2-49 · nit · docs ship with the change

tips/24_claude_code.md:136-155: Tip 24.8 (`ai`) still says one session "drives the rest ... stopping only for your
decisions". It doesn't say that an `ai implement` session now commits `Work in progress: Tasks …` and pushes the branch
at each session end (personal and company level), or that such a branch must land by a squash-merged PR rather than a
fast-forward. This is a user-visible change in what a stage `ai` starts does to the user's branch and remote. Scenario:
A user reads Tip 24.8 and expects nothing to be committed before the final review, as the old skill said. Asking the
session to wrap up then produces a commit and a push they didn't expect, and fast-forwarding `main` puts WIP commits on
it. Docs ship with the change: the tip for the user-facing command should state the new behaviour.
Refuted: Downgraded from minor by the verifier. Downgraded. Tip 24.8 makes no claim that the change makes false. It
never said nothing is committed before the final review, and it describes stages, not commit mechanics. The repo
convention ties tip updates to a changed user-facing script under source/ or bin/, and bin/ai is unchanged in this diff.
The new behaviour is documented where the session follows it: implementing-plans SKILL.md, session-end-save.md,
skill-precedence.md and staged-workflow.md. Tip 25.1 also mentions the session-end record. Adding a line to the tip
would help, but leaving it out is a gap in completeness, not a stale doc.

### R2-50 · minor · docs ship with the change

claude/CLAUDE.md:76: The adopted line was approved as "Name issues and PRs with their repo and a short title", with only
its example made neutral. As committed, it is limited to "In chat and reports" and adds "titles and links keep theirs".
That narrows the user's rule beyond the example change the § Approvals entry records, and the plan doesn't record the
rewording. The Forgejo bullet two lines up (line 74) still says to "name the work by its issue and PR numbers" with no
repo, which pulls against the new line. Scenario: Claude names an issue in a plan heading, commit message or issue body
as a bare `#53` (writing-plans SKILL.md:79 shows `## Task 2 · #53: …`). The new line now allows this because it is not
"chat or reports", but the user's approved wording forbade it everywhere. The Forgejo bullet's "by its issue and PR
numbers" also reads as permission for bare numbers.
Fixed: in round 2's fixes.

### R2-51 · nit · docs ship with the change

claude/rules/markdown-limits.md:31; claude/docs/markdown-limits.md:82; bin/check-md-limits:38: All three still say "A
file over its warn line can be pinned" as a general rule. A skill no longer has a warn line, and its pin is now ignored
and dropped. Only the docs' new paragraph says so; the rule a writer loads doesn't. Scenario: A writer with a 240-line
skill reads the rule, tries `--update-baseline` to pin it, and gets a DROP message. The rule they loaded gave no hint
that skills are exempt from pinning. This is related to, but separate from, Task 16's deferred "warn line" wording in
the DROP message.
Refuted: Mostly refuted, kept as a nit. "A file over its warn line can be pinned" is literally still true. The rule's
own table shows a skill's aim as "—", so a 240-line skill is over no warn line, and a reader of the rule can infer that
it cannot be pinned. What remains is the term: the table says "Aim under" but the pin sentence says "warn line", so the
link between the two is not explicit. That is wording.

### R2-52 · nit · docs ship with the change

claude/docs/session-end-save.md:3: The doc says it is read from `implementing-plans` § *Finish*. The skill's heading is
"Finish with the final review, in this run", and other docs cite sections by their full italic heading. Scenario: A
reader searching the skill for a section headed *Finish* finds none and has to guess which section is meant.

## Round 3

### R3-1 · major · correctness and failure modes

bin/ai-log:768-774: The JQ_LEAK check skips the `by_agent_type` keys. It looks only at the keys of tools, skills,
agents, tokens and workflows.phases, plus skills_outside and framework.plugins. At personal level `rn_agent` keeps a
custom agent type as it is, so a customer's name can reach the pushed entry through `sessions[].by_agent_type` and
`totals.by_agent_type`. That is the leak `refuse_customer_terms` exists to stop. Scenario: Reproduced with the script's
own JQ_TERMDEFS and JQ_LEAK and a terms file holding `C<TAB>acme`. An entry whose only customer-named key is
`by_agent_type: {"acme-reviewer": …}` returns false, so it is not refused. The same name under `agents`
(`acme-reviewer/default`) returns true. Two plausible paths lead there: a Workflow agent whose `.meta.json` agentType is
a user-scope agent named for a listed customer, or an Agent call made before the window start whose subagent records
fall inside the window. Either way the type lands in `by_agent_type` and not in `agents`. `record` then commits and
pushes it to the log repo.
Fixed: `JQ_LEAK` checks `by_agent_type` keys in totals and every session; tested.

### R3-2 · major · correctness and failure modes

bin/ai-log:444: `.secs[-1].lines += [$l]` assigns through a negative array index. jq 1.6 rejects that with "Out of
bounds negative array index"; jq 1.7 fixed it. RHEL 9 still ships jq 1.6, and so does Ubuntu 22.04. The CI RHEL 9 leg
installs jq with `yum install jq`, and the project supports RHEL and Ubuntu. Locally the suite only runs jq 1.8.2. Not
run under jq 1.6: downloading a jq 1.6 binary was refused in this session. Scenario: On RHEL 9 or Ubuntu 22.04 with
distro jq 1.6, run `ai-log record` on any plan that has a `## Review log (` section followed by a line. That covers the
fixture `test/ai-log/plan-example.md` and every real plan. JQ_REVIEWS_A fails, the ERR trap exits 3 with "internal error
… nothing was written", and no entry is ever recorded. Once pushed, the CI RHEL 9 leg's test_ai_log.sh should fail. A
fix: `.secs |= (.[:-1] + [.[-1] | .lines += [$l]])`, or keep the index in the reduce state.
Fixed: the update uses a computed index, no negative-index path update left.

### R3-3 · minor · correctness and failure modes

claude/docs/session-end-save.md:30-32: In the public-repo check, a failing path is unstaged with `git restore --staged`.
Step 4 then deletes 'the refs the commit now holds', but that commit no longer holds the checkpointed content of the
restored path. The ref, the only durable copy of that checkpoint, is deleted anyway. Scenario: A checkpointed task's
file fails the personal-public bar and is restored to unstaged. The commit is made without it, and `git update-ref -d`
removes every ref under `refs/checkpoints/<branch>/`. On resume, `HEAD^{tree}` lacks the file's checkpointed state, so
its change looks like a half-done task's leftover. On another machine it is lost from the plan's view: the leftover is
never pushed, and the task's row still says DONE.
Fixed: session-end-save step 4 keeps every checkpoint ref when step 2 restored a checkpointed path, and reports it.

### R3-4 · minor · correctness and failure modes

bin/ai-log:955-966: The plan says a `--dry-run` with a given `<commit>` no newer than the window's start skips the
exit-1 check. The session selection that follows still filters on `. <= $e and . > $s`, so in that case the dry run dies
anyway, with the misleading message "no session in scope: no session names `<plan>` inside the window". It should report
the empty or inverted window. Scenario: Run `ai-log record --dry-run plan-x.md <old-sha>`, where the old commit predates
the last entry's window.end. Line 955 is skipped because of the dry run, `sessions` is empty, and the run exits 1
claiming no session names the plan. The real cause is that the commit is older than the window start.
Fixed: a dry run on a commit no newer than the window start dies with 'window is empty or inverted'; tested.

### R3-5 · minor · correctness and failure modes

bin/ai-log:887-888,883-884: Window chaining is by wall-clock `window.end` across machines, while each machine only sees
its own transcripts. A session on machine B that overlaps in time with an entry machine A records has its records before
A's `window.end` dropped from B's later entry, and they are never counted. Scenario: Machine A ends a session and
records a window ending at 10:00. Machine B's session ran 09:30–11:00 and records at 11:00, so its start is A's 10:00.
B's tokens, turns and agents from 09:30 to 10:00 are filtered out by `inwin` and lost. The only sign of it is the
numbers being low.
Refuted: Kept at minor. The plan specifies this behaviour on purpose (plan line 3604: non-overlapping windows that start
at the latest window.end among entries pulled from origin), so it is not a departure from the spec. The scenario needs
two machines with sessions on the same plan running at the same time, which the session-end and resume workflow makes
unusual. It is a real undercount that nothing warns about, but cheap to live with.
Fixed: kept as designed; the accepted undercount is documented in `bin/ai-log`'s header and tip 25.

### R3-6 · nit · correctness and failure modes

claude/docs/session-end-save.md:16: "Stop and report … if the branch is not the plan's" has no defined way to tell what
the plan's branch is. Plans carry `Base:` but no branch field, so the check can't be applied mechanically. Scenario: A
session end on a plan with no branch named anywhere: the agent either guesses or skips the check, so the commit and push
can land on whichever branch is checked out.
Refuted: Dropped by the verifier. The plan's branch is defined. implementing-plans/SKILL.md:46 says "The branch: the
plan file's name minus `plan-` and `.md` (`plan-42-login.md` → `42-login`)", and session-end-save.md is read from that
skill's § Finish. The check can be applied mechanically.

### R3-7 · nit · correctness and failure modes

claude/CLAUDE.md:76-77: The adopted line says to name an issue or PR by repo and title in markdown files, never as a
bare `#N`. The repo's own CLAUDE.md still says "The Renovate dependency-dashboard issue is **#3**", and the Forgejo
bullet just above still says "name the work by its issue and PR numbers" without the repo-and-title form. Also,
`dotfiles#900` is not a form GitHub autolinks in commits or PR text (that needs `owner/repo#900`), which the second
clause only hints at. Scenario: A session reads both lines and writes a bare `#3`, as the repo CLAUDE.md does. Or it
writes `dotfiles#900` in a commit message, where it renders as plain text and not a link.
Refuted: Partly stands, as a nit. The repo CLAUDE.md:31 still writes a bare **#3** in a markdown file, which goes
against the new rule. The autolink part does not hold: the clause already says that where the platform renders a link
(commits, issue and PR text), you use a form that links. `dotfiles#900` is given as the chat and markdown-file form
only. The Forgejo bullet contrasts issue numbers with plan task numbers, so it does not conflict.

### R3-8 · major · tests

.github/workflows/tests.yml:4-14 (with test/test_workflow_docs.sh:1-4): test/test_workflow_docs.sh exists to guard the
wording of claude/docs/session-end-save.md, the implementing-plans and reviewing-in-rounds skills, skill-precedence.md
and writing-code.md's globs. The same goes for the skill and doc assertions at the end of test/test_ai_log.sh (lines
~1050-1075). But the Tests workflow (and tests-wsl.yml) lists `claude/skills/**`, `claude/docs/**`, `claude/rules/**`
and `**.md` under paths-ignore, so CI never runs these guards on the one kind of push they protect against. Scenario: A
later commit touches only claude/docs/session-end-save.md, for example dropping `--allow-empty`, `ai-log level` or the
quoted ls-files command, or it moves the session-end pointer in implementing-plans/SKILL.md past counted line 100.
Tests.yml is skipped, so CI is green and the regression lands on main. The guard only fires if someone runs the suite
locally.
Fixed: new `.github/workflows/workflow-docs.yml` runs the three guard scripts on pushes touching those paths.

### R3-9 · major · tests

test/test_ai_log.sh:139: Task 15's spec and Tests require recording the framework's `claude/` dirty flag
(`dotfiles_dirty`). The only assertion expects `false` from a clean fixture tree, and no test makes `claude/` dirty and
expects `true`. So this requirement has no test that can fail. Scenario: bin/ai-log:1084 regresses to always
`fw_dirty=false`, or runs `git status` in the wrong directory, or uses the wrong pathspec. Every entry then claims a
clean framework even when local skill edits drove the run, and the whole suite stays green.
Fixed: tests dirty the framework's `claude/` (untracked and modified) and expect `true`, and `false` outside it.

### R3-10 · minor · tests

test/test_workflow_docs.sh:47-53: The session-end guard pins `ai-log level`, the commit message, the `record` call, the
ls-files form and `git rm -f`. It does not pin `--allow-empty`, the `git update-ref -d` ref deletion or `git push -u origin <branch>`.
Task 17 depends on these: `--allow-empty` is why every session end has its own HEAD and its own log entry, and the push
is why another machine can resume. These steps were only checked by hand, once. Scenario: A reword drops `--allow-empty`
from step 3. A second session end with nothing new checkpointed then fails with 'nothing to commit', no new HEAD is made
and `ai-log record` reuses the earlier id. No test fails.
Fixed: assertions pin `--allow-empty`, `git update-ref -d` and `git push -u origin <branch>`.

### R3-11 · minor · tests

test/test_workflow_docs.sh:83-92: Only the personal-level add command is extracted from the doc and executed. The
company-level variant is given as prose ('drop `--others`', so only tracked plan files are added) and is never derived
or tested. That variant is the one that keeps an excluded company plan out of the commit. Scenario: The doc's
company-level instruction is reworded or lost and an untracked, info/exclude'd company plan gets committed and pushed.
Nothing in the suite would notice.
Fixed: the company-level add is derived from the doc and executed; an excluded untracked plan stays out.

### R3-12 · minor · tests

test/test_ai_log.sh:1063-1065: The pointer-line check restates bin/check-md-limits' counting rules in awk: naive front
matter, every `#+` line treated as free even inside a fence, no YAML check. test_workflow_docs.sh:34-44 measures the
same thing correctly through `--count-raw`, specifically so that a 'fence, front matter or heading rule is never
restated'. The pointer currently sits at exactly counted line 100, so a divergence between the two counts flips one test
and not the other. Scenario: A fenced example holding a `# ...` line is added above the pointer in
implementing-plans/SKILL.md. The awk count drops by one while the checker's count does not, so the two tests disagree
about whether the pointer is within the first 100 lines.
Fixed: the count uses `bin/check-md-limits --count-raw`.

### R3-13 · minor · tests

test/test_ai_log.sh:1059 vs test/test_workflow_docs.sh:48: The two files assert the same doc requirement differently.
test_ai_log.sh requires `ai-log level` to occur exactly once ("1") in session-end-save.md, while test_workflow_docs.sh
requires at least once. Exactly-once is not a requirement, and the duplicate makes the suite brittle. Scenario: The doc
legitimately mentions `ai-log level` a second time, for example in the customer section. test_ai_log.sh fails although
nothing is wrong.
Fixed: at least once.

### R3-14 · minor · tests

test/test_ai_log.sh (no test); claude/skills/reviewing-in-rounds/SKILL.md:100: Task 16's rule says everything needed for
the task sits within a skill's first 100 counted lines. The pointer from implementing-plans is checked against that, but
reviewing-in-rounds' step 7 (`ai-log record <plan-file>`, Task 15b's trigger) is only checked for order and uniqueness,
not position. It sits at counted line 77 of 94 today. Scenario: reviewing-in-rounds grows past 100 counted lines above §
Completion. The record trigger falls into the 'clarification only' zone and the suite stays green.
Fixed: a check places step 7's `ai-log record <plan-file>` within the first 100 counted lines.

### R3-15 · minor · tests

test/test_ai_log.sh:690-750 (redaction boundaries): The token rules are tested inside their limits but not at the
boundary or one past it. There is a 40-character hex run but no 31- versus 32-character run, and no 19- versus
20-character `sk-` body, although the length limits are spec (32+ base64/hex) and a 15b deviation (`sk-` minimum 20).
Scenario: The `{32,}` quantifier becomes `{40,}`, or the `sk-` lookahead's `{20}` becomes `{24}`. A 32-character secret
or a 20-character `sk-` key then leaks into the pushed note and no assertion fails.
Fixed: boundary tests: hex, alphanumeric and base64 at 31/32, `sk-` at 19/20.

### R3-16 · minor · tests

test/test_ai_log.sh:584-597: The spec says a failed `git pull` (and a dry run's `git fetch`) in the log clone 'warns'.
The unreachable-origin test asserts only the push-failure warning, and no test asserts the pull or fetch warning at
bin/ai-log:859/861/1184. Scenario: The pull or fetch failure is silently swallowed with no warning. The window can then
start too early because newer entries were missed, the entry double-counts tokens, and nothing tells the user.
Fixed: tests assert the pull and fetch warnings with a broken log-clone origin.

### R3-17 · minor · tests

test/test_ai_log.sh:267-268: The summary is checked to sum all windows for tokens, rounds, user turns and questions.
'Agents per type' and 'workflow phases' are only grepped for presence, and only window 1 has agents or phases. Code that
took the first entry, or any single entry with agents, would pass, although Task 15b requires each line to be summed
over every entry with this plan_key. Scenario: The jq at bin/ai-log:791-792 regresses to `$E[0]`. Agents and phases from
later windows (session-end entries) drop out of the introspection's evidence and no test fails.
Fixed: a later window carries agents and a phase; the summed values are asserted.

### R3-18 · minor · tests

test/test_check_md_limits.sh:437-443: Task 16's Tests say 'the same lines as body still warn'. The front-matter case
uses `k$i: v` lines, while the body case turns `# c` into `- c`, so the two compare different lines. The plan recorded
this as Deferred and the final review was to fix it, but it is unchanged. Scenario: A counting change that treats `key: value`
lines in a body as free would leave both assertions green, because the body test never contains such lines.
Fixed: the body case uses the same `k$i: v` lines.

### R3-19 · nit · tests

test/test_check_md_limits.sh:384-386: The rule's cap is tested only one past the limit (51 lines → ERROR). At-the-limit
cases (50, and the aim at 30/31) are not exercised in the new block, whereas the skill and non-skill files get both
sides of each boundary. Scenario: An off-by-one in limits_for for rules (for example `>=` against the cap) would go
unnoticed.

### R3-20 · nit · tests

test/test_ai_log.sh:1078, test/test_workflow_docs.sh:79-81: Several assertions restate a literal from the file under
test, such as `grep -cw bin/ai-log` on shellcheck.yml and each glob line of writing-code.md. They guard against deletion
only and cannot show the glob loads (the load check was by hand). That is acceptable as a guard, but they are not
behaviour tests. Scenario: A glob written with a typo in both places, for example a wrong extension, passes.

### R3-21 · minor · security and work context

bin/ai-log:768-774 (JQ_LEAK), bin/ai-log:1114-1122: refuse_customer_terms checks only the tool, skill, agent, model,
phase and plugin keys. It never checks the entry's `repo` and `plan` fields, which at personal level hold the real
`<owner>/<name>` and the plan's basename. So a customer named in ~/.claude-customers can reach the pushed entry through
either field, even though Task 15 requires the log repo to be 'still free of customer details' and `note` redacts these
same words from the introspection. Scenario: ~/.claude-customers lists `acme`. A personal private repo
`git@github.com:andrelin/acme-notes.git` is cloned at ~/src/notes. work-context.sh resolves it as personal: andrelin is
an own owner, so the name is not matched against it, and the folder `notes` is not named for acme. A plan
`plan-acme-migration.md` is run there. `ai-log record` writes `"repo": "andrelin/acme-notes", "plan": "plan-acme-migration.md"`
and commits and pushes it to andrelin/ai-framework-log without refusing, and the test at test/test_ai_log.sh:828-878
never plants a customer term in the repo or plan name. Fix: add `.repo` and `.plan` (at personal level) to the strings
JQ_LEAK tests, and add a test.
Refuted: Downgraded from major by the verifier. The gap is real. In bin/ai-log, JQ_LEAK (768-774) tests only tools,
skills, agents, tokens, workflow phases, skills_outside and plugins. At personal level (1114-1122), repo_out and
plan_out are the plain owner/name and plan basename. work-context.sh customer_org skips an own owner (`(( ! own ))`),
and customer_dir matches folder names, not the repo name, so `andrelin/acme-notes` in a folder named `notes` resolves as
personal and its name reaches the entry. I downgrade it for three reasons. The plan (Task 15, R6-33) explicitly decides
that 'personal level keeps' repo and plan names. The path needs a personal repo or plan named after a listed customer,
which is unusual. The destination is the private log repo. It still breaks the 'free of customer details' bar and is
cheap to fix by adding .repo and .plan to the leak check, so it stays as minor.
Fixed: `JQ_LEAK` checks `repo` and `plan`; tested.

### R3-22 · minor · security and work context

bin/ai-log:367, bin/ai-log:769: `by_agent_type` keys (and the per-session copies) come from each agent's `.meta.json`
`agentType`. At personal level rn_agent stores a custom type by name, but JQ_LEAK's `names` does not include
`by_agent_type`, so the customers-file refusal misses this field. Scenario: At personal level a Workflow script spawns
agents with a custom agentType `acme-reviewer`, and ~/.claude-customers lists `acme`. No Agent tool_use in the main
transcript names that type, so `.agents` never carries it. `.totals.by_agent_type."acme-reviewer"` is written and
pushed, although the tip and exit-code text promise that a record is refused when an 'agent' name holds a customer.
Refuted: Confirmed: by_agent_type (bin/ai-log:367) is keyed by rn_agent of the meta agentType, which keeps a custom name
at personal level, and JQ_LEAK's `names` leaves out by_agent_type. The window is narrow. Workflow agents' meta in the
fixtures is `workflow-subagent`, and a custom type spawned through the Agent tool also shows in `.agents`, which is
checked. A type seen only in meta, for example when the spawning tool_use falls outside the window, still slips past the
refusal, contrary to its message. It is real and cheap to fix, so it stays minor.
Fixed: with R3-1.

### R3-23 · minor · security and work context

bin/ai-log:215, bin/ai-log:271: At personal level the model id goes through `okname`, which accepts `:` and `/`. A
Bedrock ARN or inference-profile id, with its AWS account number and region, is stored as a `tokens` key and in `agents`
keys. Only company level narrows it (okmodel), and no personal-level test covers the account number. Scenario: A
personal repo session runs Claude through Bedrock on an employer's or client's AWS account, model
`arn:aws:bedrock:eu-north-1:123456789012:inference-profile/...`. `record` pushes
`"arn:aws:bedrock:eu-north-1:123456789012:..."` into the entry's totals.tokens keys. The account number is an
infrastructure identifier that the 'no free text / customer details' bar is meant to keep out.
Refuted: Confirmed: at personal level okmodel falls back to okname (bin/ai-log:270-271), whose class allows `:` and `/`,
so a full Bedrock ARN with its account number is stored as a key. The company-level narrowing is a deliberate choice,
and the plan allows model ids in entries. Personal sessions on a client's Bedrock account are uncommon, and the log repo
is private. The same narrowing could be applied at every level at no cost, so it stays minor.
Fixed: `okmodel` narrows at every level; a personal-level ARN becomes `unknown`.

### R3-24 · minor · security and work context

test/test_ai_log.sh:599-735, test/test_workflow_docs.sh: The redaction fixtures in this personal public repo use
registrable real-world domains: `bigco.no`, `gc.no`, `portal.no`, `kunde.pl`, `kunde2.co.uk`, `api.kunde.no`,
`mail.docs.de`, `www.gitlab.zzcorp.net`, `unlisted.no`, `portal.klient.rs`. The plan's global constraint requires
`example-client` and `example.com` in fixtures. Scenario: Global constraints: 'No customer names, hostnames ... anywhere
in a tracked file, test fixtures included. Use example-client and example.com in fixtures.' Some of these domains belong
to real organisations, and the repo publishes them as 'customers' in a test of customer redaction. Labels under
`.example`/`.test` TLDs (for example `bigco.example.no`-style `*.example`, or `*.test`) would test the same paths.
Refuted: Confirmed: the added fixtures in test/test_ai_log.sh use non-reserved, registrable domains (bigco.no, gc.no,
portal.no, kunde.pl, kunde2.co.uk, api.kunde.no, mail.docs.de, <www.gitlab.zzcorp.net>, portal.klient.rs, unlisted.no).
They appear as customer entries in a personal public repo. That violates the plan's global constraint ('Use
example-client and example.com in fixtures'). Reserved names such as *.example or*.test would exercise the same host
and TLD paths. It stays minor.
Fixed: reserved names (`*.example`, `*.test`, `*.invalid`) replace the registrable domains.

### R3-25 · nit · security and work context

bin/ai-log:194-205: require_clone only checks that AI_LOG_DIR is the top of some git clone. It never checks that its
origin is the private `andrelin/ai-framework-log`, or that it is private, before `record` and `note` push to it without
asking. Scenario: AI_LOG_DIR is pointed, or left by a mistaken clone, at another repo, such as a public one. Every
plan's entries and introspections are then committed and pushed there on the standing yes, which covers only the private
log repo (§ Approvals, 2026-11-05). A one-time `gh repo view --json visibility` or origin check would catch this.
Refuted: Confirmed: require_clone (bin/ai-log:194-205) only checks that AI_LOG_DIR is the top of some git clone, and
record then commits and pushes (1180-1184) without checking origin or visibility. AI_LOG_DIR can be overridden from the
environment (line 65). The failure needs a misconfigured or wrongly cloned directory, so this is defense in depth, and
nit is the right severity.

### R3-26 · minor · plan conformance

claude/docs/work-contexts.md:87: The Task 17 reword says `reviewing-in-rounds` "makes at most two commits, Completion's
and a tracked plan's `git rm -f`". But Completion step 2 (claude/skills/reviewing-in-rounds/SKILL.md:87) makes one
commit per task when the Files lists are disjoint, so Completion alone can make several. Scenario: A plan with three
disjoint tasks reaches Completion and gets three per-task commits plus the `git rm -f` commit, four in all. A reader of
work-contexts.md takes "at most two" as the limit and treats the third and fourth commits as a skill overstepping its
approval. Task 17 asked only that the session-end commit be named as the one exception; it did not ask for a new count.
Fixed: work-contexts.md names the commits without a count.

### R3-27 · minor · plan conformance

bin/ai-log:22-27: Exit 1 grew two cases that Task 15 and 15b never recorded: `record` refuses when a tool, skill, agent,
model, plugin or workflow-phase name holds a `~/.claude-customers` name, and `note` at company level fails when it can't
find the plan. There is also SSH-alias origin normalisation (`github.com-personal` reads as `github.com`). Task 15's
**Interfaces** still lists exit 1 as only: no plan, a stale commit, no session, no assistant record. Scenario: This
breaks the implementing-plans and writing-plans rule "never edit a task's spec to match what was built without saying so
in that task". Task 13 folds the plan and then deletes it, and Follow-up 15c/15d are later written from its Interfaces.
Those consumers would not know that `record` can exit 1 with nothing written on a personal or company repo, so a skill
step that treats exit 1 as "no session" would misreport it. The deviations may be in the code-review findings file,
which this review was barred from opening. If so, the task sections still lack the inline note.
Fixed: the exit-1 cases and the alias normalisation are noted as a deviation in Task 15's Interfaces.

### R3-28 · nit · plan conformance

claude/docs/session-end-save.md:16: The doc adds two steps that are neither in Task 17's Change nor among its recorded
deviations: stop if `HEAD` is detached or the branch is not the plan's, and prepend `<!-- DOCTOC SKIP -->` to a plan
file before adding it (lines 27-28). The public-repo check is covered by the R2-16 ruling in § Approvals; these two are
not. "The branch is not the plan's" is also undefined, since a plan does not have to name its branch. Scenario: A
session end on a plan that names no branch has no way to apply the stop check: either it stops every time, or it never
does. The doctoc step rewrites the user's plan file, which Task 17 does not cover, and no deviation line in Task 17
records it for the final review to check.
Refuted: Downgraded from minor by the verifier. Downgraded. The claim that "the branch is not the plan's" is undefined
is wrong: implementing-plans step 4 (SKILL.md:46) defines the plan's branch as the plan file's name minus `plan-` and
`.md`. So the scenario of a check that cannot be applied fails. What remains is that two how-level additions are not
recorded in Task 17's deviation line: the detached-HEAD/branch stop and the doctoc-marker prepend. The doctoc step
exists so the specified `git add` and commit can pass this repo's pre-commit hook. It is an unrecorded deviation in how,
not a wrong result.

### R3-29 · nit · plan conformance

claude/skills/implementing-plans/SKILL.md:295: The bullet "A task's `git mv` runs in the session" (commit 5b563f3) is in
the diff under review but belongs to no task. Unlike the writing-plans learning that the Handover records, the plan does
not mention it. Scenario: This is an unrecorded addition to a stage skill. A reviewer checking each change in the diff
against a task or an approval finds no source for this one. Recording it as a filed learning would close the gap.
Refuted: Dropped by the verifier. Commit 5b563f3 is a filed learning, a separate commit whose message gives its cause:
auto mode blocks a subagent's git mv. filing-learnings changes are not plan tasks, and no plan or skill requirement says
every filed learning must appear in the plan. The Handover mentions the earlier writing-plans learning only as
information. This violates no requirement and has no failure scenario.

### R3-30 · nit · plan conformance

claude/rules/writing-code.md:8-32: Task 16's Change lists 11 globs to add. The diff also adds `*.mjs`, `*.cjs`, `*.mts`,
`*.cts`, `*.razor`, `*.cshtml`, `*.cc`, `*.cxx` and `*.hpp`, and no deviation is recorded for them. They fit the user's
"C# plus the common languages", but they are scope beyond the listed spec. Scenario: Plan conformance: Task 16 has no
line saying these globs were added. The test in test/test_workflow_docs.sh:77 pins them, so they are tested, just not in
the plan.

### R3-31 · nit · plan conformance

claude/skills/implementing-plans/SKILL.md:134-135: The landing rule in Task 17's paragraph falls at counted lines
101-102, past the first 100. Only the trigger and the pointer (counted 99-100) are inside. Task 17 calls the landing
rule part of that one short paragraph, and Task 16 requires everything needed to do the task in the first 100 counted
lines. Scenario: An agent that stops reading at the first 100 counted lines misses "never a fast-forward" in this skill.
It is still in session-end-save.md § Landing and in reviewing-in-rounds step 8, so this matters little.
Refuted: Dropped by the verifier. I confirmed the counted positions: trigger and pointer at counted lines 99-100,
landing rule at 101-102. But Task 17's Line budget bullet in the plan scopes the requirement explicitly: "The trigger
and the pointer are needed, so they sit within those 100". It does not require the landing rule there. Landing is
carried out by reviewing-in-rounds Completion step 8 and session-end-save.md § Landing, not by this skill. The layout
conforms to the plan.

### R3-32 · nit · plan conformance

claude/skills/reviewing-in-rounds/SKILL.md:104: Step 8 names `session-end-save.md` bare, where elsewhere
(claude/skills/implementing-plans/SKILL.md:133) it is `~/.claude/docs/session-end-save.md`. This is the same
bare-sibling naming that Task 13 already recorded as Deferred for the docs. Scenario: An agent running Completion in a
repo other than the dotfiles cannot resolve a bare `session-end-save.md`, so it cannot open § Landing for the `git rm -f`
command.

### R3-33 · major · the change as a whole

.github/workflows/tests.yml:4-15: The CI Tests workflow ignores pushes that change only `claude/skills/**`,
`claude/docs/**`, `claude/rules/**` or `**.md`. Those are exactly the files the new `test/test_workflow_docs.sh` and
parts of `test/test_ai_log.sh` guard: the session-end-save.md wording, the `ai-log record <plan-file>` line in
reviewing-in-rounds, the session-end pointer within implementing-plans' first 100 counted lines, and writing-code.md's
globs. So the tests exist, but CI can't fail for the changes they are meant to catch. Scenario: A later commit touches
only claude/skills/reviewing-in-rounds/SKILL.md and drops step 7's `ai-log record <plan-file>` line, or moves the
session-end pointer in implementing-plans past counted line 100. The Tests workflow never starts on that push, and
Markdown CI checks only lint and length. CI stays green while the workflow silently stops recording, which breaks the
repo rule that CI fails hard.
Refuted: Not refuted. tests.yml paths-ignore lists claude/skills/**, claude/docs/**, claude/rules/**and**.md. The new
test/test_workflow_docs.sh exists only to guard wording in exactly those files: session-end-save.md, implementing-plans,
reviewing-in-rounds, writing-code.md and writing-plans. The filter is older than this branch, but the new test is what
opens the gap. A push that touches only those docs never runs it, and markdown.yml only lints and checks length. That
breaks the repo's 'CI fails hard' rule for the requirement the test was written for.
Fixed: with R3-8.

### R3-34 · major · the change as a whole

claude/docs/session-end-save.md:3-6 (with claude/skills/reviewing-in-rounds/SKILL.md § Completion step 1): The
session-end trigger is defined only in implementing-plans, and the save commits only the index plus the plan files.
During the final `reviewing-in-rounds code` run, which implementing-plans starts in the same session, a fix is an
unstaged edit until Completion stages it. A wrap-up in the middle of a review therefore commits and pushes the findings
file with `Fixed:` entries, but not the fixes those entries describe. Neither doc names this case. Scenario: A long
final code review (15+ rounds are expected) has rounds 1-4 fixed, and the user asks to wrap up. The save adds
plan-x-review-findings-code.md (with `Fixed:` lines), commits and pushes. The fixes stay unstaged on this machine.
Another machine runs `git pull` and resumes: the findings file says R1-3 is fixed, but the code isn't. Completion step
1's 'leftovers that weren't leftovers before round 1' also can't be computed in a new session.
Refuted: One part is refuted. 'Completion step 1's leftovers can't be computed in a new session' is wrong, because step
6 writes `Leftovers before round 1:` into the findings file so that a resumed session has it. The main point stands.
implementing-plans runs the final code review in the same run, and a wrap-up during it is a session end by its own
definition. session-end-save step 2 adds only the plan and findings files, and 'Leftovers ... stay unstaged and are
never pushed'. Review fixes are therefore not pushed, while the pushed findings file marks them `Fixed:`. 'What a resume
sees' only covers a half-done task restarting from the plan, so another machine resumes with findings that say fixed and
code that isn't. Neither doc names this case.
Fixed: a save during a code review also adds the review's fixes; Completion step 1 says committed fixes aren't leftovers.

### R3-35 · minor · the change as a whole

claude/CLAUDE.md:76-77: The adopted § Approvals-era line says 'In chat and markdown files, name an issue or PR by repo
and title ... never a bare #900'. Existing skills still prescribe a bare number in markdown files: writing-plans § What
each task carries (`## Task 2 · #53: …`, and its intake reads a heading's issue number), writing-follow-up-items:48/80
and setting-up-follow-up-trackers:44-47 (tracker headings with `#412` / `PR #412`). The repo CLAUDE.md:31 also names the
dashboard as a bare **#3**. Scenario: Writing a plan whose task has an issue, the agent must either follow writing-plans
and write `## Task 2 · #53:` (breaking the global rule) or write `dotfiles#53 (title)`. In the second case it breaks the
heading format that writing-plans' intake and the follow-up skills parse ('a heading carrying an issue number is read as
that issue'). One of the two instructions gets broken on every plan or tracker item that has an issue.
Refuted: Downgraded from major by the verifier. Downgraded. The conflict is real. The new claude/CLAUDE.md:76 says
'never a bare #900' in markdown files, while writing-plans:79 prescribes `## Task 2 · #53: …` and the follow-up tracker
skills prescribe `PR #412`. These are parsed heading formats in temporary or personal files, though, and the plan's
`Target:` line resolves the repo (writing-plans:21). An agent will follow the more specific skill, so the outcome is a
bare number in a plan heading that gets deleted, not a broken parse or a wrong result. Cheap to live with until the
global rule names the exception.
Fixed: writing-plans uses `dotfiles#53`, a bare number in an older plan reads the same; the repo CLAUDE.md says dotfiles#3.

### R3-36 · minor · the change as a whole

test/ai-log/plan-example.md:1, test/ai-log/plan-example-review-findings-*.md:1-3: The four new markdown fixtures carry
neither `<!-- DOCTOC SKIP -->` nor doctoc markers, and they fail markdownlint MD022 (no blank line after the `### R1-1 …`
headings). The Markdown CI step and the doctoc opt-in check both cover `test/`. On commit, the pre-commit hook will
insert a doctoc ToC and blank lines into the fixtures. I checked in a scratch copy: test_ai_log.sh still passes after
that rewrite. The fixtures change shape silently, though, and if the hook's tools are missing the push fails CI.
Scenario: The fixtures are committed on a machine where doctoc or markdownlint-cli2 isn't installed, or the hook is
skipped. CI's `markdownlint-cli2 '**/*.md'` reports 6 MD022 errors, and the doctoc opt-in step lists all four files, so
Markdown CI fails. With the hook installed, the fixtures instead gain a generated ToC they were never meant to have.
Refuted: Confirmed with one correction to the mechanism. markdownlint-cli2 reports 6 MD022 errors across 3 of the
fixtures, and none of the 4 carries a doctoc marker or `<!-- DOCTOC SKIP -->`. The finding is wrong that the hook would
quietly add a ToC. The pre-commit hook (lines 37-48) checks every tracked .md outside claude/, staged files included,
and exits 1 on a missing marker, so the commit is rejected. Bypassing the hook makes Markdown CI's opt-in step and
markdownlint fail. The fix is trivial (add SKIP and blank lines), so minor stands.
Fixed: `<!-- DOCTOC SKIP -->`, titles and blank lines; markdownlint clean.

### R3-37 · nit · the change as a whole

bin/ai-log:291 (framework.dotfiles_commit) with claude/docs/session-end-save.md § Landing: Plan assumption, never
revisited after Task 17's landing decision: each entry records the framework as `dotfiles_commit`, which Follow-up 15d
is meant to group trends by. Since Task 17, work in dotfiles itself lands by a squash-merged PR. Every entry recorded
during a dotfiles plan (session ends, the final record) therefore names branch commits that become unreachable once the
branch is deleted after the squash merge. The same applies to the entry's `commit`. Scenario: This run's own entries
record dotfiles_commit = 5b563f3… and later ai-framework commits. After the squash merge and branch deletion, 15d's
'grouped by framework commit' can't resolve those shas to any state of main, so per-framework trends for dotfiles' own
work fall into ungroupable buckets.
Refuted: Downgraded from minor by the verifier. Downgraded. Grouping by dotfiles_commit is grouping by a sha string, and
it needs no reachable commit. Every in-progress branch commit is a real, distinct framework state, so it is correctly
its own bucket. Branch commits pushed through a GitHub PR also stay fetchable via refs/pull/`<n>`/head after the squash
merge and branch deletion, so they can still be resolved and ordered when 15d needs to. What remains is a convenience
gap in mapping to a state of main, which only affects dotfiles' own plans.

### R3-38 · minor · the change as a whole

bin/ai-log:416-421: The plan assumed every findings heading has the form `### R<n>-<m> · <severity> · <lens>`. The real
data proved that wrong: 18 headings of the older `### R12-5 · refuted` form exist in this plan's own findings files.
They now only warn, so the first real entry for this plan (Task 15b's end to end, the introspection's 'rounds and majors
per review kind') undercounts this plan's findings. A dry run here still prints `warning: 18 review-log or findings heading(s) could not be parsed`.
The gap is accepted, but the introspection evidence for this plan rests on incomplete counts. Scenario: The final
review's step 7 runs `ai-log record plan-ai-framework.md`. The entry's `findings` omits 18 findings, and the
introspection's evidence ('majors per review kind') is drawn from the partial numbers.
Refuted: Not refuted. `ai-log record --dry-run plan-ai-framework.md` prints 'warning: 18 review-log or findings
heading(s) could not be parsed'. parse_findings (bin/ai-log ~418) counts any heading that doesn't match `### R<n>-<m> · <sev> · <lens>`
as bad and leaves it out of the findings. The gap is warned about and accepted, so minor, but this plan's recorded
counts are incomplete.
Fixed: the status form (`refuted`, `note`, `out of scope…`) is a known dropped-finding heading, not warned or counted.

### R3-39 · minor · the change as a whole

bin/ai-log:303: A Task 15 `Deferred:` item is still open after this review: an `Agent`/`Task` call whose `subagent_type`
fails `okname` is counted as `general-purpose`. The other Task 15 deferrals I checked are handled: okmodel narrows ARNs
at company level, `while … < <(jq …)` failures now reach exit 3 and are tested, and the after-write ERR-trap message is
tested. This one needs to go into Task 13's issue as the plan says. Scenario: A run that dispatches a custom agent type
with a name okname rejects has its tokens and counts reported under `general-purpose/<model>`. That inflates the
built-in's numbers in 15d's cut-candidate analysis.
Refuted: Not refuted. bin/ai-log:303 is `(($in.subagent_type | okname) // "general-purpose")`. A subagent_type that is
present but fails okname (over 100 characters, or containing spaces or other characters) is filed under general-purpose
instead of 'unknown'. That is rare, because okname accepts typical agent names, but it is real and still open as a
Deferred item.
Fixed: a present but rejected `subagent_type` is `unknown`; tested.

### R3-40 · minor · the change as a whole

claude/skills/reviewing-in-rounds/SKILL.md:103-105, claude/docs/staged-workflow.md:64: Step 8 makes the tracked plan's
`git rm -f` commit conditional only via 'Before it', which refers to the squash-merged PR of 'a branch holding
session-end commits'. writing-plans:122-124 requires that commit for any tracked plan before its branch merges. A branch
with a tracked plan but no session-end commits has no step in Completion that removes it. This is related to Task 13's
Deferred item 'holds only for a branch with session-end commits', which is still open in staged-workflow.md:64.
Scenario: A personal repo where the plan was tracked by hand and the whole plan ran in one session (no session-end
commit) reaches Completion. Step 8's condition doesn't hold, so no `git rm -f` commit is offered. The branch is then
merged with the plan file in it, against writing-plans § Plans are temporary.
Refuted: Not refuted. reviewing-in-rounds step 8 makes the `git rm -f` commit hang off 'Before it', meaning the
squash-merged landing of 'a branch holding session-end commits'. staged-workflow.md:64-65 and writing-plans:120-122
require the removal for any tracked plan before the merge. A tracked plan that ran in one session with no session-end
commit has no Completion step that clearly requires the removal. The wording is ambiguous rather than certainly wrong,
so minor.
Fixed: step 8 and staged-workflow.md apply to any tracked plan, still only on a yes.

### R3-41 · nit · the change as a whole

claude/docs/work-contexts.md:157: It says `reviewing-in-rounds` and the save run `ai-log` 'at every level but customer'.
reviewing-in-rounds step 7 says to run it 'at every level', and it prints the deferral line at customer level. The two
say different things about the same step. Scenario: An agent at customer level reading work-contexts.md skips `ai-log record`
while the skill says to run it. The outcome is the same today, because record defers, but the texts disagree.

### R3-42 · nit · the change as a whole

claude/docs/staged-workflow.md:82, claude/docs/work-contexts.md:168, CLAUDE.md:22: Task 13's Deferred wording items are
still present: 'AI review anchors the human reviewer there' reads backwards; 'any other exit lets the call through'
comes before exit 2 is named; 'the workflow skills' in the repo CLAUDE.md is undefined; sibling docs
(`implementing-plans-reference.md`, `review-lenses.md`, `session-end-save.md`) are named bare instead of by
`~/.claude/docs/…`. The superpowers row's reason has been added, so that item is settled. Task 17's Deferred red flag
'Only the session-end commit exists.' (implementing-plans/SKILL.md:145) still reads wrong at customer level. Task 16's
tip still says 'its first 100 lines hold the task' (tips/24_claude_code.md:87), which can read as the description's
lines. Scenario: These are wording only, named in the plan. They must go into Task 13's issue, or they are lost when the
plan is deleted.
Refuted: The cited items are all still present. staged-workflow.md:82 has 'AI review anchors the human reviewer there'.
work-contexts.md:100 has 'any other exit lets the call through' (line 100, not 168). CLAUDE.md:22 has 'the workflow
skills'. implementing-plans:145 has 'Only the session-end commit exists.' tips/24_claude_code.md:87 has 'its first 100
lines hold the task'. All are wording only.

### R3-43 · minor · fit with the surrounding code

claude/docs/work-contexts.md:87: The new line says `reviewing-in-rounds` "makes at most two commits, Completion's and a
tracked plan's `git rm -f`". That contradicts the skill next to it: Completion step 2
(claude/skills/reviewing-in-rounds/SKILL.md:86-89) makes one commit per task when the Files lists are disjoint. Line
85's "bar one exception" also undercounts. The paragraph goes on to list the session-end commit, Completion's commits,
the plan-removal commit and ai-log's commits to the log repo. Scenario: A three-task plan with disjoint Files lists
reaches Completion. The skill offers three per-task commits plus the `git rm -f` commit, four in all. A reader or
reviewer who checks against work-contexts.md (the doc the global CLAUDE.md sends them to for how a level applies) finds
"at most two" and either flags correct behaviour or squeezes the work into one commit.
Fixed: with R3-26.

### R3-44 · nit · fit with the surrounding code

bin/ai-log:118-157: `normalize_origin` copies the guard's `parse_url` (claude/hooks/work-context.sh:218) under another
name. Its own comment says it reads Azure DevOps paths "as the guard's parse_url reads it". The two copies already
differ: `parse_url` accepts only ssh, git+ssh, ssh+git, https, http and git schemes and needs a `/` after the host.
`normalize_origin` takes any `scheme://` and does extra alias folding. ai-log already shells out to `work-context.sh level`,
so it could get the host and owner from a subcommand there instead of a second parser that drifts on its own. Scenario:
A later fix to the guard's URL parsing changes only `parse_url`, for example a new Azure or GHE path form. `ai-log level`
then works out host/owner by the old rules while the guard uses the new ones. For a `file://` or other odd-scheme origin
the guard refuses to parse, ai-log still builds a host/owner and checks it against the allow file, so the two disagree
on the level of the same repo.
Refuted: Downgraded from minor by the verifier. Downgraded. compute_level (bin/ai-log:164-187) takes the level from
`work-context.sh level` first. normalize_origin's host/owner is only used afterwards, as an extra allow-list gate when
the guard said personal or company. Any parser drift can therefore only make ai-log stricter (customer, nothing
recorded), never record a repo the guard calls customer. The file:// case gives an empty or unlisted host/owner, so it
lands on customer. normalize_origin also has a separate job, a lowercase, alias-folded id that is stable across machines
(used in h12 keys and repo_name), which parse_url does not provide, and the guard has no host/owner subcommand to call.
The duplication is real but the harm is limited to a fail-safe mismatch.

### R3-45 · nit · fit with the surrounding code

bin/ai-log (19 sites, e.g. :198, :801, :822): Redirections are written in shfmt `-sr` style, `2> /dev/null`, `> /dev/null`.
Every other script in bin/ (ai, check-md-limits, check-hidden-unicode, skill-trigger-eval, dotfiles) writes
`2>/dev/null`. The new script doesn't match its neighbours, including bin/ai, whose `die`/`usage` shape it otherwise
copies. Scenario: Requirement: naming and idiom match the neighbouring code. A grep for `2>/dev/null` across bin/ now
misses ai-log, and the next edit to either style mixes the two in one file.
Refuted: Dropped by the verifier. The premise is false. bin/dotfiles already uses `2> /dev/null` (1 site) beside
`2>/dev/null` (4 sites), and no shfmt config or formatter in the repo enforces either style. bin/ already mixes the two,
so no neighbouring idiom is violated, and nothing fails.

### R3-46 · nit · fit with the surrounding code

test/test_workflow_docs.sh:95: It defines `gitin` with a fixed repo and identity (`gitin <git args>`).
test/test_ai_log.sh:27 defines a helper with the same name and a different signature (`gitin <dir> <git args>`). Two
test helpers share a name but take different arguments. Scenario: Someone copies a `gitin "$LOG" rev-list …` line from
test_ai_log.sh into test_workflow_docs.sh (or the reverse). In the workflow-docs version the directory is passed to git
as a subcommand, so git fails with "'/tmp/…' is not a git command" and nothing points at the helper mismatch.

### R3-47 · nit · fit with the surrounding code

test/test_ai_log.sh:172: `edit_plan() { … }` is the only function in the new test, and in both new test files, declared
without the `function` keyword. Every other helper there (gitin, commit_at, make_tree, run_ai, j, ord_of, …) uses
`function name() {`. Scenario: Requirement: idiom matches the neighbouring code in the same file. The one-off style
makes `grep '^function '` miss this helper.
Refuted: Dropped by the verifier. The claim is false. test_ai_log.sh:605 `run_note_home2() { ... }` also lacks the
`function` keyword, and neighbouring tests (test_check_md_limits.sh:619, test_jdk_versions.sh, test_ruby_path.sh) use
the bare `name() {` form throughout. The repo mixes both, so this is not a one-off that breaks an idiom.

### R3-48 · nit · fit with the surrounding code

claude/docs/session-end-save.md:3: The pointer back into the skill says `implementing-plans/SKILL.md` § *Finish*, but
the section is "Finish with the final review, in this run". In that same skill (line 77), "§ *Finish*" names superpowers
SDD's own § Finish, which the skill overrides. Scenario: A reader following the doc's back-reference searches the skill
for "§ *Finish*". The first hit is the "Overridden in SDD 7.0.0" paragraph, which is about the other skill's section,
not the session-end trigger.

### R3-49 · nit · fit with the surrounding code

tips/24_claude_code.md:87: The rewritten sentence says "a file nearing its aim gets a note". The checker notes a file
only once it is past its aim (claude/docs/markdown-limits.md: "warns at the aim"; a 100-line non-skill file is clean,
101 gets NOTE in test_check_md_limits.sh). "A `VENDORED.md` directory is skipped" also loses the old "a directory
holding a `VENDORED.md`" sense. Task 16's Deferred line covers the old "Nearing a cap" wording, but this reword brings
in the same mistake again with the aim. Scenario: A user reads the tip, keeps a doc at 99 lines expecting a note when it
gets close, and is surprised when nothing appears until it passes 100.

### R3-50 · minor · docs ship with the change

claude/skills/writing-plans/SKILL.md:79: The new global rule (claude/CLAUDE.md:76, adopted 2026-11-09) says that in chat
and markdown files an issue or PR is named by repo and title, never a bare #900. writing-plans still tells the author to
put the bare number in a plan heading (`## Task 2 · #53: …`). The rule changed but the skill that states the old form
was not updated. Scenario: An agent writing a plan file, which is markdown, follows the skill and writes `## Task 2 · #53: …`.
That breaks the global rule, and the next reader of the plan cannot tell which repo #53 belongs to, which is the problem
the rule was adopted to fix.
Fixed: with R3-35.

### R3-51 · minor · docs ship with the change

claude/skills/setting-up-follow-up-trackers/SKILL.md:44-47: The tracker skills still prescribe a repo-less `PR #412` /
`issue #373` form in follow-up trackers, which are markdown files: setting-up-follow-up-trackers:44-47,
writing-follow-up-items:48 ("shipped by #442") and writing-follow-up-items:80. The new claude/CLAUDE.md:76 rule asks for
repo and title in markdown files. The two instructions conflict, and neither says which one wins. Scenario: An agent
adding a tracker item writes `PR #412` in the heading because the skill says to, while CLAUDE.md says never to use a
bare number. Different sessions will resolve the conflict differently, so trackers end up with mixed reference forms.
Fixed: the tracker skills use `dotfiles#412`, a bare number in an older tracker reads the same.

### R3-52 · nit · docs ship with the change

CLAUDE.md:31: The repo CLAUDE.md still names the Renovate dashboard as a bare `**#3**`. That is a markdown file, so it
breaks the new global rule in claude/CLAUDE.md:76 (e.g. `dotfiles#3 (dependency dashboard)`). Scenario: A session that
reads both files sees the repo's own instruction file break the global convention, which weakens the rule. It is also
the one bare reference in instruction text that the rule's adoption should have swept.
Refuted: Downgraded from minor by the verifier. Downgraded. The bare **#3** in this repo's own CLAUDE.md only ever
refers to this repo's tracker, so no reader can mistake which item it means. The finding's scenario ('weakens the rule')
names no wrong result. It is a wording inconsistency with the new rule, nothing more.

### R3-53 · minor · docs ship with the change

tips/24_claude_code.md:146: Task 17 made `ai implement` runs commit `Work in progress: Tasks …` and push the branch at
every session end, without asking, at personal and company level. A branch with those commits must then land by a
squash-merged PR. Tip 24.8, the user-facing doc for `ai`, still says the session stops only for your decisions. It does
not mention the automatic commit and push, the squash-PR landing, or that resuming on another machine needs `git switch <branch> && git pull`
(plus a hand-copied plan at company level). The plan's "No script, so no tip" skips a user-visible behaviour change.
Scenario: A user runs `ai implement plan-x.md` on a company repo and ends the session. Their branch now has a pushed WIP
commit they did not expect, and nothing in tips/ explains it. Later they fast-forward `main` to the branch and put the
WIP commits on the default branch, which the docs forbid only in agent-loaded files.
Fixed: tip 24.8 covers the session-end commit and push, resuming elsewhere and the squash-merged landing.

### R3-54 · minor · docs ship with the change

tips/24_claude_code.md:79-83: `bin/check-md-limits` gained a user-facing `--count-raw` option, documented in its usage
header and tested in test/test_check_md_limits.sh:760-778. Tip 24.5's command block and text don't mention it. That
violates the repo's "Docs ship with the change" convention for a changed `bin/` script signature. Scenario: A user who
wants to see how many lines a skill counts toward its 250 cap, or toward its first 100, runs `tips` and finds no way to
do it. The option is visible only by reading the script.
Fixed: tip 24.5 lists `--count-raw`.

### R3-55 · nit · docs ship with the change

claude/docs/work-contexts.md:79-90: The section heading and its opening paragraph still say an approval covers one
action, not a policy: "Ask again, every time, however recently they said yes". The new paragraph right below introduces
standing yeses: the session end's commit and push, and ai-log's commit and push to the log repo. Nothing reconciles the
two. It also says "bar one exception" but then lists two writes made without a per-action yes (the session-end commit
and push, and ai-log's log-repo commit and push). The global claude/CLAUDE.md § Approvals ("An approval covers what it
names — never its neighbour or the next one") was not updated either. Scenario: An agent at a session end reads the §
Approvals rule and this section's first paragraph and stops to ask before the WIP commit and push. That defeats the
standing rule. Or it reads the standing yes as a precedent for other policies. Either way the convention change is
stated in only one of the two places that state the rule.
Refuted: Downgraded from minor by the verifier. Downgraded. The global § Approvals says an approval covers what it
names. The ai-log yes of 2026-11-05 names record and note writing to the log repo, so it is consistent with that rule.
The 'one action, not a policy' section is about waivers of rules. The session-end commit is the skill's own design, and
the skill says 'without asking', so the claimed scenario of an agent stopping to ask is unlikely. What remains is
wording: the heading's absolute phrasing, and 'bar one exception' followed by a second write that needs no per-action
yes.

### R3-56 · minor · docs ship with the change

claude/skills/writing-plans/SKILL.md:96-98: A plan's work may now get session-end commits, and such a branch must land
by a squash-merged PR (session-end-save.md § Landing, reviewing-in-rounds step 8). The landing also needs a yes for the
plan's `git rm -f` commit. But the up-front approvals list in writing-plans, and the template's `## Approvals` in
claude/docs/plan-file-template.md, don't prompt for how the branch lands (PR, squash merge, who merges) or for the
plan-removal commit. The changed workflow convention is missing where approvals are gathered. Scenario: A personal-level
plan is approved with "commit to main", as earlier runs were. A session end then puts WIP commits on the branch, and the
driver has no recorded yes to open and squash-merge a PR. It must stop mid-landing to ask, which the approvals-in-bulk
rule exists to prevent. Or it falls back to the fast-forward that the docs forbid.
Fixed: writing-plans and the plan template ask up front how the branch lands and for the plan-removal commit.

### R3-57 · nit · docs ship with the change

tips/25_ai_framework.md:19-21: The tip's exit-code list gives exit 2 as "usage or a missing clone". bin/ai-log:27 also
exits 2 when `note` gets empty input or input missing a heading, which the tip leaves out. Scenario: A user who pipes an
introspection without `## Cut candidates` into `ai-log note` gets exit 2. The tip suggests that means a usage error or a
missing clone, which sends them to the wrong cause.

### R3-58 · nit · docs ship with the change

claude/docs/work-contexts.md:88: This line says `reviewing-in-rounds` and the save run ai-log "at every level but
customer". reviewing-in-rounds SKILL.md step 7 says the standing yes covers record and note "at every level", and ai-log
itself runs at customer level and prints its deferral line. The docs disagree on whether the step runs at customer
level. Scenario: A reader of work-contexts.md concludes the Completion step is skipped at customer level, while the
skill runs it there. That is harmless today because ai-log defers, but the two docs describe different behaviour.

## Round 4

### R4-1 · major · correctness and failure modes

bin/ai-log:893-908 (also tips/25_ai_framework.md:33): `record` only spots a reused plan name when it finds a deletion of
the plan with `git log --diff-filter=D <last entry's commit>..<sha> -- <plan>`. In the landing flow this branch
documents, that deletion never shows up in that range. Steps 7 and 8 of `reviewing-in-rounds` § Completion record the
entry and only then run the `git rm -f` commit, so the deleting commit comes after the last entry's commit and sits on
the old branch. A plan created on its branch, which is the normal case since the session-end save commits an untracked
plan there, is added and removed inside the same squash, so the squash commit on main never touches it. At company level
the plan is untracked and git never sees it deleted. The tip says the opposite: "A new plan reusing a deleted plan's
file name starts a new chain." Scenario: Plan `plan-ai-log.md` is created on branch A, recorded, removed with `git rm`
and squash-merged. Later a new plan with the same name starts on branch B, cut from main. When B runs `record`, `pdel`
is empty, so `after` names the old plan's last entry and the window starts where the old plan's last window ended. The
'this plan, every entry together' summary in `JQ_SUMMARY` then adds the old plan's tokens, rounds and majors to the new
plan's, and the introspection works from those inflated numbers. At company level this happens on every reused name.
Fixed: entries carry the plan's `Base:` sha as `plan_base`; a different Base starts a new chain, the deletion check the fallback; tested.

### R4-2 · minor · correctness and failure modes

bin/ai-log:144-146, 172-181: `normalize_origin` turns an SSH alias such as `github.com-personal` into `github.com`, and
the tip says such an alias 'reads as github.com'. The level, though, comes from `work-context.sh level`, which does not
resolve the alias. A personal repo cloned through the alias therefore comes out as `company`, and the allowlist then
accepts it because the normalised owner is `andrelin`. Scenario: Verified in a scratch repo: origin
`git@github.com-personal:andrelin/x.git` makes `ai-log level` print `company`, while `git@github.com:andrelin/x.git`
prints `personal`. For such a personal repo, `record` stores `repo` and `plan` as hashes and counts project skills,
custom agents and MCP tools as numbers only. `note` hunts for the plan by hash and redacts the plan's and branch's
words. The session-end save takes the company path and leaves an untracked plan out of the commit, so the plan never
reaches the push the next machine resumes from.
Refuted: Reproduced in a scratch repo. With origin `git@github.com-personal:andrelin/x.git`, both `work-context.sh level`
and `ai-log level` print `company`. With `git@github.com:andrelin/x.git`, work-context prints `personal`. The tip (lines
42-43) says the alias reads as github.com, which holds for chaining but not for the level. The error leans conservative:
it hashes and redacts more, not less. But it also leaves an untracked plan out of the session-end save, so minor stands.
Fixed: with R4-35: `normalize_origin` follows the guard's rules, so the alias and the level agree; the tip says so.

### R4-3 · nit · correctness and failure modes

claude/skills/implementing-plans/SKILL.md (Before staging: 'HEAD must equal its value at the run's start');
claude/docs/session-end-save.md:1-4: A session end can be triggered by 'a part-way report that asks the user nothing' or
by a request to wrap up. Either way it commits and moves `HEAD`, but nothing says that work carried on in the same
session after that is a new run with a new start `HEAD`. The 'Before staging' check still compares against the `HEAD`
from when the run started. Scenario: A run limited to Tasks 3–4 finishes and reports part-way. That counts as a session
end, so it commits `Work in progress: Tasks 3, 4` and pushes. The user replies 'carry on with 5' in the same session.
Before staging Task 5, the driver sees `HEAD` has moved since the run started and stops with 'a subagent ran git', a
false alarm, unless it happens to re-enter the skill as a fresh run.
Refuted: Downgraded from minor by the verifier. Downgraded. session-end-save.md defines a part-way report that asks
nothing as the end of the run. implementing-plans' description says to read it 'before resuming an implementation that
stopped part-way', so 'carry on with 5' is a resume and the Setup resume path takes a fresh start `HEAD`. The false stop
happens only if the driver ignores the skill's own trigger. At most the wording could say outright that a session end
ends the run.

### R4-4 · minor · correctness and failure modes

bin/ai-log:678-685: `add_folder_terms` redacts the folder names above the repo only when the repo is under `$HOME`.
Outside `$HOME` it adds just the last path component. Task 15b's spec is 'its folder's name and those above it up to
`$HOME`', so a customer-named parent folder of a repo outside `$HOME` is never a redaction term. Scenario: A company
repo checked out at `/srv/clients/acme/tooling` (Linux or WSL), with no `~/.claude-customers` entry yet. `note` adds
only `tooling` as a term, so a bare 'acme' in the introspection is not caught by the folder rule. It reaches the pushed
`.md` unless another pattern happens to match it.
Fixed: outside `$HOME` every path component is a term; tested.

### R4-5 · nit · correctness and failure modes

bin/check-md-limits (FRONT_MATTER_PERL, the blank-line test in front_matter_end): The shared `front_matter_end` now
allows blank lines inside front matter and rejects one only straight after the opening `---`. The old `long_lines` code
rejected any blank line, and the comment removed with it gave the reason: 'Note: something' is valid YAML, so only an
unbroken block tells front matter from prose. Both the length cap and the 150-character line check now trust looser
input. Scenario: A markdown file that opens with a thematic break, then `Note: ...`, a blank line, `Status: ...` and a
closing `---` now counts as front matter. Those lines are left out of the length cap and the 150-character line check,
where before the blank line would have kept them counted.
Refuted: Confirmed. front_matter_end now skips blank lines after line 1, and the diff removes the old comment's
reasoning ('Note: something' is valid YAML; real front matter is an unbroken block). The looser parse can exempt a
key-shaped prose block between two thematic breaks from the length checks. The input that triggers it is contrived and
the effect is limited to the length checks, so nit.

### R4-6 · nit · correctness and failure modes

bin/ai-log:247 (JQ_CAND `contains($bn)`), bin/ai-log:927: A session counts as naming the plan when the plan's basename
appears as a substring of a tool_use input, not as a whole word. Any longer file name that contains the basename pulls a
session into scope and can move the plan's first appearance earlier. Scenario: Plan `plan-x.md` alongside
`subplan-x.md`, or a `plan-x.md.orig` backup. A session in the repo that only ever touched `subplan-x.md` counts as in
scope for `plan-x.md`, and its tokens and turns go into that plan's entry.
Refuted: Confirmed. JQ_CAND uses `contains($bn)` and the hit scan uses `grep -F` on the bare basename, so `subplan-x.md`
or `plan-x.md.orig` match `plan-x.md`. The cwd filter still limits this to the same repo, and such sibling names are
rare, so nit stands.

### R4-7 · minor · tests

test/test_workflow_docs.sh:58: Task 17's main behaviour has no automated test. The commit/ref-delete/push sequence, the
resume invariants (no `refs/checkpoints/`, `git write-tree` equal to `HEAD^{tree}`, `Base:` an ancestor, leftovers
unstaged and not pushed, a second session end making a new HEAD) and the customer-level no-op were checked once by hand
(plan Task 17 Result). The suite only greps the doc for literal strings: `git commit --allow-empty -m`, `git update-ref -d`,
`keep every ref`, `git push -u origin <branch>`. Only the two `ls-files | xargs` commands are actually executed.
Scenario: Someone swaps steps 3 and 4 in session-end-save.md so refs are deleted before the commit, or deletes the refs
after a failed commit. Every literal is still present and the suite stays green, but a resume finds no checkpoint ref
and the index no longer equals `HEAD^{tree}`. The checkpoints are lost.
Fixed: ordering assertions: commit, then ref deletion (only for what the commit holds), then push and `ai-log record`.

### R4-8 · minor · tests

test/test_workflow_docs.sh:100: The company-level add command is built by the test (`${ADD_CMD/--others /}`), not read
from the doc. The doc line `At company level drop --others` is never checked, so the behavioural assertions at lines
~141-145 test the test's own string. Separately, the 'untracked excluded plan is not added' case writes `info/exclude`,
but without `--others` an untracked file is never listed whatever the exclude says, so that part of the setup proves
nothing. Scenario: session-end-save.md line 25 is reworded to 'At company level drop --cached' (wrong: a tracked plan's
edits would never be added). The suite still passes because ADD_CMD_CO comes from the test's own substitution.
Refuted: The main point stands. ADD_CMD_CO on line 100 is built by the test's own substitution, and no assertion reads
the doc's 'At company level drop `--others`' line (session-end-save.md:25), so rewording that line would go unnoticed.
One part is overstated: the info/exclude setup is not wholly idle, because it also excludes the tracked plan-x.md. That
shows a tracked plan still matching an exclude pattern is listed by --cached --exclude-standard, which is the real
company case. It is true that excluding the untracked findings file proves nothing without --others.
Fixed: the doc's 'At company level drop `--others`' line is asserted; a comment says what the exclude case shows.

### R4-9 · minor · tests

claude/skills/reviewing-in-rounds/SKILL.md:96: New Completion behaviour has no test. Step 4's 'Nothing staged
(session-end commits already hold every task): offer and run no commit' and step 1's 'A session end during the review
may already have committed fixes: those are no leftovers' are not guarded. test_workflow_docs.sh pins step 7's 'or when
there was nothing to commit' but not these two lines it depends on. Scenario: A later edit drops the 'Nothing staged'
line. Completion then offers an empty commit (or fails on one) after a session end has already committed every task, and
no test fails.
Refuted: Confirmed. reviewing-in-rounds/SKILL.md line 86 ('A session end during the review may already have committed
fixes') and line 96 ('**Nothing staged** ... offer and run no commit') have no assertion in either test file.
test_workflow_docs.sh line 74 pins only step 7's 'or when there was nothing to commit'. The cost of losing them is
small: the user can decline an offered empty commit, or it fails visibly. Minor is right.
Fixed: both lines pinned.

### R4-10 · minor · tests

test/test_workflow_docs.sh:86: Task 16's glob test restates the `paths:` list literally: it asserts each `"**/*.<ext>"`
line is present, exactly as written. That guards against a line being deleted, but not against a glob that never
matches, which is the failure the task fixes (a silent non-loading rule). The plan's load check (headless `.cs`/`.go`
loads the rule, `.md` does not) was run once by hand and is not repeatable in the suite. Scenario: Someone changes the
list's quoting or indentation, or Claude Code changes glob semantics so `**/*.cs` no longer matches a root-level file.
Every assertion still passes while the rule stops loading for C#, the same silent failure the user reported.
Refuted: Dropped by the verifier. The concrete scenario is wrong. Line 87 uses grep -cxF on the exact line '  -
"**/*.`<ext>`"', so a change to quoting or indentation makes that assertion print 0, not 1, and the suite fails. The
remaining case, Claude Code changing its glob semantics, cannot be caught in a shell suite. The plan scoped the headless
load check (claude -p) as a manual check and recorded its result, so no planned test is missing.

### R4-11 · nit · tests

claude/docs/session-end-save.md:23: The behavioural test of the personal-level add command never covers two cases the
doc relies on. First, a `-closed-` findings file ('closed ones included'). Second, an untracked plan that is gitignored:
`--exclude-standard` then silently skips it, and the test only checks that the flag is present (test_workflow_docs.sh
~line 103). Scenario: A personal repo whose global gitignore or `info/exclude` lists `plan-*.md` (for example one that
was once company, or set up by habit) reaches a session end. The untracked plan is not added and never reaches another
machine, which contradicts the doc's 'At personal level an untracked one too'. No test notices, and the report says
nothing because the command exits 0.
Refuted: Downgraded from minor by the verifier. Downgraded. The `-closed-` case is matched by the same
':(top)`<stem>`-review-findings-*.md' pathspec that the test already runs with plan-x-review-findings-code.md, so a
separate case adds little. The gitignored-plan scenario at personal level is hypothetical: the user's global ignore
(link/.gitignore_global) lists no plan-* pattern. A company repo excludes plans only through its own info/exclude.
--exclude-standard is deliberate there, and the test pins that it is present. What remains is a missing doc caveat and
test, not a plausible failure.

### R4-12 · nit · tests

test/test_ai_log.sh:1249: The doc and skill guards are duplicated between test_ai_log.sh (lines 1237-1258) and
test_workflow_docs.sh: `ai-log record <plan-file>` count, `ai-log level`, `Work in progress: Tasks`, the
`session-end-save.md` pointer and its within-100-lines check. Two copies of the same literal checks drift independently,
and test_workflow_docs.sh's comment 'Another test greps this text' shows they are already coupled. Scenario: The wording
is changed on purpose and only one test file is updated. The other fails with a confusing duplicate failure, or one copy
is loosened while the other stays strict.
Refuted: Confirmed. test_ai_log.sh lines 1249-1258 repeat test_workflow_docs.sh lines 48-50 and 66-68: the 'ai-log
level' and 'Work in progress: Tasks' greps and the session-end-save.md pointer within 100 counted lines. The two copies
differ already ('-ge 1' against an exact count of 1 for the pointer). This is duplication, not a defect, so nit.

### R4-13 · nit · tests

test/test_check_md_limits.sh:454: The case 'a blank line after the opening --- means it is not front matter, so it
counts' does not isolate the blank-line rule. Its block also holds 'Prose between separators.', which fails the YAML
check on its own, so it would pass even without `return -1 if $j == 1`. The later `fm-blank-first.md` case does isolate
the rule, so this one is redundant and its description claims more than it proves. Scenario: With the `$j == 1` check
removed from FRONT_MATTER_PERL, this assertion still passes. Only `fm-blank-first.md` catches the change.
Refuted: Confirmed by tracing FRONT_MATTER_PERL (bin/check-md-limits lines 231-242). Without the `$j == 1` return, j=1
(blank) would hit `next`, then j=2 'Prose between separators.' matches none of the key, quoted-key, list or indented
patterns and returns -1. So the block is still not front matter and the assertion still passes. Only fm-blank-first.md
isolates the rule. The redundant case and its overclaiming description are cosmetic: nit.

### R4-14 · minor · security and work context

claude/docs/work-contexts.md:90 (also claude/docs/staged-workflow.md:63, README.md:82): The disclosure that backs the
user's standing yes understates what ai-log pushes. These docs say what leaves the machine is "counts, durations, tokens
and versions, and the introspection". The entry also carries names. At personal level it stores the repo as owner/name,
the plan basename, MCP tool names (`mcp__<server>__<tool>`), user-scope slash commands, custom agent types and skill
names in plain text. At company level it stores model ids. Scenario: At personal level the user works on a private repo,
say andrelin/side-gig, with a plan named for the work and an MCP server named for a third party. `record` pushes `repo`,
`plan` and the MCP server name to the log repo. The doc the user approved against said only counts, durations, tokens
and versions leave the machine. The refusal check catches a name only when `~/.claude-customers` lists it. Fix: reword
to "counts, durations, tokens, versions and tool, skill, agent and model names (repo and plan hashed at company level)".
Fixed: work-contexts.md, staged-workflow.md and README name the names that leave, hashed at company level.

### R4-15 · minor · security and work context

bin/ai-log:1194 (also :1277, require_clone at :197): `record` and `note` commit and push to whatever remote the
`AI_LOG_DIR` clone tracks. `require_clone` checks only that `AI_LOG_DIR` is the top of a git clone. Nothing checks that
its origin is the private andrelin/ai-framework-log, or that the remote is private. Yet the redaction bar
(personal-level names kept, the introspection only mechanically redacted) assumes the destination is private. Scenario:
`AI_LOG_DIR` points at the wrong clone, for example a public fork or a public test repo left exported from an
experiment. The standing yes runs `record` and `note` after every plan without asking, so entries and introspections are
pushed to a world-readable repo with no prompt. Fix: refuse, or at least warn, when `normalize_origin` of the clone's
origin is not github.com/andrelin/ai-framework-log or a line the user lists.
Fixed: `require_clone` refuses unless the clone's origin is github.com/andrelin/ai-framework-log or `AI_LOG_REMOTE`; tested.

### R4-16 · nit · security and work context

bin/ai-log:217 (okname): `okname` allows `/` and `:` in every name it passes. That covers skill names,
`attributionSkill`, slash-command names, agent types and the `version` field. So a path-shaped value such as
`/Users/x/client/thing` or `a/b/c` is stored as a name, despite the spec's "no path" rule for entries. At personal level
nothing folds it. Scenario: A transcript records a `Skill` call whose `skill` input is path-shaped, for example a
mistyped or tool-generated `../client-tree/skill`. At personal level `rn_skill` keeps it as `builtin`, and the path is
written to `skills` and `skills_outside` and pushed. It is caught only if the path holds a term from
`~/.claude-customers`. Fix: drop `/` from `okname`'s character class for skill and command names, keeping `:` for
plugin-prefixed names.
Refuted: Dropped by the verifier. `/` in okname is needed, not a leak. Claude Code names directory-scoped skills with a
path prefix such as `apps/web:deploy`, and the Skill tool's `skill` input takes exactly that name. The proposed fix of
dropping `/` would turn every such legitimate name into null/"unknown". The scenario of a mistyped
`../client-tree/skill` is implausible because the Skill tool takes only listed names. At company level a project-class
skill is folded to `_project` (rn_skill :344-346), and at personal level plain names are kept by design. The plan's "no
path" rule targets tool-input file paths, not skill identifiers. `version` and slash-command names never take a path in
practice. The finding has neither a plausible failure scenario nor a correct fix.

### R4-17 · minor · plan conformance

.github/workflows/workflow-docs.yml:1: A new CI workflow (untracked) is in no task's Files list, and neither § Approvals
nor any task records it as a deviation. § Approvals adds only `test/test_workflow_docs.sh` to Task 17's Files (R2-1,
R2-9, R2-24); this workflow, which runs that test plus test_ai_log.sh and test_check_md_limits.sh, is not mentioned
anywhere in the plan. Scenario: Plan conformance: the diff does something no task says. The final commits would add a
new CI job to a public repo with no planned or recorded decision behind it. Its trigger list (paths `**.md`,
`claude/**`) also fires on every markdown-only push, and nothing in the plan states the trigger scope that
`.claude/rules/workflows.md` asks to keep narrow. Record it under Task 17 (or 15) as a deviation, or drop it.
Fixed: recorded in Task 17 as a deviation, the workflow in its Files.

### R4-18 · minor · plan conformance

claude/skills/setting-up-follow-up-trackers/SKILL.md:44: The adopted § Approvals line covers one edit to
`claude/CLAUDE.md` ("It is in no task's Files list"). The diff also rewrites issue and PR examples in three skills and
the repo CLAUDE.md to `dotfiles#N`: setting-up-follow-up-trackers:44,47, writing-follow-up-items:48,80, the task-heading
form in writing-plans SKILL.md (`## Task 2 · dotfiles#53: …`) and CLAUDE.md:31 (`dotfiles#3`). None of these is recorded
in the plan. Scenario: Plan conformance: these edits reach past what the approval names. They also break the user's
stated rule: in markdown files an issue is named "by repo and title", but the tracker examples give `dotfiles#412` with
no title. And they mix forms: GitLab keeps a bare `!412` while GitHub becomes `dotfiles#412`, and the doc still says
"the host's own word and sigil". So a tracker for a customer's GitHub repo gets the dotfiles repo as its example. Record
the sweep under § Approvals or revert it.
Fixed: recorded under § Approvals; the tracker examples use `<repo>#412` and `<repo>!412`.

### R4-19 · minor · plan conformance

claude/skills/writing-plans/SKILL.md:99: Two edits sit in no task's Files list and have no recorded deviation:
writing-plans now tells the plan author to "also ask how the branch lands (PR, squash merge, who merges) and for the
tracked plan's removal commit", and `claude/docs/plan-file-template.md:15` gains a matching comment in § Approvals. Task
17's Files list only session-end-save.md, implementing-plans, work-contexts.md and skill-precedence.md. The handover
records only the earlier `writing-plans` learning (06f51fa), not this one. Scenario: Plan conformance: these change what
every future plan asks the user, with nothing in the plan recording them. Add both files to Task 17's Files with a dated
deviation.
Fixed: recorded in Task 17 as a deviation, both files in its Files.

### R4-20 · minor · plan conformance

tips/24_claude_code.md:153: Task 17 says "No script, so no tip", and § Approvals (2026-11-09) says new tips go in a new
tips file because `tips/24_claude_code.md` is pinned full. The diff still adds a session-end paragraph to Tip 24.8
(`ai`). To make room under the 125 pin, it also rewrites the unrelated Tip 24.7 (`skill-trigger-eval`, lines 124-130).
No deviation records either change. Scenario: Plan conformance: Task 17 adds a tip its spec rules out, in the file the
user ruled closed to new tips, and compresses an unrelated tip to fit. Either move the paragraph to
tips/25_ai_framework.md or record the deviation in Task 17.
Refuted: Partly refuted, but it still stands as minor. Task 16's Files include `tips/24_claude_code.md`, so the
check-md-limits tip edits there are planned. The session-end paragraph in Tip 24.8 belongs to Task 17, which says "No
script, so no tip" and does not list the tips file. Making room under the 125 pin needed the unrelated Tip 24.7 to be
compressed by three lines, and no task records that. One correction: this extends an existing tip rather than adding a
new one, so the § Approvals "new tips file" ruling is less directly breached than the finding says. The core point, an
unrecorded edit against Task 17's "no tip", holds.
Fixed: recorded in Task 17 as a deviation.

### R4-21 · minor · plan conformance

claude/docs/session-end-save.md:27: Task 17's spec commits the index as "the checkpointed tasks, never a leftover". The
doc adds steps the spec doesn't have: during a code review the session end also `git add`s the review's uncommitted
fixes (leftovers not on the `Leftovers before round 1:` line, :27-28); it prepends `<!-- DOCTOC SKIP -->` to a plan file
(:29-30); and it stops on a detached HEAD or a branch that isn't the plan's (:16). reviewing-in-rounds step 1 was edited
to match. The "Check, then push" public-repo read (R2-16) is in § Approvals, but these three are not recorded in Task
17's section. Scenario: Plan conformance: a session end in the middle of a code review now commits and pushes unreviewed
fix leftovers, which the spec's "never a leftover" excludes. The task's Result and Deviations lines don't mention it, so
Task 13's fold and later readers can't tell whether the user approved it.
Fixed: recorded in Task 17 as a deviation.

### R4-22 · nit · plan conformance

claude/rules/writing-code.md:8: Task 16 names the globs to add (`.cs`, `.go`, `.rs`, `.rb`, `.swift`, `.c`, `.cpp`,
`.h`, `.php`, `.scala`, `.gradle`). The diff also adds `.mjs`, `.cjs`, `.mts`, `.cts`, `.razor`, `.cshtml`, `.cc`,
`.cxx` and `.hpp`, and test_workflow_docs.sh pins them, but Task 16's section records no deviation for them. Scenario:
Plan conformance: the extras fit the user's "C# plus the common languages", but they are unrecorded scope beyond the
listed spec. Add a one-line deviation to Task 16.

### R4-23 · nit · plan conformance

bin/check-md-limits:46: A new user-facing option, `--count-raw`, is added to `bin/check-md-limits` (with a tip line and
tests). Task 16's Change doesn't call for it; it exists so that test_workflow_docs.sh can measure counted-line
positions. No deviation is recorded. Scenario: Plan conformance: an unplanned CLI surface on a shared script. Note it in
Task 16 or Task 17 (the test that needs it) as a deviation.

### R4-24 · nit · plan conformance

bin/ai-log:25: Task 15's Interfaces gives exit 1 for "a given `<commit>` no newer than the window's start without
`--dry-run`". The script exits 1 for it with `--dry-run` too ("also with --dry-run" in the header, and the dry-run
branch at about line 953). Task 15's recorded deviations (no dollars, exit 3, the dry run fetching) don't include this.
Scenario: Plan conformance: `ai-log record --dry-run plan.md <old-commit>` exits 1 where the interface text implies the
dry run goes on. Either reword the interface in the plan or record the deviation.

### R4-25 · minor · the change as a whole

claude/skills/reviewing-in-rounds/SKILL.md:84: The session-end trigger exists only in implementing-plans § Finish
(SKILL.md:131-133). session-end-save.md:3 says it is read only from there, and reviewing-in-rounds only mentions saves
that already happened (lines 86, 96). A code review started on its own (`ai review code <plan>`, which bin/ai supports)
never loads implementing-plans, so wrapping up that session does not commit, push or record anything. Scenario: The user
resumes a final code review the next day with `ai review code plan-x.md`, fixes findings for two rounds and says "let's
wrap up". Nothing tells the session to follow session-end-save.md, so the fixes stay uncommitted and are never pushed.
Another machine cannot resume from them, and no ai-log entry covers the session. This goes against the user's standing
rule from 2026-11-05: "commit and ai log at the end of sessions too".
Refuted: Not refuted. session-end-save.md:3 makes implementing-plans § Finish (SKILL.md:131-133) the only trigger.
reviewing-in-rounds:86 and :96 only mention session-end commits that already exist. bin/ai:10 supports a standalone
`review code`, which loads reviewing-in-rounds and never loads implementing-plans. A wrap-up before `Done (code):`
therefore commits, pushes and records nothing, against the standing rule of 2026-11-05 to commit and log at the end of
every session. It is only minor because review Completion still commits once the review finishes.
Fixed: `reviewing-in-rounds` points a session end before `Done (code):` at session-end-save.md, which names both triggers; tested.

### R4-26 · minor · the change as a whole

claude/docs/session-end-save.md:10: A session end decides whether to save from `ai-log level`. For an origin outside
github.com/andrelin and github.com/uptimeconsulting, that level depends on an `allow` file inside the log clone. Company
work on a Forgejo host (which the global CLAUDE.md treats as company) is therefore classed as customer whenever the
clone is missing or does not list the host. The save then commits and pushes nothing, and the doc does not say to report
ai-log's stderr reason (`add it as a line to … allow`). Scenario: On a fresh second machine with no ~/.ai-framework-log
clone, a company Forgejo repo's session end runs `ai-log level`, which prints `customer`. The doc treats that as
customer level: nothing is committed or pushed, and the report only lists uncommitted files. The user believes the work
was pushed, and the other machine cannot resume it. The cause is a missing log clone, not a real customer repo.
Fixed: session-end-save.md quotes `ai-log level`'s stderr reason in the report.

### R4-27 · nit · the change as a whole

claude/docs/session-end-save.md:67: The landing removal only lists tracked files (`git ls-files -z -- ':(top)<stem>.md'
':(top)<stem>-review-findings-*.md'`),
and Task 13's test (`git ls-files 'plan-ai-framework*'` prints nothing) only checks tracked files. An untracked findings
file is never deleted. One exists right now: `plan-ai-framework-review-findings-code-closed-2026-11-09.md` is `??` in
git status, left behind when a closed log was copied instead of `git mv`ed. The plan requires deleting every review
file, the -closed- ones included (Task 13 Files, R9-13). Scenario: Task 13's `git rm` commit runs, the `git ls-files`
test passes, and the PR is squash-merged. The untracked closed code-review log stays in the worktree. On the next
`implementing-plans` fresh start it shows up as a leftover, or it is mistaken for a live plan file. `writing-plans` §
Plans are temporary is not met.
Refuted: Downgraded from minor by the verifier. Downgraded. The untracked closed findings file is never on the branch,
so it cannot reach main. At personal level, session-end-save.md:23-26 already adds untracked plan files, `-closed-` ones
included (`--others`), so the next session end tracks the file and the Landing `git rm` then removes it. The leftovers
listing excludes `plan-*`, so a fresh start does not show it as a leftover either. What remains is a stray local file
the user removes by hand: cheap to live with.

### R4-28 · nit · the change as a whole

claude/skills/implementing-plans/SKILL.md:145: Task 17's Deferred items are still open even though the plan says the
final code review fixes the ones it reaches. Line 145's red flag "Only the session-end commit exists." is wrong at
customer level, where no session-end commit is made. Line 9's "the commit follows the code review" is now ambiguous.
Line 64's "`BASE..HEAD` holds only those" is awkward for a single commit. Line 129's final report lists "each task's
paths" but has lost "reported". Scenario: At customer level, an agent tempted to make a checkpoint commit reads "Only
the session-end commit exists" and may conclude that a commit is allowed during the run. The plan's Deferred line says
the final review fixes these, and a code review fixes its minors before `Done (code):`. Leaving them only moves them to
Task 13's issue.
Refuted: Downgraded from minor by the verifier. Downgraded. The plan (Task 17 Deferred, and the Task 15 note) says the
final review fixes only what it reaches and Task 13's issue carries the rest, so leaving these open breaks no
requirement. All four are wording. The customer-level misreading of "Only the session-end commit exists." cannot turn
into a commit, because work-context.sh blocks `git commit` at customer level anyway.

### R4-29 · minor · the change as a whole

claude/docs/staged-workflow.md:64: Task 13's Deferred items are still open. Line 64 says "The branch lands by a
squash-merged PR, never a fast-forward" without a condition. But skill-precedence.md and the skills limit that rule to a
branch holding session-end commits, and personal-level `finishing-a-development-branch` still allows a clean local merge
otherwise. Line 82, "AI review anchors the human reviewer there", reads backwards. work-contexts.md:100's "fails closed
because any other exit lets the call through" is confusing. Repo CLAUDE.md:22's "the workflow skills" is undefined.
Scenario: A maintainer who reads staged-workflow.md before changing the skills (as the repo CLAUDE.md tells them to)
concludes that every branch must land by squash PR. They then 'fix' skill-precedence.md's local-merge allowance for
personal branches without WIP commits, and the docs disagree.
Fixed: staged-workflow.md scopes the squash rule to a branch holding session-end commits; the other three lines reworded.

### R4-30 · nit · the change as a whole

bin/ai-log:25: The build differs from the plan's Interfaces without a recorded deviation. Task 15 says exit 1 for "a
given `<commit>` no newer than the window's start without --dry-run". The code, its header and test_ai_log.sh:336/1136
also exit 1 with --dry-run. Task 15's Result lists other deviations but not this one, so Task 13's fold or issue would
carry the wrong contract. Scenario: A future caller follows the plan's interface and expects `ai-log record --dry-run plan.md <old-commit>`
to print the entry for inspection. It exits 1 and prints nothing. The plan, the only place this contract was specified,
does not say why.
Refuted: Downgraded from minor by the verifier. Downgraded. The plan's "without `--dry-run`" (line 3571) was never
recorded as a deviation, but the durable contract, the ai-log header at :25 ("also with --dry-run"), matches the code
(:958-962) and the test (:336). The plan is deleted at landing, so no future caller reads the plan's version. What is
left is a missing deviation note in a temporary file.

### R4-31 · minor · the change as a whole

bin/ai-log:868: Task 15's Deferred item "a dry run reads a stale local entry when origin re-recorded the same id" is
still open. The dry-run merge only adds remote entry files that are missing locally (`! -e "$AI_LOG_DIR/$rf"`), so a
local copy that is out of date wins. It is named as Deferred, so it must go into Task 13's issue. It is not fixed.
Scenario: Machine A records entry X, then machine B re-records the same id with a later window end and pushes. A
`--dry-run` on machine A, after fetching only, reads its own older X. The computed window start and the summed summary
are then off by B's extra window.
Refuted: Confirmed in the code. ai-log:868 merges a remote entry only when `! -e "$AI_LOG_DIR/$rf"`, so after a
fetch-only dry run an outdated local copy of a re-recorded id beats origin's newer one. This affects only dry-run
output, which writes nothing, so minor fits. The plan already names it as Deferred for Task 13's issue.
Fixed: a dry run reads origin's differing entries without writing; the later `window.end` wins; tested.

### R4-32 · nit · the change as a whole

.github/workflows/workflow-docs.yml:1: A new CI workflow is untracked. No task's Files list or deviation in the plan
names it. It only reaches the commit through Completion's 'a fix outside every list going with the last task', and
nothing records why it exists (tests.yml's paths-ignore skips claude/skills, claude/docs and claude/rules). Task 13's
fold to staged-workflow.md does not mention it either. Scenario: After the plan is deleted, a maintainer sees two
workflows running test_ai_log.sh and test_check_md_limits.sh on overlapping pushes. Nothing durable explains the
duplication, so one of them may be removed, and claude/docs-only pushes would lose their guards again.
Refuted: Downgraded from minor by the verifier. Mostly refuted. workflow-docs.yml:2-3 states in a comment why it exists:
tests.yml and tests-wsl.yml paths-ignore claude/skills, docs and rules and markdown, so this workflow runs those guards
on such pushes. A maintainer who opens the file sees why it duplicates them, so the "nothing durable explains the
duplication" scenario does not hold. What remains is bookkeeping: the plan's Files lists and Task 13's fold do not name
the file.

### R4-33 · nit · the change as a whole

tips/24_claude_code.md:88: Task 16's Deferred item about the tip's wording is only partly fixed. "its first 100 lines
hold the task" says lines, not counted lines (front matter, blanks and headings excluded). Because it directly follows
the description cap, it still reads as if it were about the description. Scenario: A reader of the tip counts raw lines
from the top of SKILL.md, front matter included, and moves needed text up or down unnecessarily.

### R4-34 · nit · the change as a whole

claude/skills/setting-up-follow-up-trackers/SKILL.md:44: The adopted CLAUDE.md issue-naming line was applied here in a
way that mixes up two concerns. The paragraph is about the host's own PR sigil, but GitHub's sigil is given as
`dotfiles#412` (repo-qualified), which GitHub does not render that way. The PR-vs-issue disambiguation example drops the
title that the CLAUDE.md line asks for ("by repo and title"). Scenario: A tracker set up from this skill writes `PR dotfiles#412`
with no title. A reader does not know what it refers to, which is what the CLAUDE.md line from 2026-11-09 was meant to
prevent.

### R4-35 · minor · fit with the surrounding code

bin/ai-log:124: `normalize_origin` is a second copy of the guard's `parse_url`/`host_alias`
(claude/hooks/work-context.sh:218, :399), rewritten from scratch, and it already differs from it. The guard's
`host_alias` accepts `.` as a separator and treats a dotless SSH alias with a `v3/` path as Azure DevOps;
`normalize_origin` accepts only `-`/`_` and keeps a dotless alias as written. The `add_customer_line` parser
(bin/ai-log:573) likewise copies the guard's `customer_entry` (its comment says "as the guard's customer_entry … but
without its refusals"). Scenario: Origin `git@github.com.personal:andrelin/x.git`: the guard's `host_alias` reads the
host as github.com and gives `personal`. `compute_level` then builds `hostowner` from `normalize_origin`, gets
`github.com.personal/andrelin`, misses the built-in allowlist and records nothing (customer). The two parsers will drift
further each time one is edited, because no test checks one against the other. The guard is bash 3.2 and could expose a
`parse-origin`/`customer-terms` subcommand, as it already does for `level`, so ai-log could call it instead of keeping
its own copy.
Fixed: `normalize_origin` mirrors `parse_url`/`host_alias`; a test runs 25 origins through both.

### R4-36 · nit · fit with the surrounding code

test/test_workflow_docs.sh:147: The test writes with `git -C "$repo" rm -q --cached plan-x.md`. Every other write in
this file goes through `gitin`, line 107's comment says the writes go "through a subshell the way test_ai_log.sh does",
and the plan's Global constraints forbid `git -C <path>` for a write in scratch repos, because the guard blocks some of
them. Scenario: A session or CI run with `claude/shims` on PATH, where the guard checks `git -C` writes, can block or
misresolve this one call while every `gitin` call around it passes. Use `gitin rm -q --cached plan-x.md` instead.
Refuted: Downgraded from minor by the verifier. Downgraded. The `git -C "$repo" rm -q --cached` at
test/test_workflow_docs.sh:147 does break the file's own `gitin` idiom, and the comment at line 107 says the writes go
through a subshell. But the guard scenario doesn't hold up. The plan's ban (plan line 50) is about the agent's own Bash
calls, which the PreToolUse guard checks. A test script's internal git calls aren't hook-checked, and `rm --cached` is
not on the forbidden list in any case. What's left is an inconsistency.

### R4-37 · nit · fit with the surrounding code

test/test_ai_log.sh:1110: The test writes with `git -C "$WFX" checkout -q -- plan-example-review-findings-plan.md`. The
file's own header (line 19) says "git writes run in a subshell cd", it defines `gitin <dir>` for this purpose, and the
plan's constraint bans `git -C <path>` writes. Scenario: Under the shims and guard, this checkout is the one write in
the file that bypasses the subshell-cd idiom, so it is the one call the guard may stop. Use `gitin "$WFX" checkout -q -- …`.
Refuted: Downgraded from minor by the verifier. Downgraded for the same reason as finding 1. test/test_ai_log.sh:1110
bypasses the file's `gitin <dir>` idiom, which its line 18 header describes. But `checkout --` is explicitly allowed by
the guard, and a command inside a test script isn't checked by the hook. There is no plausible failure, only a mismatch
with the file's convention.

### R4-38 · nit · fit with the surrounding code

claude/docs/work-contexts.md:86: New lines in agent-loaded files name `session-end-save.md` bare. The surrounding text
names sibling docs by `~/.claude/docs/…`: line 93 of the same paragraph writes `~/.claude/docs/staged-workflow.md`, and
reviewing-in-rounds/SKILL.md:10 writes `~/.claude/docs/review-lenses.md`. The same bare form appears in
claude/skills/reviewing-in-rounds/SKILL.md:86 and :105, claude/docs/skill-precedence.md:51, and
claude/docs/staged-workflow.md:24 and :68. Task 13's Deferred line already lists this ("sibling docs named bare").
Scenario: A session working in another repo, such as a company repo during Completion step 8, reads
"(`session-end-save.md` § *Landing*)" and looks for it relative to the cwd. It finds nothing and lands without the doc's
`-f` and empty-list handling.
Refuted: Downgraded from minor by the verifier. Downgraded. The bare names are real (work-contexts.md:86,
skill-precedence.md:51, reviewing-in-rounds/SKILL.md:86 and :105, staged-workflow.md:62). But the base tree already
names sibling docs bare, for example work-contexts.md at cdf0a77 names `skill-precedence.md` bare. The new lines follow
an existing mixed practice rather than breaking one, and the plan already defers this as Task 13. It is a wording
consistency point.

### R4-39 · nit · fit with the surrounding code

bin/ai-log:256: `utext` in JQ_AGENT_LENS and `intext` in JQ_REDUCE (bin/ai-log:274) are the same jq function under two
names. `JQ_COMMON` exists to hold shared defs and both programs already include it. Scenario: A later change to how text
is pulled from a message, such as a new content-block type, gets made in one copy only. Lens matching and slash-command
detection then disagree about the same record. Move one definition into JQ_COMMON.

### R4-40 · nit · fit with the surrounding code

test/test_workflow_docs.sh:74: The file defines a `count` helper (line 27) for fixed-string occurrence counts and uses
it in lines 48-73. From line 74 on, the same check is written as raw `grep -cF`, and line 74 uses `grep -cE` for a fixed
string. The assertion shape also switches from `[[ … -ge 1 ]] && echo yes` to an exact count. Scenario: With two idioms
for one check, a reader can't tell whether `-ge 1` versus `== 1` is deliberate. Line 70's comment says some must be
exactly 1, and the switch hides which ones. Use `count` throughout and keep the exact-count form only where uniqueness
is the point.

### R4-41 · nit · fit with the surrounding code

test/test_workflow_docs.sh:5: This test names the checkout `CHECKOUT` (with `pwd -P`) and drops the "resolve before
sourcing the helper" why-comment that its neighbours carry: test_ai_log.sh:1-4 uses `REPO`, test_check_md_limits.sh:1-4
explains it. It also defines `gitin` with a different signature from test_ai_log.sh's `gitin <dir> …`, which uses the
same name. Scenario: Someone moving the `source` line above the resolution doesn't know why it is ordered that way, and
the test then reads `~/.dotfiles` instead of the tree under test. Copying a `gitin` call between the two test files
silently takes the first argument as a git subcommand.

### R4-42 · nit · fit with the surrounding code

bin/check-md-limits:169: "No aim" is encoded as the sentinel `250 250` (warn == hard), and `warn == hard` is checked in
two places (lines 517 and 541) to mean "skill, no pin". The rule table writes `—` and the doc writes `none` for the same
idea, and the `limits_for` comment has to explain the trick. Scenario: A future type given the same aim and cap on
purpose would silently lose pinning and warnings. An explicit `0` or empty aim would say what it means without needing
the comment.

### R4-43 · nit · fit with the surrounding code

tips.md:56: The new 25 entry is a prose sentence ("`ai-log` records how a plan fared: counts, plus …"). The neighbouring
entries, such as the 24 entry directly above, list the commands the file covers ("— `sync-claude-deny`,
`sort-claude-settings`, …"). Scenario: A reader scanning tips.md for a command name expects the entry to list it the way
the entries around it do. The entry would read like its neighbours as "— `ai-log` (`record`, `note`, `level`)".

### R4-44 · major · docs ship with the change

.github/workflows/workflow-docs.yml:1: The new CI workflow is the only thing that runs test/test_workflow_docs.sh,
test_ai_log.sh and test_check_md_limits.sh on doc-only pushes, because tests.yml's paths-ignore skips claude/skills,
claude/docs, claude/rules and **.md. The file is untracked and appears in no task's Files list. The plan names only
test/test_workflow_docs.sh when it joins Task 17's Files (§ Approvals). It is also absent from the deviations and the
File map. Scenario: Completion builds its commits from each task's Files list and stages only paths that were not
already leftovers before round 1. An untracked file created before round 1 "stays unstaged, the report names it". The
squash-merged PR then lands every doc guard the review relies on, but a later push that touches only session-end-save.md
or a SKILL.md runs none of them in CI. A reworded or dropped pointer (the case test_workflow_docs.sh exists to catch)
would go green.
Fixed: with R4-17.

### R4-45 · minor · docs ship with the change

claude/skills/maintaining-follow-up-trackers/SKILL.md:32: Step 2 still says the issue number is "written `issue #<n>` as
`writing-follow-up-items` says". writing-follow-up-items now gives the repo-qualified form (`issue dotfiles#373`) under
the adopted claude/CLAUDE.md line ("In chat and markdown files, name an issue or PR by repo and title"). The ripple edit
reached writing-follow-up-items, setting-up-follow-up-trackers and writing-plans, but not this skill. Scenario: A
tracker review run following maintaining-follow-up-trackers writes a bare `issue #412` into a tracker, which is a
markdown file. That breaks the new global rule "never a bare #900", and the two skills now give conflicting forms for
the same field.
Fixed: `issue <repo>#<n>`.

### R4-46 · nit · docs ship with the change

tips/25_ai_framework.md:19: The tip's exit-code list puts only "usage or a missing clone" under exit 2. bin/ai-log's
header (lines 25-29) also exits 2 when `note` gets empty input or input missing a heading, which plan Task 15b specifies
too. The tip leaves out that `note` case. Scenario: A user pipes an introspection without a `## Didn't` heading to
`ai-log note <id>` and gets exit 2. The tip says 2 means a usage error or a missing clone, so they go looking for a
clone or argument problem that isn't there.
Refuted: Downgraded from minor by the verifier. Downgraded. Empty input, or input missing a required heading, is
malformed input to `note`, which a reader can fairly count as "usage". The tip is a deliberate summary of the header.
The scenario of a user hunting for a missing clone is weak, because the failing `note` call reports its own reason. A
wording gap at most.

### R4-47 · nit · docs ship with the change

tips/24_claude_code.md:692: "A skill's `description` is capped at 300 characters, and a skill has no aim, so no note
(250 passes, 251 fails): its first 100 lines hold the task." In this sentence, "its first 100 lines" reads as the
description's first 100 lines. It also leaves out "counted" lines, which the rule and doc use, and front matter is
excluded from that count. Task 16 deferred this to the final review, and it is still unfixed. Scenario: A reader of
`tips 24` concludes the 100-line placement rule is about the description or raw file lines. They put essential steps at
raw line 95 of a skill with long front matter, or mis-split a skill.
Refuted: Downgraded from minor by the verifier. Downgraded. The sentence is at tips/24_claude_code.md:88, not 692. In "a
skill has no aim, so no note (...): its first 100 lines hold the task", the subject of the clause chain is "a skill", so
"its" most naturally means the skill. claude/docs/markdown-limits.md defines what is counted. The missing word "counted"
is a wording imprecision, not a plausible misreading that leads someone to mis-split a skill.

### R4-48 · nit · docs ship with the change

claude/skills/implementing-plans/SKILL.md:145: The red flag reply now reads "Only the session-end commit exists. The
index and the ref are the checkpoint." There is no session-end commit at customer level (session-end-save.md § At
customer level), and even at other levels it is not the only commit (Completion commits per task). Task 17 deferred this
and it is still unfixed. Scenario: During a customer-level run, an agent tempted by a checkpoint commit reads that a
session-end commit "exists". It may treat a commit as permitted there, against the guard's rule. At best the red flag no
longer clearly says why a mid-run commit is wrong.
Refuted: Downgraded from minor by the verifier. Downgraded. The red flag concerns mid-run checkpointing. The same
skill's line 9 says "nothing is committed bar the session-end commit" before the code review, so "only the session-end
commit exists" matches the skill's own framing for that phase, and Completion commits come after it. At customer level
the work-context guard hook blocks commits whatever this line says, so the scenario that an agent is "permitted" to
commit cannot happen. What is left is imprecise wording for the customer case.

### R4-49 · minor · docs ship with the change

claude/docs/staged-workflow.md:64: "The branch lands by a squash-merged PR, never a fast-forward" is stated for every
branch. session-end-save.md § Landing, the implementing-plans and reviewing-in-rounds skills, and skill-precedence.md
all scope the rule to "a branch holding session-end commits" (customer-level runs and branches without WIP commits can
still fast-forward or merge locally). Task 13 deferred this and it is still unfixed. Scenario: Someone changing the
workflow reads staged-workflow.md as the rationale doc, which CLAUDE.md tells them to read first. They believe every
plan branch must squash-merge, then tighten a skill or `finishing-a-development-branch` handling to match. That
contradicts skill-precedence.md, which keeps the clean local merge for branches without session-end commits.
Fixed: with R4-29.

### R4-50 · nit · docs ship with the change

claude/docs/work-contexts.md:89: work-contexts.md says that after a plan's commit "at every level but customer,
`reviewing-in-rounds` and the save run `ai-log`". reviewing-in-rounds step 7 says to run `ai-log record` "at every
level", and ai-log itself prints the deferral line at customer level. The two docs now disagree on whether the skill
runs ai-log at customer level. Scenario: At customer level, an agent following work-contexts.md skips `ai-log record`,
while one following the skill runs it and gets the deferral line. That is harmless today, but a later change to ai-log's
customer handling (Follow-up 15c) would be wired to whichever doc the implementer reads, and the other would then be
wrong.
Refuted: Downgraded from minor by the verifier. Downgraded. In reviewing-in-rounds step 7, "at every level" qualifies
what the user's standing yes covers. At customer level `ai-log` itself defers and records nothing. Whether the agent
skips the call (work-contexts.md) or runs it and gets the deferral line (the skill), the outcome is identical, as the
finding itself admits. The failure scenario is a speculative future change, so only a wording inconsistency remains.

### R4-51 · nit · docs ship with the change

claude/docs/staged-workflow.md:82: "The completion report names the files no finding touched, because AI review anchors
the human reviewer there" reads backwards: AI findings anchor the reviewer on the files they touched, which is why the
report names the untouched ones. Task 13 deferred this and it is still unfixed. Scenario: A maintainer reading the
rationale takes it to mean that the untouched files are where the anchoring happens. The reason for the report step then
seems self-contradictory, and the step may be cut as unjustified.

### R4-52 · nit · docs ship with the change

claude/docs/markdown-limits.md:72: Two parts of the doc still assume every file type has an aim. § Splitting opens "Past
the aim, look for the seam" and § Files that were already long (line 82) says "A file over its warn line can be pinned",
but a skill now has no aim and cannot be pinned. The rule file (claude/rules/markdown-limits.md:27,31) has the same two
phrasings. Scenario: An author with a 200-line skill looks for when to split or pin. The doc points them at an aim and a
warn line that skills no longer have, with no statement that skills split only at the 250 cap or by the first-100
placement rule.
Refuted: Dropped by the verifier. The doc already says what the finding claims is missing. markdown-limits.md:38 gives a
skill "none" for aim and 250 for the cap. Line 41 says the checker warns at the aim "for every type but a skill". Lines
43-48 explain why a skill has no aim and say "With no aim there is nothing to pin, so a skill's pin is ignored". "A file
over its warn line can be pinned" is literally true and simply does not apply to a skill, which has no warn line. An
author of a 200-line skill is not misled.

### R4-53 · nit · docs ship with the change

tips/24_claude_code.md:127: The reflow of Tip 24's skill-trigger-eval paragraph dropped one fact:
`caches/.skill-trigger-eval-moved` names where the skill was moved. The new text only says the next run refuses "until
the skill is put back". Scenario: After a `kill -9`, a user reads the tip to restore the hidden skill. Nothing in it
says the marker file holds the skill's current location, so they have to search for it.
Refuted: Dropped by the verifier. The scenario fails. The next run's refusal in bin/skill-trigger-eval:52 prints the
marker's contents: "an earlier run left a skill moved out ($(cat "$marker")); put it back and delete $marker", where the
marker holds "$skill $hidden". The user is told where the skill went the moment the tip says the run refuses, so there
is nothing to search for.

### R4-54 · nit · docs ship with the change

claude/docs/staged-workflow.md:65: staged-workflow.md names its sibling docs bare (`session-end-save.md`,
`implementing-plans-reference.md`, `review-lenses.md`, `work-contexts.md`, `skill-precedence.md`). work-contexts.md
points at it as `~/.claude/docs/staged-workflow.md`. Task 13 deferred this and it is still unfixed. Scenario: An agent
that loaded staged-workflow.md from the repo path tries to open `session-end-save.md` relative to its cwd and fails to
find it.
Refuted: Dropped by the verifier. Bare sibling names are the convention across claude/docs. session-end-save.md,
skill-precedence.md, implementing-plans-reference.md, review-lenses.md and others use no ~/.claude/docs/ prefix (grep
count 0), and skill-precedence.md:51 cites `session-end-save.md` bare. A doc resolves its siblings relative to its own
directory, so neither a violated requirement nor a plausible failure follows from staged-workflow.md matching that
convention.

## Round 5

### R5-1 · minor · correctness and failure modes

claude/docs/session-end-save.md:54 (also tips/24_claude_code.md:154): The resume instruction 'on another after `git switch <branch> && git pull`'
fails on a machine whose clone has not fetched since the branch was first pushed: switch's DWIM needs the
remote-tracking ref origin/`<branch>`, and only a fetch creates it. Scenario: Reproduced in a scratch repo. Clone B is
made, then clone A pushes `feat` with `push -u`. In B, `git switch feat` prints `fatal: invalid reference: feat` (exit
128), so the documented resume on a second machine stops at its first command. The fix is `git fetch && git switch <branch> && git pull`,
or `git switch --track origin/<branch>` after a fetch.
Fixed: `git fetch && git switch <branch>` in the doc and Tip 24.8.

### R5-2 · minor · correctness and failure modes

claude/docs/session-end-save.md:10-13 with bin/ai-log:199-223: The session-end save decides whether to commit and push
by `ai-log level`, which also requires the origin to be github.com/andrelin, github.com/uptimeconsulting or a line in
the log clone's `allow` file. A missing log clone or allow file therefore turns off the WIP commit and push, not only
the logging. The guard allows those writes. Scenario: On a new machine without ~/.ai-framework-log, take company work on
a company Forgejo host (the case the global CLAUDE.md's Forgejo rule covers), or a personal repo on gitlab.com. `ai-log level`
prints `customer`, so the session end commits and pushes nothing, and the next machine cannot resume from a push. The
only signal is the stderr reason quoted in the report. An origin-less personal scratch repo also reads `customer`
(verified), although the global rule calls it personal.
Refuted: Dropped by the verifier. This is the intended design. Lines 10-13 of the doc and plan lines 3650, 3692-3693 and
3924 make the `ai-log level` origin allowlist the gate on purpose: an unlisted origin, even one the guard calls company
(a company Forgejo, say), counts as customer until the allow file names it. That is fail-safe, because nothing is
committed or pushed. bin/ai-log:215-221 prints the reason on stderr, including the missing-clone and no-origin cases,
and the doc tells the report to quote it so the user can fix it. Treating an origin-less repo as customer is likewise
deliberate (LEVEL_WHY 'the repository has no origin'). No requirement is violated.
Fixed: refuted as designed, then overtaken by the user's ruling: `ai-log level` is the guard's level, no list or `allow` file.

### R5-3 · minor · correctness and failure modes

claude/docs/session-end-save.md:29-30: During a code review, the session end stages every leftover not on the `Leftovers before round 1:`
line. Unlike implementing-plans' 'Not leftovers' carve-out, it has no exception for untracked artifacts a suite run
creates, so those are committed and pushed with the fixes. Scenario: During the review a suite run leaves an untracked,
non-ignored file, for example a test's output dump in the tree. The user wraps up, step 2 `git add`s it as a 'fix', and
step 5 pushes it. In a private personal or company repo no public-bar check runs, so the stray file lands on the branch
unnoticed.
Fixed: untracked files a suite run created are not staged; the report names them.

### R5-4 · minor · correctness and failure modes

claude/docs/session-end-save.md:40-42: After a second commit failure the doc says 'the index again equal to the last
checkpoint', but only the plan paths are restored. The review fixes that step 2 staged during a code review stay in the
index. Scenario: A session end runs during a code review, and the pre-commit hook rejects a staged fix file
(markdownlint or check-md-limits on a skill). The first commit fails and the plan paths are unstaged; the retry fails on
the same fix file. The index now holds the fixes, not the last checkpoint. A resume that compares `git write-tree` with
the checkpoint stops on a mismatch the doc said could not happen.
Fixed: a second failure also unstages the review's fixes, so the index equals the last checkpoint.

### R5-5 · nit · correctness and failure modes

claude/skills/reviewing-in-rounds/SKILL.md:35: The skill's trigger says a session end is when 'the run stops part-way',
with no qualifier. session-end-save.md and implementing-plans both say a stop to ask is not a session end. A review that
stops for a user decision (a re-evaluation recommending a stop, or a user-decision line) reads as a session end, which
commits and pushes WIP. Scenario: After round N a re-evaluation recommends stopping and asks the user. Following the
skill's line, the session commits `Work in progress: Tasks …` and pushes before the user answers in the same session.
The doc's first lines contradict this, so the outcome depends on which text the agent weighs.
Refuted: Downgraded from minor by the verifier. Downgraded. The skill line at reviewing-in-rounds/SKILL.md:35 is only a
pointer to session-end-save.md, which the agent must read to act. That doc's first lines (4-5) define the trigger as 'a
report that asks the user nothing' and say outright 'A stop to ask is not a session end.' The skill line never says a
stop to ask is a session end. It only leaves out the qualifier, and the doc it sends the reader to supplies it before
any commit step. A wrong WIP push therefore needs the agent to ignore the doc it is following. What remains is a wording
gap.

### R5-6 · nit · correctness and failure modes

bin/ai-log:878-881: The plan path is always resolved against the repo root, never the cwd. A relative path given from a
subdirectory (`ai-log record ../plan-x.md`) becomes `<root>/../plan-x.md` and fails with 'no such plan file', although
the usage line says only 'run in the work repo'. Scenario: From `<repo>/sub`, run `ai-log record ../plan-x.md`. It exits
1 with 'no such plan file: ../plan-x.md' even though the file exists. The skills pass root-relative names, so this hits
only a manual run.

### R5-7 · nit · correctness and failure modes

bin/ai-log:1000, 288: Session scoping matches the plan's basename as a plain substring (`grep -F` and jq `contains`), so
a plan whose name is a substring of another plan's name pulls that plan's sessions into its window. Scenario: Two plans
in one repo, `plan-foo.md` and `plan-old-plan-foo.md`. Sessions that only touch the second also name 'plan-foo.md' as a
substring, so `record plan-foo.md` counts their tokens and turns. This is unlikely with the `plan-<n>-<slug>` naming.

### R5-8 · minor · tests

bin/ai-log:914: Several drift paths that the spec says must 'degrade loudly' (a warning in the entry and on stderr, the
field null, exit 0) have no test. These are: a corrupt entry file in the log clone (914) or on origin (925); a
transcript that cannot be read (1004) or fully read (1061); an agent lens that cannot be read (1065); an unreadable
workflow summary (1105); a missing review-lenses.md (1052); a tree that is not a git checkout (1166); and a failed `git pull --rebase`
in the log clone (1265/1348). Tests cover only no usage, a non-JSON line, a missing plugins file, a bad meta.json,
unparseable headings, and a failed fetch, pull --ff-only or push. Scenario: Requirement: Task 15 'Drift degrades
loudly'. Example: a half-written entries/`<id>`.json in the log clone. If a change made that path abort (exit 3), or
silently skip the prior entry without a warning, the window would restart at the plan's first appearance and
double-count tokens. Every test would still pass.
Fixed: tests for each drift path: corrupt entries locally and on origin, unreadable transcript and lens, bad workflow summary,
missing lenses doc, no git tree, failed `pull --rebase`.

### R5-9 · minor · tests

test/test_workflow_docs.sh:45: Several session-end-save.md requirements added by Task 17's deviations have no guard,
though this file pins the doc's other wording: the stop on a detached HEAD or another branch (doc line 18), the `<!-- DOCTOC SKIP -->`
marker added to a plan before staging (lines 31-32), the `Work in progress: Tasks (none new)` form for an empty session
end (line 38), and the `git restore --staged` that leaves out what fails the public-repo check (line 36). Scenario:
Someone rewording the doc drops 'Stop and report if HEAD is detached'. A session end then commits and pushes `git push -u origin <branch>`
from a detached HEAD or the wrong branch, and test_workflow_docs.sh stays green. The same goes for losing the DOCTOC
line: the repo's pre-commit hook then rejects every session-end commit that adds a plan.
Fixed: the four lines pinned.

### R5-10 · minor · tests

test/test_ai_log.sh:1197: Whether the refusal for a customer term in the repo name is tested depends on a runtime
branch. If the guard reports `customer` for the repo, the test asserts only that and never checks that `record` refuses
a repo-name match at personal level. Which branch runs is not pinned, so a guard change can quietly swap the refusal
assertions for a weaker one. Scenario: A change to work-context.sh makes a listed name match a repo name, so zlevel
becomes `customer`. The two assertions 'a customer term in the repo name refuses the record' stop running, and a
regression in ai-log's repo-name check (the R-fix that brought repo and plan into the name check) goes unnoticed.
Fixed: the test asserts the guard resolves personal, then the refusal, unconditionally.

### R5-11 · nit · tests

test/test_ai_log.sh:118: The assertion is labelled 'record exits 0 with a warning present', but the same entry is
asserted at line 128 to have `warnings: []` ('a clean run has no warnings'). The label describes a condition that does
not hold. The exit-0-with-warning path is actually covered at line 366. Scenario: A reader trusting the label thinks the
first run tests exit 0 with warnings, and may drop the line-366 case as a duplicate.

### R5-12 · nit · tests

test/test_ai_log.sh:1266: The doc and skill wording checks here duplicate test_workflow_docs.sh almost one for one:
ai-log level and `Work in progress: Tasks` in session-end-save.md, the session-end-save.md pointer within the first 100
counted lines of implementing-plans, and `ai-log record <plan-file>` once in reviewing-in-rounds. The pointer check
reimplements counted_line inline. Scenario: A wording change has to be made in two test files. If one copy drifts from
the other, the same requirement is held to two different needles.

### R5-13 · nit · tests

claude/rules/writing-code.md:45: Task 16 added `.editorconfig` with `dotnet format` to the formatter examples, but no
test pins it, unlike the globs, each of which test_workflow_docs.sh pins. The same holds for the adopted
claude/CLAUDE.md line on naming an issue by repo and title, and for Task 7's § Code review reword ('not
`reviewing-locally`'). Both are prose with no guard. Acceptable for prose, so noted only. Scenario: A later trim drops
the .NET formatter example, and the C# case that Task 16 set out to cover loses its formatter pointer with no test
failing.

### R5-14 · minor · security and work context

bin/ai-log:242: require_clone checks the log clone's origin fetch URL (`git remote get-url origin`), but record and note
push with a bare `git push -q` (bin/ai-log:1267, 1350). That push goes to `remote.origin.pushurl`, or to the current
branch's upstream or pushRemote. None of these is checked, so the guarantee that a record or note pushes only to the log
repo can be bypassed. Scenario: The log clone has `remote.origin.pushurl` set to another repository, or its checked-out
branch tracks a different remote. I confirmed in a scratch repo that `git remote get-url origin` prints
<git@github.com>:andrelin/ai-framework-log.git while `git remote get-url --push origin` prints
<git@github.com>:someone/other.git. require_clone passes, and the entry or redacted introspection is pushed to the other
repository. Fix: compare `git remote get-url --push origin` as well, and push explicitly with `git push origin HEAD:<branch>`.
Fixed: `require_clone` also checks the push URL; pushes and pulls name origin and the branch; tested.

### R5-15 · minor · security and work context

bin/ai-log:484: The review kind is taken as any `[a-z]+` word from a plan's `## Review log (<kind>…)` heading, and from
the findings file names. It is stored unhashed as `reviews[].kind` and as the top-level keys of `findings`, even at
company level. JQ_LEAK (bin/ai-log:817-821) does not check these fields against ~/.claude-customers. So free text from
the plan can reach a pushed entry, unlike every other name, which is either folded, hashed or checked. Scenario: A
company plan has a review section headed `## Review log (acme)` (a typo, or a kind named for the client). It also has a
matching `plan-x-review-findings-acme.md`. `ai-log record` pushes `"kind": "acme"` and `findings.acme` to the log repo.
The refusal does not trigger even when `acme` is listed in ~/.claude-customers. Fix: map kinds outside {plan, code} to
"other", or add the review kinds to JQ_LEAK's names.
Fixed: kinds other than `plan` and `code` are stored as `other`; tested.

### R5-16 · minor · security and work context

bin/ai-log:798: The redaction's hostname pattern rejects a final label that is in the file-extension list. Several of
those extensions are real country-code TLDs (sh, rs, py, md). As a result, a fully qualified host on one of these TLDs
is not redacted as [host] in a pushed introspection unless ~/.claude-customers lists it. Scenario: An introspection at
company level says 'deploy to build.kunde.rs failed (2 retries)'. `build.kunde.rs` is not matched as a host, because
'rs' is in exts and the backtracked 'build.kunde' fails the trailing `(?!\.[A-Za-z0-9])`. The hostname is committed and
pushed to the log repo verbatim. This limitation is documented nowhere.
Refuted: Confirmed by running the hostname regex with the real exts list in jq. 'build.kunde.rs' and 'api.foo.py' are
left unredacted, while 'x.kunde.no' becomes [host]. The term passes still catch hosts whose labels come from the repo,
branch or customers file, so only a host unrelated to those slips through. work-contexts.md and staged-workflow.md do
not document the limitation. Minor.
Fixed: three or more labels ending in md, sh, py or rs are a host; the two-label gap is documented; tested both ways.

### R5-17 · nit · security and work context

claude/docs/staged-workflow.md:12: The stages table says Implement runs on 'opus (`AI_MODEL_REVIEW`)', which matches
bin/ai:68. But a reader of the decisions doc would expect an `AI_MODEL_IMPLEMENT` stage variable, and that name means
the implementer subagents' model (sonnet) two lines below. The doc never says that the implement stage's session model
is deliberately shared with the review stage. Scenario: Someone sets AI_MODEL_IMPLEMENT=opus expecting `ai implement` to
open on it. Only the subagents change, and the reason is not stated in the doc that exists to record why the workflow is
built this way.

### R5-18 · minor · plan conformance

claude/docs/work-contexts.md:85-87: The Task 17 edit that gives the line "workflow skills never commit on their own" its
exception says "bar one exception". It names only `implementing-plans`' session end, then says `reviewing-in-rounds`
commits *only* Completion's fixes and the plan's `git rm -f`. But the diff also gives `reviewing-in-rounds` a
session-end trigger (SKILL.md:35, "A session end before `Done (code):` ... follows session-end-save.md"), and that
trigger commits `Work in progress` and pushes without a per-commit yes. Task 17 requires every "never commits" statement
to name the session-end commit as its one exception. This doc now states the rule wrongly for one of the two skills that
run the save. Scenario: A reader of work-contexts.md (the doc the global CLAUDE.md sends you to for how a level applies)
concludes that `reviewing-in-rounds` never commits except Completion's commits after a yes. A code review interrupted by
"wrap up" then commits and pushes a WIP commit that this doc says cannot happen. The doc and the skills contradict each
other on when a commit happens without asking.
Refuted: The finding stands. work-contexts.md:85-87 says `reviewing-in-rounds` commits *only* Completion's fixes and the
plan's `git rm -f`, each after a yes. Task 17's code-review deviation gave `reviewing-in-rounds` the session-end trigger
(SKILL.md:35), and session-end-save.md:3 names that skill as a caller. That save commits `Work in progress` and pushes
on the standing yes, and it adds the review's uncommitted fixes too. The next sentence mentions `reviewing-in-rounds`
and the save running `ai-log`, but it never says that skill makes the WIP commit. So the "only" is wrong for one of the
two skills that run the save.
Fixed: work-contexts.md names both skills' session-end save, Completion's commits and ai-log's pushes, with no count.

### R5-19 · minor · plan conformance

claude/rules/writing-code.md:8-29: Task 16's Change lists exactly which globs to add: cs, go, rs, rb, swift, c, cpp, h,
php, scala and gradle. The diff also adds mjs, cjs, mts, cts, razor, cshtml, cc, cxx and hpp. No deviation line in Task
16 records these extras. They fit the user's "C# plus the common languages", but they are scope past the written spec.
The plan requires a deviation in what a task delivers to be recorded in its section. Scenario: Task 13 folds the plan
and deletes it, so the record of which globs were specified and which were added in review is lost. A later audit of the
rule against the plan cannot tell an intended addition from drift, which is the gap the plan's sync rule exists to
close.
Refuted: The finding stands. Task 16's Change lists exactly cs, go, rs, rb, swift, c, cpp, h, php, scala and gradle. The
diff also adds mjs, cjs, mts, cts, razor, cshtml, cc, cxx and hpp. Neither Task 16's Deviation paragraph nor its Result
records them, and the plan's sync rule requires a deviation in what a task delivers to be written inline. The extras fit
the user's ruling, so the cost is only a missing record. Minor.
Fixed: recorded in Task 16 as a deviation.

### R5-20 · minor · plan conformance

bin/check-md-limits:46-49,111,247-254: A new user-facing `--count-raw` option was added to bin/check-md-limits, with its
tip line in tips/24_claude_code.md and tests. It is in no task's Change, and no deviation records it. Task 16's Files
list covers the checker only for the front-matter change, and Task 17's code-review deviations name workflow-docs.yml,
session-end-save.md extras, writing-plans and Tip 24.8, but not this option. It exists so test_workflow_docs.sh can
measure counted lines. Scenario: An unrecorded interface change to a script under bin/ ships in the squash merge. The
plan, which is the only place the change would be explained, is deleted by Task 13, so the option's origin and contract
(exactly one file, exit 2 otherwise) are recorded nowhere but the code.
Refuted: The finding stands. A grep of the reviewed plan finds no `--count-raw`. The diff adds the option to
bin/check-md-limits (lines 46-49, 111 and 415), a tip line at tips/24_claude_code.md:82, and tests in
test_check_md_limits.sh and test_ai_log.sh. No task's Change or deviation list names it: Task 17's code-review
deviations cover workflow-docs.yml, the session-end-save extras, writing-plans/template and Tip 24.8. It is an
unrecorded change to the interface of a script under bin/.
Fixed: recorded in Task 16 as a deviation.

### R5-21 · nit · plan conformance

test/test_workflow_docs.sh:132,169: The plan's Global constraints say scratch repos in tests use literal paths, "never
`cd \"$var\"` or `git -C <path>` for a write". The test's `gitin` helper does `cd "$repo"` for every write, and line 169
runs `git -C "$repo" rm -q --cached plan-x.md`. The comment on line 128 claims this follows test_ai_log.sh's pattern,
but the `git -C` write breaks even that pattern. Scenario: With the guard's shims on PATH (Task 2b), as when the suite
runs inside a Claude session, a `git -C` write is one of the forms the constraint says the guard may block or
misresolve. The test then depends on the guard's gap rather than on the convention every other test follows.
Refuted: The finding stands as a nit. The plan's Global constraint says, for scratch repos "in tests": never `cd "$var"`
or `git -C <path>` for a write. test_workflow_docs.sh:132 defines `gitin` as `(cd "$repo" && git ...)`, and line 169
runs `git -C "$repo" rm -q --cached plan-x.md`, which is a write. test_ai_log.sh:27 uses the same `cd "$d"` subshell
pattern, so the convention is already loose in the repo. The `git -C` write is still a literal breach. The finding's
guard scenario is speculative, because the PreToolUse hook sees only `bash test/...`, so nit is right.

### R5-22 · nit · plan conformance

CLAUDE.md:22: The Task 13 deviation's pointer lists the workflow skills as "(writing-issues, -plans, implementing-plans,
reviewing-in-rounds)". The "-plans" shorthand is not a skill name, so a reader or a grep for `writing-plans` misses that
this line governs it. This was Task 13's Deferred item ("the workflow skills" undefined), and it is now fixed with a
list that has a truncated name. Scenario: Someone about to change claude/skills/writing-plans greps the repo CLAUDE.md
for `writing-plans`, finds nothing, and skips reading staged-workflow.md before the change.
Refuted: The finding stands. CLAUDE.md:22 reads "(writing-issues, -plans, implementing-plans, reviewing-in-rounds)". A
grep for `writing-plans` misses this line, though it is the pointer meant to stop someone from changing that skill
without reading staged-workflow.md first. It is cheap wording, so nit.

### R5-23 · nit · plan conformance

claude/docs/staged-workflow.md:24,62,67,69,74,93: Task 13's Deferred item "sibling docs named bare, not by
`~/.claude/docs/…`" is still open: `implementing-plans-reference.md`, `session-end-save.md`, `work-contexts.md`,
`review-lenses.md` and `skill-precedence.md` are all named bare. Task 13's Change also sets this file at ≤ 100 lines; it
is 101 physical lines (79 counted). Read as counted lines it passes, but the bound is ambiguous. Scenario: An agent that
reads staged-workflow.md from another repo's session, as the CLAUDE.md pointer and work-contexts.md send it to, resolves
`session-end-save.md` against its own cwd and fails to open it. Unless this is fixed, Task 13's issue has to carry it.
Refuted: Part of the finding is refuted. The length bound is counted lines throughout the plan and the checker, and Task
13's Result records "77 counted lines". `bin/check-md-limits --count-raw` prints 79, under 100, so the 101 physical
lines break nothing. The bare sibling-doc names still stand: implementing-plans-reference.md, session-end-save.md,
work-contexts.md, review-lenses.md and skill-precedence.md at lines 24, 62, 69, 74 and 93. That is Task 13's own
Deferred item, still open, so Task 13's issue must carry it if it is not fixed. Nit, on the bare names only.

### R5-24 · nit · the change as a whole

bin/ai-log:209-220 (compute_level); claude/docs/session-end-save.md:10-13: The session-end save takes its level from
`ai-log level`, which gives `customer` whenever the origin isn't on the built-in list and the log clone's `allow` file
can't be read. That includes a machine with no `~/.ai-framework-log` clone. The same happens when `ai-log` exits 2
because bash is older than 5. Either way, the commit and push to the user's own branch now depend on a logging
prerequisite. Scenario: An allow-listed company Forgejo repo (work-context.sh says company) is resumed on a second
machine where the log clone was never cloned. Or it runs on a stock macOS shell without Homebrew bash. `ai-log level`
prints customer, or fails. The session end commits and pushes nothing, so another machine can't resume from a push. The
user's standing rule 'Commit and push the branch' fails for a reason that has nothing to do with the work context. The
doc only reports the reason; it doesn't separate 'can't log' from 'must not push'.
Refuted: Downgraded from minor by the verifier. Downgraded. The behaviour is real: compute_level (bin/ai-log ~199-220)
returns customer when the origin is not github.com/andrelin or github.com/uptimeconsulting and there is no allow file.
But the plan asks for this. Task 17's 'The level' says to use `ai-log level` with its origin allowlist so that an origin
nobody listed gets nothing committed or pushed (R9-50). It fails safe, and session-end-save.md:12-13 already makes the
report quote ai-log's stderr reason, which names the missing clone or the missing allow line, so the user can fix it.
What is left is a design trade-off that the plan accepted, not a defect, so this is a nit.

### R5-25 · minor · the change as a whole

claude/skills/reviewing-in-rounds/SKILL.md:35; claude/docs/session-end-save.md:18-46: The session-end trigger applies to
every code review before `Done (code):`, including `/reviewing-in-rounds code` with no plan. Every step of
session-end-save.md needs a plan: `<stem>`, 'the plan's branch', the `Leftovers` line in
`<stem>-review-findings-code.md` and `ai-log record <plan-file>`. Scenario: A plan-less branch review is interrupted
when the user wraps up. The save can't name the stem, can't check that 'the branch is the plan's', and can't run
`record`. Its steps are undefined, so the session either stops at the branch check or improvises a commit.
Fixed: the trigger covers a code review of a plan; a plan-less review saves nothing and says so.

### R5-26 · minor · the change as a whole

claude/skills/reviewing-in-rounds/SKILL.md:98,102: Completion now runs `ai-log record` 'when there was nothing to
commit', and step 4 offers no commit when nothing is staged. Task 15b's spec says 'once the commit has run', and Task
17's says each session end has its own HEAD and so its own entry. Neither change is recorded as a deviation in Task 15b
or 17. The change also breaks Task 17's own-HEAD assumption: with nothing committed, HEAD is still the last session-end
commit, so the final `record` produces the same id and replaces that session-end entry. Scenario: All tasks are already
in a session-end WIP commit and the final review makes no fixes. Step 7 records at HEAD = the WIP commit. The id equals
the session-end entry's id, so `record` skips that entry in its window search and overwrites `entries/<id>.json` with
one merged window. The per-session-end entry the plan promised is gone, and the introspection is attached to it. The
plan says nothing about this behaviour.
Fixed: recorded in Task 15b as a deviation; the header and Tip 25 say so.

### R5-27 · minor · the change as a whole

test/test_workflow_docs.sh:57-75; plan Task 17 Tests: Task 17's core behaviour has no automated test. That behaviour is:
commit, then delete the refs, after which no ref is left, `git write-tree` equals `HEAD^{tree}` and `Base:` is an
ancestor, both locally and in a fresh clone; and a second empty session end gives a new HEAD. It was checked once by
hand. test_workflow_docs.sh only greps wording, checks line order and runs the two ls-files commands. Scenario: Suppose
a later edit rewords step 4 to delete every `refs/checkpoints/<branch>/*` unconditionally, or drops `--allow-empty` from
the prose while keeping the grepped string elsewhere. The resume invariant breaks: refs are lost after a public-check
restore, or two session ends share an id. CI stays green because no test runs the sequence.
Refuted: Kept at minor, not major. Task 17's Tests name the resume scenario as run 'by the session', and its Result
records that it passed. The plan accepted a by-hand check, so this is not an unmet requirement. Still, nothing in CI can
fail if the ref-deletion or --allow-empty wording regresses; test_workflow_docs.sh only checks wording and the add and
rm commands. Real, but cheap to live with.
Fixed: an executed scratch-repo test runs the doc's commit and ref deletion and checks the resume invariants and a second empty session end.

### R5-28 · nit · the change as a whole

bin/ai-log (entry fields commit, framework.dotfiles_commit); plan Follow-up 15d: Entries store branch shas (`commit`,
`dotfiles_commit`). The squash-merged landing that Task 17 introduces orphans those shas on the default branch.
Follow-up 15d plans to group trends 'by framework commit', which assumes the shas stay resolvable. Scenario: After the
`ai-framework` PR is squash-merged and the branch deleted, every entry's `dotfiles_commit` names a commit that `main`
doesn't contain. 15d can't order those commits or map them to a main commit, except through recorded_at or the PR head
ref.

### R5-29 · nit · the change as a whole

CLAUDE.md:22: '(writing-issues, -plans, implementing-plans, reviewing-in-rounds)' abbreviates writing-plans as '-plans'.
It reads as a typo, and the definition of 'the workflow skills' in Task 13's Deferred line is only half fixed. Scenario:
A reader or a grep for `writing-plans` doesn't find it in the list of skills whose change requires reading
staged-workflow.md.
Refuted: Confirmed: CLAUDE.md:22 reads '(writing-issues, -plans, implementing-plans, reviewing-in-rounds)'. A grep for
writing-plans misses it. Wording only.

### R5-30 · nit · the change as a whole

test/test_workflow_docs.sh:169: The test makes a git write with `git -C "$repo" rm`, although the plan's global
constraint and the file's own comment (line 128: writes 'through a subshell') say to avoid `git -C <path>` for writes.
Scenario: Not a functional failure under the suite. The test breaks the convention its header states, and a reviewer
copying the pattern into a Claude Bash call would hit the guard.
Refuted: Confirmed. test/test_workflow_docs.sh:169 is `git -C "$repo" rm -q --cached plan-x.md`, while the comment at
line 128 says writes go through a subshell (gitin). It breaks the file's own stated convention but has no functional
effect.

### R5-31 · nit · the change as a whole

.github/workflows/markdown.yml:45-46: The baseline step's comment says a pin can only be removed by the file shrinking
under its warn line. Task 16 now also drops a pin from any skill, whatever its size. Scenario: Someone debugging a
dropped skill pin reads the comment and expects a shrink. The check doesn't break, because pins-before is read from
HEAD.
Refuted: Confirmed. check-md-limits (header lines 18-19) says a pin on a skill is ignored and --update-baseline drops
it, but the comment in markdown.yml at line 45 and the error message at line 51 still say a pin goes only when the file
shrinks. Only the wording is stale; the check itself still works.

### R5-32 · nit · the change as a whole

claude/skills/implementing-plans/SKILL.md:9,64,129,145; claude/docs/staged-workflow.md:24,62,67: Several Deferred lines
are still open in the code: the red flag 'Only the session-end commit exists.' (wrong at customer level), 'holds only
those', 'the commit follows the code review', 'each task's paths' without 'reported', and sibling docs named bare
instead of by `~/.claude/docs/…`. They are named in Tasks 17 and 13, so they are handled only if Task 13's issue carries
them. Also, Task 17's Change still says 'reviewing-in-rounds is unchanged', which its deviations contradict. Scenario:
The plan is `git rm`ed before Task 13's issue lists these items, so they are lost. At customer level, the red flag tells
the session a session-end commit exists when none is allowed.
Refuted: Dropped by the verifier. Every item named here is in Task 17's or Task 13's own `Deferred:` lines: the red flag
at customer level, 'holds only those', 'the commit follows the code review' and 'each task's paths'. Task 13 requires
that before the plan is deleted, every item still open in it, the Deferred lines included, goes into Task 13's issue
(plan Task 13, deviation 2026-11-03 R3). So the loss scenario contradicts a rule the plan already has. The
'reviewing-in-rounds is unchanged' contradiction is in the plan text, which is outside the reviewed diff, and Task 17's
code-review deviations already record that change. No new defect beyond the known deferred items.

### R5-33 · minor · fit with the surrounding code

bin/ai-log:1255-1268 and bin/ai-log:1340-1349: cmd_record and cmd_note each carry the same block, line for line: git
add, a commit only if the diff is non-empty, `git pull --rebase` with `rebase --abort` and a warning, then `git push`
with a warning. Only the path and the commit-message verb differ. Every other repeated step in the script (in_log_clone,
require_clone, compute_level, warn) is already a helper. Scenario: A later fix to the log clone's sync goes into one
copy and not the other. Say someone adds a `--autostash` or changes the push warning in record's block: note then
behaves differently on a diverged clone, and no test compares the two. One `commit_and_push <path> <message>` helper
would fit the script's own style.
Fixed: `commit_and_push` serves `record` and `note`.

### R5-34 · minor · fit with the surrounding code

claude/docs/work-contexts.md:358-363: The paragraph opens with "the workflow skills never commit on their own, bar one
exception" and then lists several. implementing-plans' session-end commit and push, reviewing-in-rounds' Completion
commits and its `git rm -f` commit (both on a yes), and ai-log's commit and push to the log repo after a plan's commit
and at each session end. It also credits the session end to `implementing-plans` alone, but reviewing-in-rounds:35 now
triggers the same save. Scenario: Someone checking whether reviewing-in-rounds may commit during a review reads "only
its [implementing-plans'] session end commits" and "bar one exception". From that they conclude a session end inside a
code review must not commit, which contradicts reviewing-in-rounds' new trigger and session-end-save.md's opening line.
Fixed: with R5-18.

### R5-35 · minor · fit with the surrounding code

test/test_workflow_docs.sh:820-824, 861: The comment says the scratch repo's writes go "through a subshell the way
test_ai_log.sh does". Line 861 is a `git -C "$repo" rm -q --cached` write, the form the plan's Global constraints forbid
for scratch-repo writes. Also, the local `gitin` takes no directory argument, while test_ai_log.sh:27 defines `gitin <dir> <args>`.
Same name, different arity, in sibling tests the comment says it copies. Scenario: A maintainer copies a line between
the two test files, for example `gitin "$repo" add x` from test_ai_log.sh. In test_workflow_docs.sh it runs `git <repo-path> add x`
and fails with "not a git command". The `git -C` write contradicts both the comment beside it and the scratch-repo rule
the plan gives every test.
Fixed: the helper is `repo_git` and every write goes through it.

### R5-36 · nit · fit with the surrounding code

bin/check-md-limits:169, 517-521, 541: "A skill has no aim" is encoded as limits_for returning `250 250`, with "equal
numbers mean no aim" as a sentinel that two later places test with `(( warn == hard ))`. Those new branches use `(( … )) && echo`
and `(( … )) && pinned=""` one-liners where the surrounding code uses if-blocks. The SKIP message is also duplicated
verbatim from the next branch. Scenario: A future type given equal aim and cap on purpose, say `50 50`, silently loses
its pins and warnings. Under `set -e` the `&&`-list idiom also differs from the neighbouring if-blocks, which a reader
has to re-check. An explicit `none` aim or a named predicate would read as the intent.
Refuted: Partly stands. limits_for does encode 'no aim' as equal warn and hard ('250 250'), and two later sites test it
with (( warn == hard )). The sentinel reads as an implicit convention, and a future type given equal numbers on purpose
would lose its pins. The style part is weak: the neighbouring elif branch already uses the `[[ -n "$pinned" ]] && new_pins+=...`
one-liner, and the && lists are safe under set -e. The duplicated SKIP message is real. It remains a nit.

### R5-37 · nit · fit with the surrounding code

bin/ai-log:89-94: bin/ai-log defines `die <rc> <msg…>`, while its sibling bin/ai defines `die <msg…>`, which always
exits 2. Both scripts were written as a pair (the plan says "like `bin/ai`"), and the same helper name now has two
signatures. Scenario: Someone moving a check from bin/ai into bin/ai-log writes `die "no such plan file"`. bash then
runs `exit "no such plan file"`, which fails with "numeric argument required" (exit 2 by accident) instead of printing
the message.

### R5-38 · nit · fit with the surrounding code

bin/ai-log:115-124: resolve_tree re-implements the by-hand symlink walk that bin/check-md-limits:68-78 already has as
`resolve_symlink`, under a different name and with a slightly different shape. bin scripts are standalone, so copying is
accepted, but the name should match. Scenario: A reader grepping for `resolve_symlink` to fix a symlink-resolution bug,
such as a relative link through a symlinked parent dir, finds one copy and misses the one in ai-log.
Refuted: Dropped by the verifier. Refuted. resolve_tree is not the same function under another name. check-md-limits'
resolve_symlink takes a path argument and returns the resolved file. resolve_tree takes no argument, walks
BASH_SOURCE[0] and returns the tree root (the parent of the script's directory, resolved with cd -P). It also resolves
relative links against the physical directory, which resolve_symlink does not. The different name describes a different
result. Renaming it resolve_symlink would mislabel it, and a grep for symlink handling finds both through readlink
anyway.

### R5-39 · nit · fit with the surrounding code

test/test_ai_log.sh:172: `edit_plan() { … }` is the only function in the file declared without the `function` keyword.
Every other one in this file and in test_workflow_docs.sh uses `function name() {`. Scenario: Style drift only. fn_src
at test_ai_log.sh:1345 already has to accept both forms when it greps sources.

### R5-40 · nit · fit with the surrounding code

test/test_workflow_docs.sh:740-766: Fifteen assertions repeat the pattern `assert "$([[ $(count X "$SAVE") -ge 1 ]] && echo yes)" "yes" …`.
first_line (757) repeats the grep/cut that counted_line (728) already does inline. A small `has <needle> <file>` helper
would match how the file factors count and counted_line. Scenario: A reworded needle has to be changed inside the nested
`$( [[ $(…) ]] )` of each copy, and a failing assertion prints only "yes" vs "", without the count.

### R5-41 · nit · fit with the surrounding code

CLAUDE.md:22: "the workflow skills (writing-issues, -plans, implementing-plans, reviewing-in-rounds)" shortens
writing-plans to "-plans". The names are also unformatted, while every other skill name in the repo's CLAUDE.md and docs
is a backticked full name. Scenario: A reader or a grep for `writing-plans` doesn't find it in the pointer meant to stop
edits to that skill without reading staged-workflow.md first.

### R5-42 · nit · fit with the surrounding code

claude/docs/session-end-save.md:34: The placeholder `git diff --cached <Base:>` keeps the colon of the plan line inside
the angle brackets. Sibling docs and skills write `Base:` for the line and `<Base>` or "the plan's `Base:` sha" for the
value. test_workflow_docs.sh:877 pins this odd spelling. Scenario: An agent pastes the command with the value written
`<sha>:`, or reads `<Base:>` as a ref named `Base:`. Fixing the wording later also needs a test edit.

### R5-43 · nit · fit with the surrounding code

claude/docs/staged-workflow.md:68, 77, 81; claude/docs/work-contexts.md:363: staged-workflow.md names sibling docs bare
(`session-end-save.md`, `review-lenses.md`, `implementing-plans-reference.md`, `work-contexts.md`). Its neighbour
work-contexts.md and the skills write the full `~/.claude/docs/…` path. Task 13's own Deferred line records this, and it
is still open. Scenario: An agent loading staged-workflow.md from a project directory resolves `session-end-save.md`
against the cwd, finds nothing, and skips the steps it points to.

### R5-44 · nit · fit with the surrounding code

tips/25_ai_framework.md:3: The new tips file's title "AI framework" is in sentence case. Its neighbours are title case:
"Claude Code Integration", "Local Dev Infrastructure", "Shell and Repo Workflow". Scenario: Style drift only: the tips
index lists "25. AI framework" beside "24. Claude Code integration" (the index itself is mixed).

### R5-45 · minor · docs ship with the change

claude/docs/staged-workflow.md:68-69: The doc says ai-log stores "the names of the repo, plan, tools, skills, agents and
models (hashed at company level)". bin/ai-log hashes only `repo` and `plan` at company level (around line 1192). Project
skills, custom agent types and MCP tools are stored only as counts or placeholders (`_project`, `_custom_agent`,
`_mcp`), built-in tool names and model ids are kept, and nothing else is hashed. Scenario: Someone changing ai-log reads
the 'why' doc first, as the repo CLAUDE.md tells them to. They conclude that model and tool names are hashed at company
level and that free-standing model ids are already protected, then drop the model-id narrowing (bin/ai-log:312) as
redundant. The doc no longer describes what the script does.
Fixed: staged-workflow.md says only repo and plan are hashed; project skills, custom agents and MCP tools are counts.

### R5-46 · minor · docs ship with the change

claude/docs/work-contexts.md:85-91: Line 85 says the workflow skills never commit on their own "bar one exception". The
paragraph then describes two commits made without a per-action yes: the session-end WIP commit and push, and ai-log's
commit and push to the log repo (after Completion and at each session end). Line 91 lists "tool, skill, agent and model
names" as leaving the machine but does not say that at company level project skills, custom agents and MCP tools leave
only as counts. Scenario: A reader uses this paragraph to check what may be committed or pushed without asking. They
count one exception and treat ai-log's standing-yes push to the log repo as an unapproved write. Or they assume a
company repo's project-skill names reach the private log, when the script stores only counts.
Fixed: with R5-18.

### R5-47 · minor · docs ship with the change

claude/skills/implementing-plans/SKILL.md:145: This red flag was reworded to "Only the session-end commit exists." Task
17's Deferred line flagged it as wrong at customer level, where session-end-save.md commits nothing, and it is still
unfixed. The opening line ("nothing is committed bar the session-end commit: the commit follows the code review") is
also still ambiguous, which Task 17 deferred too. Scenario: An implementer at customer level reads the red flag and
believes a session-end commit is part of the workflow there. session-end-save.md § At customer level forbids that
commit, and the guard blocks it. The skill and its doc now contradict each other on a forbidden write.
Fixed: the opening says commits come only at a session end and after the code review; the red flag is reworded.

### R5-48 · minor · docs ship with the change

tips/25_ai_framework.md:19-21: The tip's exit-code list puts all of exit 2 under "usage or a missing clone".
bin/ai-log's header also exits 2 when the clone's origin is not the log repo (the tip only mentions that later) and when
`note` gets empty input or a missing heading. Exit 1 is also missing two causes: a given commit no newer than the window
start, and no assistant record parsed. Scenario: A user pipes an empty introspection to `ai-log note <id>` and gets exit
2. The tip says exit 2 means usage or a missing clone, so they look at the clone instead of the input.
Fixed: the exit-code list is complete.

### R5-49 · nit · docs ship with the change

tips.md:57: The index entry says "`level` prints the work context". `ai-log level` prints its own gated level, which
reports customer for an unlisted company-resolving origin or a non-allowlisted host, even where work-context.sh says
company. Tip 25.1 states this correctly ("by the rule record applies"). Scenario: A user runs `ai-log level` in a
Forgejo company repo that is not in `allow`, sees `customer`, and takes the index to mean the work-context guard thinks
the repo is customer.

### R5-50 · nit · docs ship with the change

tips/24_claude_code.md:88-89: "its first 100 lines hold the task" omits "counted", and the paragraph never says that
`.md-baseline` pins do not apply to skills. Line 89's "a file nearing its aim gets a note" is inaccurate: the checker
notes a file that has passed its aim, not one nearing it. Part of this is Task 16's deferred wording, still open.
Scenario: A reader trims a skill so its 100 raw lines, front matter and blanks included, hold the task, or pins a skill
expecting the pin to be enforced; check-md-limits silently drops a skill's pin.

### R5-51 · nit · docs ship with the change

claude/rules/markdown-limits.md:31: The rule still says "A file over its warn line can be pinned" without excluding
skills. A skill no longer has a warn line, and its pin is ignored and dropped by `--update-baseline`, which only the
reference doc (markdown-limits.md:47) says. Scenario: An author pins a long skill by editing .md-baseline by hand,
believing the pin stops it growing. The checker ignores the pin, so the skill can grow to 250 lines without anything
flagging it.
Refuted: Dropped by the verifier. Refuted. The same rule's table (claude/rules/markdown-limits.md:19) gives a skill no
aim ("—" | 250), so a skill has no warn line, and "A file over its warn line can be pinned" does not apply to one. In
the script, warn == hard for a skill, so being "over its warn line" already means failing the cap. The rule therefore
never invites pinning a skill below 250. Nothing flagging a skill under 250 is the intended design, not a missing pin.

### R5-52 · nit · docs ship with the change

CLAUDE.md:22: The new pointer abbreviates writing-plans as "-plans" in "(writing-issues, -plans, implementing-plans,
reviewing-in-rounds)". That is not a skill name, and a grep for `writing-plans` does not find it. Scenario: Someone
greps CLAUDE.md for `writing-plans` to see which docs govern changing it, misses this line, and skips
staged-workflow.md.
