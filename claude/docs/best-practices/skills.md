# Skills: writing them, and making them load

## How skills load

- **Progressive disclosure:** name and description are always in context; the body loads when the skill is
  relevant; linked files load only when read **[A]** (agent skills). Keep the body under 500 lines and references one
  level deep **[A]**.
- **The description is the trigger.** "Claude matches your task against skill descriptions"; the description and
  `when_to_use` together are cut at 1,536 characters — put the key use case first **[A]** (skills docs).
- **The listing has a budget:** 1% of the context window, and on overflow the least-invoked skills lose their
  descriptions first **[A]**. `/doctor` and `/skill-doctor` show the cost. A skill with
  `disable-model-invocation: true` costs nothing in the listing and loads only when invoked by name **[A]**.
- **Name collisions:** a personal skill shadows a same-named project one; plugin skills are namespaced and never
  shadowed, so "prefer my skill over the plugin's" can only be an instruction **[A]**.

## Skills misfire silently

- **In Vercel's evals the skill was never invoked in 56% of cases;** a compressed docs index in `AGENTS.md` scored
  100% where skills peaked at 79% **[S, vendor, narrow task]**. A skill that never triggers fails without an error.
- **Therefore anything that must always apply is never only a skill.** Put it in always-on context or a hook **[A]**
  (skills docs: "rules that must always hold belong in a hook").
- **Over-aggressive wording over-triggers on current models** — "MUST use when…" is a cause **[A]** (prompting best
  practices). Pushiness about *when*, without shouting, is the target.

## Writing the description

- **Anthropic's pattern says what the skill does and when to use it,** in the third person **[A]** (skill authoring
  best practices). This config deliberately says only *when* — a summary in the description gets followed in place of
  the body — and settles the difference with trigger evals rather than by assertion.
- **Name the easy-to-miss trigger** ("even when the user only says…") rather than restating the obvious one.

## Writing the body

- **Build evals before the docs:** run representative tasks without the skill, note the gaps, write a few scenarios
  that test them, record a baseline, then write the minimum that closes them **[A]**.
- **Author with one instance, test with a fresh one** — leftover context from authoring masks gaps **[A]**.
- **Test across models** (Haiku, Sonnet, Opus) when the skill must work on all of them **[A]**.
- **Write standing rules, not one-off steps:** the file isn't re-read on later turns, and after compaction only its
  first 5,000 tokens survive **[A]**.
- **Push deterministic work into scripts** that handle their own errors; say whether the agent should run a script or
  read it; validate before executing **[A]** ("solve, don't defer").

## Supply chain

- **Install skills and plugins only from sources you trust, and read them** **[A]**. A scan of about 4,000 public
  skills found 13.4% with critical issues — malware, prompt injection, secrets **[S]** (Snyk ToxicSkills).
- **Review plugin and MCP updates as code, and pin versions** **[C]** — see [safety.md](safety.md).
