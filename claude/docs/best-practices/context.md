# Context: what loads, and what to keep out

The context window is the main constraint on an agent: "performance degrades as it fills" **[A]** (Claude Code best
practices). Anthropic calls the effect "context rot" and treats context as a finite attention budget **[A]**
(effective context engineering).

## Always-on instruction files

- **Keep them short and prune them.** For each line ask "Would removing this cause Claude to make mistakes?";
  "Bloated CLAUDE.md files cause Claude to ignore your actual instructions." **[A]** The docs' ceiling is under 200
  lines per file **[A]** (memory); this config's aims are far lower, which is consistent.
- **`@` imports don't save context:** imported files load at launch too **[A]**. A plain-text path the agent reads
  on demand is what defers the cost.
- **More instructions can make results worse.** An ICLR 2026 study of Claude Code, Codex and Qwen Code found
  LLM-generated AGENTS.md files cut task success by about 3% and raised cost by over 20%; human-written ones gained
  about 4% but still cost up to 19% more **[S]**. Instruction-following degrades as the count grows, favouring the
  earliest **[S]** (IFScale). Thoughtworks rates "agent instruction bloat" *Caution* **[C]**.
- **What belongs:** commands the agent can't guess, non-default conventions, gotchas, the permission rules.
  **What doesn't:** anything the code says, file-by-file tours, fast-changing facts, platitudes **[A]**.
- **Add a line when the agent gets the same thing wrong twice,** not pre-emptively **[A]** (features overview).
- **Emphasis works only when rare.** The docs suggest marking one skipped line; "if you emphasize many lines, none
  of them stands out" **[A]**. This config's form is a bold "Important:" prefix rather than capitals.
- **Notes for maintainers cost nothing** as block-level HTML comments, stripped before injection **[A]**.
- **AGENTS.md is the cross-tool standard** (Codex, Cursor, Gemini CLI, Copilot and others), now under the Linux
  Foundation's Agentic AI Foundation since December 2025 **[O]**. Claude Code reads it only where no `CLAUDE.md` exists, unless configured to.

## Loading on demand

- **Progressive disclosure:** a short always-on map, with detail in skills, path-scoped rules and docs loaded when
  the task needs them **[A]** **[C]** (Thoughtworks *Trial*).
- **Just-in-time retrieval:** keep identifiers — paths, queries, links — and fetch content through tools when needed;
  agentic search (grep, the filesystem) before semantic search **[A]**.
- **Prefer a CLI to an MCP server** where both exist; it is the more context-efficient interface **[A]**.

## What survives compaction

- **Re-injected from disk:** the project-root `CLAUDE.md`, unscoped rules, auto memory, the plan-mode plan **[A]**.
- **Dropped until re-triggered:** path-scoped rules and nested `CLAUDE.md` files. "If a rule must persist across
  compaction, drop the `paths:` frontmatter or move it to the project-root CLAUDE.md." **[A]**
- **Skills:** only the first 5,000 tokens of each invoked skill survive (25,000 across all) — put what matters at
  the top, and write standing rules rather than one-off steps **[A]**.
- **A SessionStart hook with matcher `compact`** can re-inject context after compaction **[A]**.

## Clear, compact or start fresh

- **`/clear` between unrelated tasks;** after two failed corrections on one issue, clear and re-prompt: "A clean
  session with a better prompt almost always outperforms a long session with accumulated corrections." **[A]**
- **Compaction is itself a large request** — it reads what it summarises; `/clear` costs nothing **[A]** (costs).
  Steer it with `/compact <focus>` or compaction instructions in `CLAUDE.md`.
- **A fresh window can beat compaction** for long work: current models rediscover state from the filesystem well,
  given a prescribed start — "Review progress.txt, tests.json, and the git logs" **[A]** (prompting best practices).
- **Tell the agent when compaction exists,** or it may rush to wrap up near the limit ("context anxiety") **[A]**.
- **Side questions** go through `/btw`, which never enters history **[A]**.

## Durable state

- **Machine-local state desyncs.** Auto memory "is machine-local… not shared across machines" **[A]**, and plan
  mode's plans default to `~/.claude/plans`; the `plansDirectory` setting moves them into the repo **[A]**.
- **Store state by kind:** structured files (JSON) for status the agent must not rewrite loosely — the model is
  "less likely to inappropriately change or overwrite JSON files compared to Markdown" — and free text for progress
  notes; git as the log **[A]** (long-running harnesses).
