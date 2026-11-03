<!-- DOCTOC SKIP -->

Leftovers before round 1: none

## Round 1

Seven lenses, all verified. Findings most severe first; nits and refuted findings follow.
The run stopped here on 2026-11-02 at the user's request; the resumed session fixed them on 2026-11-03.

### R1-1 · major · tests (also correctness, downgraded there to minor)

`bin/dotfiles` `init_files()` calls `migrate_init_selection` after the cache read, and no test reaches the call:
deleting it passes every test, and every machine with a cache comes up with `52_claude.sh` unticked.
Suggested fix: move the cache read and the migration into one function above the source-mode return
(`read_init_cache <file>`), called from `init_files`, and test it against a temp file holding `52_macos_claude.sh`.
Fixed: `read_init_cache <file>` above the source-mode return, called by `init_files`; tested against a temp cache, a grep holding the call site.

### R1-2 · major · security (also whole-change, minor)

`bin/check-hidden-unicode`'s default set excludes `claude/skills/unslop/`, while `writing-mr-descriptions` now has
every PR/MR pass read `~/.claude/skills/unslop/SKILL.md`: a hidden instruction arriving in an upstream re-sync passes
pre-commit and CI. The scanner only reads, so scanning a vendored file edits nothing; it scans clean today.
Fix: drop the exclusion (script, its usage header, Tip 24.9, the default-set test fixture) and record it as a
deviation from Task 12's Interfaces.
Fixed: exclusion dropped from the script, its usage header, Tip 24.9 and the test fixture (seven files); Task 12 Deviation.

### R1-3 · minor · security, correctness

Missed characters the spec's own categories cover: U+061C ARABIC LETTER MARK (bidi), U+180B-180D and U+180F
(Mongolian variation selectors); cheap to add with U+206A-206F (`\xE2\x81[\xA0-\xA4\xA6-\xAF]`, `\xE1\xA0[\x8B-\x8F]`,
`\xD8\x9C`). `test/test_check_hidden_unicode.sh` asserts U+206A passes: move it to the flagged cases.
Fixed: the four ranges added; U+206A moved to the flagged ends, U+061B/061D, U+180A, U+1810, U+2070 added as passing neighbours.

### R1-4 · minor · security

`--cached` scans a tracked symlink's blob, the target path, not what the agent reads; CI's worktree mode follows it.
Suggested fix: in mode b, when `-l $label && -f $label`, also scan the file it resolves to.
Fixed: mode b scans the file behind a tracked symlink after its blob; tested.

### R1-5 · minor · security

`.github/workflows/markdown.yml`: the hidden-Unicode step runs after the length step with no `if:`, so a length failure
hides its report. Fix: `if: ${{ !cancelled() }}`.
Fixed: `if: ${{ !cancelled() }}` on the step.

### R1-6 · minor · correctness

Worktree mode: a dangling tracked file symlink in the default set gives "no such file" and exit 2 (Task 12's
`Deferred:` names only the directory case). Suggested fix: in the default set, worktree mode, skip what isn't `-f`,
which also settles that `Deferred:` line.
Fixed: the default set skips what isn't a regular file, in both modes, silently;
tested with a dangling and a directory symlink and an unstaged deletion.

### R1-7 · minor · fit, docs (nit)

`.claude/rules/scripts.md:29-30`: Claude Code never runs `bin/check-hidden-unicode`, and `env bash` is Apple's 3.2
only without Homebrew on the `PATH`. Reword: "which `hooks/pre-commit` runs through `env bash`, Apple's 3.2 unless
Homebrew's bash is on the `PATH`".
Fixed: reworded as suggested.

### R1-8 · minor · fit

`test/test_check_hidden_unicode.sh`: "Everything below needs git repos. Each is created in a call of its own." is
false (the code uses `git -C "$repo"`). Delete the second sentence.
Fixed: sentence deleted.

### R1-9 · minor · tests

`test/test_init_selection.sh` "empty selection stays empty": the function runs in a subshell, so the count restates the
test's own `()`. Run it in the current shell, then assert.
Fixed: runs in the current shell, output to a temp file.

### R1-10 · minor · tests

Nothing automated holds `bin/check-hidden-unicode`'s bash 3.2 requirement. Add a run through `/bin/bash "$CHECKER"`
when `/bin/bash` is 3.x.
Fixed: `/bin/bash "$CHECKER"` cases, `--cached` and the default set, when `/bin/bash` is 3.x.

### R1-11 · minor · tests

`migrate_init_selection` under zsh is untested though sourced into every interactive zsh. Add a `zsh -f` case when
zsh is installed (it passes today).
Fixed: a `zsh -f` case when zsh is installed.

### R1-12 · minor · plan conformance, whole-change

`claude/docs/skill-precedence.md`'s `finishing-a-development-branch` row allows a clean local merge and `git pull`;
the spec said stop before merge into base. Consistent with the global rules; record a `Deviation:` in Task 4.
Fixed: Task 4 Deviation recorded.

### R1-13 · minor · plan conformance, whole-change (tests: nit)

`claude/docs/work-contexts.md:27-30` departs from the spec's exact line (prefix, three lines, a fourth sentence on
customer work); its `grep -F` test can't pass. Record a `Deviation:` in Task 4.
Fixed: Task 4 Deviation recorded.

### R1-14 · minor · docs

On a customer self-review `reviewing-locally` and `reviewing-in-rounds` both fire; only `skill-precedence.md` says the
latter takes the fetch, never the rebase. Add that line to `claude/skills/reviewing-in-rounds/SKILL.md`, as
`reviewing-for-feedback:25` has.
Fixed: a line in § *The inputs*.

### R1-15 · minor · docs

The renamed-init-script convention (an `old:new` entry in `bin/dotfiles`' `renamed_init_scripts`) is in no rule or
README. Add it to `init/README.md`, which `scripts.md` sends a renamer to.
Fixed: a paragraph at the end of `init/README.md`.

### R1-16 · nit · various, left

Fit: truncated comment `test/test_init_selection.sh:32` (already `Deferred:`; trailing whitespace too), redundant
`&& exit 0 || exit $?`, `migrate_init_selection` idiom drift, the test's own `DOTFILES` override, the step's home in
`markdown.yml`, Tip 24.4 narrating the rename. Correctness: Tip 24.3 says "a staged file", `top` read from the
environment, `:/` and `1:foo` specs, unmerged entries listed per stage, a newline in a tracked name.
Conformance: Task 4's mention lines, Task 11's Check-first and deliberate-failure results, Task 7's audit re-run
(each verified as holding, only unrecorded), condensed table rows, the three-line `unslop` pointer.
Tests: the ZWJ two-hit case (unrecorded clarification). Docs: the tips intro, scripts.md's reason.

### R1-17 · refuted

Fit: the batching header comment (a real *why*), the error-prefix style (`bin/ai` uses the same).
Correctness: the default-set scope (spec-defined), an empty set passing (exact counts tested), check before
re-stage, the zsh global. Conformance: CLAUDE.md's line count (the user's recorded edit), Tip 24.3's edit (recorded).
Tests: gitlink and `-- -x` (tested by hand, work). Docs: Tip 24.9's exit 2 (in the usage header), `VENDORED.md`,
the work-contexts placement, Task 7's result (Task 13 folds it), Tip 24.3's rewrap (already `Deferred:`).
Security: plan and eval files in the default set (deliberately scoped).

### R1-18 · note

A tests verifier's experiment ran `sed -i` in the real repo after a failed `rsync`; it restored `bin/dotfiles` from the
index. Checked: the index equalled checkpoint 7's tree and nothing but the plan was unstaged.

### R1-19 · minor · change as a whole

Raw-byte matching flags random binary content: a 400 KB random file under `claude/` gave U+00AD hits and exit 1, so a
future binary asset or `.secret` there would block every commit. Nothing binary is tracked there today.
Suggested fix: in the default set, skip files git sees as binary (`git grep -I -l ''`-style, or perl's `-B`).
Fixed: the default set skips content with a NUL in its first 8000 bytes, git's test; a named binary file is still scanned.

### R1-20 · nit · change as a whole, left

The run's one commit carries the user's § *Language* edit; its message names it. Trailing whitespace at
`test/test_init_selection.sh:32` (fix with R1-16's comment). `bin/ai:14` says `AI_MODEL_IMPLEMENT` is "read by the
skill", now the reference doc. Refuted: the redundant dedup (the spec requires it), RHEL's perl (the test guards it).
Duplicates of R1-2, R1-12 and R1-13 are folded into those.

## Round 2

Seven lenses, all verified; cross-lens duplicates folded into one entry, most severe first.

### R2-1 · major · tests, security (correctness: minor)

`bin/check-hidden-unicode`'s default set skipped any file with a NUL in its first 8000 bytes (R1-19's fix), so one stray
NUL in a tracked `claude/*.md` hid every hidden character in it from pre-commit and CI.
Fixed: no content-based skip; a file with the `binary` attribute in `.gitattributes` is left out, and any other NUL in
the default set is reported as a hit, the rest of the file still scanned; tests for both modes and the attribute.

### R2-2 · major · tests (correctness, security, whole-change: minor)

`--cached` read a symlink's target from the working tree: a staged hit in the target passed when cleaned unstaged, an
unstaged edit to `claude/shims/shim.sh` blocked every commit through its four tracked symlinks, reported as `gh`.
Fixed: a staged symlink is resolved from its blob and the target's staged blob scanned, chains followed, each target
once, reported under its own path; tests for staged-dirty/worktree-clean, the reverse, a chain and two links.

### R2-3 · minor · correctness

`--cached` with a relative path leaving the repository made `git cat-file --batch` die: exit 255, later files unscanned.
Fixed: every named path is resolved to the toplevel; outside it is "no such file"; tested from a subdirectory.

### R2-4 · minor · correctness (security: nit)

U+034F, U+115F-1160, U+17B4-17B5, U+3164, U+FFA0 and U+FFF9-FFFB rendered invisibly and passed.
Fixed: added, with ends and neighbours tested.

### R2-5 · minor · tests

`migrate_init_selection` matched each entry against the original name, so `a:b b:c` left `c` unticked.
Fixed: chains followed; tested in both orders.

### R2-6 · minor · tests

The `read_init_cache` call-site test grepped the source.
Fixed: the wrapper is gone; the test lifts `init_files` out of `bin/dotfiles` with `prompt_menu` stubbed and checks
its output and the rewritten cache.

### R2-7 · minor · tests

The `--cached` and subdirectory default-set assertions counted lines only. Fixed: exit code and names asserted.

### R2-8 · minor · tests

`--` and a dash-leading file name were untested. Fixed: tested.

### R2-9 · minor · security

A UTF-16 agent file was never scanned. Fixed by R2-1: its NULs are reported.

### R2-10 · minor · plan conformance

R1-14's line in `reviewing-in-rounds/SKILL.md` was in no Files list and unrecorded. Fixed: Task 4 Deviation.

### R2-11 · minor · plan conformance

Task 11's *Check first* results were unrecorded. Fixed: re-run and recorded in Task 11.

### R2-12 · minor · fit

The checker was bash-3.2-safe with a `scripts.md` exception, where its siblings re-exec under Homebrew's bash; a later
bash-4 construct would pass Linux CI and break the hook on a Mac. Fixed: the siblings' preamble, the exception
reverted, the `/bin/bash` test now checks the re-exec; Task 12's deviation updated.

### R2-13 · minor · fit (correctness, docs: nit)

Tip 24.4 narrated the rename and read as if the machine ticked `52_claude.sh` itself. Fixed: says it runs by default
everywhere, and to tick it by hand once where a saved selection predates it.

### R2-14 · minor · fit

`markdown.yml` triggered on `test/test_check_hidden_unicode.sh`, which it never runs. Fixed: entry removed.

### R2-15 · minor · docs

`claude/skills/unslop/VENDORED.md` says repo checks don't apply, but the scan now covers it; vendored files are never
edited. Fixed: Tip 24.9 says a hit blocks a re-sync, which is held and raised upstream.

### R2-16 · nit · various, left

A failing `git ls-files` in the process substitution passes; directory and unknown-option assertions check rc only;
the ZWJ two-hit case and `skill-precedence.md` row wording unrecorded; Tip 24.4's wording against the spec; the Task 4
`Deferred:` lines live only in the plan; `ERROR:` prefix style; `run_in` duplicating `run`; the test's `DOTFILES`
comment; `tips.md` and Tip 24.3 wrapping; Tip 24.3's "a staged file"; `docs/how-it-works.md`'s platform lists.
Settled anyway by other fixes: the stale Task 11 `Deferred:` line and status row, `read_init_cache` in zsh, the exit
idiom, Tip 24.9's exit 2.

### R2-17 · refuted

Docs: `scripts.md` not naming `renamed_init_scripts` (it sends a renamer to `init/README.md`, which now does).

## Round 3

Seven lenses, all verified; cross-lens duplicates folded, most severe first.

### R3-1 · major · correctness (security, whole-change: minor)

The default set dropped every file with the `binary` attribute, so `*.md binary` in a nested `.gitattributes` hid an
agent-loaded `SKILL.md` from pre-commit and CI, and GitHub hides a binary diff from review too.
Fixed: the attribute skips a file only when it does hold a NUL; a `.md` so marked with a U+202E is flagged, both modes.

### R3-2 · major · security (tests: minor)

`--cached` sent `:<path>`; a leading `1:` is a merge stage, so `1:evil/CLAUDE.md` came back missing and was skipped.
Fixed: `:0:<path>`, and `:0:.git/not-a-spec` for a path outside the repo (no `:/` history search); tested.

### R3-3 · minor · correctness (tests: nit)

No bash 4 exited 1, the code for a hit. Fixed: exit 2, the script's own prefix; header and Tip 24.9 say so.

### R3-4 · minor · correctness

One tracked name with a newline aborted every `--cached` run, so every commit. Fixed: read by its object id; tested.

### R3-5 · minor · correctness

A named UTF-16 file passed silently. Fixed: a NUL is reported in named files too; tested.

### R3-6 · minor · tests

The worktree symlink test only passed a clean target. Fixed: a hit through a symlink, under the symlink's name.

### R3-7 · minor · tests

The flagged-ends loop's glob matched extra lines. Fixed: one line required.

### R3-8 · minor · tests

The gitlink skip had no test. Fixed: a `160000` entry in the skip fixture.

### R3-9 · minor · security

`:(glob)**/CLAUDE.md` missed `docs/claude.md`, which a case-insensitive filesystem loads. Fixed: `icase`; tested.

### R3-10 · minor · change as a whole

Task 13 deletes the plan with open `Deferred:` lines, Task 7's conflict and Task 11's pending checks in it.
Fixed: a Task 13 deviation carries them into an issue, on the user's yes, before the delete.

### R3-11 · minor · change as a whole

`skill-precedence.md`'s "on company work the rows don't apply" freed `superpowers:writing-plans`' commit steps (Task 4's
second `Deferred:`). Fixed: the row and the sentence say the personal `writing-plans` holds at every level.

### R3-12 · minor · docs

Tip 24.3 said only staged files being committed are checked. Fixed: the staged copy of any agent-loaded file, NUL too.

### R3-13 · minor · docs

`unslop/VENDORED.md` doesn't say the scan applies, and the directory is never edited. Fixed: `.claude/rules/vendored.md`,
loading under `claude/skills/unslop/`, says it does and that a hit holds the re-sync.

### R3-14 · nit · various, left

The 8-hop symlink limit; the `:/` spec's history search (settled by R3-2); `ERROR:` (settled by R3-3); the `/bin/bash`
and zsh cases skipped silently off their platforms; the pre-commit fixture's extra staged file; two exit-2 paths untested;
UTF-16 without a NUL; scratch-repo `git -C` against the plan's agent rule; Tip 24.4's cause; three `skill-precedence.md`
rows' reasons; `--` unrecorded in Interfaces; `markdown.yml` as the step's home and its comment; `_` in
`migrate_init_selection`; `# perl alone.` (settled); `run`/`run_in`; the header's symlink wording (settled); Tip 24.7
on the plugin answering during an eval; Tip 24.3's wrap; `work-contexts.md`'s placement; Task 7's audit re-run record.

### R3-15 · refuted

Conformance: Tip 24.3's edit (in Task 12's Files and recorded). Docs: `safety.md` not naming the script (a survey, true).

## Round 4

Seven lenses, all verified; cross-lens duplicates folded, most severe first.

### R4-1 · major · tests

U+E0100-E01EF spans two regex branches, and only the outer ends were probed: narrowing `[\x84-\x86]` passed every test.
Fixed: U+E01BF and U+E01C0 probed.

### R4-2 · major · tests

The no-bash-4 fallback's exit 2 never ran in a test. Fixed: a copy with no candidates, run by `/bin/bash` 3.x.

### R4-3 · major · change as a whole

`bin/check-md-limits --no-warn` failed on two tracked plan-file lines past 150 characters, blocking the commit and CI.
Fixed: both wrapped; the repo passes.

### R4-4 · minor · correctness

`--cached` ignored a staged symlink whose target is absolute or outside the repo, which worktree mode follows.
Fixed: such a target is read from disk, under the link's name; tested, with a relative link climbing out.

### R4-5 · minor · correctness (security: nit)

U+2800, U+13430-1343F and U+1D173-1D17A passed. Fixed: flagged, ends and neighbours tested.

### R4-6 · minor · correctness

`markdown.yml` didn't trigger on `.gitattributes`, which changes the verdict. Fixed: `**/.gitattributes`. Its missing
test-file trigger is R2-14's deliberate removal, recorded in Task 12.

### R4-7 · minor · tests

No `--cached` run on a named file with a NUL. Fixed: tested.

### R4-8 · minor · tests

`--cached` symlink edges untested: outside targets, a cycle. Fixed: tested.

### R4-9 · minor · tests

`init_files`' no-cache defaults were untested. Fixed: `get_os` stubbed, `52_claude.sh` ticked on Linux.

### R4-10 · minor · security

`binary` plus one NUL still hid a file. Fixed: the attribute only silences the NUL report; the regex always runs.

### R4-11 · minor · security

A symlink to a directory was skipped, so a skill vendored as a linked directory went unscanned.
Fixed: worktree mode walks it; `--cached` scans the staged files under its target; tested.

### R4-12 · minor · plan conformance (whole-change, docs: downgraded from major)

`.claude/rules/vendored.md` is untracked, so no round saw it: the review input said "no untracked files".
Fixed: it is among the commit's paths, and from round 5 the review input lists untracked files.

### R4-13 · minor · change as a whole

The `finishing-a-development-branch` row left its cleanup step's commit option open (Task 4's first `Deferred:`).
Fixed: the row says to draft it.

### R4-14 · minor · fit

The bash 4 guard gave no reason, though nothing in the script needs bash 4. Fixed: a comment saying why it stays.

### R4-15 · minor · fit

Only the hidden-Unicode step ran after a failure; a hit then hid the baseline and doctoc checks.
Fixed: every check after markdownlint runs under `!cancelled()`, one comment above them.

### R4-16 · minor · docs

`reviewing-locally` step 3 still said to rebase with no pointer to the overlap rule. Fixed: never when
`reviewing-in-rounds` or `reviewing-for-feedback` runs the review.

### R4-17 · minor · docs

Tip 24.3 claimed every agent-loaded file. Fixed: the staged copy of a file in Tip 24.9's default set.

### R4-18 · nit · various, left

Case-mismatched named paths under `--cached`; UTF-16 without a NUL; `core.symlinks=false` checkouts; Tip 24.4 naming
RHEL; Tip 24.9 promising "invisible characters" in general; the deliberate-failure record; the ZWJ fixture record;
`writing-mr-descriptions`' pointer wording; Tip 24.3's wrap; the tips file's length; the header's process-count sentence;
error-prefix style; `.claude/rules/markdown.md`'s hook paragraph; `safety.md`; the tips file as a whole.

### R4-19 · refuted

The zsh and `/bin/bash` cases' silent skips; `skill-precedence.md` line 21 and three rows; `test_init_selection.sh`'s
setup; `bin/dotfiles`' "reach both" comment; Task 11's Built note.

## Round 5

Seven lenses, all verified, the untracked `.claude/rules/vendored.md` in the input this time; duplicates folded.

### R5-1 · major · security (correctness: minor)

A UTF-16 file marked `binary` hid completely: the attribute silenced its NUL report, and the UTF-8 matcher sees nothing.
Fixed: no attribute exempts a file; every NUL in the default set is reported; tested with `claude/** binary`.

### R5-2 · major · change as a whole, docs (conformance: minor)

R4-16's `reviewing-locally` line said the review skills "take only steps 1 and 2"; step 2 is `origin/main...HEAD`,
which drops uncommitted work, against `reviewing-in-rounds` and `skill-precedence.md`. Fixed: "only step 1, the fetch".

### R5-3 · minor · correctness (security: minor)

`--cached` took a staged link to an untracked in-repo file for an empty directory and skipped it. Fixed: read from disk.

### R5-4 · minor · correctness (security: minor)

`scan_tree` ignored the binary attribute that `--cached` honoured. Settled by R5-1: no attribute is honoured.

### R5-5 · minor · correctness (security: minor)

`markdown.yml`'s paths missed files outside them reached through a link. Fixed: the step moved to
`.github/workflows/hidden-unicode.yml`, on every push; `markdown.yml` is back as it was.

### R5-6 · minor · tests

No test reached the out-of-repo fallback for a relative link. Fixed: `../../outside.txt`, existing, scanned.

### R5-7 · minor · tests

The non-blob branch never ran: the gitlink's object was fake. Fixed: a gitlink to a real tree object, named.

### R5-8 · minor · tests, correctness (nit)

A perl `die` or git failure exited with errno or 255, not 2. Fixed: a `__DIE__` handler exits 3, the shell maps any
code past 2 to 2 with a line saying so; tested with a `git` whose `cat-file` fails.

### R5-9 · minor · plan conformance, change as a whole

The `reviewing-locally` edit was in no Files list. Fixed: Task 4 Deviation.

### R5-10 · minor · change as a whole

Task 7's audit re-run was never recorded. Fixed: re-run by one read-only agent, recorded in Task 7; its one new stale
fact (`markdown-limits.md` saying `claude/CLAUDE.md` is pinned) removed.

### R5-11 · minor · fit

A hit printed bare lines with no remedy, unlike the hook's other checks. Fixed: a stderr line saying what to do.

### R5-12 · minor · docs

Tip 24.9 said the `binary` attribute skips a file. Fixed with R5-1: a NUL is reported whatever `.gitattributes` says.

### R5-13 · minor · docs

`claude/skills/unslop/VENDORED.md` still says this repo's conventions don't apply, though the scan now covers it; also
R2-15 and R3-13. Not fixed: the user's standing rule forbids editing `claude/skills/unslop/`; asked.

### R5-14 · nit · various, left

`ls-files` listing unmerged paths per stage; the Flagged list's breadth; `skill-precedence.md` row wording and its
line 21–40 layout; work-contexts placement; the status table's rows 4 and 12; Tip 24.3's wrap; the odd-names
assertion's `sed`; the no-cache init test's narrowness; Tip 24.9's symlink and exit sentences; `vendored.md`'s
frontmatter; `test_init_selection.sh`'s setup comment; several files' long lines.

### R5-15 · refuted

`claude/CLAUDE.md` § *Language*; `bin/dotfiles:98`; Tip 24.9's first sentence.

## Round 6

Seven lenses, all verified; launched before the user set the scanner's bar in Task 12, which is applied to this round's
findings below. Duplicates folded.

### R6-1 · major · change as a whole

R4-11's directory walk used `File::Find`, which RHEL 9's perl-interpreter lacks: the RHEL leg failed two assertions.
Fixed: a walk of its own with `opendir`, nested links followed, each directory once by device and inode.

### R6-2 · major · change as a whole

Task 11's Docker legs ran on 2026-11-02, before rounds 1-5 changed the checker and the init-selection test.
Fixed: both legs re-run in Docker, install, error scan and suite all passing; recorded in Task 11.

### R6-3 · major · tests (correctness: minor)

`--cached` skipped a staged link to an untracked directory. Fixed: read from disk, as is a link to a gitlink; tested.

### R6-4 · minor · correctness

`cat-file --batch` strips a trailing CR, so a name ending in one was read as its CR-less neighbour or skipped.
Fixed: read by object id, like a newline name; tested, and the fix mutation-checked.

### R6-5 · minor · correctness, security (tests: downgraded from major)

`--cached` gave up after 8 links silently. Fixed: 40, the kernel's own order, then exit 2 saying so; tested at both.

### R6-6 · minor · correctness

A staged link to a gitlink was dropped. Fixed with R6-3: the submodule's files are read from disk.

### R6-7 · minor · security

Worktree mode didn't enter a directory link nested in a linked directory. Fixed with R6-1; tested.

### R6-8 · minor · security

`hidden-unicode.yml` ran on push only, so a fork's pull request was never checked. Fixed: `pull_request` too.

### R6-9 · minor · tests

No hook test for a scan that can't run. Fixed: the hook with a failing `git cat-file` blocks the commit.

### R6-10 · minor · plan conformance

Task 4's note gave a count, not each non-table name's matching line. Fixed: the five lines recorded.

### R6-11 · minor · plan conformance (whole-change, docs: nit)

Tip 24.4 called the old script macOS-only and told every Linux machine to tick it. Fixed: only where unticked, RHEL
named, and why.

### R6-12 · minor · change as a whole (conformance, fit: nit)

Tip 24.9's exit-2 causes left out a git or perl failure. Fixed.

### R6-13 · out of scope, by the bar

Security: a UTF-16 file with no NUL byte passes (major as reported); further Default_Ignorable code points
(U+1BCA0-1BCA3, U+2065, U+FFF0-FFF8, unassigned plane-14 ranges) pass (minor). Both are accepted gaps.

### R6-14 · nit · various, left

Compile-time perl failures exit 2 without "the scan failed"; `set -u` with an empty selection under bash 3.2; the
odd-names assertion's `sed`; the test's helper sourcing; `skill-precedence.md`'s "only local history" and the overlap
bullets' order; Tip 24.3's wrap; the tests' stale setup comments; `_` not `local`; the `get_os` stub uncommented; wrap
widths in `claude/CLAUDE.md` and `skill-precedence.md`; Tip 24.7 on the plugin answering; Tip 24.9's omissions.

### R6-15 · refuted

The `/bin/bash` blocks' skips (the macOS leg runs them); Task 11's settled `Deferred:`; `work-contexts.md`'s placement;
`work-contexts.md`'s every-level line; the old `vendored.md` rule (now dropped); `safety.md`.

## Round 7

Seven lenses, all verified, the reviewers and verifiers given Task 12's bar; duplicates folded.

### R7-1 · major · correctness, security

`--cached` looked a link's target up by its string path, so one passing through a staged directory link
(`claude/l.md -> ../docs/d/x.md`, `docs/d -> real`) had no index entry and was read from disk: a staged U+200B passed.
Fixed: the whole index is read once and staged directory links along a target's path are resolved; tested both ways.

### R7-2 · major · tests (correctness: minor)

Only `git cat-file --batch` failing was tested; a failing default-set `ls-files` (a process substitution), `ls-files -s`
or `cat-file blob` passed clean. Fixed: each fails the run with exit 2; tested with a `git` failing one subcommand.

### R7-3 · major · tests

Dropping the walk's visit-once guard passed every test. Fixed: `claude/self -> .` must give each hit once.

### R7-4 · minor · correctness

An unreadable tracked file was skipped silently in the default set. Fixed: "cannot read", exit 2; tested unless root.

### R7-5 · minor · security

A linked directory that is a git checkout had its `.git` walked, every object a NUL hit. Fixed: `.git` skipped; a gitlink's
mode is checked before any blob read.

### R7-6 · minor · security

A pull request ran its own copy of the scanner, which it could weaken. Fixed: the base branch's copy scans its tree.

### R7-7 · minor · tests

The `/bin/bash` test passed with the bash 4 guard deleted. Fixed: a copy with a bash 4 construct must still run.

### R7-8 · minor · change as a whole

`implementing-plans` (120) and `tips/24_claude_code.md` (125) sat past their aim, unpinned, against `markdown-limits.md`.
Fixed: both pinned in `.md-baseline`.

### R7-9 · minor · fit

Tip 24.9 said CI runs on every push, leaving out pull requests. Fixed, with the base-branch copy.

### R7-10 · minor · fit

`work-contexts.md`'s every-level line sat in § *personal private*. Fixed: moved to § *An approval covers one action*.

### R7-11 · nit · various, left

Worktree mode reporting a file once per path reaching it; the default set's non-regular skips; Tip 24.9's symlink and
exit sentences; the header's process-count sentence; error prefixes; `%modes`/`%entries` naming (gone with R7-1);
the `get_os` stub; `skill-precedence.md`'s counts and `writing-skills` row; `markdown-limits.md`'s removed line and
`VENDORED.md`'s added one against Task 7's bounded fixes (both recorded decisions); Task 12's row and its Deferred rewrap;
`hidden-unicode.yml` against `workflows.md`'s narrow triggers (its comment says why).

### R7-12 · refuted

The diff-wide security pass; `migrate_init_selection`'s `_`; `test_init_selection.sh`'s setup; Tip 24.3's wrap.

## Round 8

Seven lenses, all verified with Task 12's bar; duplicates folded.

### R8-1 · blocking · correctness, tests

R6-5's 40-link limit was one counter for the whole run: after 40 directory-link resolutions across all targets, every
later target was dropped silently, so with 45 links through `docs/d -> real` a staged U+200B in the ninth passed.
Fixed: a resolver that counts per path; tested with 45 links.

### R8-2 · major · security

`..` was collapsed as text before staged directory links were resolved, unlike the kernel, so
`claude/link.md -> ../docs/a/../b.md` with `docs/a -> ../other/deep` scanned `docs/b.md`, not `other/b.md`.
Fixed: the target is resolved one component at a time against the index, each link replaced where it is met; tested.

### R8-3 · major · docs, security (whole-change, fit, tests: minor)

The pull-request step failed outright where the base has no copy of the script, the pull request bringing it in included.
Fixed: it falls back to the pull request's own copy with a notice; Tip 24.9 says where the base has one.

### R8-4 · minor · correctness, security

A submodule in the default set was skipped, while one reached through a link was scanned. Fixed: scanned from disk in
both modes, its `.git` left out; tested.

### R8-5 · minor · correctness

The workflow comment claimed a pull request can't weaken its check, but a pull request runs its own copy of the workflow.
Fixed: the comment says an edit to the script alone can't, and an edit to the workflow shows in the diff.

### R8-6 · minor · tests

No test for an unreadable linked directory. Fixed: both modes, exit 2, unless root.

### R8-7 · minor · plan conformance

Task 4's R1-13 still pointed at `work-contexts.md:27-30` after R7-10 moved the line. Fixed: it names the new section.

### R8-8 · minor · docs (correctness: nit)

Tip 24.9 and the header left an unreadable file out of exit 2's causes. Fixed. (Past 40 links is now treated like a
dangling link: reported only when named.)

### R8-9 · out of scope, by the bar

Correctness: a tracked link to `/` or `$HOME` walked in worktree mode; an unreadable out-of-repo target under `--cached`.

### R8-10 · nit · various, left

`migrate_init_selection`'s `_`; the `get_os` stub; the odd-names `sed`; `skill-precedence.md` rows and line 27;
`.md-baseline`'s header; Task 12's status row; Tip 24.3's sentence; `bin/dotfiles`' bash paragraph; error prefixes;
`implementing-plans-reference.md`'s opening; `shellcheck.yml`'s list; Task 12's Files against the Round 5 note.

### R8-11 · refuted

The test files' mode; Tip 24.3's wrap; `claude/CLAUDE.md`'s Skills bullet; the two Task 7 bounded-fix records.

## Round 9

Seven lenses, all verified with Task 12's bar; duplicates folded.

### R9-1 · major · correctness

A staged link resolving to the toplevel (`claude/up -> ..`) came back as "leaves the repository", so nothing under it
was scanned under `--cached`. Fixed: the toplevel resolves to itself and everything the index holds is followed; tested.

### R9-2 · major · change as a whole

The only CI step running the scan is in the untracked `.github/workflows/hidden-unicode.yml`, which Task 12's Files list
didn't name. Fixed: named there; it is among the leftovers the completion step stages.

### R9-3 · minor · security (downgraded from major)

A target written as an absolute path into the repository, or one climbing out of it and back in, was read from disk.
Fixed: the resolver keeps absolute paths, so both reach the index; tested.

### R9-4 · minor · tests

Nothing ran the workflow's pull-request logic. Fixed: the test lifts its run block out of the file and runs it against
a scratch origin, for a base with the script, a push, and a base without it.

### R9-5 · minor · tests

The unreadable-file assertions are skipped as root, so the RHEL leg never ran them. Fixed: as root, a named unreadable
file is checked as `nobody` through `runuser` where it exists.

### R9-6 · minor · change as a whole

Task 13 said the findings file was deleted, but both findings files are tracked. Fixed: Task 13 deletes all three.

### R9-7 · minor · fit

The header's "one git cat-file serves every file" ignored the per-link calls, and each link was resolved twice.
Fixed: the header names the per-link cost, and `follow` memoises.

### R9-8 · minor · docs

`tips-file-sizing.md` named four pinned tips files that aren't pinned, and `.md-baseline`'s header said every pin
predates the limits. Fixed: the doc names `24_claude_code`'s pin and why; the header, written by `bin/check-md-limits`,
says a pin is a length decided on.

### R9-12 · blocking · test failure after this round's fixes

The Ubuntu Docker leg failed four new assertions: `bin/dotfiles` installs this repo's `.gitconfig` there, which signs
every commit, so the submodule and pull-request fixtures' commits failed without a key (RHEL gets no `copy/`).
Fixed: those commits pass `-c commit.gpgsign=false`; both legs re-run and pass.

### R9-9 · out of scope, by the bar

A worktree walk through a link leaving the repository (`claude/x -> /`).

### R9-10 · nit · various, left

Untracked files under a linked tracked directory in worktree mode (downgraded); a link's own target text scanned only
under `--cached`; worktree duplicates and per-stage listing mid-merge; SIGPIPE read as a scan failure; `scan_tree`'s
`sort` unpinned and several assertion shapes; `markdown-limits.md`'s removed line; the overlap bullet's wording;
`workflows.md`'s narrow-trigger rule; Tip 24.9's length; the status table's rows; `_` in `migrate_init_selection`.

### R9-11 · refuted

Tip 24.3's wrap and the Deferred line; the bash guard's messages; the `get_os` stub.

## Round 10

Seven lenses, all verified with Task 12's bar; duplicates folded.

### R10-1 · major · tests

No fixture held a toplevel `CLAUDE.md`: a pathspec dropping it passed every test. Fixed: one in the default-set
fixture, and a lower-case `lower/agents.md` beside it (R10-5).

### R10-2 · minor · correctness, security (downgraded from major)

An absolute target written through a symlinked prefix above the toplevel (`/var` for `/private/var`) counted as outside
the repository and was read from disk. Fixed: a component the index doesn't hold is resolved with `readlink` on disk,
as the kernel would; tested where the test's directory sits under such a prefix (macOS).

### R10-3 · minor · security

A target through an untracked link inside the repository (`alias -> .`) reached a path read from disk, not the index.
Fixed by R10-2's rule; tested.

### R10-4 · minor · correctness

Hits alongside a missing file exited 2 with no hint, and Tip 24.9 said exit 2 is never a hit. Fixed: the hint prints on
any hit, and the tip says exit 2 trumps 1.

### R10-5 · minor · tests

`icase` on `AGENTS.md` was untested. Fixed with R10-1.

### R10-6 · minor · tests

The no-cache `init_files` test passed whatever the script is called. Fixed: it takes the name from `init/`.

### R10-7 · minor · change as a whole

The workflow's pull-request path "has no test that can fail". Already covered: R9-4's test lifts the step out of the
file and fails if the base copy isn't used.

### R10-8 · nit · various, left

Worktree duplicates (mid-merge, and per route); helper layout and messages in the script; `skill-precedence.md` rows;
`writing-mr-descriptions`' pointer; Tip 24.4; `tips.md`'s wrap; `tips-file-sizing.md`'s wording; the workflow's
`on:`; the test's setup comments and helper sourcing; the usage header's order; Task 4's and Task 7's records.

### R10-9 · refuted

Task 11's Built note; Tip 24.3's wrap; `safety.md`.

## Round 11

Seven lenses, all verified with Task 12's bar; duplicates folded.

### R11-1 · major · security

CI's checkout fetched no submodules, so a submodule in the default set was an empty directory there and passed.
Fixed: `submodules: recursive` on the checkout.

### R11-2 · major · security

A Git LFS file in the default set was scanned only as its pointer, in the index and in CI. Fixed: a pointer is a hit,
in both modes, since agent-loaded text doesn't belong in LFS; tested.

### R11-3 · minor · correctness

`PERL_UNICODE` with `D` decoded the index's paths, so a non-ASCII staged link missed its entry. Fixed: `perl -C0`;
tested with `D`, `SDL` and empty.

### R11-4 · minor · correctness

The hint, on unbuffered stderr, overtook the buffered hits in a captured log. Fixed: `$| = 1`; tested.

### R11-5 · minor · correctness

A named staged link to nothing passed under `--cached`, while worktree mode said "no such file". Fixed; tested.

### R11-6 · minor · security

A tracked directory replaced on disk by an unstaged link was resolved through the link, missing its staged files.
Fixed: a directory the index holds files under is never resolved on disk; tested.

### R11-7 · minor · tests

Every mixed case named the missing file first. Fixed: a hit named before a missing file must still exit 2.

### R11-8 · minor · tests

No test of an empty default set. Fixed: both modes pass on a repository with no agent files.

### R11-9 · minor · tests

"The real repo passes" ran in worktree mode only. Fixed: `--cached` too, as pre-commit runs it.

### R11-10 · minor · tests

The workflow test's stub scanners always exited 0 and the block ran without `-e`. Fixed: run under `bash -e`; a
scanner exit 1 and an unfetchable base both fail the step.

### R11-11 · minor · tests

The one-cat-file process budget was untested. Fixed: `--cached` makes as many git calls for 30 files as for one.

### R11-12 · minor · plan conformance

Task 7's bounded-fixes check now prints `VENDORED.md`. Fixed: a Task 7 deviation pointing at the user's approval.

### R11-13 · minor · change as a whole

Tip 24.9 described only `--cached`'s symlink labels. Fixed: both modes' labels.

### R11-14 · out of scope, by the bar

Worktree mode walking a link that leaves the repository (refuted by the verifier as an accepted gap).

### R11-15 · nit · various, left

A named directory or directory link under worktree mode; macOS giving up at 32 links, not 40; several test shapes;
`skill-precedence.md`'s layout and brainstorming row; the pointer and tip wording; the status rows and Built notes;
the script's helper layout; `_`; the `get_os` stub; `workflows.md`; `markdown-limits.md`'s heading; Tip 24.3.

### R11-16 · refuted

The helper's sourcing, `claude/CLAUDE.md`'s count, `bin/ai:14`, Task 12's Deferred rewrap, the guard's layout and
messages, `test_init_selection.sh`'s setup, Tip 24.3's wrap, the workflow's checkout pin, `.md-baseline`'s header,
`safety.md`.

## Round 12

Seven lenses, all verified with Task 12's bar, run after the rebase onto 3fcebf0 against the new `Base:`. No blocking
and no major: these minors are this review's last fixes, not re-reviewed.

### R12-1 · minor · tests

The zsh case covered one rename only; chains and the reverse-order dedupe ran under bash alone.
Fixed: a reverse-order chain under `zsh -f`.

### R12-2 · minor · security

The default set held the toplevel `.claude/` only, though `CLAUDE.md` and `AGENTS.md` match at any depth and Claude
Code reads nested `.claude/` content. Fixed: `:(glob)**/.claude/**`; `sub/.claude/c.md` in the fixture; header and
Tip 24.9 say "any `.claude/`".

### R12-3 · minor · docs

`tips-file-sizing.md` gave 80/150 for tips files, where the checker warns at 100 and fails at 200, and R9-8's pin
paragraph leaned on the 150. Fixed: 100/200 throughout.

### R12-4 · nit · various, left

A link to `.git` walked; link labels by mode and duplicates; a named directory as "no such file"; CR-only line
numbering; Linux machines' one manual tick (Task 11's choice); several test and wording nits; `skill-precedence.md`
rows; `claude/CLAUDE.md`'s wrap; Task 12's Interfaces and Files against what was built (recorded as deviations).

### R12-5 · refuted

The bash guard (`scripts.md` allows bash 5; pre-commit re-execs first); the cat-file/perl exit under pipefail (perl
dies with 3 before any exit 1 can win); several test and workflow nits; the file mode; the review method.
