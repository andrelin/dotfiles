---
name: implementing-plans
description: Read before implementing any plan file, or any part of one - in this session or through subagents, even a single small task - and before resuming an implementation that stopped part-way.
---

# Implementing plans

`/implementing-plans <plan-file> [<task>…]`, the path from `git rev-parse --show-toplevel` whatever the cwd; tasks limit the run.
Each finished task is checkpointed in the index and nothing is committed: the commit follows the code review.

**The listing**, used throughout: `git status --porcelain -z --no-renames --untracked-files=all --
':(top,glob,exclude)plan-*' ':(top,glob,exclude)**/00-follow-ups-*' | tr '\0' '\n'` — `top` so it holds from a
subdirectory, `--no-renames` so a staged rename is a `D` and an `A`. Its *leftovers* are the entries whose worktree
column isn't blank (unstaged or untracked); staged paths are not leftovers.

## Before the first task

- **Only a reviewed plan.** No plan file given, or one that doesn't exist → stop, listing the root's `plan-*.md`.
  Its open `## Review log (plan)` section — not a `closed` one — must end in a `Done (plan):` line; else stop and
  say so. A task already ✅ DONE is skipped on any start.
- **The level**, from `~/.claude/hooks/work-context.sh level`. At company and customer level, add `/plan-*.md` to
  `$(git rev-parse --git-path info/exclude)` unless it is there.

Then, in this order:

1. **Resuming.** The branch (named as in 4) exists but the plan has no `Base:` line, or the reverse → stop and ask.
   With both: switch to the branch, keep `Base:`, carry on from the first task not ✅ DONE.
   The last checkpoint is the ref of the last task in plan order that has one; a task with a ref but no ✅ DONE row
   whose `<ref>^2^{tree}` equals the index's tree becomes ✅ DONE first.
   Stop and ask if `Base:` is no longer an ancestor of `HEAD` (`git merge-base --is-ancestor`), or if
   `git write-tree` differs from the last checkpoint's `<ref>^2^{tree}` (no ref yet: `HEAD^{tree}`) — show
   `git diff --cached --name-status <ref>^2` and name `git read-tree <ref>^2` as the restore, which drops that diff
   (`HEAD` for both with no ref).
   Leftovers in the Files list of a task not ✅ DONE go to its implementer as its starting point; any other leftover
   → stop and ask. No baseline on resume; the final report says so.
2. **A fresh start needs a clean tree:** any entry in the listing, staged or not → stop, listing the files for the
   user to stash or commit, or review would take their work for the plan's. Likewise stop if
   `git for-each-ref refs/checkpoints/<branch>/` lists an earlier run's ref, naming `git update-ref -d` for each.
3. **Baseline,** fresh start only, before the branch exists: run the suite — the `Suite:` line in the plan's
   § *Global constraints*, else the command the repo's `CLAUDE.md` names, else ask once. Every suite run uses the
   Bash tool's `timeout: 600000`; a timeout stops the run as a timeout, never as failing tests. A failure stops the
   run listing the failing tests, with no branch and no `Base:`. No suite: say so in the final report and go on.
4. **The branch:** the plan file's name minus `plan-` and `.md` (`plan-42-login.md` → `42-login`),
   `git switch -c <name>`; then `Base: <git rev-parse HEAD>` on its own line, after a blank line, under the plan's
   status table.

## Technique from superpowers, rules from here

Use `superpowers:subagent-driven-development` (7.0.0) for its loop: per task a fresh implementer
(`implementer-prompt.md`), then a fresh task reviewer (`task-reviewer-prompt.md`; after each fix
`re-review-prompt.md`), each review given the whole task's input re-captured, never a fix-only diff.
**Every task gets its task review**, a one-line task included: none is checkpointed or ✅ DONE without one passing.

- **The implementer** gets that task's text, § *Global constraints*, the interfaces it consumes and any
  starting-point leftovers; its prompt, like every fixer's, carries this line verbatim:
  "no git writes; never delete or loosen an existing test; report the paths you changed".
  The implementer's also carries, verbatim: "handle every error path and test the edge cases and boundaries of what
  you build, whether or not the task lists them" — the plan leaves them to implementation, never out. The task
  reviewer's brief asks whether they are.
  An existing test is any in the tree when that subagent starts, its own task's included.
- **The review input** replaces `scripts/review-package`, since nothing is committed and `BASE..HEAD` is empty:
  `git diff -- <paths>` plus the full content of each new file (`git ls-files --others --exclude-standard -- <paths>`),
  written like each brief and report to `<scratchpad>/impl-<task>-*.md`.
- **Parallel** (`superpowers:dispatching-parallel-agents`, one message) only for tasks with disjoint Files lists,
  no order between them — neither's **Interfaces** names the other task or a path in its Files list — and scoped
  tests (those its **Tests** names) sharing no build directory (`build/`, `node_modules`). Unsure → in order.
- **By hand:** a task only the user or a fresh session can do — done by hand, a spike the user judges, a test
  needing a fresh or interactive session or a `!` line — never goes to a subagent, which would simulate it. Stop
  before its batch, give the commands, and once the user reports back, check what its **Tests** name.
- **Models:** `model` on every Agent call, this session's alias (a full model ID passes its family's), never the
  cheapest that might do. An attempt fails when the implementer reports itself blocked, or the task's review or
  tests still fail after its fix loop. Twice failed → once more with `model: "opus"` unless already on Opus, then
  the user. Each new attempt starts from the failed one's tree, told what failed; nothing is reverted.

**Overridden in SDD 7.0.0:** every commit step, whatever `skill-precedence.md` says; its ban on parallel
implementers (SKILL.md:282), replaced by the rule above; `scripts/task-brief` and § *Setup* (worktree, branch,
the `sdd-workspace` ledger) — resume from the plan's status table; its "rulings, not stalls" — every stop here
stops; deferred minors go in the task's section as a `Deferred:` line, listed in the final report;
§ *Model Selection*; its fix-loop escalation — all five rounds run, rounds 4–5 a fresh implementer on the same
model, the retry above being the only escalation; its breaker, which parks findings and marks the task complete
— here a failed attempt; § *Final Review* and § *Finish*.

## Checkpoint in the index, at every level

After a batch — one task, or a parallel batch once all have returned — passes its task reviews (their input being
the *unstaged* diff) and the suite. Stage a batch only when every task in it passes; a task going to the user stops
the run with the whole batch unstaged.

- **Parallel subagents** never run git or the full suite, only their own scoped tests. The session runs the suite
  once all have returned; a failure is pinned to a task by rerunning each one's scoped tests, and that task goes
  back to its fix loop. Pinned to none → stop for the user.
- **Before staging:** `HEAD` must equal its value at the run's start and the index's tree the last checkpoint's
  (`HEAD^{tree}` before the first); otherwise a subagent ran git — stop, naming the moved `HEAD` or the paths
  `git diff --cached --name-status` shows against it.
- **Each leftover** must fall in exactly one of the batch's tasks' Files lists and is staged with that task. Any
  other leftover, a Files-list path that is gitignored, or a task with nothing to stage → stop, unstaged, naming the
  path or task; the user adds the path to that task's **Files** or undoes the change. Never `-A`.
- **Not leftovers,** never staged, named in the final report: untracked paths outside every Files list that a suite
  run creates (the listing just before and after it), and gitignored paths a batch created
  (`git ls-files --others --ignored --exclude-standard`, before and after).
- **Stage task by task, in plan order** (concurrent `git add` collides on `.git/index.lock`): `git add -- <paths>`,
  then at once `git update-ref refs/checkpoints/<branch>/<task> "$(git stash create)"`, `<task>` as its heading
  writes it (`2b`) — a save point on a private ref, touching no branch, index or tree. `git read-tree <ref>^2`
  restores the index, `git checkout <ref> -- <paths>` the tree. Then the task's row becomes ✅ DONE.
- **The plan file is never staged.** The final report lists the refs; the code review deletes them after the commit.

## Between tasks, revisit the plan

The plan is iterated as the work teaches, not settled up front (`writing-plans` § *Planning in iterations*).
After each checkpoint, before the next batch:

- **Fold in what the task taught:** a wrong assumption, a `Deferred:` line, an interface that came out different —
  into every upcoming task it touches, each edit noted as a deviation in that task.
- **Stop for a plan iteration** at a `## Revisit` heading, before a `Sketch:` task, or when a fold-in would change an
  upcoming task's requirement or the approach: print `ai plan <plan-file>` to iterate it, then
  `ai review plan <plan-file>`, then `ai implement <plan-file>` to resume; the run's report says why it stopped.

## Keeping the plan in sync

Per `writing-plans` § *Keeping it in sync*, per task: status, and any deviation inline. Never edit a task's spec to
match what was built without saying so in that task. A task review that flags a deviation from the plan stops the
run, the batch unstaged; the user's ruling goes in that task's section.

## Finish by handing over to the final review

**The work isn't finished until the final code review says `Done (code):`**, whatever the task reviews found — they
each saw one task, never the whole. Run `filing-learnings`, then print `ai review code <plan-file>` for a fresh
session — a review in this session anchors on its own reasoning — and make the report's first line, verbatim,
`Not done: the final code review is next.` The status table's `Final code review` row stays ⏳ PENDING; only that review flips it.
The final report lists the refs, each task's reported paths, the `Deferred:` lines, the unstaged suite or ignored
artifacts, and whether a baseline ran. A run that stopped part-way prints no
`ai review code` line; it says which tasks aren't ✅ DONE.

## Red flags

| Thought | Reality |
| --- | --- |
| "Every task passed its review, so it's done." | Not until the final code review ends in `Done (code):`. |
| "This task is too small to review." | Every task gets its task review. |
| "The task doesn't mention error handling." | The implementer adds it, and the edge-case tests, anyway. |
| "A checkpoint commit is safer." | Nothing is committed here. The index and the ref are the checkpoint. |
| "`git add -A` is quicker." | It stages the user's stray files as the plan's. Stage each task's Files list. |
| "`git stash`, then `stash pop`." | Without `--index` the pop unstages every checkpoint. |
| "The test was wrong, I'll loosen it." | A deleted or loosened test is how agents reach green. It goes to the user. |
| "Give the implementer `isolation: worktree`." | It branches from the remote default branch, not this work. |
| "Run the formatter over the repo." | Only the current task's files; the rest belongs to no task. |
| "These two can share the file, in parallel." | Parallel subagents share no file and run no git. |
| "The review flagged a deviation, but it's fine." | A deviation is the user's ruling. Stop. |
