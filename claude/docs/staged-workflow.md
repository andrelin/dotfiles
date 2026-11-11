# The staged workflow — why it is built this way

Read when changing the workflow skills, `bin/ai` or `bin/ai-log`, or when asked why a stage works as it does.
What each step does is in the skill; this file holds the decisions and what was declined.

## The stages

| Stage | Skill | Default model | Hand-over |
| --- | --- | --- | --- |
| Issue | `writing-issues` | sonnet (`AI_MODEL_ISSUE`) | the issue, or a follow-up tracker item |
| Plan | `writing-plans` | opus (`AI_MODEL_PLAN`) | `plan-<n>-<slug>.md`, reviewed to `Done (plan):` |
| Implement | `implementing-plans` | opus (`AI_MODEL_REVIEW`) | the branch and the plan's status table |
| Review | `reviewing-in-rounds` | opus (`AI_MODEL_REVIEW`) | the review log appended to the plan |

- **The hand-over is an artifact, never chat:** a fresh session reads the file and nothing else, so nothing rests on what a session remembered.
- **A fresh session per stage** starts each stage free of the last one's anchoring; `bin/ai <stage>` opens it on the stage's model.
- **Models are defaults, not rules:** `ai --model <m>` or the variables override them.
  Issue is sonnet, not haiku, because the interview's hard part is knowing what is missing.
- **The model is set at session start,** since a skill can't open a fresh session on another model and `model` isn't a portable front matter field.
- **Rejected: `opusplan`,** which switches model inside one session and gives up the clean context per stage.
- **Subagents get `model` on every Agent call:** `CLAUDE_CODE_SUBAGENT_MODEL` outranks the session's model, so "inherit" is not guaranteed.
  Leave `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` unset: its effect on an explicit `model` is undocumented.
- **Implementers and fixers run on `AI_MODEL_IMPLEMENT` (sonnet),** reviewers and plan agents on the session's model.
  Detail: `implementing-plans-reference.md`.

## One driver from the plan on

- **`writing-plans` goes straight on to `implementing-plans`,** unless the user asked for the plan alone.
  Stopping after every stage, and three times at every revisit, made the user the scheduler.
- **The driver stops only for the user's decision:** an approval missing from the plan,
  a deviation in what a task delivers, a review's user-decision line.
- **Reviewers and verifiers stay fresh agents;** only the fixing is the driver's, and that anchoring is accepted.
- **Subagents can't dispatch subagents,** so a stage that fans out runs in the main session.
- **`writing-issues` still prints `ai plan …`,** since the interview needs the user anyway.
- **A session claims its issue in the in-flight tracker before planning,** not once the plan is ready:
  parallel sessions had picked up the same issue, unseen until a plan or PR appeared.
- **A new session restarts the issue interview;** only compaction resumes it, from the scratchpad draft.
- **The issue's last turn asks "anything to change?"** before Claude files: a world-readable issue earns a last look.

## Agile, in small tasks

- **Small tasks, riskiest first,** each implemented, tested, reviewed and learned from before the next; a plan can't settle every problem up front.
- **Planning iterates too:** only what is next is planned in full and later tasks are sketches.
  The plan is revisited between tasks and at a `## Revisit` heading.
- **A plan review checks soundness and slicing,** and leaves implementation detail, tests included, to the code.
  Early plan rounds of 88–134 findings on code not yet written are what it must not become.
- **The weight is on the code review,** which hunts every bug.
- **Both reviews are mandatory:** the task review after every task and the final `reviewing-in-rounds code`, which agents had been skipping.
- **The status table's last row is `Final code review`,** ⏳ PENDING until the review ends in `Done (code):`,
  so a skipped review shows in the plan itself.
- **Error handling and edge-case tests are the implementer's** for every task, listed or not; the task review checks them.
- **Approvals are asked in bulk, up front,** so small tasks don't mean babysitting; the plan's `## Approvals` records the answers.
- **Task tracker and follow-up tracker are two questions:** does it belong in the project's tracker, and does the user work on it?
  `writing-issues` holds both.
- **Where issues live is a rule per group of repos,** not per repo.
  Jira is out of scope until a project uses it, and drafting covers it meanwhile.

## Checkpoints and landing

- **The index is the checkpoint, not commits:** each approved task is `git add`ed and the unstaged diff is the task in progress.
  Claude Code's "commit only when asked" then holds; the superpowers loop's per-task commits would be blocked mid-run at customer level.
- **The index is fragile** (one `stash` or `restore` loses it, and agents have done both),
  so each checkpoint is also a `git stash create` under a private ref.
- **A session end commits `Work in progress: Tasks …`, pushes and logs** (`session-end-save.md`), so another machine resumes from a push.
  It never happens at customer level.
- **A branch holding session-end commits lands by a squash-merged PR, never a fast-forward,**
  so the work-in-progress commits and per-task commits stay off the default branch.
- **A plan is deleted only after its work is committed and logged:** the `ai-log record` after the commit still reads it.
  Any tracked plan is `git rm -f`ed on its branch before the merge (`-f`: its own status edits are unstaged), in `reviewing-in-rounds` Completion.
- **`ai-log` records counts, durations, token counts and versions** to a private repo, with the repo and plan names (hashed at company level),
  built-in tool names and model ids, only counts of project skills, custom agents and MCP tools (`_project`, `_custom_agent`, `_mcp`)
  and the introspection, mechanically redacted (`work-contexts.md`).
  No dollar costs are tracked.

## The review loop's brake

- **One loop for plans and code,** with a lens set and a scale per kind (`review-lenses.md`).
  Someone else's work is `reviewing-for-feedback`, which writes a report and changes nothing.
- **Reviewers report everything with a severity and the verifier filters,** since a threshold in a reviewer's prompt lowers recall.
  A finding without a failure scenario or a violated requirement is dropped.
- **A plan review is Done at "no `blocking` or `major` left", not "only nits":** waiting for nits costs a round per minor fix.
  A code review also fixes its minors before Done. The rule and the round numbers are in `reviewing-in-rounds`.
- **A re-evaluation applies its own recommendation** and stops only for a user decision.
  It may recommend stopping, "the remaining findings don't affect correctness or the requirements", always as the user's decision.
- **A removed or loosened assertion is `blocking`,** since agents weaken tests to reach green.
- **The completion report names the files no finding touched,** because AI review hasn't covered them, so the human reviewer starts there.
- **Weakly tested code gets characterisation tests first,** and `implementing-plans` runs the suite as a baseline before the first task.

## Declined, and what was taken

| Source | Taken | Declined |
| --- | --- | --- |
| gstack | the plan-review lens idea; hooks over prose for guards | vendoring: ~30 KB preamble per skill, daily churn, unprefixed names, release skills that commit and post |
| gstack `document-release` | nothing: the `source/` and `bin/` docs hook covers drift | the skill itself |
| gstack retro | nothing yet | deferred until something consumes a weekly git-log summary |
| superpowers | the plugin as is, for technique (`skill-precedence.md`) | vendoring (commit steps can't be edited out, cross-references would dangle) and replacing it |
| Compound Engineering | one learning per task (`filing-learnings`) | its 36-skill loop |
| OpenSpec | folding a finished plan into durable docs | a second spec tree and CLI |
| Spec Kit | clarify and analyze passes as plan-review lenses | the pipeline |
| Trail of Bits config | credential and rc-file deny rules | a Stop-hook gate: superpowers' verification skill covers it in prose |
| BMAD, SuperClaude, wshobson/agents | nothing | persona bloat; installers that rewrite `~/.claude` |

Also declined: JSON status files (the plan's status table is what the user reads)
and `includeGitInstructions: false` (the built-in guidance already commits only when asked).
