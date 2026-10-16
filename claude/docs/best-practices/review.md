# Review: agents reviewing agents, and people reviewing both

## Separate the writer from the reviewer

- **Review in a fresh context:** it "improves code review since Claude won't be biased toward code it just wrote";
  the reviewer "sees only the diff and the criteria you give it" **[A]** (Claude Code best practices).
- **A standalone, sceptically tuned evaluator beats self-critique.** Agents grading their own work "confidently
  prais[e] the work — even when… obviously mediocre"; "tuning a standalone evaluator to be skeptical turns out to be
  far more tractable" **[A]** (harness design). Calibrate it with a few scored examples of correct verdicts.
- **Same-model bias is contested:** an older study found models rate their own outputs about 10% higher, a 2026 one
  found no detectable effect on instruction-following **[S, mixed]**. A different model as reviewer is a reasonable
  hedge, not a requirement.

## Adversarial reviewers always find something

- "A reviewer prompted to find gaps will usually report some, even when the work is sound… Chasing every finding
  leads to over-engineering… flag only gaps that affect correctness or the stated requirements." **[A]**
- **But don't filter inside the reviewer's prompt on current Opus models:** "only report high-severity issues" is
  followed literally and lowers recall; "ask it to report everything and filter in a separate pass" **[A]**
  (prompting Claude Opus 5). Severity is assigned by the reviewer, the threshold applied afterwards.
- **Make every finding earn its place:** a concrete failure scenario, or the requirement it violates **[C]**.
  AI review tools' own precision is modest — one test put a leading tool at 64% **[U]** — and vendors' benchmarks
  each crown the vendor **[O]**.
- **Bound the loop.** Anthropic's agent patterns add "stopping conditions (such as a maximum number of iterations)"
  and a pause for a person at blockers **[A]** (building effective agents). A review loop judged by "no serious
  findings left" can fail to converge on a large artifact; pair it with a cap, or a periodic check of whether the
  findings are still about correctness rather than polish.
- **A verifier pass that tries to refute each finding** is the separate filtering pass the guidance asks for.

## People reviewing agent output

- **AI review anchors people.** In a controlled study, reviewers given an LLM review accepted most of its issues and
  focused on the places it flagged rather than searching elsewhere **[S]** (USI, 29 professionals). Do your own read
  first, or explicitly cover what the agent didn't flag.
- **Never pass on unreviewed agent code to collaborators** **[O]** (Willison). On someone else's project the review
  is yours to give, under your name.
- **Small diffs get real review.** Bigger AI-era PRs drove review time up sharply **[U]**; keep changes reviewable.
- **Watch for cognitive debt** — code nobody on the team understands — Thoughtworks *Caution* **[C]**.

## Reviewing agent-written tests

- **Read test diffs as closely as code diffs.** A removed or loosened assertion is the cheapest way for an agent to
  turn red into green — see [verification.md](verification.md).
