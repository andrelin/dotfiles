---
name: reviewing-in-rounds
description: Read before reviewing your own plan or a branch this workflow built - even a small one, and even when the user only says "take a look" - and before resuming an interrupted review or judging whether a review process is working.
---

# Reviewing in rounds

`/reviewing-in-rounds plan <plan-file>` or `/reviewing-in-rounds code [<plan-file>]`; `code` with no plan reviews the
current branch. Rounds of fresh reviewers, one per lens, verified and fixed between rounds, logged in the plan.
First read `~/.claude/docs/review-lenses.md` (lenses, severity) and `~/.claude/docs/review-log.md` (log, findings
file, resuming, closing): their formats are literal.

## Before anything is written or renamed

1. **Whose work.** The user's when the evidence says so: a plan untracked or written in this session, or whose
   commits are all by `git config user.email`; a code review whose plan has a `Base:` line; a branch whose commits
   since the base are all by that email. Otherwise ask once — someone else's hands over to `reviewing-for-feedback`
   and stops, with nothing written.
2. **The level**, from `~/.claude/hooks/work-context.sh level`. At company and customer level, add `/plan-*.md` to
   `$(git rev-parse --git-path info/exclude)` before the first plan or review file is written.
3. **The name.** A plan not named `plan-*.md` at the repo root is first moved to `plan-<stem>.md` there (a stem
   already starting `plan-` kept as is): `mv` when untracked; when tracked, a copy, and tell the user the original is
   theirs to remove — a staged rename trips `implementing-plans`' clean-tree check.
4. **The bar, for a guard, parser or other security check:** get it into the spec before round 1 — which forms it
   must catch and which are accepted gaps — or the correctness lens keeps finding new bypass forms and the rounds
   don't converge.
5. **Resume or start**, per `review-log.md` § *Resuming*: an open question first, an interrupted round finished, a
   due re-evaluation run. A finished open section: say so and ask; on a yes, close it and start at round 1 — from the
   second close that day, the closed names gain `-<n>` before `.md`, `<n>` being that close's count for the day.
6. **Code only, the leftovers:** before round 1 of a fresh run, record the entries of
   `git status --porcelain -z --no-renames --untracked-files=all --` with the two pathspecs below (`| tr '\0' '\n'`)
   whose worktree column isn't blank — unstaged or untracked — as a `Leftovers before round 1:` line at the top of
   the findings file, so a resumed session has it too. Completion compares against it.

## The inputs

- **The plan copy:** `<scratchpad>/reviewed-plan.md`, rewritten each round from the plan with every `## Review log (`
  section removed — for a code review too, which the plan-conformance lens checks the diff against. Pass its path,
  never the text: a pasted plan is one more thing to get wrong.
- **The diff,** for code, from the local clone at every level, never the platform: the working tree (staged, unstaged,
  untracked) against the base — the plan's `Base:` line, else the merge-base with a freshly fetched default branch,
  else ask. Always with `':(top,glob,exclude)plan-*' ':(top,glob,exclude)**/00-follow-ups-*'`; untracked files listed with
  `git ls-files --others --exclude-standard` under the same pathspecs.

## A round

1. **Reviewers:** one fresh Agent per lens of the kind's set, all in parallel, each with `model` set to this
   session's alias (`opus`, `sonnet`, `haiku`; a full model ID passes its family's). Each prompt, and nothing more:
   > You review one lens of `<scratchpad>/reviewed-plan.md` `[and the diff from <the git diff command>]` in `<repo>`.
   > Do not invoke any skill or open `plan-*` or `00-follow-ups-*` files in the repo. Change nothing in the repo;
   > run any experiment in a fresh `mktemp -d`, and delete nothing but that directory, by the path it printed.
   > A scratch repo there: `git init` in a Bash call of its own, then literal paths, never `cd "$var"` or `git -C`.
   > Lens: `<the lens's heading and questions>`. Severity: `<the scale>`. Report every finding you see, each with a
   > severity, the location, and the failure scenario or requirement it breaks.
2. **Verifiers:** one fresh Agent per lens, given that lens's findings, the artifact and the scale, told to refute
   each: drop or downgrade only with a written refutation. Same prohibitions. Unsupported findings — no failure
   scenario, no requirement — are dropped.
3. **Record** the verified findings in the findings file under `## Round <n>`, refutations beside theirs.
4. **Fix** every surviving `blocking`, `major` and `minor` — yourself, or one fixer Agent told it may edit, makes no git
   writes, invokes no skill, and reports the paths it changed. Mark each entry `Fixed:`. **Leave nits alone:** every
   fix is new text the next round reviews, and polishing wording is how a review stops converging.
5. **Code only:** run the project's tests. A failure is a `blocking` finding of this round; record it, fix it, rerun.
6. **Log the row.** Then, if the round is 15, 20, 25, … and didn't finish the review, the re-evaluation.

**Done** when a round's verified findings hold no `blocking` or `major` and its minors are fixed: write
`Done (<kind>):` with the round and the unfixed nits' ids. Final — those last fixes are not re-reviewed.

## Re-evaluation

A fresh Agent, no skills, no edits, reads the log and the findings file and recommends one of: continue as is,
change a lens, or a user decision. Log it. The first two are applied and the loop goes on; a user decision stops the
run with the question logged. Always a user decision: a change to the severity scale, two lenses in conflict over what
the spec requires, and stopping because the remaining findings don't affect correctness or the requirements.

## Completion of a code review

1. **Stage** the paths the fixes changed: the leftovers now that weren't leftovers before round 1, never `plan-*`.
   One that was a leftover both times stays unstaged, and the report names it.
2. **Pathspecs:** each task's Files list (`writing-plans` § *What each task carries*) intersected with
   `git diff --cached --name-only --no-renames`, so a rename's deletion is kept. One commit per task when every pair
   of lists is disjoint, a fix outside every list going with the last task; else one commit of them all. No plan:
   one commit of `git diff --cached --name-only --no-renames`.
3. **If `git diff -- <paths>` is non-empty, stop** and list those paths: `git commit -- <paths>` would take their
   unstaged edits too.
4. **Personal and company:** offer the commit, run it only on a yes. **Customer:** draft it for the user.
   **Company, no plan, on the default branch:** offer none, and say the company bar wants a branch.
5. **After the commit runs** — yours on a yes, or the drafted one once the user says it ran — delete every
   `refs/checkpoints/<branch>/*` with `git update-ref -d`. A declined commit keeps them, and the report says so.
6. **The report** names the changed files no verified finding touched — where the user's own read should start.
7. Then `filing-learnings`, before reporting the review done.

## Red flags

| Thought | Reality |
| --- | --- |
| "One more round will settle it." | Past round 15 that is the re-evaluation's call, not yours. |
| "This major is really a minor." | Only a verifier's written refutation downgrades. Downgrading to end the loop hides it. |
| "Tell round 2 what round 1 found, to save time." | A reviewer primed with findings re-finds them and misses the rest. |
| "Only report serious issues." | Models follow a threshold literally and recall drops. Filtering is the verifier's job. |
| "Reuse the round-1 reviewer, it knows the plan." | It knows its own earlier reading. Every round is fresh agents. |
| "The PR's diff view is quicker." | The local clone, every level. The platform's diff has its own base. |
| "Give the reviewers the findings file for context." | Then they review the findings, not the artifact. |
