# Planning: when to plan, and what a plan must hold

## When

- **Explore, plan, implement, then commit** — but "if you could describe the diff in one sentence, skip the plan"
  **[A]** (Claude Code best practices). Planning pays when the approach is uncertain or the change spans files.
- **Scale the spec to the change.** Spec-driven tools generate more markdown than small changes need — one bug fix
  became four user stories and sixteen acceptance criteria; "I'd rather review code than all these markdown files"
  **[O]** (Böckeler, martinfowler.com). Thoughtworks has spec-driven development in *Assess*, warning that
  "handcrafting detailed rules for AI ultimately doesn't scale" **[C]**.
- **Experienced developers plan more** with agents, per a study Cursor cites **[U]**.

## How

- **Interview first.** Have the agent ask the questions — the docs suggest AskUserQuestion — until it can write a
  spec, then "start a fresh session to execute it" **[A]**. The same interview → spec → plan → execute shape is the
  practitioner norm **[C]** (Harper Reed, Addy Osmani).
- **A good spec names the files and interfaces, states what is out of scope, and ends with an end-to-end
  verification step** **[A]**.
- **Brownfield changes are deltas.** Describe what the change adds, modifies and removes against the current truth,
  rather than restating the system; full-pipeline tools were seen regenerating classes they were told existed
  **[O]** (OpenSpec's model; Böckeler).
- **Agree on "done" before coding.** Anthropic's long-running harness has generator and evaluator agree a "sprint
  contract" — acceptance criteria the reviewer grades against — before work starts **[A]** (harness design).
- **Small, atomic steps, each verified before the next** **[C]** (Osmani, Reed, Cursor).
- **Every line in a plan is an instruction the executor will follow.** Extra requirements make tasks harder **[S]**
  (see [context.md](context.md)) — a plan earns its length the way a `CLAUDE.md` does.

## Before touching weakly tested code

- **Get a safety net first.** Where the code a change will touch has little test coverage, the first step is tests
  that pin down its current behaviour — characterisation tests — so a regression shows up as a failure rather than
  a surprise. Scope them to what the change touches; covering the whole codebase first is a project of its own.
- **Run the existing suite before the first edit** to get a baseline; a suite that already fails is reported, not
  silently inherited **[O]** (Willison, agentic engineering patterns).
- **Why it matters more with agents:** passing tests is the agent's main signal that it is done, and agent-authored
  changes carry more logic errors than human ones **[S]** (see [verification.md](verification.md)).

## Plans as hand-off

- **The plan file is the hand-off between sessions,** not the conversation: files avoid the "game of telephone"
  **[A]** (multi-agent research system).
- **Status the executor updates is better structured** — a table or JSON list — than prose it might rewrite **[A]**.
- **Plans can live outside the repo by default:** plan mode writes to `~/.claude/plans` unless `plansDirectory` is set
  **[A]**. Where plans must survive across machines, keep them in the repo.
