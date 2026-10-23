---
name: reviewing-for-feedback
description: Read before reviewing someone else's branch, MR, PR or plan to give them feedback - even a quick look at a colleague's change - and before re-reviewing one after its author pushes again.
---

# Reviewing for feedback

`/reviewing-for-feedback <branch|MR|PR|plan-file>`, or handed over by `reviewing-in-rounds`.
Someone else's work: nothing is fixed, so one pass of every lens plus verification, and the output is feedback the
user gives the author in their own name. Read `~/.claude/docs/review-lenses.md` first.

## It changes nothing

At every level: no edit, stage, rename, log, checkout, switch, rebase, stash or `git worktree add` in the repo, and
nothing posted to the platform. Reading needs none of them:

- **A branch:** `git fetch <remote>` from the remote holding it — ask if more than one could — then
  `git diff <remote>/<default>...<remote>/<branch>`, `git log` and `git show <ref>:<path>` for whole files.
- **An MR or PR number `<n>`:** after that fetch, `git fetch <remote> refs/pull/<n>/head` (GitHub) or
  `refs/merge-requests/<n>/head` (GitLab; a host you can't tell, try both) into `FETCH_HEAD` only, no local ref,
  and review `<remote>/<default>...FETCH_HEAD`. Never look it up on the platform.
- **A plan:** copy it to `<scratchpad>/reviewed-plan.md` with every `## Review log (` section removed.
- **Running code:** `git show <ref>:<path>` into a fresh `mktemp -d` and run it there.

`reviewing-locally`'s no-posting rule applies; its rebase never does — the branch is the author's.

## One pass

1. **Reviewers:** one fresh Agent per lens of the fitting set (code or plan), all in parallel, each with `model` set
   to this session's alias (`opus`, `sonnet`, `haiku`). Each prompt, and nothing more:
   > You review one lens of `<the diff command, or the plan copy's path>` in `<repo>`. Do not invoke any skill or
   > open `plan-*` or `00-follow-ups-*` files in the repo. Change nothing in the repo; run any experiment in a fresh
   > `mktemp -d`, and delete nothing but that directory, by the path it printed.
   > Lens: `<the lens's heading and questions>`. Severity: `<the scale>`. Report every finding you see, each with a
   > severity, the file and line, and the failure scenario or requirement it breaks.
2. **Verifiers:** one fresh Agent per lens — never one over every lens's findings, which skims them — same
   prohibitions, given that lens's findings, the artifact and the scale, told to refute each: drop or downgrade only
   with a written refutation. Findings naming neither a failure scenario nor a requirement are dropped.
3. **The report** — below — then a summary of it in the conversation.

## The report

`<scratchpad>/review-<branch>.md` (`/` → `-`; for a plan, its stem), in English whatever the thread's language:

1. **The verdict suggested:** approve, approve with nits, or changes requested — the user's call, said so.
2. **Findings by severity,** `blocking` first. Each: the file and line, why it matters in one or two sentences, a
   `Verified:` line with its verifier's verdict, and a suggested comment the user could paste to the author as
   written — addressed to them, with the fix.
3. **On a re-review, before the new findings:** each earlier finding marked addressed, partly addressed or open,
   with the line that shows it.

End the first review by telling the user the report's path and that the scratchpad lasts only this session, so they
can keep it if they want a re-review later.

## Re-review

Given an earlier report, as a path or pasted text: fetch again, review the whole branch as above, and check every
earlier finding against the new code before writing the new ones.

## Red flags

| Thought | Reality |
| --- | --- |
| "A worktree makes running the tests easier." | It writes to the author's repo. `git show` into `mktemp -d`. |
| "The diff is small, I'll just read it myself." | One reader finds what one reader finds. Run the lenses. |
| "The reviewers agree, verifying adds nothing." | A false finding goes out in the user's name. Every lens is verified. |
| "I'll post the comments, it saves a step." | They go out in the user's name. The user posts them. |
| "Let me fix it while I'm here." | It's their branch. Write the fix into the comment. |
