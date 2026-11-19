# Implementing plans, reference

Read from `~/.claude/skills/implementing-plans/SKILL.md` before the approvals step, before dispatching any subagent,
and before a task only the user can do.

- **By hand:** a task only the user or a fresh session can do — done by hand, a spike the user judges,
  a test needing a fresh or interactive session or a `!` line — never goes to a subagent, which would simulate it.
  Stop before its batch, give the commands, and once the user reports back, check what its **Tests** name.
- **Models:** `model` on every Agent call
  — implementers and fixers on `$AI_MODEL_IMPLEMENT`, else `sonnet`; task reviewers and plan agents on this session's alias
  (a full model ID passes its family's).
  An attempt fails when the implementer reports itself blocked, or the task's review or tests still fail after its fix loop.
  Twice failed → once more with `model: "opus"` unless already on Opus, then the user.
  Each new attempt starts from the failed one's tree, told what failed; nothing is reverted.
- **After `git apply -3` of parallel side-worktree patches**, check that each test block appended to a shared test file
  still ends in its own closing line (`});`): blocks appended at the same place share one, and the merge leaves one unclosed.
