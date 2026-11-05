<!-- DOCTOC SKIP -->

# Review findings (plan)

Scope: Task 14 and the lines naming it (2026-11-05), the rest read as context.

## Round 1

### R1-1 · minor · scope and slicing

The headless pair's baseline is unverified, and the `--setting-sources` variant drops the global `CLAUDE.md` and every
rule along with the new file (checked by the verifier), so only a `HOME` without the file isolates it.
Downgraded from major by the verifier: the user's complaint is the evidence; the test only confirms it.

### R1-2 · nit · scope and slicing

No out-of-scope line; the Files list already names only the new rule. Downgraded from minor.

### R1-3 · minor · scope and slicing

A copy of the real `HOME` is not the throwaway `HOME` the 2026-10-30 yes names; the pair needs one holding only `.claude`.

### R1-4 · minor · decisions

Whether a logged `user decision needed — <question>` carries the restatement. Downgraded from major: the Change says it
does; `<question>` is a placeholder, so `review-log.md`'s form is unchanged (consistency verifier).

### R1-5 · minor · decisions

Options and a recommendation fit a choice, not an information or yes/no question; the rule's wording should say
"for a choice". Downgraded from major: the user's words set "every question".

### R1-6 · minor · decisions, consistency, grounding, work context

The 2026-11-05 Approvals note cites the run-scoped 2026-11-02 yes; the writes rest on 2026-10-30's first bullet plus
the user's 2026-11-03 branch request. Downgraded from major.

### R1-7 · nit · decisions

"Its first line says why it has none": in `style.md` the why sits under the heading.

### R1-8 · minor · consistency

The `Final code review` row stays ✅ DONE and the open code log ends in `Done (code):`, so Task 14's code review would
stop to ask before starting fresh. Downgraded from major: one yes/no stop, nothing built wrong.

### R1-9 · minor · consistency

"Subagents and skill runs included" is unverified for `/code-review` runs, Task 7's open conflict.

### R1-10 · nit · consistency

The handover list doesn't name Task 14; the status table and order line already cover it. Downgraded from minor.

### R1-11 · nit · consistency

"As Task 6's scenario tests" points at the wrong precedent: those ran as subagents.

### R1-12 · minor · grounding

"The recommendation with its reason" is the plan's addition, not the user's words; the rule-over-`CLAUDE.md` reason
is better put as the requirement needing several lines.

### R1-13 · nit · work context

Recorded outputs go into a public plan: the scenario's history must be invented, `example-client`-style.

Refuted: whether the rule binds a subagent's question (a relayed question is the caller's); a missing pass criterion
(left to the code); Task 13 not naming Task 14 (its Interfaces line does); the file map listing this plan; `review-log.md`
in Files (its form is unchanged); the channels the scenario exercises (left to the code).
