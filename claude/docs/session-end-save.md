# Session-end save, reference

Read at a session end from `~/.claude/skills/implementing-plans/SKILL.md` § *Finish*, or from `~/.claude/skills/reviewing-in-rounds/SKILL.md`
when a code review of a plan ends before `Done (code):`: the user asks to wrap up, or the run ends part-way with a report that asks the user nothing.
Every step needs a plan: a code review with none saves nothing, and the report says so.
A stop to ask is not a session end.
A session killed without a turn saves nothing: the same machine resumes from where the work is, another from the last session end's push.

## The level

- **Run `ai-log level`**, which is `work-context.sh level`'s answer (non-zero is customer) plus a check that the log clone exists.
- **A failure or an unexpected output** is customer level: commit nothing, report the failure.
  When it prints `customer` with a reason on stderr (a failed guard, a missing log clone), the report quotes that reason, so the user can fix it.

## At personal and company level

On the user's standing yes of 2026-11-05 and 2026-11-09.
Stop and report if `HEAD` is detached, or if the branch is not the plan's.

1. **Name the tasks:** list `git for-each-ref --format='%(refname)' refs/checkpoints/<branch>/` before anything else.
   Its tasks are the ones checkpointed since the last session end.
2. **Add the plan files that exist**, `<stem>` being the plan file's name without `.md`: `<stem>.md` and each `<stem>-review-findings-*.md`,
   closed ones included. List them with quoted pathspecs from the repo root, so the cwd doesn't matter,
   never an unquoted glob in `ls`, `git add` or `&&`, which abort on no match:
   `git ls-files -z --others --cached --exclude-standard -- ':(top)<stem>.md' ':(top)<stem>-review-findings-*.md' | xargs -0 -r git add --`,
   empty when none exist (`-r` skips the empty run on GNU and macOS alike).
   At company level drop `--others`: the plan is excluded there, so only a tracked one goes in.
   At personal level an untracked one too, since a tracked plan is `git rm -f`ed on the branch before the squash merge (*Landing*).
   **During a code review** (`<stem>-review-findings-code.md` exists) also `git add` the review's fixes: the leftovers not listed on its
   `Leftovers before round 1:` line, never `plan-*`, so the commit holds the fixes its `Fixed:` lines claim.
   Untracked files outside the review's fixes that a suite run created are not leftovers: never staged, and the report names them.
   Where the repo's pre-commit hook wants a doctoc marker on tracked markdown (this repo's does), a plan file without
   `<!-- DOCTOC SKIP -->` gets it as its first line before it is added, or the hook rejects the commit and the plan stays off the push.
   **In a public repo** (`gh repo view --json visibility`; undeterminable is public) the pushed branch stays world-readable after that merge,
   so read the whole commit, `git diff --cached <Base:>` plus the plan files, against the bar —
   no customer names, hostnames, internal tooling or secrets (no `Base:` line: `git diff --cached`).
   Whatever fails stays out: `git restore --staged -- <path>` leaves it as an unstaged leftover, and the report names it.
3. **Commit the index:** `git commit --allow-empty -m "Work in progress: Tasks <list>"`.
   The list is step 1's tasks, never a leftover; none → `Work in progress: Tasks (none new)`.
   `--allow-empty` gives every session end its own `HEAD`, so its own log entry.
   A failed commit — a pre-commit hook that rewrites or rejects a plan file counts — keeps the refs:
   run `git restore --staged -- <the plan paths added>`, report the hook's message, and commit once more without the plan files,
   so the checkpoints still reach step 5. A second failure stops here:
   `git restore --staged -- <the review's fixes added in step 2>` too, so the index again equals the last checkpoint.
4. **Delete the refs** the commit now holds, each `git update-ref -d <ref>`.
   If step 2 restored a path a checkpoint holds, the commit lacks that content: keep every ref and say so in the report.
5. **Push:** `git push -u origin <branch>`. A failure goes in the report; go on to 6.
6. **Record:** `ai-log record <plan-file>` — read its counts, skip the introspection it prints, which comes once per plan after its final commit.
   A nonzero exit goes in the report with its message.

Leftovers of a half-done task stay unstaged and are never pushed.

## What a resume sees

- **No checkpoint ref,** so the last checkpoint is `HEAD^{tree}`, which equals the index after the commit,
  on this machine and on another after `git fetch && git switch <branch>`.
- **`Base:`** is still an ancestor of `HEAD`, the session-end commits sitting on top of it.
- **This machine** hands the leftovers to the task's implementer as before; another restarts that task from the plan.
- **At company level** the plan is untracked, so it does not reach another machine: copy it by hand.

## At customer level

Nothing is committed or pushed. The report lists what is uncommitted, the listing and the checkpoint refs.

## Landing

A branch holding session-end commits lands by a squash-merged PR, never a fast-forward or a local merge,
so the `Work in progress` commits and Completion's per-task commits never reach the default branch.
Before the merge, once `ai-log record` has read them, the tracked plan files go in one commit on the branch,
offered and run only on the user's yes, one in the plan's `## Approvals` counting, and drafted at customer level:
`git ls-files -z -- ':(top)<stem>.md' ':(top)<stem>-review-findings-*.md' | xargs -0 -r git rm -f --`,
which does nothing when that lists nothing (`git rm` with no path fails).
`-f` because the review's status-row flip and log leave the tracked plan modified, and those edits are the plan's own.
Completion commits what is left after the last session-end commit, per task as before.
The final review diffs from `Base:`, so it covers the session-end commits.
