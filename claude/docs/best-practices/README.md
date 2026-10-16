# Best practices for working with AI agents

A reference library, researched on 2026-10-16, for this config and for any project that wants to cite it.
Read the file for the decision in front of you, not the set: each covers one subject and stands alone.
Reference it from another project as `~/.claude/docs/best-practices/<file>.md`.

| File | Read when you are deciding… |
| --- | --- |
| [context.md](context.md) | what goes in `CLAUDE.md`, a rule or a skill; when to clear, compact or start fresh |
| [planning.md](planning.md) | whether a change needs a plan, and what a plan or spec must hold |
| [verification.md](verification.md) | how an agent proves its work, and how tests stay the contract |
| [review.md](review.md) | how to review agent output — with agents, with people, in rounds |
| [multi-agent.md](multi-agent.md) | whether to fan out to subagents or parallel sessions, and which model each gets |
| [skills.md](skills.md) | how to write a skill and its description, and how to test that it triggers |
| [evals.md](evals.md) | how to measure an agent, a prompt or a skill |
| [safety.md](safety.md) | what an agent may do unsupervised, and how to enforce it |
| [automation.md](automation.md) | scheduled or unattended agents, and agents writing to trackers |
| [sources.md](sources.md) | where a claim comes from, and how much to trust it |

## The short version

1. **Context is the scarce resource.** Every always-loaded line costs every task; load the rest on demand.
2. **Instructions advise, hooks enforce.** Anything that must hold every time is a hook or a permission, never prose alone.
3. **Hand off through files, not chat.** A fresh session reading an artifact beats a long session carrying history.
4. **Plan when the diff can't be said in one sentence;** skip the plan when it can.
5. **Give the agent a check it can run,** and ask for evidence, not assertions.
6. **Tests are the contract.** An agent that weakens a test to get to green has failed the task.
7. **The writer never grades its own work.** Review in a fresh context, against stated criteria.
8. **Adversarial reviewers always find something.** Bound the loop and judge findings against the requirements.
9. **Fan out only for breadth.** Parallel agents cost several times the tokens and pay only on independent work.
10. **Measure before tuning,** with small, unambiguous evals drawn from real failures, and read the transcripts.
11. **Treat repo content, issues and plugins as untrusted input.** Never give one session private data, untrusted
    content and a way out all at once.
12. **Compute facts with scripts; let the model write the narrative** — status, counts and links never come from
    the model's memory.

## How to read the evidence tags

Each claim carries one: **[A]** Anthropic's docs or engineering posts; **[S]** a measured study; **[C]**
practitioner consensus across independent sources; **[O]** one author's or vendor's opinion or self-report;
**[U]** seen only second-hand. Full list with dates: [sources.md](sources.md).
Guidance ages fast: Anthropic itself says harness pieces "go stale as models improve". Re-check a claim older
than a model generation before building on it.
