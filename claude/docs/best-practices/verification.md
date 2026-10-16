# Verification: how an agent proves its work

## Give it a check it can run

- **The single highest-leverage practice:** "Give Claude a check it can run… It's the difference between a session
  you watch and one you walk away from." **[A]** (Claude Code best practices)
- **Gates, weakest to strongest** **[A]**: a check named in the prompt; a `/goal` condition re-judged every turn by a
  separate evaluator (which judges the transcript and runs no tools); a Stop hook; a verification subagent, "so the
  agent doing the work isn't the one grading it".
- **Ask for evidence, not assertions** — the command run and its output **[A]**. Agents have claimed commits that
  don't exist and deleted open tasks to hide unfinished work **[U]** (reported Claude Code issues).
- **Deterministic feedback in the loop** — compilers, linters, type checkers, tests — so failures are fixed before a
  person looks **[C]** (Thoughtworks *Trial*).
- **Bug fixes start with a failing test** that reproduces the issue **[A]**; fix the root cause, never suppress the
  error.

## Tests are the contract

- **The verifier must be nearly perfect, "otherwise Claude will solve the wrong problem"** **[A]** (C compiler
  project). Keep test output concise, log the rest to files, and offer a fast sampled run.
- **Agents weaken tests to get to green.** "It is unacceptable to remove or edit tests" is Anthropic's own
  long-running-harness instruction **[A]**; Kent Beck calls agents "unpredictable genies" that delete tests **[O]**.
  Treat any removed or loosened assertion in an agent's diff as a finding of the highest severity.
- **Keep test authorship apart from implementation where you can:** one session writes tests, another writes code
  to pass them **[A]** (writer/reviewer variants).
- **Mutation testing shows whether tests catch behaviour changes,** "critical in AI-assisted development" **[C]**
  (Thoughtworks *Trial*).
- **Before changing weakly tested code, add tests for its current behaviour** — see [planning.md](planning.md).

## Passing is not mergeable

- **Maintainers would reject about half of agent PRs that pass SWE-bench;** merge rates ran about 24 points below
  benchmark scores (296 PRs, four maintainers) **[S, small]** (METR, 2026).
- **Agent-authored PRs carried about 1.7× more issues** — 75% more logic errors, up to 2.74× more security issues —
  across 470 open-source PRs **[S, vendor-run]** (CodeRabbit).
- **AI amplifies what is there:** adoption now correlates with higher throughput but also more instability, rework
  and change failures **[S, survey]** (DORA 2025).

## Productivity claims are weak

- **METR's 2025 trial:** experienced developers were 19% slower with AI while believing they were 20% faster **[S]**.
  Its 2026 follow-up shows a directional speed-up that METR itself calls unreliable **[S]**.
- **Review is the bottleneck:** telemetry from a large adopter base showed far more merged PRs but much longer review
  times and bigger PRs, with flat delivery metrics **[U]** (Faros). Optimise for what a reviewer can check, not for
  output volume.
- **Measure stability and first-pass acceptance, not lines or PR counts** — "coding throughput as productivity
  measure" is Thoughtworks *Caution* **[C]**.
