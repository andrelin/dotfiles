# Evals: measuring an agent, a prompt or a skill

## Vocabulary

A *task* is one case; a *trial* one attempt at it; a *grader* scores the outcome from the *transcript* **[A]**
(demystifying evals). Graders are code-based (fast, brittle), model-based (flexible, needs calibration) or human
(the reference). Use pass@k when one success is enough, pass^k when every run must succeed **[A]**.

## Building the set

- **Start small, from real failures:** 20–50 simple tasks drawn from bugs and manual checks **[A]**; Anthropic's
  research system started with about 20 queries **[A]**; a skill needs at least three scenarios **[A]**.
- **Make every task unambiguous:** "two domain experts would independently reach the same pass/fail verdict" **[A]**.
- **Balance both directions** — should-trigger and should-not-trigger, should-search and shouldn't — or the eval
  rewards a system that always says yes **[A]**.
- **Keep two suites:** capability evals start with a low pass rate and show progress; regression evals sit near 100%
  and catch breakage **[A]**. Retire saturated ones.
- **Hold cases out** when an agent tunes against the set, or it overfits to the cases you then report **[A]**
  (writing tools for agents).

## Running it

- **Isolate every trial** in a clean environment — leftover state skews results **[A]**. For skill triggers, a fresh
  session with the skill on and again with it off **[A]** (skills docs).
- **Run several trials per task:** model behaviour is non-deterministic, so a single run is an anecdote.
- **Grade outcomes, not paths:** step-sequence checks are "overly brittle" **[A]**.
- **Model graders:** one isolated judge per rubric dimension, an "Unknown" escape, partial credit where it fits,
  calibrated against human verdicts **[A]**.

## Reading it

- **Read the transcripts.** Scores hide why **[A]**.
- **0% across many trials usually means a broken task, not a bad system** **[A]**; grader and task bugs took one
  benchmark from 42% to 95% once fixed **[A]**.
- **Small differences are noise:** infrastructure configuration alone moved one benchmark by 6 points; distrust gaps
  under about 3 **[A]** (infrastructure noise). On a 20-case set, one case is 5 points.
- **Automated evals are one layer** of a "Swiss cheese" model with production monitoring and periodic human review
  **[A]**.
- **Tool and description wording is cheap to tune and high-yield:** small refinements to tool descriptions gave
  "dramatic improvements"; agent-rewritten descriptions cut completion time by 40% **[A]**.
