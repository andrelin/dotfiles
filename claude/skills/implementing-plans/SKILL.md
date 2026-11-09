---
name: implementing-plans
description: Read before implementing any plan file, or any part of one - in this session or through subagents, even a single small task - and before resuming an implementation that stopped part-way.
---

# Implementing plans

`/implementing-plans <plan-file> [<task>…]`, the path from `git rev-parse --show-toplevel` whatever the cwd; tasks limit the run.
Each finished task is checkpointed in the index; commits come only at a session end and after the code review, never at customer level.

**The listing**, used throughout: `git status --porcelain -z --no-renames --untracked-files=all --
':(top,glob,exclude)plan-*' ':(top,glob,exclude)**/00-follow-ups-*' | tr '\0' '\n'` — `top` so it holds from a
subdirectory, `--no-renames` so a rename is a `D` and an `A`. Its *leftovers* are the entries with a non-blank worktree
column (unstaged or untracked), never staged paths.

## Before the first task

- **Only a reviewed plan.** No plan file given, or one that doesn't exist → stop, listing the root's `plan-*.md`.
  Its open `## Review log (plan)` section — not a `closed` one — must end in a `Done (plan):` line; else stop and
  say so. A task already ✅ DONE is skipped on any start.
- **Approvals,** from the plan's `## Approvals`: a recorded yes is acted on without asking. Anything the run will
  need that isn't there — a tool permission for the suite, a by-hand step — is asked once, all together, before the
  first task, and recorded there, so the run then goes without stopping for permission.
- **The level**, from `~/.claude/hooks/work-context.sh level`. At company and customer level, add `/plan-*.md` to
  `$(git rev-parse --git-path info/exclude)` unless it is there.

Then, in this order:

1. **Resuming.** The branch (named as in 4) exists but the plan has no `Base:` line, or the reverse → stop and ask. With
   both: switch to the branch, keep `Base:`, carry on from the first task not ✅ DONE. The last checkpoint is the ref of
   the last task in plan order that has one; a task with a ref but no ✅ DONE row whose `<ref>^2^{tree}` equals the
   index's tree becomes ✅ DONE first. Stop and ask if `Base:` is no longer an ancestor of `HEAD` (`git merge-base
   --is-ancestor`), or if `git write-tree` differs from the last checkpoint's `<ref>^2^{tree}` (no ref yet:
   `HEAD^{tree}`) — show `git diff --cached --name-status <ref>^2` and name `git read-tree <ref>^2` as the restore,
   which drops that diff (`HEAD` for both with no ref). Leftovers in the Files list of a task not ✅ DONE go to its
   implementer as its starting point; any other leftover → stop and ask. No baseline on resume; the final report says
   so. On resume, rewrite each brief from the plan before dispatching: the scratchpad doesn't survive to the next day,
   and an agent pointed at a missing brief works without its spec.
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
  you build, whether or not the task lists them" — the plan leaves them to implementation, never out. Every task
  review's brief, re-reviews included, asks whether they are.
  An existing test is any in the tree when that subagent starts, its own task's included.
- **The review input** replaces `scripts/review-package`, since nothing is committed bar a session-end commit, so `BASE..HEAD` holds only those:
  `git diff -- <paths>` plus the full content of each new file (`git ls-files --others --exclude-standard -- <paths>`),
  written like each brief and report to `<scratchpad>/impl-<task>-*.md`.
- **Parallel** (`superpowers:dispatching-parallel-agents`, one message) only for tasks with disjoint Files lists,
  no order between them — neither's **Interfaces** names the other task or a path in its Files list — and scoped
  tests (those its **Tests** names) sharing no build directory (`build/`, `node_modules`). Unsure → in order.
- **Before the approvals step, before dispatching any subagent, and before a task only the user can do:** read
  `~/.claude/docs/implementing-plans-reference.md` — the by-hand rule and the model choice, a failed attempt included.

**Overridden in SDD 7.0.0:** every commit step, whatever `skill-precedence.md` says; its parallel-implementer ban (SKILL.md:282), replaced by
**Parallel** above; `scripts/task-brief` and § *Setup* (worktree, branch, `sdd-workspace` ledger), resume coming from the plan's status table;
"rulings, not stalls", since every stop here stops (a deferred minor is a `Deferred:` line in its task's section, listed in the final report);
§ *Model Selection*; fix-loop escalation (all five rounds run, 4–5 a fresh implementer on the same model, the reference doc's retry the only one);
its breaker, which parks findings and marks the task complete, being here a failed attempt; § *Final Review* and § *Finish*.

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
- **A task's `git mv` runs in the session:** auto mode blocks a subagent's as destructive, so a subagent can only copy the file and leave the old one.
- **A checkpoint never stages the plan file** (the session-end commit does). The report lists the refs; the review or the save deletes them.

## Between tasks, revisit the plan

The plan is iterated as the work teaches, not settled up front (`writing-plans` § *Planning in iterations*).
After each checkpoint, before the next batch:

- **Fold in what the task taught:** a wrong assumption, a `Deferred:` line, an interface that came out different —
  into every upcoming task it touches, each edit noted as a deviation in that task.
- **Iterate the plan in this run** at a `## Revisit` heading, before a `Sketch:` task, or when a fold-in would change
  an upcoming task's requirement or the approach. A fresh plan agent, told to follow `writing-plans`
  § *Planning in iterations* up to its review, to edit only the plan file and to make no git writes, iterates it;
  then `reviewing-in-rounds plan <plan-file>` here, and on its `Done (plan):` the next batch. An approval the
  iteration adds that § *Approvals* lacks, or a review stopping for a user decision, stops the run.

## Keeping the plan in sync

Per `writing-plans` § *Keeping it in sync*, per task: status, and any deviation inline. Never edit a task's spec to match what was built
without saying so in that task. A deviation in what a task delivers — its behaviour, interface or tests — stops the run, the batch unstaged,
whoever finds it (this session, an implementer or a task review); the user's ruling goes in that task's section.
One in how — a stale line number, a renamed helper — is noted inline and the run goes on, for the final review to check.

## Finish with the final review, in this run

**The work isn't finished until the final code review says `Done (code):`**, whatever the task reviews found — they
each saw one task, never the whole. Run `filing-learnings`, then `reviewing-in-rounds code <plan-file>` here, without
stopping: its reviewers and verifiers are fresh agents, so only the fixing is this session's.
The final report lists the refs, each task's paths, the `Deferred:` lines, unstaged or ignored suite artifacts and whether a
baseline ran. A run that stopped part-way runs no code review: it names the tasks not ✅ DONE and prints `ai implement <plan-file>`.

**A session end** is the user's request to wrap up, or a part-way report that asks the user nothing; a stop to ask is none.
Follow `~/.claude/docs/session-end-save.md` then.
A branch with session-end commits lands by a squash-merged PR, never a fast-forward;
the final review's Completion owns the tracked plan's `git rm -f` before it.

## Red flags

| Thought | Reality |
| --- | --- |
| "Every task passed its review, so it's done." | Not until the final code review ends in `Done (code):`. |
| "I'll stop so the user can start the next stage." | Plan iterations and the code review run here; stop only for the user's decisions. |
| "This task is too small to review." | Every task gets its task review. |
| "The task doesn't mention error handling." | The implementer adds it, and the edge-case tests, anyway. |
| "A checkpoint commit is safer." | No checkpoint is committed (a session-end commit comes later, not at customer level). The index and the ref are the checkpoint. |
| "`git add -A` is quicker." | It stages the user's stray files as the plan's. Stage each task's Files list. |
| "`git stash`, then `stash pop`." | Without `--index` the pop unstages every checkpoint. |
| "The test was wrong, I'll loosen it." | A deleted or loosened test is how agents reach green. It goes to the user. |
| "Give the implementer `isolation: worktree`." | It branches from the remote default branch, not this work. |
| "Run the formatter over the repo." | Only the current task's files; the rest belongs to no task. |
| "These two can share the file, in parallel." | Parallel subagents share no file and run no git. |
| "The spec can't be met as written; I'll pick the closest." | A change in what it delivers is the user's. Stop. |
