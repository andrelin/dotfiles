# Sources

Fetched on 2026-10-16. Anthropic's engineering posts were read through a summariser, so spot-check a quote against
the page before reusing it publicly. Tags as in [README.md](README.md).

## Anthropic — Claude Code docs [A]

All under `https://code.claude.com/docs/en/`: `best-practices`, `memory`, `context-window`, `costs`, `skills`,
`sub-agents`, `hooks`, `permissions`, `permission-modes`, `security`, `headless`, `github-actions`, `routines`,
`desktop-scheduled-tasks`, `worktrees`, `model-config`, `goal`, `workflows`, `features-overview`,
`common-workflows`, `settings-reference`.

## Anthropic — engineering and platform docs [A]

- Building effective agents (Dec 2024): <https://www.anthropic.com/engineering/building-effective-agents>
- Effective context engineering (Sep 2025): <https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents>
- Writing effective tools for agents (Sep 2025): <https://www.anthropic.com/engineering/writing-tools-for-agents>
- Multi-agent research system (Jun 2025): <https://www.anthropic.com/engineering/multi-agent-research-system>
- Agent Skills (Oct 2025): <https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills>
- Skill authoring best practices: <https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices>
- Demystifying evals (Jan 2026): <https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents>
- Infrastructure noise in evals (Feb 2026): <https://www.anthropic.com/engineering/infrastructure-noise>
- Effective harnesses for long-running agents (Nov 2025): <https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents>
- Harness design for long-running apps (Mar 2026): <https://www.anthropic.com/engineering/harness-design-long-running-apps>
- Building a C compiler with parallel Claudes (Feb 2026): <https://www.anthropic.com/engineering/building-c-compiler>
- Auto mode (Mar 2026): <https://www.anthropic.com/engineering/claude-code-auto-mode>
- Sandboxing (Oct 2025): <https://www.anthropic.com/engineering/claude-code-sandboxing>
- How we contain Claude (May 2026): <https://www.anthropic.com/engineering/how-we-contain-claude>
- Code execution with MCP (Nov 2025): <https://www.anthropic.com/engineering/code-execution-with-mcp>
- Prompt injection defenses (Nov 2025): <https://www.anthropic.com/research/prompt-injection-defenses>
- Prompting best practices: <https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices>
- Prompting Claude Opus 5: <https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5>

## Studies [S]

- METR, AI and experienced developer productivity (2025): <https://simonwillison.net/b/8833> (summary); 2026
  update: <https://blog.robbowley.net/2026/04/04/metrs-developer-productivity-research-2026-update/>
- METR, SWE-bench-passing PRs maintainers would reject (Mar 2026): <https://metr.org/notes/2026-03-10-many-swe-bench-passing-prs-would-not-be-merged-into-main/>
- Evaluating AGENTS.md files (ICLR 2026): <https://arxiv.org/abs/2602.11988>
- IFScale, instruction-count scaling: <https://arxiv.org/abs/2507.11538>
- LLM reviews anchoring human reviewers (USI): <https://www.usi.ch/en/feeds/30481>
- Self-preference in LLM judges (2026): <https://arxiv.org/abs/2606.20093>
- LLM bug-report summaries, fabrication and omission: <https://www.alphaxiv.org/abs/2605.24137>
- CodeRabbit, AI versus human PRs (vendor-run): <https://coderabbit.ai/blog/state-of-ai-vs-human-code-generation-report>
- DORA, State of AI-assisted development 2025: <https://www.infoq.com/news/2025/09/dora-state-of-ai-in-dev-2025>
- Vercel, AGENTS.md against skills (vendor, narrow): <https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals>
- Aider, architect/editor model split (benchmark): <https://aider.chat/2025/01/24/r1-sonnet.html>
- Snyk ToxicSkills: <https://snyk.io/blog/toxicskills-malicious-ai-agent-skills-clawhub>
- Invariant Labs, GitHub MCP cross-repo injection: <https://invariantlabs.ai/blog/mcp-github-vulnerability>
- IDEsaster, agent-tool CVEs: <https://thehackernews.com/2025/12/researchers-uncover-30-flaws-in-ai.html>
- Rules File Backdoor: <https://thehackernews.com/2025/03/new-rules-file-backdoor-attack-lets.html>

## Practitioners and industry [C] [O]

- Thoughtworks Radar, spec-driven development: <https://www.thoughtworks.com/radar/techniques/spec-driven-development>;
  Ralph loop: <https://www.thoughtworks.com/radar/techniques/ralph-loop>
- Böckeler, spec-driven tools: <https://www.martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html>; context
  engineering: <https://martinfowler.com/articles/exploring-gen-ai/context-engineering-coding-agents.html>
- Simon Willison, agentic engineering patterns: <https://simonwillison.net/guides/agentic-engineering-patterns/>;
  parallel agents: <https://simonwillison.net/2025/Oct/5/parallel-coding-agents/>; the lethal trifecta:
  <https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/>
- Meta, Agents Rule of Two: <https://ai.meta.com/blog/practical-ai-agent-security/>
- OWASP Top 10 for Agentic Applications 2026: <https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/>
- Harper Reed, LLM codegen workflow: <https://harper.blog/2025/02/16/my-llm-codegen-workflow-atm/>
- Addy Osmani, AI coding workflow: <https://addyosmani.com/blog/ai-coding-workflow/>
- Cursor, agent best practices: <https://cursor.com/blog/agent-best-practices>
- Kent Beck on TDD with agents: <https://newsletter.pragmaticengineer.com/p/tdd-ai-agents-and-coding-with-kent>
- OpenAI, AGENTS.md to the Agentic AI Foundation: <https://openai.com/index/agentic-ai-foundation/>
- GitHub Agentic Workflows, safe outputs: <https://github.github.com/gh-aw/reference/safe-outputs/>; staged mode:
  <https://github.github.com/gh-aw/reference/staged-mode>
- ccpm: <https://github.com/automazeio/ccpm>
- postmark-mcp backdoor: <https://koi.ai/blog/postmark-mcp-npm-malicious-backdoor-email-theft>
- Anthropic's duplicate bot, reported failures [U]: <https://github.com/anthropics/claude-code/issues/35923>
