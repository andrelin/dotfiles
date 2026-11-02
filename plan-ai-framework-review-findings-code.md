<!-- DOCTOC SKIP -->

Leftovers before round 1: none

## Round 1

Seven lenses, all verified. Findings most severe first; nits and refuted findings follow.
None is fixed yet: the run stopped here on 2026-11-02 at the user's request, so a resumed session applies them.

### R1-1 · major · tests (also correctness, downgraded there to minor)

`bin/dotfiles` `init_files()` calls `migrate_init_selection` after the cache read, and no test reaches the call:
deleting it passes every test, and every machine with a cache comes up with `52_claude.sh` unticked.
Suggested fix: move the cache read and the migration into one function above the source-mode return
(`read_init_cache <file>`), called from `init_files`, and test it against a temp file holding `52_macos_claude.sh`.

### R1-2 · major · security (also whole-change, minor)

`bin/check-hidden-unicode`'s default set excludes `claude/skills/unslop/`, while `writing-mr-descriptions` now has
every PR/MR pass read `~/.claude/skills/unslop/SKILL.md`: a hidden instruction arriving in an upstream re-sync passes
pre-commit and CI. The scanner only reads, so scanning a vendored file edits nothing; it scans clean today.
Fix: drop the exclusion (script, its usage header, Tip 24.9, the default-set test fixture) and record it as a
deviation from Task 12's Interfaces.

### R1-3 · minor · security, correctness

Missed characters the spec's own categories cover: U+061C ARABIC LETTER MARK (bidi), U+180B-180D and U+180F
(Mongolian variation selectors); cheap to add with U+206A-206F (`\xE2\x81[\xA0-\xA4\xA6-\xAF]`, `\xE1\xA0[\x8B-\x8F]`,
`\xD8\x9C`). `test/test_check_hidden_unicode.sh` asserts U+206A passes: move it to the flagged cases.

### R1-4 · minor · security

`--cached` scans a tracked symlink's blob, the target path, not what the agent reads; CI's worktree mode follows it.
Suggested fix: in mode b, when `-l $label && -f $label`, also scan the file it resolves to.

### R1-5 · minor · security

`.github/workflows/markdown.yml`: the hidden-Unicode step runs after the length step with no `if:`, so a length failure
hides its report. Fix: `if: ${{ !cancelled() }}`.

### R1-6 · minor · correctness

Worktree mode: a dangling tracked file symlink in the default set gives "no such file" and exit 2 (Task 12's
`Deferred:` names only the directory case). Suggested fix: in the default set, worktree mode, skip what isn't `-f`,
which also settles that `Deferred:` line.

### R1-7 · minor · fit, docs (nit)

`.claude/rules/scripts.md:29-30`: Claude Code never runs `bin/check-hidden-unicode`, and `env bash` is Apple's 3.2
only without Homebrew on the `PATH`. Reword: "which `hooks/pre-commit` runs through `env bash`, Apple's 3.2 unless
Homebrew's bash is on the `PATH`".

### R1-8 · minor · fit

`test/test_check_hidden_unicode.sh`: "Everything below needs git repos. Each is created in a call of its own." is
false (the code uses `git -C "$repo"`). Delete the second sentence.

### R1-9 · minor · tests

`test/test_init_selection.sh` "empty selection stays empty": the function runs in a subshell, so the count restates the
test's own `()`. Run it in the current shell, then assert.

### R1-10 · minor · tests

Nothing automated holds `bin/check-hidden-unicode`'s bash 3.2 requirement. Add a run through `/bin/bash "$CHECKER"`
when `/bin/bash` is 3.x.

### R1-11 · minor · tests

`migrate_init_selection` under zsh is untested though sourced into every interactive zsh. Add a `zsh -f` case when
zsh is installed (it passes today).

### R1-12 · minor · plan conformance, whole-change

`claude/docs/skill-precedence.md`'s `finishing-a-development-branch` row allows a clean local merge and `git pull`;
the spec said stop before merge into base. Consistent with the global rules; record a `Deviation:` in Task 4.

### R1-13 · minor · plan conformance, whole-change (tests: nit)

`claude/docs/work-contexts.md:27-30` departs from the spec's exact line (prefix, three lines, a fourth sentence on
customer work); its `grep -F` test can't pass. Record a `Deviation:` in Task 4.

### R1-14 · minor · docs

On a customer self-review `reviewing-locally` and `reviewing-in-rounds` both fire; only `skill-precedence.md` says the
latter takes the fetch, never the rebase. Add that line to `claude/skills/reviewing-in-rounds/SKILL.md`, as
`reviewing-for-feedback:25` has.

### R1-15 · minor · docs

The renamed-init-script convention (an `old:new` entry in `bin/dotfiles`' `renamed_init_scripts`) is in no rule or
README. Add it to `init/README.md`, which `scripts.md` sends a renamer to.

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

### R1-20 · nit · change as a whole, left

The run's one commit carries the user's § *Language* edit; its message names it. Trailing whitespace at
`test/test_init_selection.sh:32` (fix with R1-16's comment). `bin/ai:14` says `AI_MODEL_IMPLEMENT` is "read by the
skill", now the reference doc. Refuted: the redundant dedup (the spec requires it), RHEL's perl (the test guards it).
Duplicates of R1-2, R1-12 and R1-13 are folded into those.
