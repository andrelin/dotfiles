# Multi-agent work: subagents, parallel sessions and model choice

## When fanning out pays

- **Start simple; add agents only when simpler solutions fall short** **[A]** (building effective agents). Workflows
  are predefined code paths; agents direct themselves. Prefer the workflow when the steps are known.
- **Multi-agent pays for breadth** — parallelisable work, more information than one window holds, heavy tool use —
  and is a poor fit where agents need shared context: "most coding tasks involve fewer truly parallelizable tasks
  than research" **[A]** (multi-agent research system).
- **It is expensive:** agents use about 4× the tokens of chat, multi-agent systems about 15×; token use explained 80%
  of performance variance in Anthropic's research evals **[A]**. A full planner/generator/evaluator harness cost
  about 22× a solo run on the same app ($200 against $9) **[A]** (harness design).
- **Role-specific small teams are worth trying; large swarms are *Caution*** — they amplify bias, cost and
  coordination failures **[C]** (Thoughtworks).

## Delegating well

- **Every delegation names four things:** "an objective, an output format, guidance on the tools and sources to use,
  and clear task boundaries" **[A]**. Scale effort to the task: one agent and a few calls for simple lookups.
- **Subagents return a distilled summary,** often 1,000–2,000 tokens, which is the point: exploration stays out of the
  main context **[A]**. Send verbose work — test runs, log digging, research — to them **[A]**.
- **Hand results back through files** where they are long **[A]**.
- **What a subagent sees** **[A]** (subagents docs): its own prompt and task, the full `CLAUDE.md` hierarchy and
  rules, and git status — not the parent's conversation, nor skills the parent invoked. The built-in Explore and Plan
  agents start without `CLAUDE.md`.
- **Current Opus models over-delegate.** Anthropic's suggested damping includes "do not use subagents to verify or
  double-check your own work" **[A]** (prompting Claude Opus 5). Hard caps exist for depth and concurrency
  (`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`, `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS`) **[A]**.
- **Drop redundant self-checks on current models:** explicit "verify your work" steps cause over-verification; keep
  the *separate* review stage, which still pays **[A]**.

## Parallel sessions

- **One worktree per agent** is the norm **[C]** (Cursor, OpenAI, Willison). A worktree subagent branches from the
  remote default branch unless `worktree.baseRef: "head"` is set — needed when it must build on in-progress work
  **[A]**.
- **The "scout":** run an agent you never intend to land, to learn which files a change touches **[O]** (Willison).
- **Lock files plus git** coordinated 16 parallel agents in Anthropic's C compiler project (about 2,000 sessions,
  $20k) **[A]**.
- **A fresh window per task** — the "Ralph loop", one task per iteration with the codebase as memory — is the
  practitioner form of the same idea **[O]**.

## Choosing models

- **Sonnet for most coding, Opus for architecture and multi-step reasoning, Haiku for simple subagents** **[A]**
  (costs). An Opus lead with Sonnet workers is Anthropic's own research setup **[A]**.
- **Set a subagent's model explicitly.** Resolution order: the per-call `model` parameter, the agent's frontmatter,
  `CLAUDE_CODE_SUBAGENT_MODEL`, then the session's model **[A]**.
- **A session's model is set at launch** with `--model`, per terminal; a skill's `model` field lasts only for the
  rest of its turn **[A]**.
- **Planner/editor splits help some model pairs and not others** **[S, benchmark]** (Aider) — treat per-stage models
  as tunable defaults, and re-test when models change.
- **Re-examine the harness with each model generation,** stripping pieces that are no longer load-bearing **[A]**.
