<!-- DOCTOC SKIP -->

# Review findings (plan) — plan-ai-framework.md

Scope: Tasks 15, 15b, 15c and 16, detailed or added 2026-11-05; the rest of the plan read as context.

## Round 1

### R1-1 · major · grounding

Task 15 · Change: Scope (window start), Reviews, Cost; Interfaces: entry `sessions[]`/`totals`: Entries are per *final
code review run*, but each one covers the plan's whole history. The window starts at the earliest record that names
the plan, the review data is every `## Review log (` section (closed ones included) plus every
`<stem>-review-findings-*.md` (the `-closed-*` files included), and `cost_usd` is the session's unwindowed
`cost-state`. I checked: 11 of the 19 surviving sessions in this repo name `plan-ai-framework.md`, going back to Oct
7. Four findings files sit beside it, two of them closed. This plan has already had three final code reviews (Tasks
4/12/11/7, Task 14, and Task 15b's next one). A simpler approach is already available. The plan carries a `Base:` line
per run (implementing-plans step 4, and reviewing-in-rounds uses it as the diff base). Start the window at the Base
commit's time, count only that run's open log and findings file, and record dollars only for sessions that sit inside
the window. Scenario: Task 15's real run records about a month of sessions and every closed round. Task 15b's
end-to-end run, after this plan's next code review, records the same sessions, rounds and the long-lived session
775cc01c's whole $216+ again. Task 15c's per-plan cost and rounds-over-time trend then sums overlapping entries and
inflates this plan several times over. Its cut candidates rest on those inflated numbers.
Fixed: Task 15 now records one entry per implementing run: the window starts at the plan's `Base:` commit time,
reviews come from open log sections and un-closed findings files only, and dollars count only for sessions wholly
inside the window; a two-run fixture test added.

### R1-2 · minor · grounding

Task 15 · Change: Cost; Task 15b · Change: `record` prints cost per session: The session that runs `record` (the one
driving the plan, usually the most expensive) never has a current `cost-state` at record time. I verified this on the
live session 775cc01c. Its last `cost-state` is at line 5055 of 7008, $216.11, written before a resume. So the cost
that 15b prints for the introspection is stale or null for the dominant session in every entry. Refreshing it is
pushed to 15c's sketch as "settled when detailed", which means the short introspection the user asked for after every
plan never sees its own run's dollars. Simpler: compute dollars from the windowed transcript tokens with a per-model
price table, keeping `cost-state` as a cross-check. Or settle the refresh mechanism now, in 15/15b. Scenario: After
the next final code review, `record` prints `cost_usd` of $216 (stale, the whole session since Nov 2) or null for the
main session. The model-written introspection judges what the run cost from that number, and the entry stays wrong
until someone re-runs `record`, which nothing schedules.
Refuted: Downgraded from major by the verifier. Downgraded. The plan knows about this and states it: cost-state 'is
written when a session exits, so the session running the script has none, or a stale one'. It flags such sessions with
`cost_complete` false and nulls `cost_usd` when there is none. It also defers refreshing them to 15c by design. The
introspection still gets windowed tokens from the transcript. What `record` prints and how it labels an incomplete
cost is an output-format choice the executor can make. Real, but cheap to settle while implementing 15b, for example
by printing incomplete cost as such.

### R1-3 · minor · grounding

Task 15 · Change: The log repo (push); Approvals 'Not yet asked' bullet ('on every machine'): The plan never pulls the
log repo. It does `git add`, commit, `git push`. A failed push only warns and "keeps the commit for the next push".
The global CLAUDE.md says the user works from more than one machine, and the pending approval covers pushing "on every
machine". As soon as machine B has pushed an entry, every push from machine A is rejected as non-fast-forward,
permanently, because no later step fetches or rebases. Task 15c's report then reads a clone that is missing the other
machine's entries. The approach assumes a single writer and nothing checks that assumption. Entries are distinct
files, so a `git pull --rebase` before the push is enough. Scenario: The user records a plan on the laptop, then one
on the desktop. Every later `record` and `note` on the laptop prints a push warning, exits 0 and piles up local
commits that never reach `andrelin/ai-framework-log`. `ai-log report` on the desktop silently leaves the laptop's
plans out.
Refuted: Downgraded from major by the verifier. Real, but downgraded. The plan does only add, commit and push, and the
pending approval says 'on every machine', so the non-fast-forward scenario is concrete. The approach does not rest on
a single writer, though. Entries are separate files named by id, so a `git pull --rebase` before the push is a
one-line fix with no conflicts. That is cheap to settle while implementing and a reviewer can check it in the diff. It
should still be named in the plan, since the tests as written wouldn't catch it.

### R1-4 · major · grounding

Task 15b · Change: `note <id>` checks and 'At every level'; Task 15 user decision 'Still free of customer details': At
customer level, a model-written free-text introspection about the customer's work is pushed to GitHub. The only
machine check is a blocklist: absolute paths, `~/.claude-customers` entries, and the repo's host, owner, name and
folder. Engagement details that are not names pass that check: feature names, system names, defects, hostnames written
without the owner. The user's requirement was "still free of customer details: redacted copies", and a name blocklist
cannot enforce that on prose. The global CLAUDE.md also says the customer's own CLAUDE.md wins at customer level, and
the plan never consults it before exporting text. Simpler: at customer level, write only the numeric entry (already
redacted by construction) and keep the prose note out of the repo, or reduce it to the three headings over counts.
Scenario: After a customer plan, the introspection reads "Didn't: the correctness lens missed the race in the invoice
batch export to the ERP (R3-2)". It names no customer, owner or path, so `note` accepts it and pushes it to the
personal GitHub repo. That is a customer engagement detail stored off the customer's premises.
Fixed: Replaced the blocklist-only design with the user's 2026-11-05 decision: entries store redacted prompts,
questions and the introspection at every level; `ai-log` redacts mechanically (every customers-file form, remotes,
folders, hosts, emails, paths, URLs, tokens), and at customer level holds the entry until a model pass gathers the
session's customer terms into `--terms`, re-runs and re-reads it before `publish`; fixtures with invented terms only
that pass knows.

### R1-5 · minor · grounding

Task 15 'Why one skill line doesn't contradict "no skill changes"'; Task 15b Files (`reviewing-in-rounds/SKILL.md`);
Approvals 2026-11-05: The user picked "a script ... no skill changes" (Approvals, 2026-11-05), and Task 15b adds a
step to `reviewing-in-rounds`. The plan argues that the user meant no per-stage instrumentation, but that is the
plan's reading of the decision, not the user's ruling. The 'Not yet asked' bullet that goes to the user before 15b
covers only the commit and push. The skill step does not trace back to a user decision. Scenario: 15b's code review or
the user finds a skill change that the recorded decision rules out. The fix is cheap: put the one-line skill step to
the user together with the pending approval.

### R1-6 · minor · grounding

Task 15 · Interfaces (`tokens` model → input/output/…, `workflows`); Tests 'Real data': I verified that Workflow-tool
agents leave no transcripts. The 13 `wf_*.json` runs in session 775cc01c have 5 to 14 agents each, and no subagent
file starts inside any run's time span. Their `totalTokens` (about 1M per review round) comes with no per-model or
input/output split. So the per-model token figures, and the "tokens ≤ cost-state" sanity check, leave out the review
rounds, which are the bulk of the work. The entry keeps `workflows.tokens` apart, but nothing says that `record`'s
printed "cost and tokens per session" must add them in. Scenario: An introspection compares the token counts of two
plans' runs. One plan's reviews ran through Workflow and the other's through Agent calls, so the Workflow one looks
far cheaper than it was, and a cut candidate is picked on wrong numbers.
Refuted: Dropped by the verifier. The plan already handles workflow runs apart. It reads `wf_*.json` (`agentCount`,
`totalTokens`, `durationMs`) into each session's `workflows` field (`runs`, `agents`, `tokens`, `ms`) and into
`totals`. The 'tokens ≤ cost-state' check stays valid when workflow tokens are left out, because leaving them out can
only lower the transcript side. Whether `record`'s printed summary adds `workflows.tokens` to the per-model figures is
an output-format choice, which is out of scope.

### R1-7 · minor · grounding

Task 15 · Sketch vs Interfaces (entry fields); Change: Scope: The sketch's data list includes "stops for the user,
re-asked questions, failed attempts", and the entry drops them without saying so. `questions` counts only
`AskUserQuestion` calls: 20 across all 19 sessions here, against 444 Agent calls. In this workflow most questions come
at the end of a message (Task 14's subject). The scope also leaves out the headless `claude -p` test sessions a stage
starts in `mktemp -d` cwds (the handover cites a $39 battery), because their `cwd` is not under the work repo.
Scenario: The cross-session report shows almost no stops for the user and leaves out test-battery spending. The 'what
isn't pulling its weight' judgement then misses the two costs the user is most likely to notice.

### R1-8 · minor · grounding

Task 16 · Change ('The rule stays under its 30-line aim'): The claim is false. `bin/check-md-limits` counts
front-matter lines. I copied the rule into a `mktemp -d`, added 11 glob lines, and the checker reported "is 38 lines;
keep it to 30 or fewer (hard cap 50)". That is advisory, exit 0, but over the stated aim. Scenario: The executor
follows the plan, gets the advisory note, and either ships over the aim against the plan's own claim or improvises.
The cheap fix is to accept 38 lines, or check whether `paths:` supports a brace glob.

### R1-9 · minor · grounding

Task 16 · Spec and Tests: The cause has not been proven. The user saw the rule fail to load for a `.cs` file in a
*desktop* session. The test runs only the CLI (`claude -p`), and only after the change, with no baseline run before it
showing that a `.cs` file does not load the rule today. If desktop sessions load `~/.claude/rules` path-scoped rules
differently, or not at all, adding the globs does not fix what the user reported. Scenario: The globs are added, the
headless CLI test passes, and the next desktop session on a `.cs` file still does not load `writing-code.md`. The
report is closed without its cause ever having been reproduced.
Refuted: Dropped by the verifier. The cause is visible in the repo. The rule's `paths:` lists no `*.cs` glob, so it
can't load by path for a `.cs` file in any client. The user then ruled on the fix ('cover C# plus the common
languages'). The idea that desktop sessions load path-scoped rules differently comes with no evidence. Whether to add
a baseline run before the change is exact test design, which is out of scope.

### R1-10 · major · scope and slicing

Task 15, Change § Scope (window) and Interfaces (`<commit>` default HEAD): The window runs from the earliest record
anywhere that names the plan's basename to the commit time. That assumes one plan means one run. Long-lived plans are
run several times, and this one has had at least four runs (2026-10-16, 10-30, 11-02, 11-05). Each later `record`
re-includes every earlier run's sessions inside its own window, and each session's `cost_usd` is counted whole,
without a window. Nothing in the plan bounds the start by the previous entry for the same plan, or by the previous
commit. Scenario: Task 15b's step records an entry at each final code review of plan-ai-framework.md. The second
entry's tokens, agents, turns and cost include the first run's too. Task 15c's trends then show cost growing per plan
when it isn't, and since entries are append-only aggregates, the double count is costly to undo once entries pile up
in the private repo.
Fixed: An entry covers one run, from the plan's `Base:` commit time to the recorded commit; each run gets its own id,
and a later run's window starts at its own `Base:`.

### R1-11 · minor · scope and slicing

Task 15, Tests last bullet (Real data) versus the Revisit section and the task order: The riskiest assumptions are
tested last, after the whole schema, redaction, log-repo and shim machinery is built. Those assumptions are that 'a
tool_use input names the plan basename' picks the right sessions, that the transcript fields are present as inspected,
and that the numbers are enough to judge a stage by. The Revisit section that asks whether an entry holds what an
introspection needs also comes only after the full build. A `--dry-run` over real transcripts should come first, as a
spike, before the full field list is fixed. Scenario: The real dry run shows that scope picks up sessions from other
plans that merely read this plan, or misses Workflow-run reviewers. Or the Revisit finds that per-stage numbers (from
`attributionSkill`) are what matter. Either way, the schema, the fixtures and the redaction tests are reworked after
being built, and `"schema": 1` entries may already have been pushed.
Refuted: Downgraded from major by the verifier. Downgraded. The field-presence half is already settled: § 'What the
transcripts hold' was inspected on real transcripts on 2026-11-05. What remains unverified is the scope heuristic,
which is one jq filter, and that is cheap to change. The entry carries a `"schema": 1` version for exactly this kind
of change. Nothing stops the executor from running `--dry-run` early, since test order inside a task is the executor's
to choose. The real risk is that one real entry gets pushed before the Revisit. That is real but cheap to settle while
implementing, not a decision that is costly to reverse.

### R1-12 · major · scope and slicing

Task 15b, Files and Change (`claude/skills/reviewing-in-rounds/SKILL.md` step); Approvals 'Asked and answered
2026-11-05' first bullet; 'Not yet asked' block: The user approved Task 15 as 'a script ... no skill changes'. Task
15b edits a skill, and the plan argues itself past that ruling ('Why one skill line doesn't contradict'). It does not
put the question back to the user. The pending approval block lists only the auto-commit and push to the log repo, not
the skill edit. An approval covers what it names, so the skill change has no approval. Scenario: The executor reaches
Task 15b, gets the commit-and-push yes, and edits `reviewing-in-rounds`. That goes against the user's explicit 'no
skill changes' choice, and the user finds out only in the diff.
Fixed: Recorded the user's 2026-11-05 ruling ("Yes, one line is fine.") in Task 15's decisions and § Approvals,
replacing the plan's own argument.

### R1-13 · minor · scope and slicing

Order paragraph ('15 → 15b → 15c ... 15c detailed only once real plans have left entries'; '13 comes after every other
task') and Task 15c: Task 15c stays a sketch until several real plans have left entries, for an open-ended time. Task
13, which folds this plan into durable docs and deletes it, must come after every other task, 15c included. Nothing
states whether 15c moves out of this plan, for example into the Task 13 issue, or whether 13 may run without it.
Scenario: Every task but 15c finishes. The executor can't start Task 13 because the order forbids it, and the plan
file lingers for weeks waiting on data from other plans. Or the executor details and builds 15c early on one or two
entries, building a report nothing has data for.
Refuted: Downgraded from major by the verifier. Downgraded. The conflict is real: the Order line has 13 after every
other task, and 15c stays a sketch until real entries exist. But Task 13's own R3 deviation already gives the way out:
before the delete, 'every item still open in this plan' goes into a GitHub issue filed with writing-issues. Moving 15c
into that issue, and saying so in the Order line, is a one-line fix. The executor is not stuck with no option, so this
is cheap to settle and not major.

### R1-14 · minor · scope and slicing

Task 16, Spec, Change and Tests: The plan reads the user's report ('didn't load for a `.cs` file in a desktop
session') as a missing glob and fixes the globs. It never reproduces the failure: there is no baseline run showing
that `.cs` does not load the rule today. The test runs headless CLI `claude -p`, not the desktop session where the
user hit it. If the desktop app handles `paths:` rules differently, the change ships and the test passes while the
user's case stays broken. Scenario: The globs are added and the headless check names `writing-code.md` for `.cs`. The
user opens a `.cs` file in the desktop app again and the rule still doesn't load, because the cause was the desktop
surface, not the glob. The task is marked done on a test that never exercised the report.
Refuted: Downgraded from major by the verifier. Downgraded. The cause is visible without running anything.
claude/rules/writing-code.md's `paths:` lists only kt/java/ts/tsx/js/jsx/py/sh/zsh/kts plus `bin/**` and `hooks/**`, with
no `.cs` glob, so per claude/docs/rule-globs.md the rule cannot load for a .cs file. The glob change is needed
whatever else is going on. The Tests already verify loading behaviour the way rule-globs.md says to. A desktop-surface
cause on top of that is speculative, and adding a baseline run, or a desktop check by the user, is cheap to do while
implementing. The approach does not rest on an unverified assumption.

### R1-15 · minor · scope and slicing

Approvals, 'Not yet asked' block ('at every level and on every machine'); Task 15 Files 'Outside this repo' (clone at
`$HOME/.ai-framework-log`): The approval and the 15b step cover every machine, but only this machine gets the clone.
Nothing says whether `bin/dotfiles` or an init script should clone it elsewhere, or that this is out of scope. On
another machine `record` exits 2 at every plan's end. Scenario: On the second machine, every final code review reports
an `ai-log record` failure ('AI_LOG_DIR not a git clone'). Either the data silently never collects there, or an
executor adds a clone step to an init script that nothing asked for.

### R1-16 · minor · scope and slicing

Approvals, 'Not yet asked' block, versus the 2026-11-05 run 'over the remaining tasks': The run started 2026-11-05
covers Tasks 15 and 15b, yet one approval it will need is left to ask mid-run. That goes against asking in bulk up
front. Scenario: The implementing run stops between Task 15 and Task 15b to ask the commit-and-push question. The stop
could have been avoided by asking now, together with the skill-edit question above.

### R1-17 · minor · scope and slicing

Task 15, Sketch (1) versus the entry schema in Interfaces: The sketch lists 're-asked questions' and 'failed attempts'
among the data. The detailed schema drops both without saying so or saying why. 'Stops for the user' maps only partly
to `questions` and `interrupts`. Scenario: An executor or reviewer reads the sketch and adds heuristic counters for
re-asks and failed attempts, which are hard to compute from field names alone and widen the redaction surface. Or the
user later finds them missing with no record of the decision.

### R1-18 · minor · scope and slicing

Task 15b, Tests 'End to end, by the session': Task 15b's end-to-end proof is deferred to 'this plan's next final code
review'. That is the same review that commits 15b, and the session's loaded copy of `reviewing-in-rounds` predates the
edit. So the task cannot show its behaviour working when it is done, and the plan doesn't name who flips the row, or
when, if no later review comes before Task 13. Scenario: The final review commits 15b from a skill text it loaded
before the new step existed, so no entry or introspection is written. The row is flipped done anyway, or stays pending
with nothing scheduled to close it.

### R1-19 · minor · scope and slicing

Revisit · Does a real entry hold what an introspection needs?: The Revisit is a gate between Task 15 and Task 15b, but
it is not in the Implementation status table or the Order line. Nothing records its answer, or stops 15b until it is
answered. Scenario: The executor goes from 15 to 15b by the status table, skips the Revisit, and fixes `record`'s
printed numbers without the check the Revisit asks for.

### R1-20 · nit · scope and slicing

Task 16, Change (formatter bullet: `.editorconfig` and `dotnet format`): The user ruled on `paths:` coverage. Adding
.NET formatter examples to the body is a small extra nobody asked for, though it is cheap and related. Scenario: The
body grows toward its 30-line aim for an example the language-neutral 'found from its config' wording already covers.

### R1-21 · major · decisions

Approvals, 2026-11-05 bullet 1 ("no skill changes") vs Task 15 "Why one skill line doesn't contradict" and Task 15b
Files/Change (claude/skills/reviewing-in-rounds/SKILL.md): The user's recorded answer is "a script over the session
transcripts and the plans' review logs, no skill changes". Task 15b edits reviewing-in-rounds/SKILL.md anyway, and
justifies it with the plan's own reading of what the user meant. The not-yet-asked bullet covers only the commit and
push without asking, not the skill edit. The question the executor would ask: "You said no skill changes; may Task 15b
add the `ai-log record` step to reviewing-in-rounds § Completion of a code review, or should something outside the
skills trigger the script?" Scenario: An implementing-plans executor acts on recorded answers without asking. It
builds 15b and commits a skill change against a recorded user "no", or it stops mid-run with no recorded answer to act
on. Either way the decision is the user's, and the plan has settled it on the user's behalf.
Refuted: Downgraded from blocking by the verifier. Downgraded from blocking. The tension is real: Approvals line 84
records the user's answer as "no skill changes", Task 15b edits reviewing-in-rounds/SKILL.md, and nothing asks the
user about it. But the plan does not hide the edit. It argues for it in the open ("Why one skill line doesn't
contradict"). The user's own "When" decision ("the final implementing-plans step, after the commit") already needs
something in the workflow to fire the script, and the plan shows why the alternatives fail (bin/ai exec, SessionEnd
hook). It is not a forbidden write, and undoing it costs one skill line. It stays a decision that reinterprets a
recorded user answer and should be put to the user, so major, not dropped.
Fixed: Recorded the user's 2026-11-05 approval of the one-line trigger in Task 15 and § Approvals; Task 15b says why
it lives only in `reviewing-in-rounds`.

### R1-22 · major · decisions

Task 15 Change § Scope and Interfaces (`window`, `<id>`); Task 15b skill step; Task 15c sketch: The plan never says
what one entry covers when a plan has more than one final code review and commit. This plan already has several (Task
14's run, the 2026-11-02 run, the current run). The window starts at "the earliest such record across those sessions"
and ends at the commit, so each later entry re-counts the earlier runs. The start also moves as transcripts older than
30 days are deleted. A session that worked on two plans counts in full in both. The question: "Is an entry one run
(from the previous entry's commit to this one), or everything for the plan so far? And how is a session shared between
plans split?" Scenario: Task 15c sums cost and rounds per plan over time and gets double or triple counts for a plan
with several runs. The trend then rises because the window is cumulative, not because cost went up. Once schema-1
entries are pushed to the private repo, fixing this means re-deriving them, and the transcripts behind them are gone
after 30 days.
Fixed: An entry is one implementing run: window from `Base:` to the commit, open logs and un-closed findings files
only; several runs give several entries with distinct ids.

### R1-23 · major · decisions

Revisit block; Task 15 Interfaces (entry schema 1, `sessions[]`); Task 15 Spec sketch (1) "per plan, what each stage
cost and caught": The user's sketch asks for what each stage cost. Schema 1 records per session only, and the Revisit
defers the per-stage split "if wanted" until after real entries exist. The question: "Must schema 1 split tokens,
agents and time per stage (for example by `attributionSkill`: writing-plans, implementing-plans, reviewing-in-rounds),
or is per-session enough?" That is a data-format choice that 15b and 15c consume. Scenario: Task 15 ships and pushes
schema-1 entries without a per-stage split. The Revisit then wants one, but the earlier entries' transcripts are
deleted after 30 days, so they can never be backfilled. The cross-session report can't compare stages across the first
month of data, which is the question the user asked.
Refuted: Dropped by the verifier. The plan defers this on purpose, and the deferral is sound. The '## Revisit · Does a
real entry hold what an introspection needs?' stop comes right after Task 15's single real run and before Task 15b
adds the routine recording step. It names attributionSkill as the source of a per-stage split. Before that decision
only one entry exists, from a dry run plus one real record, so the scenario 'can never be backfilled for the first
month' does not happen. The entry also carries a schema version.

### R1-24 · major · decisions

Approvals, "Not yet asked" bullet; Task 15b skill step ("At every level"); Task 13 (deletes the plan): The standing
approval to commit and push to ai-framework-log "after every plan, at every level and on every machine" is recorded
only in this plan's ## Approvals. reviewing-in-rounds step 4 counts only a yes recorded in the plan being run. Task 13
then deletes this plan. Nothing says where the yes lives durably, or whether the skill step itself authorizes the
push. The question: "Where is the standing yes recorded so later plans' runs act on it: in the skill step's wording,
in global CLAUDE.md, or in each plan's Approvals?" Scenario: After Task 13, a later plan's final code review reaches
the new step. Its plan has no recorded yes, and the global rule says an approval covers only what it names. So the run
either stops to ask every time, against what the user wanted, or pushes with no approval it can point to. At customer
level, the second also runs into the global "push in any form" prohibition.
Fixed: Task 15b's skill step itself states it runs without asking, on the user's standing yes of 2026-11-05, so the
yes outlives the plan; § Approvals points to it.

### R1-25 · minor · decisions

Task 15 Change § Cost; Task 15b "record prints ... cost and tokens per session": `cost-state` is written only when a
session exits. The session that runs `record` right after the commit is the session that did the plan's work, so its
cost_usd is null or stale. The introspection is written at that moment, so it always lacks the main cost figure.
Refreshing incomplete entries is left to Task 15c's sketch. The question: "Should the introspection go ahead without
dollars, should record estimate dollars from tokens, or should a later re-record be scheduled? And if so, by what?"
Scenario: Every short introspection says the cost is unknown for the main session, so "what each stage cost" is never
answered at the plan's end. Until 15c is built, nothing re-runs record before the 30-day cleanup, and the dollar data
is lost for good.
Refuted: Downgraded from major by the verifier. Downgraded. The plan states the limitation outright: cost-state is
written at exit, and cost_complete is false. It also stores per-model token counts windowed to the plan, so dollars
can still be estimated from tokens later and the data is not lost for good. The short introspection can still judge
cost from tokens. When to refresh is already listed as something Task 15c settles. A real gap, but cheap to settle
(for example, print tokens and flag the dollars as incomplete).

### R1-26 · minor · decisions

Task 16 Change, "The rule stays under its 30-line aim": claude/rules/writing-code.md is already 30 lines.
check-md-limits counts every line of a Claude-loaded file except blank lines and headings, so about 27 count now.
Adding 11 globs one per line, plus the formatter wording, puts it near 38, over the 30 aim (under the 50 cap). The
instruction can't be met as written. The executor has to choose between going over the aim, collapsing the globs into
a brace form (whose support claude/docs/rule-globs.md doesn't confirm), or dropping languages from the user's "C# plus
the common languages". Scenario: One executor goes over the aim and reports a deviation. Another drops some globs to
meet it, and those rules then silently fail to load for Rust or PHP. That silent failure is exactly what the task
exists to fix.

### R1-27 · minor · decisions

Approvals, "Not yet asked ... to ask before Task 15b runs": The run started 2026-11-05 was asked in bulk "over the
remaining tasks", but this approval was left out and is to be asked mid-run. The global rule says to ask in bulk, up
front. The plan doesn't say whether the executor stops before 15b, or builds 15b and holds only the end-to-end step.
It also doesn't cover cloning the log repo on the user's other machines: no init script does it, so `record` exits 2
there. Scenario: The executor reaches 15b with no recorded yes and stops the unattended run partway. Or it builds the
step, and on the user's second machine every plan ends with `AI_LOG_DIR not a git clone`, because nothing in
bin/dotfiles clones the log repo.

### R1-28 · minor · decisions

Task 15b Interfaces/Change, `ai-log note <id>`: `note` rejects the customer repo's origin host, owner and name and its
top-level folder's name "when the work repo is at customer level". It takes only an id, though, and the customer entry
stores `repo: customer`, `plan` and `commit` null. The plan doesn't say how `note` finds the work repo: from the cwd,
or from a new argument? This changes the interface 15b produces. Scenario: `note` is run from the log repo's directory
or a subshell, so the cwd isn't the work repo. The customer-name check then has nothing to compare against, and an
introspection naming the customer's repo is accepted and pushed.
Refuted: Dropped by the verifier. Out of scope: an executor choice a reviewer can check in the diff. The plan already
states record is 'run in the work repo', the same session runs note right after, and only the skill step that Task 15b
itself writes consumes it. Whether note takes the work repo from the cwd or from the entry's context is an
implementation detail. The ~/.claude-customers check applies whatever the cwd.

### R1-29 · minor · decisions

Task 15 Interfaces, findings outcome words "(Fixed, Refuted, Dropped; none is open)" and "opening a finding's last
paragraph": claude/docs/review-log.md defines only `Fixed:` and `Refuted:` lines; a dropped or downgraded finding
carries `Refuted:`. Nothing defines `Dropped`, or says the outcome opens the last paragraph. The `findings` map's
`dropped` bucket therefore has no source. The question: "Is `dropped` a separate outcome, or is it folded into
`refuted`?" Scenario: The parser looks for a `Dropped` word that real findings files never contain. Every dropped
finding counts as refuted or open, so 15c's cut candidates (lenses whose findings are all refuted or dropped) are
computed from the wrong buckets.

### R1-30 · nit · decisions

Task 15b Change, "Re-running `record` keeps an existing `entries/<id>.md`": A re-run of `record` prints the
introspection instruction again, and the skill step says to "do what it prints". So a re-run, for example the 15c
refresh of incomplete costs, would also make the model write and replace the introspection, which defeats keeping the
existing one. Scenario: A cost refresh replaces the plan's original end-of-run introspection with one written weeks
later from a different session, which has none of the run's context.

### R1-31 · major · consistency

Task 15 § Interfaces (findings outcome) and § Tests › Reviews: Task 15 says it reads a finding's outcome from "the
outcome word opening a finding's last paragraph (`Fixed`, `Refuted`, `Dropped`; none is open)". The format it
consumes, claude/docs/review-log.md § The findings file, defines something else. An entry is a heading followed by one
block with no blank line, and the `Fixed:` or `Refuted:` line sits under the description. That doc defines no
`Dropped`: a dropped or downgraded finding gets `Refuted:`. And "no `Fixed:` and no `Refuted:`" means unfixed.
Scenario: An executor builds fixtures that match Task 15's wording, with the outcome word opening a separate
paragraph, and the tests pass. On real findings files written per review-log.md, the last paragraph is the whole entry
and opens with the description. Every finding is then counted `open`, and the counts of fixed, refuted and open
findings by lens are wrong. Task 15c's cut candidates ("cost with no findings or fixes to show") are built on those
wrong counts.
Fixed: Task 15 parses outcomes as `review-log.md` defines them: a `Fixed:` line, else a `Refuted:` line, else open;
the `dropped` bucket is gone, and the reviews test uses that format.

### R1-32 · major · consistency

Approvals, 2026-11-05 block ("no skill changes") vs Task 15b › Files and Change (the skill step), and the "Not yet
asked" bullet: The user answered "a script ... no skill changes". Task 15b adds a step to
`claude/skills/reviewing-in-rounds/SKILL.md`. Task 15 argues that this does not contradict the answer, but the
decision is the user's, and nothing puts it back to them. The "Not yet asked" bullet asks only about committing and
pushing to the log repo without asking each time. It does not ask about the new skill step that runs after every
plan's commit at every level. Scenario: Before Task 15b, the executor asks only the commit/push question and gets a
yes. It then edits a skill the user said would not change, on the plan's own reasoning. This goes against the global
rule that an approval covers only what it names. If the user disagrees after the step ships, every plan run since has
carried it.
Fixed: The user approved the one-line skill step on 2026-11-05; recorded in Task 15 and § Approvals in place of the
plan's own argument.

### R1-33 · major · consistency

Implementation status › Order ("15c detailed only once real plans have left entries") vs Task 13 ("After every other
task, M included"): Task 15c cannot be detailed until real plans have written entries, and only plans finished after
Task 15b write them. Task 13 has to wait for every other task, 15c included. Task 13 lists the open items it carries
into an issue (`Deferred:` lines, Task 7, Task 11) but does not mention 15c, so it gives no way to move a
still-sketched 15c out of the plan. Scenario: After 15b and M, the executor reaches Task 13 while 15c is still a
sketch waiting on entries that other plans have not produced yet. Task 13 can't start, and this plan, its findings
files and its approvals stay on `main` indefinitely. The other option is to delete the plan and lose 15c, which Task
13's issue list does not cover.
Fixed: 15c leaves this plan: the Order line, its status row and its section say Task 13's issue carries it as a
follow-up, and Task 13 runs after every task but 15c.

### R1-34 · major · consistency

Task 15b › Files and Change (the skill step "At every level"): The step makes every customer-level session run a
script that commits and pushes, to the private log repo. Task 15b's Files does not include the docs that describe what
each skill writes per level, so they are not updated. claude/docs/work-contexts.md:86-88 says `reviewing-in-rounds`
commits only after a yes and only drafts on customer work. This breaks the global constraint "Docs ship with the
change: ... claude/docs/* updated in the same task that changes behaviour". Scenario: A customer session reaches the
new step. The prose it has loaded says customer level allows no push in any form, and work-contexts.md says the skill
only drafts. The model either refuses to run `ai-log record`, so the step silently never runs on customer work, or
runs it while the docs say otherwise. Task 13 then folds the outdated description into durable docs.
Fixed: Task 15b's Files add `claude/docs/work-contexts.md`, saying the log repo is the user's own, outside the
customer's history and remote, and what leaves the machine.

### R1-35 · minor · consistency

Task 16 › Change ("The rule stays under its 30-line aim"): The claim is wrong. I checked a scratch copy of
`claude/rules/writing-code.md` with 11 path lines added, before any change to the formatter bullet.
`bin/check-md-limits` counts 38 lines and prints the advisory "keep it to 30 or fewer (hard cap 50)". The original
counts under 30. Scenario: The executor adds the eleven globs, runs the Tests' `bin/check-md-limits` and gets an
advisory that contradicts the task. It then either trims the language list the user ruled on or goes past the stated
bar without recording it as a deviation.

### R1-36 · minor · consistency

Task 15b › Interfaces and Change (`note <id>` redaction against the customer repo's origin and folder): The check that
rejects text naming the customer repo's origin host, owner or name, or its top-level folder, needs the work repo. That
information is not in the entry, which stores `repo: customer`. The interface never says `note` runs in the work repo
or how it finds it, unlike `record`, which says "run in the work repo". Scenario: `record` prints the instruction to
pipe to `ai-log note <id>`, and the model runs it from another cwd or after a `cd` into the log repo. `note` then
resolves a personal level, skips the origin/owner check, and accepts an introspection that names the customer's repo.

### R1-37 · minor · consistency

Handover › Start next session here, items 0 and 5: The handover was not updated when the plan was iterated. Item 0
still says Task 15 "is a sketch ... detail it with /writing-plans", but it has been detailed and split into 15, 15b
and 15c. Item 5 still asks to "Decide Task 7's open conflict", but the 2026-11-05 Approvals block and status row 7 say
it was ruled and `CLAUDE.md` reworded. Scenario: A resumed session starts from the handover, as the plan tells it to.
It re-runs `/writing-plans` on Task 15, or asks the user again about Task 7's conflict, which they already answered.

### R1-38 · nit · consistency

Task 15b › Files: Task 15b adds the user-facing subcommand `ai-log note`, but its Files list only
`tips/24_claude_code.md`. `README.md` § Scripts and `tips.md`'s 24 entry, which Task 15 edits for `ai-log`, are not
included. The repo convention is that the docs ship with the change. Scenario: After 15b, `README.md` describes
`ai-log` as `record` only, and nothing in the README index mentions `note`.
Refuted: Downgraded from minor by the verifier. Downgraded. The omission is real: README.md § Scripts lists
subcommands for `ai` (`issue`, `plan`, ...), so an `ai-log` line written as `record` only would need `note`. But the
plan's global constraint "Docs ship with the change", together with the `writing-tips` skill that loads for any change
to a script under bin/, already requires that update. tips.md's 24 entry lists command names only, so it needs no
change for a subcommand. A reviewer can check the README line in the diff, so what is left is a gap in the Files
list's wording.

### R1-39 · nit · consistency

Implementation status table and Order vs "Revisit · Does a real entry hold what an introspection needs?": The Revisit
section sits between Tasks 15 and 15b and feeds both of them ("Fold the answer into the numbers record prints in Task
15b"). It has no row in the status table and is not mentioned in the Order line. Scenario: An executor following the
table goes from 15 straight to 15b and never answers the Revisit question before choosing which numbers `record`
prints.

### R1-40 · nit · consistency

Approvals, "Not yet asked" bullet: The standing yes for every future plan and machine is recorded only in this plan,
which Task 13 deletes. Task 15b's skill step is the only lasting place for it, and no task says that step records the
approval or cites it. Scenario: After Task 13, a later reader of the skill step finds no record that the user approved
the automatic commit and push at every level.

### R1-41 · minor · work context

Task 15b, Change, 'The skill step' ('At every level: the entry is redacted, and the log repo is the user's own') and
Task 15, Change, 'Redaction, the bar': At customer level the step exports data derived from the client's work,
including a model-written introspection of it, to a GitHub-hosted personal repo. It does this without consulting the
customer tree's CLAUDE.md, which by § Work contexts ('their CLAUDE.md wins over this file') may forbid moving
engagement data off the client's systems. Neither task says to read the customer CLAUDE.md, or to skip or draft the
record/note at customer level when that file restricts it. Scenario: A customer's CLAUDE.md says no work data leaves
its systems. A plan finishes there, the user says the drafted commit ran, and step 7 runs `ai-log record` then `ai-log
note`. Session counts, timings and a free-text introspection of the client's work are pushed to
github.com/andrelin/ai-framework-log, against the rule that outranks the global file.
Refuted: Downgraded from major by the verifier. Downgraded. The gap is real: Task 15b's step says 'At every level: the
entry is redacted, and the log repo is the user's own' and never mentions the customer tree's CLAUDE.md, which § Work
contexts says wins. It is not major for three reasons. The user decided on 2026-11-05 that redacted copies of every
plan's data go to this private repo. The customer-tree CLAUDE.md is the user's own file, and it loads in any session
under that tree (parent-directory CLAUDE.md files load, per the plan's own § 'Should customer, company and personal be
split further?'), so the session already sees it. And the fix is one clause in the skill step: skip `record`/`note`
where the customer tree's CLAUDE.md restricts it. Nothing built has to be redone.

### R1-42 · major · work context

Task 15, Interfaces (entry fields `framework.plugins`, `skills_outside`, `agents`, `tools`) and Change, 'Redaction,
the bar': The customer-level redaction folds only project skills, custom agent types and MCP tools outside
`mcp__claude_ai_*`. Several names that can identify a customer or its internal tooling still go into every entry
unredacted: plugin names and marketplaces from installed_plugins.json, `<plugin>:<skill>` skill names, plugin agent
types, and `mcp__claude_ai_*` connector names, which come from claude.ai connectors the user named. The plan's bar is
'still free of customer details'. Installed plugins are machine-wide, so this leaks at every level, not only in
customer sessions. Scenario: The user installs a customer's internal plugin marketplace (e.g.
`acme-tools@acme-marketplace`) or adds a claude.ai custom connector named after the client. Every entry, including
those for personal plans, then writes `acme-tools` into `framework.plugins`, and customer-level entries also write
`acme-tools:deploy` into `skills`/`skills_outside` and `mcp__claude_ai_Acme_Jira__*` into `tools`. All of it is
committed and pushed to the log repo. The redaction tests plant markers only in project skills, an MCP server and a
custom agent type, so they miss this.
Fixed: At customer level every free-standing name folds to a count: plugins and marketplaces off a short allowlist,
their skills and agent types, project skills, custom agents and every MCP tool, `mcp__claude_ai_*` included; name
fields also pass the mechanical redaction at every level; tests plant these names.

### R1-43 · minor · work context

Approvals, 'Not yet asked — added 2026-11-05' bullet: The pending question asks to commit and push 'at every level'
without saying in plain words that this includes customer work, or what leaves the machine: redacted aggregates plus a
model-written introspection, in a GitHub-hosted repo. It also doesn't say that a customer's CLAUDE.md may forbid this.
The asking-questions rule requires that the user can decide from the question alone. Here the decision is the only
gate on customer-derived data leaving the client's context. Scenario: The user reads 'commit to the clone of the
private andrelin/ai-framework-log and push it, without asking each time' as plumbing for personal work and says yes.
From then on, introspections of customer engagements are pushed off-machine with no further prompt, and nobody ever
made the customer decision explicitly.
Refuted: Downgraded from major by the verifier. Downgraded. The question does say 'at every level', which includes
customer, and the user set the design themselves on 2026-11-05: redacted copies, 'Still free of customer details', in
a separate private repo. So the customer decision has been made in substance. The finding is still right under the
asking-questions rule: the question should say in plain words that this covers customer work, and that what leaves the
machine is redacted aggregates plus a model-written introspection. Rewording one bullet before it is asked fixes that,
so it is cheap to settle.

### R1-44 · minor · work context

Task 15b, Change, '`note <id>`' redaction check: The check is a whole-word match of each `~/.claude-customers` entry.
Entries can be `<host>/<owner>` pairs, whole hosts or directories (§ Work contexts), so a `<host>/<owner>` entry only
matches when that exact string appears. The customer's owner name or host on its own passes. Also, the origin host,
owner and name are checked only when the current work repo is at customer level, so a note written for a company plan
that mentions a customer is checked only against the raw entries. Scenario: `~/.claude-customers` lists
`git.acme.example/platform`. The introspection says 'the platform team's acme deploy tool slowed review'. Neither
`acme` nor `git.acme.example` is a whole-word match for the entry, so `note` accepts the text and pushes it.

### R1-45 · minor · work context

Task 15b, Change, 'record prints' instruction ('no customer names, hostnames, paths, code or quotes from the work'):
For a customer's internal tooling, project codenames, class or service names and similar text, prose in the printed
instruction is the only control: `note`'s mechanical check catches only absolute paths and customer identifiers. The
test suite proves only the mechanical rejections, so nothing verifies the free-text bar the user set ('free of
customer details'). Scenario: The model writes 'Cut candidates: the OrderSyncService integration tests took 3 rounds
(R2-4)'. No path or listed customer name appears, so `note` accepts it, and a client's internal service name lands in
the log repo.

### R1-46 · nit · work context

Task 15, Files (tip in `tips/24_claude_code.md`, `README.md` § Scripts) and Interfaces (exit-2 message): The public
dotfiles repo will name the private repo `andrelin/ai-framework-log` in a tip, the README and the script's error
message. This names no customer and no secret, but it publishes that the private log exists. A placeholder such as
`<your log repo>` in the tracked text, with the real name in `AI_LOG_DIR` docs only, would avoid that if the user
prefers. Scenario: A reader of the public repo learns the private repo's name and what it holds. Nothing more leaks,
since the repo stays private.
Refuted: Dropped by the verifier. Dropped: no requirement is violated. The personal-public bar (§ Work contexts,
work-contexts.md) excludes customer names, hostnames, internal tooling and secrets. The name of the user's own private
repo is none of these, and the finding grants that nothing leaks because the repo stays private. The plan file, which
is itself tracked in this public repo, names `andrelin/ai-framework-log` anyway, and the finding offers only an
optional preference.

## Round 2

### R2-1 · major · grounding

Task 15 § Change, "Cost, only for sessions inside the window", and § What the transcripts hold (cost-state): Under the
stated rule, dollars can never be recorded for the session that drives a plan. Three things combine. (1) `cost-state`
is written when the session exits, which is after the commit that closes the window, so it falls outside the window.
Task 15c's refresh, re-running `record` later, cannot fix this, because the window still ends at the commit. (2) The
rule requires that no record follows the last `cost-state`. In every ended transcript I checked (443dfffa, 6328cccc,
87b5de25, 775cc01c), the last `cost-state` is followed by `last-prompt` and `file-history-snapshot` records. (3)
`cost-state` has no `timestamp` field, only `startTime`, so whether it 'falls inside the window' cannot be read from
the record itself. The plan also asserts unverified that `cost-state` covers the whole session. Its `startTime` and
`totalDuration` (33.8 h for 775cc01c, a session resumed across 11-02, 11-03 and 11-05) suggest the figure is per
process, not cumulative across resumes. The simpler, checkable route is to price the windowed tokens from a per-model
price table, marked as an estimate. Alternatively, drop dollars from the entry and say so. Scenario: This plan's own
run: the driving session 775cc01c started 2026-11-02T11:18Z, before Base cdf0a77 (committed 2026-11-05 16:28 +01:00).
Its first record is before the window, so `cost_usd` is null and `cost_complete` false. Every later re-run of `record`
also gives null, because the exit-time `cost-state` comes after the commit. The user's requirement 'what each stage
cost' in dollars is never met for the main run. Task 15c's cost trend has no data points, and the real-data test's
'ended session wholly inside the window' may not exist.
Fixed: Task 15 § Change, Cost: dollars are now an estimate, the windowed tokens priced per model from a price table in
the script, marked `cost_estimated`; `cost-state` only cross-checks the table in the real-data test, and
`cost_complete` is gone, as is Task 15c's refresh, replaced by re-pricing stored tokens.

### R2-2 · major · grounding

Task 15 § Interfaces (exit 1 when the plan file is missing or has no `Base:` line), and Task 15b § Change, the skill
step and the end-to-end test: `record` needs the plan file on disk, with its `Base:` line, open review logs and
findings files. `writing-plans` § Plans are temporary says that when the last task lands, the plan and its review
files are deleted in that same change, and Task 13 does exactly that for this plan. At company and customer level,
plans are excluded through `info/exclude` and never tracked, so nothing can be recovered from git either. The plan
does not say how `record` gets `Base:` and the review data on a plan's final run. One option is to have the step read
them before the deleting commit. Another is to fall back to `<commit>^:<plan>` where the plan is tracked. Scenario: A
plan's last task folds the plan into durable docs and deletes it. The final code review commits that change. The new
step then runs `ai-log record plan-x.md`, which exits 1 because the plan file is missing. That is the 'after every
plan' introspection the user asked for, and it fails on exactly the run that finishes the plan; only the 'failure goes
in the report' path remains. If this plan's remaining run builds Tasks 15b and 13 together, Task 15b's end-to-end test
('this plan's next final code review runs the step') fails the same way.
Fixed: Task 15 gains `ai-log record --snapshot <plan>`, writing the parsed review counts and keys to the untracked
`$AI_LOG_DIR/snapshots/<plan_key>.json`; `record` reads the plan, else that snapshot, and identifies the plan by
`plan_key` (origin URL and basename), not `Base:`. Task 15b's one skill step now sits before the commit: snapshot now,
`record` once the commit has run.

### R2-3 · major · grounding

Task 15 § Change, "Scope, one entry per implementing run" (the window starts at the committer time of the `Base:`
commit): The window starts at the time the Base commit was committed, not when the run started. That boundary does not
match the stages. The issue and plan stages (writing the issue, writing the plan, plan review rounds) normally happen
before `implementing-plans` writes `Base:`, and the same session often continues into implementation. Their cost is
therefore out of the window, yet `reviews[]` still counts the plan kind's open review log and findings. Which stages
fall inside also depends on how old HEAD is. If `main` has not moved for weeks, the window reaches back over the
planning sessions. If someone committed an hour before the run, it does not. Entries are then not comparable, and Task
15c's per-plan trends rest on that comparison. The user's spec asks for 'what each stage cost and caught'. Scenario:
Plan A is drafted and reviewed over three rounds on a repo whose last commit is a month old: the plan-stage tokens
fall inside A's window. Plan B is drafted the same way, but a commit lands an hour before its run: B's plan-stage
tokens are excluded. Both entries show plan-review majors, while their costs measure different things. A Task 15c cut
candidate such as 'plan review costs X with no findings' is then an artifact of the window, not a property of the
framework.
Fixed: Task 15 § Change, Scope: the window no longer uses `Base:`; an entry runs from the previous entry's end for the
same `plan_key` (or the plan's first appearance) to the commit, and a Stages bullet splits it into issue, plan, plan
review, implement and code review by the skills invoked, so every stage counts and entries compare.

### R2-4 · minor · grounding

Task 15 § Change, Scope (candidates are sessions whose `cwd` is under the work repo): Headless `claude -p` runs that a
plan's session launches run in a `mktemp -d`, and some run in a throwaway `HOME`. Those runs are left out of the
entry. Their transcripts sit under another project directory, and the throwaway-`HOME` ones are not under
`$AI_LOG_PROJECTS` at all. The plan's handover shows these runs are a large share of spend: a 58-case battery at about
$39, against about $11 for an end-to-end run. No requirement or decision excludes them, and the entry gives no sign
that they are missing. Scenario: A plan whose tasks are mostly scenario-tested skills (Tasks 5, 8, 9, 14 and 15b here)
records the driving session's tokens and leaves out every headless battery it launched. The cut-candidate analysis
then sees scenario testing as nearly free and cannot flag it, although it is the costliest stage.
Refuted: Downgraded from major by the verifier. Downgraded. The gap is real: `~/.claude/projects` holds
`-private-var-folders-...-T-tmp-*` project dirs, and the plan's handover (line 190-191) reports headless batteries of
about $39 against about $11 for an end-to-end run. The approach does not rest on including them, though, and no
structure has to change. The executor can count `claude -p` launches in Bash `tool_use` or add a known-gap warning,
and either is additive and cheap to settle while implementing. Transcripts written under a throwaway HOME are gone
with that HOME anyway, so no later decision can recover them.

### R2-5 · minor · grounding

§ Approvals, block 'Added 2026-11-05 by the iteration that detailed Task 15', and Task 15b § Change, the skill step
and the customer model pass: The standing yes names only '`ai-log record` and `ai-log note` commit ... and push it'.
At customer level, the step pushes with `ai-log publish <id>`, and it also deletes the held entry files when the
customer's `CLAUDE.md` forbids data leaving. Neither action is named in the approval. The global rule is that an
approval covers what it names, never its neighbour, and the skill step says to 'do what it prints, without asking'.
The new `work-contexts.md` text also attributes the pushes to that yes. This is the one push that sends
customer-session text off the machine, so it is the action that most needs an explicit approval. Scenario: A
customer-level session reaches the step. `record` holds the entry and prints the model-pass instructions, ending in
`ai-log publish <id>`. The session pushes the redacted customer prompts to GitHub without asking, and no recorded yes
names `publish`. Alternatively, a careful session stops to ask on every customer plan, contradicting 'without asking'.
Fix: add `publish`, and deleting held entries, to the approval bullet and to the skill line's wording.
Refuted: Downgraded from major by the verifier. Downgraded. The wording gap is real: `publish` and deleting held files
are not named. However, the same approval says 'at every level', and at customer level `record` commits nothing, so
only `publish` can carry out that yes. The adjacent bullet also approves storing prompts and questions 'at every
level'. The user has therefore consented to the customer-level push itself, which means this is not an unapproved
forbidden write. It is a one-word fix to the approval bullet and the skill line.
Fixed: § Approvals' bullet now names every write the step makes, `record` (with `--snapshot`), `note`, `publish` and
deleting a held entry, marked as restating the user's yes of 2026-11-05; Task 15b's skill line says the yes covers
every write `ai-log` makes.

### R2-6 · minor · grounding

Task 15b § Files (only `claude/docs/work-contexts.md` changes); the global `claude/CLAUDE.md` § Work contexts: The
global `CLAUDE.md` lists `push` in any form as forbidden 'where history and the remote are the user's (customer)', and
it does not mention the log repo. Task 15b qualifies this only in `work-contexts.md`, a doc the model reads on demand.
A customer-level session that has only the always-loaded text may treat the log push as forbidden. The guard, which
resolves each command by its own directory, would allow it. Scenario: At customer level the session reads 'push in any
form ... forbidden' and declines to run `ai-log publish`, or drafts it for the user. Every customer-plan entry then
stays held and is never published, so customer work is missing from the data, with no error.

### R2-7 · minor · grounding

Task 16 § Spec and § Tests: The user's report was that the rule did not load in a desktop session. The test checks
loading only with headless `claude -p` from the CLI. If the desktop app does not apply user-level path-scoped rules
the same way, the added globs pass the test and the reported problem remains. The test should repeat the 'which rules
loaded' check in a desktop session, or the task should record that this was not checked. Separately, 'C# plus the
common languages' leaves out files a .NET or JS/C++ project edits often: `.razor`, `.cshtml` and `.fs`/`.fsx` (F#),
`.mjs`/`.cjs`/`.mts`, and `.hpp`/`.cc`. Scenario: The headless check names `writing-code.md` for the `.cs` file, and
Task 16 is marked done. The user reopens a `.cs` file in the desktop app, the rule still does not load, and the bug
they reported is unfixed. Likewise, editing a Blazor `.razor` or an `.mjs` file still loads no rule.
Refuted: Dropped by the verifier. Out of scope. Whether to add a desktop-session check is a choice of exact test
cases. Which further extensions count as 'common languages' (`.razor`, `.mjs` and so on) is an executor choice a
reviewer can check in the diff. The finding also has no supporting evidence. `claude/rules/writing-code.md`'s `paths:`
plainly lacks `/*.cs`, which fully explains the reported miss, and nothing suggests the desktop app matches rule globs
differently from the CLI engine the headless test exercises.

### R2-8 · minor · grounding

§ Approvals ('on every machine') and Task 15 § Interfaces (exit 2 when `AI_LOG_DIR` is not a git clone): The approval
and the skill step expect recording on every machine, but nothing creates the `$HOME/.ai-framework-log` clone.
`bin/dotfiles` and its init scripts are not in Task 15's or 15b's Files. On any machine without the clone, every
plan's step exits 2, and the 'failure goes in the report' path lets the entry be lost. Recovery depends on the
transcripts surviving `cleanupPeriodDays`, and on the plan file still existing. Scenario: The user's second machine
runs a plan to completion. `ai-log record` exits 2, naming `gh repo clone`, and the session reports it and moves on.
The plan is deleted in its last change, so a later re-run after cloning also fails (see the plan-file finding), and
that run's data is lost.

### R2-9 · major · scope and slicing

Task 15 § Tests, last bullet ('Real data, last, by the session'), with § Implementation status 'Base: cdf0a77…': Task
15's only check against real data can't run while Task 15 is being built. This run commits nothing until its final
code review, so HEAD is still the Base commit (cdf0a77, verified: `git rev-parse HEAD` = Base, committer time
2026-11-05T16:28:25+01:00). `ai-log record --dry-run plan-ai-framework.md` defaults `<commit>` to HEAD, so its window
runs from Base's time to Base's time and holds no sessions. That is exit 1, 'no session in scope'. The follow-on 'real
`record`, its entry pushed' fails the same way. Scenario: The executor reaches the last test of Task 15, runs the dry
run, gets exit 1 and has nothing to check the token-versus-cost-state bound or the redaction grep against. They either
stop or fake a window (a `<commit>` ahead of HEAD doesn't exist). So the task's main real-world verification is either
skipped or invented. Fix: name what the check runs on, for example an earlier finished run such as the Task 14 commit
with its own Base, or a `--until now` window, or move the check to after this run's commit.
Fixed: Task 15's real-data test now runs `--dry-run` while `HEAD` is still `Base:`; with nothing committed since the
start the window ends now, so it holds this plan's sessions. The first real `record` moved to Task 15b's end to end.

### R2-10 · minor · scope and slicing

'Revisit · Does a real entry hold what an introspection needs?' (between Task 15 and 15b), and the order of Task 15:
The riskiest assumption comes last. The assumption is that per-session aggregates, windowed by the Base commit's time
and scoped by sessions that name the plan, hold what an introspection and a cut decision need. It is checked only
after Task 15 has built the whole schema-1 entry: cost windowing, review and findings parsing, framework
classification, the full redaction, customer folding, `publish` and the log-repo git. A cheap real-data probe (a jq
pass, or a personal-level `record` with no redaction or customer path) would test it before the rest is built on it.
The Revisit also has no row in the status table, no owner (executor or user) and no stop condition. An
`implementing-plans` executor can't tell whether it is a step to run, a stop for the user, or prose. Scenario: The
real run shows that sessions aren't stages, or that the Base-time window takes in plan-writing and plan-review
sessions from before the run, or that the counts can't tell a stage that earns its cost from one that doesn't. Schema
1, its tests and the customer machinery then all change at once, and entries already pushed to the private repo carry
the old shape. Or the executor skips the Revisit, and 15b fixes the printed numbers without the answer.
Refuted: Downgraded from major by the verifier. Downgraded. The 'no owner or stop condition' half is refuted. `##
Revisit` is a construct the plan defines: Task 9's `implementing-plans` 'stop[s] for an iteration at a `## Revisit`
heading' (plan lines 372 and 2926, with toy-run tests at 2937 and 2948). So the executor knows it is a stop for the
user, and no status row is needed. The ordering point stands but is cheap. Schema 1 is versioned, and the only entry
pushed before the Revisit is this one real run. The printed numbers are explicitly deferred to 15b, so changing the
aggregates after the Revisit is not costly to reverse.

### R2-11 · minor · scope and slicing

Task 15b § Tests, 'The model pass, by the session', and the 2026-11-05 decision to store customer prompts (Task 15
'What text'): Storing customer prompts and questions rests on one unverified assumption: that a session finds every
customer term it knows and puts it in the terms file. That is tested last, in Task 15b's headless scenario. Task 15
first builds the held-entry, `terms_pass`, `publish` and folding machinery around that assumption. If the scenario
fails (the session misses `Marta Kestrel`), the design of storing customer text after a model pass has to change after
it is built. Scenario: Task 15 ships `publish`, held entries, and `terms_pass` in schema 1 with their tests. Task
15b's headless run then publishes without one invented term. The remedy is to stop storing prose at customer level, or
to require the user to confirm, and Task 15's customer design and tests are redone. Running the headless model-pass
scenario as a spike before Task 15's customer half would surface this first.
Refuted: Downgraded from major by the verifier. Downgraded. The held entry, `terms_pass`, `publish` and `--terms` gate
are needed whether the model pass works well or not. They are what stops an un-passed customer entry from leaving the
machine, and their mechanical tests stand on their own. If 15b's headless scenario misses a term, the likely fixes are
a stronger instruction in what `record` prints, or dropping `prompts`/`asked` at customer level. Both are cheap, and
neither means rebuilding Task 15. The user also ruled on 2026-11-05 that the session 'should be able to figure that
out', so storing the text is a user decision, not an unverified design premise.

### R2-12 · minor · scope and slicing

Task 15 as a whole (§ Interfaces, § Change, § Tests): Task 15 is one slice holding about ten separable concerns:
transcript scoping and windowing, token and cost aggregation, review-log and findings parsing, framework and plugin
classification, mechanical redaction of seven kinds, customer-level name folding, the held entry with `publish`,
`--terms`, log-repo commit and push, and the shims interaction. A personal-level `record` without the customer path
would run end to end and could be learned from on its own. The customer half could follow as its own task alongside
15b's model pass. Scenario: An executor builds the whole of Task 15 before anything runs on real data. Problems in the
scoping rule, or in what the numbers show, turn up only after redaction and customer folding have been written against
fields that then change. One code review also has to judge the whole diff.

### R2-13 · minor · scope and slicing

2026-11-05 Approvals block ('ai-log record and ai-log note commit … and push it') vs Task 15 `ai-log publish` and the
Task 15b skill step: The standing yes names `ai-log record` and `ai-log note`. At customer level the push is made by
`ai-log publish`, which the approval doesn't name. The skill line says the yes 'covers its commits and pushes', and
the global rule says an approval covers only what it names. Scenario: At customer level, after the model pass, a
session sticking to 'an approval covers what it names' stops to ask before `ai-log publish`. That breaks the 'without
asking' step. Or a reviewer later flags the push as unapproved. Naming `publish` in the approval bullet, and in the
skill line, settles it.

### R2-14 · minor · scope and slicing

Task 15 § Files ('Outside this repo … cloned to $HOME/.ai-framework-log') and the approval 'on every machine': The
step is to run after every plan on every machine, but only one machine gets the clone. Nothing says whether
`bin/dotfiles` or an init script should clone it elsewhere, or that this is deliberately left out. On a machine
without the clone, `record` exits 2 and the skill step only reports the failure. Scenario: On the user's second
machine every plan's step exits 2. The data the cross-session report needs goes missing there, and nobody notices
beyond a line in each report. Alternatively an executor adds a clone step to an init script nobody asked for. State
the out-of-scope (a by-hand clone per machine) or include it.

### R2-15 · nit · scope and slicing

Task 15 Sketch and the entry schema (§ Interfaces): The sketch lists 're-asked questions' and 'failed attempts' among
the data, but the entry schema has no field for either, and no line says they were dropped or deferred. Scenario: An
executor tries to derive 're-asked' or 'failed attempts' from the transcripts and adds fields nothing specifies,
growing the task. Or a reviewer flags their absence as a missed requirement. Put a line under the decisions, or in
Task 15c's sketch, saying they are left out and why.
Refuted: Downgraded from minor by the verifier. Downgraded. The detailed § Interfaces is the binding spec for the
executor, and the user's quoted spec doesn't name 're-asked questions' or 'failed attempts'. Only the plan's own early
Sketch paragraph does. The stored `asked[]` and `prompts[]` also let 15c derive re-asking later, so an executor
following Interfaces won't grow the task. A line recording that they were dropped is a wording fix.

### R2-16 · minor · scope and slicing

Task 15 § Change, 'Scope, one entry per implementing run': Nothing says whether runs from before `ai-log` existed get
recorded. Earlier runs of this plan, such as the Task 14 commit and the 2026-11-02 run, are still in the 30-day
transcripts. An executor may reach for a backfill, and the Base-time window (Base can be an older commit) also takes
in planning and plan-review sessions that name the plan. Whether those count as part of 'the run' isn't said.
Scenario: The executor spends effort backfilling, or a reviewer disputes whether plan-review sessions belong in an
implementing run's cost. Stating both decisions, no backfill and planning sessions in or out, takes a line.

### R2-17 · minor · scope and slicing

Task 15b § Tests, 'End to end, by the session': Task 15b's end-to-end proof runs only at this plan's final code
review, after every task (16 and M included), so 15b can't be judged done when it is built. Its status row then stays
pending, or gets flipped on unit tests alone. Scenario: The executor marks 15b ✅ DONE on the unit tests, and if the
real step later fails, Task 13 deletes the plan straight after. Or the executor leaves 15b open until the final
review, which the `implementing-plans` flow may treat as an unfinished task. Say which way it goes, for example DONE
on unit and headless tests with the end-to-end check owned by the final code review.

### R2-18 · nit · scope and slicing

Task 16 § Tests: The cause isn't shown before the fix. No baseline run confirms that `writing-code.md` fails to load
for a `.cs` file today, so the test can't fail for the reported reason. The cause may instead be desktop-session
behaviour, which the headless CLI test doesn't exercise. Scenario: The headless run after the change names
`writing-code.md` for `.cs`, but the user's desktop session still doesn't load it, because the real cause was
elsewhere. Run the same headless check on the unchanged rule first and record that it fails.
Refuted: Downgraded from minor by the verifier. Downgraded. The cause is visible without a run:
`claude/rules/writing-code.md`'s `paths:` lists kt, java, ts, tsx, js, jsx, py, sh, zsh, kts, bin/ and hooks/, with no
`*.cs`, and `rule-globs.md` documents that an unmatched glob fails silently. Whether to add a pre-change baseline run
is a test-case choice, which the out-of-scope line covers. The desktop-versus-headless worry is speculative and has no
evidence behind it.

### R2-19 · nit · scope and slicing

Task 16 § Change ('add `.editorconfig` and `dotnet format` to the formatter bullet'): The formatter-example addition
and `/*.gradle` go beyond the report (the rule not loading for `.cs`). They are cheap and arguably part of 'C# plus
the common languages', but nothing asked for them. Scenario: Small scope creep in a rule that is loaded whole.
Acceptable if kept within the 30-line aim the task already states.

### R2-20 · major · decisions

Task 15 § Tests, 'Real data, last, by the session' (plan line ~3634) with § Implementation status 'Base: cdf0a77…':
The real-data step runs `ai-log record --dry-run plan-ai-framework.md` with `<commit>` defaulting to `HEAD`, but this
run commits only after its final code review. Until then `HEAD` is the `Base:` commit cdf0a77 itself, so the window
runs from 2026-11-05T16:28:25 to the same instant. The executor has to decide which commit and window the real-data
check uses: an earlier run's commit with its old `Base:` (which this plan no longer holds), a temporary commit, or
moving the check to after the final commit. Scenario: The executor reaches the last Task 15 test. The window has zero
length, so no session is in scope, `record` exits 1 by its own interface, and neither the token-versus-`cost-state`
check nor the 'real record, its entry pushed' step can run as written.
Fixed: With R2-9: the window end is `<commit>`'s time when given or `HEAD` is newer than the start, else now for
`--dry-run`; the real-data check runs on that window and pushes nothing.

### R2-21 · minor · decisions

Task 15b § Tests, 'The model pass, by the session' (line ~3701): The scenario sets up 'a work repo with a fixture plan
and commit', then runs a headless session that is told to run the step. Under Task 15's scope rule, only records
between the `Base:` commit's time and `<commit>`'s committer time count, and this session runs after the fixture
commit. Its prompts naming Bluefin and Marta Kestrel are therefore out of the window. The plan also doesn't say
whether the throwaway `HOME` holds the real `claude/` config (global `CLAUDE.md`, skills, hooks, shims) or only a
`~/.claude-customers` file. These two readings build different tests: one tests the printed instruction alone, the
other tests the real skill under the customer guard. Scenario: The executor builds it as written. `record` finds no
session in scope, exits 1, and nothing is held or published, so the test fails for a reason unrelated to the model
pass. Or the executor moves the commit inside the session without saying so, and the test no longer matches the plan.
Refuted: Downgraded from major by the verifier. Downgraded. The window problem is real: the fixture commit comes
before the headless session, and the window ends at the commit, so the session's prompts fall outside it. But the fix
is cheap and visible in the diff. The session can make the commit after its prompts, or the fixture can put `Base:`
before the prompts and the commit after them, and that still matches 'a work repo with a fixture plan and commit …
told to run the step'. Whether the throwaway HOME holds the real skill is a detail of test construction, which is out
of scope. No costly or wrong build results.

### R2-22 · minor · decisions

§ Approvals, 2026-11-05 'Added … by the iteration that detailed Task 15' bullet (lines 96-98) vs Task 15 interface
`ai-log publish` and Task 15b skill step: The standing yes names only `ai-log record` and `ai-log note` as committing
and pushing. At customer level neither of them pushes: only `ai-log publish` does. The global rule says 'An approval
covers what it names — never its neighbour', and the global customer row forbids `push` in any form. Task 15b's skill
line nonetheless says the yes 'covers its commits and pushes … at every level'. The executor's question: does the
recorded yes cover `publish` at customer level, or must that be asked again? The answer is the user's. Scenario: At
customer level a session following the skill runs `ai-log publish` with no recorded approval naming it, which is a
push the approvals rule does not cover. Alternatively, a careful session stops to ask after every customer plan, which
defeats the 'without asking each time' the user granted.
Refuted: Downgraded from major by the verifier. Downgraded. The recorded yes is to commits and pushes to the private
log repo 'after every plan, at every level', and customer is named explicitly. At customer level the only way that
push can happen is `publish`, so `publish` is the same action under a command name the approval was written before.
The global 'push in any form' row covers 'where history and the remote are the user's' (the customer repo). The log
repo is the user's own, and the guard resolves it as personal. The 15b skill line states that coverage. What remains
is a wording gap: the approval bullet should name `publish` so a careful session doesn't stop to ask. That is cheap to
fix.

### R2-23 · major · decisions

Task 15 Interfaces `ai-log publish` / `terms_pass`; Task 15b Interfaces `ai-log note` and § Change 'Re-running
`record` keeps an existing `entries/<id>.md`': `publish` refuses only an entry whose JSON `terms_pass` is false, and
that flag is set by `record --terms`. Nothing says whether `note` records its own terms flag, or whether `publish`
checks that the `.md` was written with `--terms`. `record` prints the introspection instruction ('pipe it to
`ai-log note <id>`') at every level, and a re-run of `record` keeps an existing `.md` unredacted. So which file does
`terms_pass` gate, and is that a field the entry format must carry? It is a format decision, and costly once entries
exist. Scenario: At customer level the session follows the generic instruction first and pipes the introspection to
`note` without `--terms`. It then re-runs `record --terms`, which sets `terms_pass` true and keeps the old `.md`.
`publish` then pushes an introspection that names Bluefin to GitHub.
Fixed: `note` now sets the entry's `note_terms_pass`, refuses without `--terms` at customer level, and `publish`
refuses at every level unless the `.md` exists and both flags are true; a `record --terms` re-run re-redacts a kept
`.md`.

### R2-24 · minor · decisions

Task 15 § Interfaces / Change 'Scope, one entry per implementing run' and Tests 'Two runs' (fixture 'two `Base:` and
two commits'): The window starts at the plan's `Base:` line, but the plan never says what happens to that line between
runs. `implementing-plans` stops and asks when a `Base:` exists with no branch, and this plan replaced its earlier
`Base:` in place. The 'Two runs' test, however, speaks of 'two `Base:`' in one fixture plan. The executor's questions:
does a plan hold one `Base:` (replaced each run) or one per run? If several, which one does `record` pick for a given
`<commit>`? Scenario: One executor builds `record` to read the single `Base:` line. Recording run 1 after run 2 has
started then uses run 2's `Base:`, giving an empty or wrong window. Another executor builds a multi-`Base:` lookup
that `implementing-plans` never produces. The test fixture fits only one of the two.
Refuted: Downgraded from major by the verifier. Downgraded. Tasks 5 and 9 define a single `Base:` line: written at a
fresh start, kept on resume. The natural reading of 'two `Base:` and two commits' is that the one line is rewritten
between the two runs, and a single-line reader fits that. `record` runs right after its own commit, in the same
session, so 'run 1 recorded after run 2 started' is an edge case. Reading the plan at `<commit>` (git show) would also
settle it, and that choice shows in the diff. It is cheap to settle while implementing.

### R2-25 · major · decisions

Task 15 § Change 'Scope' (window from the `Base:` commit's committer time): The approach assumes the `Base:` commit's
committer time is close to when the run started. `Base:` is `HEAD` when `implementing-plans` starts, and that commit
can be days older than the run. So the window also takes in planning and plan-review sessions, and any earlier session
in the repo that names the plan. It also takes in the previous run's after-commit introspection session, because that
session's `ai-log record <plan>` names the plan, and that run's commit becomes the next run's `Base:`. Whether an
'implementing run' entry should include the plan stage is a question about the data format Task 15c consumes. It is
not settled. Scenario: main was last committed on Monday, and the plan is written and reviewed Tuesday through
Thursday. Then implementing starts. The entry's tokens, dollars and prompts include three days of planning sessions,
attributed to the implementing run. Cross-session trends in 15c then compare unlike quantities.
Fixed: With R2-3: planning and plan-review sessions are now part of the entry, split into their own stages, and the
window starts at the plan's previous entry, not at a commit's time, so the previous run's after-commit tail lands
once, in the next entry.

### R2-26 · minor · decisions

§ Revisit · Does a real entry hold what an introspection needs? (lines 3640-3644): The Revisit says a per-stage split
is added 'if … wanted' and 'comes from `attributionSkill`'. It doesn't say who decides, and the split would change the
entry format (`"schema": 1`) that Task 15 has already pushed to the private repo in its real run, and that Task 15c
reads. The executor's question: is a per-stage split wanted, and if so, does it go into schema 1 before the first real
entry is pushed, or does it bump the schema afterwards? Scenario: The executor judges the split unwanted and ships
schema 1. Later the user wants per-stage cost, and every stored entry lacks it with no way to recompute, because
transcripts are deleted after 30 days. Or the executor adds it unasked, and the schema changes between the real entry
and 15b.
Refuted: Downgraded from major by the verifier. Downgraded. The Revisit is an explicit checkpoint that sits after Task
15's real run, and its answer is folded into 15b and 15c, so the decision is deliberately deferred to a point where
the session can ask the user. Before that decision only one real entry exists. A later additive field or schema bump
costs little, and 15c already plans to refresh entries while their transcripts are still on disk. Real, but cheap.

### R2-27 · minor · decisions

Task 15b § Files, the `claude/docs/work-contexts.md` change, vs the existing lines 85-88 of that doc and global
`CLAUDE.md` § Work contexts: The task adds a paragraph saying `reviewing-in-rounds` commits and pushes to the log repo
at every level. It leaves in place 'At every level, the workflow skills never commit on their own', the section's own
premise 'An approval covers one action, not a policy … Ask again, every time', and the global customer row 'push in
any form' forbidden. The executor has to decide between rewording those lines and only appending an exception. The two
choices leave different text for future sessions to read. Scenario: An appended exception sits under a heading and a
sentence that contradict it. A later session at customer level reads the global file's 'push in any form' and the
'never commit on their own' line, and declines to run the log step, or asks every time.
Refuted: Dropped by the verifier. Out of scope. 15b says the § *An approval covers one action* section 'gains' the
paragraph. Whether to reword the adjacent 'never commit on their own' lines or append an exception is a drafting
choice the executor makes and a reviewer can check in the diff. The global customer row is scoped to 'where history
and the remote are the user's', meaning the customer repo. The log repo is not that, and the guard resolves it as
personal, so the global file is not contradicted.

### R2-28 · minor · decisions

Task 15b § Change, 'The skill step, after step 6 (the commit ran)': At customer level the commit is drafted for the
user, and step 6 waits for 'the user says it ran'. Nothing says what happens when the user runs the drafted commit
after the session has ended, or never confirms it. Is the record then skipped (contradicting the spec 'after every
plan'), or does the report tell the user to run `ai-log record` by hand? Scenario: A customer plan ends with a drafted
commit, and the user runs it in a terminal an hour later. No entry is ever recorded for that plan, and nothing says
so.

### R2-29 · minor · decisions

Task 15 § Change, 'Redaction, mechanical' — 'the names of its folder and the folders above it up to `$HOME`': Folder
names above the repo are often generic words (`code`, `src`, `work`, `projects`, `git`). Matched case-insensitively as
whole words at every level, they replace those words wherever they appear in the stored prompts and questions. Should
generic folder names be exempt, as the host labels `git`/`www`/`github` are? It is cheap to settle but affects how
readable every entry is. Scenario: The work repo is at `~/code/app`. The prompt 'write the code for the parser' is
stored as 'write the [repo] for the parser' in every entry from that machine.

### R2-30 · minor · decisions

Task 15 § Change, 'hostnames (dotted names whose last label is a TLD, never a file name such as `SKILL.md`)': `.md`,
`.sh`, `.py`, `.rs`, `.io` and `.ai` are all real TLDs, so 'last label is a TLD' and 'never a file name' conflict, and
the plan doesn't say how to tell them apart: an extension denylist, a TLD allowlist, or a known-hosts rule. The two
readings redact different text. Scenario: An executor with the full IANA list redacts `test_ai_log.sh` and `SKILL.md`,
which breaks the test. One with a short TLD allowlist lets `build.acme.io` through unredacted at personal level.
Refuted: Dropped by the verifier. Out of scope. The plan states the requirement: hostnames are redacted and file names
such as `SKILL.md` survive, and a test asserts the `SKILL.md` case. How to tell a hostname from a file name (an
extension denylist, a TLD allowlist) is an edge-case and implementation choice the executor makes and a reviewer can
check. At customer level, hosts from remotes and `~/.claude-customers` are redacted by their own rule anyway.

### R2-31 · minor · decisions

Task 16 § Change, 'The rule stays under its 30-line aim': `bin/check-md-limits` counts front matter lines. The rule
already sits at about 26 counted lines, and adding 11 glob lines one per line ('as the list has them') plus the
formatter wording puts it at about 37, over the 30-line aim. The two instructions can't both hold. The executor must
choose: break the one-per-line form (does `paths:` accept brace globs?), cut body text, or accept going over the aim.
Scenario: The executor follows 'one per line' and `check-md-limits` warns that the aim is exceeded, contradicting the
task's own claim. Or the executor compacts with a brace glob that the harness may not expand, and the rule silently
fails to load, which is the very failure Task 16 fixes.

### R2-32 · minor · decisions

Task 16 § Spec / Tests: The user's report concerns a desktop session, but the test runs headless `claude -p`. The
assumption is that the missing `.cs` glob was the whole cause, and that the desktop app loads path-scoped rules on
file reads the same way the CLI does. Neither is checked. Scenario: The CLI test passes and the task is marked done,
but in the desktop app a `.cs` file still doesn't load the rule, so the user's reported problem remains.
Refuted: Dropped by the verifier. Refuted. The rule's `paths:` (read in the repo) has no `.cs` pattern, so the missing
glob is provably a cause, whatever else may be at play. The user's ruling of 2026-11-05 defines the task as covering
C# plus the common languages, and the test checks that requirement. The desktop app runs the same Claude Code engine.
The finding gives no concrete reason it would load path-scoped rules differently, so this is speculation, not a
failure scenario.

### R2-33 · nit · decisions

Task 16 § Change, the glob list: 'The common languages' omits `.mjs`/`.cjs`/`.mts`/`.cts`, `.cc`/`.hpp`, `.ps1`,
`.dart` and `.sql`, and the `.editorconfig`/`dotnet format` addition puts a command among examples that are otherwise
config files. Scenario: A `.mjs` or `.hpp` file is edited and the rule doesn't load, the same silent miss Task 16 sets
out to fix.

### R2-34 · major · consistency

Task 15 § Tests, 'Real data, last, by the session' (with Approvals 2026-11-05 'committed after the final code review'
and Base: cdf0a77): Task 15's real-data run can't find any session. The run commits nothing until the final code
review, so while Task 15 is being built `HEAD` is still the `Base:` commit: `git rev-parse HEAD` and `Base:` are both
cdf0a77 on branch `ai-framework`. `record` defaults `<commit>` to `HEAD`, so its window runs from Base's committer
time to the same instant. Scenario: The executor runs `ai-log record --dry-run plan-ai-framework.md` as the test says.
The window is empty, so 'no session in scope' exits 1, and the required tokens-vs-cost-state check and the real pushed
entry can't be produced. If the executor passes some other commit to get around it, that entry is pushed to the
private repo under an id that the real run's later record (Task 15b end to end) will never replace.
Fixed: With R2-9: the dry run's window ends now, and Task 15 no longer runs a real `record`, so no entry is pushed
under an id the later record wouldn't replace.

### R2-35 · major · consistency

Task 15 § Change, 'Reviews, this run's only' and § Interfaces `reviews[]`: The plan assumes that closed log sections
and `-closed-` findings files 'belong to earlier runs'. That isn't true. `implementing-plans` runs a fresh
`reviewing-in-rounds plan` at every `## Revisit` or plan iteration, and § The staged workflow says 'The re-review is
still a fresh run, closing the old log'. So one implementing run closes its own plan-review logs part-way through. The
untracked `plan-ai-framework-review-findings-plan-closed-2026-11-05-2.md` is exactly this: a second close on the same
day. Scenario: This run iterates the plan at the Revisit before 15b, which closes the round's plan log. The entry
recorded after the commit then counts only the last plan review, so the rounds, findings and majors for plan review
are undercounted with no warning. Task 15c's 'cost recurs with no findings' cut candidates would then point at the
plan lenses on wrong data.
Fixed: Task 15 § Change, Reviews: logs and findings files closed on or after the window start's date count too, each
section keyed by kind, first row and first finding, so a log an earlier entry counted adds only its new rows; tests
cover a log closed between two runs.

### R2-36 · major · consistency

Task 15 § Change, 'Cost, only for sessions inside the window', and Task 15c sketch ('refreshing entries whose
cost_complete is false by re-running record'): The cost rule never captures dollars for the driver session, and that
session's `cost-state` holds the cost of all its subagents. A `cost-state` counts only when it falls inside the
window, the window ends at `<commit>`'s time, and the driver session keeps running after the commit to run record,
note and filing-learnings. Its `cost-state` is written at exit, so it is always after the window. That also means Task
15c's planned refresh can never make such an entry complete. Scenario: After every `ai implement` run, the main
session has `cost_usd: null` and `cost_complete: false`, even when record is re-run after the session has ended.
Dollars per plan, which the user's spec asks for, are null for almost every entry, and 15c's refresh step produces
nothing.
Fixed: With R2-1: `cost_usd` is priced from the windowed tokens for every session, the driving one included,
`cost_complete` and the refresh are dropped, and Task 15c's sketch re-prices entries from their stored tokens when the
table changes.

### R2-37 · major · consistency

Task 15 § Interfaces (`publish` gate on `terms_pass`) vs Task 15b § Interfaces/Change (`note --terms`): At customer
level, `publish` refuses only when the JSON entry's `terms_pass` is false. Nothing records whether `entries/<id>.md`
was written with `--terms`. Task 15b also says that re-running `record` keeps an existing `.md`. So the mechanical
gate covers the JSON and not the introspection that `publish` pushes alongside it. Scenario: At customer level the
session pipes its introspection to `ai-log note <id>` without `--terms`, as `record`'s first, personal-form
instruction prints, or before it builds the terms file. It then runs `record --terms <file>`, which sets `terms_pass`
true and keeps the stale `.md`. `publish` accepts the entry and pushes a `.md` that still names `Bluefin` and `Marta
Kestrel`.
Fixed: With R2-23: the `.md` has its own terms flag, which `publish` checks with the JSON's, and a re-run of `record`
either re-redacts the kept `.md` with the terms file or leaves its flag unchanged, so no unredacted `.md` becomes
publishable.

### R2-38 · minor · consistency

Task 15b § Files (claude/docs/work-contexts.md § An approval covers one action, not a policy): The task tells the
executor to add text to a section without changing its existing lines, but the new text contradicts them. The section
is headed 'An approval covers one action, not a policy' and says 'At every level, the workflow skills never commit on
their own' and 'On customer work reviewing-in-rounds drafts the commit rather than committing'. The new text describes
a standing yes under which `reviewing-in-rounds` commits and pushes at every level, customer included. The task
doesn't say to reword the existing lines. Scenario: The executor appends the new paragraph as written. The doc now
says both that the skills never commit on their own and that they commit and push the log repo on a standing policy. A
later session that reads the existing line at customer level declines or asks before `ai-log`, and the standing yes
the step depends on doesn't hold.

### R2-39 · minor · consistency

Approvals, 'Added 2026-11-05 by the iteration that detailed Task 15' first bullet: The standing yes names `ai-log
record` and `ai-log note`. At customer level, though, the commit and push are done by `ai-log publish` (Task 15 §
Interfaces). Under the global rule 'An approval covers what it names — never its neighbour', the customer-level push
isn't covered. Scenario: At customer level, a session that applies the approvals literally stops to ask before `ai-log
publish`. Or the 15b skill line 'covers its commits and pushes' claims a yes that the recorded approval doesn't name.

### R2-40 · minor · consistency

Task 15 § Interfaces (findings entry 'with no blank line inside') vs Handover's unfiled detour (MD022): The Handover
records that markdownlint (MD022) inserts a blank line after headings where `review-log.md`'s literal format has none.
Task 15's parse contract assumes there is no blank line inside an entry, so it hasn't absorbed that known deviation.
Scenario: A findings file that markdownlint has reformatted has a blank line between `### R3-2 · …` and its `Fixed:`
line. A parser built to the stated contract stops at the blank line, so it records the finding as open with no
warning, and the fixed and open counts are silently wrong.

### R2-41 · minor · consistency

Implementation status table, 'Final code review' row: The row is ✅ DONE, from Task 14's round 2 and the round-12 log,
while Tasks 15, 15b and 16 are still ⏳ PENDING. § The staged workflow says this row stays ⏳ PENDING until
`reviewing-in-rounds code` reaches `Done (code):`, so that a skipped final review shows in the plan. Once new tasks
are added, the row no longer tells the truth. Scenario: 15, 15b and 16 are built and checkpointed, and the run stops
or skips its final review. The table shows every row ✅ DONE, including Final code review, so the missing review, which
is also the trigger for Task 15b's end-to-end test, can't be seen.

### R2-42 · minor · consistency

Task 16 § Change ('The rule stays under its 30-line aim'): `claude/rules/writing-code.md` is already exactly 30 lines,
and `bin/check-md-limits` counts the front matter. Adding 11 globs, one per line, makes it at least 41 lines, over the
aim though under the 50-line cap. The plan's statement is false. Scenario: The executor adds the globs as specified
and `check-md-limits` prints the advisory over-aim warning. Either the task's own claim fails review, or the executor
squeezes the body to meet an aim the plan said would hold anyway.

### R2-43 · nit · consistency

Task 15b § Files vs File map: Task 15b's tests need new customer-level fixtures (an introspection with the invented
terms, a customer tree with a `CLAUDE.md`). The File map lists `test/ai-log/` for 15 and 15b, but 15b's Files list
leaves it out. Completion splits commits by each task's Files list. Scenario: Fixtures added in 15b fall outside 15b's
list and get attributed to the last task. That's harmless here because 15 and 15b share files and produce one commit,
but the two lists disagree.

### R2-44 · nit · consistency

Handover item 6 vs Task 13 deviation and status rows: Handover item 6 lists what goes into Task 13's issue ('the
Deferred: lines, the audit's recorded Mediums and Lows, R12-4') but leaves out Task 15c. The status table, the Order
line and Task 13's deviation all name 15c as a follow-up in that issue. Scenario: A session resuming from the Handover
files Task 13's issue without 15c and its sketch, then deletes the plan, and the only record of the cross-session
report is lost.
Refuted: Dropped by the verifier. Refuted. Handover item 0 of the same list says '15c goes to Task 13's issue', and
Task 13's own deviation names 'Task 15c with its sketch, as a follow-up' among the issue's contents. A session filing
Task 13's issue follows Task 13's section, so the claimed loss of 15c does not happen.

### R2-45 · major · work context

Task 15 § Change, 'Redaction, mechanical' and 'Customer level, names folded'; Task 15b § Change, 'At customer level
record prints the model pass': The model pass and name folding run only when the guard says customer. At personal and
company level the entry stores `repo`, `plan` and the user's typed prompts after mechanical redaction alone, which
covers only `~/.claude-customers` entries, remotes, hosts, paths, emails, URLs and tokens. The user's ruling for the
log repo is 'still free of customer details'. Under the global § Work contexts, any origin that isn't the personal
account and isn't listed in `~/.claude-customers` resolves to company, so a customer's repo the user hasn't listed yet
gets no protection. Neither does a dotfiles or company session whose prompts name a customer, its systems or its
internal tooling. Scenario: The user works in `acme-corp/app` before adding Acme to `~/.claude-customers`. The level
resolves company, so `record` stores `repo: acme-corp/app` and the plan's basename unchanged. A prompt like 'the
Bluefin export job for Acme fails' is kept, because Bluefin matches no mechanical pattern. Everything is committed and
pushed to `andrelin/ai-framework-log` with no model pass. The same happens in Task 15's own real run over this repo,
where sessions discussed Task M's customer-specific repo. Once pushed, the text stays in the remote's history, so
removing it means rewriting history.
Fixed: The model terms pass now runs at every level: `record` holds the entry at every level until `--terms` runs,
`publish` makes every push, and folding names stays customer-only; 15b's step says so, and its tests add a
company-level headless run and a personal-level gate.

### R2-46 · minor · work context

Task 15b § Change, model pass, last sentence ('When the customer tree's CLAUDE.md forbids work data leaving the
client's systems ...'): Publishing is the default and the customer's `CLAUDE.md` can only veto it. The global rule
says the customer's `CLAUDE.md` wins, but an engagement's confidentiality terms are often not written there, and some
customer trees have no root `CLAUDE.md` at all. In both cases the step publishes redacted prompts, questions and the
introspection off the machine without asking. Scenario: A customer tree has no root `CLAUDE.md`, or one that is silent
on data handling, while the engagement's NDA bars sharing work details. The step runs 'without asking', gathers terms,
publishes, and pushes customer-session prompts to GitHub. Nobody checked whether that was allowed, and the push can't
be undone without rewriting history.
Refuted: Dropped by the verifier. The user ruled on this explicitly. Lines 3444-3448 and 96-99 say entries store
redacted prompts, questions and the introspection 'at every level, customer included', and commit and push 'without
asking each time'. The user is the one who knows their engagements' terms, and they gave the standing yes knowing
customer sessions are included. The CLAUDE.md veto is an extra safeguard on top of that yes, not the only authority.
The global rule also has Claude read the customer tree's root CLAUDE.md before customer work. Asking per run would
contradict the approved 'without asking'.

### R2-47 · nit · work context

Task 15b § Files (the `claude/docs/work-contexts.md` addition) vs `claude/CLAUDE.md` § Durable context and § Work
contexts: The exception that lets customer-session data leave for the personal log repo is written only into
`work-contexts.md` and the `reviewing-in-rounds` step. The global `CLAUDE.md`, which loads in every session, still
says 'customer context stays outside the repos, in that customer's tree' and that the customer's `CLAUDE.md` wins. So
at customer level the always-loaded rule and the skill step disagree, and nothing in the global file points to the
carve-out. Scenario: A customer-level session reaches the new step after its commit. With only the global `CLAUDE.md`
and the skill in context, the model sees customer context going into a repo outside the customer tree. It either stops
to ask, which defeats 'without asking', or proceeds against the global text. Which one happens depends on how it
weighs the conflict, so runs behave inconsistently.
Refuted: Downgraded from minor by the verifier. Downgraded. The global CLAUDE.md line 'customer context stays outside
the repos, in that customer's tree' sits in § Durable context and is about where durable project context goes instead
of memory. It doesn't cover aggregated performance entries. The customer rule on history and the remote covers the
customer's repos, and the log repo resolves as personal through the shims (line 3584). The skill step itself says 'at
every level' and 'without asking', and that it runs on the user's standing yes (line 3671). So a model is unlikely to
stall. A one-line pointer in the global file would only be a wording improvement.

### R2-48 · minor · work context

Task 15b § Tests, 'The model pass, by the session': The headless customer-level scenario is told to 'run the step',
but the plan never says `AI_LOG_DIR` points at the local bare repo's clone. In the throwaway `HOME` the default
`$HOME/.ai-framework-log` is missing, so `record` exits 2 and prints `gh repo clone andrelin/ai-framework-log`. A
session following that instruction, with a `GH_TOKEN` inherited from the environment or the real `gh` config, would
clone the real private log repo and push invented test data to it. Scenario: The executor starts the `claude -p` test
with only `HOME` swapped. `ai-log` reports exit 2 with the clone hint. The test agent follows it, clones the real
`andrelin/ai-framework-log`, and publishes the Bluefin and Marta Kestrel test entry into the user's real performance
log, which then skews Task 15c's cross-session data.

### R2-49 · minor · work context

Task 15 § Interfaces ('at customer level it holds the entry, written but uncommitted'); Task 15b model pass: An entry
held at customer level sits unredacted, as `entries/<id>.json` and `.md` holding customer prompts and terms, in the
working tree of the personal log clone. Nothing cleans it up if the session stops before the model pass finishes or
before `publish`. Only the 'CLAUDE.md forbids' branch deletes held files. Untracked customer text then stays
indefinitely in a personal repo's clone. Scenario: A customer session is interrupted after `record` but before
`publish`. `$HOME/.ai-framework-log/entries/` keeps an untracked file holding raw customer prompts. A later manual
`git add -A` or `git add entries` in the log repo, by the user or another session, commits and pushes it unredacted.
The plan's guarantee that each run adds only its own files does not hold for a human or a different command.

### R2-50 · nit · work context

Task 15 § Tests, 'Real data, last, by the session' ('Record any warnings in this task'): Warnings are copied into the
tracked plan in a personal public repo. A warning about a line that isn't JSON or about a transcript source may
include the transcript path. That path is an absolute path under `~/.claude/projects/` and its directory name encodes
the cwd, which goes against the plan's own 'no hardcoded absolute paths in tracked files' constraint. Scenario:
`record` warns 'non-JSON line in /Users/`<user>`/.claude/projects/-Users-`<user>`--dotfiles/`<session>`.jsonl'. The executor
records it verbatim in Task 15 and commits it to the public repo, publishing the username and an absolute path.
Refuted: Dropped by the verifier. Covered elsewhere and out of scope. The plan's Global constraints already forbid
hardcoded absolute paths and customer details in every tracked file. The same instruction says 'never transcript
content', so the executor is bound to strip a path before recording a warning. What a warning message contains is an
output format, which the out-of-scope line leaves to the code.

## Round 3

### R3-1 · major · grounding

Task 15 § What the transcripts hold (subagent and workflow layout) and § Change, Cost / Stages: The transcript layout
the script rests on is incomplete. Workflow-tool agents keep their own per-model transcripts under
`<session>/subagents/workflows/wf_*/agent-<id>.jsonl`, each with a `.meta.json` holding
`agentType: workflow-subagent`, `workflowPhase` and `model`. The plan names only `<session>/subagents/agent-<id>.jsonl` and the
`<session>/workflows/wf_*.json` summaries, and those summaries carry only a model-less `totalTokens`. In this run's
own session the workflow agents' transcripts come to 101 MB, against 62 MB for the plain subagents. 15 of its 16
`Workflow` calls are review rounds, and their records have `attributionSkill: null`. Scenario: An executor following
the plan globs `subagents/agent-*.jsonl`. The review rounds' tokens then reach the entry only as `workflows.tokens`,
which has no model and no price. So `cost_usd` and the per-model `tokens` leave out most of the
`plan_review`/`code_review` spend, and the introspection judges the review stages as cheap. If the executor instead
globs recursively and also sums `workflows.tokens` into the totals, the same tokens are counted twice.
Fixed: Task 15's transcript layout names the workflow agents' transcripts under `subagents/workflows/wf_*/` and their
`.meta.json`; they count in `tokens` once per model like subagents, `workflows` drops its `tokens`, and the summaries'
`totalTokens` is never added; a Counts test covers it.

### R3-2 · major · grounding

Task 15 § Interfaces, stored text `prompts[]` and `user_turns` (`promptSource: "typed"`); Task 15b Tests, The model
pass, by the session: Typed user turns are not only `promptSource: "typed"`. In real transcripts I found `queued`
(typed while Claude is busy, 4 records) and `suggestion_accepted` (22), and headless `claude -p` prompts are `sdk`.
The filter drops all of these. As a result, the headless model-pass scenarios in 15b, both the customer run and the
company-resolving run, cannot fail on the prompts path. Scenario: In the 15b scenario the session's prompt names
`Bluefin` and `Marta Kestrel`, but its `promptSource` is `sdk`. `record` stores no `prompts[]` entry for it, so
neither term ever reaches the bare origin, whether or not the session gathered them into a terms file. The test passes
even when the model pass is skipped. In interactive use, queued prompts disappear from `prompts[]` and from
`user_turns`.
Fixed: a user's prompt is now a `type: user`, non-sidechain record with `promptSource` `typed`, `queued`,
`suggestion_accepted` or `sdk`; `prompts[]` and `user_turns` both use that, and the Counts test has one turn of each.

### R3-3 · minor · grounding

Approvals, block 'Added 2026-11-05 by the plan-review fixes'; Task 15b Tests, The model pass, by the session: The
scenario needs the session to create a throwaway `HOME` whose `~/.claude-customers` lists `example--client`. The guard
blocks every Bash or Write call that writes a `.claude-customers` file, even under a `mktemp -d` `HOME`. I verified
this: both calls were refused with 'Only the user edits ~/.claude-customers'. The Approvals block arranges only the
login token, not how that file gets created. This is the same wall that left Task 8's customer cases at PARTIAL.
Scenario: The session reaches the 15b customer-pass scenario, its setup step is blocked, and the run stops. Otherwise
it routes around a block that the global CLAUDE.md says is final. The user has to be asked mid-run for something the
bulk approvals were meant to cover up front.
Refuted: Downgraded from major by the verifier. Downgraded. The guard's `basename_is_protected`/`deny_protected` does
refuse a direct Bash or Write to any path whose basename is `.claude-customers`. But the 2026-10-30 Approvals bullet
already covers 'a throwaway HOME with a ~/.claude-customers listing example--client for the customer cases', so the
claim that the Approvals block arranges only the token is wrong. The repo's existing tests also write that file from
inside a script: test/test_claude_shims.sh:53 and test/test_work_context.sh:40, which the guard does not see as a
direct write. An executor is not stuck: putting the scenario's HOME setup in a script, as those tests do, is cheap to
settle. The plan should still say so, given Task 8's earlier inconclusive customer cases.

### R3-4 · minor · grounding

Task 15 § Change, Stages (reviewing-in-rounds args opening `plan` / `code`; attributionSkill first):
`attributionSkill` is consulted first, but on its own it cannot separate the plan-review stage from the code-review
stage: it says `reviewing-in-rounds` for both. Real `Skill` args are free text and do not always open with `plan` or
`code`, e.g. 'Resume code review (no plan) from …'. Sessions started by `bin/ai` invoke the skill as a slash command
rather than through a `Skill` tool call. The plan does not say what such records map to. Scenario: A resumed code
review whose args read 'Resume code review…', or a run started by `ai review plan`, has `attributionSkill`
reviewing-in-rounds and no `Skill` call with matching args. Its records land in the wrong stage or in `other`, so the
per-stage numbers the introspection relies on are wrong.

### R3-5 · minor · grounding

Task 15b § Change, The skill step ('without asking') and the work-contexts.md edit; global claude/CLAUDE.md §
Approvals: Task 15b amends `claude/docs/work-contexts.md`, which says the workflow skills never commit on their own
and that an approval is not a policy. It leaves the global `claude/CLAUDE.md` § Approvals unchanged, and that section
loads in every session and says an approval covers 'never its neighbour or the next one'. The standing yes that
'outlives this plan' then lives only in one skill line, which contradicts the always-loaded global rule. Scenario:
After Task 13 deletes the plan, a session at completion reads the global rule, treats the `ai-log publish` commit and
push as needing a fresh yes, and stops to ask. That breaks the user's 'without asking each time'. Alternatively, the
two instructions are read as conflicting and the session behaves inconsistently across runs.

### R3-6 · minor · grounding

Task 15c and Implementation status / Order (15c 'not built in this plan'): The user explicitly asked to 'run
introspection across multiple sessions'. That requirement is moved out of the plan into a follow-up in Task 13's
issue, and no user decision for the deferral is recorded. Every other scope ruling in Task 15 cites the user.
Scenario: The plan completes and is deleted with only per-plan entries built. The user's cross-session requirement
depends on a follow-up item they never agreed to defer, and nothing in the plan shows they accepted that the
requirement ships later.

### R3-7 · nit · grounding

Approvals, block 'Added 2026-11-05 by the iteration that detailed Task 15': The block heading says the yes was 'asked
and answered yes the same day'. Its body then says the yes was widened to `publish` and to deleting held entries with
'nothing was asked again'. Under the global 'an approval covers what it names', the record should either show the
user's yes to the wider scope or not claim it. Scenario: An executor or reviewer reads the heading as covering
deletion of held entries and `publish` at customer level, while the body admits only `record` and `note` were named.
The question resurfaces mid-run, or the plan is reported as holding an approval it lacks.
Refuted: Downgraded from minor by the verifier. Downgraded to nit. The user's yes as quoted names the action itself:
'commit to the clone of the private andrelin/ai-framework-log and push it, without asking each time'. `ai-log publish`
is exactly that commit and push, and `record`/`note` write only local, uncommitted files. Deleting a held entry
removes an uncommitted local file in the user's own clone. The body openly says the subcommand list restates that yes.
No write beyond the commit and push the user named is claimed, so only the heading's wording ('asked and answered
yes') could be tighter.

### R3-8 · minor · grounding

Task 16 § Change ('The rule stays under its 30-line aim'): `claude/rules/writing-code.md` is already 30 lines (`wc
-l`). `bin/check-md-limits` counts front matter toward a rule's 30/50 limit. Adding 11 glob lines one per line takes
it to about 41, past the aim, so the plan's claim is false. Scenario: The executor follows the plan, and
`check-md-limits` warns that the rule exceeds its aim. The executor must then either compress the body, or pin the
length as a decision the plan says isn't needed.

### R3-9 · minor · grounding

Task 16 § Change (glob list): The ruling was 'C# plus the common languages'. The list covers `.cs` but not the other
files .NET work routinely opens (`.csproj`, `.razor`, `.cshtml`, `.fs`). It also omits common languages such as
`.kt`'s peers `.dart`, `.vue`, `.svelte`, `.sql`, `.ps1`, `.hpp`/`.cc` and `.m`. Under rule-globs.md a missing glob
fails silently. Scenario: The user opens a `.razor` or `.csproj` file in a C# desktop session, the rule doesn't load,
and that is the same silent miss that triggered Task 16.

### R3-10 · minor · scope and slicing

Task 15 (whole task) and Revisit · Does a real entry hold what an introspection needs?; Implementation status Order
line: The riskiest assumption comes last. Task 15 assumes that windowed transcript records, split by stage through
`attributionSkill` and stage `Skill` calls, give per-stage numbers good enough to judge a stage by. That assumption is
checked only by the real-data `--dry-run` at the very end of Task 15 and by the Revisit after it. By then the task has
already built mechanical redaction, customer name folding, the price table, review `key` dedup across entries,
`--snapshot`, `publish` and the terms gate. Scenario: The real dry run on this repo's sessions shows that stages bleed
into each other. For example, after a nested plan review the implementing work counts as `plan_review`, or subagent
files cannot be tied to the record that spawned them. The entry schema (`stages`, `reviews[]` keys, the `after`
chaining) then has to change after it is fully built and covered by about 15 test groups. Fix: put a thin first slice
up front, a read-only parse of real transcripts into windows, stages and tokens, run with `--dry-run` on this plan.
Hold the Revisit there, and build redaction, publish and dedup on top of that answer.
Refuted: Downgraded from major by the verifier. Downgraded from major. The concern is real: the stage split is checked
only by the real dry run at the end of Task 15 and by the Revisit. But the plan already knows this, says that
nested-stage work bleeds, and places the Revisit right after the dry run, before 15b prints anything or any real entry
is published. Moving the stage split later would be cheap. It lives in one function of one script, and the entry is
schema 1 with no real entry pushed yet ("No real `record` runs here"). Redaction, publish, the terms gate and
review-key dedup don't depend on how stages are attributed. A wrong split means changing the attribution code and its
Stages test group, not the schema or the parts built on it, so this is not a decision that is costly to reverse once
built.

### R3-11 · minor · scope and slicing

Task 15b, Change, The skill step ("once the commit has run, `ai-log record <plan-file>`") vs reviewing-in-rounds §
Completion step 4: At customer level `reviewing-in-rounds` never runs the commit; step 4 drafts it for the user. The
new step still says to run `record` "once the commit has run". It does not say, as step 6 does, to wait for the user
to say the drafted commit ran. `record` exits 1 when `HEAD` is no newer than the window's start, so at customer level
the step as written fails. The requirement is "after every plan, at every level". No 15b test covers this case: the
customer scenario runs a fixture commit, not a drafted one. Scenario: A customer-level code review drafts the commit,
then runs `ai-log record` right away. The result is exit 1 (HEAD not newer than the start), or with a stale HEAD a
window that leaves out the run. Either way no entry is recorded for customer plans. Fix: tie the record half of the
step to step 6's trigger ("the drafted one once the user says it ran"), and add that case to the tests.
Refuted: Downgraded from major by the verifier. Downgraded from major. Read literally, "once the commit has run"
already means waiting until the commit exists, which at customer level is the user's drafted commit. So the step as
worded does not tell the session to run `record` right after drafting. Matching step 6's explicit wording ("or the
drafted one once the user says it ran") is a sensible clarification, and the executor can settle it in the skill text
where a reviewer can check it. The test detail is out of scope.

### R3-12 · minor · scope and slicing

Approvals (2026-11-05 run: "no skill changes" and "Yes, one line is fine") vs Task 15b, Change, The skill step: The
user approved one line in `reviewing-in-rounds`. The step Task 15b writes is a multi-sentence list item: snapshot now,
record after the commit, do what it prints without asking, the standing yes at every level, and a failure goes in the
report. At 150 characters a line that is about four lines, plus renumbering every later step. The approval covers what
it names, and this goes past it without a new question. Scenario: The executor adds a four-line procedure-like step
and treats the 2026-11-05 "one line" yes as covering it. The user later finds that a skill change they limited to one
line has grown. Either cut the step to one line, with the rest carried by `record`'s printed output as the plan
already intends, or ask the user before building.
Refuted: Downgraded from major by the verifier. Downgraded from major. The 2026-11-05 approval that detailed Task 15
was asked and answered yes. It names this skill step as the place where the standing yes lives on: "the yes lives on
in the skill step Task 15b writes, which says it runs on it". So the user approved the standing-yes clause being in
the step. What remains is snapshot-then-record and "a failure goes in the report". That is one list item of about 330
characters, which is a reasonable reading of "one line" as opposed to a procedure. No write is forbidden and nothing
is built wrong. Trimming the step, or confirming the reading with the user, is cheap at implementation.

### R3-13 · minor · scope and slicing

Task 16, Spec and Tests: The task rests on an unproven cause. The user's report says the rule didn't load for a `.cs`
file in a desktop session and that `paths:` "may not" cover C#. The task adds globs without first reproducing the
miss. Its test runs headless `claude -p` in the CLI, not the desktop session where it failed, and checks only after
the change, with no baseline run showing that `.cs` fails to load the rule before it. Scenario: The desktop app
doesn't load path-scoped rules at all, or loads them only on some tools, so the missing glob was not the cause. The
headless test passes once the globs are added and the task is marked done, but the reported desktop miss remains. Fix:
start with a baseline run on a `.cs` file that does not load the rule before the edit, then prove the fix flips it.
Either state the desktop case as out of scope or check it by hand.
Refuted: Downgraded from major by the verifier. Downgraded from major. The cause is not an unproven hypothesis.
`claude/rules/writing-code.md`'s `paths:` list has no `/*.cs`, so no path-scoped load can match a .cs file. The user
also ruled on the fix directly: "cover C# plus the common languages." The task builds what was asked. Two cheap
additions remain: a baseline run before the edit, and a line saying whether the desktop case is out of scope or
checked by hand. The exact test steps are otherwise out of scope.

### R3-14 · minor · scope and slicing

Task 15, Interfaces/Tests (`publish`, terms gate) and Real data ("No real `record` runs here"): This is a slicing
problem. Task 15 builds `publish` and the terms gate, but nothing in Task 15 uses them on real data, and its real-data
check is dry-run only. Their first consumer is Task 15b's step. Task 15 therefore ships a commit-and-push path that no
real run touches until 15b's end-to-end run. The task is also much broader than 'the data' it is named for. Scenario:
A bug in `publish` against the real private repo first shows up in 15b's end-to-end run, after this run's commit, in a
different task's review. Moving `publish` and the gate into 15b, where the step first uses them, would leave Task 15
as a read-only reader that ends in a runnable dry run.
Refuted: Dropped by the verifier. Moving `publish` and the terms gate into 15b would not change when they first meet
real data. That is 15b's end-to-end run either way, because the plan forbids a real `record` in Task 15 for a stated
reason (an id a later record wouldn't replace). Task 15's tests already exercise `publish` against a bare origin, with
the gate, shims and an unreachable remote. So the move prevents no concrete failure. It is a preference about how to
slice the tasks, not a defect.

### R3-15 · nit · scope and slicing

Task 15, Files ("Outside this repo") vs Approvals ("push to it as Task 15 builds") and Real data ("No real `record`
runs here"): The plan doesn't say who makes the log repo's first commit, holding `README.md` and `.gitignore`, or
when. Task 15 says the repo holds them, but also that no real record runs, and `publish` adds only `entries/<id>.*`.
Nothing states whether the executor commits and pushes these by hand in Task 15. Scenario: One executor creates the
repo empty, so the first `git pull --ff-only` in `record` warns on an empty remote and the `snapshots/` ignore never
lands. Another hand-writes and pushes an initial commit under the approval. Either way it is cheap to say which.
Refuted: Downgraded from minor by the verifier. Downgraded from minor. The Files list already says what the log repo
holds (`entries/`, `README.md`, `.gitignore` listing `snapshots/`). The Approvals cover creating it and "push to it as
Task 15 builds". So the executor creates the repo with those files and pushes, and a reviewer can check it. The
failure scenario is also weak. `publish` adds only `entries/<id>.*`, so `snapshots/` is never committed even without
the ignore file. An empty-remote `pull --ff-only` only warns, by design. One clarifying clause would close it.

### R3-16 · nit · scope and slicing

Task 15b, Tests, End to end: The end-to-end acceptance for 15b runs only at "this plan's next final code review",
which is the completion step that commits 15b itself. So the task's main behaviour is proved only after its own
commit, with no runnable check inside the task that the live symlinked skill step drives `record`, `note` and
`publish` in order. The headless model-pass runs cover the pass, not the step's place in § Completion. Scenario: The
step text is misread in the real completion, for example `record` is run before the commit or the snapshot is skipped.
The failure surfaces only after the run's commit and push, with the code review already marked done. A fix then needs
a further commit outside any reviewed task.
Refuted: Downgraded from minor by the verifier. Downgraded from minor. A step that runs after a real commit can only
be proved end to end at a real completion. That is inherent to the step, not a slicing mistake. Before that, the 15b
headless runs drive the step on a fixture plan and commit through record, note and publish, and the grep test pins the
step's place before the commit in the Completion list. By the plan's design an ai-log failure "goes in the report and
never undoes the commit". Which further checks to add is a test-case choice, and those are out of scope.

### R3-17 · minor · scope and slicing

Task 16, Change ("The rule stays under its 30-line aim"): `claude/rules/writing-code.md` is already 30 lines, and
`bin/check-md-limits` counts front matter toward file length. Adding 11 globs, one per line, makes it 41 lines, over
the 30 aim and short of the 50 cap. So the plan's claim is false, and check-md-limits will print its advisory.
Scenario: The executor sees the length warning and either trims body bullets to meet a claim the plan made, cutting
guidance nothing asked to remove, or treats the warning as a failed test. State that the rule may go past its aim for
the globs, or pin the length.

### R3-18 · nit · scope and slicing

Task 15b, Files (`claude/skills/reviewing-in-rounds/SKILL.md`): The skill is at 112 lines, already over its 100-line
aim. The added step grows it further, and the plan doesn't mention the aim the way Task 16 does for its rule.
Scenario: check-md-limits prints an advisory on the skill, and the executor has no guidance on whether to accept it or
trim elsewhere.
Refuted: Dropped by the verifier. Wrong on the facts. check-md-limits doesn't count blank lines or headings. By its
count the skill is 90 lines (112 raw), under its 100-line aim, and running it on the skill prints no advisory. A step
of three or four lines leaves it at about 94, still under the aim. Task 15b's tests already run `bin/check-md-limits`
on the skill.

### R3-19 · major · decisions

Task 15 · Interfaces (`ai-log publish`) vs Task 15 · Tests (*The model pass, mechanically*, *Log repo*, *Shims*):
`publish` refuses at every level unless `entries/<id>.md` exists and `note_terms_pass` is true, but only Task 15b's
`ai-log note` writes that `.md` and sets that flag. Task 15's own tests need `publish` to push ("`publish` pushes",
"`publish`'s commit is pushed to the bare origin", the shims case). The executor's question: "Do I build `note` in
Task 15, have the fixtures hand-write the `.md` and flip `note_terms_pass`, or relax the gate until 15b?" Each answer
builds something different. Scenario: An executor builds Task 15 exactly as its Interfaces say. Then every Task 15
test that expects a push fails, because no `.md` can exist yet. Either the task can't close, or the executor quietly
weakens the gate the user's redaction requirement depends on.
Fixed: with R3-30, Task 15's `publish` gate needs only `terms_pass`; Task 15b extends it with the `.md` and
`note_terms_pass`, and Task 15's push tests run `record --terms` first.

### R3-20 · major · decisions

Task 15 · Interfaces, `<id>` and `plan_key` (sha256 over "origin URL"): Both hashes take the raw origin URL as input.
The user works from several machines, and one clone may use `git@github.com:o/r.git` while another uses
`https://github.com/o/r`. The plan never says whether the URL is normalised first, for example to the `<owner>/<name>`
that `repo` already stores. The executor's question: "Which URL form goes into the hash?" Changing the answer later is
costly: stored entries can't be re-keyed, and Task 15c groups by these keys. Scenario: A plan is run on the laptop
over SSH and then on the desktop over HTTPS. The two machines compute different `plan_key`s, so the second run finds
no earlier entry, starts its window at the plan's first appearance and counts the first run's tokens and review rows
again. A re-run of `record` on the other machine also writes a second entry instead of replacing the first.
Fixed: `<id>` and `plan_key` hash the origin URL normalised to `<host>/<owner>/<repo>`, lowercase, no scheme, user or
`.git`; a Log repo test checks an https origin gives the ssh one's id and `plan_key`.

### R3-21 · minor · decisions

Task 15b · Change, *The skill step*, vs § Approvals 2026-11-05 ("Yes, one line is fine."): The user approved one line
in `reviewing-in-rounds`. The quoted step is about 430 characters, which comes to three or four lines at the
150-character limit, and the test only checks that it is "one list item". So "one line" has two readings: one source
line, which the given wording can't fit, or one list item, which goes past the literal approval. Scenario: The
executor commits a multi-line step to a skill under a "no skill changes" ruling, on an approval that named "one line".
That is a change the user didn't approve, and the global § Approvals says an approval covers what it names. The other
way round, a step squeezed into one line drops the snapshot-first order or the failure-handling clause.
Refuted: Downgraded from major by the verifier. Downgraded. The user's ruling was a design question ("may Task 15b add
one line despite 'no skill changes'"), not a git or platform write. The plan frames it as one step, "a pointer, not a
procedure". A single list item wrapped across source lines by the 150-char limit is the natural reading of "one line"
for a step. The risk is real but cheap: the executor can show the user the step text, or tighten it, while
implementing, and reverting a skill edit costs little.

### R3-22 · minor · decisions

Task 15b · Files, the `claude/docs/work-contexts.md` § *An approval covers one action, not a policy* addition: That
section says "An approval covers one action, not a policy… Ask again, every time" and "At every level, the workflow
skills never commit on their own." Task 15b adds a standing, ask-never commit and push from `reviewing-in-rounds` at
every level, but it doesn't say whether the heading and those two sentences get reworded or carry an explicit
exception. The executor's question: "Do I amend the principle, or append beside it?" The doc is a global, user-visible
rule. Scenario: The executor appends the new paragraph and leaves "never commit on their own" and "not a policy"
unchanged. A later session reading the doc then finds it contradicting the skill step. It either refuses to run
`ai-log publish` and asks every time, defeating the standing yes, or treats the contradiction as permission to set
aside other single-use approvals.
Refuted: Downgraded from major by the verifier. Downgraded. The tension is real. `claude/docs/work-contexts.md` lines
78-88 say "At every level, the workflow skills never commit on their own" and "Ask again, every time", and 15b only
says the section "gains" a paragraph. But it is a doc edit to the user's own public repo, cheap to settle while
implementing, and a reviewer can check it in the diff. The added text already scopes itself as a standing yes for the
user's own log repo. Rewording the "never commit on their own" sentence to carve out that exception is a small edit,
not something costly to reverse.

### R3-23 · minor · decisions

Task 15 · Change, *Stages, split by the skills invoked*: The stage split assumes each stage starts with a `Skill` tool
call or carries a matching `attributionSkill`. `bin/ai` starts stages as fresh sessions from a slash command ("`ai
implement plan.md`", a bare `/implementing-plans`), and the stage prompts say "then `reviewing-in-rounds plan <plan-file>`
here". Nothing recorded checks whether a typed slash command, or a skill the model follows from prose,
produces a `Skill` record or an `attributionSkill` value. The Revisit checks the split only after the script is built.
Scenario: Suppose a session started with `/implementing-plans` has no `Skill` tool_use and no `attributionSkill` on
its records. All of its implement work then lands in `other`, and the per-stage numbers that the introspection and
Task 15c judge stages by are wrong from the first entry on.
Refuted: Downgraded from major by the verifier. Downgraded. The local transcripts give partial evidence for the
assumption. In this repo's current session, which started with the `/doctor` slash command, 7 assistant records carry
`attributionSkill: doctor`, so slash-invoked skills do set `attributionSkill`. Model-followed skills here also show as
`Skill` tool_use calls with matching attribution. No transcript of a session started with `/implementing-plans` was
found, so some risk remains. The plan's Revisit checks stage attribution on real data before Task 15b builds on it,
and fixing the mapping costs a few lines in the script, not stored data (tokens stay per record source only through
aggregation, so early entries could be off, but the Revisit comes before any real entry is published).

### R3-24 · minor · decisions

Task 16 · Change ("The rule stays under its 30-line aim"): `claude/rules/writing-code.md` already counts 27 lines
under `bin/check-md-limits` (front matter included; blank lines and headings excluded). Adding 11 globs one per line,
as instructed, plus the formatter examples puts it at about 38, past the 30-line aim though under the 50-line cap. The
two instructions can't both hold. The executor's question: "Do I keep one glob per line and go past the aim, merge
globs into brace patterns (whose matching `rule-globs.md` doesn't confirm), or find a seam elsewhere?" Scenario: The
executor keeps one glob per line and the aim is broken. Or the executor collapses the list into `/*.{cs,go,…}`, and if
braces aren't honoured the rule silently stops loading for every language, which is the very failure Task 16 exists to
fix.

### R3-25 · minor · decisions

Task 15b · Change, *The skill step* ("once the commit has run") at customer level: At customer level
`reviewing-in-rounds` drafts the commit and the user runs it. The step doesn't say whether the session waits for the
user to say the commit ran, as step 6 does for the checkpoint refs, before `ai-log record`. Nor does it say what to do
when the session ends first. Scenario: The session ends after drafting the commit. `record` never runs, or it runs
before the user's commit with `HEAD` no newer than the window's start and exits 1. That customer plan gets no entry
and no introspection, against the user's "after every plan".

### R3-26 · minor · decisions

Task 15 · Change, *Scope* ("the earliest record in a candidate session that names the plan") vs scope test ("a
`tool_use` input … names the plan file's basename"): Sessions are scoped by `tool_use` inputs, but a plan's first
appearance is "any record that names the plan". That covers a typed prompt such as `ai implement plan-x.md`, or
assistant text. The two readings give different window starts for a plan's first entry. Scenario: The first appearance
is a typed prompt hours before the first `Read` of the plan. One build starts the window at the prompt and the other
at the `Read`, so the first entry's tokens, wall time and stored prompts differ depending on which reading the
executor took.

### R3-27 · nit · decisions

Task 15b · Tests, *The model pass, by the session*: The headless scenario runs in a throwaway `HOME`, so the default
`AI_LOG_DIR` (`$HOME/.ai-framework-log`) doesn't exist there. The plan says the check is a grep over "a clone of the
bare origin", but it never says to set `AI_LOG_DIR` to a scratch clone of a local bare repository. An executor might
instead clone the real `andrelin/ai-framework-log` into the throwaway `HOME`. Scenario: The executor clones the real
private log repo into the throwaway `HOME`. A failing run, one that publishes without the invented terms, then pushes
`Bluefin` and `Marta Kestrel` test entries to the user's real log repo. Test noise becomes permanent history there.
Refuted: Downgraded from minor by the verifier. Downgraded. The test text says to grep "a clone of the bare origin",
and Task 15's test setup defines that as a local bare repo ("`AI_LOG_DIR` is a clone of a local bare repo") in the
same `test/test_ai_log.sh`. So the scratch-repo reading is already the stated one. Cloning the real repo means
ignoring "bare origin". A throwaway `HOME` also lacks the user's `gh` hosts config and SSH keys, so a stray clone of
the private repo would most likely fail. What's left is a wording gap: the test could name `AI_LOG_DIR` explicitly.

### R3-28 · nit · decisions

Task 15 · Change, *Stages* ("`implementing-plans` → `implement`, and with `code` → `code_review`"): "and with `code`"
reads as if it attaches to `implementing-plans`. It means `reviewing-in-rounds` with `args` opening `code`. Scenario:
A literal reading maps `implementing-plans code` to `code_review` and never maps `reviewing-in-rounds code` at all, so
code-review work lands in whichever stage came before it.

### R3-29 · nit · decisions

Task 16 · Change (formatter bullet): "Add `.editorconfig` and `dotnet format` to the formatter bullet's examples": the
bullet lists config files that the formatters are found from, and `dotnet format` is a command, not a config file.
Scenario: The executor puts a command into a list of config files, and the bullet's "found from its config" logic
becomes muddled for the .NET case.
Refuted: Dropped by the verifier. Refuted. The formatter bullet's list is not limited to config files. It already
includes "Gradle tasks", which isn't a config file either, so adding `dotnet format` beside `.editorconfig` fits the
bullet as written. It's also a wording choice a reviewer can check in the diff, which is out of scope.

### R3-30 · blocking · consistency

Task 15 § Interfaces (`ai-log publish`) and § Tests (The model pass, Log repo, Shims); Task 15b § Interfaces (`ai-log
note`): Task 15's `publish` refuses at every level unless `entries/<id>.md` exists and `note_terms_pass` is true. Only
`ai-log note` writes that `.md` or sets that flag, and `note` is a Task 15b product. Even so, Task 15's own tests
require `publish` to succeed: "re-run with a `--terms` file … `publish` pushes", "Log repo: `publish`'s commit is
pushed to the bare origin", the re-run that adds no commit, the unreachable-origin case and "Shims: `publish`'s commit
and push … pass the guard". Scenario: An executor builds Task 15 in plan order (15, then 15b). With no `note`
subcommand there is no `.md` and `note_terms_pass` stays false, so every one of those `publish` tests exits 1. The
task can't reach DONE unless the executor builds part of 15b early or writes the `.md` by hand in the fixtures. Fix:
move `note` into Task 15, or move the gate's `.md`/`note_terms_pass` condition and the publish-success tests into 15b.
Fixed: Task 15's `publish` refuses only without `terms_pass`; Task 15b's Interfaces add the `.md` and
`note_terms_pass` to the gate, and every Task 15 test expecting a push runs `record --terms` first.

### R3-31 · major · consistency

Task 15b § Change, the skill step ("The plan still exists when § Completion starts … so a deletion is staged after the
snapshot"); Task 15b Tests, End to end: The step assumes that when Task 13 deletes the plan in the final commit, the
deletion is staged after the snapshot. Nothing in § *Completion of a code review* stages it: step 1 stages the fixes'
paths "never `plan-*`", and steps 2-4 only commit what is already staged. The end-to-end test ("even if Task 13
deletes the plan in that commit") depends on a mechanism no task produces. Scenario: This run reaches Task 13 and its
final code review. Either Task 13's implementer has already `git rm`'d the plan, so the review has no plan to write
its log into and the snapshot has nothing to read, or the plan is still on disk and Completion step 1 refuses to stage
`plan-*`. In that second case the commit leaves the plan tracked and Task 13's `git ls-files 'plan-ai-framework*'`
test fails. Either way the snapshot-then-delete order the step relies on never happens.
Fixed: the skill step's reasoning now says the snapshot runs before any commit and `record` falls back to it whenever
the plan is gone, however its deletion was staged; the claim that a deletion is staged after the snapshot and the
end-to-end test's reliance on it are gone.

### R3-32 · minor · consistency

Task 15 § Change, Stages ("takes the stage of its `attributionSkill` … else of the session's latest stage `Skill`
call") and § What the transcripts hold: Stage attribution relies on `Skill` tool_use calls and `attributionSkill`. The
plan's own launcher, `bin/ai`, starts a stage as a typed slash command (`prompt="/$skill"`), and the transcript
inspection never checked what a slash-invoked skill leaves behind. In this repo's transcripts no session started by a
slash command could be found to confirm it. `attributionSkill` appears on only about 120 of about 1,430 assistant
records in the current session, so the `Skill` call fallback carries most of the attribution. Scenario: A plan is run
the way the Handover says (`ai implement plan-x.md`). If a slash-invoked skill produces a user record with
`<\command-name>` and no `Skill` tool_use, every record before the first nested `Skill` call (`reviewing-in-rounds
plan` or `code`) falls into `other`. The implement stage then reads near zero and `other` holds the bulk of the cost,
which is exactly the misattribution the Revisit asks about, but found only after the schema is built. The fixtures
only test `Skill`-call sessions, so they pass anyway.
Refuted: Downgraded from major by the verifier. Downgraded. I checked a real slash-invoked skill in a local transcript
(`/superpowers:writing-plans`, Claude Code 2.1.308). It leaves a `<\command-name>` user record and no `Skill`
tool_use, but every assistant record after it carries `attributionSkill: "superpowers:writing-plans"`. The Stages rule
takes `attributionSkill` first, so a stage started by `bin/ai`'s `/$skill` is attributed, not dropped into `other`.
That refutes the failure scenario as stated. One gap remains: whether `attributionSkill` persists over long multi-turn
stage sessions. The sample was a 5-record session. The plan's own Revisit ("check here that each stage's work lands in
its stage") is placed to catch this on real data, so it is cheap to settle during implementation.

### R3-33 · minor · consistency

Implementation status, `Final code review` row; Order: The `Final code review` row is ✅ DONE (Task 14's round 2 and
the 2026-11-02 run's round 12), while Tasks 15, 15b and 16 are pending and need a final code review of their own.
`implementing-plans` skips any row already ✅ DONE on any start, and Task 15b's end-to-end test depends on "this plan's
next final code review". Scenario: A resumed `implementing-plans` run sees the row as DONE and may treat the final
review as finished, so the 15b skill step and `ai-log record` never run and no entry is pushed. The row should be
reset to pending, or its note should say it covers only the earlier tasks.
Refuted: Dropped by the verifier. `implementing-plans` § *Finish with the final review, in this run* runs
`reviewing-in-rounds code` at the end of every run that completes its tasks, whatever the table says. The "skipped if
✅ DONE" rule applies to tasks, and the `Final code review` row is not a task. The row's note already names what it
covered (Task 14's round 2, and round 12 of the closed log for Tasks 4, 12, 11 and 7). Task 14's own run had the row
DONE beforehand and still ran its final review. No failure scenario survives.

### R3-34 · minor · consistency

Task 16 § Change ("The rule stays under its 30-line aim"): `claude/rules/writing-code.md` already counts 27 lines
under `bin/check-md-limits` (front matter included, blank lines and headings excluded). Adding 11 globs one per line,
plus the formatter example, brings it to about 38, past the 30-line aim, though still under the 50 cap. Scenario: The
executor follows the task literally, and `check-md-limits` warns at the aim. Either the claim in the task is false, or
the executor has to restructure the rule (for example a brace glob such as `/*.{cs,go,rs,…}`, if the loader supports
it, which `rule-globs.md` would have to confirm). The plan doesn't decide which.

### R3-35 · minor · consistency

Task 13 § Files and § Tests (iteration not folded in): Task 13 deletes only `plan-ai-framework.md`,
`…-review-findings-plan.md` and `…-review-findings-code.md`. Logs have since been closed:
`plan-ai-framework-review-findings-code-closed-2026-11-05.md` and `…-plan-closed-2026-11-05.md` are tracked, and
`…-plan-closed-2026-11-05-2.md` exists untracked. Its deviation also still lists "Task 7's conflict sent to the user"
as an open item, although it was decided and reworded on 2026-11-05 (Approvals, Handover item 5). Scenario: Task 13's
own test `git ls-files 'plan-ai-framework*'` prints the closed findings files and fails. The follow-up issue carries
an item that is already settled.

### R3-36 · minor · consistency

Task 15b § Tests, End to end ("Record here only that it ran, and the entry's id"): The entry id exists only after
`ai-log record` runs, and that is after the final commit. Recording it "here" means editing the plan after its last
commit, or, if Task 13 deleted the plan in that commit, writing into a file that no longer exists. Scenario: After the
end-to-end run the plan holds an uncommitted edit that nothing commits, or the executor can't write the id anywhere
because the plan is gone. The test needs a target that outlives the commit, such as the report or Task 13's issue.

### R3-37 · minor · consistency

Task 15b § Files (`claude/docs/work-contexts.md` only); global `claude/CLAUDE.md` § Work contexts: At customer level,
`CLAUDE.md` forbids "`push` in any form", and the guard's prose is the reasoning sessions read. Task 15b explains the
log-repo exception only in `work-contexts.md` and the skill step, and leaves the always-loaded `CLAUDE.md` line
unqualified. Scenario: In a customer session the model reads "push in any form" in `CLAUDE.md` and declines `ai-log
publish`, or asks each time, despite the standing yes. The step then silently records nothing at customer level, which
is the case the model-pass tests target. Either `CLAUDE.md` needs a pointer, or the plan should state why
`work-contexts.md` is enough.

### R3-38 · nit · consistency

Order and Implementation status vs. § Revisit · Does a real entry hold what an introspection needs?: The Revisit sits
between Task 15 and Task 15b and feeds both 15b's printed numbers and 15c's sketch, but neither the status table nor
the Order line names it ("15 → 15b after 14"). The dependency "after 14" has no reason given: Task 15 consumes nothing
from Task 14. Scenario: An executor driving from the table and the Order line goes straight from 15 to 15b and skips
the Revisit check on nested-stage attribution.
Refuted: Dropped by the verifier. The scenario doesn't happen. `writing-plans` defines a Revisit as a `## Revisit · …`
heading between tasks. `implementing-plans` § *Between tasks, revisit the plan* acts on such a heading by its position
in the document ("Iterate the plan in this run at a `## Revisit` heading"), not from the status table or the Order
line. A Revisit placed between Task 15 and Task 15b is reached in order. What remains, the missing reason for "after
14", is only wording, with no failure scenario.

### R3-39 · minor · work context

Task 15b, Files (claude/docs/work-contexts.md) and Change (the skill step); § Approvals, 'Added 2026-11-05 by the
iteration that detailed Task 15': The standing yes ('without asking each time', 'doing what it prints without asking')
contradicts rules that outrank the skill line, and the plan reconciles only one list in one doc.
claude/docs/work-contexts.md § 'An approval covers one action, not a policy' says 'Ask again, every time, however
recently they said yes' and 'At every level, the workflow skills never commit on their own'. Global claude/CLAUDE.md §
Approvals says 'An approval covers what it names — never ... the next one', and § Work contexts says it 'outranks
every skill'. Task 15b only adds an entry to the doc's per-level list. It leaves the section's 'not a policy' and
'never commit on their own' sentences and the CLAUDE.md § Approvals text as they are. Scenario: At customer level the
session-start banner says customer, and CLAUDE.md lists 'push in any form' as forbidden. A session at that point
reaches the reviewing-in-rounds line telling it to publish without asking. CLAUDE.md says skills are 'read for
technique, never for what is allowed', so the session either stops to ask on every plan or treats a skill line as
overriding the global rules. Both are wrong. Fix: state the standing exception in claude/CLAUDE.md § Approvals or §
Work contexts (or the doc section's opening sentences), naming the private log repo as a personal-level target outside
the customer's history.
Refuted: Downgraded from major by the verifier. Partly refuted. The customer forbidden list covers the customer's own
history and remote. The log clone resolves as personal: § The log repo runs its git commands from inside AI_LOG_DIR,
and a shim test proves the guard passes there. So § Work contexts doesn't forbid the write, and the standing yes names
its scope as CLAUDE.md § Approvals asks ('each named with its scope'). The contradiction that remains is in
claude/docs/work-contexts.md: lines 82 ('Ask again, every time') and 85 ('At every level, the workflow skills never
commit on their own') would sit next to the new entry. Task 15b already edits that section, so rewording those two
sentences in the same edit is cheap and doesn't affect the design. Downgraded from major.

### R3-40 · major · work context

Task 15, Change ('Redaction, mechanical' and 'The stored text'); Task 15b, model pass and its tests: At customer
level, the plan assumes a terms list plus the mechanical patterns can redact verbatim user prompts and AskUserQuestion
options. Neither the plan nor its tests checks this against what prompts really contain: pasted code, stack traces,
log lines, package names such as com.`<client>`.billing (the last label is not a TLD, so the hostname rule misses it),
class and service names, ticket keys. The tests plant only two clean proper nouns (Bluefin, Marta Kestrel). Scenario:
A user at a customer repo pastes a stack trace into a prompt. Internal module and service names stay in prompts[]
because no pattern matches them and the model's term-gathering misses some of them. publish then pushes the client's
internal tooling names to GitHub, a third-party host, against the 'no internal tooling' bar the plan itself sets.
Possible fixes: drop or truncate prompts and options that hold code blocks or multi-line pastes at customer level, or
add a test with a pasted trace and dotted package names.
Fixed: at customer level each stored string keeps only its prose before redaction: fenced and indented blocks and
lines shaped like stack frames, timestamped log lines or dotted package names become `[code]`, the rest cut at 500
characters; a stored-text test plants a trace, `com.example.billing` and a log line.

### R3-41 · minor · work context

Task 15b, Change ('At every level record prints the model pass', the last sentence): Only the customer tree's root
CLAUDE.md is checked for whether work data may leave the client's systems. The global table says 'their CLAUDE.md wins
over this file', and the work repo's own checked-in CLAUDE.md (or AGENTS.md) is just as much 'theirs'. Scenario: A
customer repo's own CLAUDE.md forbids sending session content off the client's systems, and the user's customer-tree
CLAUDE.md is silent on it. The step publishes redacted prompts anyway, breaking a customer rule that outranks the
user's global approval.

### R3-42 · minor · work context

Task 15b, Tests ('The model pass, by the session'): The headless scenario runs in a throwaway HOME, where AI_LOG_DIR
defaults to $HOME/.ai-framework-log, and record's exit-2 message tells the session to run 'gh repo clone
andrelin/ai-framework-log'. The test never says that AI_LOG_DIR must be a clone of a local bare repo. It only mentions
'the bare origin' afterwards. Scenario: An executor or the headless session follows the printed message and clones the
real private repo into the throwaway HOME. The test's fixture entries are then pushed to the real
andrelin/ai-framework-log. The standing yes covers writes 'after every plan', not test pushes, and those entries
pollute the data that Task 15c later reads.
Refuted: Dropped by the verifier. Out of scope, since test setup is the executor's choice and can be checked in the
diff. The test already refers to 'the bare origin', and Task 15's tests set AI_LOG_DIR to a clone of a local bare
repo. The scenario is also unlikely: a throwaway HOME has no gh config, so gh isn't logged in and can't clone the
private repo, and the headless run uses scoped tool lists.

### R3-43 · minor · work context

§ Approvals, 'Added 2026-11-05 by the plan-review fixes' (the token for Task 15b's customer-pass scenario): Running '!
claude setup-token' inside the session puts the long-lived token's output into the session transcript under
~/.claude/projects, where it stays for cleanupPeriodDays. That contradicts 'not stored'. The same transcript is also
what ai-log record scans for this plan's end-to-end entry, and only the token-shape regex would keep it out. Scenario:
The token sits on disk in a transcript for 30 days and is read into prompts[] by the plan's own record run. It reaches
the private log repo if the redaction regex misses its exact shape. Better: have the user run setup-token in a
separate terminal and pass the token by env var to the headless run only.

### R3-44 · minor · work context

Task 15, Change ('The log repo', 'record ... holds the entry'); Task 15b, model pass: Entries held before the terms
pass sit uncommitted in the working tree of a pushed personal repo. They contain customer prompts redacted only
mechanically. Nothing cleans them up if the session dies, the commit is declined, or publish keeps refusing. The terms
file of customer names made with mktemp is deleted only on the success path ('Only then ai-log publish, and delete the
terms file'). Scenario: A session ends between record and publish. Weeks later someone runs a manual 'git add -A &&
git commit && git push' in $HOME/.ai-framework-log, and the unredacted customer terms are pushed. Meanwhile the terms
file lists every customer name in $TMPDIR. Possible fixes: keep held entries outside the clone, or gitignore them
until publish moves them in, and delete the terms file on every exit path.

### R3-45 · minor · work context

Task 15, Change ('Redaction, the bar' and 'Format drift'); Tests ('Real data ... Record any warnings in this task'):
warnings[] is not in the redaction bar's list of what an entry may hold, and nothing says warnings are redacted. A
warning about 'a findings heading it can't parse' or 'a line that isn't JSON' will naturally quote that heading or
line. The real-data step then copies the warnings into this plan, which lives in a personal public repo. Scenario: An
unparseable findings heading in a customer plan carries a finding's text or a path. It is stored in the entry's
warnings, and from a dotfiles run it is pasted into the public plan as 'warnings', against the bar's 'no finding text,
path'.
Refuted: Dropped by the verifier. The redaction bar already rules this out. An entry holds the listed kinds and the
stored text, 'nothing else — no ... finding text', so a warning that quotes a heading would break the bar, and a
reviewer can catch that in the diff. Warning wording is an output-format choice, which is out of scope. The real-data
step runs on this repo's own plan, so no customer heading can reach the warnings it records.

### R3-46 · nit · work context

Task 15, Interfaces (exit 2 message); Task 15b, skill step ('doing what it prints without asking'); § Approvals: The
standing yes lists record, note, publish, commit, push and deleting a held entry. It does not cover cloning the log
repo. Yet on a new machine record's exit-2 message names 'gh repo clone', and the skill tells the session to do what
record prints without asking. Scenario: On a fresh machine at customer level, the session runs gh repo clone into
$HOME on its own, an action outside what the approval names. It is cheap to settle: either name the clone in the
approval or have the step stop and report instead.

### R3-47 · nit · work context

Task 15, Interfaces ('`<id>`' and 'plan_key' ... 'naming nothing'): id and plan_key are unsalted sha256 hashes of the
origin URL plus the plan basename, so 'naming nothing' overstates it. Anyone who can read the log repo can confirm a
guessed customer origin (`git@github.com:<client>/<repo>.git`) by hashing it. Scenario: The risk is low because the repo
is private and the user's own, but the claim that customer-level entries name nothing does not hold against a guess. A
per-clone secret salt kept out of the repo would make it true.

## Re-evaluation after round 3

Majors went 12, 12, 6 with a blocking in round 3 (R3-30) born of the fixes' own growth; Tasks 15 and 15b are about
440 lines. Round 3's R3-1, R3-2 and R3-20 are field-level detail the code review owns; R3-19/30, R3-31 and R3-40 come
from Task 15 shipping counts, stored text and pushing at once.

- **Re-slice (recommended):** Task 15 records counts only (tokens, stages, review rounds and findings, estimated cost)
  for one run, dry run plus a commit to the private log repo; stored text, redaction and the introspection step become
  later tasks, detailed after the Revisit has seen real entries. Costs one rewrite of Task 15; the user's ruling to
  store prompt text is deferred, not reversed; the riskiest part is then designed against real data.
- **Continue as is:** one to three more rounds, likely more field-level majors and more design text.
- **Stop and build as written:** cheapest now; the customer-level redaction design is settled in code only.

Open design points from round 3's fixer: the 500-character, code-stripped customer prompts need the user unless
deferred by a re-slice; who stages Task 13's `git rm` of the plan goes in Task 13's own text.

## Round 4

### R4-1 · major · grounding

Task 15 § Change, *Stages, from the skills invoked*; § Interfaces (`user_turns`); Tests *Stages*: Stage attribution
assumes a stage is entered through a `Skill` tool_use carrying `args`, but `bin/ai` starts every stage with a slash
prompt (`exec claude ... "/$skill args"`). I checked this with a headless run in a `mktemp -d`. A session started with
`/cutting-comments just reply ok` records a user message holding
`<command-name>/cutting-comments</command-name><command-args>…</command-args>`, with `promptSource` null and no
`Skill` tool_use at all. The assistant records do carry `attributionSkill: cutting-comments`, but that is a bare name
with no args. Scenario: `ai review code plan-x.md` starts a session whose records are all attributed to
`reviewing-in-rounds`, and no `Skill` call opens it with `plan` or `code`. The plan's rule can't place it in
`code_review` rather than `plan_review`, and `ai review plan` has the same problem. The session's opening prompt has
`promptSource` null, so `user_turns` leaves it out. Fixtures invented to the plan's assumed shape pass the tests, and
the error only shows at the Revisit, after 15b already pushes entries. Fix: also read the stage and its args from a
`type: user` record's `<command-name>`/`<command-args>`, count that record as a user turn, and add a fixture of that
shape.
Fixed: Task 15's Stages bullet reads a slash-prompt `type: user` record's `<command-name>`/`<command-args>`
the same way, counts it as a user turn, with a fixture of that shape.

### R4-2 · minor · grounding

Task 15 § Change, *Stages*: "a record takes the stage of its `attributionSkill`": The rule doesn't say what happens
when `attributionSkill` names a non-stage skill. Transcripts show it changing per record to skills like
`filing-learnings`, `proving-causes` or `chrome-browser` partway through an `implementing-plans` session. The rule
only says other skills 'leave it as it was' for `Skill` calls. `attributionSkill: reviewing-in-rounds` also maps to
two stages, and the name alone can't separate them. Scenario: An implementer's records attributed to `proving-causes`
fall into `other` rather than `implement`. Each stage's tokens are then undercounted, and the 15d cut candidates are
drawn from misplaced numbers.

### R4-3 · minor · grounding

Task 15 § Change, *The window*: "with none, at the plan's first appearance": 'First appearance' is not defined.
`writing-plans` adds `/plan-*.md` to `info/exclude`, so in every repo but this one the plan never appears in git
history, and the only source is the transcripts. The plan names neither source. Scenario: One executor reads 'first
appearance' as `git log --diff-filter=A` on the plan. That works here, where plans are tracked, but in any other repo
the first entry for a plan finds no commit, and the result is an empty window or an exit 1. Say: the earliest in-scope
transcript record whose tool_use names the plan's basename.

### R4-4 · minor · grounding

Task 16 § Change: "The rule stays under its 30-line aim": False as specified. `claude/rules/writing-code.md` is
already 30 lines, and `bin/check-md-limits` counts a claude file's raw lines, front matter included. Eleven more
globs, one per line, plus the formatter wording puts it at about 41 lines. That is past the 30-line aim, though under
the 50 hard cap. Scenario: The executor follows the glob list and the check warns the file is over its aim, so the
stated requirement fails. Either accept about 41 lines and say so, or use a single brace glob such as
`/*.{cs,go,rs,…}`. Check first that `paths:` supports brace expansion (`claude/docs/rule-globs.md` doesn't say),
because a glob that never matches fails silently.

### R4-5 · minor · grounding

Task 15b § Files, the `claude/docs/work-contexts.md` sentence; 2026-11-05 Approvals "at every level": The doc text
says 'at customer level nothing is recorded and nothing leaves the machine'. That holds only for customers already
listed in `~/.claude-customers`. An unlisted customer repo resolves as company, as the 15c notes admit, and is then
recorded with `repo` as `<owner>/<name>` in clear. Its introspection is also redacted from a customers file that
doesn't name it. The model terms pass that would cover this was deferred to 15c, while 15b's trigger runs at every
level from now on. Scenario: The user takes on a new customer and runs a plan before adding it to
`~/.claude-customers`. The entry pushed to `andrelin/ai-framework-log` then names the customer's owner/repo, against
the user's decision that the log stays 'free of customer details'. Either word the doc claim as 'listed customers', or
hold `repo` and the plan basename back at company level for non-`uptime` owners until 15c lands.

### R4-6 · nit · grounding

Task 15 § What the transcripts hold: "`type: cost-state` is written at exit, per process": Partly off. The live
session running this review already holds two identical `cost-state` records (same `startTime`), and most `.dotfiles`
transcripts hold two. 'One per ended process' and 'never-resumed' therefore can't be judged by counting records.
Scenario: The price check picks a 'never-resumed' session by requiring exactly one `cost-state` record and finds
almost none. Better to judge it by distinct `startTime` values.

### R4-7 · major · scope and slicing

Task 15 · Tests, 'Real data, last' (with Change, 'The window'): The real-data dry run cannot show this run's work, so
the check that stage attribution works on real transcripts never happens. By the window rule, the window ends at
`<commit>`'s committer time. It ends at 'now' only with `--dry-run` *and* nothing committed since the start. With no
earlier entry, the start is the plan's first appearance (58d4816, 2026-10-16). `HEAD` = Base cdf0a77 was committed
2026-11-05T16:28, after that start, so the window ends at 16:28. Task 15's own implementation, and every stage of this
run after that time, falls outside it. The test's premise, 'so the window runs from the plan's first appearance to
now' and 'the stages hold this run's work where it belongs', contradicts the rule the same task specifies. Scenario:
The executor runs `ai-log record --dry-run plan-ai-framework.md` at Base. The entry's implement and code_review stages
hold only sessions from before 16:28 (most older ones have already aged out under the 30-day cleanup). The check 'this
run's work lands in its stage' is then either vacuous or misread as a pass. The riskiest assumption (that
`attributionSkill`, the Skill calls and the cwd/basename scope sort real work into stages) is first exercised by 15b's
real `record`, after the final code review.
Fixed: `--dry-run` with no `<commit>` now always ends the window now, so the real-data check sees this run.

### R4-8 · minor · scope and slicing

Revisit · Does a real entry hold what an introspection needs? (with the Order paragraph and Task 13's 2026-11-05
deviation): The riskiest assumption comes last, and nothing says what happens to what it teaches. The assumption is
that the counts are right and are enough to judge a stage by. It is learned only after Task 15 and 15b are fully
built, reviewed and committed: 15b's first real entry comes from 'this plan's next final code review'. The Revisit
then asks to 'fold the answer into what `record` prints', which is a code change to `bin/ai-log` and its tests. But
the Revisit has no Files, no Tests and no review or commit path. It falls after the run's final code review and before
Task 13 deletes the plan. No task owns that change, and no approval covers it. Scenario: The first real entry shows
that plan-review work nested in a Workflow lands in `other`, or that the printed summary lacks something the
introspection needed. The fix to `record` is either made unreviewed after the final code review, outside the approved
'committed after the final code review' flow. Or it is left undone while Task 13 deletes the plan, and is lost unless
someone thinks to add it to Task 13's issue. A cheaper order would run a real-data dry run (or a real `record` on an
earlier commit) before the review-log and stage machinery is finished.
Refuted: Downgraded from major by the verifier. Downgraded. A `## Revisit` heading is a defined stop in this workflow:
implementing-plans has a fresh plan agent iterate the plan there, runs `reviewing-in-rounds plan`, and carries on
through implement and code review (plan § The staged workflow, Task 9). So a change to what `record` prints would get
a task and a review, not land unreviewed after the final code review. The finding also says the riskiest assumption is
checked last. That point belongs to finding 0: the dry run was meant to check it earlier, and fixing that window
contradiction restores the early check. What remains is real but cheap: if the plan ends first, Task 13's issue
carries 15c but does not mention the fold into `record`'s output. One line settles that.

### R4-9 · minor · scope and slicing

Task 15 · Interfaces (entry `stages`) and Change, 'The window' / scope rule: The `issue` stage is built but cannot be
filled under the scope rule. A session is in scope only when a `tool_use` input inside the window names the plan's
basename, and the window starts no earlier than 'the plan's first appearance'. A `writing-issues` session runs before
the plan exists, so it neither names the plan nor falls inside the window. 'First appearance' is also left undefined
(first git commit, or first transcript mention). If it means the git add, the `writing-plans` session that wrote the
plan is cut off too. Scenario: Every entry reports `issue` as zero, and possibly `plan` as zero. A later 15d report
then reads this as the issue stage costing nothing and proposes no cuts there, or proposes cutting it. Meanwhile the
tests (which name no `issue`-stage case) pass.

### R4-10 · minor · scope and slicing

Task 15b · Change, 'The mechanical redaction', first sub-bullet: This builds customer-file redaction that the user's
re-slice deferred, and that nothing exercises now. The user's ruling was 'build the personal and Uptime part, and
defer the customer part', with every customer-level part moving to 15c. The user also has no customer at present, so
`~/.claude-customers` is empty. Even so, 15b builds every form of matching for that file (host labels minus TLD and
generic ones, directory path, `~/` form and last component, abbreviations) along with its tests. The remaining
redactions (the work repo's remotes and folders, hosts, emails, paths, URLs, tokens) already cover what personal and
company introspections can leak. Scenario: The executor spends the bulk of 15b's redaction work and tests on matching
rules for a file that lists nothing. Task 15c, when detailed from the Revisit, may then redefine customer redaction
(folding, the model terms pass) and leave this code redundant or contradicting it.
Refuted: Dropped by the verifier. The user deferred the customer-level parts: running at customer level, folded names,
stored text, the model pass and prose (Task 15 'Customer level deferred'). Redacting `~/.claude-customers` names out
of personal- and company-level introspections is not a customer-level part. It protects the personal and Uptime output
the user asked to build now. The log runs after every plan, on every machine, from now on, and a customer added to
that file before 15c is built could be named in a company-level introspection (15c's own sketch notes that an unlisted
customer repo resolves as company). That the file is empty today does not make the safeguard out of scope. How much to
test each matching form is the executor's call and falls under the out-of-scope line.

### R4-11 · minor · scope and slicing

Task 13 · 2026-11-05 deviation (with the Order paragraph and Implementation status row for 15c): The deviation moves
only the delete after the run's last commit and 15b's `record`. It leaves unstated where the rest of Task 13 falls
relative to the final code review, the Revisit and Task M. The rest is the fold into `staged-workflow.md` and
`work-contexts.md`, and filing the issue that must carry 15c 'detailed at the Revisit'. Task M is pending and by hand,
and Task 13 must follow it. Scenario: The executor builds Task 13's fold inside this run, before the final code
review. It is then reviewed and recorded, but the issue is filed before the Revisit has detailed 15c, so the issue
carries only the sketch. Alternatively, the executor does the whole of Task 13 after the review, and the fold commit
lands on `main` unreviewed. Either way, Task M not being done blocks Task 13 under the order rule, and nothing says
whether the run should stop there.

### R4-12 · minor · scope and slicing

Task 16 · Change, 'The rule stays under its 30-line aim': The claim is false, and the test will show a warning that
the task says won't occur. `bin/check-md-limits` counts every non-blank, non-heading line of a Claude-loaded file,
front matter included. The rule is at its 30-line aim today. A scratch copy with 11 more `paths:` lines reports 'is 38
lines; keep it to 30 or fewer (hard cap 50)', exit 0, advisory. That is before the formatter bullet grows for
`.editorconfig`/`dotnet format`. Scenario: The executor sees the advisory and either drops languages the user asked
for to get back to 30, or pins the file in `.md-baseline`. Neither choice is stated, so the review flags the deviation
afterwards. The plan should accept going over the aim (under the cap), or say which globs to drop.

### R4-13 · minor · scope and slicing

Task 16 · Spec and Tests, 'Loads where it should': The test runs headless `claude -p` and has no red-first run, but
the user's report came from a desktop session. Nothing first shows the rule *not* loading for a `.cs` file before the
change. So the cause ('`paths:` may not cover C#') stays a hypothesis, and the test does not show it can fail for the
reported reason. If the desktop app handles path-scoped rules differently, the change passes its test and leaves the
user's case broken. Scenario: After the change, headless reports `writing-code.md` loaded for `.cs`, and the task
closes. The user opens a `.cs` file in the desktop app and the rule still doesn't load, because the cause was
elsewhere (for example the desktop session's rule loading), which the plan never checked.
Refuted: Dropped by the verifier. The cause is not a hypothesis. The repo's claude/rules/writing-code.md `paths:`
lists only kt/java/ts/tsx/js/jsx/py/sh/zsh/kts plus bin/ and hooks/, so no glob can match a `.cs` file. Inspecting the
file proves that the rule can't load for C#. That the desktop app might load path-scoped rules differently from
headless is speculation with no evidence. Whether to add a red-first run before the change is a test-design choice,
which the out-of-scope line covers (exact test cases).

### R4-14 · nit · scope and slicing

Task 16 · Change, formatter bullet: Adding `.editorconfig` and `dotnet format` to the formatter examples goes beyond
the requirement. The user asked for the rule to *load* for C# and other common languages, and this edit changes its
body for one language only. It is cheap, but it also pushes the rule further past its aim (see the line-count
finding). Scenario: Each later language request adds its own formatter example, and the language-neutral bullet
becomes a list that grows toward the 50-line cap.

### R4-15 · minor · decisions

Task 16, Change ("one per line as the list has them" … "The rule stays under its 30-line aim"): The instruction cannot
be followed as written: `claude/rules/writing-code.md` is already exactly 30 lines (`wc -l`), and
`bin/check-md-limits` counts front matter toward a rule's 30/50, so 11 more globs one per line take it to about 41.
The executor's question: "Do I go over the aim and pin the file's length, switch to a brace glob like `/*.{cs,go,rs}`
(Claude Code's support for it is unverified, and `rule-globs.md` says a glob that never matches fails silently), or
drop languages from the user's 'C# plus the common languages' ruling?" Each option builds something different, and the
last one belongs to the user. Scenario: The executor keeps "one per line". The rule reaches about 41 lines, the plan's
own claim is false and check-md-limits gives a length advisory. Or the executor saves lines with a brace glob that
Claude Code doesn't expand. Then the rule stops loading for every language, Kotlin and TS included, with no error.
Refuted: Downgraded from major by the verifier. The facts hold. `claude/rules/writing-code.md` is exactly 30 lines,
front matter included, and `bin/check-md-limits` counts a rule against 30/50. So eleven one-per-line globs make about
41 lines, and "stays under its 30-line aim" cannot be true. I downgraded it because the fix is cheap and checkable.
The plan's "one per line as the list has them" is explicit, and 41 lines is still under the hard limit of 50, so the
obvious path is to go over the aim. That trips only an advisory, which the executor settles by pinning the length or
rewording the claim. A reviewer sees the choice in the diff. If an executor tried a brace glob, the plan's own load
test on `.cs` and `.go` files would catch it. Dropping languages contradicts the explicit list, so no executor has to
make that call.

### R4-16 · major · decisions

Task 15, Change, *The window* ("with none, at the plan's first appearance") and Tests, *Real data*: "The plan's first
appearance" has two readings that give different windows: the commit that added the plan file (`git log
--diff-filter=A`; for this plan 58d4816, 2026-10-16), or the earliest transcript `tool_use` that names the plan's
basename. The executor's question: "Is first appearance measured from git history or from the transcripts?" The
real-data test ("from the plan's first appearance to now") fits either reading. Both `window.start` and the first
entry of every later plan depend on the answer, and the stored windows cannot be changed afterwards. Scenario: With
the git reading, a plan that is written and only committed with its implementation gets a first appearance at that
commit. The window is then near zero, `HEAD` is no newer than the start, and `record` exits 1 or records nothing. With
the transcript reading, a plan first committed weeks earlier starts at a point whose transcripts may already have been
removed after 30 days. Two executors produce entries that disagree on every plan.
Fixed: first appearance is the earliest in-scope transcript record naming the plan's basename, never git history.

### R4-17 · minor · decisions

Task 15, Interfaces (the `stages` key `issue`) and Change, *Stages* / *The window*: The entry format has an `issue`
stage that the scoping rule can never fill. A session counts only if a `tool_use` inside the window names the plan's
basename. The `writing-issues` session (started by `ai issue`) runs before the plan file exists and never names it.
The executor's question: "Should the issue session count? If so, how is it linked to the plan: the issue number, the
session before the `writing-plans` one, or a wider window?" Task 15d reads this format to judge stages over time.
Scenario: Every entry records `issue` as zero tokens and zero cost. Task 15d's cut-candidate pass then sees the issue
stage as free, or as never used, and either misses its cost or proposes cutting it. Changing this later means
re-recording entries whose transcripts are gone after 30 days.
Refuted: Downgraded from major by the verifier. The gap is real. The staged workflow runs the issue stage in its own
clean session before the plan exists, and `writing-issues` hands off by printing `ai plan …`. That session never names
the plan's basename, so the scoping rule leaves it out and the `issue` stage holds only stray `writing-issues` calls
made inside plan-naming sessions, such as Task 13's follow-up filing. I downgraded it because the plan already has a
checkpoint for exactly this: the Revisit right after the first real entry is told to "Check that each stage's work
lands in its stage" and to fold the answer in. Task 15d, the only consumer that judges stages over time, is a sketch
to be detailed later from real entries. So the gap is cheap to settle at the Revisit, before anything is built on it.

### R4-18 · minor · decisions

Task 15b, Files (`claude/docs/work-contexts.md` § *An approval covers one action, not a policy*) and the 2026-11-05
Approvals bullet "without asking each time": The plan puts a standing, no-ask commit-and-push yes into the one section
whose rule is "Ask again, every time". The same section also says "At every level, the workflow skills never commit on
their own" and "`reviewing-in-rounds` commits only after the user's yes". The plan only says the section "gains" a
statement and never says whether those lines are reworded. The executor's question: "Do I amend the 'never commit on
their own' and 'ask again, every time' lines to make an exception for the private log repo, and where does a standing
exception live, given the global CLAUDE.md's 'An approval covers what it names'?" Scenario: The executor appends the
new sentence and leaves the rest. A later session loads work-contexts.md and reaches the new skill step ("run …
without asking"). It now holds two directly conflicting instructions, so it asks before every `record` or `note`, or
declines to push. That breaks the 'after every plan, without asking' behaviour the user approved, and nobody notices
until the log repo stays empty.
Refuted: Downgraded from major by the verifier. The tension is real. Lines 78-88 of `work-contexts.md` say "Ask again,
every time" and "the workflow skills never commit on their own", and the plan only says the section "gains" a
statement. I downgraded it because the content the plan prescribes is itself an explicit exception: it names the
private log repo, `ai-log` and the user's standing yes. The skill step adds "without asking: the user's standing yes
of 2026-11-05 covers `record` and `note`". A specific, named exception next to a general rule is how the executor
naturally writes it. Rewording the neighbouring lines so they don't contradict it is a choice a reviewer checks in the
diff, and the `check-md-limits` test already reads that section. It is cheap to settle while implementing, not a
costly or unverified foundation.

### R4-19 · minor · decisions

Revisit section, Task 15b Tests *End to end*, and Task 13's 2026-11-05 deviation: The order of the end of the run is
not settled. The first real entry only exists after the final code review's commit (Task 15b end to end). The Revisit
then has to change "what `record` prints" and detail Task 15c. Task 13 deletes the plan right after that same
`record`. The executor's question: "Does the Revisit come before Task 13's delete? If it changes `bin/ai-log`, does
that change get its own code review, commit and second `record` run? Is the Revisit the user's call or mine?" None of
this is in the Approvals, which cover only commits after the final code review. Scenario: The executor runs `record`,
finds the output lacking, edits `bin/ai-log` after the final code review, and commits it straight to `main`. That
change is unreviewed (company and showcase bar) and outside the approved 'committed after the final code review' flow.
Alternatively Task 13 deletes the plan first, and the Revisit's findings and 15c's detail have nowhere to go except an
issue that is filed before they exist.
Refuted: Downgraded from major by the verifier. The ordering gap is real. The first real entry exists only after a
final code review's commit, the Revisit may then change `bin/ai-log`, and Task 13 deletes the plan after that same
`record`. The failure scenario overstates it, though. This repo is personal public, not company, so the 'company and
showcase bar' does not apply. The plan also gives a fallback for most of the Revisit's output: "if this plan ends
first, Task 13's issue carries" Task 15c, and Task 15d stays a sketch. The executor can settle the order in ways the
existing workflow already supports: end a review-and-record cycle after 15b (the plan says "this plan's next final
code review", which allows more than one), or send any change to `record`'s output through the normal task review and
final review before Task 13. It is cheap to settle and visible in the history, so minor.

### R4-20 · minor · decisions

Task 13, first line ("in one commit") vs its 2026-11-05 deviation ("the delete is its own commit on `main`"): Two
plausible readings build different histories. (a) The fold (`staged-workflow.md`, `work-contexts.md`) and the delete
form one commit on `main` after `record`. (b) The fold goes into the run's reviewed last commit and only the delete
follows on `main`. The executor's question: "Is the docs fold part of the code-reviewed branch commit, or of the
separate post-record commit on `main`, and does the 2026-11-05 approval (branch, review, fast-forward) cover a direct
commit on `main` at all?" Separately, the existing closed logs
(`plan-ai-framework-review-findings-*-closed-2026-11-05*.md`) are not in Task 13's Files, yet its test needs `git
ls-files 'plan-ai-framework*'` to print nothing. Scenario: Under reading (a), the new durable doc `staged-workflow.md`
reaches `main` with no code review. Under (b), the fold lands before `record`, which is fine, but then 'in one commit'
is broken. Either way the closed findings logs are left tracked or deleted without a decision, and the test fails or
passes by accident.

### R4-21 · minor · decisions

Task 15b, Change, *At customer level* ("the introspection, from the session alone, is printed only"): Nothing triggers
this behaviour. The skill step says "do what it prints", and at customer level `record` prints only `ai-log: customer
level is deferred, nothing recorded`, which asks for no introspection. The executor's question: "Should the skill step
tell the session to write and print an introspection at customer level anyway, or does customer level get no
introspection until 15c?" Scenario: The step is built literally. A customer-level run prints the deferral line and
stops, so the promised printed introspection never appears. Or the executor adds the instruction to the skill step,
which goes beyond the user's 'one line' exception.

### R4-22 · minor · decisions

Approvals 2026-11-05 ("on every machine") and Task 15, Files ("cloned to `$HOME/.ai-framework-log`"): The approval
covers every machine, but only this machine's clone is planned. The executor's question: "Should `bin/dotfiles`'
Claude init script (`52_claude.sh` / `52_macos_claude.sh`) clone the private log repo, or is it a manual step on each
machine, and where is that documented?" On a machine without the clone, `record` exits 2, and the skill step treats
that as a failure that only goes in the report. Scenario: On the Linux or WSL machine from Task 11, every plan's
completion reports an exit-2 failure from `ai-log`, and no entries are recorded there. The cross-machine data the user
asked for is quietly missing until someone notices.

### R4-23 · minor · decisions

Task 15b, *The trigger* / *The skill step*, and Approvals ("Yes, one line is fine."): The quoted step is about 330
characters, so it wraps to three lines at the 150-character limit, and steps 7–8 are renumbered too. The executor's
question: "Does the user's 'one line' mean one list item or one physical line? Does a three-line step plus renumbering
stay inside that approval?" Per the global rule that an approval covers what it names, this decides whether the edit
is approved as drafted. Scenario: The executor ships the three-line step and treats the approval as covering it. The
user meant a single line, which makes the edit unapproved. Or the executor cuts the step to fit one line and drops the
'failure never undoes the commit' clause.
Refuted: Dropped by the verifier. The plan records the user's yes against this exact item. Task 15 asked "whether Task
15b may add one line to `reviewing-in-rounds` despite 'no skill changes'", the user answered "Yes, one line is fine",
and Task 15b quotes the step under that approval. In that exchange, 'one line' means one addition to the skill as
opposed to a broader rewrite, not one physical line at 150 characters. The plan's own test pins it as "one list item
after the commit step". Renumbering the steps after it follows mechanically from inserting a list item and is not a
separate change that needs approval. No requirement is violated.

### R4-24 · nit · decisions

Task 15, Interfaces, `<id>` ("<commit date, YYYY-MM-DD>"): "Commit date" can mean the author date or the committer
date, and the window uses committer time. The id format is permanent once entries exist, so name the date: the
committer date (`%cI`), in which timezone. Scenario: After a rebase or amend that keeps the author date, an id built
from the author date carries a different date from the window it labels. A later change to the other date would split
one plan's re-records across two ids.
Refuted: Dropped by the verifier. This is an output-format detail, which the out-of-scope line leaves to the code. In
git, "commit date" by convention means the committer date (`%cd`/`%cI`), and the plan already says to take timestamps
through `git log --format=%cI`. The failure scenario also doesn't hold: the id hashes the commit sha, and a rebase or
amend changes the sha, so the id changes whichever date is used. Re-records of the same commit keep both dates. A
reviewer checks the format in the diff.

### R4-25 · blocking · consistency

Revisit · Does a real entry hold what an introspection needs? (with Task 15b Tests 'End to end', Order lines 151-152,
Task 15c/15d 'Sketch:'): The Revisit sits between Task 15b and Task 15c and is gated on 'Task 15b's first real entry'.
That entry is only written by the new step in `reviewing-in-rounds` § Completion, which runs after the final code
review's commit, and so after every task in the run. `implementing-plans` iterates at a `## Revisit` heading between
tasks, before the next batch, and it has no Revisit step after Finish. Scenario: After 15b is checkpointed, the driver
reaches the Revisit heading and, right after it, 15c's `Sketch:` line. Both are mandatory iteration triggers. The plan
agent is asked to judge a real entry that does not exist yet, so it either stalls or details 15c (customer-level
stored text, which the user deferred) without data. The driver then builds 15c, and 15d after it, even though 15d says
'Not built in this plan'. Neither the plan nor the skill has a way to mark a pending Sketch task as skipped for this
run. The alternative is that the run stops for a decision nobody foresaw.
Fixed: 15c and 15d leave the task list for a § Follow-ups section with the Revisit, no status row; Task 13's issue
carries all three.

### R4-26 · minor · consistency

Task 15 · Tests, 'Real data, last' (with Change 'The window'): The real-data check runs `record --dry-run` 'while HEAD
is still the Base: commit, so the window runs from the plan's first appearance to now'. The window rule, though, ends
the window at `<commit>`'s committer time, and uses 'now' only when nothing has been committed since the start. Base
cdf0a77 (2026-11-05T16:28) is newer than the plan's first appearance (58d4816, 2026-10-16), so the window ends at
cdf0a77's commit time, not now. Scenario: The dry run drops every record of the current run, which happens after
cdf0a77 because implementing-plans never commits. The check 'The stages hold this run's work where it belongs' then
fails, or passes vacuously on older sessions, and the price check is done on the wrong sessions.
Refuted: Downgraded from major by the verifier. Downgraded from major. The contradiction is real. The window rule ends
the window at `<commit>`'s committer time, and uses 'now' with --dry-run only 'when nothing is committed since the
start'. The start is the plan's first appearance (58d4816, 2026-10-16), and commits have landed since then. HEAD =
Base cdf0a77 was committed 2026-11-05T16:28, so the dry run's window ends there, not 'now', and this run's later
sessions are dropped. The approach does not rest on this, though. The window rule itself is sound, and only the
real-data check's expectation contradicts it. The executor can settle it while implementing, either by letting
--dry-run end the window now or by changing the check, and the price check on ended sessions is unaffected.

### R4-27 · minor · consistency

Implementation status table, row 'Final code review' (✅ DONE) vs Task 15b Tests 'End to end' and Findings 'The status
table's last row is Final code review': The row is already ✅ DONE from Task 14's and the 2026-11-02 run's reviews, and
no task or Approvals line sets it back to ⏳ PENDING for the 2026-11-05 run over 15, 15b and 16. The stated reason for
the row is that a skipped final review is visible in the plan itself. Scenario: If the run skips its final code
review, the table still shows ✅ DONE. In that case 15b's end-to-end step (`ai-log record` after the commit) never
runs, and nothing in the plan shows it.

### R4-28 · minor · consistency

Task 15b · Files (`claude/docs/work-contexts.md` § An approval covers one action, not a policy): Task 15b only says
the section 'gains' the standing-yes text. The section's title and body say an approval expires with the change, that
you ask again every time, and that 'the workflow skills never commit on their own… `reviewing-in-rounds` commits only
after the user's yes'. After 15b, `reviewing-in-rounds` commits and pushes to the log repo without asking. The global
`CLAUDE.md` says the same thing ('never its neighbour or the next one'). Scenario: An executor appends the new
sentence and leaves the contradicting lines in place. A later session reading the doc sees both 'never commit on their
own' and 'commits and pushes on a standing yes', and may ask every time, defeating the yes, or treat the doc as
inconsistent.

### R4-29 · minor · consistency

Task 15b · Change, 'At customer level' vs Task 15 Change 'Customer level, deferred': Task 15b says that at customer
level 'the introspection, from the session alone, is printed only'. Task 15's customer path prints only `ai-log:
customer level is deferred, nothing recorded`, and the skill step says 'do what it prints'. Nothing tells the session
to write that introspection at customer level. Scenario: At customer level the session follows the printed line, does
nothing, and no introspection is ever produced. That contradicts the 15b sentence, and the user's 'after every plan… a
short introspection'.

### R4-30 · minor · consistency

Task 13 · Files and Tests (deleted files list): The Files list deletes only `plan-ai-framework.md`,
`-review-findings-plan.md` and `-review-findings-code.md`. The repo also tracks
`plan-ai-framework-review-findings-code-closed-2026-11-05.md` and
`plan-ai-framework-review-findings-plan-closed-2026-11-05.md`, and an untracked `…-plan-closed-2026-11-05-2.md`
exists, all produced by the 2026-11-05 log closes. Scenario: The executor deletes the three named files, and the test
`git ls-files 'plan-ai-framework*'` still prints the closed findings files, so Task 13 fails its own test.

### R4-31 · minor · consistency

Task 13 · opening line and 2026-11-05 Deviation; Approvals 2026-11-05 'This run works on branch ai-framework…': Task
13 still opens with 'in one commit', while its 2026-11-05 deviation makes the delete a separate commit on `main` after
the run's last commit has landed and after `ai-log record`. That delete comes after the final code review, which
`implementing-plans` has no step for, and `reviewing-in-rounds` § Completion never stages `plan-*`. The 2026-11-05
Approvals name only commits after the final review plus a fast-forward of `main`, not a later direct commit on `main`.
Scenario: An executor running Task 13 in its batch cannot delete the plan before the final review, because `record`
needs the file, and no step after the review owns the delete. Under 'an approval covers what it names', the direct
commit on `main` has no recorded yes, so the run stops or the delete is left out.

### R4-32 · minor · consistency

Task 13 · Deviation (2026-11-03) open-items list vs Handover step 6 and Approvals: The two lists of what Task 13's
issue carries disagree. Task 13 lists Task 7's conflict 'sent to the user', which was decided and applied on
2026-11-05 (Handover step 5, Approvals), plus 15c and 15d. Handover step 6 lists the audit's Mediums and Lows and
R12-4, which Task 13 omits, and leaves out 15c and 15d. Scenario: The Task 13 executor follows its own section. The
issue then reopens an already settled conflict and drops the audit's recorded Mediums and Lows and R12-4, and those
are lost when the plan is deleted.

### R4-33 · minor · consistency

Task 15 · Change 'The window' ('with none, at the plan's first appearance'): 'The plan's first appearance' is
undefined, and at company level `reviewing-in-rounds` writes `/plan-*.md` into `info/exclude`, so the plan is never in
git history. Task 15 counts company level as built, but its tests use a fixture plan in a personal-style repo.
Scenario: At company level the first `record` for a plan finds no git history for the plan file. Depending on the
executor's guess, the window starts at the epoch (counting unrelated sessions that once named the basename) or at
nothing (exit 1, no session in scope).

### R4-34 · nit · consistency

Implementation status table / Order vs Handover step 0 and implementing-plans resume: The order line places 15 → 15b →
Revisit and 16 'any time', but says nothing about the 🚧 PARTIAL Tasks 5, 8 and 9 or the by-hand Task M.
`implementing-plans` resumes 'from the first task not ✅ DONE' in table order, which is Task 5, not 15. Handover step 0
says this run reviews and builds 15, 15b and 16. Scenario: `ai implement plan-ai-framework.md` resumes on the existing
`ai-framework` branch with `Base:` set, and starts with Task 5's pending headless reruns instead of Task 15. It later
reaches Task M, which only the user can do, and may stop there before Task 16.
Refuted: Downgraded from minor by the verifier. Downgraded. Resuming at Task 5 is not the wrong work. Handover step 1
tells the session to rerun Tasks 5, 8 and 9's unfinished cases ('These close Tasks 5, 8 and 9's 🚧 PARTIAL rows'), and
the 2026-11-05 Approvals cover 'the run started that day over the remaining tasks'. The Order line does place M ('by
hand, any time after 3'), and implementing-plans asks for by-hand steps up front. What remains is wording: step 0
implies the run is only 15, 15b and 16.

### R4-35 · minor · consistency

Approvals 2026-11-05 'From Task 15b on… on every machine' vs Task 15 Files/Interfaces (exit 2 when `AI_LOG_DIR` is not
a clone): The yes and the skill step cover every machine, but only Task 15 clones the log repo, by hand on this
machine. No installer or init step provisions `$HOME/.ai-framework-log` elsewhere, and `record` exits 2 without it.
Scenario: On a second machine, every plan's completion step fails with exit 2 and is only noted in the report. No
entries are recorded there, against the user's 'after every plan… on every machine' intent.

### R4-36 · nit · consistency

Task 16 · Change, 'The rule stays under its 30-line aim': `claude/rules/writing-code.md` is already 30 lines. Adding
eleven `paths:` globs (one per line) plus the formatter examples takes it to about 41, over the 30-line aim but within
the 50 hard cap. Scenario: The executor cannot meet the stated requirement as written, and either trims body lines to
hit it or ignores it. The task should say 'under the 50-line cap' or name what is cut.

### R4-37 · minor · work context

Task 15 § Change (Customer level, deferred; No free text) and Task 15b § Change (At customer level; The mechanical
redaction): Tasks 15 and 15b treat 'not customer by the resolver' as 'free of customer details', but the resolver
sends an unlisted customer repo to company level ('anything else → company'). Task 15c's own sketch admits this: 'a
customer repo not yet in ~/.claude-customers resolves as company'. Yet 15 and 15b ship without the model terms pass.
At company level, Task 15 stores `repo` (`<owner>`/`<name>`) and `plan` (basename) in plain text, along with project-skill
names, MCP tool names and agent types; the folding that would hide these is put off to 15c. Task 15b pushes
model-written prose whose redaction catches only listed names, remotes, folders and fixed shapes. Scenario: The user
starts work for a new client and has not yet added it to ~/.claude-customers. The repo is github.com/clientorg/app.
The work resolves as company, so `ai-log record` commits `"repo": "clientorg/app"`, a plan named after the client, and
the client's project skills and MCP tool names. The introspection then names the client's product, which no redaction
rule matches, and the entry is pushed. This breaks the user's 2026-11-05 decision for the log repo, 'Still free of
customer details'. The work-contexts.md text added in 15b ('at customer level nothing is recorded') also stops being
true. The fix is cheap and should come before 15b: hash or fold `repo` and `plan`, fold project and MCP names at every
level, or have `record` warn when the origin's owner is neither the personal account nor the company org.
Refuted: Downgraded from major by the verifier. The leak path is real but smaller than the finding claims, so it is
downgraded from major. In Task 15b the mechanical redaction already covers 'the work repo's remotes' hosts, owners and
names, and its folder's name and those above it up to $HOME'. So an unlisted client's owner and repo name
('clientorg', 'app') are scrubbed from the pushed introspection prose. What actually leaks is the JSON's plain `repo`
and `plan` fields and project-skill and MCP names. They go to the user's own private log repo, and only when the user
has not listed a customer that the whole guard framework depends on them listing; that same mistake would also let
Claude commit and push to the client repo. The user has also said they have no customer at the moment, and Task 15c
already names this gap. It is still real against the 'Still free of customer details' decision and cheap to settle
while implementing: hash `repo` and `plan`, or warn when the owner is neither the personal account nor the company
org. That makes it minor, not an approach-level assumption.

### R4-38 · minor · work context

Task 13, the 2026-11-05 deviation, and § Approvals (2026-11-05 blocks): The deviation makes the plan's delete a
separate commit straight on `main`, after the run's last commit has landed. It also files the follow-up GitHub issue
'on the user's yes'. Neither write appears in the 2026-11-05 bulk approvals. That block covers only 'work on branch
ai-framework, committed after the final code review, main fast-forwarded, pushed and CI watched', and the 2026-11-02
precedent says such a bullet replaces the 2026-10-30 'commit to main' yes for the run it covers. This breaks the
global rule 'An approval covers what it names … Ask in bulk, up front'. Scenario: The executor reaches Task 13 and
finds that nothing approves a direct commit and push to `main` outside the fast-forward, or filing the issue. It has
to stop mid-run to ask, which bulk approval exists to prevent. Or it reads the 2026-10-30 'commit to main' bullet as
still in force and pushes without an explicit yes. Fix: add both writes, by name, to the 2026-11-05 Approvals block.

### R4-39 · minor · work context

Task 15 § Tests, Real data ('Record warnings here') and § Change (Drift degrades loudly): The plan is a tracked file
in a personal public repo, and the real-data step copies the dry run's warnings into it. The 'No free text' bar covers
entry fields, but nothing limits what a warning line may contain. The obvious way to word one, such as 'not JSON:
`<file>`:`<line>`' or an unparseable findings heading, includes a transcript path or finding text. A transcript path
encodes the session's cwd as the project dir name. Scenario: During the dry run, a subagent transcript has a truncated
line. The warning gives its path, ~/.claude/projects/-Users-andrelin-`<client-folder>`-…/…jsonl. That path is either the
user's $HOME, which the grep check rejects but the warning list may not be grepped for, or a sibling project whose
folder name identifies a customer. The executor pastes the warnings into plan-ai-framework.md and commits them to the
public repo. Fix: say that warnings name only the kind of source and a count, never a path or quoted text, and apply
the same `$HOME`, email and ~/.claude-customers grep to what gets recorded.
Refuted: Dropped by the verifier. The warnings list is a field of the entry. Task 15's 'No free text' bar applies to the
whole entry: 'no prompt, question, message, tool input or output, path, branch, commit message or finding text'. So a
warning naming a transcript path or quoting a findings heading already breaks a stated requirement, and the reviewer
can check that in the diff. The real-data step also says 'Record warnings here, never transcript content'. How exactly
a warning line is worded is an output-format choice, which is out of scope.

### R4-40 · minor · work context

Task 15 § Tests (personal origin `git@github.com:andrelin/x.git`): The fixture's personal origin points at a real host
and the real personal account. To resolve the level, Task 1's resolver runs `gh repo view --json visibility` for
`andrelin/x`. That is a live platform read on every test run, which a local fixture or stub would replace, and the
result depends on the network and on whether that repo happens to exist. Scenario: On an offline machine, in CI
without gh authentication, or after someone creates andrelin/x, the level comes out personal public, personal private,
or something else again. The level-dependent assertions then flip, or the run quietly queries GitHub. Fix: make the
resolver's visibility lookup stubbable, or use an origin it can resolve locally, so the tests never touch the
platform.
Refuted: Dropped by the verifier. Refuted against the repo. `claude/hooks/work-context.sh` contains no visibility
lookup: grep finds no 'visibility', 'gh repo view', 'public' or 'private'. Its `level` output for an andrelin origin
is simply `personal`. test/test_work_context.sh already asserts `https://andrelin@github.com/andrelin/x.git|personal`
with no platform call. So the fixture origin never queries GitHub, and the level cannot flip with the network or gh
authentication.

### R4-41 · nit · work context

Task 15b § Change (The skill step) vs § Approvals 2026-11-05 ('at every level'): The step runs 'once the commit has
run' and 'A declined commit records nothing', yet the standing yes is worded 'at every level'. At customer level
Claude never commits: the commit is drafted and the user runs it. So the step's trigger does not exist at customer
level, and the wording leaves unclear whether Claude should still run `ai-log record` there after the user commits.
Scenario: After a customer-level code review, an executor following the skill literally either skips `record`, since
no commit 'ran' in the session, or runs it after the user's own commit. Either way the outcome is the same deferral
line, so nothing leaks, but the skill text and the work-contexts.md text describe a step that cannot fire as written.
Fix: say what happens at customer level, for example 'at customer level, after the user's commit, run it anyway: it
prints its deferral line'.

## Round 5

### R5-1 · major · grounding

Task 15 § Interfaces (entry `repo`, `skills_outside`, `tools`) and § Change *Customer level, deferred*; Approvals
block 'Added 2026-11-05 by the iteration that detailed Task 15': With customer level deferred, Task 15's only
protection is that `work-context.sh level` prints `customer`. But `~/.claude-customers` is machine-local, and the plan
admits it in 15c's notes: a customer repo not listed there resolves as company. At company level the entry stores
`repo` as `<owner>/<name>` in clear, plus unfolded MCP tool names, project-skill names and agent-type names. The
standing yes covers 'every level and every machine', and the step pushes without asking. This breaks the user's
requirement that the log stay 'free of customer details'. Once pushed, it can only be removed by rewriting history in
the log repo. Scenario: On a second machine with no `~/.claude-customers` yet, or before the user lists a new client,
a plan in `git@gitlab.client.example:client/app.git` finishes its code review. `ai-log record` resolves it as company,
writes `"repo": "client/app"` and `mcp__client-jira__*` tool names, and pushes them to `andrelin/ai-framework-log`. A
simpler approach: write `repo` and unfold names only when the owner is `andrelin` or `uptimeconsulting`, and fold to
`other` otherwise. That moves the narrow part of 15c's folding into 15.
Fixed: `record` defers, as at customer level, any origin whose owner is neither `andrelin` nor `uptimeconsulting`;
a test covers an unlisted company-resolving origin.

### R5-2 · major · grounding

Task 15 § Change *Cost, an estimate* and § Interfaces `tokens` (model → `input`, `output`, `cache_read`,
`cache_creation`): The price table charges cache writes at the '5-minute cache write' rate. Checked in a real
transcript under this machine's Claude Code: every cache write was 1-hour TTL
(`message.usage.cache_creation.ephemeral_1h_input_tokens` summed to 269047, `ephemeral_5m_input_tokens` to 0). 1-hour
writes cost 2x input, against 1.25x for 5-minute ones. § *What the transcripts hold* never mentions the TTL split, and
the stored schema keeps only a single `cache_creation` count. So stored entries can't be re-priced correctly later,
which Follow-up 15d plans to do from their tokens. Scenario: Opus sessions with heavy cache creation come out well
below `cost-state` `costUSD`, and the real-data price check fails. Fixing that takes a schema change, not just a price
edit, and if any entry has already been written under `schema: 1` its dollars are unrecoverable. The fix is to store
`cache_creation_5m` and `cache_creation_1h` per model and price each one.
Fixed: tokens store `cache_write_5m` and `cache_write_1h` from `usage.cache_creation`, each priced at its own rate.

### R5-3 · minor · grounding

Task 15 § Change *The window* and *Stages* (`writing-issues` → `issue`): The window starts at the plan's first
appearance: the earliest in-scope record whose `tool_use` input names the plan's basename. A session also counts only
if it names the plan. The `writing-issues` stage comes before the plan file exists and never names it, so its records
fall outside the window or outside scope. The `issue` stage is therefore always empty. That contradicts the four-stage
evaluation it exists for, the user's 'evaluate what works'. Scenario: An issue written in one session and planned in
the next records `issue` with zero tokens, zero turns and zero cost. The introspection then judges `writing-issues` as
free, and Follow-up 15d might list it as a cut candidate or miss its cost entirely.

### R5-4 · minor · grounding

Task 15 § Change *Reviews, each counted once*: A review section's `key` hashes its kind, its first row and its first
finding's heading. Rows carry no date (`| 1 | 5 | 0 | 0 | 8 | 5 | 0 |`), and headings follow the pattern
`R1-1 · <severity> · <lens>`. So two different review logs of the same plan and kind can easily share a key, most likely when
round 1 had no findings and therefore no heading. The second log is then treated as a continuation of the first.
Scenario: A plan gets a second code-review run whose round 1 has the same counts as the first run's. Its key matches
an earlier entry, so only the rows beyond what that entry counted are added, and the new review is undercounted or
dropped. Adding the findings file's name or its close date to the key would separate them.

### R5-5 · minor · grounding

Task 15b § Files (`claude/docs/work-contexts.md` § *An approval covers one action, not a policy*); 2026-11-05
Approvals block: Task 15b only adds a line to that section. The section's existing text stays: 'Ask again, every time'
and 'At every level, the workflow skills never commit on their own'. The global `CLAUDE.md` § *Approvals* also says an
approval never covers 'the next one'. After the change, the skill step commits and pushes on a standing yes, which
those sentences forbid. Nothing in the plan rewords them. Scenario: In a later session, an agent running
`reviewing-in-rounds` reads the global rule and `work-contexts.md`, decides the 'standing yes' in a skill line can't
override them, and asks before every `ai-log record`, or declines to run it. That defeats the trigger. The 'never
commit on their own' sentence also becomes false documentation.

### R5-6 · minor · grounding

Task 15b § Change *At customer level*: The plan says that at customer level 'the introspection, from the session
alone, is printed only'. But `record` prints only its deferral line, and the skill step says 'do what it prints'. No
instruction ever reaches the session to write an introspection at customer level. Scenario: After a customer plan's
drafted commit runs, the session sees `ai-log: customer level is deferred, nothing recorded` and stops. No
introspection is printed, contrary to the plan's claim. Either the deferral line has to carry the introspection
prompt, or the claim should be dropped.

### R5-7 · minor · grounding

Task 16 § Change ('The rule stays under its 30-line aim'): This claim is wrong. `bin/check-md-limits` counts front
matter toward file length (its own comment says so: 'inside a fence or front matter, still counts').
`claude/rules/writing-code.md` already counts 27 lines. Adding 11 globs, one per line, brings it to about 38, over the
30 aim though under the 50 cap. Separately, the user's report came from a desktop session, but the test is headless
CLI only. That leaves unverified whether the desktop app loads `paths:` rules the same way, so the reported failure
isn't actually reproduced. Scenario: The executor adds the globs, and the checker passes the hard cap while the file
sits past its aim. Meanwhile the user's desktop `.cs` session may still not load the rule if the desktop app's
path-rule loading differs, and the plan would still report the task done.

### R5-8 · minor · grounding

Task 15 § Change *The window* (a session is in scope when its `cwd` is the work repo or below it): The scope rule
counts only sessions whose cwd is in the work repo. The plan's own headless test runs execute in a `mktemp -d`: Task
8's batteries, Task 14 and 16's scenario pairs, and 15c's customer-pass scenario. So do any worktrees created outside
the repo. All of these drop out of the entry, though they are real costs of the plan. Scenario: A run whose biggest
cost is a 58-case headless battery (about $39 in the handover) records only the orchestrating session's cost. The
introspection then misjudges which stage or skill is expensive, which is exactly the 'not pulling their weight'
question the user asked.

### R5-9 · nit · grounding

Task 15b § Change *The mechanical redaction* (the work repo's owners and names, its folder names up to `$HOME`):
Redaction runs at personal level too. In this repo it would replace `dotfiles` and `andrelin` everywhere in the
introspection, even though both are the user's own and the log repo is private. Scenario: A personal introspection
reads '[repo] commit' and '[customer]/[repo]' where it means the framework itself, which makes cross-session reading
in 15d harder.

### R5-10 · nit · grounding

Task 13, first paragraph and its 2026-11-05 deviation: 'After every other task, M included, in one commit' sits beside
the deviation's 'the delete is its own commit on `main`'. The task now takes two commits (the fold into durable docs,
then the delete), but the opening line was never updated. Scenario: An executor reads 'in one commit' and deletes the
plan in the same commit as the fold. `ai-log record` on that commit then finds no plan file and exits 1.

### R5-11 · minor · scope and slicing

Task 15, Tests › Real data, last; Follow-ups › Revisit: The riskiest assumption comes last. The whole entry schema
rests on a single 2026-11-05 field inspection of the transcripts: stage attribution through attributionSkill or the
latest Skill call or a slash-prompt record, nested plan reviews, Workflow agents, plan-basename scoping, and the price
table matching cost-state. Yet the first contact with real transcripts is the last step of Task 15, after every
fixture-driven feature is built. The check of whether a stage's work lands in its stage is deferred further, to the
Revisit, after 15b. Scenario: On this plan's real transcripts, a nested `reviewing-in-rounds plan` called from inside
`implementing-plans` lends its attributionSkill to the implementer's tokens, or a resumed session's records sit
outside the window. The fixtures pass, because they encode the same assumption, so the defect only surfaces after the
stages, reviews and window code have all been built on it. A thin dry-run spike at the start of Task 15 would expose
this before the rest is built: real transcripts, per-stage tokens and the price check against cost-state.
Refuted: Downgraded from major by the verifier. Downgraded. The real-data dry run is inside Task 15, before anything
is committed or recorded: its checks ('the stages hold this run's work where it belongs' and the price check against
cost-state, 'fixed before going on') gate the task, so a wrong attribution rule is found while it is still an
uncommitted script change, not after later tasks are built on it. The field shapes come from a real inspection under
2.1.309, not a guess. The nested-plan-review risk is named in the Revisit. Moving the dry run to the start of the task
as a spike is a cheap ordering choice that the executor can make. It is not a costly reversal.

### R5-12 · minor · scope and slicing

§ Approvals (2026-11-05 blocks); Task 13 deviation: The 2026-11-05 bulk approvals for 'the remaining tasks' leave out
writes that Task 13 needs. Filing the open-items GitHub issue is still 'on the user's yes'. The Task 13 deviation also
makes the delete its own commit on `main` after the run has fast-forwarded. The 2026-11-05 run approval only covers
working on `ai-framework`, committing after the final code review and fast-forwarding `main`. It does not cover a
later direct commit to `main` that has no review. Scenario: The executor reaches Task 13 after the run's fast-forward.
It has two writes that nobody approved up front (`gh issue create` and a direct commit plus push to `main` deleting
the plan), so it stops mid-run. That breaks 'ask in bulk, up front'. Alternatively it treats the 2026-10-30 'commit to
main' bullet as still live, though the 11-05 block says the run's commits go through `ai-framework` 'as for Task 14'.
Refuted: Downgraded from major by the verifier. Partly stands, downgraded. It is true that filing Task 13's issue is
still 'on the user's yes', and none of the 2026-11-05 bulk approvals covers it. That goes against 'ask in bulk, up
front'. But the run cannot reach Task 13 without stopping anyway: the plan's order puts 13 after M, and M is done by
the user by hand and is still pending. So the missing approval adds one question at a stop the plan already forces.
The direct commit to main is arguably covered by the 2026-10-30 'commit to main, for the rest of this plan' bullet.
The 11-05 run bullet replaces that only for the run's own commits ('as for Task 14', which itself cites the 10-30
bullet). This is cheap to settle by adding one approval bullet.

### R5-13 · minor · scope and slicing

Task 13 deviation (2026-11-05) vs Task 13 header and Files: The 2026-11-05 deviation makes the delete its own commit
on `main`, after the run's last commit and its `ai-log record`. It does not say where Task 13's other output goes:
`staged-workflow.md`, the `work-contexts.md` additions and the issue. The header still says 'in one commit', and the
order still says 13 comes after M, which is by hand and pending. Scenario: There are two readings. (a) The executor
builds the docs fold inside the run's reviewed commit. That puts Task 13 before M, against the plan's order. (b) The
executor puts the fold in the post-record delete commit. Then new durable docs land on `main` without code review, and
`ai-log` never records them. Either way the executor has to guess how the task is sliced, and the run can't end in a
reviewed state while M is still the user's.
Refuted: Downgraded from major by the verifier. Stands as an ambiguity, downgraded. The most natural reading of 'the
delete is its own commit on main, after the run's last commit' is that Task 13's single commit (the docs fold plus the
delete) lands on main after the run and after the 15b record. That keeps the header's 'one commit' and the 13-after-M
order. The repo is personal public, so docs reaching main without a code review breaks no level bar, and ai-log not
recording the fold is the intended effect of recording before the delete. The guess is real but cheap to settle in a
sentence. It does not stop the executor.

### R5-14 · minor · scope and slicing

Task 15, Change › The window / Reviews: Task 15 is billed as 'counts only', but it still builds machinery for cases
that only arise once there are multiple entries per plan, before any real entry exists. Examples: non-overlapping
windows chained through `after` and `plan_key`, plus review-section `key` hashing that counts only the rows an earlier
entry hasn't counted. These are the costliest parts to get right, and the Revisit may reshape them once real entries
show what an introspection needs. Scenario: The Revisit finds that per-review attribution needs a different shape, for
example per-round instead of per-section. The key and incremental-count logic and its tests are then rewritten. A
first slice that records one entry per commit, with a window from the plan's first appearance, would meet the user's
'after every plan' requirement and defer the dedup until a second entry exists.
Refuted: Dropped by the verifier. Dropped. Multiple entries per plan come up at once, not in some later phase. 15b
records after every code-review commit with a plan, and this plan has already had several such runs (Task 14's, then
the remaining tasks'). Without non-overlapping windows and review keys, the second entry for any plan would count
every token and every review row twice. The machinery was added on purpose by plan review R2-3, R2-25 and R2-35 to
meet the user's cross-session requirement. Deferring it would make the first multi-run plan's data wrong.

### R5-15 · minor · scope and slicing

Task 16, Change: The task says 'the rule stays under its 30-line aim', but `claude/rules/writing-code.md` is already
exactly 30 lines. Adding 11 globs one per line, as specified, plus the formatter wording, takes it to about 41 lines.
The aim and the slice conflict. Scenario: `bin/check-md-limits` warns past the 30-line aim. The executor then has to
choose between dropping languages the user asked for, cutting body text the task doesn't name, or breaking a
constraint the plan says holds. A brace glob such as `/*.{cs,go,rs,...}` (if the matcher supports it, which nothing
has checked) or an accepted aim overrun should be decided in the plan.

### R5-16 · nit · scope and slicing

Task 16, Tests: The test proves only that the fixed rule loads headless in the CLI. It has no baseline showing that
`.cs` failed to load before the change, though `claude/docs/rule-globs.md` says to take the baseline by moving the
file aside. It also never checks the surface where the user saw the failure, a desktop session. Scenario: The desktop
app loads path rules differently, for example not on files opened through its own viewer. The CLI test passes and the
task is marked done, but the user's reported failure in a desktop session persists. The plan should either state that
the desktop surface is out of scope or name a by-hand desktop check.
Refuted: Downgraded from minor by the verifier. Downgraded. The baseline run and the exact checks are test design,
which the out-of-scope line leaves to the code. The cause is plain from the file: its paths list has no .cs glob, and
rule-globs.md says a glob that never matches fails silently, so there is no hypothesis left to prove with a baseline.
The desktop concern is speculative, since nothing shows the desktop app loads rules differently from the CLI. Saying
which surface is in scope is at most a wording point.

### R5-17 · nit · scope and slicing

Task 15b, Tests › End to end; Task 13 deviation: The end-to-end result ('record here only that it ran, and the id')
has to be written into the plan after the run's final commit, because the step runs after that commit. The plan file
is then deleted in Task 13's separate commit, so the only record of 15b's acceptance test is either an uncommitted
edit or lost. Scenario: After the final code review commit, the session writes the entry id into
`plan-ai-framework.md`. That edit is either swept into the delete commit and so never visible on `main`, or forces an
extra unreviewed commit. 15b's status row is never backed by a committed result. Naming Task 13's issue or the log
repo's entry as the record would close this.
Refuted: Downgraded from minor by the verifier. Downgraded. The durable record of 15b's end-to-end run is the entry
and introspection that run pushes to andrelin/ai-framework-log, which is the very output the test checks. A plan-file
line saying that it ran, plus the id, is bookkeeping in a file Task 13 deletes anyway, as it does every other status
row. At most, the wording should name the log repo or Task 13's issue as where the id is kept.

### R5-18 · nit · scope and slicing

Task 15, Tests › Real data: The real-data dry run expects 'the window runs from the plan's first appearance to now',
but this plan dates from 2026-10-16 and transcripts are deleted after `cleanupPeriodDays` (30). On 2026-11-05 the
earliest sessions are at or near that edge, so the 'first appearance' is just the oldest transcript that survived, and
the plan doesn't say so. Scenario: The executor checks that the window starts at the plan's real first appearance,
finds a later date, and spends time chasing a phantom bug in window resolution.
Refuted: Dropped by the verifier. Dropped. git log shows plan-ai-framework.md was added on 2026-10-16, which is 20
days before 2026-11-05. ~/.claude/settings.json does not override cleanupPeriodDays, so the default of 30 applies. The
earliest transcripts naming the plan therefore still exist and are not at the cleanup edge. Also, the plan defines
'first appearance' as the earliest in-scope transcript record that names the basename, not the plan's creation date,
so there is no gap with the definition for the executor to chase.

### R5-19 · minor · decisions

Task 15 · The entry (`repo`, `plan`, `skills_outside`, `plugins`, `tools`, `agents`) and § *No free text*; Follow-up
15c notes: Task 15 writes the repo's `<owner>/<name>`, the plan's basename, project-skill names, custom agent types,
every MCP tool name and every installed plugin and marketplace into the JSON without redaction at company level, and
pushes it. Follow-up 15c says itself that a customer repo not yet listed in `~/.claude-customers` resolves as company,
and that these names can identify a customer. The user's decision for the log repo was 'Still free of customer
details: redacted copies'. The executor would ask: at company level, are `repo`, `plan` and the skill, agent, MCP and
plugin names stored as they are, folded, or left out until 15c? Once pushed, they stay in the log's git history.
Scenario: A customer repo `acme-corp/billing` is not yet in `~/.claude-customers`, so it resolves as company. Its plan
is `plan-acme-invoice-migration.md` and it uses an `mcp__acme_jira__*` tool and a project skill `acme-deploy`.
`record` pushes `"repo":"acme-corp/billing"`, the plan name and those tool and skill names to GitHub. Removing them
later means rewriting the log repo's history.
Refuted: Downgraded from major by the verifier. Downgraded. The plan does decide this, so the executor has nothing to
ask: § No free text explicitly allows model ids and tool, skill, agent-type and lens names, and the entry schema names
`repo` and `plan`. Follow-up 15c's own notes say folding those names waits for 15c. The case of a customer repo
resolving as company is a risk the plan knowingly accepts, and the user's own decision limits it: they have no
customer at the moment and deferred the customer part. Listing a client in `~/.claude-customers` is how such a repo
gets handled. The log repo is also private. The gap from the 'free of customer details' wording is real but small for
now, so minor.

### R5-20 · minor · decisions

Task 15b · Files (`claude/docs/work-contexts.md` § *An approval covers one action, not a policy*) and the skill step;
§ Approvals 2026-11-05 'From Task 15b on': The plan adds a standing, every-level, never-ask commit-and-push to the
section whose heading and body say an approval 'applies to the change in front of them and expires with it'. In that
same section, line 85 says 'At every level, the workflow skills never commit on their own'. The global `CLAUDE.md`
adds that 'An approval covers what it names — never its neighbour or the next one'. The plan says what the section
gains, but not whether line 85 and the heading are amended or the standing yes is framed as an exception. The executor
would ask: is the 'never commit on their own' line rewritten, or does the new text sit beside it as a carve-out, and
does the global `CLAUDE.md` need a pointer? Scenario: A later session at company level reaches step 7 of
`reviewing-in-rounds`. It reads `work-contexts.md`, where 'never commit on their own' and 'expires with it' still
stand, plus the global approvals rule. It stops to ask before `ai-log record` commits and pushes, or it declines. The
trigger then fails silently in practice, and no entries collect for the Revisit or for Task 15d.
Refuted: Downgraded from major by the verifier. Downgraded. The tension exists: `claude/docs/work-contexts.md` line 80
says an approval 'expires with it', and line 85 says 'At every level, the workflow skills never commit on their own'.
But the plan already says what the section gains: a standing yes for `ai-log` writes to the private log repo. Wording
it as a carve-out next to line 85 is a doc edit the executor can make and a reviewer can check in the diff. The
failure scenario is also weak. The skill step Task 15b writes says explicitly 'without asking: the user's standing yes
of 2026-11-05 covers `record` and `note`', and that step names the approval, so it satisfies the global rule that an
approval covers what it names. A later session following the skill would not stop.

### R5-21 · minor · decisions

Task 15b · Change, 'At customer level `record` prints only its deferral line, so the introspection, from the session
alone, is printed only'; Task 15 · Customer level, deferred: There are two readings, and they build different things.
(a) At customer level the model still writes the introspection and shows it in chat. (b) Nothing happens. The skill
step says only 'do what it prints', and Task 15 fixes the customer output as exactly `ai-log: customer level is
deferred, nothing recorded`, which tells the model to do nothing. So reading (a) has no mechanism unless the deferral
line or the skill step gains an instruction, and that changes an interface Task 15 has fixed. The executor would ask:
at customer level, should the model write an introspection into the chat? If so, does the instruction go in the
deferral line or in the skill step? Scenario: The executor builds Task 15's line word for word and Task 15b's one-line
skill step. On customer work the session prints the deferral line and moves on. The customer-level printed
introspection that the Change claims never appears, and no test catches it, because no test covers customer level in
15b.
Refuted: Downgraded from major by the verifier. Kept as a real ambiguity, but downgraded. The sentence 'the
introspection, from the session alone, is printed only' has no mechanism: the deferral line is fixed and the skill
step only says 'do what it prints'. Settling it is cheap: add one clause to the skill step, or drop the sentence.
Customer level is explicitly deferred to 15c, and the user has no customer now, so building either reading costs
nothing to change later.

### R5-22 · major · decisions

Task 13 · Deviation (2026-11-05), with § Approvals 2026-11-05 'This run works on branch `ai-framework`…' and Order (M
before 13): The deviation makes the delete 'its own commit on `main`, after the run's last commit has landed there'.
Task 13 still opens with 'in one commit', and the 2026-11-05 approval replaces commit-to-`main` with branch, final
code review, then fast-forward. It is open whether Task 13's fold (`staged-workflow.md`, `work-contexts.md`) is built
and code-reviewed inside the run, with the delete following on `main`, or whether both happen after the final code
review. In the second case, no 2026-11-05 approval covers either. Task M is by hand and must come before 13, so the
run may not reach 13 at all. The executor would ask: is Task 13's fold part of the reviewed run on `ai-framework`?
Which approval covers a commit made directly on `main` for the delete (and for the fold, if it falls outside the
review)? Scenario: The executor finishes 15, 15b and 16, and the final code review commits, runs `ai-log record` and
fast-forwards `main`. It then writes `staged-workflow.md` and deletes the plan in a direct commit on `main` with no
review. That breaks the company-style 'reviewed before main' bar the run follows, and none of the 2026-11-05 approvals
names that commit. Or the executor stops mid-run to ask, which is the stop the bulk approvals were meant to prevent.
Fixed: Task 13's fold is built and code-reviewed in the run; only the delete waits for `main`.

### R5-23 · major · decisions

Task 16 · Spec and Tests: The fix rests on an assumption it never checks: that the rule failed to load in the user's
desktop session because of the `paths:` glob. The verification runs headless `claude -p` only. If the desktop app
doesn't load path-scoped user rules the same way, which `rule-globs.md` doesn't cover, adding `/*.cs` passes every
listed test and leaves the user's report unfixed. The executor would ask: is the desktop session part of the pass
criterion, or should a run there (or a check that `.kt` files load the rule on desktop today) come first, to prove the
glob is the cause? Scenario: The executor adds the globs, and the headless runs report `writing-code.md` loaded for
`.cs` and `.go`. The task is marked done. The user opens a `.cs` file in a desktop session again and the rule still
doesn't load, because that surface handles user rules differently. The proving-causes step was skipped.
Refuted: Dropped by the verifier. `claude/rules/writing-code.md`'s `paths:` lists only kt, java, ts, tsx, js, jsx, py,
sh, zsh, kts, `bin/` and `hooks/`. No `.cs` glob exists, so the rule cannot load for a `.cs` file on any surface. The
missing glob is a verified, sufficient cause, not an untested assumption. The user's ruling sets the scope as 'cover
C# plus the common languages', and the task meets it. The idea that the desktop app handles user rules differently is
speculation, with no evidence in the plan or the repo.

### R5-24 · minor · decisions

§ Approvals, 2026-11-05 blocks; Task 13 (issue filed 'on the user's yes'): The 2026-11-05 bulk approvals for 'the run
… over the remaining tasks' leave out Task 13's GitHub issue, which is filed only 'on the user's yes', and the delete
commit on `main`. The global rule says to ask in bulk, up front, for every approval a stretch of work needs. The
executor would ask: is the Task 13 issue filing pre-approved for this run, or is a mid-run stop expected? Scenario:
After the final code review, Task 13 needs to file the issue that carries 15c, 15d and the Revisit before it deletes
the plan. The run stops for a yes that could have been collected with the other 2026-11-05 approvals. If the session
ends there, the plan is left half-folded.
Refuted: Downgraded from major by the verifier. Downgraded. The run must stop before Task 13 anyway: Task M is by hand
('The user runs every step') and must come before 13. So the yes for the issue can be asked at that stop, with no
extra interruption. The plan also states the 'on the user's yes' explicitly rather than leaving it open. The
bulk-approval gap is real but cheap.

### R5-25 · minor · decisions

Task 15 · Files ('cloned to `$HOME/.ai-framework-log`') and § Approvals 'on every machine': The approval and the skill
step run `record` 'on every machine', but only this machine gets the clone. Nothing says whether `bin/dotfiles` or an
init script clones the private log repo on the user's other machines (macOS, Linux and WSL), or whether the user does
it by hand after the first exit 2. That is visible to the user on every other machine. The executor would ask: should
an init script clone `andrelin/ai-framework-log` where `gh` is authenticated, or is cloning by hand on the first
failure the intended setup? Scenario: On the user's second laptop every plan's final code review reports an `ai-log`
exit 2 in the report. No entries reach the log from that machine until the user notices, so cross-session data quietly
misses part of the work.

### R5-26 · minor · decisions

Task 15b · Files, the text `work-contexts.md` gains ('what leaves the machine is counts, durations, tokens, estimated
dollars and versions, and the introspection'): The user-facing statement of what leaves the machine is narrower than
Task 15's schema. Entries also carry `repo` owner and name, the plan basename, model ids and skill, tool, MCP,
agent-type, lens and plugin names. The executor would ask: should the doc list everything the schema holds, or should
the schema shrink to match the doc? Scenario: The user or a colleague reads `work-contexts.md` and believes only
numbers and versions are pushed. In fact repo and plan names and MCP tool names are pushed too, so the doc misleads on
exactly the privacy question it is there to answer.

### R5-27 · minor · decisions

Task 15b · The mechanical redaction (the work repo's remotes' owners and names, folder names up to `$HOME`, hostnames
'never a file name'): Two readings: does the redaction of the work repo's owner, name and folders apply at personal
level too? If it does, introspections about the dotfiles replace every whole word `dotfiles` (the `.` in `.dotfiles`
breaks words) and `andrelin` with `[repo]`, while the JSON beside them keeps `repo` in clear. Separately, the
'hostname but never a file name' rule gives no criterion: `.md`, `.sh` and `.rs` are real TLDs, so `SKILL.md` and
`bin/ai-log` evidence look like hostnames. The executor would ask: should the work repo's names be redacted at
personal level, and which file extensions count as file names rather than TLDs? Scenario: An introspection for this
plan says '`dotfiles_commit` drifted; `work-context.sh` cost 3 rounds'. It is stored as '[repo]_commit drifted; [host]
cost 3 rounds'. The evidence the Revisit and Task 15d rely on becomes unreadable.

### R5-28 · nit · decisions

Task 16 · Change (the glob list): 'C# plus the common languages' leaves Razor and other C#-adjacent files (`.cshtml`,
`.razor`, `.csx`) and C++ variants (`.cc`, `.hpp`) out of the list. The user's ruling names C# first, so the executor
may want to confirm whether .NET project files count. Scenario: The user edits a `.razor` component in a .NET project
and the rule doesn't load, which repeats the original report for the language the task was opened for.
Refuted: Dropped by the verifier. Out of scope. Which extensions count among 'the common languages' is a choice the
executor can make and a reviewer can check in the diff. The user's ruling ('C# plus the common languages') leaves it
open on purpose.

### R5-29 · minor · consistency

Task 15b, Files: `claude/docs/work-contexts.md` § An approval covers one action, not a policy: Task 15b only adds a
paragraph to this section. The section's existing text says the opposite, and the plan never amends or scopes it: "An
approval covers one action, not a policy … Ask again, every time" and "At every level, the workflow skills never
commit on their own … `reviewing-in-rounds` commits only after the user's yes". Task 15b's skill step makes
`reviewing-in-rounds` run `ai-log`, which commits and pushes without asking, on a standing yes. That is a policy-style
approval, and the global `CLAUDE.md` § Approvals line "An approval covers what it names — never … the next one" also
stands unchanged. Scenario: After Task 13 deletes the plan, a later session reaches the new step and reads
work-contexts.md, or the global § Approvals. It finds two contradictory statements in the same section. It either
refuses to run `ai-log record` and asks the user every time, which defeats the standing yes, or it follows the step
and breaks the doc's stated rule. Task 15b should name the sentences it rewords so the doc carries a single rule with
the exception stated in it.
Refuted: Downgraded from major by the verifier. Partly refuted. The conflict is real: work-contexts.md lines 78-88 say
"Ask again, every time" and "At every level, the workflow skills never commit on their own ... `reviewing-in-rounds`
commits only after the user's yes". Task 15b only appends a paragraph and leaves those lines as they are. But the
appended paragraph names the exception itself (reviewing-in-rounds runs ai-log on a standing yes, to the user's own
log repo), and the skill step cites that yes explicitly. A specific stated exception beside a general rule doesn't
stop an executor or a later session, and the fix is cheap and made while writing that paragraph: scope 'never commit
on their own' to the work repo, or reword it as an exception. It isn't costly to reverse and isn't an assumption the
approach rests on, so it is minor, not major.

### R5-30 · minor · consistency

Task 13, Files and Tests (deviation 2026-11-03 R9, unchanged by the 2026-11-05 iteration): The delete list names only
`plan-ai-framework.md`, `-review-findings-plan.md` and `-review-findings-code.md`. Since the 2026-11-05 closes, git
also tracks `plan-ai-framework-review-findings-code-closed-2026-11-05.md` and
`plan-ai-framework-review-findings-plan-closed-2026-11-05.md`, and
`plan-ai-framework-review-findings-plan-closed-2026-11-05-2.md` exists untracked. The text still says "both findings
files". Scenario: An executor deletes the three listed files, and Task 13's own test `git ls-files
'plan-ai-framework*'` still prints the closed findings files. Either the task fails, or the executor improvises which
closed logs to delete outside the Files list. The Files list should cover
`plan-ai-framework-review-findings-*-closed-*.md`.

### R5-31 · minor · consistency

Task 13, opening line vs. its 2026-11-05 deviation; § Approvals (2026-11-05 run bullet): The task still opens with "in
one commit", but the new deviation makes the delete its own commit directly on `main`, after "the run's last commit"
has landed and 15b's `record` has run. The plan doesn't say whether the fold (`staged-workflow.md`, the
`work-contexts.md` additions) goes into that run's reviewed commit or into the delete commit. It also doesn't say
which run's last commit is meant, because Task 13 follows Task M, which is done by hand. The 2026-11-05 run approval
covers commits on `ai-framework` after the final code review, then a fast-forward. It doesn't cover a separate direct
commit on `main`. Scenario: Case 1: the executor folds and deletes in one commit through `reviewing-in-rounds code`.
The completion step then runs `ai-log record plan-ai-framework.md` after the commit that removed the plan, and
`record` exits 1 ("no plan file"). That is exactly what the deviation exists to avoid. Case 2: the executor commits
the delete straight to `main`. That commit sits outside the run's recorded approval scope, so the executor has to stop
and ask.

### R5-32 · minor · consistency

Task 15b, Change: "At customer level `record` prints only its deferral line, so the introspection, from the session
alone, is printed only": The skill step says "run `ai-log record <plan-file>` and do what it prints". At customer
level `record` prints only `ai-log: customer level is deferred, nothing recorded`, which holds no instruction to write
an introspection. Nothing then produces the introspection that this sentence says gets printed. Scenario: After a
commit at customer level, the session runs `record`, gets the deferral line, sees nothing to do and writes no
introspection. That contradicts Task 15b's own statement and the user's "after every plan, a short introspection"
spec. Either the deferral line or the skill step needs to ask for the printed-only introspection, or the sentence
should be dropped.

### R5-33 · minor · consistency

Task 16, Change: "The rule stays under its 30-line aim": `claude/rules/writing-code.md` is 30 lines now, 26 of them
counted by `bin/check-md-limits` (blank lines and headings excluded). Task 16 adds 11 `paths:` globs, one per line,
plus formatter examples, which brings it to about 37 counted lines. That is over the 30-line aim but under the 50 cap.
The plan's claim is unverified and false. Scenario: The executor adds the globs and `bin/check-md-limits` prints the
advisory over-aim line. The task's own stated outcome is then false, and the executor has to choose between trimming
the rule's body, pinning the length, or dropping globs, with no guidance. The plan should state the expected count or
say the aim is knowingly exceeded.

### R5-34 · nit · consistency

Task 13, deviation 2026-11-03 R3 list; Handover item 6: Task 13's list of open items still includes "Task 7's conflict
sent to the user". That conflict was decided on 2026-11-05 (§ Approvals, Task 7's status row, Handover item 5).
Meanwhile Handover item 6, which describes Task 13's issue, lists only the `Deferred:` lines, the audit's Mediums and
Lows and R12-4. It omits follow-ups 15c and 15d and the Revisit question, which § Order, Handover item 0 and §
Follow-ups all send to Task 13's issue. Scenario: An executor who starts Task 13 from the Handover files an issue
without 15c, 15d and the Revisit, and the plan delete then loses them, the very loss the deviation exists to prevent.
One who starts from Task 13's section re-files the already-decided Task 7 conflict as open.
Refuted: Downgraded from minor by the verifier. Downgraded. Task 13's list still says 'Task 7's conflict sent to the
user', which is stale: Task 7's status row, Approvals and Handover item 5 all record it as decided. Anyone filing the
issue sees that at once, so it costs a wording fix. Handover item 6 omits 15c, 15d and the Revisit, but Handover item
0 of the same Handover, § Order, § Follow-ups and Task 13's own section all send them to Task 13's issue. An executor
starting from the Handover reads item 0 first and then works Task 13 from its section, so the loss scenario doesn't
hold. Wording only.

### R5-35 · nit · consistency

Task 15b, Files: Task 15 adds `ai-log` to `README.md` § Scripts and to `tips.md`'s entry 24, describing `record`. Task
15b adds the `note` subcommand but updates only `tips/24_claude_code.md`. That breaks the repo's "Docs ship with the
change" convention for a user-facing script under `bin/`. Scenario: After Task 15b, the README's Scripts line and
`tips.md`'s index describe `ai-log` as `record` only, while the tip documents `note`. The docs disagree, and review
flags it late.
Refuted: Downgraded from minor by the verifier. Largely refuted. tips.md's entry 24 lists only command names
(`sync-claude-deny`, ..., `ai`), so adding `note` doesn't make it disagree with anything. The README § Scripts line is
one sentence per script, and Task 15's executor chooses whether it names `record`. A line describing ai-log
generically needs no change in 15b, and writing-tips, which the convention invokes, would catch a stale line in the
diff. At most a wording nit about adding README.md to 15b's Files list.

### R5-36 · nit · consistency

Task 15, Interfaces: "Produces, for Tasks 15b to 15d"; § Approvals, 2026-11-05 plan-review-fixes bullet: 15c and 15d
are no longer tasks of this run (§ Follow-ups, plan review R4-25), but Task 15 still calls them tasks. The Approvals
bullet records a token yes for a scenario that now belongs to 15c, which this run doesn't build. Scenario: A reader
takes 15c and 15d as tasks that consume Task 15's interface within this run, or takes the token approval as live for
this run, though no status row or Order line includes them.

### R5-37 · major · work context

Task 15b, Change: 'The mechanical redaction' and 'record prints … Pipe it to ai-log note'; 2026-11-05 Approvals, 'at
every level and on every machine'; Follow-up 15c's own note 'since a customer repo not yet in ~/.claude-customers
resolves as company': 15b pushes model-written introspection prose to a remote at company level. Its only protection
is mechanical redaction keyed on `~/.claude-customers` entries and the work repo's own remotes. The plan says itself
(15c) that a customer repo missing from `~/.claude-customers` resolves as company. It still ships the push now and
leaves the terms pass, which is the only defence against names the file does not list, to 15c, which may never be
built (Task 13 only files it as an issue). Scenario: Take a machine with no or an incomplete `~/.claude-customers`,
for example a new work laptop, since the approval covers every machine. A session runs a plan in a customer's repo
whose origin owner is not listed, so the guard resolves it as company. reviewing-in-rounds commits, `ai-log record`
writes an entry, and the introspection names the customer's product, a colleague, an internal tool or an issue title
the model saw. Redaction catches only the origin's host, owner and name, so the rest is pushed to
`andrelin/ai-framework-log` on GitHub. Once in pushed history it is costly to remove, and it breaks the global rule
that customer content never leaves the customer's tree. A fix: hold `note` back at company level until 15c's terms
pass exists, or require that the level is confirmed company (an Uptime-named repo or an owner in
`~/.claude-company-orgs`) before writing prose.
Fixed: with R5-1, no note is stored for a repo outside the user's two owners, so no unlisted customer's prose leaves.

### R5-38 · major · work context

Task 15, Interfaces: the entry fields `repo` (`<owner>/<name>`), `plan` (basename), `skills_outside`, `tools`,
`agents`; Change: 'No free text': 'No free text' lists names it allows (tool, skill, agent-type and plugin names), and
the entry stores `repo` owner and name and the plan basename unredacted. The JSON never passes through 15b's
redaction. Folding identifying names to `other` / `mcp__other` is deferred to 15c. But Task 15 already pushes these at
company level, which is exactly where an unlisted customer repo lands. Scenario: Take a customer repo not in
`~/.claude-customers` that resolves as company. Its entry pushes `repo: "<customer-owner>/<customer-repo>"`, a plan
basename such as `plan-<customer>-migration.md`, project skill names and MCP tool names such as
`mcp__<customer-jira>__…`. All of these are in `andrelin/ai-framework-log`'s history. The 'No free text' test plants
markers only in prompts, questions, tool input/output, the branch and findings, so it never catches this. Either fold
or hash `repo`, `plan` and non-allowlisted skill/tool/plugin names now, or narrow the 2026-11-05 approval to repos
whose company level is positively confirmed.
Fixed: with R5-1, `repo`, the plan name and unfolded names are only ever stored for the user's two owners.

### R5-39 · minor · work context

Task 15b, Files: the sentence added to `claude/docs/work-contexts.md` § An approval covers one action, not a policy:
The durable doc line says 'what leaves the machine is counts, durations, tokens, estimated dollars and versions, and
the introspection, mechanically redacted'. The entry also pushes the repo's owner and name, the plan basename, the
commit sha, and skill, tool, plugin and agent-type names. A reader relying on the doc to judge what goes to the log
repo is misled about what leaves the machine. Scenario: A future session, or the user, checks work-contexts.md to
decide whether running a plan in a sensitive company or misclassified repo is safe to log. It reads 'counts … and
versions', concludes no names leave, and so does not stop. The pushed entry still names the repo and the plan. Fix it
by listing the identifying fields in the doc line, or by removing them from the entry.

### R5-40 · minor · work context

2026-11-05 Approvals block ('at every level and on every machine … commit … and push it, without asking'); Task 15b
skill step ('at every level'); global ~/.claude/CLAUDE.md § Work contexts ('push in any form' forbidden at customer
level): The standing yes and the skill step both say 'at every level', and the skill step is the only place it lives
on after Task 13. The global rule still forbids 'push in any form' at customer level and says a customer's CLAUDE.md
wins. Nothing reconciles the two. Today this is harmless only because 15/15b record nothing at customer level. Once
15c is built, a customer-level session reads two contradictory instructions, and the skill line claims an approval
that a customer tree's CLAUDE.md may override. Scenario: 15c lands and `ai-log` begins pushing at customer level. A
session in a customer tree whose CLAUDE.md forbids data leaving the machine follows the reviewing-in-rounds line
('without asking … at every level') and pushes to the personal log repo, because nothing tells it that the customer's
CLAUDE.md or the global 'push in any form' rule takes precedence. Fix: say 'personal and company level' in the skill
step and the approval wording until 15c is built, and have 15c state the carve-out in the global § Work contexts and
defer to a customer CLAUDE.md.
Refuted: Dropped by the verifier. The user's 2026-11-05 decision, recorded in Task 15 'What text', is explicitly 'at
every level, customer included', so 'at every level' in the approval is what the user ruled, not an oversight. The
global ban on 'push in any form' covers the customer repo's own history and remote. The log clone is the user's
personal repo, which the guard resolves as personal because Task 15 runs git in a subshell `cd` into AI_LOG_DIR. Today
Task 15 records nothing at customer level, so the step never pushes there. The scenario needs 15c to be built, and 15c
is a Sketch follow-up whose precedence over a customer CLAUDE.md gets settled when it is detailed. That makes this a
sketch's missing detail, which is out of scope.

### R5-41 · minor · work context

Task 13, 2026-11-05 deviation ('the delete is its own commit on `main`, after the run's last commit has landed there')
vs Approvals 2026-11-05 ('This run works on branch `ai-framework`, committed after the final code review, `main`
fast-forwarded'): The deviation commits the plan's deletion directly on `main`, after the fast-forward and the `ai-log
record`. The 2026-11-05 run approval names only the branch-then-fast-forward route. The 2026-10-30 'commit to main'
bullet was replaced for the 2026-11-02 run, and it is unclear whether it still applies to this run. The direct-to-main
commit and its push are not named by any current approval, and the global § Approvals says an approval covers only
what it names. Scenario: The executor reaches Task 13 after the fast-forward. It either commits and pushes straight to
`main` without a named yes, or stops mid-run to ask, which defeats the ask-in-bulk-up-front rule. Add 'Task 13's
delete commits directly on `main`, pushed and CI watched' to the 2026-11-05 approval list, or route the delete through
the same branch and fast-forward.
Refuted: Dropped by the verifier. The 2026-10-30 approval is scoped 'for the rest of this plan' and says 'Commit each
change to `main` … push to `origin main` and watch CI'. The 2026-11-02 replacement was explicitly 'for that run' only.
Task 14 (2026-11-05) re-applied the 10-30 first bullet, which shows it is still live. The delete commit on main after
the fast-forward is therefore covered by a named, standing yes. The 2026-11-05 run bullet adds the branch route for
the run's work and does not revoke the commit-to-main yes.

### R5-42 · nit · work context

Task 15b, Change: 'The mechanical redaction' list: Company-level introspections are pushed to a personal repo.
Redaction covers customer entries, remotes, hosts, emails, paths, URLs and tokens, but not people's names.
Company-internal colleague names or the company's internal tooling names, which the model may cite as evidence, pass
through unredacted. This is allowed by the levels table, since company history is the user's, but the plan never says
it chose this. Scenario: An introspection says 'the reviewer (a colleague's name) overrode …' or names an internal Uptime
service, and it is pushed as-is. If that is acceptable, say so in one line. Otherwise the prompt `record` prints
should also forbid people's and internal service names.
Refuted: Dropped by the verifier. The finding says itself that the levels table allows this: company history is the
user's, and the log repo is the user's own private repo. It names no violated requirement, and its scenario is not a
failure. The record prompt already forbids 'quotes from the work'. Asking the plan to state a choice it does not need
to make is unsupported.

## Round 6

### R6-1 · major · grounding

Task 15, Change, Stages bullet (and the Real-data test 'The stages hold this run's work where it belongs'): Stage
attribution rests on an unchecked assumption: that each review stage starts with a `Skill` call to
`reviewing-in-rounds plan|code`, or carries an `attributionSkill` that can be mapped. The real transcript of this run
(775cc01c…jsonl) shows otherwise. `attributionSkill` drops back to null within a turn or two of the skill loading
(main session: 23 records of implementing-plans, then 208 null). The second `implementing-plans` call is followed by
six Workflow plan-review runs and no `reviewing-in-rounds` Skill call. A `writing-plans` call with no args sits
between review rounds. Workflow agents carry `attributionSkill: "reviewing-in-rounds"` (246 records) with no args, so
plan and code reviews can't be told apart. The rule 'a subagent or workflow file takes its spawning record's' also
clashes with records that carry their own `attributionSkill`. Scenario: This plan's own run: the plan-review rounds
driven from `implementing-plans` (Workflow calls after the second `Skill:implementing-plans`) land in `implement`.
Rounds after the mid-review `writing-plans` call land in `plan`. Workflow agents attributed only to
`reviewing-in-rounds` have no defined stage. Task 15's own Real-data check then fails, and the plan gives the executor
no rule to fix it. The Revisit only checks this after entries are already being pushed. A fix: map Workflow and Agent
spawns through the latest `reviewing-in-rounds` args seen, or through the review-log rows each round writes, and
define the arg-less case.
Fixed: Task 15 drops the per-stage split; per session, agent type, skill and workflow phase stand in, and the
Revisit decides whether a stage split is worth building.

### R6-2 · minor · grounding

Task 16, Change: 'The rule stays under its 30-line aim': This claim is false. `claude/rules/writing-code.md` is
already 30 lines. Adding the 11 glob lines brings it to 41. I simulated the edit in a mktemp copy, and
`bin/check-md-limits` prints 'is 38 lines; keep it to 30 or fewer (hard cap 50)'. That is advisory, exit 0, so the
check still passes. Scenario: An executor following the plan either ships a rule over its aim while the plan says it
isn't, or stops to shorten text the user never asked to change. Settle it now: accept the overrun with its reason, or
check whether `paths:` takes a brace glob (`/*.{cs,go,rs,…}`) and use one line. Brace support in Claude Code is
unverified.

### R6-3 · nit · grounding

Approvals, 2026-11-05 'from Task 15b on … on every machine'; Task 15 Files 'cloned to $HOME/.ai-framework-log': The
standing yes covers every machine, but nothing sets up the log clone outside this one. No `init/` script or installer
step clones `andrelin/ai-framework-log`, and the global CLAUDE.md says the user works from more than one machine.
Scenario: On a second machine, every plan's completion step runs `ai-log record`, which exits 2 ('AI_LOG_DIR not a git
clone'). The step logs a failure in the report and records nothing, every time, until someone clones by hand. Either
add the clone to the Claude init script, or have the exit-2 message and the skill step say it is a one-time setup per
machine.
Refuted: Downgraded from minor by the verifier. Downgraded. The finding's second fix is mostly in the plan already.
Task 15 Interfaces gives exit 2 for '`AI_LOG_DIR` not a git clone, the message naming `gh repo clone
andrelin/ai-framework-log "$HOME/.ai-framework-log"`'. Task 15b's step puts any failure in the report. So on a new
machine the first run tells the user the exact one-time command; it does not fail silently forever. Cloning
automatically from an init script is a convenience the executor can add or skip. No init/ or bin/ script mentions the
log repo today, so the gap is real, but it costs one reported failure per machine.

### R6-4 · minor · grounding

Task 13, 2026-11-05 deviation ('the delete is its own commit on `main`'): The 2026-11-05 run approval names this flow:
commit on branch `ai-framework` after the final code review, fast-forward `main`, push, watch CI. It does not name a
separate direct commit on `main` after that. The older 2026-10-30 'commit to main' bullet was replaced for later runs.
Under the global rule that an approval covers what it names, the delete commit and its push are not clearly covered.
Scenario: At Task 13's end the executor either commits and pushes the delete to `main` without a clear yes, or stops
mid-run to ask. Add the delete commit and its push to the 2026-11-05 Approvals block, or state that the 2026-10-30
bullet still covers it.
Refuted: Dropped by the verifier. The premise is wrong. The 2026-10-30 bullet ('Commit each change to `main` ... push
to `origin main` and watch CI') was given 'for the rest of this plan'. Only the 2026-11-02 block says it 'replaces the
first bullet above for that run', and that applies to that run alone. The 2026-11-05 Task 14 note applies the
2026-10-30 first bullet again, which shows it is still in force. The 2026-11-05 run bullet points to 'as for Task 14'.
The Task 13 deviation also quotes the user's own ruling, 'We delete plans after they have landed on main'. So a direct
delete commit on `main` and its push are covered.

### R6-5 · minor · grounding

Task 15, Interfaces (findings outcome: 'a `Fixed:` line → fixed, else `Refuted:` → refuted'): The review-log format
puts severity downgrades under `Refuted:` too. Real entries read 'Refuted: Downgraded from major by the verifier.
Real, but downgraded.' and keep their original severity in the heading. So the counts book a real finding as a refuted
major instead of a valid finding at its new severity. Scenario: In `plan-ai-framework-review-findings-plan.md`,
findings the verifier downgraded rather than rejected count as refuted majors. That inflates the false-positive rate
per lens, the very signal Task 15d's cut-candidate logic uses to say a lens isn't pulling its weight. Either tell
'Downgraded' apart from refuted, or note the limitation.

### R6-6 · nit · grounding

Task 15, What the transcripts hold ('promptSource one of typed, queued, suggestion_accepted, sdk'): Real transcripts
also hold `promptSource: "system"` (594 records here): task notifications and subagent hand-backs. The plan's list
implicitly treats these as not user turns, which is right, but it never names them, so the fixture set may leave them
out. Scenario: If an implementer counts every non-null `promptSource` as a user turn, `user_turns` in a Workflow-heavy
run is inflated several-fold. Name `system` as excluded so the fixtures include one.
Refuted: Dropped by the verifier. The plan's list is an allowlist: 'promptSource one of typed, queued,
suggestion_accepted, sdk'. An implementer who follows it already excludes `system`. Such records do exist (162 in the
main session file). But the failure needs an implementer who ignores the plan's explicit list. Which fixtures to
include is an edge-case test input, which the review scope leaves to the code.

### R6-7 · minor · scope and slicing

Task 15 · Change, Stages ("a subagent or workflow file takes its spawning record's") and Tests, Real data last: How a
`subagents/agent-<id>.jsonl` or `workflows/wf_*/agent-<id>.jsonl` file maps back to the record that spawned it is
never checked. § What the transcripts hold lists file layout and field names but no join key between an agent file and
an `Agent`/Workflow `tool_use`. Stage attribution for every subagent, and so most of the tokens in an
`implementing-plans` or `reviewing-in-rounds` run, depends on that link. The only check against real data comes last
in the task, after the fixtures and the stage logic are built on the guessed shape. The Revisit then names the same
risk ("after a nested plan review above all") only after 15b ships. Scenario: The real transcripts link an agent file
to its parent by something other than what the fixtures invent, such as a `toolUseID` on the first record or only the
parent session plus a timestamp. The fixture tests pass, but on real data every subagent falls to `other` or to the
wrong stage. That only shows up in the final dry run, after the whole schema, stage logic and tests have been written
around the wrong link. Fix: start Task 15 with a spike that inspects one real nested run (a plan review inside an
implement run) and records the join key, then write the fixtures from it.
Refuted: Downgraded from major by the verifier. Downgraded from major. The link exists in real data and is easy to
find, so the approach does not rest on a false assumption. In the dotfiles project's transcripts, each
`subagents/agent-<id>.jsonl` has a sibling `agent-<id>.meta.json` with `toolUseId`. The parent's tool-result record
also carries `toolUseResult.agentId` and `sourceToolAssistantUUID`. Workflow agents' meta files have no `toolUseId`,
but their directory is named after the `wf_*` run, whose `wf_*.json` carries `runId`/`taskId`. There is also a
fallback that needs no join key: take the parent session's stage at the agent file's first timestamp. The finding is
still real, because § What the transcripts hold names none of these and the fixtures are invented. But recording the
key costs one line at implementation time, not a spike before the task.

### R6-8 · minor · scope and slicing

Approvals, 2026-11-05 run block ("push to it as Task 15 builds") vs Task 15 Tests, Real data ("No real `record` runs
here"): The approval and the Files list make Task 15 create `andrelin/ai-framework-log` and clone it, but nothing in
Task 15 writes to or pushes to it, because its real-data step is `--dry-run` only. So Task 15 ends with an empty
remote repo that its own tests never touch. Creating the repo really belongs to Task 15b, whose end-to-end run is the
first real `record`. Scenario: An executor creates the repo and clone in Task 15 and checks the remote and clone setup
against nothing. Any problem with the real clone (wrong path, missing README push, auth) first appears during 15b's
end-to-end run after the final code review commit. There it is reported as a failure and not fixed before the plan
closes. Fix: move the repo creation to 15b, or add one real `record` against a scratch plan to Task 15.

### R6-9 · minor · scope and slicing

Task 15b · Change, The mechanical redaction (the `~/.claude-customers` forms, host labels, directory forms): Tasks 15
and 15b are scoped to personal and company level only (Customer level deferred). Even so, 15b builds the full
customer-term redaction: each `<host>/<owner>` split three ways, hosts by label minus TLD and generic labels,
directories by path, `~/` form and last component, and hyphen-breaking whole-word matching. That machinery serves the
customer-level work moved to 15c, whose notes (folding, `[code]` blocks, terms pass) say it will be redesigned once
the Revisit has seen real entries. A narrower 15b would redact only the generic kinds (emails, paths, URLs, hosts,
tokens) and the plain `~/.claude-customers` names. Scenario: 15b builds and tests the elaborate per-form term matching
now. Then 15c, after the Revisit, replaces or extends it with folding and a model terms pass, and the 15b forms and
their tests get rewritten. That is effort spent on a level nothing records yet. Cheap to settle by trimming the list
while implementing.
Refuted: Dropped by the verifier. Dropped. The per-form customer-term redaction serves 15b's own levels and is not
wasted effort. The introspection `note` stores is written at personal and company level, and company work at Uptime
can mention customer names, hosts or directories. The user's decision says the log is "still free of customer
details", and the global rules bar customer names from anything not customer-scoped. Task 15 already skips repos whose
origin owner is neither `andrelin` nor `uptimeconsulting`, so `~/.claude-customers` terms are the only defence for
text written in a personal or company session. The 15c notes extend this matching with folding, `[code]` blocks and a
model pass. They do not replace it.

### R6-10 · minor · scope and slicing

Task 15b · Tests, End to end, and Task 13 deviation: The 15b end-to-end check and Task 13's delete ordering both
assume the final code review session loads the edited `reviewing-in-rounds/SKILL.md` from the `ai-framework` working
tree through the `~/.claude/skills` link. The plan never says the run must stay in the main checkout and not a
worktree. It also doesn't say that a code-review session started before 15b's edit will not see the new step.
Scenario: The final code review runs in a worktree, or in a session whose skill text was loaded before 15b's edit
landed. Step 7 is then absent, no `record` runs after the commit, and Task 13's delete precondition ("15b's `ai-log
record` has run on it") is never met. Either the plan is deleted without its entry or the run stalls. Fix: one line
saying the final review runs from the main checkout in a session started after 15b is built, and that if the step was
missed, `record` is run by hand before 13's delete.

### R6-11 · minor · scope and slicing

Task 16 · Tests, Loads where it should: The user's report was that the rule didn't load in a desktop session. The test
proves loading only under headless `claude -p` in the CLI, and it judges loading by the model's own answer to "which
rules loaded". The plan asserts the cause (missing `.cs` glob, confirmed by the current `paths:` list) but doesn't say
whether desktop sessions load path-scoped rules the same way. It also doesn't state that the desktop check is out of
scope or left to the user by hand. Scenario: The globs are added and the CLI check passes, but in the desktop app the
rule still doesn't load for `.cs`, for example because path-scoped rules load differently there. The task is marked
done against the user's report without the reported case ever being re-run. Fix: name a by-hand desktop recheck for
the user, or state it as out of scope.
Refuted: Dropped by the verifier. Dropped. How Task 16 is verified (CLI headless versus a desktop recheck, and judging
loading by the model's answer) is a choice of exact test cases, which the out-of-scope line covers. The cause is
evidenced in the plan: the `paths:` list has no `.cs` glob, and `claude/docs/rule-globs.md` notes that a glob that
never matches fails silently. The desktop app runs the same Claude Code rule loading. The finding offers no evidence
that path-scoped rules load differently there.

### R6-12 · nit · scope and slicing

Task 15 · Change, Customer level deferred: The origin-owner allowlist (`andrelin` or `uptimeconsulting`, otherwise
deferred) also skips origin-less repos. The global rules resolve those as personal, so they lose recording in Tasks 15
and 15b. The Tests list the customer and unlisted-owner cases but don't mention this effect. Scenario: A plan run in
an origin-less personal repo, such as a temp or scratch project, prints the deferral line and records nothing. The
executor or user may then read that as a bug. One clause saying it is intended (or not) settles it.

### R6-13 · minor · decisions

Task 13, Deviation (2026-11-05), against § Approvals, the 2026-11-05 run block ("This run works on branch ai-framework
… main fast-forwarded"): The deviation makes the delete "its own commit on `main`", made after the run's last commit
has landed. The only approval for this run says the work sits on branch `ai-framework`, is committed after the final
code review, and `main` is fast-forwarded to it. No approval names a commit made directly on `main` and pushed. The
2026-10-30 commit-to-main bullet was replaced "for that run", and later blocks replace it again "as for Task 14". The
executor would ask: may I commit the delete straight onto `main` and push it, or does it go on `ai-framework` and get
fast-forwarded? Does it need its own yes? Scenario: The executor reaches Task 13's delete with `main` fast-forwarded
to `ai-framework`. One reading commits and pushes on `main` under the 2026-10-30 bullet, which may be a write nobody
approved. The other cuts a branch for a one-file delete that has no code review step to commit it. Either way the
executor stops to ask, or makes a write the approvals don't cover.
Refuted: Downgraded from major by the verifier. Downgraded from major. The 2026-10-30 bullet ('Commit each change to
`main` ... push to `origin main` and watch CI') was approved 'for the rest of this plan'. It was replaced only 'for
that run' on 2026-11-02, and on 2026-11-05 it was explicitly 're-applied' to Task 14. The 2026-11-05 branch block says
how the run's built tasks land. The delete itself rests on the user's own ruling 'We delete plans after they have
landed on main', so a commit on `main` is the intended place. This is a personal public repo, where the history is the
user's, so nothing forbidden is written. What is left is a small gap: no line says whether the 2026-10-30 bullet or
the branch-and-fast-forward block covers the delete commit. Either reading is approved for this plan, so one line
settles it cheaply.

### R6-14 · minor · decisions

Task 15, Change, *Customer level, deferred* (owner allowlist `andrelin` / `uptimeconsulting`): The plan adds a rule
that the global `CLAUDE.md` doesn't have: anything whose origin owner is not `andrelin` or `uptimeconsulting` counts
as customer and is never recorded. That rule decides which runs ever produce data. It leaves out every company-level
repo under another owner ("anything else → company"), every origin-less personal repo in a temp directory, and repos
under those owners on another host. The plan never asks the user whether "the personal and Uptime part" means only
these two owner names on any host. It also doesn't say whether the host should be part of the check, or whether an
origin-less personal repo should record. The executor would ask: should the allowlist match the host too, and should a
personal repo with no origin record? Scenario: Example: a plan run in a personal scratch repo with no origin, or in a
company repo owned by a client-agnostic org. Each prints "customer level is deferred" and records nothing. The user's
cross-session data then silently misses whole classes of their own work. Example the other way: a customer GitLab host
carrying an `andrelin/...` fork is recorded as personal. Changing the rule after entries exist leaves the history
inconsistent.
Refuted: Downgraded from major by the verifier. Downgraded from major. The scenario 'the other way' is wrong. The
check is OR-ed with `work-context.sh level` printing customer, and the resolver maps `andrelin` only on `github.com`:
`git@gitlab.com:andrelin/x.git` resolves as customer (Task 1 test, line 874). So a fork on a customer host is never
recorded. Origin-less repos are mostly throwaway test repos, and the id is hashed over the origin anyway. The
allowlist is a deliberate, conservative decision recorded from plan review R5-1, R5-37 and R5-38 and from the user's
'build the personal and Uptime part'. It fails toward recording nothing, never toward leaking data, and relaxing it
later is cheap, since a missed run can be recorded again while its transcripts last 30 days. One real point remains:
repos whose owner is listed in `~/.claude-company-orgs` resolve as company but are excluded by the owner allowlist.
That is worth one line to settle, but it doesn't block the build.

### R6-15 · minor · decisions

§ Approvals, the 2026-11-05 log-repo block ("on every machine"), and Task 15 Files (clone to
`$HOME/.ai-framework-log`): The standing yes covers every machine, but nothing decides how the log clone gets onto
each machine. The plan doesn't say whether a dotfiles init script (for example `52_claude.sh`) clones it, or whether
the user does it by hand once per machine. `record` exits 2 without a clone, and the skill step only reports the
failure. The executor would ask: should `bin/dotfiles` set up `~/.ai-framework-log`, or is a missing clone left for
the user to notice? Scenario: The user runs a plan on their second machine. Every completion reports `ai-log` exit 2
inside a long review report. No entry is written for that machine's plans until somebody notices, so the cross-session
data (Task 15d) skews to one machine.

### R6-16 · minor · decisions

Task 15b, Tests, *End to end, by the session* ("this plan's next final code review runs the step"): "Next final code
review" has two readings. (a) It is this run's final code review, the one that reviews 15, 15b and 16 and commits
them; the newly written skill step runs at that review's completion. (b) It is a later code review, such as Task 13's
fold. The two readings decide when 15b's row can flip to done, and whether this run must push a real entry before it
ends. Scenario: Under reading (b) the executor finishes the run with 15b marked done without ever having run `record`
or `note` for real. Under reading (a) it expects the step to fire in the same completion that commits the skill edit.
That only happens if the review session loads the skill after the edit, which nobody checks. Either way the end-to-end
proof may never happen before Task 13 deletes the plan.
Refuted: Dropped by the verifier. Neither reading lets the proof be skipped. Task 13's deviation makes the delete wait
until '15b's `ai-log record` has run' on the run's last landed commit, so a real `record` before the plan is deleted
is already a gate. The fold is code-reviewed 'in the run like any task', so whichever final code review comes after
15b's edit runs the edited step. Under the 'Done (code)' rule, that review session invokes `reviewing-in-rounds code`
after the implementation, so the skill it loads already has the step. When the status row flips is the executor's
call, and a reviewer can check it.

### R6-17 · minor · decisions

Task 16, Change (the glob list): Which languages count as "the common languages" is the user's call. The plan's list
has gaps that change behaviour for languages the user will edit. It includes `.h` and `.cpp` but not `.hpp` or `.cc`.
It includes `.cs` but none of the .NET sibling files (`.razor`, `.cshtml`, `.csproj`). It also leaves out
`.mjs`/`.cjs`, `.vue`/`.svelte`, `.ps1` and `.sql`. The executor would ask: is this list final, or should it follow
the extensions the user actually works in, starting with the full set of C# and .NET files that prompted the report?
Scenario: The user opens a `.razor` or `.hpp` file in their next C# or C++ session and the rule silently fails to load
again, which is the failure Task 16 exists to fix (`rule-globs.md`: a glob that never matches fails silently).
Refuted: Dropped by the verifier. Out of scope. The exact extension list is a choice the executor can make and a
reviewer can check in the diff. The user's ruling was 'cover C# plus the common languages', and `/*.cs` covers the C#
that prompted the report. Adding `.hpp`, `.cc`, `.mjs` or `.razor` is a one-line diff change, not a decision only the
user can make.

### R6-18 · minor · decisions

Task 13, Deviation (2026-11-05), "after the run's last commit has landed there and 15b's `ai-log record` has run on
it": The sentence has two readings for when `record` runs. (a) `record` runs on the landed commit on `main`. (b)
`record` runs at the code-review completion on the branch, before the merge. Reading (b) is what the user's ruling "We
log after we commit to a PR, before merging it" and the 15b trigger actually do. Reading (a) asks for a second
`record` run by hand on `main` after the fast-forward. Scenario: An executor following reading (a) runs `ai-log record
plan-ai-framework.md` again on `main` after the fast-forward. If the commit is the same, the id is the same and the
entry is replaced. If the executor passes the merge or tip commit instead, a second entry is written whose window is
empty or overlaps. Either way the log gets noise right before the plan is deleted and can't be re-recorded.
Refuted: Dropped by the verifier. Both readings name the same commit. `main` is fast-forwarded to `ai-framework`, so
the run's last commit has the same sha on both branches, and no merge commit exists to pass instead. Task 15 makes
`record` idempotent per commit: 'A re-run for the same commit has the same id, skips its own entry in the search, and
replaces it.' A second run on `main` therefore produces no second entry and no overlapping window. No failure scenario
survives.

### R6-19 · nit · decisions

Task 15b, Files, the text added to `claude/docs/work-contexts.md` § *An approval covers one action, not a policy*: The
added text says `reviewing-in-rounds` runs `ai-log` "at every level" and, in the same breath, that at customer level
nothing is recorded. It also places a standing, policy-wide yes under a heading that says approvals are not policies.
A reader may take "at every level" as permission for customer-level writes before Task 15c exists. Scenario: A later
session reads `work-contexts.md` and treats customer-level `ai-log note` or `ai-log record` writes as approved. The
approval only covers the deferral line until Task 15c is built and its stored-text decisions are applied.

### R6-20 · minor · consistency

Implementation status table, row `Final code review` (and Task 15b Tests, *End to end*): The row still reads ✅ DONE
(from Task 14's round 2 and the round-12 log), though Tasks 15, 15b, 16 and 13 were added after it and are ⏳ PENDING.
§ *The staged workflow* says the row stays PENDING until `reviewing-in-rounds code` ends in `Done (code):` and flips
it, so that a skipped final review shows in the plan. Task 15b's end-to-end test depends on 'this plan's next final
code review' actually running. Scenario: After building 15, 15b and 16, the driver reads a table where every task row
and `Final code review` are DONE. It skips the mandatory final review, which is the failure that row exists to catch.
The final review's commit and its Completion step are then never reached, so `ai-log record` never fires and 15b's
end-to-end never runs.
Refuted: Downgraded from major by the verifier. Partly refuted on severity. The inconsistency is real: line 139 reads
DONE while 15, 15b, 16 and 13 are PENDING, and § The staged workflow (line 388) says the row stays PENDING until `Done
(code):`. But `implementing-plans` (SKILL.md lines 129-135) runs `reviewing-in-rounds code` in the same run whatever
the table says, so the review isn't skipped on a normal run. The row matters on a resume from the table, and resetting
it to PENDING is a one-cell edit. Nothing is costly to reverse, so minor.

### R6-21 · minor · consistency

Task 13, Files, Tests and the 2026-11-03 deviation; File map row for 13 ('this plan and its findings file (deleted)'):
The run has not folded in the closed findings files that Task 14's runs created on 2026-11-05. Task 13 deletes only
`plan-ai-framework.md`, `…-review-findings-plan.md` and `…-review-findings-code.md`. But `git ls-files` already tracks
`plan-ai-framework-review-findings-code-closed-2026-11-05.md` and `…-plan-closed-2026-11-05.md`, and
`…-plan-closed-2026-11-05-2.md` exists untracked. The File map says 'its findings file', singular. Scenario: The
executor deletes the three named files. Task 13's own test, `git ls-files 'plan-ai-framework*'` prints nothing, then
fails on the two tracked closed files, and the untracked `-2` file is left behind.

### R6-22 · minor · consistency

Task 13, deviation (2026-11-03, R3) list of open items vs Handover item 6: Two lists that should agree do not. Task 13
still names 'Task 7's conflict sent to the user' as open, though Handover item 5 and § *Approvals* record it as
decided and the wording changed on 2026-11-05. Handover item 6 lists the audit's recorded Mediums and Lows and R12-4,
which Task 13 omits. Task 13 lists Task 11's checks and follow-ups 15c and 15d, which item 6 omits. Scenario: The
executor filing Task 13's issue from Task 13's text re-raises a settled Task 7 conflict, then drops the audit's
Mediums and Lows and R12-4. Deleting the plan loses them, which the deviation exists to prevent.

### R6-23 · minor · consistency

Task 13 deviation ('filed with `writing-issues` on the user's yes') vs § Approvals, 2026-11-05 run block: Filing Task
13's GitHub issue needs a yes that the bulk approvals for 'the run started that day over the remaining tasks' never
asked for, though it was foreseeable. The global § *Approvals* says to ask in bulk, up front, and to ask again only
for what nobody could foresee. Scenario: The run reaches Task 13 and must stop mid-run for a foreseeable approval,
which the bulk approvals were meant to prevent.

### R6-24 · nit · consistency

Task 15b, *The skill step* and Tests ('the step is one list item') vs § Approvals 2026-11-05 ('Yes, one line is
fine'): The user approved one line in `reviewing-in-rounds`. The quoted step is three sentences, about 290 characters.
Under the repo's one-sentence-per-line rule with 150-character lines, that is three lines. The test re-reads 'one
line' as 'one list item', so the change goes beyond what the approval names. Scenario: The executor writes a
three-line step and the test passes. The skill change goes beyond the exception the user approved ('an approval covers
what it names'). Either the step fits in one sentence and line, or the user is asked.
Refuted: Downgraded from minor by the verifier. Downgraded. The plan framed the question as 'the one-line trigger',
meaning one step in § Completion, and the user approved that one trigger step. The step is two sentences, not three.
That it wraps to two physical lines under the 150-character cap and the one-sentence-per-line rule
(claude/rules/markdown-limits.md) is formatting, not a wider change. Tightening the wording is at most a nit.

### R6-25 · minor · consistency

Task 16, Change ('The rule stays under its 30-line aim'): `bin/check-md-limits` counts front matter.
`claude/rules/writing-code.md` already counts 27 lines (16 front-matter lines plus 11 body lines). Adding 11 globs
'one per line as the list has them' makes 38, over the 30-line aim but under the 50-line cap. The plan's two
requirements contradict each other. Scenario: The executor follows 'one per line' and the claim 'stays under its
30-line aim' is false. Or it collapses the globs into a brace pattern against the stated format. Either way one
requirement of the task is broken.

### R6-26 · minor · consistency

Task 16, Tests: Task 14's lesson and `rule-globs.md` both call for a baseline run, yet nothing shows that the headless
check fails before the change. The user's report came from a desktop session, and the fix assumes a missing glob is
the whole cause there. Scenario: If the desktop app does not load path-scoped rules the way headless `claude -p` does,
the `.cs` check passes after the edit while the user's reported failure persists. Neither a before-change headless run
nor a desktop check would show that.
Refuted: Dropped by the verifier. Out of scope: it asks for an extra test case, a before-change run. The cause also
isn't in doubt. The current `paths:` holds no `/*.cs`, so the rule cannot load for a .cs file, and the after-change
check (`.cs` loads, `.md` doesn't) tests the fix directly. Whether the desktop app loads rules at all is a separate
hypothesis, which the user didn't raise.

### R6-27 · minor · consistency

Task 15b, Files: text added to `claude/docs/work-contexts.md` § *An approval covers one action, not a policy*: The
text added there says what leaves the machine is 'counts, durations, tokens, estimated dollars and versions, and the
introspection'. Task 15's entry also holds `repo` (`<owner>/<name>`), the plan's basename and the commit sha. It also
says only customer level records nothing, but Task 15 skips every origin whose owner is neither `andrelin` nor
`uptimeconsulting`. The section's own lines 'Ask again, every time' and 'the workflow skills never commit on their
own' are left contradicting the new standing yes. Scenario: A reader of the durable doc believes repo names and shas
never leave the machine, and that an unlisted company-resolving repo is recorded. The same section still tells Claude
to ask again every time, which conflicts with the step that runs without asking.

### R6-28 · minor · consistency

Task 15b, Tests *End to end* ('Record here only that it ran, and the id') with Task 13's delete: The end-to-end result
is written into the plan after the final review's commit, and Completion step 1 never stages `plan-*`. Task 13 then
deletes the plan, and its issue list does not mention this record. The Revisit, which needs 'Task 15b's first real
entry', has no durable pointer to the id. Scenario: The id of the first real entry lives only in an uncommitted edit
to a plan that is then deleted. The Revisit carried in Task 13's issue cannot locate the entry it is meant to inspect.
Refuted: Dropped by the verifier. No real failure. The first real entry lives in the private log repo, and each entry
carries `repo`, `plan` (basename), `commit` and a date-prefixed id. It is also the repo's first entry, so the Revisit
can find it there without the plan's note. The note in the plan is not the only pointer.

### R6-29 · minor · consistency

Task 15, Interfaces (review log forms consumed): Task 15 counts `-review-findings-*.md` files that are 'open or closed
on or after the window start's date' and keys sections by their first finding's heading. It names only the `### R…`
heading and the `Fixed:`/`Refuted:` forms. It does not name the closing forms in `review-log.md` that link a closed
section to its file: the heading `## Review log (<kind>, closed <date>)` and the file
`…-<kind>-closed-<date>[-<n>].md`. This plan already has two plan-kind closes on 2026-11-05. Scenario: Two closed plan
logs share the heading date 2026-11-05. Matching a section to `…-plan-closed-2026-11-05.md` versus `…-2.md` by date
alone can pair the wrong findings with a section, so lens and severity counts are wrong in the first real entry.

### R6-30 · nit · consistency

Follow-up 15c, last note ('needs a login token in a throwaway `HOME` (§ *Approvals*)'): The reference points at this
plan's § *Approvals*, which Task 13 deletes. Task 13's issue carries 15c's sketch but nothing says it carries that
approval. Scenario: Once the plan is gone, the 15c follow-up in the issue cites an approval section that no longer
exists.

### R6-31 · nit · consistency

File map, `claude/docs/work-contexts.md` rows: The file appears in three rows: '2, 2b, 3b', one for 4, and the 15b and
13 rows. The first row's task list is incomplete, so the map does not show at a glance every task that touches the
file. Scenario: A reader checking which tasks touch `work-contexts.md` from its main row misses 4, 13 and 15b.

### R6-32 · major · work context

Task 15 § Change, *Customer level, deferred* (and its Tests, *Customer level*): The extra gate checks only the
origin's owner (`andrelin` or `uptimeconsulting`), not its host. The resolver (`claude/hooks/work-context.sh`
`classify`, lines 650-657) treats `uptimeconsulting` as company on any host, and `andrelin` on any host other than
github.com as company. So a repo on a customer's self-hosted Git server, under a namespace with the same name, passes
both checks. R5-1/R5-37/R5-38 were meant to guarantee that an unlisted customer repo is never recorded, and they
don't. Scenario: While `~/.claude-customers` is empty (the user has no customer now), the user clones
`git@git.client-host.example:andrelin/integration.git` or `.../uptimeconsulting/x.git` on a customer's GitLab. The
resolver returns company and the owner check passes. `record` then commits and pushes `repo: andrelin/integration`,
the plan basename, project skill and MCP tool names and plugin names to GitHub, and 15b's `note` pushes the
introspection. Fix: also require host `github.com` (or the same host the resolver uses for personal), and add a test
fixture of that shape.
Fixed: the gate needs the host too — `github.com/andrelin` or `github.com/uptimeconsulting`, or a `<host>/<owner>`
line in the private clone's `allow` file; a test covers another host.

### R6-33 · major · work context

Task 15 § Interfaces (entry fields `repo`, `plan`, `skills_outside`, `framework.plugins`, `tools`, `agents`) vs §
Change *No free text* and the user decision *Where* ("Still free of customer details"): At company level the entry
stores, unfolded, the repo's `<owner>/<name>`, the plan's basename, project skill names, custom agent types, every MCP
tool name and every installed plugin and marketplace name. Company repos and plans are often named after a customer
engagement, and MCP or plugin names can name internal tooling. Follow-up 15c's own notes treat exactly these names as
identifying and fold them, but only at customer level. 15b's redaction also scrubs the repo's owner and name from the
`.md` while the JSON beside it keeps them in plain text. Scenario: Company repo `uptimeconsulting/acme-billing` with
plan `plan-acme-sso.md`, a project skill `acme-deploy` and an MCP server `mcp__acme-jira__*`. Every name lands in
plain text in `entries/<id>.json` on GitHub, which breaks "free of customer details". Store `repo` and `plan` only as
the existing hashes (`id` and `plan_key` already cover identity), or fold those names at company level too.
Fixed: at company level `repo` and `plan` are hashes, and project skills, custom agent types and MCP tools counts.

### R6-34 · minor · work context

Task 15b § Files, the `claude/docs/work-contexts.md` addition: The public doc tells the user that what leaves the
machine is "counts, durations, tokens, estimated dollars and versions, and the introspection". The entry also carries
the repo owner and name, the plan basename, the commit sha, skill, tool, MCP and agent-type names and plugin names.
The disclosure the standing yes rests on understates what is pushed. Scenario: The user, or a later session, reads
work-contexts.md to judge whether running `ai-log` in a sensitive company repo is safe. They conclude only numbers
leave the machine, but the repo and plan names and MCP tool names are pushed as well.

### R6-35 · minor · work context

Task 15 § Change, *Drift degrades loudly*; entry field `warnings[]`: Warnings are stored in the entry and pushed, but
the plan never says they must be free of content. A warning for "a line that isn't JSON" or "an unparseable findings
heading" naturally quotes the offending line or heading, which is transcript or finding text. That breaks *No free
text*, and the *No free text* test plants markers only in valid records. Scenario: A truncated transcript line holding
a customer prompt fragment, or a malformed `### R3-2 ...` heading naming a customer system, is echoed into
`warnings[]` and pushed to the log repo. Say that warnings name only the kind, file class and line number, and plant a
marker in a malformed line in the test.
Refuted: Dropped by the verifier. *No free text* already governs the whole entry, `warnings[]` included: 'no prompt,
question, message, tool input or output, path ... or finding text'. A warning that echoed a transcript line or a
findings heading would break a rule the plan already states, and a reviewer can check that in the diff. A warning's
exact wording is an output-format and error-handling choice, which is out of scope.

### R6-36 · minor · work context

Task 15 § Change, *Customer level, deferred* (hardcoded `andrelin`/`uptimeconsulting`): The script keeps its own owner
allowlist beside the resolver instead of using the resolver's result. Task M already refers to company owners in
`~/.claude-company-orgs`. If the resolver ever learns more company orgs or host aliases (for example
`github.com-work`), the two lists drift apart without anyone noticing. Scenario: A second company org is added to the
resolver. `ai-log` keeps refusing that org's repos as customer, which is safe but loses data, or a later edit loosens
one list and not the other. Read the resolver's verdict with its host, owner and repo instead of re-deriving it.

### R6-37 · minor · work context

§ Approvals, 2026-11-05 bullet "Entries store the user's prompts and Claude's questions, redacted, and the
introspection, at every level" (carried into Follow-up 15c): A standing yes to push redacted customer-session prompts
and prose to a personal GitHub repo sits awkwardly with the global § *Durable context*: customer context stays outside
the repos, in that customer's tree. A customer's confidentiality terms may also forbid it, however good the redaction.
The yes is recorded now, but what it covers is decided only when 15c is detailed. Scenario: 15c is later built from
this recorded yes alone. Customer-session text, mechanically and model-redacted, is then pushed to GitHub without
anyone re-checking it against the customer's own `CLAUDE.md` or terms. Note in 15c that the customer tree's
`CLAUDE.md` is read first and wins, as the global table says ("their CLAUDE.md wins").
Refuted: Dropped by the verifier. Follow-up 15c is explicitly a sketch, 'Detailed after the Revisit has seen real
entries', and it is not a task of this run. The out-of-scope line covers a Sketch task's missing detail. The global
CLAUDE.md table already says a customer's CLAUDE.md wins, and 15c will be detailed and reviewed before anything is
built. Nothing in this run pushes customer text, because Task 15 makes customer level a no-op.

### R6-38 · minor · work context

Task 13, 2026-11-05 deviation; § Approvals 2026-11-05 run bullet: The deviation makes the plan delete a separate
commit on `main`, made after the fast-forward and the push. The 2026-11-05 run approval names only the `ai-framework`
branch, its commit after the final code review, the fast-forward of `main`, the push and the CI watch, "as for Task
14". A later direct commit and push to `main` is not named there, and an approval covers only what it names. Task 13's
GitHub issue is also left "on the user's yes" rather than asked in bulk up front. Scenario: The executor reaches Task
13's delete and has to stop to ask whether a direct commit and push to `main` is covered, or treats the 2026-10-30
bullet as still covering it although that bullet was superseded. Add the delete commit and push, and the issue filing,
to the 2026-11-05 block.

### R6-39 · nit · work context

§ Approvals, 2026-11-05 iteration bullet "at every level and on every machine": "At every level" reads as a yes to
push from customer sessions, yet Tasks 15 and 15b make `record` a no-op there. "On every machine" includes a
customer-issued laptop, where pushing even counts to a personal GitHub repo may not be allowed. Scenario: An executor
or a later 15c builder reads the bullet as already covering customer-level pushes. Reword it to "personal and company
level until 15c" to match *Customer level deferred*.

## Round 7

### R7-1 · major · grounding

Task 15 · Change, Tokens and The window (lines 3516-3526); Tests, Counts (3573): Tokens, user turns and the other
counts are de-duplicated by `message.id` only within a session, but resumed or forked sessions copy the earlier
session's records into a new session file, keeping the same message ids and timestamps. I checked this on real
transcripts: 435 assistant message ids appear in two top-level session files. For example, `oppdragslab` sessions
8595dbd8 and 2a5951c5 share 155 ids, both starting at 2026-10-08T13:47:21.062Z. Summing `sessions[]` into `totals`
therefore counts the shared prefix twice. The plan's own handover relies on `claude -p --resume`. The fix is to
de-duplicate by `message.id` (and record uuid for user turns) across every in-scope file before computing totals, and
to add a fixture of a resumed session. Scenario: A stage is resumed with `claude -p --resume <id> "<answer>"`, which
creates a new session file holding the old history. Both files are in scope and in the window, so tokens, cost, user
turns, questions and agents for the copied part are doubled in `totals`. The Revisit and Task 15d then read inflated
costs as real.
Fixed: counts are de-duplicated across all in-scope files, assistant records by `message.id`, others by `uuid`;
a resumed-session fixture.

### R7-2 · major · grounding

Task 15 · Interfaces, the entry (lines 3507-3510), with Follow-up 15d's cut candidates (3695-3698): The user asked to
find what isn't pulling its weight, and 15d plans to report lenses and agent types "whose cost recurs with no findings
or fixes". But no entry stores cost by lens or by agent type: `agents` is a count per `<type>/<model>`, and workflow
tokens are kept only per `workflowPhase` (Review or Verify). The lens is available in each workflow agent's
`.meta.json` `description` (seen: `"description":"verify:security","workflowPhase":"Verify"`), and lens names are
allowed in entries. Entries keep aggregates only and transcripts are deleted after 30 days, so this cannot be filled
in later. The Revisit can only notice the gap after the early entries have already lost it. Recording tokens per lens
(from the meta description) and per agent type now is cheap. Scenario: After a few months of entries, `ai-log report`
has to name which review lens costs the most for the fewest findings. Findings by lens exist, but cost by lens does
not, and the transcripts it would come from are gone. The cut candidates the user asked for cannot be computed from
the stored data.
Fixed: tokens are kept per agent type and per review lens, from workflow agents' `.meta.json` `description`.

### R7-3 · major · grounding

Task 15b · The mechanical redaction (lines 3633-3642) against Task 15 · Company level, names hashed (3551-3553): Task
15 hashes `repo` and `plan` at company level because "company repos and plans are often named for an engagement"
(R6-33). The introspection `.md`, which is also pushed at company level, removes the repo's remote names and folder
names but not the plan basename's words. The only other protection is the prompt's instruction to leave out customer
names. The user's decision was "Still free of customer details", and they asked for extra redaction effort, but the
model pass is deferred to 15c. A name the JSON hides on purpose can therefore reach the pushed history through the
prose. The plan basename's words (and the plan title) should go into the redaction set. Scenario: A company plan
`plan-acme-sso-migration.md` in `uptimeconsulting/portal`. The entry stores the plan as a hash, but the introspection
says "the acme-sso migration's review rounds…". Nothing in the redaction set matches `acme`, so it is committed and
pushed to `andrelin/ai-framework-log`, and removing it later means rewriting history.
Fixed: at company level the introspection's redaction adds the plan basename's, first heading's and branch's words.

### R7-4 · minor · grounding

Task 16 · Change (lines 3712-3714): The claim that the rule stays under its 30-line aim is false. I applied the eleven
globs to a copy of `claude/rules/writing-code.md`: the file grows to 41 lines, and `bin/check-md-limits` reports "is
38 lines; keep it to 30 or fewer (hard cap 50)", before the formatter bullet's addition. The check still passes (it is
only advisory), but the plan's statement is wrong. Fix it by accepting and stating the overage, or by trimming
elsewhere. Scenario: The executor follows the plan, sees the NOTE from `check-md-limits`, and has to decide alone
whether to cut list entries, cut body lines or ignore it. A reviewer then flags the stated aim as missed.

### R7-5 · minor · grounding

Task 16 · Spec and Tests (lines 3704-3705, 3720-3723): The user reported the problem in a desktop session, but the
test only runs the headless CLI. The missing `/*.cs` glob is verified and is a sufficient cause. Still, nothing checks
that the desktop app loads `~/.claude/rules` for that session the same way, so the reported symptom is never
re-checked where it occurred. Scenario: The desktop app handles path-scoped user rules differently from the CLI. The
headless test passes after the change, the user opens a `.cs` file in the desktop app, and the rule is still missing.
Refuted: Dropped by the verifier. Out of scope: which test cases to run and where is left to the executor and
checkable in the diff. The scenario that the desktop app treats path-scoped rules differently is speculation with no
evidence. The plan's fix targets the verified, sufficient cause, the missing `/*.cs` glob, through the documented
rule-glob mechanism.

### R7-6 · minor · grounding

Approvals, 2026-11-05 block (lines 96-101); Task 15 Files, Outside this repo (3481-3482): The standing yes covers
committing and pushing to the log clone "on every machine", but only this machine's clone is created. No init script
or tip clones `andrelin/ai-framework-log` on the user's other machines. On those machines, every plan's final code
review hits exit 2 (`AI_LOG_DIR` is not a git clone) and records nothing until the user notices and clones it by hand.
Scenario: The user finishes a plan on a second machine. The skill step runs `ai-log record`, gets exit 2, and the
failure goes into the report. No entry is written, and that plan's data is lost once its transcripts are cleaned up
after 30 days.

### R7-7 · minor · grounding

Task 13 · 2026-11-05 deviation (lines 3757-3759) against the 2026-11-05 Approvals block (lines 82-92): The deviation
adds a separate delete commit made directly on `main`, plus its push, after the fast-forward. The 2026-11-05 run
approvals name only the post-review commit on `ai-framework`, the fast-forward, the push and watching CI. Filing Task
13's issue is still "on the user's yes" and was not asked up front. Under the global rule (an approval covers what it
names; ask in bulk, up front), the run will stop at both points unless the Approvals block names them. Scenario: The
run reaches Task 13's delete and its issue filing, finds no approval naming either, and stops to ask. That is the
mid-run stop the bulk-approval rule is meant to prevent.

### R7-8 · minor · grounding

Follow-up 15c sketch (lines 3673-3675): The sketch says the model terms pass must run at every level "since a customer
repo not yet in `~/.claude-customers` resolves as company". Task 15 already rules this case out: `record` writes
nothing unless the origin is `github.com/andrelin/…`, `github.com/uptimeconsulting/…` or listed in `allow` (R5-38).
The rationale carried into Task 13's issue is out of date. The real reason a company-level pass would be needed is
engagement names inside the uptimeconsulting org (see the redaction finding above). Scenario: Whoever details 15c from
Task 13's issue sizes the model pass on a risk that Task 15 already closed, and misses the actual company-level leak
path.

### R7-9 · minor · grounding

Task 15 · Tests, Real data (lines 3593-3596): The real-data privacy check greps the dry-run output for every
`~/.claude-customers` entry. That file does not exist on this machine (`ls ~/.claude-customers` reports no such file),
so the check passes without testing anything. It also reads only this repo's sessions, which are personal level.
Scenario: The real-data step reports "no customer entries found" while having checked against an empty list. The
company-level redaction is never tested on real data before 15b pushes the first real entry.
Refuted: Dropped by the verifier. I confirmed that `~/.claude-customers` is absent on this machine, but the user has
said there is no customer at the moment (customer level deferred), so there is nothing to leak and nothing to test
against. The finding is about the content of a test assertion and how much data it checks, which the out-of-scope line
covers. Company-level redaction is also tested on fixtures in Task 15's and 15b's tests.

### R7-10 · nit · grounding

Task 15b · The trigger and The skill step (lines 3603, 3623-3626): The user approved "one line" in
`reviewing-in-rounds`. The step as written is two sentences, about 290 characters, which is two or three lines under
the one-sentence-per-line rule. The skill is also already at 112 lines, over its 100-line aim. The plan calls this the
user's one-line exception without noting the stretch. Scenario: A code reviewer measures the added step against the
user's "Yes, one line is fine." and flags it as going beyond what the user approved.

### R7-11 · nit · grounding

Task 15 · User decisions, Where (lines 3434-3436) against Company level, names hashed (3551-3553): The user asked that
each entry record which skills and tools from outside the dotfiles were used. At company level, project skills, custom
agent types and MCP tools are stored only as counts, following plan review R6-33 rather than a user decision.
Narrowing a requirement the user stated should be noted as a deviation or put to the user. Scenario: At company level,
the user tries to see which MCP tools a run relied on and finds only a number.

### R7-12 · minor · scope and slicing

Task 15 · Tests, the last bullet (Real data, last, by the session), and Task 15 as a whole: The riskiest assumption in
Task 15 is tested last. That assumption is that real transcripts are attributed, windowed and priced correctly. The
fixtures are invented from a field-names-only inspection, and the one run against real data (`--dry-run
plan-ai-framework.md` plus the price check) comes after the whole script exists. By then the script includes
review-key incremental counting, framework and skill classification, workflow phases, company hashing, the customer
refusal with its `allow` file, and log-clone rebase and push. The re-slice was meant to make Task 15 reviewable to a
finish, but it is still the widest task in the plan. Scenario: Two things could go wrong on the real dry run. Scope
detection may miss sessions: for example, a session whose only mention of the plan is in a Workflow agent's input, or
a resumed session whose cwd differs. Or the main model's priced tokens may miss the `cost-state` check by more than
10% because of how per-`message.id` usage repeats. Either way, the window, scope and token core that every later part
of the script builds on has to be reworked, along with the tests and fixtures written against invented data. The fix:
build the core first (scope, window, tokens and cost) and run it with `--dry-run` on real data, before the reviews,
framework, company-hashing and log-clone parts are added.
Refuted: Downgraded from major by the verifier. Downgraded. The concern is real: the plan puts the real-data dry run
and price check last. But the transcript fields were already inspected on real data (2026-11-05, field names, the
per-message.id repeat already noted), so the core does not rest on a wholly unverified assumption. Also, Task 15 is
committed only after its final code review, so reworking the window, scope and token core after a failing dry run is
uncommitted, in-task work, not a costly reversal. Running `--dry-run` early, once scope, window and tokens exist, is
an ordering choice the executor can make cheaply. A one-line note in the plan settles it.

### R7-13 · minor · scope and slicing

Task 15b · Change, The mechanical redaction, the second bullet (the work repo's remotes, its folder and those above it
up to `$HOME`): At personal and company level, redaction replaces the work repo's owner, its name and every folder
name between it and `$HOME`. At personal level nothing asks for this: the entry's JSON already stores `repo` and
`plan` in clear text. Combined with whole-word matching where `-`, `.` and `/` break words, it also damages the
introspection. Scenario: Take a repo checked out at `~/code/dotfiles`, or `~/.dotfiles` (owner `andrelin`). The words
'code', 'dotfiles' and 'andrelin' anywhere in the introspection become `[repo]`. 'code review' is printed as '[repo]
review', so Task 15d's cut-candidate analysis reads garbled evidence. The fix: limit this bullet to company level, or
drop it until Task 15c, and state that.

### R7-14 · minor · scope and slicing

Approvals, 2026-11-05 standing yes ('on every machine'); Task 15 · Files ('cloned to `$HOME/.ai-framework-log`'): The
standing yes and the skill step assume the log clone exists on every machine, but no task provisions it beyond the
current one, and the plan does not say that provisioning is out of scope. Sessions are also per machine: a plan worked
on across two machines has transcripts on both, and `record` sees only the local ones. Neither limit is stated.
Scenario: An executor either adds an init script to `bin/dotfiles` to clone the log repo, which nothing asks for, or
leaves it out. On a second machine, every plan's completion step then exits 2 with only a line in the report, so no
entries are recorded there. Separately, the cost and turns of a plan split across machines are undercounted with no
warning. The fix: state both limits under Task 15's out-of-scope, or add the clone to an init script deliberately.

### R7-15 · minor · scope and slicing

Task 16 · Spec and Tests: The fix rests on an unproven cause: that `paths:` lacks C#. The user's report came from a
desktop session. Task 16's tests run only after the change and only through headless `claude -p`, with no baseline
showing that a `.cs` read fails to load the rule before the change. Scenario: Suppose the desktop app did not load the
rule for some other reason, for example because the session was started before the rule existed, or the file was
opened by a tool that does not trigger path rules. Adding the globs then passes the headless test, but the user's
desktop case is still broken, and the task is marked done. The fix: run the `.cs` scenario once before the edit to
confirm it fails, as `rule-globs.md` and Task 14's move-aside baseline do.
Refuted: Dropped by the verifier. Refuted against the repo. `claude/rules/writing-code.md`'s `paths:` lists only kt,
java, ts, tsx, js, jsx, py, sh, zsh, kts, `bin/` and `hooks/`, so no `.cs` file can match, and the cause is proven by
inspection. Separately, the user's 2026-11-05 ruling asks to cover C# plus the common languages, so the change is
right whatever happened in the desktop session. Whether to add a baseline run is a test-case detail, which the
out-of-scope line covers.

### R7-16 · minor · scope and slicing

Task 13 · Deviation (2026-11-03, code review R3) and the 2026-11-05 Approvals block: Task 13 still needs a yes the
plan does not record: filing the follow-ups issue 'on the user's yes', which now also carries Follow-ups 15c and 15d
and the Revisit. Its delete commit lands directly on `main`, while the 2026-11-05 run approval describes work on
branch `ai-framework` with `main` fast-forwarded to it. Neither is in the 2026-11-05 bulk approvals, against the
global rule to ask in bulk up front. Scenario: The run reaches Task 13 after the record step. It either stops to ask
about the issue and about committing the delete directly to `main`, or treats the 2026-10-30 commit-to-`main` bullet
as covering the delete when the 2026-11-05 branch approval was meant to replace it. The fix: add both to the
2026-11-05 approvals block, or note that the 2026-10-30 bullet covers the delete commit.

### R7-17 · nit · scope and slicing

Task 15b · Tests, End to end ('Record here only that it ran, and the id'): The end-to-end test writes its result into
this plan after the commit the step runs on, but nothing says where that edit is committed. Task 13 then deletes the
plan, so the record of the test never lands. Scenario: After the final code review's commit, the session runs `ai-log
record`, then edits the plan to note the id. The edit either sits uncommitted until the Task 13 delete removes it, or
forces an extra commit that the window and the approvals do not account for. The fix: record the id in the follow-ups
issue Task 13 files, or in the log repo itself, rather than in the plan.
Refuted: Downgraded from minor by the verifier. Downgraded. The entry itself is committed and pushed to the log repo,
and its id is printed, so evidence that the end-to-end test ran survives in the log repo whatever happens to the plan
note. The lost note is in a plan Task 13 deletes minutes later, and nothing reads it afterwards. Where the note goes
is a wording fix, such as 'report it' or 'put it in Task 13's issue', not a failure.

### R7-18 · nit · scope and slicing

Task 15 · Change, Customer level, deferred (the clone's `allow` file): The `allow` file for non-GitHub company hosts
is built and tested even though Task 15 has no company Forgejo case in its spec. It is cheap, but it is a mechanism
nothing in the user's decisions asks for yet. Scenario: An executor builds and tests the `allow` parsing and host
matching for a host no current repo uses, which adds surface to the widest task. The plan could note it as optional,
or defer it until a company Forgejo repo needs recording.
Refuted: Dropped by the verifier. Refuted. The user's decision is to build the personal and Uptime part, and the
global CLAUDE.md says company work runs on Forgejo ('Forgejo work: every task has a Forgejo issue'). Without the
`allow` file, every company repo on a Forgejo host fails the github.com-only check and is silently never recorded. So
the mechanism serves a current company case the user asked to build. It also keeps unlisted customer repos out (R5-1,
R6-32), so it is not speculative surface.

### R7-19 · minor · decisions

Task 15, Change, *Customer level, deferred* (the `allow` file); the user's decision *Customer level deferred* ("build
the personal and Uptime part"): The plan never settles which company repos get recorded. Anything outside
`github.com/andrelin/…` and `github.com/uptimeconsulting/…` is treated as customer unless a `<host>/<owner>` line in
the private clone's `allow` file names it. The global CLAUDE.md treats company work as Forgejo work. No task creates
the `allow` file, and nothing says who decides its first entries. The executor would have to ask: "Where does Uptime's
day-to-day work live (which Forgejo host and owner), and should I seed `allow` with it in the log repo now, or leave
it empty?" Scenario: Tasks 15 and 15b ship with an empty `allow`. Every company plan on the company Forgejo prints
`customer level is deferred, nothing recorded`. The 'Uptime part' the user asked for records nothing, and nobody
notices until 15d finds no company entries. If the executor guesses the host instead, a company hostname goes into a
repo without the user choosing it.
Refuted: Downgraded from major by the verifier. Partly refuted. The gap is real: claude/CLAUDE.md treats company work
as Forgejo work, and work-contexts.md:95 says no customer uses Forgejo yet. So Uptime work on a company Forgejo would
hit the deferral unless `allow` names it. But the code Task 15 builds is the same either way. `allow` is a data file
in the user's private log clone, and it is read at run time, so seeding it later takes one line, with no rework and no
schema change. The failure isn't silent either: every such run prints `ai-log: customer level is deferred, nothing
recorded` in the report the skill step produces. The executor shouldn't guess a hostname. Asking the user for the
Forgejo host/owner while implementing settles it cheaply, so this is minor, not major.

### R7-20 · minor · decisions

§ Approvals, 2026-11-05 blocks; Task 13's 2026-11-05 deviation and its 2026-11-03 issue deviation: Task 13 makes two
writes that no 2026-11-05 approval covers. The first is the delete as "its own commit on `main`", made directly on
main rather than on `ai-framework` with a fast-forward, plus its push. The 2026-11-05 run bullet covers only the
branch, the commit after the final code review, the fast-forward and the push. The second is filing the follow-up
issue "on the user's yes", which was never asked. The global rule says to ask for these in bulk, up front. The
executor would ask: "May the delete be committed straight to main and pushed, and may I file the Task 13 follow-up
issue on andrelin/dotfiles?" Scenario: The run reaches Task 13 and either stops mid-run for two approvals it could
have collected up front, or treats the 2026-10-30 'commit to main' bullet as still live and commits and pushes the
delete on main. The 2026-11-02 and 2026-11-05 bullets replaced that bullet, so this would be a write the user never
approved.
Refuted: Downgraded from major by the verifier. Partly refuted. The 2026-10-30 bullet is approved 'for the rest of
this plan' and covers commit to main and push. The 2026-11-02 bullet replaces it only 'for that run', and the
2026-11-05 Task 14 note applies it again explicitly, so the delete commit on main and its push are covered. The issue
filing is gated 'on the user's yes', so the executor asks before the write and nothing unapproved happens. What stands
is that a foreseeable approval wasn't asked in bulk up front, which the global § Approvals requires. That costs one
mid-run stop and is cheap to fix by adding a bullet, so minor.

### R7-21 · minor · decisions

§ Approvals, "for the run started that day over the remaining tasks"; Handover step 0; Task 13 opening ("After every
other task, M included"): It is unclear whether Task 13 belongs to this run. The Approvals block says the run covers
"the remaining tasks", and the Task 13 deviation describes the fold being built and code-reviewed in the run. Handover
step 0, however, lists only 15, 15b and 16. Task 13 must also come after Task M, which is the user's to do by hand and
is still pending. The executor would ask: "Is Task 13's fold part of this run, before Task M is done? If not, which
later session runs it and its delete?" Scenario: One executor builds the fold now, ahead of M, breaking the stated
order. Another skips it, so the final commit and `ai-log record` run without the fold, and the delete-after-record
sequence the deviation relies on has no owner.
Refuted: Downgraded from major by the verifier. Mostly refuted. The plan's order is explicit: 'M is by hand… 13 comes
after every other task, M included'. Tasks 5, 8 and 9 are still PARTIAL and M is PENDING. Handover step 0 lists only
15, 15b and 16 for this run, and step 6 puts Task 13 last, after the by-hand items. An executor following the plan
does not build 13 now. 'Built and code-reviewed in the run' means whichever run does Task 13. The phrase 'the
remaining tasks' in Approvals is the only real ambiguity. Either reading is cheap to reverse: the fold is a docs
change, and M is untracked machine-local work, so building it early breaks nothing. Wording, at most minor.

### R7-22 · minor · decisions

Task 15b, Tests, *End to end, by the session*: "This plan's next final code review runs the step after its commit" can
be read two ways. It may mean this run's own final code review, whose commit contains 15b itself, or a later review,
in which case 15b's row can't close in this run. Either way, "Record here only that it ran, and the id" edits the
tracked plan after its last commit. That needs one more commit, on a branch or on main, that no approval names, and it
has to land before Task 13 deletes the plan. The executor would ask: "Which review is meant, and is the recorded id
committed, or left out because Task 13 deletes the plan?" Scenario: The executor marks 15b done without the end-to-end
run, or makes an unapproved follow-up commit to the plan after the run's final commit.

### R7-23 · nit · decisions

§ Approvals, 2026-11-05, "on every machine"; Task 15, Files ("cloned to `$HOME/.ai-framework-log`"): The standing yes
covers every machine, but nothing puts the log clone on the user's other machines. The plan doesn't say whether an
`init/` script or `bin/dotfiles` should clone it, or whether it stays a by-hand step. The executor would ask: "Should
the dotfiles installer clone andrelin/ai-framework-log, or does each machine clone it by hand?" Scenario: On the
second machine, every plan's completion reports exit 2 from `ai-log record`. Entries from that machine are silently
missing until the user clones by hand.
Refuted: Downgraded from minor by the verifier. The scenario's 'silently missing' is refuted. Exit 2's message names
`gh repo clone andrelin/ai-framework-log "$HOME/.ai-framework-log"`, and the skill step says 'A failure goes in the
report', so the second machine shows the failure and the fix on its first run. Cloning by hand per machine matches the
plan's Files line and needs no decision from the executor. An installer hook would be extra scope, not a gap that
blocks or misbuilds anything.

### R7-24 · minor · decisions

Task 15, Interfaces, the entry (`reviews[]`, `agents`, company-level counting): Several parts of the entry format,
which 15d reads and which stays in a pushed repo, are given only in prose. `reviews[]` lists "rows counted, `Done`
round, unfixed, re-evaluations, user decisions" without key names. Company level stores "custom agent types and MCP
tools as counts, not names", but the plan doesn't say what key a counted agent type takes in the `agents` map
(`<type>/<model>` → count), for example one `custom/<model>` bucket or a separate total. The hash for company `repo`
and `plan` is "like `plan_key`", but its input is not named. Scenario: The executor picks names. 15d and the Revisit
then read entries whose keys differ from what they expect, and changing them later means bumping `schema` and handling
old entries already pushed.
Refuted: Dropped by the verifier. Out of scope: JSON key names and bucket naming are output-format choices the
executor makes and a reviewer checks in the diff. The entry carries `"schema": 1`, and 15d is a sketch that will be
detailed only after real entries exist (plan review R4-25, the Revisit), so it will read whatever keys were built. No
requirement is violated.

### R7-25 · minor · decisions

Task 15, Interfaces (`questions` per session and in `totals`); Task 15b, `record` prints "user turns and questions":
`questions` can be read two ways. It could count `AskUserQuestion` calls only, which the tests check. It could also
include questions that end an assistant message, which Task 14 and Task 15's *What text* treat as questions to the
user. The second reading needs the assistant's text, which the no-free-text rule otherwise keeps out of the script's
output. Scenario: One build counts only `AskUserQuestion` calls, and these are rare in practice. The introspection's
"questions" evidence then reads near zero on runs where the user was asked many questions at the ends of messages.
Refuted: Dropped by the verifier. Settled by the plan. Task 15's Counts test names `AskUserQuestion` calls as what is
counted. The no-free-text rule and the deferral of questions-ending-a-message to 15c (What text, the re-slice) make
that reading deliberate. Whether the count is enough evidence is exactly the Revisit's question. This is a choice the
executor makes, and a reviewer can check it against the test, so it is out of scope.

### R7-26 · minor · decisions

Task 13, Files and Tests (`git ls-files 'plan-ai-framework*'` prints nothing): Files names three files to delete. Two
closed findings files are also tracked: `plan-ai-framework-review-findings-code-closed-2026-11-05.md` and
`plan-ai-framework-review-findings-plan-closed-2026-11-05.md`. A third, `…-plan-closed-2026-11-05-2.md`, is untracked.
The plan doesn't say whether those are deleted, or whether they go into the issue first. Scenario: An executor who
deletes only the listed files fails Task 13's own `git ls-files` test. One who deletes all of them removes closed
review logs without anyone deciding to.

### R7-27 · nit · decisions

Task 16, Spec and Tests: The user reported the problem in a desktop session, but the test checks only headless `claude
-p`. Nothing confirms that the missing glob caused the desktop failure, rather than the desktop app loading
path-scoped rules differently. The extension list is fixed, but "C# plus the common languages" leaves .NET's other
source types (`.razor`, `.cshtml`, `.fs`), `.hpp` and `.cc`, and `.mjs` and `.cjs` unruled. The executor may ask
whether those are in or out. Scenario: The headless test passes, but the rule still doesn't load for the user's `.cs`
file in the desktop app, so the reported problem stays. Or Razor and F# files in a .NET repo still miss the rule.
Refuted: Downgraded from minor by the verifier. Mostly refuted. The cause is shown statically: the rule's `paths:` has
no pattern matching `.cs`, so it cannot load for a `.cs` file in any client, and the fix is needed whatever the
desktop app does. The extension list is the user's own ruling ('C# plus the common languages'), and the plan fixes it
explicitly. Adding `.razor`, `.fs`, `.hpp` and the like is a choice the executor can make and a reviewer can check in
the diff. What remains is wording: the test could also note a desktop spot-check.

### R7-28 · minor · consistency

Task 13, Files and Tests (and its 2026-11-03 deviation, 'both findings files are tracked'): Task 13 deletes only
`plan-ai-framework.md`, `-review-findings-plan.md` and `-review-findings-code.md`. Task 14's run closed logs on
2026-11-05, so `git ls-files` now also tracks `plan-ai-framework-review-findings-code-closed-2026-11-05.md` and
`plan-ai-framework-review-findings-plan-closed-2026-11-05.md`, and `-plan-closed-2026-11-05-2.md` exists untracked.
The iteration did not fold those closed files into the Files list. Scenario: The executor deletes the three listed
files. Task 13's own test, `git ls-files 'plan-ai-framework*'` prints nothing, then fails on the closed findings
files. The `git grep plan-ai-framework` check may also hit them. The Files list is the commit pathspec, so it has to
be fixed mid-task.

### R7-29 · minor · consistency

Task 16, Change: 'The rule stays under its 30-line aim': `claude/rules/writing-code.md` already has 27 counted lines:
`bin/check-md-limits` counts front matter and skips only the blank lines and the heading. Adding 11 globs one per line
puts it at about 38 lines, plus any wrap from the `.editorconfig`/`dotnet format` addition. The two requirements in
this task cannot both hold. Scenario: The executor adds the globs as instructed and finds the rule at about 38 lines.
That passes the hard cap of 50 but breaks the plan's own statement. They have to stop and choose between fewer globs,
a combined brace glob, or a deviation.

### R7-30 · minor · consistency

Task 13, 2026-11-03 deviation: list of open items for the issue: The list still names 'Task 7's conflict sent to the
user' as an open item. That conflict was decided and applied on 2026-11-05 (Approvals, Handover item 5, status row 7).
The list was not updated for what the built task settled. Scenario: The Task 13 executor files the issue from this
list and either carries an already-settled conflict as open or spends time checking it. That noise ends up in the
durable issue.

### R7-31 · minor · consistency

Handover item 6 vs Task 13 deviation and Handover item 0: Handover item 6 lists what goes into Task 13's issue as
'(the `Deferred:` lines, the audit's recorded Mediums and Lows, R12-4)'. It leaves out follow-ups 15c and 15d and the
Revisit's question, which Handover item 0, the Order paragraph and Task 13's deviation all route to that issue. Task
13's deviation, in turn, omits the audit's Mediums and Lows and R12-4. The two lists disagree. Scenario: An executor
who starts from the handover files the issue without 15c, 15d and the Revisit, so the plan's delete loses them. One
who starts from Task 13 loses the audit items.

### R7-32 · minor · consistency

Approvals, 2026-11-05 run block, vs Task 13's 2026-11-05 deviation: Two foreseeable writes in the remaining run are
missing from the bulk approval. The 2026-11-05 run approval covers commits 'after the final code review, `main`
fast-forwarded'. Task 13's deviation adds a separate delete commit directly on `main` after that, outside any code
review. It also files the GitHub issue 'on the user's yes'. Neither is named in the bulk approval, which breaks the
global rule to ask in bulk, up front, with each approval naming its scope. Scenario: The run reaches Task 13 and stops
twice to ask: once for the direct `main` delete commit and once for filing the issue. Or it treats the 2026-10-30
'commit to main' bullet as covering a write that later approvals replaced for run-style work.

### R7-33 · minor · consistency

Task 15b, Files: text added to `claude/docs/work-contexts.md` § An approval covers one action, not a policy: That
section currently says approvals expire with the change, that you 'ask again, every time', and that 'the workflow
skills never commit on their own'. Task 15b only says the section 'gains' a sentence about a standing yes for `ai-log`
commits and pushes. Adding it without amending the existing sentences leaves the doc contradicting itself. Scenario:
After the change, a session reading work-contexts.md finds both 'skills never commit on their own / ask again every
time' and 'reviewing-in-rounds runs ai-log, which commits and pushes on a standing yes'. It then either asks before
every `ai-log` push, against the user's yes, or loses trust in the section's rule.

### R7-34 · minor · consistency

Task 15b, Files (work-contexts.md wording) vs Task 15 entry schema: The durable doc text says what leaves the machine
is 'counts, durations, tokens, estimated dollars and versions, and the introspection'. Task 15's entry also stores
repo and plan names at personal level, `plan_key` and `id` hashes, model ids, tool, skill, agent-type and lens names,
commit shas and timestamps. The disclosure does not match what the entry produces. Scenario: A reader of
work-contexts.md concludes that repo and plan names never leave the machine, but every personal-level entry pushes
them to the log repo.

### R7-35 · minor · consistency

Task 15b, The mechanical redaction, vs Task 15, 'Company level, names hashed or counted (R6-33)': Task 15 hashes
`repo` and `plan` at company level because company repos and plans are often named for an engagement. Task 15b's
redaction list covers the remotes' hosts, owners and names and the folder names, but not the plan basename or stem. It
also has no company-level difference, so the lesson from R6-33 is not carried into the introspection. Scenario: At
company level the model writes an introspection such as 'the `<engagement>`-migration plan's review…'. `note` keeps the
plan's engagement name in `entries/<id>.md`, while the JSON beside it holds only the hash.

### R7-36 · nit · consistency

Task 15, Files (outside this repo) vs Change, Customer level: The customer gate reads a `<host>/<owner>` `allow` file
in the private clone, but Task 15's description of the log repo lists only `entries/` and a `README.md`. The `allow`
file is never named as something created or documented. Scenario: A company Forgejo repo prints 'customer level is
deferred, nothing recorded'. Neither the log repo README nor the tip says an `allow` file exists to fix that.

### R7-37 · nit · consistency

Follow-up 15c sketch, 'a model terms pass … runs at every level, since a customer repo not yet in ~/.claude-customers
resolves as company': Task 15's allowlist gate (R5-1, R5-37, R5-38, R6-32) already treats any origin outside
github.com/andrelin, github.com/uptimeconsulting or the `allow` file as customer. The sketch's reason for running the
pass at every level predates that gate and was not updated. Scenario: Whoever details 15c builds a pass at every level
on a reason that no longer holds, or has to work out the current reason again.

### R7-38 · nit · consistency

Task 15 Interfaces ('Produces, for Tasks 15b to 15d'), Task 15 decisions and Approvals ('Task 15c', 'Task 15c's
test'): 15c and 15d were renamed 'Follow-up 15c/15d', and the plan says they are 'not tasks of this run', with no
status row. Other sections still call them Task 15c and Task 15d. Follow-up 15d also lists 'stages' among cut
candidates, but Task 15 dropped the stage split (R6-1). Scenario: A reader looks for a Task 15c status row or section
and finds none.

### R7-39 · major · work context

Task 15, Interfaces (the entry's `framework.plugins` and `skills_outside`) and Change, *Framework* / *Company level,
names hashed or counted*: The entry stores every installed plugin by name, from the machine-wide
`installed_plugins.json`, at personal and company level. Their skills and agent types are stored by name too. Only
Task 15c, which is deferred, folds plugin and marketplace names off an allowlist. The user's requirement for the log
repo is 'Still free of customer details'. A plugin from a customer's marketplace usually names the customer or its
internal tooling, and nothing in Tasks 15 or 15b keeps that name out. Scenario: The user installs a customer's plugin,
say `acme-internal-tools@acme-marketplace`, for customer work. The next personal-level `ai-log record` on any dotfiles
plan writes `framework.plugins.acme-internal-tools` into the entry, then commits and pushes it to
`andrelin/ai-framework-log` without asking, under the standing yes. Removing it afterwards means rewriting history.
Task 15's real-data check would not catch it: the grep looks only for `~/.claude-customers` entries, and a plugin name
need not match any of them. Fix: fold plugins outside a short allowlist (Anthropic's and `superpowers`) at every level
now, as 15c's note already proposes, or store only a count.
Fixed: plugins are named only for Anthropic's own marketplaces and `superpowers`; others, their skills and agent
types, are `other` with a count.

### R7-40 · major · work context

Task 15b, Change, *The mechanical redaction* (with Task 15, *Company level, names hashed or counted*): Task 15 hashes
`repo` and `plan` at company level because company repos and plans are often named for an engagement (R6-33). The
redaction of the introspection does not cover the plan's basename, the branch name or the commit subjects. The
hostname pattern deliberately spares file names such as `SKILL.md`, so `plan-acme-migration.md` passes through
untouched. The prompt's 'no customer names' is model compliance, which nothing verifies, and the model terms pass is
deferred to 15c. Yet the 2026-11-05 Approvals already store company-level introspections. Scenario: A company plan
`plan-acme-sso.md` on branch `acme-sso`: the model writes 'Worked: plan-acme-sso.md's review settled in 2 rounds
(rounds: 2)'. `note` sees no customers-file entry, no remote name, no host and no path, so it pushes the engagement
name to the log repo. That defeats the hashing the JSON entry does for the same reason. Fix: add the plan basename
(with and without `plan-` and `.md`), the current branch and the work repo's name parts to the redaction terms at
company level, and test it.
Fixed: with R7-3.

### R7-41 · minor · work context

Task 15b, Files: the text added to `claude/docs/work-contexts.md` § *An approval covers one action, not a policy*: The
sentence the docs gain says what leaves the machine is 'counts, durations, tokens, estimated dollars and versions, and
the introspection'. At personal level the entry also stores the repo (`<owner>/<name>`), the plan basename, and skill,
tool, MCP-tool, agent-type and plugin names (Task 15, *Company level* and *No free text*). The published doc that
justifies the standing exception would understate what is pushed. Scenario: A reader, or a later session judging
whether the standing yes still holds, relies on the doc. They conclude no names leave the machine, and approve
recording on a repo whose name or tools they would not have wanted logged. Fix: list names (personal level) and hashes
(company level) in that sentence.

### R7-42 · minor · work context

2026-11-05 Approvals block; Task 13, deviation (2026-11-05): The deviation makes the delete 'its own commit on `main`,
after the run's last commit has landed there', and it then has to be pushed. The 2026-11-05 Approvals cover this run
working on branch `ai-framework`, being committed after the final code review, `main` being fast-forwarded, pushed and
CI watched, plus the log-repo writes. None of them names a direct commit to `main` for the delete, or its push. The
level allows it (personal public), but the global § *Approvals* says an approval covers only what it names, and to ask
in bulk up front. Scenario: The executor reaches Task 13's delete. Either it stops mid-run to ask for a write that
could have been foreseen, or it treats the branch approval as covering a commit straight to `main`, which is the
neighbour-approval overreach the rule forbids. Fix: add 'commit Task 13's delete directly on `main` and push it, CI
watched' to the 2026-11-05 Approvals.
Refuted: Dropped by the verifier. The 2026-10-30 Approvals cover it. They were 'asked in bulk... for the rest of this
plan', and their first bullet is 'Commit each change to `main`... push to `origin main` and watch CI'. The 2026-11-02
bullet replaced that only 'for that run'. The 2026-11-05 run bullet adds the branch flow for that run's work but does
not revoke the standing bullet, and the 2026-11-05 note on Task 14 re-applies the same bullet. A direct commit on
`main` for Task 13's delete, its push and the CI watch are therefore named in an existing approval. This is not
neighbour-approval overreach.

### R7-43 · nit · work context

Task 15b, Change, *The skill step* ('run `ai-log record <plan-file>` and do what it prints, without asking'), with
Task 15, Interfaces, exit 2: On a machine without the log clone, `record` exits 2 with a message naming `gh repo clone
andrelin/ai-framework-log "$HOME/.ai-framework-log"`. The skill step tells Claude to 'do what it prints, without
asking'. Read literally, that has Claude clone the private repo into `$HOME` on its own, outside the standing yes,
which names only `record`'s and `note`'s commit and push. The approval says 'on every machine', so the first run on a
new machine hits this path. Scenario: On a second machine, at the end of a company plan, `record` exits 2. Claude
follows 'do what it prints' and runs `gh repo clone` into `$HOME` unasked, then retries. If the step is instead read
narrowly, it is unclear whether a failure goes in the report. Fix: say in the step that only the introspection prompt
is to be followed, and that a non-zero exit is reported, never acted on.
Refuted: Downgraded from minor by the verifier. Downgraded. The same skill step already says 'A failure goes in the
report and never undoes the commit', and an exit 2 is a failure, so reading it as 'report it' is supported by the
text. A `gh repo clone` of the user's own private repo writes nothing to a remote or platform. How the step handles a
non-zero exit is mostly error handling, which is out of scope. What remains is a wording tightening: 'follow the
introspection prompt only'.

### R7-44 · nit · work context

2026-11-05 Approvals block, 'Added 2026-11-05 by the iteration that detailed Task 15', first bullet: The bullet grants
'at every level' and 'on every machine'. Two lines later the same block says customer level records nothing until Task
15c, and Task 15b says `note` never runs there. The wording grants a customer-level push that no step makes, and the
yes 'lives on in the skill step', which also says 'at every level'. Scenario: After this plan is deleted, a reader of
the skill step sees 'at every level' and takes it as standing consent for pushes from customer sessions once 15c
lands. 15c's stored text at customer level is a materially different payload, and it would ship with no fresh
question. Fix: word the yes as 'personal and company level until Task 15c, which asks again for customer level'.
Refuted: Dropped by the verifier. 'At every level' is what the user approved. The Approvals' second bullet, answered
yes, says entries store the prompts, questions and introspection 'at every level', and the *What text* decision says
'at every level, customer included'. Task 15c is explicitly 'governed by their decisions of that day'. Customer-level
pushes after 15c are therefore within the user's yes, not a grant beyond it. Until 15c, Task 15 makes `record` exit
before any write at customer level, and 15b's doc sentence says nothing leaves the machine there. Nothing is
mis-granted.

## Round 8

### R8-1 · blocking · grounding

Task 15b, 'And at the end of every session' paragraph (the new implementing-plans line); § Approvals 2026-11-05, last
bullet ('Tasks 9 and 15b make that the session-end rule for every run'): The line Task 15b adds to
`implementing-plans` makes every session that ends before the final code review commit the work in progress and run
`git push -u origin <branch>`. It has no level gate. `implementing-plans` runs at every level, and at customer level
`git commit` and `push` are forbidden writes under the global § Work contexts. Compare `reviewing-in-rounds` §
Completion step 4, which only drafts the commit at customer level. Personal and company level are a problem too. The
line commits and pushes without asking, but the only recorded yes is scoped to 'each session of this run'. Promoting
it to a standing rule for every future run is not something the user was asked about, and per § Approvals an approval
covers only what it names. Scenario: A customer repo, a plan run stopped at the end of the day. The skill tells Claude
to commit and push the branch. The guard blocks it, so the step 'fails' every time, and the skill now tells Claude to
attempt a forbidden write. In a later personal-level run with no session-end yes in its plan, Claude commits and
pushes without asking.
Fixed: The session-end rule moved out of Task 15b into a new Task 17 · Session-end save. Its skill section runs at
personal and company level only, on the user's standing yes, which § Approvals now records as a rule for future runs,
quoting the question; at customer level `plan-wip save` commits and pushes nothing and prints what is uncommitted.

### R8-2 · major · grounding

Task 15b, session-end paragraph ('main still waits for the final review, which diffs from Base: and so is unchanged by
these commits'); interaction with reviewing-in-rounds § Completion steps 1-4: The plan checks that work-in-progress
commits leave the review diff intact. That part holds: the review input is the working tree against `Base:`, which I
verified. It does not check Completion's commit step. That step builds per-task commits from `git diff --cached`, the
index against `HEAD`, so it only sees changes made after the last work-in-progress commit. The history that reaches
`main` then becomes one or more 'WIP' commits plus partial per-task commits. That breaks the company bar of 'a
readable history before it reaches main' and the one-commit-per-task design. The plan file is also affected. At
company and customer level it is in `info/exclude`, and `implementing-plans` says 'The plan file is never staged'. Yet
the real work-in-progress commit d88b6fa carried `plan-ai-framework.md`, which is what lets another machine resume. At
company level that commit can't carry the plan, so resuming on another machine (the user's reason for the rule) stops
with 'branch exists but plan has no Base: line'. Scenario: A company-level run spans two days. Day 1's session-end
commit holds Tasks 1-3. Day 2 finishes Tasks 4-5 and the code review. Completion's `git diff --cached` lists only Task
4-5 paths, and `main` is fast-forwarded to 'Record work in progress' plus two task commits. On the second machine,
`git pull` brings the branch but no plan file, and the run can't resume.
Fixed: The session-end rule moved out of Task 15b into a new Task 17 · Session-end save. Per the user's 2026-11-09
ruling, where `main` is fast-forwarded (as here) the save goes to the private ref `refs/wip/<branch>`, so the branch,
Completion's per-task commits and `main` are untouched; the save holds the index, the leftovers and the plan files
even untracked, so a company-level plan reaches another machine through it. Only a squash-merged-PR run commits on the
branch, where Completion commits what is left and the squash makes the split moot.

### R8-3 · minor · grounding

Task 15b, session-end paragraph ('its resume checks ... must hold across a work-in-progress commit — the task's tests
show it'): The plan never says what a session-end commit contains, yet whether the resume check survives depends on
it. One option is staged checkpoints only. Then an in-progress task's unstaged work stays out of the commit and never
reaches the other machine. The other is everything (the listing, unstaged included). Then `git write-tree` (index =
HEAD) no longer equals the last checkpoint's `<ref>^2^{tree}`, so resume step 1 stops and asks. Checkpoint refs are
also local-only (`refs/checkpoints/...` aren't pushed), so on another machine the check falls back to `HEAD^{tree}`.
The task asserts the checks hold without deciding which behaviour it relies on. Scenario: A session ends mid-task with
an implementer's edits unstaged. If the commit includes them, the next day's resume on the same machine compares the
index with checkpoint ref ^2, which differs, and stops. If the commit leaves them out, the user resumes on another
machine and the half-done task is missing.
Refuted: Downgraded from major by the verifier. Downgraded to minor. The gap is real: the plan never says what a
session-end commit holds, and the resume check compares `git write-tree` with `<ref>^2^{tree}`. But this is cheap to
settle while implementing, and a reviewer can check it in the diff and tests. The 2026-11-05 handover already shows a
workable answer: the checkpoint ref was deleted once the commit held it, so a resume compares the index with
HEAD^{tree}. Committing staged checkpoints and dropping their refs keeps both checks passing. The cross-machine loss
of the plan file is finding 1's major, not this one.

### R8-4 · minor · grounding

Task 15b, session-end paragraph ('a session ending before the final code review commits ...'): The trigger assumes
Claude knows when a session is ending. Nothing tells the model. The plan itself rejects a `SessionEnd` hook as having
no model. The cases that actually end a run (the user closing the terminal, a usage-limit death, a stop to ask, a
crash) give Claude no turn in which to act. In practice the step only runs when the user explicitly says 'wrap up'.
The simpler, grounded approach is to name that trigger (a user's wrap-up request, or the run's own stop points such as
a stop-and-ask or the final report of a partial run) rather than 'a session ending'. Scenario: A run dies on the usage
limit or the user quits at 18:00. Nothing is committed, pushed or recorded, so the next day's work on another machine
finds the branch stale. That is the failure the rule was meant to prevent.
Refuted: Downgraded from major by the verifier. Downgraded to minor. It is true that Claude gets no turn when the user
closes the terminal, the usage limit hits or the session crashes. No wording can fix that, and the plan already
rejects SessionEnd hooks for having no model. The fix is to reword the trigger in one skill line: the user's wrap-up,
a stop-and-ask, or a partial run's final report. That is cheap while implementing and easy to reverse. The approach
does not rest on detecting every session end: the one real session end so far (2026-11-05) was a wrap-up and worked.

### R8-5 · major · grounding

Task 15, Interfaces/entry ('tokens ... per review lens — a workflow agent's .meta.json description (review:`<lens>`,
verify:`<lens>`)'); Change, Framework: Cost per lens rests on a convention that nothing in the repo guarantees. I
verified that `review:<lens>` and `verify:<lens>` labels exist in this session's workflow agents' `.meta.json`. They
come from ad hoc Workflow scripts the session wrote (`workflows/scripts/plan-review-round-1-*.js`).
`reviewing-in-rounds` specifies 'one fresh Agent per lens', and Agent-tool subagents' `.meta.json` `description` is
free text such as 'Round 5: review tasks 0-3'. A review run the way the skill says produces no lens attribution, so
Task 15d's cut candidates by lens get no data. Either the skill (or a shared workflow script) must fix the label
format, or this field must be dropped. Scenario: A later plan review follows `reviewing-in-rounds` literally with
Agent calls. Every lens's tokens land in an empty or 'unknown' bucket, and the cross-session report can never flag a
lens that isn't pulling its weight.
Fixed: Task 15 takes an agent's lens from the `Lens:` line of its prompt, which `reviewing-in-rounds` writes literally
into every reviewer's prompt, for an `Agent` or a Workflow agent alike, matched to `review-lenses.md`'s headings; a
verifier counts under a lens only when its prompt carries the line; the prompt is never stored. `.meta.json`
descriptions are no longer used.

### R8-6 · minor · grounding

Task 15, Tests, 'Real data, last' ('while HEAD is still the Base: commit'): The premise is already false. `Base:` is
cdf0a77, and branch `ai-framework` has four commits on top (d88b6fa ... 5b563f3), including the session-end commit
that this very change introduced. The executor can't meet the stated condition. With `--dry-run` and no `<commit>` the
window ends now regardless, so the condition should be dropped or restated. Scenario: The executor reads 'while HEAD
is still the Base: commit', finds HEAD at 5b563f3, and stops to ask, or reverts HEAD to satisfy the test.

### R8-7 · minor · grounding

Task 15, Tests, Counts ('at company level the plan's and branch's words redacted from the introspection (15b)'): Task
15's test list includes an assertion about the introspection's redaction. Introspection and `note` are Task 15b's, so
Task 15 can't build or pass this test on its own. Scenario: The Task 15 implementer must either build part of `note`
early or leave a listed test unmet, and its task review fails on a test that belongs to 15b.

### R8-8 · minor · grounding

Task 15b, session-end line ('runs ai-log record `<plan-file>`'); Task 15b Change, 'record prints ... write a short
introspection ... Pipe it to ai-log note': `record` always prints the introspection prompt. The completion step says
'do what it prints', but the session-end line only says 'runs'. It is unclear whether each session end also writes an
introspection. The user asked for one 'after every plan'. Separately, if the session-end commit was skipped (nothing
to commit), `record` hits exit 1, 'HEAD no newer than the window's start'. Scenario: The plan spans three sessions.
Either it gets three introspections where the user wanted one per plan, or none for the partial sessions, depending on
how the model reads the line. A session end with no new commit reports an ai-log failure every time.

### R8-9 · minor · grounding

Task 13, 2026-11-05 deviation and Files/Tests: The delete covers three named files. The tree now also tracks
`plan-ai-framework-review-findings-code-closed-2026-11-05.md`, `...-plan-closed-2026-11-05.md` and
`...-plan-closed-2026-11-05-2.md` (verified with `git ls-tree`). Task 13's own test, `git ls-files
'plan-ai-framework*'` printing nothing, fails unless they go too, and the Files list doesn't say they should.
Scenario: The executor deletes the three listed files, and the test still lists three closed logs. Either the task
fails or the executor guesses whether closed review logs are meant to survive on `main`.

### R8-10 · nit · grounding

§ Approvals, 2026-11-05 session-end bullet ('Tasks 9 and 15b make that the session-end rule'): It credits Task 9, but
only Task 15b's text changes `implementing-plans` for this. Task 9 isn't in the remaining build list ('build 16, 15
and 15b'). Scenario: A reader looks in Task 9 for the session-end rule and finds nothing.

### R8-11 · blocking · scope and slicing

Task 15b, 'And at the end of every session' paragraph; § Approvals, 2026-11-05 block, last bullet ('Tasks 9 and 15b
make that the session-end rule for every run'): The session-end line added to `implementing-plans` makes every session
that ends before the final review `git commit` and `git push -u origin <branch>`, and nothing limits it to personal
and company level. The approval bullet widens a yes given for this run's sessions into 'the session-end rule for every
run'. At customer level, commit and push are forbidden writes. `reviewing-in-rounds` § Completion step 4 already
splits this by level ('Customer: draft it for the user'), and this line drops that split. The global decision
'Implementation checkpoints in the index at every level … the user commits at the end' is also reversed with nothing
said about customer level. Scenario: An `implementing-plans` run on a customer repo reaches the end of a session. The
skill tells the agent to commit and push. The guard blocks it, or, through a path the guard misses (the plan itself
records `git -C $var` gaps), the client's history gets a work-in-progress commit pushed to their remote. Fix: make the
line 'personal and company: commit and push; customer: draft both for the user', and limit the approval to what the
user's words named.
Fixed: The session-end rule moved out of Task 15b into a new Task 17 · Session-end save. It is gated to personal and
company level; at customer level it writes nothing and prints what is uncommitted. § Approvals scopes the yes as the
user gave it, quoting the question that made it a rule for future runs.

### R8-12 · major · scope and slicing

Task 15b, session-end paragraph ('its resume checks … must hold across a work-in-progress commit — the task's tests
show it'): The plan assumes a work-in-progress commit leaves the rest of `implementing-plans` and the code-review
completion unchanged, and it never checks that or names a test that would. Several parts depend on 'nothing is
committed': the skill's review input replaces `scripts/review-package` 'since nothing is committed and `BASE..HEAD` is
empty' (SKILL.md:64). The checkpoint refs are `git stash create` against the old `HEAD`. `reviewing-in-rounds` §
Completion step 2 builds one commit per task from `git diff --cached` file lists, and that index is empty for any task
a work-in-progress commit already took. 'The final review diffs from `Base:` and so is unchanged' covers only one of
these consumers. This is a change to a core rule of the skill, and it rests on a claim nobody has verified. Scenario:
A session ends after Tasks 1 and 2 are checkpointed, and the work-in-progress commit takes them. On resume, the review
input is no longer empty. The final completion finds nothing staged for Tasks 1 and 2, so it either makes one combined
commit or none for them, and the per-task history is lost. The stale checkpoint refs also trip the resume check 'index
against the last checkpoint'. Name the resume, review-input and completion behaviour as tests, or run a toy plan
across a session end before building on this.
Fixed: The session-end rule moved out of Task 15b into a new Task 17 · Session-end save. Its Change states what each
consumer sees: the branch case commits only the index, so task-review input and checkpoint refs hold; the ref case
changes no branch; resume and the before-staging check gain one clause each; Completion is unchanged. Its tests run
save and restore in scratch repos with a bare origin, including a fresh clone and the resume checks.

### R8-13 · minor · scope and slicing

Task 15b, session-end paragraph and its Files line ('Files gain `claude/skills/implementing-plans/SKILL.md`'):
Slicing: Task 15b, the `ai-log` trigger and introspection, also carries an unrelated change to the workflow itself:
commit and push at every session end. It was added after review round 7 and marked 'not yet reviewed', and it reverses
`implementing-plans`' rule that nothing is committed. Nothing ties it to `ai-log` except that it also calls `record`.
Bundled like this, it can't be reviewed, tested or reverted on its own, and if it fails, the trigger work goes down
with it. Scenario: The session-end commit turns out to break the per-task commits at completion (see the finding
above). Reverting it means unpicking Task 15b's diff, and with it the `note` command and the trigger step, which have
nothing to do with it. Split it into its own task against `implementing-plans`, with its own tests, ordered before 15b
so its `ai-log record` call has a tested command to call.
Refuted: Downgraded from major by the verifier. Downgraded. The bundling is real: the session-end commit rule has
nothing to do with `ai-log note` or the trigger. But it is one line in one skill. Moving it into its own task, or
reverting it, is cheap, and the plan can settle it while implementing. Finding 1 already covers the real risk, that
the rule breaks completion. Being bundled does not make the change costly to reverse.

### R8-14 · major · scope and slicing

Task 13, first paragraph and 2026-11-05 deviation; Implementation status, Order ('13 comes after every other task, M
included'); Handover, 'Start next session here': Three passages give different orders for the end of the plan. Task 13
says its fold is 'built and code-reviewed in the run like any task' and comes after Task M, which the user does by
hand and which is still pending. Its deviation puts the `git rm` after the final code review's commit and 15b's
record. The Handover runs '16, 15 and 15b, then the final code review, commit, fast-forward `main`', leaving out 13's
fold and M entirely. An executor can't tell whether the final code review waits for the user's Task M and then covers
the fold, or runs now and leaves the fold for a second review. Scenario: The driver follows the Handover and runs the
final code review, its commit and 15b's `record`. Then it reaches Task 13, whose fold of `staged-workflow.md` and
`work-contexts.md` is new, unreviewed code. Either it reopens a code review after `Done (code):`, or it fast-forwards
`main` with unreviewed docs. The other choice stalls the run on Task M, which only the user can do. State one order:
fold, then final review, then record, then the `git rm`, and say whether M blocks it.
Fixed: One order now: 13's fold is the run's last task, covered by the one final code review; M is by hand and blocks
nothing, an open M going into Task 13's issue; the `git rm` follows that review's commit and `ai-log record`, before
`main` is fast-forwarded. Task 13, the Order line and the Handover say the same.

### R8-15 · minor · scope and slicing

Task 15, Tests, 'Real data, last, by the session': The approach rests on one assumption: that the token sums and
session scoping from real transcripts match reality, which the `cost-state` price check and the in-scope detection
test. That is checked last, after windows, review keys, company hashing, the plugin allowlist and the log-clone push
are all built against invented fixtures. Field names do exist (`.meta.json` `description: review:<lens>` and
`workflowPhase` were checked on a real file), but whether sums and scope come out right on real data isn't known until
the end. Scenario: The price check shows tokens counted roughly twice, for example because forked sessions or workflow
agents are mis-scoped. The fix reshapes the dedup and scope code that every later fixture test was written against.
Run the `--dry-run` with the price check right after the scope, window and token core works, before the review,
company and framework parts.

### R8-16 · minor · scope and slicing

Task 15, Tests, 'Counts' bullet ('at company level the plan's and branch's words redacted from the introspection
(15b)'): Task 15's tests include behaviour that Task 15b builds. Redacting the introspection belongs to `note`, which
doesn't exist until 15b, so as written Task 15 can't end green. Scenario: An implementer of Task 15 tries to write the
test and finds no introspection to redact. They either stub `note` early or mark the task done with a test that fails.
Move the assertion to 15b's Redaction tests.

### R8-17 · minor · scope and slicing

Task 15, Interfaces (entry `workflows` tokens per `workflowPhase`, tokens per agent type and per review lens, R7-2):
Task 15 builds per-lens and per-phase token breakdowns for Task 15d's cut candidates. Task 15d is a sketch and not a
task of this run, and the Revisit exists to decide from real entries what an entry needs. The reason given, that
transcripts are lost after 30 days, is real but small, since only a few runs would go unrecorded. So the slice billed
as 'counts only' is wider than its own requirement. Scenario: The Revisit decides cut candidates need a different
grouping, such as per round or per verifier verdict. The per-lens fields then sit in `schema: 1` as dead weight that
every later schema has to carry. Either keep them and state the reason as a decision, or drop them until the Revisit
asks for them.
Refuted: Dropped by the verifier. The plan already states the reason as a decision: '...so cost by lens and agent
type, which transcripts lose after 30 days, is kept for Task 15d's cut candidates (plan review R7-2)'. The finding's
own remedy, 'keep them and state the reason as a decision', is what the plan already does. The 'dead weight in schema
1' scenario is speculative, with no requirement violated.

### R8-18 · minor · scope and slicing

Task 15, Tests, last bullet ('No real `record` runs here: the first is Task 15b's end to end'), against § Approvals
2026-11-05 session-end bullet and Task 15b's session-end line: Two parts of the plan disagree about the first real
`record`. Task 15 says it is 15b's end-to-end run at the final code review. But once Task 15 is built, the session-end
rule runs `ai-log record <plan-file>` at every session end of this run. The session-end line also doesn't say whether
the introspection that `record` then asks for gets written and sent to `note`. That would be one introspection per
session, where the user asked for one 'after every plan'. Scenario: A session ends between Task 15 and 15b. The driver
runs a real `record`, which pushes to `andrelin/ai-framework-log` before 15b's redaction exists. `record`'s output
then asks for an introspection that `note` can't yet take. Say whether session-end records start only after 15b, and
whether a session end writes a note.

### R8-19 · minor · scope and slicing

Task 16, Spec and Tests ('Loads where it should' runs headless `claude -p`): The user reported the rule failing to
load in a desktop session. The fix assumes the cause is the missing glob, and the test checks only headless CLI
loading. Out of scope isn't stated: other path-scoped rules that might miss the same languages, and whether the
desktop app honours `paths:` at all. Scenario: After the change the headless test passes, but the user's next `.cs`
file in the desktop app still runs without the rule, because the desktop host loads path rules differently. The task
is marked done and the reported bug remains. Add the desktop check to the user's by-hand list, or record it as out of
scope.
Refuted: Dropped by the verifier. The cause is visible in the repo: `claude/rules/writing-code.md`'s `paths:` lists
only kt/java/ts/tsx/js/jsx/py/sh/zsh/kts, with no `.cs`, so the missing glob is a proven cause, not an assumption. The
claim that the desktop host loads path rules differently has no evidence behind it, so the failure scenario is
unsupported.

### R8-20 · nit · scope and slicing

Task 16, Change ('Front matter leaves the line count'): A checker change for every file is bundled into a task named
for one rule's globs. `bin/check-md-limits` stops counting front matter for all files, and the title doesn't say so.
The narrow fix is the globs. The checker change is a separate behaviour with its own tests, and it affects every skill
and rule. Scenario: A reviewer or a later `git log` reader looking for why skills got longer front matter never finds
a task titled for it. A revert of the C# globs would also revert the checker. Name it in the title or split it, with
the checker change first, since the rule's line budget depends on it.
Refuted: Downgraded from minor by the verifier. Downgraded to nit. The checker change is not hidden. Task 16 gives it
its own bold paragraph with the user's quoted ruling, its own Files entries (`bin/check-md-limits`,
`test/test_check_md_limits.sh`, `claude/docs/markdown-limits.md`) and its own tests, and the Handover's item 0 flags
it for review. Only the title fails to name it, which is a wording matter.

### R8-21 · minor · scope and slicing

§ Approvals, 2026-11-05 block; Task 13 deviation ('filed with `writing-issues` on the user's yes'); Handover item 6:
The 2026-11-05 bulk approvals don't include filing Task 13's issue, which every other source says needs the user's
yes. That is a foreseeable approval left out of the up-front batch, which the global § Approvals requires. Scenario:
The run gets through the final review, `record` and the fold, then stops at its last step to ask about filing an
issue. That is the per-step stop the bulk-approval rule exists to prevent. Add it to the block, or ask now.

### R8-22 · nit · scope and slicing

§ Approvals, 2026-11-05 block, last bullet: 'Tasks 9 and 15b make that the session-end rule' credits Task 9, but the
change is in Task 15b. Task 15b edits `implementing-plans`, and Task 9's section doesn't mention it. Scenario: An
executor looks for the session-end change in Task 9, finds nothing there, and wonders whether a Task 9 edit is
missing.

### R8-23 · nit · scope and slicing

Task 15b, Tests, 'End to end, by the session' ('Record here only that it ran, and the id'): The result is to be
recorded in a plan that Task 13 `git rm`s right after that same step, so the record has no reader. The Revisit that
would use it is carried by Task 13's issue. Scenario: The id is written into the plan and deleted in the next commit.
Record it in Task 13's issue alongside the Revisit's question instead.
Refuted: Dropped by the verifier. The record does have a reader. Task 13's delete is a `git rm` commit, so the id
stays in the branch's history and on `main` after the fast-forward. Task 13 also files its issue from the plan's open
items, the Revisit included, before the delete. No failure scenario.

### R8-24 · blocking · decisions

Task 15b, 'And at the end of every session' paragraph (the new `implementing-plans` line); § Approvals 2026-11-05,
last bullet of the run block: The session-end line tells `implementing-plans` to commit the work in progress and `git push -u origin <branch>`
with no level qualifier, and the Approvals block makes it 'the session-end rule for every
run'. `implementing-plans` runs at customer level too, where `git commit` and `push` are forbidden. The skill's own
Completion step drafts the commit for the user there, and nothing in this line does. The executor would ask: does the
line apply at personal and company level only, with customer drafting the commit, or does it skip customer entirely?
Scenario: A customer-level `implementing-plans` session reaches its end. The skill tells it to commit and push to the
client's remote, which is a forbidden write. The guard blocks it (or misses it in one of its known gaps), so the skill
as written instructs what § Work contexts forbids.
Fixed: The session-end rule moved out of Task 15b into a new Task 17 · Session-end save. Its skill section applies at
personal and company level; at customer level `plan-wip save` commits, pushes and records nothing and prints the
uncommitted work for the user.

### R8-25 · major · decisions

Task 15b, session-end paragraph, versus `reviewing-in-rounds` § Completion of a code review steps 1-2 and Task 13's
2026-11-05 deviation: Work-in-progress commits on the plan's branch are never reconciled with Completion, which builds
one commit per task from `git diff --cached` and then fast-forwards `main` to the branch. The plan only says the final
review 'diffs from `Base:` and so is unchanged'. Nobody decides whether the WIP commits stay in `main`'s history, get
squashed or rewritten before the fast-forward (which needs a force push of the pushed branch), or whether Completion's
per-task commits now cover only what changed since the last WIP commit. The executor would ask: what does `main`'s
history look like after a run with session-end commits, and who approves rewriting a pushed branch? Scenario: A
company plan runs over two sessions. The first ends with a WIP commit holding Tasks 1-3. At Completion, `git diff
--cached` holds only Tasks 4-5, so 'one commit per task' yields commits for 4 and 5 only. `main` is then
fast-forwarded to a history with a 'work in progress' commit in it, which breaks the company bar of a readable history
before `main`, and it is costly to undo once pushed.
Fixed: The session-end rule moved out of Task 15b into a new Task 17 · Session-end save. A fast-forward run saves to
`refs/wip/<branch>` and never commits on the branch, so `main` gets no WIP commit and Completion's per-task commits
are as before; a squash-merged-PR run commits the index on the branch, Completion commits what is left, and the squash
makes the split moot. No rewrite of a pushed branch is needed.

### R8-26 · major · decisions

Task 15b, session-end paragraph ('commits the work in progress on the plan's branch'): 'The work in progress' has two
readings that build different things. One commits only the index, the checkpointed tasks. The other commits
everything, including a half-done task's unstaged leftovers and the plan file. The skill says 'The plan file is never
staged', and at company and customer level the plan is in `info/exclude`. So the multi-machine resume the user wanted
works only if the plan and the leftovers travel. The executor would ask: does the session-end commit include the
half-done task's files and the plan file, and how does a resume on another machine find the plan at company level?
Scenario: Reading one: a half-done task's edits stay local, and the user resumes on the other machine without them.
Reading two: the commit holds unstaged leftovers. On resume, `git write-tree` equals `HEAD^{tree}`, so the leftovers
check no longer sees them as a starting point. At company level, the excluded plan is never pushed, so `ai implement <plan>`
on the second machine finds no plan.
Fixed: The session-end rule moved out of Task 15b into a new Task 17 · Session-end save. The save holds the index (the
checkpoints) as its second parent and, as its tree, the listing's entries unstaged and untracked plus the plan and its
review files, force-added when excluded; a branch-case commit takes the index only. `restore` brings it to a fresh
clone and checks it, so the plan reaches another machine at company level.

### R8-27 · major · decisions

Task 15b, session-end paragraph; § Approvals 2026-11-05 ('Tasks 9 and 15b make that the session-end rule for every
run'): The user's yes ('We should commit and ai log at the end of sessions too', 'Commit and push the branch') was
given in this run. The plan turns it into a permanent skill rule: commit and push at every session end of every future
run, without asking. But `reviewing-in-rounds` Completion step 4 says 'offer the commit, run it only on a yes', and
the user had approved only one skill line (in `reviewing-in-rounds`) as the exception to 'no skill changes'. The
executor would ask: does the session-end commit and push run without asking in later runs, or does it offer as
Completion does? And did the user approve a second skill edit, to `implementing-plans`, which the plan had earlier
declined in 'Why not also `implementing-plans`'? Also, which task edits it: Task 9 or Task 15b? Scenario: A later
company-level plan run ends a session. The session commits and pushes a WIP branch to the company remote without
asking, on a standing yes that § Approvals scoped to 'this run'. That breaks the global rule that an approval covers
what it names.
Fixed: § Approvals now quotes the question "The same choice becomes the session-end rule written into the plan for
future runs" with the answer, so the yes is recorded as a standing rule for future runs at personal and company level,
and the new Task 17 (not Task 9) builds it. Saving is not offered like Completion's commit: it runs on that standing
yes. The `implementing-plans` edit is recorded as a second skill change resting on this request.

### R8-28 · minor · decisions

Task 15b, session-end paragraph ('runs `ai-log record <plan-file>`') versus Change 'record prints … write a short
introspection … Pipe it to `ai-log note <id>`': `record` always prints the instruction to write and pipe an
introspection, and the `reviewing-in-rounds` step says 'do what it prints'. Nothing says whether a session-end record
also writes an introspection. The user asked for one 'after every plan'. The executor would ask: does a session-end
record write an introspection, or counts only? If counts only, how does `record` know not to ask for one (a flag, or a
different output)? Scenario: Reading one: every session end of a multi-day plan writes an introspection on a partial
run, so 15d's repeated `## Cut candidates` bullets are inflated by mid-run notes. Reading two: the session follows
`record`'s printed instruction anyway, because the implementing-plans line says nothing either way.
Refuted: Downgraded from major by the verifier. Downgraded. The ambiguity is real: the session-end line says 'runs
`ai-log record <plan-file>`', while `record` always prints the instruction to write and pipe an introspection. But
nothing the approach rests on depends on it, and it is cheap to settle while implementing: the line can say 'counts
only, ignore the prompt', or `record` can take a flag. Entries in the log repo are append-only data that 15d, still a
sketch, can filter, so it is not costly to reverse.

### R8-29 · minor · decisions

Task 15b, Interfaces ('`ai-log note <id>`') and Change, redaction bullet 'at company level, the words of the plan's
basename and first heading and of the branch name': `note` takes only `<id>`, but company-level redaction needs the
plan's basename, its first heading and the branch name. Task 15 stores `plan` as a hash at company level, so `note`
can't recover them from the entry. It also needs the work repo's remotes and folder names, so it must run in the work
repo. The executor would ask: does `note` take the plan file as an argument, read it from the cwd, or does `record`
store the redaction terms somewhere `note` can read them? Scenario: At company level, `ai-log note <id>` is run from
the log clone, or anywhere but the work repo. It has no plan basename or branch to redact, so the engagement-named
words in the introspection are pushed unredacted.
Refuted: Downgraded from major by the verifier. Downgraded. `note`'s argument list is an interface only `record`'s own
printed output consumes ('Pipe it to `ai-log note <id>`'), so the executor can have `record` print
`ai-log note <id> <plan-file>`, or have `note` read the branch and remotes from the cwd. The repo-remote and folder redaction already
implies `note` runs in the work repo. The 15b redaction tests, plus the company-level redaction assertion that Task 15
lists, would catch an unredacted push in the diff. It is a gap to close while implementing, not a decision the
executor cannot make.

### R8-30 · minor · decisions

Task 13, 2026-11-05 deviation; Implementation status 'Order'; Handover 'Start next session here': The sequence is
contradictory. The handover runs 16, 15, 15b, then the final code review, commit and fast-forward of `main`. Task 13
must come after every task, M included, which is by hand and pending, and its fold is 'code-reviewed in the run like
any task'. Its deviation puts the `git rm` commit after 'the final code review's commit and 15b's `ai-log record`'.
The executor would ask: is there one final code review covering Task 13's fold, or two (one for 15/15b, one for Task
13)? Does `main` get fast-forwarded before Task 13? Is the `git rm` commit, which no code review sees, covered by an
approval? Scenario: The run fast-forwards `main` after the 15/15b review, as the handover says. A later Task 13 then
needs a second code review, which triggers the 15b step and a second real `record`. Or the run waits for the user's
Task M and never finishes. Either way, the 15b end-to-end test ('this plan's next final code review') and the Task 13
deviation describe different final reviews.
Refuted: Downgraded from major by the verifier. Downgraded. The plan does not contradict itself. Task 13 must follow
Task M, which is by hand and pending, so the handover's next run (16, 15, 15b, final review, commit, fast-forward
`main`) leaves 13 out. A later run does Task 13: its fold is reviewed in that run's own final code review, then its
commit, a second `record` (whose window, by design, does not overlap the first), then the `git rm` commit and the
fast-forward. 'The final code review' in Task 13's deviation reads naturally as that run's own review. The executor
can start. What remains is minor: the plan could say outright that 13 is a separate later run, and that the `git rm`
commit falls under the 2026-11-05 branch-and-fast-forward yes.

### R8-31 · minor · decisions

Task 15, Change 'Customer level, deferred' ('a `<host>/<owner>` line in the private clone's `allow` file'): The
`allow` file is a data format that later work consumes (15c, and every machine). But its path in the clone, its format
and who creates it are not decided, and it is missing from Task 15's Files list ('outside this repo': `entries/` and
`README.md` only). The executor would ask: is it `allow` at the clone root, one `<host>/<owner>` per line, comments
allowed, created empty by Task 15? Scenario: The executor names it `allow.txt` or puts it under `entries/`, and the
user's Forgejo line is never read, so company Forgejo plans are silently treated as customer and never recorded.
Refuted: Dropped by the verifier. This is covered by the out-of-scope line. The plan already fixes the content, 'a
`<host>/<owner>` line', and the place, 'the private clone's `allow` file', meaning `allow` at the clone root. Task
15's tests use it ('the clone's `allow` names `git.example.com/uptimeconsulting`'). The exact file format and whether
the file starts out empty are choices the executor makes and a reviewer can check in the diff. If the file is absent,
the code fails closed: records nothing and treats the repo as customer, so there is no harmful outcome.

### R8-32 · minor · decisions

Task 15, Change 'Company level, names hashed or counted': The plan doesn't say what the company-level `repo` hash is
over. It may be the normalised origin, like `plan_key`, or `<owner>/<name>`, and it may or may not be salted. Task 15d
groups entries by it, so changing it later splits a repo's history. Scenario: Task 15 hashes `<owner>/<name>` while
`plan_key` hashes the normalised origin. Later 15d can't join them, or a fix changes the hash and orphans earlier
entries.
Refuted: Dropped by the verifier. This is covered by the out-of-scope line. The plan says company `repo` and `plan`
are 'stored as hashes, like `plan_key`', which points at the same unsalted sha256 scheme. Whether the input is
`<owner>/<name>` or the normalised origin is a choice the executor makes and a reviewer can check in the diff. 15d is
a sketch with no consumer yet, so nothing is joined against this hash today.

### R8-33 · nit · decisions

Task 15, Tests 'Real data, last' ('while `HEAD` is still the `Base:` commit'): `HEAD` has already moved past `Base:`
cdf0a77 through the session-end commits (d88b6fa … 5b563f3), so the condition can't hold. The executor would ask: run
the dry run at the current `HEAD`, or check out `Base:`? Scenario: An executor who takes the condition literally
checks out cdf0a77, detaching `HEAD` mid-run, and loses the scripts built since. One who ignores it can't tell whether
the window is the intended one.
Refuted: Downgraded from minor by the verifier. Downgraded to wording. The condition is stale: `HEAD` is 5b563f3, past
Base cdf0a77. But with `--dry-run` and no `<commit>`, the window ends now regardless, and with no earlier entry it
starts at the plan's first appearance. That is exactly the window the sentence names, so a run at the current `HEAD`
gives the intended result. Checking out Base mid-run is not a plausible reading. The clause should simply be removed.

### R8-34 · nit · decisions

Task 15, Tests 'Counts' (last line: 'at company level the plan's and branch's words redacted from the introspection
(15b)'): A Task 15 test asserts a behaviour of `note`, which Task 15b builds. Read literally, Task 15 can't pass its
own tests. Scenario: Task 15's task review fails it for the missing redaction test, or the implementer builds part of
`note` in Task 15, breaking the slice.
Refuted: Downgraded from minor by the verifier. Downgraded. The assertion is explicitly tagged '(15b)' inside Task
15's test list, which marks it as 15b's behaviour. A task reviewer can see that, and 15b's own Redaction tests cover
it. The issue is only where the line sits.

### R8-35 · minor · decisions

§ Approvals 2026-11-05 ('on every machine') and Task 15 Interfaces (exit 2 when `AI_LOG_DIR` is not a clone): The
standing yes covers every machine, but nothing sets up `$HOME/.ai-framework-log` on a machine other than the one Task
15 runs on, such as a `bin/dotfiles` init step. The executor would ask: should an init script clone it, or does each
machine stay unrecorded until the user clones it by hand? Scenario: On the user's second machine every run's `record`
exits 2. The report notes a failure each time, and that machine's plans leave no entries, which skews 15d's
cross-session report.

### R8-36 · blocking · consistency

Task 15b, the session-end paragraph ("`implementing-plans` gains one line ..."); § Approvals 2026-11-05, the bullet
"Tasks 9 and 15b make that the session-end rule for every run": The new `implementing-plans` line tells every run, at
every level, to commit the work in progress on the plan's branch and run `git push -u origin <branch>` when a session
ends. Nothing exempts customer level. The global § Work contexts forbids `git commit` and `push` in any form there.
The skill's own § *Checkpoint in the index, at every level* and the decision "Implementation checkpoints in the index
at every level ... the user commits at the end" both rest on that ban. Scenario: A customer-level run ends its session
before the final review. The skill tells Claude to commit and push, so Claude tries a forbidden write. If the guard
misses it (an unlisted customer resolves as company, or one of the guard's `git -C`/`cd "$var"` gaps), the write lands
in the client's history and on their remote. The line needs a level gate: personal and company commit and push;
customer drafts the commands for the user, as Completion step 4 does.
Fixed: The session-end rule moved out of Task 15b into a new Task 17 · Session-end save. It carries a level gate:
personal and company save, customer level writes nothing and lists what is uncommitted.

### R8-37 · major · consistency

§ Approvals (2026-11-05 block, lines 84-87 and 93-95; the 2026-11-05 standing-yes block, lines 99-104); Task 15b
session-end paragraph: The approvals don't cover the second skill edit or the session-end log writes. The user
approved "no skill changes" with one exception: one line in `reviewing-in-rounds`. Task 15b also edits
`implementing-plans`. The user's quote ("commit and ai log at the end of sessions too") is recorded for *this run*.
The sentence widening it to "every run" through Tasks 9 and 15b is plan text, not the user's answer. The standing yes
for `ai-log` writes covers "after every plan", not mid-plan session ends, and the quoted skill step that carries that
yes past Task 13 sits only in `reviewing-in-rounds`. An approval covers only what it names. Scenario: After Task 13
deletes the plan, `implementing-plans` tells future runs to commit, push and `ai-log record` at every session end, on
no recorded yes. That breaks the rule that an approval covers only what it names. It also changes how every later plan
is committed, which is costly to reverse. Ask the user explicitly about the generalised rule and the second skill
line, and state in the `implementing-plans` line which yes covers its `record`/`note` writes.
Fixed: § Approvals now records the generalised rule as the user's answer to a question that said it becomes the rule
for future runs, and that the `implementing-plans` edit rests on this request, not the "one line" exception. Task 17's
skill section names the standing yes of 2026-11-05 and 2026-11-09 that covers its save and its counts-only `ai-log
record`.

### R8-38 · major · consistency

Task 15b session-end paragraph ("`main` still waits for the final review, which diffs from `Base:` and so is unchanged
by these commits"); `reviewing-in-rounds` § Completion of a code review steps 1-2: The plan checks only that the
review's diff survives work-in-progress commits. Completion builds its per-task commits from `git diff --cached`, the
index against `HEAD`, so tasks already committed at a session end drop out of that split. The work-in-progress commits
then stay in the history that `main` is fast-forwarded to. Task 15b's tests check only the resume checks, and its
Tests list holds no case for the session-end line at all, though the paragraph says "the task's tests show it".
Scenario: The plan is built over two sessions. Session 1's tasks land in a commit named as work in progress, and
Completion commits only session 2's tasks and the fixes. `main` gets a history that is neither one commit per task nor
one commit of the whole, which misses the company bar of a readable history before `main`. Task 15b should say how
Completion treats work-in-progress commits (squash, or per-task commits from `Base:`) and add the test it promises.
Fixed: The session-end rule moved out of Task 15b into a new Task 17 · Session-end save. It says how Completion treats
a session save: a fast-forward run saves to a private ref and Completion is unchanged; a squash-merged-PR run commits
only the index, Completion commits what is left per task, and the squash makes the split moot. Task 17 has its own
tests for save, restore, replace, drop and the branch case.

### R8-39 · minor · consistency

§ Implementation status, the `Final code review` row (✅ DONE): The row reads ✅ DONE, from Task 14's and the 2026-11-02
run's reviews, while 15, 15b, 16, M and 13 are ⏳ PENDING. The staged-workflow decision says the row stays ⏳ PENDING
until `reviewing-in-rounds code` ends in `Done (code):`, so that a skipped final review shows in the plan. The table
and the order (Handover: "then the final code review") disagree. Scenario: A resumed run, or a reader, sees the final
review already done and goes from the last task straight to commit and fast-forward. Then 15b's end-to-end step, which
happens inside the final review, and Task 13's delete, which waits for that review's commit, run against a review that
never covered Tasks 15, 15b, 16 or 13. Reset the row to ⏳ PENDING for this run.
Refuted: Downgraded from major by the verifier. Downgraded from major. The contradiction is real: the decision at line
394 says the row stays ⏳ PENDING until `Done (code):`, yet the row reads ✅ DONE from earlier runs. But the Handover's
'Start next session here' names the final code review explicitly. `implementing-plans` line 129 also says the work
isn't finished until the final code review says `Done (code):`. So a resumed run is unlikely to skip it, and resetting
the row is a one-line fix.

### R8-40 · minor · consistency

Task 15 Tests, *Counts* bullet ("at company level the plan's and branch's words redacted from the introspection
(15b)"): Task 15's tests include a 15b feature: redacting the introspection. That needs `ai-log note` and the
redaction, which Task 15b produces. Task 15b's own Redaction test doesn't list the company-level plan and branch
words. Scenario: An executor building Task 15 alone can't write this test, because `note` doesn't exist yet. So it
stops, or writes a stub, and the case is lost when 15b's tests don't name it. Move the case to Task 15b's Redaction
bullet.

### R8-41 · minor · consistency

Task 15 Tests, *Real data* bullet ("while `HEAD` is still the `Base:` commit"): The bullet doesn't reflect the
session-end commits. `HEAD` is already past `Base:` (cdf0a77): 5b563f3 and others sit on `ai-framework`, and the
session-end rule adds more. The condition can't hold. With `--dry-run` and no `<commit>`, the window ends at now
anyway, so the condition isn't needed. Scenario: An executor checks the precondition, finds `HEAD` != `Base:` and
stops to ask, or resets. Drop the condition, or restate it as `--dry-run` with no commit.

### R8-42 · minor · consistency

Task 13, the 2026-11-03 deviation list of open items; Handover item 6: Two lists of what goes into Task 13's issue
disagree, and one is out of date. Task 13 still lists "Task 7's conflict sent to the user", which was decided and
reworded 2026-11-05 (status row 7, Handover item 5, § Approvals). Task 13 lacks the audit's recorded Mediums and Lows
and R12-4, which Handover item 6 names. Handover item 6 lacks 15c, 15d and the Revisit question. Scenario: Task 13's
executor files the issue from the Task 13 section. It reopens a settled conflict and drops the audit Mediums/Lows and
R12-4, and then deleting the plan loses them. Merge the two lists into Task 13.

### R8-43 · minor · consistency

Task 13 deviation ("filed with `writing-issues` on the user's yes"); § Approvals: Filing Task 13's issue on this repo
needs a yes the plan names but § Approvals never records. That issue write was foreseeable, so it belongs in the
2026-11-05 bulk question. Scenario: The run reaches Task 13 and stops for a question it could have asked up front,
which goes against "ask in bulk, up front" and the goal of a run that doesn't stop between stages.

### R8-44 · minor · consistency

§ Approvals 2026-11-05, "Tasks 9 and 15b make that the session-end rule"; Task 9 section; § File map rows for 15b and
16: Several references don't match the task sections. The Approvals bullet names Task 9 as making the session-end
rule, but Task 9's section has no such change; only Task 15b edits `implementing-plans`. The File map row for 15b
omits `claude/skills/implementing-plans/SKILL.md`, which Task 15b's Files gains, and the existing `implementing-plans`
row names only Task 9. Task 16's row lists only `claude/rules/writing-code.md`, not `bin/check-md-limits`,
`test/test_check_md_limits.sh` and `claude/docs/markdown-limits.md`, which Task 16's Files names. Scenario: An
executor deciding what can run in parallel, or what a task's commit takes, reads the File map. It misses that 15b and
Task 0's `bin/check-md-limits` row share files with 16, and Completion's per-task pathspecs may leave the
`implementing-plans` edit out of 15b's commit if the Files line isn't updated in step.

### R8-45 · minor · consistency

Task 15b session-end paragraph vs Change ("do what it prints"): The session-end line says only "runs `ai-log record <plan-file>`".
`record` prints the prompt for an introspection piped to `ai-log note`. The step's "do what it prints,
without asking", and the yes behind it, are only in `reviewing-in-rounds`. Whether a session end also writes an
introspection is unstated. Scenario: At a session end, one executor writes and pushes a `note` and another doesn't.
Entries for the same plan then differ, which affects what Task 15d's `## Cut candidates` aggregation reads.

### R8-46 · nit · consistency

Task 15b Files (`reviewing-in-rounds` "a step after step 6") vs Tests ("one list item after the commit step"); the
user's "one line" exception: The skill's commit step is step 4, so Files ("after step 6") and Tests ("after the commit
step") place the new step differently. The quoted step also runs to three sentences, more than one 150-character line
under the one-sentence-per-line rule. The user approved "one line". Scenario: The test checks a different position
from the one the Files line places it at. A three-line step goes beyond the user's "one line" exception. Name the
position once, and trim the step or record that the user accepted the length.
Refuted: Downgraded from minor by the verifier. Downgraded from minor. Step 6 of Completion is 'After the commit
runs', the step tied to the commit. 'After step 6' and 'after the commit step' both point at roughly the same spot,
and a reviewer can check the placement in the diff. Reading the user's 'one line is fine' as one list item rather than
one physical line is reasonable. What is left is wording.

### R8-47 · nit · consistency

§ Approvals, 2026-11-05 plan-review-fixes block (customer-pass token yes): That yes now belongs to Task 15c, which
isn't a task of this run and survives only through Task 13's issue. Task 13's list of what the issue carries doesn't
mention the approval. Scenario: When 15c is detailed from the issue after the plan is deleted, the token approval is
gone, and the scenario is either re-asked or run without the yes on record.

### R8-48 · blocking · work context

Task 15b, 'And at the end of every session' paragraph (the new `implementing-plans` line); also § Approvals
2026-11-05, last bullet ('Tasks 9 and 15b make that the session-end rule for every run'): The session-end line added
to `implementing-plans` tells every run to commit the work in progress on the plan's branch and push it with `git push -u origin <branch>`.
It says nothing about level. At customer level, `git commit` and `push` in any form are forbidden
(~/.claude/CLAUDE.md § Work contexts). Elsewhere the skills deal with this explicitly: `reviewing-in-rounds` §
Completion step 4 says 'Customer: draft it for the user', and `implementing-plans` says 'At company and customer
level…'. The new line needs the same split: offer at personal and company, draft at customer. Scenario: An
`implementing-plans` run in a customer tree reaches the end of a session before the final review. The skill line tells
the executor to commit and push. The guard blocks it, so the session ends on a refused forbidden write instead of a
drafted commit. Where the guard has known gaps (`git -C $var`, `cd "$var"`), the write could go through. This also
contradicts the line Task 15b adds to `work-contexts.md`: 'at customer level … nothing leaves the machine'.
Fixed: The session-end rule moved out of Task 15b into a new Task 17 · Session-end save. Personal and company save per
the user's 2026-11-09 ruling; customer level writes nothing and prints the uncommitted work, so nothing leaves the
machine.

### R8-49 · major · work context

Task 15b, session-end paragraph; § Approvals 2026-11-05 (session-end bullet): The yes recorded in § Approvals covers
'each session of this run' and names `git push -u origin ai-framework`. Task 15b turns it into a skill rule for every
run, every repo and every branch, with no wording that ties the commit and push to a yes. Task 15b's skill step says
outright that it carries a standing yes for the ai-log writes. The session-end line has no such wording, and Task 13
deletes this plan with its Approvals block. That leaves two outcomes. Either the rule silently assumes a standing yes
for work-repo commits and pushes that the record doesn't show, which breaks the global 'An approval covers what it
names' rule. Or future runs have no recorded yes, which conflicts with `reviewing-in-rounds` step 4 ('run it only on a
yes — one recorded in the plan's `## Approvals` counts'). Scenario: A later personal or company plan has no Approvals
entry for work-in-progress commits. At session end, `implementing-plans` commits and pushes a branch to that repo's
origin without asking, on the strength of a yes given for one branch of one run of this plan.
Fixed: § Approvals now quotes the question that made the yes a standing rule for future runs at personal and company
level, and Task 17's skill section says it runs on that yes of 2026-11-05 and 2026-11-09, so the yes outlives the plan
in the skill line, as 15b's does.

### R8-50 · major · work context

Task 15b, session-end paragraph ('`main` still waits for the final review…'); Task 13 deviation (git rm commit, then
`main` fast-forwarded): The work-in-progress commits go on the plan's branch, and `main` is then fast-forwarded to
that branch, so the WIP commits land in `main`'s history. At company level the global table requires 'a readable
history before it reaches `main`'. A fast-forward of a branch full of 'Record … work in progress' commits breaks that
bar. The plan argues only that the review diff is unchanged ('diffs from `Base:`'). It doesn't address history, and it
doesn't say whether the WIP commits are squashed or rewritten before `main`. Scenario: A company-level run lasts three
sessions. `main` is fast-forwarded to a branch holding three WIP checkpoint commits and the final commit, so the
repo's showcase history reaches `main` unreadable. This plan already does the same on its own branch (commit d88b6fa
'Record the ai-framework run's work in progress'), and the 2026-11-05 run will fast-forward `main` to it.
Fixed: The session-end rule moved out of Task 15b into a new Task 17 · Session-end save. Per the user's 2026-11-09
ruling, a run that fast-forwards `main` saves to `refs/wip/<branch>`, never the branch, so no WIP commit reaches
`main`; only a squash-merged-PR run commits on the branch. § Approvals records that d88b6fa stays: this repo is
personal level, with no readable-history bar.

### R8-51 · minor · work context

Task 15b, *Change* (introspection at company level) vs Follow-up 15c sketch ('a model terms pass … runs at every
level, since a customer repo not yet in `~/.claude-customers` resolves as company'): Task 15b stores model-written
introspection prose at company level, with only the mechanical redaction. The plan itself says, in 15c, that a model
terms pass is needed at every level because an unlisted customer repo resolves as company. Task 15's origin allowlist
(github.com/uptimeconsulting plus the `allow` file) narrows the exposure, but company repos on that org can still be
engagement work. Words in the introspection that are not in the plan basename, the first heading, the branch or
`~/.claude-customers` pass through. This conflicts with Task 15's 'Still free of customer details'. The log repo is
private, so no level rule is broken, but the plan should state that this gap is accepted until 15c is built. Scenario:
A run on `github.com/uptimeconsulting/integration` produces an introspection that names the end client mentioned in a
review finding (e.g. 'the Acme sync lens found nothing'). 'Acme' is not in any redaction source, so it is committed
and pushed to `andrelin/ai-framework-log`.
Refuted: Dropped by the verifier. The gap is already recorded and accepted in the plan. § Approvals (plan lines
105-107), answered yes on 2026-11-05, says that until 15c is built 'the introspection is stored at personal and
company level only'. Follow-up 15c (line 3703) gives the reason a model terms pass is needed at every level. So the
plan already states the accepted interim state and its limit. The finding agrees that the log repo is private and that
no level rule is broken. What it asks for, an extra 'gap accepted' sentence, is wording at most, and it has no
requirement behind it.

## Round 9

### R9-1 · major · grounding

Task 17 § Change, The skill ("The skill is at its line cap until Task 16 stops counting front matter"); Implementation
status, Order ("16, which frees the line budget its skill edit needs"): The budget claim is wrong.
`claude/skills/implementing-plans/SKILL.md` is pinned in `.md-baseline` at 120 and counts exactly 120 today, and a
pinned file may not grow by a single line. Task 16 frees only its 4 front-matter lines (`---`, `name`, `description`,
`---`; checked with check-md-limits' own `count_lines raw`). Task 17 adds a section of about seven to ten bullets
(branch-case commit, save and record, customer line, restore before the first task, resume step 1, before-staging HEAD
rule, finish drop) and also edits the opening line and a red flag. Scenario: Task 17's own test that
`bin/check-md-limits` passes on the skill fails with "a pinned file may not grow" at about 124 or more lines against a
pin of 120. The executor then has to cut existing skill text that the plan never chose, or loosen the pin, which
`--update-baseline` refuses to do.
Fixed: Task 17 now names the budget: the skill counts 120, its pin, never raised; Task 16 frees 4 front-matter lines
and Task 17's skill edit (one paragraph plus two in-place edits) must fit in them, else resume step 1's brief-rewrite
sentence moves to `implementing-plans-reference.md`.

### R9-2 · major · grounding

Task 15 Files (tips/24_claude_code.md, a new tip), Task 15b Files (the tip gains `note`), Task 17 Files (a new tip):
`tips/24_claude_code.md` is pinned in `.md-baseline` at 125 and counts exactly 125 rendered lines today.
`.claude/docs/tips-file-sizing.md` says a pinned file "may not grow at all". Three tasks each append to this file and
each test that check-md-limits passes on it, so all three fail. Task 16's front-matter change does not help, because
tips files have no front matter. The way out is a split or renumber, which `writing-tips` makes the user's call.
Scenario: The Task 15 implementer adds Tip 24.10 and the check fails with "up from its pinned 125". The run stops for
a user ruling on splitting `24_claude_code` and renumbering. The plan could have settled this up front (for example a
new tips file for the ai-log and plan-wip tools) in its approvals round.
Fixed: New tips go in a new `tips/25_ai_framework.md` (the user: "A new tips file"): Task 15 adds Tip 25.1 and a
`tips.md` 25 entry, Task 15b extends it; Task 17 has no script and no tip; the File map follows.

### R9-3 · major · grounding

Task 17 § Change, The skill ("Before the first task, ahead of the plan-file check: `plan-wip restore`, so a plan
untracked at company level arrives too"): Task 17 assumes a resume reaches the skill without the plan file on disk,
but `bin/ai` checks for it first. `require_plan_file` (`bin/ai:39-44`) dies with "no such plan file" (exit 2) before
`claude` starts. Tip 24.8 and the handover both name `ai implement <plan-file>` as the way to resume. Task 17 does not
change `bin/ai` and does not tell the user to run `plan-wip restore` by hand first. Scenario: A company-level run
stops on machine A and saves to `refs/wip/<branch>`. On machine B the user runs `ai implement plan-x.md` as the tip
says. `bin/ai` exits 2 because the untracked plan was never restored. The cross-machine resume that Task 17 exists to
provide fails at its documented entry point.
Fixed: Moot: Task 17 no longer has a private ref or `bin/plan-wip`; on the user's 2026-11-09 ruling after round 9 a
session end commits the work in progress on the branch and pushes it, and the work lands by a squash-merged PR. A
tracked plan arrives with the branch; an untracked company plan doesn't travel, an accepted gap carried to Task 13's
issue.

### R9-4 · major · grounding

Task 17 (session-end `ai-log record <plan-file>` in the ref case) together with Task 15 § The window ("session-end
runs at an unmoved HEAD share one id, the later replacing the earlier"): In the ref case `HEAD` stays at `Base:` for
the whole run, so every session-end record of that plan, on every machine, gets the same id. Each re-run skips its own
entry when it looks for a window start, finds no other entry for the plan, starts the window at the plan's first
appearance in the *local* transcripts, and overwrites the shared entry. The replace-with-a-longer-window design only
works on one machine. It loses data in exactly the multi-machine resume that Task 17 adds. Scenario: Session 1 on
laptop A ends and records entry E (A's tokens). The run resumes on desktop B, which ends and records the same id E
from B's transcripts only, overwriting A's counts. The final record after the commit then starts its window at E's
end. A's whole session is gone from the log, and per-plan cost and turn totals undercount without any warning.
Fixed: With WIP commits `HEAD` moves at each session end: Task 17 commits before `ai-log record`, with `--allow-empty`
when nothing new was checkpointed, so every session end, on any machine, has its own id and window; Task 15 § The
window says so, and a same-id replace is left only for a re-run at one commit.

### R9-5 · major · grounding

Task 17 § Tests, By the session ("showing GitHub keeps a ref outside `refs/heads`"); § Change, The ref case ("At
company level the plan reaches another machine only this way"): The ref case depends on the origin accepting and
keeping `refs/wip/*`. That is checked only on GitHub, and only as the last step after the script is built. Company
work in this setup is on Forgejo (global CLAUDE.md § Forgejo work), and the plan never checks that Forgejo, GitLab or
a customer's host accepts a push outside `refs/heads` and `refs/tags`, or keeps it through gc. The local git mechanics
hold: I ran save, push, fetch into a fresh clone and `read-tree -u --reset` plus `read-tree <save>^2` in a scratch
repo, and the leftovers, staged checkpoint, deletion and excluded plan came back correctly. Scenario: On a company
Forgejo repo the server rejects the push to `refs/wip/<branch>`. `save` exits 1 at every session end, and the
untracked company plan never reaches another machine, which is the only reason given for the ref case at company
level. Check this with a first spike against GitHub and the company forge before building `plan-wip`, not as its final
test.
Fixed: Moot: Task 17 no longer has a private ref or `bin/plan-wip`; on the user's 2026-11-09 ruling after round 9 a
session end commits the work in progress on the branch and pushes it, and the work lands by a squash-merged PR.
Nothing outside `refs/heads` is pushed.

### R9-6 · minor · grounding

Task 15 § Interfaces ("An agent's lens comes from the `Lens:` line of its prompt... the `###` heading ... the line
starts with"): I checked a real Workflow reviewer transcript (this run's agents). `Lens:` is not on a line of its own
and does not start a line. It sits mid-line after "read the rest of the plan as context.", inside a harness-wrapped
and indented prompt. A parser that looks for a line starting with `Lens:` files every such agent under no lens. Each
agent's `.meta.json` already carries the lens: `description: "review:Work context"` next to `workflowPhase`. That is a
simpler and more reliable source for Workflow agents. Scenario: `record` over a Workflow-driven plan review reports
zero tokens for every lens, so Task 15d's cut-candidates-by-lens has no data. The fixture test passes only because it
was built with the line at line start.

### R9-7 · minor · grounding

Approvals, 2026-11-09 bulk ("the final review's commit step rebuilds the branch from `Base:` so no work-in-progress
commit reaches `main`"): No task or skill step owns this rebuild. `reviewing-in-rounds` § Completion commits `git diff
--cached` on top of `HEAD`. There are four commits since `Base:` (cdf0a77): `d88b6fa` (the WIP commit) plus `06f51fa`,
`0433f08` and `5b563f3`. Two of those are legitimate skill changes (filed learnings). A literal rebuild from `Base:`
drops them or folds them into a task commit. The approval names only `d88b6fa`. Scenario: At the final commit the
executor resets to `Base:` and recommits per task. The `writing-plans` learning (06f51fa) and the `implementing-plans`
git-mv rule (5b563f3) either disappear from `main` or land inside an unrelated task's commit, because their paths fall
in no task's Files list and go with the last task.

### R9-8 · minor · grounding

Task 15 § Change, The window ("with none, at the plan's first appearance") and § Tests, Real data: `ai-log` will
undercount this plan's first real entry without saying so. Transcripts are cleaned up after 30 days
(`cleanupPeriodDays` is unset here, so the default applies). The oldest dotfiles transcript is from Oct 13 and this
plan began Oct 16, so its earliest sessions are already near expiry. Nothing warns when the window start comes from
the oldest surviving transcript rather than the plan's real start. Scenario: The first real `record` for
`plan-ai-framework.md` (or any long plan) silently omits sessions older than 30 days. The per-plan cost and turns look
complete but are not, and the Revisit judges each stage on partial numbers.

### R9-9 · minor · grounding

Task 16 § Spec and § Tests: The user's report was about a *desktop* session. The fix (adding globs) clearly targets
the cause, since `.cs` is not in `paths:`. But the load test runs only headless CLI `claude -p`, so it never confirms
the reported environment now loads the rule. Scenario: The globs are added and the CLI test passes. If the desktop app
handles user `~/.claude/rules` path triggers differently, the user's `.cs` case still fails and the task is marked
done.
Refuted: Dropped by the verifier. Out of scope. Which environment the load test runs in is a test-case choice, which
the out-of-scope line leaves to the code. The finding agrees the cause is clear: `.cs` is missing from `paths:`, and
adding the glob addresses exactly that. Its failure scenario depends on the desktop app handling user-rule path
triggers differently from the CLI, which it gives no evidence for. The desktop app runs the same Claude Code engine.

### R9-10 · minor · grounding

Task 17 § Change, When ("the run's own stop: a stop to ask"): Treating every stop-to-ask as a session end goes beyond
the user's request ("at the end of sessions"). `implementing-plans` stops for many in-session questions, and each
would then make a branch commit and push in the branch case, plus a wip push and an `ai-log` entry. Scenario: A
company PR-based run stops three times for user rulings in one sitting. It makes three `Work in progress` commits and
pushes, and three entries that fragment the plan's windows, though the session never ended. The squash hides the
commits, but the log gets noise entries.
Refuted: Dropped by the verifier. The plan made this choice deliberately and says why: 'Claude can't know a session is
ending' (plan review R8-4), so a stop to ask is when the user may walk away. The harm claimed does not follow. In the
ref case `HEAD` does not move, so repeated session-end records share one id and replace each other rather than piling
up. In the branch case, windows are non-overlapping, so per-plan totals still sum correctly. The extra commits are
squashed by the PR merge, which the user ruled makes them harmless ('this shouldnt be a problem'). No concrete failure
remains.

### R9-11 · major · scope and slicing

Task 17 · Change, *The skill* ("The skill is at its line cap until Task 16 stops counting front matter … the skill
gains only these lines"); Task 16 · Files; Order ("after 16, which frees the line budget its skill edit needs"): The
budget the plan relies on doesn't exist. What binds `claude/skills/implementing-plans/SKILL.md` is not the 150-line
cap but its pin in `.md-baseline`, which is 120 counted lines, and the file is at exactly 120 today (blank lines and
headings aside). Task 16 dropping the 4-line front matter frees 4 lines, bringing it to 116. Task 17's new section and
its added lines come to roughly 8 to 12 counted lines: the standing-yes line, the branch-case commit and push, save
and record, failure, customer level, restore before the first task, resume step 1, before staging, finish and drop.
That lands at about 124 to 128, past the pin. `--update-baseline` only ever lowers a pin, and neither task lists
`.md-baseline` in its Files. Scenario: The executor builds Task 17's skill lines and `bin/check-md-limits` fails on
the skill, which Task 17's own *Files edits* test requires to pass. They can't raise the pin with the tool, and no
task says whether to hand-edit `.md-baseline` (overriding the ratchet) or cut existing skill lines, so the task stops
for the user mid-run. The fix: count the real headroom now, then either add `.md-baseline` to Task 17's Files with the
user's yes to raise the pin, or name the skill lines Task 17 moves into `bin/plan-wip`'s usage text or a doc.
Fixed: Task 17 now names the budget: the skill counts 120, its pin, never raised; Task 16 frees 4 front-matter lines
and Task 17's skill edit (one paragraph plus two in-place edits) must fit in them, else resume step 1's brief-rewrite
sentence moves to `implementing-plans-reference.md`. The Order line says 16 frees the 4 lines the edit fits in.

### R9-12 · major · scope and slicing

§ Approvals, 2026-11-09 bulk ("the final review's commit step rebuilds the branch from `Base:`") together with Task
13's 2026-11-05 deviation and Task 17 *Finish*: No task owns the rebuild of `ai-framework` from `Base:` that squashes
out the work-in-progress commit `d88b6fa`. The plan never says where in the closing sequence it runs, relative to
Completion's per-task commits, `ai-log record`, `plan-wip drop`, Task 13's `git rm` commit, the one force-push and the
fast-forward. It also never says what happens to the real commits on the branch past `Base:`. `06f51fa`
(writing-plans) and `5b563f3` (implementing-plans) change skills that appear in no task's Files list of this run.
`reviewing-in-rounds` § *Completion* has no rebuild step, so an executor following the skills keeps `d88b6fa`.
Scenario: At the final review the executor runs Completion as the skill says and commits per task on top of `d88b6fa`,
so the work-in-progress commit reaches `main` against the user's "Squash it out". Or the executor does a `git reset
--soft cdf0a77` by guess, and Completion's pathspec rule then puts the two learnings commits' skill edits, along with
d88b6fa's `claude/CLAUDE.md` change, into whichever task commit comes last. Either way the readable history the
company and showcase bar asks for is lost. A short step list in Task 13 would settle it: when the rebuild runs, how
the learnings commits are kept, and where the force-push falls.
Fixed: Moot: no rebuild and no force push; on the user's 2026-11-09 ruling after round 9 this run lands by a
squash-merged PR, which removes `d88b6fa`, and the Order line, the handover and Task 13 now list the tail: the final
review's commits on `ai-framework`, `ai-log record`, Task 13's `git rm` commit, push, the PR, squash-merged on green
CI, `main` pulled.

### R9-13 · minor · scope and slicing

Task 13 · Files and Tests: The delete is narrower than its own test. Task 13 deletes three files, but `git ls-files
'plan-ai-framework*'` already lists six. Three closed review logs are tracked:
`plan-ai-framework-review-findings-code-closed-2026-11-05.md`, `…-plan-closed-2026-11-05.md` and
`…-plan-closed-2026-11-05-2.md`, the last added in `d88b6fa`. Scenario: After the `git rm` commit, the test `git
ls-files 'plan-ai-framework*'` still prints three files and fails, so the task doesn't end in something that passes.
The Files list should name the closed logs, or use a glob. They must still exist when `ai-log record` runs, since Task
15 counts closed logs, which the existing order already allows.

### R9-14 · minor · scope and slicing

Task 15 · Tests, *Counts* ("at company level the plan's and branch's words redacted from the introspection (15b)"): A
test of Task 15b's behaviour sits in Task 15's test list. Task 15 builds no `note` and no redaction, so an executor
working on Task 15 alone can't write or pass it. Task 15b's own *Redaction* test list leaves out the company-level
words case. Scenario: The Task 15 implementer either builds part of 15b's redaction early, which widens the slice, or
leaves a listed test unwritten, and the task review flags it as missing. Meanwhile 15b's tests never prove that the
plan's and branch's words are redacted at company level. The bullet belongs in Task 15b's *Redaction* tests.

### R9-15 · minor · scope and slicing

Task 17 · Tests, *By the session* (last): The assumption every part of `save`, `restore` and `drop` rests on is tested
last, after the script is built. That assumption is that this repo's origin accepts, keeps and deletes a ref outside
`refs/heads` (`refs/wip/ai-framework`) through a force refspec, past the guard and the push hooks (the Handover
already notes a spurious "pushed to main, watch CI" hook). `git ls-remote origin 'refs/wip/*'` shows none today, so no
session has exercised it. Scenario: GitHub, a hook or the guard refuses or mangles a `+refs/wip/…` push. Then the
save, restore and drop design and its tests are rebuilt after the fact, and the § Approvals rule that this run's
session ends save to the ref by hand had nothing under it. A one-off push, `ls-remote` and delete before the script is
written would settle it.
Refuted: Dropped by the verifier. The assumption is low-risk and already has a gate. GitHub accepts pushes to refs
outside refs/heads (only refs/pull is reserved). `claude/hooks/work-context.sh` forbids push only at customer level,
and this repo is personal public. Task 17 already makes the real save, ls-remote and drop a by-session test, and "a
refusal stops the task for the user". When to run that check within the task is an ordering choice for the executor,
which is out of scope.

### R9-16 · minor · scope and slicing

Task 16 · Spec and Tests (*Loads where it should*): The cause is assumed, not proven. The report came from a desktop
session ("may not cover C#"), but the test checks only headless CLI loading after the change. It never shows that
`.cs` failed to load before the change while `.kt` loaded, and never covers the desktop surface where the symptom was
seen. Scenario: The desktop app doesn't apply `paths:` rules the way the CLI does, so the new globs pass the headless
test while the user's reported symptom remains, and the task is marked done. Running the headless probe once before
the edit, with a `.cs` file and a `.kt` file, would prove the cause, and the report could note that the desktop
surface is untested.
Refuted: Dropped by the verifier. The cause is proven by reading the file. The `paths:` list in
`claude/rules/writing-code.md` has kt, java, ts, tsx, js, jsx, py, sh, zsh, kts, bin/ and hooks/, and no `.cs` glob,
so a `.cs` file can't match it. A before-the-edit probe is an exact-test-case choice, which is out of scope. Whether
the desktop app applies `paths:` the same way is not a scoping defect of this plan.

### R9-17 · minor · scope and slicing

Task 15b · Files, `claude/docs/work-contexts.md` addition; Task 17: The work-contexts doc text that Task 15b writes
describes only the per-plan `record` and `note` after a commit. But Task 17, built before 15b, also has
`implementing-plans` run `ai-log record` at every personal- or company-level session end, and push a
`refs/wip/<branch>` ref. Neither task updates `work-contexts.md` § *An approval covers one action* for those writes,
so the docs-ship-with-the-change constraint is broken for Task 17. Scenario: A later reader of `work-contexts.md`
learns of a per-plan entry only, and doesn't know that each session end also commits and pushes to the log repo and
the origin. That is exactly the standing-yes scope the doc exists to state. Task 17's Files should include
`claude/docs/work-contexts.md`.

### R9-18 · nit · scope and slicing

Task 15 · Change, *Customer level, deferred* (the private clone's `allow` file); Task 15 · Files: `record` reads an
`allow` file in the log clone, but no task creates it or documents its format in the log repo's `README.md`. Without
an entry there, every company repo off `github.com/uptimeconsulting`, such as the company Forgejo the global
instructions name, records nothing at all. Scenario: After the run, company Forgejo plans silently log nothing because
`allow` doesn't exist. Nobody notices until a cross-session report (15d) finds them missing. The file is built for a
case nothing in this run exercises, so either drop it from this slice or add its creation, with its format, to Task
15's *Outside this repo* bullet.
Refuted: Downgraded from minor by the verifier. Downgraded. An absent `allow` file is the designed safe default: an
origin it doesn't list is never recorded, so an unlisted customer repo that resolves as company leaks nothing (R5-1,
R5-37). Nothing in this run needs a Forgejo entry. The real gap is documenting the file's `<host>/<owner>` format in
the log repo's README, which is wording.

### R9-19 · minor · scope and slicing

Task 15 · Tests, *Real data, last* ("while `HEAD` is still the `Base:` commit"): The precondition is already false.
`HEAD` is `5b563f3`, four commits past `Base:` `cdf0a77` (`d88b6fa`, `06f51fa`, `0433f08`, `5b563f3`), and it stays
there through Task 15 because checkpoints sit in the index. Scenario: The executor checks the stated precondition,
finds it false and stops to ask, or guesses at a `<commit>` argument and so gets a window it didn't intend. The test
should say "before the final review's commit" instead.

### R9-20 · nit · scope and slicing

Follow-up 15c ("if this plan ends first, Task 13's issue carries it"); Task 15b · Tests, *End to end* ("Record here
only that it ran, and the id"): Both conditions are settled by the order. The Revisit needs 15b's first real entry,
which is written only after the final review's commit, right before Task 13's `git rm`. So the plan always ends first,
and the 15b result recorded "here" is deleted in the very next commit. Scenario: Wording only. Say outright that Task
13's issue carries 15c, 15d and the Revisit, and record the end-to-end id in that issue or the final report rather
than in the plan.

### R9-21 · major · decisions

Task 15 Files (tips/24_claude_code.md), Task 17 Files (tips/24_claude_code.md,
claude/skills/implementing-plans/SKILL.md) and both tasks' Files-edits tests: Both target files are already pinned at
their current size in `.md-baseline`: `tips/24_claude_code.md` at 125 and `implementing-plans/SKILL.md` at 120. Both
pass `bin/check-md-limits` today only because neither has room left. A pin "may not grow past the size recorded", and
`--update-baseline` refuses to raise one. Task 15 adds a tip, Task 17 adds another, and Task 15b extends Task 15's.
Task 16 removes about 4 front-matter lines from the skill, but Task 17 adds a new section, a restore step, a
resume-step change and a finish line, which is likely 8 or more counted lines. The plan says "the skill gains only
these lines" without checking them against the pin. The executor would ask: may I raise the pins in `.md-baseline` by
hand, should the new tips go in a new tips file, or what gets cut or moved to `implementing-plans-reference.md`?
Moving session-end steps into the reference doc changes when they load. Scenario: After Task 15's tip,
`bin/check-md-limits tips/24_claude_code.md` fails on the pin, so the task's required test can't pass. Task 17's skill
edit fails the same way on the 120 pin. The executor must either edit a pin the user set deliberately or move skill
text into a doc that isn't loaded when the session ends. Both are the user's call.
Fixed: Task 17 now names the budget: the skill counts 120, its pin, never raised; Task 16 frees 4 front-matter lines
and Task 17's skill edit (one paragraph plus two in-place edits) must fit in them, else resume step 1's brief-rewrite
sentence moves to `implementing-plans-reference.md`. New tips go in a new `tips/25_ai_framework.md` (the user: "A new
tips file"): Task 15 adds Tip 25.1 and a `tips.md` 25 entry, Task 15b extends it; Task 17 has no script and no tip;
the File map follows.

### R9-22 · major · decisions

Task 17 Change, `restore` ("a present plan file identical to the save's; otherwise exit 1"); 2026-11-09 Approvals;
Handover "Start next session here": The rule has two readings: any plan file on disk must equal the save's copy, or
only an untracked or locally changed one. In the ref case with a tracked plan (this repo), the plan's edits during the
run are never committed, so the save holds an edited plan. On another machine, `git switch ai-framework && git pull`
checks out the plan from `HEAD`, which differs from the save, so `restore` exits 1 and stops the run every time. The
round-trip test only covers an untracked plan, so it won't catch this. The executor would ask: when the plan is
tracked and its only difference is the save's own edits, should restore overwrite it, or refuse? Scenario: Session on
machine A ends, and the save holds `plan-ai-framework.md` with its status table updated. On machine B, the next
session pulls the branch and runs `plan-wip restore plan-ai-framework.md`. The present plan is the committed version,
not the save's, so restore exits 1 and the cross-machine resume Task 17 exists for never works for this plan.
Fixed: Moot: Task 17 no longer has a private ref or `bin/plan-wip`; on the user's 2026-11-09 ruling after round 9 a
session end commits the work in progress on the branch and pushes it, and the work lands by a squash-merged PR. No
`restore` exists to compare plan files.

### R9-23 · major · decisions

Task 17 Change, *When* ("the same machine then resumes from where the work is") and `restore`'s refusal; the skill's
"Before the first task: plan-wip restore … a non-zero exit stops the run": "A stop to ask" counts as a save trigger,
and after the user answers, the run carries on in the same session. Any later work, such as more checkpoints and
leftovers before a kill, makes the local state differ from the save. The next start on the same machine then runs
`restore`, which finds a non-empty listing or an index unlike the save's `^2` and exits 1. That stops the run,
contradicting "the same machine resumes from where the work is". The executor would ask: when the local state is newer
than the save (`HEAD` the same, checkpoint refs past the save), should restore keep local work and exit 0, or refuse?
Scenario: The run stops to ask at Task 15, so it saves. The user answers, Task 15 and part of Task 17 get
checkpointed, then the usage limit kills the session. The next `ai implement` on the same machine stops at restore
with exit 1, and the user must work out by hand which state wins and drop the ref.
Fixed: Task 17's trigger is now the user's wrap-up request or the run's part-way final report, not a stop to ask; with
no `restore`, a later same-machine start just resumes from the index and leftovers.

### R9-24 · minor · decisions

Task 17 Change, `save` (`git push origin +refs/wip/<branch>:refs/wip/<branch>`, "one per branch"); 2026-11-09
Approvals ("if we manage to keep track of it properly"): There is one ref per branch, force-pushed by every save from
any machine, with no check that origin's ref is the one this machine last restored or saved. The user made the private
ref conditional on keeping track of it properly. Letting one machine silently overwrite another's newer save is a
data-loss behaviour the user should decide. The executor would ask: should `save` refuse, or warn, when origin's
`refs/wip/<branch>` is neither this machine's last save nor the one it restored, or is last-writer-wins acceptable?
Scenario: Machine A saves on Friday. On Monday, machine B starts without restoring (for example, the branch was
already checked out with stale local work), works, and saves. B's `+` push replaces A's save on origin, and A's
work-in-progress is gone without any message.
Refuted: Downgraded from major by the verifier. Downgraded. The skill runs `plan-wip restore` before the first task
and stops the run on a non-zero exit. Restore refuses when HEAD isn't the save's parent or the listing isn't empty, so
machine B can't start on stale local work and then overwrite A's save without the user settling it by hand first.
Last-writer-wins remains only for two machines running at the same time, or after a manual override. That's real but
cheap to add, for example as a lease check on the push.

### R9-25 · minor · decisions

Task 15b Interfaces (`ai-log note <id>`) and Change, *The mechanical redaction* (company-level plan basename, first
heading and branch words; the work repo's remotes and folder names): `note` takes only an id and stdin, yet its
redaction needs the work repo's remotes, folder path, branch name, and the plan's basename and first heading. At
company level the entry stores `repo` and `plan` as hashes, so `note` can't recover those terms from the entry. The
interface is consumed by the line `record` prints ("Pipe it to `ai-log note <id>`"), so the executor would ask: must
`note` run in the work repo and take the plan file, or should `record` keep the redaction terms somewhere (and where,
given entries hold no free text)? Scenario: One executor builds `note <id>` to read the cwd's origin and branch but
has no plan file, so the plan's first-heading words go unredacted at company level. Another adds a `<plan-file>`
argument, which breaks the printed instruction and the Tests' `note` calls. Either way the redaction tests for company
level don't match the interface.
Refuted: Downgraded from major by the verifier. Downgraded. `note` runs from the same skill step, in the work repo, so
the cwd gives the remotes, folder and branch. At company level the entry's `plan` is a hash over origin and basename,
so `note` can hash each `plan-*.md` at the repo root to find the plan file and read its first heading, with no
interface change. An executor can choose this and a reviewer can check it in the diff, so it's cheap to settle while
implementing.

### R9-26 · minor · decisions

Task 15 Change, *The window* with Task 17's session-end `ai-log record`, and Task 15b's printed introspection prompt:
Session-end records are new in Task 17, and each one ends a window. The final `record` after the plan's commit then
starts at the last session-end entry's end. So the numbers 15b prints for "a short introspection of this run" cover
only the final session, not the plan. The spec asks for "After every plan … a short introspection of how well the
ai-framework handled it". Two readings build different outputs: the introspection judges the last window, or `record`
prints totals over every entry with this `plan_key`. The executor would ask which. Scenario: A three-session run:
sessions 1 and 2 each end with a counts-only record, and session 3 commits and records. The printed summary shows only
session 3's cost, rounds and majors, and the per-plan introspection cites evidence that leaves out most of the plan's
review rounds.
Refuted: Downgraded from major by the verifier. Downgraded. The mechanics are right: session-end entries close
windows, and review rows already counted are skipped, so the final `record` prints only the last window's numbers. But
changing what `record` prints, for example to totals over the `plan_key`, is a small change confined to that output.
The plan's Revisit exists precisely to judge whether the printed numbers are right and enough after the first real
entry. It's real, but not costly to reverse.

### R9-27 · major · decisions

Task 17 Change, *When* ("a stop to ask") and *The skill* (branch case: commit `Work in progress: Tasks <list>` and
push): The user asked to "commit and ai log at the end of sessions". The plan widens that to every stop to ask, and
most stops are answered in the same session. In the branch case, each question then makes a work-in-progress commit
pushed to the PR branch (starting CI, visible to colleagues at company level), plus a log entry pushed to the log
repo. Those effects reach other people, and the user hasn't confirmed this widening. The executor would ask: is a stop
to ask a session end, or only a wrap-up request and a part-way final report? Scenario: In a company run landing by PR,
a run stops to ask four times. The PR branch gets four `Work in progress` commits and four CI runs that colleagues
see, though the user never ended a session.
Fixed: A stop to ask is no longer a session end: Task 17 triggers on the user's wrap-up request or a part-way final
report, the user having said "at the end of sessions".

### R9-28 · major · decisions

Task 17 Tests, *By the session* (the real `save`, `ls-remote` and `drop` of `refs/wip/ai-framework`); 2026-11-09
Approvals: The ref case rests on two things that are checked only after the script and skill are built: that the
remote host accepts and keeps a ref outside `refs/heads`, and that auto mode and the guard let a session run the force
push (`+refs/...`) and the delete push (`:refs/...`). Auto mode already blocks some git operations as destructive (the
plan's own note about `git mv`). If either assumption fails, the design must change after it's built. The executor
would ask: is this spiked first, and if auto mode refuses the `+` push, which fallback (for example, delete then
push)? Scenario: Task 17 is built and reviewed. Then the session's real `save` is refused by auto mode as a force
push, or a company Forgejo rejects `refs/wip/*`. The skill's session-end path doesn't work, and the stop comes at the
end of the task rather than before the work.
Fixed: Moot: Task 17 no longer has a private ref or `bin/plan-wip`; on the user's 2026-11-09 ruling after round 9 a
session end commits the work in progress on the branch and pushes it, and the work lands by a squash-merged PR. The
only pushes are `git push -u origin <branch>` and the log clone's, no force or delete push.

### R9-29 · minor · decisions

Task 13 Files and Tests; deviation of 2026-11-03 / 2026-11-05: The Files list deletes three plan files, but `git
ls-files 'plan-ai-framework*'` also lists the closed logs
`plan-ai-framework-review-findings-code-closed-2026-11-05.md`, `…-plan-closed-2026-11-05.md` and
`…-plan-closed-2026-11-05-2.md`. The test demands they go too. The executor would ask: delete the closed review logs
as well, or narrow the test? Task 15's `record` also reads closed logs, so they must outlive the record step either
way. Scenario: The executor deletes only the three listed files, and Task 13's test fails on the closed logs. Or it
deletes them too, outside its Files list, and Completion's per-task pathspecs miss the deletions.

### R9-30 · nit · decisions

Task 15 Tests, *Real data* ("while `HEAD` is still the `Base:` commit"): `HEAD` is already past `Base:` (cdf0a77):
commits d88b6fa through 5b563f3 sit on top, and the 2026-11-09 rebuild doesn't happen until the final review. Two
readings give different windows. Pass `Base:` as `<commit>`, which ends the window before the run's work, or pass no
commit, which ends it now, as the stated intent says. Scenario: An executor passes `cdf0a77` to honour the condition
and gets a window that ends before the 2026-11-05 work. The price check and the warnings audit then run over the wrong
data.
Refuted: Downgraded from minor by the verifier. Downgraded to wording. HEAD is past `Base:` (5b563f3 vs cdf0a77), but
the command given has no `<commit>`, and the sentence states the intent: 'so the window runs from the plan's first
appearance to now'. With no commit the window ends now whatever HEAD is. The 'while HEAD is still Base' clause is
stale wording, and the command an executor would actually run isn't ambiguous.

### R9-31 · nit · decisions

Follow-ups section, `### Revisit · Does a real entry hold what an introspection needs?`: `implementing-plans` iterates
the plan in the run "at a `## Revisit` heading". This heading is `###`, under "Follow-ups, not tasks of this run". An
executor might read it as the skill's Revisit trigger and stop to iterate after Task 15's dry run, or skip it as the
plan intends. The two readings differ in whether the run halts there. Scenario: After Task 15, the session sees
"Revisit" and launches a plan-iteration agent and a plan review in the middle of the run, though the Revisit needs
15b's first real entry, which only exists after the final commit.
Refuted: Downgraded from minor by the verifier. Downgraded. The skill's trigger is literally a `## Revisit` heading
(SKILL.md:113). This one is `###`, under 'Follow-ups, not tasks of this run', and it says it needs Task 15b's first
real entry, which exists only after the final commit. A literal reading doesn't trigger the in-run iteration. At most
it's a wording risk.

### R9-32 · minor · decisions

Task 15 Change, *Customer level, deferred* (the clone's `allow` file): The plan doesn't say whether Task 15 creates
and seeds `allow` in the private log repo, or what its committed format and initial contents are. The user's company
work runs on Forgejo (global `CLAUDE.md`), so without a line for that host every company run prints "customer level is
deferred, nothing recorded". The executor would ask: is the company Forgejo's `<host>/<owner>` added now, by the user
and by hand, and does `allow` live committed in the log repo so every machine shares it? Scenario: Task 15 ships with
no `allow` file. Every Uptime run on Forgejo silently records nothing, and the message wrongly calls it customer
level.

### R9-33 · minor · decisions

2026-11-05 Approvals ("after every plan, at every level and on every machine") and Task 15 exit 2: The plan doesn't
say how the log clone `$HOME/.ai-framework-log` gets onto each machine: an init script, or by hand. Without a clone,
`record` exits 2, and the skill step only reports it, so entries quietly go missing on other machines. The executor
would ask: does a `bin/dotfiles` init script clone it, or is it a manual step recorded in docs? Scenario: On the
user's second machine, the first plan's completion runs `ai-log record` and exits 2. The report notes the failure, but
that plan's entry and introspection are never written.

### R9-34 · major · consistency

§ Approvals, 2026-11-09 bulk answers (d88b6fa "Squash it out"); Task 13's 2026-11-05 deviation; Order (lines 183-184);
Handover "Start next session here" (line 202): The approved rebuild of `ai-framework` from `Base:` and the one `git
push --force-with-lease origin ai-framework` appear only in § Approvals. No task, the Order paragraph, Task 13's
delete sequence, or the Handover's resume line includes them. Those three all list the run's tail as: final review
commit, `ai-log record`, 13's `git rm`, fast-forward `main`, push. Nothing says who rebuilds, when, or what happens to
the non-WIP commits since Base (06f51fa, 0433f08, 5b563f3) and to d88b6fa's content, which includes Task 7's
task-reviewed `CLAUDE.md` reword. Scenario: An executor following the Order or the Handover line runs the final
commit, record, `git rm`, then fast-forwards `main`. The WIP commit d88b6fa reaches `main`, against the user's "Squash
it out". If the executor rebuilds after `ai-log record` instead, the recorded entry's `commit`/id names a sha the
force-push discards.
Fixed: Moot: no rebuild and no force push; on the user's 2026-11-09 ruling after round 9 this run lands by a
squash-merged PR, which removes `d88b6fa`, and the Order line, the handover and Task 13 now list the tail: the final
review's commits on `ai-framework`, `ai-log record`, Task 13's `git rm` commit, push, the PR, squash-merged on green
CI, `main` pulled. The squash happens after `ai-log record`, whose entry names the pre-squash commit, as any PR's
would.

### R9-35 · major · consistency

Task 17 § The skill (session-end `ai-log record`) vs Task 15b § Change (`record` prints, then the introspection) and
Task 15 § The window: Task 17 adds a counts-only `record` at every session end, and each entry ends the next one's
window. Task 15b's per-plan introspection is still written from the numbers the final `record` prints, and those cover
only the window since the last session-end entry. Task 15b was not updated to sum the plan's entries by `plan_key`.
Scenario: A plan built over three sessions: sessions 1 and 2 end with session-end records. The final commit's `record`
prints cost, rounds and majors for session 3 only. The "short introspection of how well the ai-framework handled it"
after every plan (Task 15's spec) judges the whole plan from a fraction of its data, e.g. missing the plan-review
rounds that ran in session 1.
Fixed: Task 15b's `record` now prints each number summed over every entry with the plan's `plan_key`, session-end ones
included, so the introspection covers the whole plan; a test proves the sum over three windows.

### R9-36 · major · consistency

Task 15 § The window ("session-end runs at an unmoved HEAD share one id, the later replacing the earlier with the
longer window") vs Task 15 § What the transcripts hold (`cleanupPeriodDays` 30) and Task 17's ref case: In the ref
case `HEAD` never moves between sessions, so every session-end `record` recomputes the same entry from the plan's
first appearance and replaces it. That assumes every transcript since the first appearance still exists. Task 15
itself notes transcripts are deleted after 30 days and that this is why entries hold aggregates. Scenario: This plan
first appeared around 2026-10-13. A session-end record after 2026-11-12 recomputes the entry with the October
transcripts gone and overwrites the earlier, fuller entry. Tokens, cost and the review counts already captured are
lost for good.
Fixed: Each session end now commits before `record`, so it gets its own id and a window starting at the previous
entry's end; nothing recomputes an older entry from the plan's first appearance, so expired transcripts can't
overwrite one (Task 15 § The window, Task 17).

### R9-37 · minor · consistency

Task 17 § The skill ("The skill is at its line cap until Task 16 stops counting front matter"); Order line 180:
`implementing-plans/SKILL.md` is pinned at 120 counted lines in `.md-baseline`, a ratchet. It is far below the 150
hard cap. Not counting front matter frees only its 4 lines (116 of 120). Task 17 adds more than that: a new section,
the restore line, edits to resume step 1, Before staging and Finish, and the opening line and red flag. The
16-before-17 ordering rests on a budget that wasn't measured. Scenario: After Task 16, Task 17's implementer adds
about 8-10 lines. `bin/check-md-limits` fails on the pin, and the task stops. The executor must either deliberately
raise a pin the plan never mentions or move text to `implementing-plans-reference.md`, which the plan does not say.
Refuted: Downgraded from major by the verifier. The budget problem is real. .md-baseline pins
implementing-plans/SKILL.md at 120, and the skill counts 120 now (non-blank, non-heading lines). Dropping the 4
front-matter lines frees only 4, and Task 17's listed additions run to roughly 8-12 lines. Downgraded because
claude/docs/implementing-plans-reference.md already exists (14 lines) and can take the overflow. Only the three
trigger lines the tests grep for must stay in the skill. That is cheap to settle while implementing and checkable in
the diff, and it needs no rework of the ordering.

### R9-38 · minor · consistency

Task 17 § Change, `save` (`':(exclude)plan-*' ':(exclude)/00-follow-ups-*'`) vs "Follow-up trackers stay out, as from
the listing": The save's pathspec is not the listing's. The listing uses `:(top,glob,exclude)`, but the save uses
plain `:(exclude)`. Without `glob` magic, `/00-follow-ups-*` needs a literal slash, so a root-level tracker is not
excluded. I checked this in a scratch repo: `00-follow-ups-me.md` at the root was added and `sub/00-follow-ups-x.md`
was excluded. Without `top`, the patterns are also relative to the cwd. Scenario: A repo with `00-follow-ups-me.md` at
its root: `plan-wip save` puts the user's private tracker into `refs/wip/<branch>` and pushes it to origin, which may
be a shared company remote. Follow-up items are meant to be "the user's own and never shared".

### R9-39 · minor · consistency

Task 17 § The skill ("Resume step 1 … the restored save's `^2`"; "Before staging: `HEAD` must equal …") vs
implementing-plans § Checkpoint, Before staging ("the index's tree the last checkpoint's (`HEAD^{tree}` before the
first)"): Task 17 updates resume step 1's notion of the last checkpoint and the `HEAD` half of the Before-staging
check. It leaves that check's index half as `HEAD^{tree}` before the first checkpoint, which no longer holds after a
restore on another machine. Scenario: On a second machine, `restore` puts the index at the save's `^2`, which holds
checkpointed tasks, with no `refs/checkpoints/*`. Before the run's first staging, the session compares the index with
`HEAD^{tree}`, finds them different, and stops with "a subagent ran git".

### R9-40 · minor · consistency

Task 13's 2026-11-05 deviation and Deviation (2026-11-03) open-item list; Handover item 6; status table rows 5, 8, 9:
Task 13's issue list is stale and incomplete. It still lists "Task 7's conflict sent to the user", which was ruled
2026-11-05 (Approvals, Handover item 5). It omits what Handover item 6 names (the audit's Mediums and Lows, R12-4). It
also omits the reruns that keep Tasks 5, 8 and 9 🚧 PARTIAL (Handover items 1-2), the unfiled learnings, and #73.
Scenario: The plan is `git rm`'d after an issue built from Task 13's list. The pending reruns for Tasks 5, 8 and 9 and
the unfiled learnings exist nowhere else and are lost, defeating "so deleting the plan loses none of them".

### R9-41 · nit · consistency

Implementation status, `Final code review` row (✅ DONE); Task 13 ("the run's one final code review covers it"): The
status table shows the final code review ✅ DONE from earlier runs while Tasks 15, 15b, 16, 17 and 13's fold are
pending. The workflow says this row stays ⏳ PENDING until `Done (code):`. Scenario: An executor or the user reading
the table believes the final review for this run's tasks is already done, and a skipped final review stops being
visible in the plan, which is the row's whole purpose.
Refuted: Downgraded from minor by the verifier. Downgraded. reviewing-in-rounds flips the row to DONE on `Done
(code):`, and no rule explicitly resets it. More to the point, the Handover's resume line, the Order and Task 13 all
name this run's final code review as still to come. No executor would skip it because of the table, so this is a stale
status label, not a real risk.

### R9-42 · minor · consistency

Task 15 § Tests, Real data ("while `HEAD` is still the `Base:` commit") and "No real `record` runs here: the first is
Task 15b's end to end": Both statements are stale. `ai-framework` already has four commits past `Base:` cdf0a77
(d88b6fa, 06f51fa, 0433f08, 5b563f3). Also, the run builds 17 before 15b, so Task 17's session-end `record` runs a
real record, and pushes to the log repo, before Task 15b exists. Scenario: The executor reaching the real-data step
finds `HEAD` ≠ `Base:` and either stops or misreads the window. A session ending between Tasks 17 and 15b writes the
first real entry, contradicting Task 15. It is also outside the "From Task 15b on" wording of the log-repo approval.

### R9-43 · minor · consistency

Task 17 § Files; Task 15b § Files (`claude/docs/work-contexts.md` line): Task 15b's `work-contexts.md` text says only
that `reviewing-in-rounds` runs `ai-log` after a plan's commit. Task 17 adds standing-yes writes at every session end:
a WIP commit and `git push -u` in the branch case, a push of `refs/wip/<branch>` to origin, and a session-end `ai-log
record`. Task 17 does not update `work-contexts.md` § *An approval covers one action, not a policy*. Scenario: The
durable doc says the only standing-yes write is the post-commit log step. A reader or agent checking what may be
pushed without asking finds no basis for session-end pushes once Task 13 deletes the plan.

### R9-44 · nit · consistency

Task 15b § Tests, End to end ("Record here only that it ran, and the id"): The run happens after the final code
review's commit, and Task 13's `git rm` deletes this plan right after. So the evidence is recorded in a file that is
never committed and is deleted immediately, and Task 13's issue was already filed by then. Scenario: The id and the
fact that the step ran are lost with the plan. Nothing durable shows that Task 15b's end-to-end test passed.
Refuted: Downgraded from minor by the verifier. Downgraded. The step's evidence lives durably elsewhere: the entry and
its introspection are committed and pushed to andrelin/ai-framework-log under that id, and the run's final report
names it. Losing the plan's one-line note costs nothing that matters.

### R9-45 · nit · consistency

File map: Task 16's files (`bin/check-md-limits`, `test/test_check_md_limits.sh`, `claude/docs/markdown-limits.md`)
are missing from the file map. The `bin/check-md-limits` row lists only Task 0. Scenario: A parallel-safety check
against the file map would miss that Task 16 shares `bin/check-md-limits` and its test with any other task touching
them.
Refuted: Downgraded from minor by the verifier. Downgraded. The file map indeed lists bin/check-md-limits and its test
only for Task 0, and omits claude/docs/markdown-limits.md. But this run builds 16, 15, 17 and 15b one after another,
and Task 0 is done, so no parallel-safety decision depends on the omission. It is bookkeeping.

### R9-46 · nit · consistency

§ Global constraints, Markdown limits: The limits are not updated for Task 16's decision that front matter no longer
counts toward a file's aim and cap. Scenario: After Task 16, a reader of the constraints would count front matter
against a skill's 100/150.

### R9-47 · nit · consistency

§ Approvals, 2026-11-09 bullet (line 110): A comma is missing: "This run's session ends before Task 17 is built follow
its steps by hand." Scenario: The sentence reads as "Task 17 is built follow…", which obscures that it is an
instruction to follow Task 17's steps by hand.

### R9-48 · major · work context

Task 17, Change: `save` and the ref case; the 2026-11-09 Approvals block ("a private ref is fine"); Tests: By the
session: The 'private ref' `refs/wip/<branch>` is only private where the repo is. On a personal public repo such as
this one (and on any public company repo), every pushed ref is listed by `git ls-remote` and anyone can fetch it.
GitHub also keeps the objects reachable by SHA after `drop` deletes the ref. The save's tree is `git add -A` over
every unstaged and untracked file that isn't ignored, plus plan and review files, "tracked or not". So scratch files,
drafts, and company plans kept untracked on purpose get published world-readable forever. The level check is only
`work-context.sh level`, which prints `personal`/`company` and never consults `gh repo view --json visibility`. The
user's ruling rests on the ref being private, and the plan never checks that. Scenario: A session on this public
dotfiles repo stops part-way while an untracked scratch note sits in the work tree, for example a draft that names a
customer for a Task M edit or a token pasted while debugging. `plan-wip save` commits it into `refs/wip/ai-framework`
and runs `git push origin +refs/wip/...`. The content is now public, which breaks the personal-public bar
("world-readable forever: no customer names, hostnames, internal tooling, secrets"). The same applies at company level
when an untracked plan named for an engagement is pushed to a public `uptimeconsulting` repo. Fix: resolve visibility
and refuse, or save only the plan and checkpoint files, on a public origin.
Fixed: Moot: Task 17 no longer has a private ref or `bin/plan-wip`; on the user's 2026-11-09 ruling after round 9 a
session end commits the work in progress on the branch and pushes it, and the work lands by a squash-merged PR. Only
checkpointed tasks and the tracked plan files are committed, so no untracked scratch file is published.

### R9-49 · minor · work context

Task 17, Change: `save` (the tree is "the index plus every entry of the skill's listing, unstaged and untracked"); the
2026-10-30 Approvals first bullet: `save` sweeps the user's own uncommitted edits into a commit and pushes it to
origin. The standing approvals say the opposite: commit "keeping the user's own uncommitted edits out". An approval
also covers only what it names, and the 2026-11-09 yes named the run's checkpoints, half-done task and plan. Nothing
in `save` tells a leftover from the run's half-done task apart from an edit the user made by hand. Scenario: The
gitStatus at this session's start shows the user's own uncommitted edits to `plan-ai-framework.md` and the findings
file. The plan files are included on purpose. But an unrelated edit the user is making in `source/` or `claude/` at
the same time gets pushed to origin under `refs/wip/ai-framework` without the user's yes. A later `restore` on another
machine then lays it down with `read-tree -u --reset`.
Refuted: Downgraded from major by the verifier. Downgraded. The 2026-10-30 'keeping the user's own uncommitted edits
out' bullet governs commits to main, and later bullets replaced it for these runs. The save is a non-branch ref that
each save replaces and `drop` deletes. `restore` refuses unless the target's listing is empty, so it never overwrites
local work. Part of the concern is real: the yes named the run's checkpoints, half-done task and plan, and
implementing-plans already separates run leftovers (paths in a task's Files list) from everything else. Limiting the
save to Files-list leftovers plus the plan files is a pathspec change that is cheap to make while implementing. Where
it matters most, on a public origin, finding 0 already covers it.

### R9-50 · major · work context

Task 17, Interfaces and `save` (level from `PLAN_WIP_LEVEL` = `work-context.sh level` only), compared with Task 15's
Customer level, deferred: Task 15 deliberately stops trusting `work-context.sh level` alone (R5-37, R5-38, R6-32). A
customer repo not yet in `~/.claude-customers` resolves as `company` (guard lines 639-662, and 15c's note says the
same), so `ai-log` also requires the origin to be `github.com/andrelin`, `github.com/uptimeconsulting` or an `allow`
entry. `plan-wip` has no such check. In the branch case its skill section commits and runs `git push -u origin <branch>`
and in both cases it pushes a `refs/wip/` ref, including untracked plan files, to whatever origin resolves
as company. Scenario: The user starts work in a new customer's GitHub org and hasn't added the org to
`~/.claude-customers` yet. The guard resolves it as company, the session stops part-way, and `plan-wip save` pushes
`refs/wip/<branch>` into the client's remote. If the plan's Approvals mention a PR, the skill also commits a `Work in
progress` commit there and pushes it. Both are customer-level writes ("push in any form") that the user never made.
Task 15 already closed this gap for the log, which only reads transcripts.
Fixed: Task 17's level is now `ai-log level`, a new Task 15 subcommand printing the level by Task 15's gate with its
origin allowlist, so an unlisted customer repo gets no commit or push; tests in both tasks.

### R9-51 · minor · work context

Task 17, Change: `drop` and `restore`; the skill's Finish step: Only `save` checks the level. `drop` always runs `git push origin :refs/wip/<branch>`
and `restore` fetches and runs `git switch -c`/`read-tree`, with no customer check.
The skill's Finish step ("once the code review's commit has run, `plan-wip drop`") isn't limited to personal and
company level either. Inside the script the push is caught only if the `git` shim is first on `PATH`, not by the
PreToolUse hook, which sees just `plan-wip drop`. Scenario: A customer-level run ends: the user makes the commit, and
the skill then runs `plan-wip drop`. If "none present" only means locally absent, the script still issues `git push origin :refs/wip/<branch>`
against the customer's remote. That is a push in a form the level forbids, and it is
blocked only by luck of `PATH`. Fix: make `drop` (and `restore`'s writes) exit 0 at customer level as `save` does, and
say so in the skill line.

### R9-52 · nit · work context

Task 15b, Change: the mechanical redaction; the 2026-11-05 Approvals ("at every level ... the introspection"): At
company level the introspection's prose goes to a repo on the personal account. Redaction folds only names listed in
`~/.claude-customers`, the work repo's remotes and folders, and the plan's and branch's words. The client named inside
a company engagement's plan body or tasks is not in any of those sources until 15c's model pass. The plan relies only
on the prompt's "no customer names". Scenario: An `uptimeconsulting/<engagement>` repo whose plan's tasks name the end
client, with the client not listed because the repo is company. The model's introspection says "the `<client>` SSO
migration review took 9 rounds". The redaction misses it, and `ai-log note` commits and pushes it. Within the user's
private repo this is acceptable at personal-private level, but the gap should be stated in the `work-contexts.md` text
Task 15b adds, which currently promises the prose is "mechanically redacted".
Refuted: Downgraded from minor by the verifier. Downgraded to nit. The destination is the user's own private log repo,
and the 2026-11-05 Approvals explicitly cover the introspection at company level. The prompt forbids customer names.
Follow-up 15c already records the model terms pass 'at every level, since a customer repo not yet in
~/.claude-customers resolves as company', so the gap is known and deferred. The work-contexts.md text says
'mechanically redacted', which is accurate; it doesn't promise the result is complete. What's left is an optional
caveat in the doc's wording.

### R9-53 · nit · work context

Task 13, Deviation (2026-11-03): the issue that carries open items: The issue goes on this public repo. The plan
doesn't say that what it carries meets the personal-public bar, for example that Task M's items name no customer or
repo-specific facts (its own text says those stay in the private repo). Scenario: While drafting, the executor expands
Task M's "that repo's confidentiality, its external mirror folder" into the actual repo and folder names to make the
item actionable, and files that on the public dotfiles issue tracker. One line saying the issue keeps to the plan's
wording, with no names added, would settle it.
Refuted: Dropped by the verifier. Dropped. The 2026-11-09 Approvals record Task 13's issue as 'Ask me then — the run
stops at Task 13 to show the draft before filing', so the user reads the draft before anything reaches the public
tracker. Task M also keeps customer names in the private repo by its own text. The scenario where names creep in
during drafting is caught at that user checkpoint, so it isn't an unguarded failure, and it is a drafting choice left
to the executor.

## Round 10

### R10-1 · major · grounding

Task 17, Change, *Landing* and *The skill*; Approvals 2026-11-09 ("work that has such commits lands by a squash-merged
PR"): The rule that makes WIP commits acceptable, that such work lands only by a squash-merged PR, is not written
anywhere an executor loads. Task 17's skill paragraph holds only "the trigger, the level, the steps and customer
level", and `reviewing-in-rounds` stays "unchanged", which means its Completion still only offers per-task commits and
says nothing about how the branch lands. The rule would exist only in the plan, which Task 13 deletes, and in
`staged-workflow.md`, a reference doc no skill loads. Simpler fix: put one clause in the same `implementing-plans`
paragraph, or in Completion: "a branch holding session-end commits lands by a squash-merged PR, never a fast-forward".
Scenario: A future personal plan whose `## Approvals` says "fast-forward `main`, push", as this plan's own 2026-11-02
run did, has two session ends. Its `Work in progress: Tasks …` commits, empty ones included, are fast-forwarded onto
`main` and pushed to a public repo. At company level the same thing breaks the "readable history before `main`" bar
that the user's ruling was meant to protect.
Fixed: Task 17's skill paragraph carries the landing rule: a branch holding session-end commits lands by a
squash-merged PR, never a fast-forward.

### R10-2 · minor · grounding

Task 17, Change, *The level* ("`ai-log level`, Task 15's gate with its origin allowlist"); Task 15, *Customer level,
deferred*: The session-end commit and push are gated on the analytics allowlist: `github.com/andrelin`,
`github.com/uptimeconsulting`, or a line in the private log clone's `allow` file. Any other origin counts as customer.
That makes a git-safety decision depend on a data repo's config. Nothing in the plan populates `allow` or says who
does, and it does not say what `ai-log level` prints when `AI_LOG_DIR` is missing, as on a fresh machine. The stated
reason (R9-50: an unlisted customer repo gets nothing committed) is also inconsistent: the same unlisted repo resolves
as company for `reviewing-in-rounds` Completion, which commits on `work-context.sh level`, and for the guard. The
simpler approach is the level every other commit step already uses, `work-context.sh level`, which the guard enforces
anyway. Scenario: Company work on the company's Forgejo host (the global `CLAUDE.md`'s *Forgejo work*; the plan itself
names "a company Forgejo") resolves as company, but `ai-log level` prints `customer`. Every session end there commits
and pushes nothing. That silently breaks the user's standing rule, "Commit and push the branch" at personal and
company level, and work done on one machine never reaches another. The same happens on any machine where the log repo
isn't cloned yet, if `ai-log level` fails or defaults to customer.
Refuted: Downgraded from major by the verifier. Downgraded. The gate is a deliberate, recorded decision (R9-50), and
Task 15 already names the `allow` file as the remedy for "a company Forgejo, say". Its failure is fail-safe: at
customer level nothing is committed, and the report lists the uncommitted work and checkpoint refs, so nothing is lost
or wrongly written. The real gaps are cheap to settle while implementing: what `ai-log level` prints when `AI_LOG_DIR`
is missing, and who adds the Forgejo line to `allow`. Switching to `work-context.sh level` would also not be costly to
reverse once built.

### R10-3 · minor · grounding

Task 17, Change, *When*: The trigger contradicts itself. It names "the run's part-way final report, the one that
prints `ai implement <plan-file>`" as a trigger, and says "a stop to ask is not one". But `implementing-plans` prints
exactly that part-way report on every stop, a stop for a user decision included ("every stop here stops"; § *Finish*:
"A run that stopped part-way … prints `ai implement <plan-file>`"). The executor can't tell which stops should save.
Scenario: A run stops to ask about a deviation and prints the part-way report. Under one reading it makes an
`--allow-empty` WIP commit, pushes, and writes a log entry on every question. Under the other reading the part-way
report never triggers, and only an explicit "wrap up" saves.

### R10-4 · minor · grounding

Task 15, Interfaces, the entry ("An agent's lens comes from the `Lens:` line of its prompt … the `###` heading … the
line starts with"): The plan assumes the reviewer prompt holds a line that starts with `Lens:`. I checked this
session's real Workflow agent transcripts (`subagents/workflows/wf_*/agent-*.jsonl`): the harness indents every line
of the computed task text, so the line reads `Lens: Security and work context — …`, with leading spaces after a
harness preamble. In the skill's template the `Lens:` text also sits mid-line after a sentence. Fixtures invented from
the template would pass, while real Workflow reviewers land under no lens. The real-data dry run only greps for leaks
and checks prices, so nothing would catch it. Scenario: Task 15's real dry run on this plan writes `tokens per review
lens` with every Workflow reviewer's tokens under no lens. Follow-up 15d's cut candidates by lens are then built on
empty data.

### R10-5 · nit · grounding

Task 17, Change, *The skill* (only the opening line and the red flag are edited);
`claude/skills/implementing-plans/SKILL.md:64`: The skill's review-input rationale, "since nothing is committed and
`BASE..HEAD` is empty", becomes false after a session-end commit, but Task 17 doesn't list it among the in-place
edits. The per-task input (the unstaged diff) is still right, but the stated reason now misleads a reader into
thinking `Base..HEAD` is always empty. Scenario: After a resume across a session-end commit, a session reasons from
line 64 that `HEAD` equals `Base:`, then misreads the moved `HEAD` as a subagent having run git, or picks the wrong
review input.
Refuted: Downgraded from minor by the verifier. Downgraded. Behaviour is unaffected. The per-task review input stays
`git diff -- <paths>` on the unstaged diff, which is still right, and the *Before staging* moved-`HEAD` check
(SKILL.md:91) compares against the run's starting `HEAD`. Task 17 says explicitly that the check is unchanged and that
the next run starts at the new `HEAD`. Only the stated reason ("`BASE..HEAD` is empty") becomes inaccurate, so this is
wording.

### R10-6 · nit · grounding

Follow-up 15c, Sketch ("a model terms pass … runs at every level, since a customer repo not yet in
`~/.claude-customers` resolves as company"): This rationale is out of date against Task 15's origin allowlist. Any
origin outside `github.com/andrelin` and `github.com/uptimeconsulting` and not in `allow` is already deferred as
customer, so an unlisted customer repo is not recorded as company. Task 13's issue would carry the stale reasoning.
Scenario: Whoever details 15c from the issue builds a model pass at personal and company level for a risk the
allowlist already closed, paying a model call on every entry.
Refuted: Downgraded from minor by the verifier. Downgraded. The rationale is stale: Task 15's origin allowlist already
treats an unlisted customer repo as customer. But 15c is a Sketch, which by its own text is detailed only after the
Revisit has seen real entries, and it is re-decided then. A stale reason in a sketch is wording and costs nothing to
fix now. Whether to build the model pass at personal and company level gets settled when 15c is detailed.

### R10-7 · nit · grounding

Task 15b, *Why not also `implementing-plans`* ("it never commits"): Once Task 17 is built, `implementing-plans` does
commit (the session-end commit) and runs `ai-log record`, so this justification is wrong. The outcome is still right,
since the 15b introspection step belongs only in Completion. Scenario: A reader of the folded `staged-workflow.md` or
of Task 13's issue sees "implementing-plans never commits" next to a skill that does.

### R10-8 · nit · grounding

Task 16, Change (glob list): "The common languages" is the user's ruling, but the list leaves out several common
source extensions that the language-neutral rule would apply to: `.mjs`, `.cjs`, `.vue`, `.dart`, `.sql`,
`.cs`-adjacent `.csx`/`.razor`, `.m`. I verified the problem is real: the current `paths:` holds no `/*.cs`. Scenario:
The next report says the rule didn't load for an `.mjs` or `.razor` file, which is the same silent failure
`rule-globs.md` warns about.

### R10-9 · major · scope and slicing

Task 15, Interfaces (the entry: tokens per review lens from the `Lens:` line) and Tests (Counts); order of the Real
data step: Per-lens cost rests on an unverified assumption: that a reviewer's prompt has a line that *starts* with
`Lens:`. Workflow-computed prompts break that. In this very review's prompt, `Lens: Scope and slicing — …` sits in the
middle of one long line. Meanwhile each Workflow agent's `.meta.json` already carries the lens in `description`
(`"review:Scope and slicing"`, checked in ~/.claude/projects/-Users-andrelin--dotfiles/*/subagents/*.meta.json), and
Task 15 reads that file only for `workflowPhase`. The fixtures are invented to match the assumption, so the tests
pass. The one check against real transcripts is the dry run, which comes last and greps only for leaks, never for
per-lens totals. Scenario: Task 15 ships green. Every plan review run as a Workflow puts its reviewer tokens under no
lens, and no warning fires. Task 15d's cut candidates by lens (the reason R7-2 added the field) then rest on empty
data, and the stored entries can't be re-derived once transcripts expire after 30 days. Two fixes: check per-lens
totals in the real-data dry run, and move that check up as a first spike so a missing field is caught before the
schema is built on it. Or take the lens from `.meta.json` `description`.
Fixed: the lens comes from a Workflow agent's `.meta.json` `description` where present, else from `Lens:` anywhere
in the prompt, indented or mid-line; a fixture copies a real prompt's shape.

### R10-10 · minor · scope and slicing

Task 17, Tests (Resume across a session-end commit) against Task 15's `ai-log level` gate: The resume test calls for
'a scratch repo with a local bare repo as `origin`'. Task 15's gate prints `customer` for any origin that is not
`github.com/andrelin/…`, `github.com/uptimeconsulting/…` or a host/owner in the clone's `allow` file. A local path
origin fails that gate, so the session-end steps 'as the skill words them' commit and push nothing, and the test
cannot pass as written. The plan says neither how to make that origin resolve as personal (for example a
`github.com:andrelin/…` url with a `pushurl` to the bare repo, or an `allow` entry) nor that `AI_LOG_DIR` must point
at a throwaway clone. Scenario: An executor runs the test as written, sees no commit, and either loosens the gate or
points origin at a real `github.com:andrelin/…` url. In the second case the steps' `ai-log record` writes to and
pushes the user's real `$HOME/.ai-framework-log`, a write this test was never approved for.
Refuted: Downgraded from major by the verifier. Downgraded. The gap is real: a local-path origin fails `ai-log
level`'s origin allowlist, so the session-end steps commit and push nothing and the test as written cannot pass. But
it is a test-setup choice the executor can settle cheaply (a github.com:andrelin/… url with a `pushurl` to the bare
repo, or an `allow` entry), and a reviewer can check it in the diff. The feared write to the real log is also
unlikely. The session's cwd is the dotfiles repo, not the scratch repo, so `ai-log record` there finds no session in
scope and exits 1 without writing.

### R10-11 · minor · scope and slicing

Task 17, Change: Landing vs The skill: Work-in-progress commits are only safe because 'work that has such commits
lands by a squash-merged PR'. But the skill paragraph Task 17 writes holds only 'the trigger, the level, the steps and
customer level', not the landing rule. The rule applies to every future run at personal and company level, but it
would live in this plan alone, and Task 13 deletes the plan. Scenario: A later plan's `## Approvals` says 'commit to
`main`' or 'fast-forward `main`', as this plan's own 2026-10-30 and 2026-11-02 blocks did. Its session ends make `Work
in progress: Tasks …` commits, some of them empty, and the fast-forward lands them on the default branch. At company
level that breaks the readable-history bar. Fix: put the landing rule in the skill line, or have the session end stop
when the plan's Approvals land by anything other than a PR.
Refuted: Downgraded from major by the verifier. Downgraded. 'It would live in this plan alone' is refuted: Task 13's
fold writes 'a session end's work-in-progress commit and the squash-merged PR it calls for' into
claude/docs/staged-workflow.md. What remains is that the skill, which is the point where the commits are made, does
not carry the landing rule. A future run reading only implementing-plans could still fast-forward WIP commits onto
main. Adding one clause to the skill paragraph is cheap while implementing.

### R10-12 · minor · scope and slicing

Task 17, Change: `--allow-empty` (R9-4, R9-36): The forced empty commit adds a mechanism nothing needs. Task 15
already handles a re-run at the same `HEAD`: same id, it skips its own entry when searching and replaces it with a
window from the previous other entry to now (Task 15's test: 'two runs at the same `HEAD` → one entry, the later
window'). So a second session end with no new checkpoint loses no counts without an empty commit. Scenario: Every
session end with nothing new still adds an empty commit to the branch and the PR. The test 'A second session end …
still makes a commit' then locks in behaviour no requirement asks for. Dropping `--allow-empty` and that test makes
the task smaller.
Refuted: Dropped by the verifier. The empty commit does something Task 15's same-HEAD replace cannot. Suppose a
session end on machine A records id(X) at HEAD X. Machine B then pulls and ends a session that checkpointed nothing
new. Without an empty commit, B's record replaces entry id(X) from B's transcripts alone, and A's sessions are lost,
because B cannot see A's transcripts. A new HEAD per session end avoids that. The empty commits vanish in the squash
merge, so they cost little.

### R10-13 · minor · scope and slicing

Task 15, Tests: Counts ('at company level the plan's and branch's words redacted from the introspection (15b)'): Task
15's test list includes a behaviour of Task 15b: redacting the introspection through `ai-log note`. That subcommand
doesn't exist until 15b is built. Scenario: The Task 15 executor can't write or pass this test, and either stubs
`note` early (building part of 15b inside 15) or leaves a test unmet and stops. Move the line to Task 15b's Redaction
tests.

### R10-14 · minor · scope and slicing

Task 15, Interfaces (`commit`, `framework.dotfiles_commit`) vs the 2026-11-09 squash-merge landing: Task 15's schema
was designed before the switch to squash-merged PRs. Under that landing, every run built on a branch records branch
shas, and the squash plus branch deletion makes those shas unreachable. Nobody re-checked whether `commit` and
`dotfiles_commit` still identify anything once the run lands. Scenario: This run's own entries, and every later run
built on a branch, name a `dotfiles_commit` that `main` does not contain. Task 15d's 'grouped by framework commit'
then groups by dead shas, and the stored entries are costly to repair once many exist. Settle what to store (for
example the merge-base with the default branch as well) before the first real entry.
Refuted: Dropped by the verifier. Weak failure scenario. GitHub keeps every PR's head under refs/pull/`<n>`/head after a
squash merge and branch deletion, so the shas remain fetchable. `dotfiles_commit` is a branch sha only when the plan
being run is in the dotfiles repo itself. Other runs read the dotfiles checkout, normally on main. Grouping by sha
works whether or not the sha is on main. Task 15d is an explicit sketch to be settled once real entries exist.

### R10-15 · minor · scope and slicing

Approvals, 2026-11-09 bulk block: 'A company plan landing by "a PR" counts as squash-merged … (Task 17)': This ruling
only mattered for the superseded private-ref design, which picked a branch commit or a private ref depending on how
the work landed. Task 17 as rewritten no longer has that branch, yet the Approvals line still points to Task 17, and
Task 17 says nothing of it. Scenario: An executor following the pointer looks for a 'squash-merged vs not' branch in
Task 17 and may rebuild one. Mark the line as moot under the later ruling, or drop the '(Task 17)' pointer.
Refuted: Dropped by the verifier. Not moot. Task 17's Landing still requires 'work that has such commits lands by a
squash-merged PR'. The ruling 'Any PR counts as squashed' settles that a plan whose Approvals say 'a PR' meets that
requirement. It sits in the bulk block answered after the redesign, so its pointer to Task 17 is correct and does not
invite a squash-or-not branch.

### R10-16 · nit · scope and slicing

Task 15b, 'Why not also `implementing-plans`': The rationale says `implementing-plans` 'never commits'. That has been
stale since Task 17, which adds session-end commits to `implementing-plans`. The conclusion still holds, because the
session end skips the introspection, but the stated reason no longer does. Scenario: A reader of the folded doc or the
skill history sees a reason that contradicts Task 17. Reword to: its only commits are session-end checkpoints, which
record counts but no introspection.

### R10-17 · major · decisions

Task 17, Change, Landing and The skill (with § Approvals 2026-11-09, second block): The rule that work with
session-end commits must land by a squash-merged PR is not placed anywhere an executor of a future plan will read it.
The Skill bullet puts only the trigger, the level, the steps and customer level into `implementing-plans`.
`reviewing-in-rounds` is "unchanged", and `staged-workflow.md` (Task 13) is a reference doc, not a step. The plan also
leaves open what a session end does when the plan's own `## Approvals` says to fast-forward `main`, as the 2026-10-30
and 2026-11-02 blocks did. Question the executor would ask: "Does the session-end paragraph also tell the run to land
by a squash-merged PR and override an Approvals block that says fast-forward, or does the Approvals block win?"
Scenario: A later personal plan records "commit to main / fast-forward main" in its Approvals. Its session ends write
`Work in progress: Tasks …` commits on the branch, and Completion then fast-forwards `main`. Those WIP commits reach
`main`, which the 2026-11-09 ruling ("should work in PRs that gets squashed") and the company bar of a readable
history before `main` forbid.
Fixed: with R10-1.

### R10-18 · major · decisions

Task 17, Change, At personal and company level: Nothing says what a session end does when the run's branch is the
default branch. The 2026-10-30 Approvals and earlier runs committed straight to `main`, and the step pushes `<branch>`
on a standing yes. Question the executor would ask: "On `main` or `master`, does the session end refuse, create a
branch first, or commit and push to the default branch?" Scenario: A personal plan run on `main` reaches a wrap-up.
The skill commits `Work in progress: Tasks 3, 4` with `--allow-empty` and runs `git push -u origin main`. Unreviewed
WIP commits, empty ones included, are now on the published default branch, and no squashing PR can remove them. This
is a remote write the user never approved in that form.
Refuted: Dropped by the verifier. implementing-plans step 4 always runs `git switch -c <name>`, with the name taken
from the plan file's name minus `plan-` and `.md`, and resume switches to that same branch. A run's branch is
therefore never the default branch, and `git push -u origin <branch>` pushes the plan branch. The 2026-10-30 commits
to main came before the skill existed and are not a session-end path.

### R10-19 · minor · decisions

Task 17, Tests, Resume across a session-end commit (with Task 15, Customer level deferred / `ai-log level`): The
resume test uses "a local bare repo as `origin`". Task 15's gate prints `customer` for any origin that is not
`github.com/andrelin/…`, not `github.com/uptimeconsulting/…`, and not in the clone's `allow` file. So by the skill's
own wording the session-end steps commit and push nothing in that test, while the test expects a commit, a push and a
clone that sees it. Question the executor would ask: "Does the test set a personal-looking origin URL with a separate
pushurl or `insteadOf` to the bare repo, add an `allow` line, or does the gate treat local-path origins differently?"
The last option changes a gate other tasks consume. Scenario: The executor follows the test literally, and `ai-log
level` prints `customer`. Either the test fails, or the executor quietly weakens the gate (for example, local paths
count as personal) to make it pass. That widens what `record` and the session end treat as non-customer.
Refuted: Downgraded from major by the verifier. Downgraded. The gate would print `customer` for a local-path origin,
so the test can't be run literally. The executor can fix this inside the test without changing the gate: set origin's
URL to `git@github.com:andrelin/x.git` and give it a `pushurl` (or `pushInsteadOf`) pointing at the bare repo, which
`git remote get-url origin` does not show. If the gate were weakened instead, a reviewer would see it in the diff.
Cheap to settle while implementing.

### R10-20 · minor · decisions

Task 15, Interfaces `ai-log level` / Exit 2; Task 17, The level: It is not decided whether `ai-log level` needs the
log clone. The gate reads an `allow` file in the private clone, and exit 2 is defined for "`AI_LOG_DIR` not a git
clone". Task 17 makes the session-end save of the user's work depend on that command. Question the executor would ask:
"On a machine without `~/.ai-framework-log`, does `ai-log level` fall back to the built-in allowlist, print
`customer`, or exit 2? And does the session end then skip the commit and push?" Scenario: On a second machine where
the log repo was never cloned (the Approvals say "on every machine", but nothing clones it), `ai-log level` exits 2.
Every session end there saves nothing, so the work-in-progress commit and push the user asked for ("Commit and push
the branch") never happen, and the cause is a missing analytics clone.
Refuted: Downgraded from major by the verifier. Downgraded. The gap is real: Task 15 defines exit 2 for "AI_LOG_DIR
not a git clone" without saying whether that applies to `level`. But treating the `allow` file as optional, so `level`
falls back to the built-in allowlist and the commit and push run before `record`, is a one-line choice a reviewer can
check in the diff. No built thing is costly to reverse.

### R10-21 · minor · decisions

Task 15b, The trigger / Files / Change, The skill step (with § Approvals 2026-11-05 "Yes, one line is fine"): The user
approved "one line" in `reviewing-in-rounds`. The quoted step is three sentences, about 300 characters, which under
the 150-character, one-sentence-per-line limit is at least three physical lines. The plan also renumbers steps 7 and
8. Question the executor would ask: "Does the user's 'one line' mean one list item, or one physical line? If one line,
which of the three sentences may be cut or moved into the printed output of `ai-log record`?" Scenario: The executor
writes the three-line step and renumbers the list. That edit exceeds the user's exception as worded, and an approval
covers only what it names (global § Approvals). Or the executor squeezes it into one line and drops "never undoes the
commit" or the standing-yes clause the plan relies on for the yes to outlive the plan.
Refuted: Downgraded from major by the verifier. Downgraded. The plan quotes the step's exact text, and its test fixes
the shape as "one list item after the commit step", so the executor is not left to decide anything. The open point is
whether the user's "one line" covers a three-sentence list item. That is cheap to confirm, or to trim by moving text
into `record`'s printed output, and the edit is easy to reverse.

### R10-22 · minor · decisions

Task 15, Interfaces `<id>` / entry `commit`, `framework.dotfiles_commit` (with Task 13's 2026-11-05 deviation and the
squash-merge landing): Entries store `commit` and `dotfiles_commit` as branch shas, recorded "after we commit to a PR,
before merging it". Every run now lands by a squash-merged PR (2026-11-09), so those shas are never on the default
branch and stop resolving once the branch is deleted. Task 15d groups trends "by framework commit". Question the
executor would ask: "Should an entry record something that survives the squash (the PR number, the merge-base with the
default branch, or a later back-fill of the squash sha), or are branch shas accepted as opaque?" Scenario: This run's
entries and every session-end entry carry `dotfiles_commit` values from `ai-framework`. After the squash and branch
deletion, `git show <sha>` fails, and 15d cannot tell which framework version an entry ran on. The entries are already
pushed, so fixing the format later means migrating stored data.
Refuted: Downgraded from major by the verifier. Downgraded. The user ruled "We log after we commit to a PR, before
merging it", so storing a pre-merge sha was a deliberate choice. Shas still work as opaque keys for the id hash and
for 15d's grouping, since equal shas group together even when they no longer resolve. In normal use `dotfiles_commit`
comes from main on installed machines. 15d is only a sketch, so a PR-number field can be added when it is detailed.

### R10-23 · minor · decisions

Task 17, Change, At personal and company level (`plan-<branch>-review-*`): The pattern for the review files has two
readings: the branch name, as written, or the plan's basename, which is how the findings files are actually named
(`plan-ai-framework-review-findings-*.md` for `plan-ai-framework.md`). The two coincide only in this run. Question the
executor would ask: "Is the glob built from the branch name or the plan basename?" Scenario: In a later run the plan
is `plan-auth.md` on branch `fix-login`. `git add -u -- plan-fix-login-review-*` matches nothing, so the tracked
review logs are never checkpointed and another machine resumes with stale review logs.
Refuted: Dropped by the verifier. The two readings can't differ. implementing-plans step 4 always names the branch
after the plan file minus `plan-` and `.md`, and review-log.md names the findings files
`plan-<stem>-review-findings-<kind>.md`. So `plan-<branch>-review-*` is `plan-<stem>-review-*` by construction. The
scenario's `plan-auth.md` on branch `fix-login` cannot arise under the skill.

### R10-24 · minor · decisions

Task 17, Change, the commit message `Work in progress: Tasks <list>` with `--allow-empty`: Two message questions are
left open. First, `<list>` is undefined for an empty session-end commit with nothing new checkpointed, which the test
requires. Second, at company level on Forgejo the global rule says to name work by issue and PR numbers, never a
plan's task numbers. Question the executor would ask: "What does the message say when no task was checkpointed, and do
Forgejo or company runs use issue numbers instead?" Scenario: An empty session end produces `Work in progress: Tasks …`
or an invented filler. On a company Forgejo branch the commit names plan task numbers colleagues cannot map, against
the global § Working on code. The squash hides it on `main`, but it stays in the open PR's history.

### R10-25 · minor · decisions

Task 17, Change, the `ai-log record` step ("counts only, skipping the introspection it prints") vs Task 15b's skill
step ("do what it prints, without asking"): `record` prints an instruction to write and pipe an introspection, and one
skill says to obey it while the other says to ignore it. It is not decided whether "counts only" means a flag on
`record` (an interface change Task 15 would need) or prose in the session-end paragraph. Question the executor would
ask: "Does `record` get an option that suppresses the introspection prompt, or does the session end rely on Claude
ignoring printed instructions?" Scenario: A session end runs `record` under the 15b habit of doing what it prints.
Claude writes and pushes an introspection for every session, and 15d's cut-candidate counts are inflated by mid-plan
introspections.
Refuted: Dropped by the verifier. The plan does decide this. The session-end paragraph in implementing-plans says
outright "counts only, skipping the introspection it prints". 15b's "do what it prints" step sits in
reviewing-in-rounds Completion, which runs only at the end of a plan, not at a session end. The two instructions live
in different skills and fire in different situations. Whether to add a flag is out of scope as a command-flag choice.

### R10-26 · nit · decisions

Task 17, Change, When ("the run's part-way final report" vs "A stop to ask is not one"): Some planned stops are both:
the run stopping at Task 13 to show the issue draft ("Ask me then"), or a usage-limit wrap-up that prints `ai
implement`. The plan does not say which triggers apply when a stop to ask is also the run's part-way final report.
Question the executor would ask: "If the run stops to ask and prints the resume command, is that a session end?"
Scenario: At the Task 13 stop, one reading commits WIP and runs `record` before the user answers, and the other saves
nothing. If the user then closes the terminal, the work is either pushed or left local, depending on which reading the
executor wrote into the skill.
Refuted: Downgraded from minor by the verifier. Downgraded. implementing-plans prints `ai implement <plan-file>` only
in the final report of a run that stopped part-way, and Task 17 defines the trigger as "the one that prints `ai implement <plan-file>`".
A stop to ask, such as the Task 13 draft, does not print that command, and a wrap-up that
does is a session end. At most a clarifying word is missing.

### R10-27 · minor · decisions

Task 15, Files (outside this repo) / § Approvals 2026-11-05 "on every machine": The yes covers every machine, but
nothing decides who creates `$HOME/.ai-framework-log` on a new machine. The plan does not say whether a `bin/dotfiles`
init step clones it or the user does it by hand. Question the executor would ask: "Should the Claude init script clone
the log repo, or is a manual clone the documented setup?" Scenario: On a fresh WSL machine every `record` and `note`
exits 2 with the clone hint. The 15b step reports a failure after every plan and no data is collected there, so the
'every machine' requirement silently fails.

### R10-28 · minor · decisions

Task 13, 2026-11-05 deviation and issue paragraph: The plan says "a GitHub issue" but never names the repo. On
`andrelin/dotfiles` it is public, and the carried items include Task M's sketch (a private repo's confidentiality,
mirror folder and push soft-deny) and 15c's customer-redaction notes. Question the executor would ask: "Is the issue
filed on the public `andrelin/dotfiles`, and if so, is Task M's sketch reduced to a generic line?" The user's "Ask me
then" covers the filing, but not which sketches are fit to publish. Scenario: The draft copies Task M step 1 verbatim
into a public issue and describes a private, customer-bearing repo's setup in world-readable text, against the
personal-public bar.
Refuted: Dropped by the verifier. The plan file itself is tracked in the public `andrelin/dotfiles` and already
contains Task M's sketch and 15c's notes in generic words, with no names. An issue repeating them reveals nothing new.
The 2026-11-09 "Ask me then" also makes the run stop and show the user the draft before anything is filed.

### R10-29 · nit · decisions

Task 15, Tests, Counts ("at company level the plan's and branch's words redacted from the introspection (15b)"): A
Task 15b behaviour (`note`'s redaction) is listed among Task 15's tests, though Task 15 has no `note` and no
introspection. Scenario: A Task 15 implementer must either build part of 15b early or leave a listed test unwritten,
and the task review flags whichever choice they make.

### R10-30 · major · consistency

Task 17, Files / The skill; claude/docs/work-contexts.md:85-86; claude/docs/skill-precedence.md:45;
claude/skills/implementing-plans/SKILL.md:64 and :103: Task 17 makes `implementing-plans` commit and push without
asking at a session end, and stage the plan file. Its Files list only the skill and the reference doc, and its
in-place edits name only the opening line and the red flag. Several statements that say the opposite are left
standing: work-contexts.md "At every level, the workflow skills never commit on their own. `implementing-plans`
checkpoints in the index and never commits"; skill-precedence.md "the commit waits for the user"; the skill's own
"since nothing is committed and `BASE..HEAD` is empty" (line 64) and "The plan file is never staged" (line 103). Task
15b's later work-contexts.md edit covers only `ai-log`, not the session-end commit. Scenario: After Task 17 is built,
a session ending at personal level reads the skill paragraph saying commit, stage the plan and push. The same skill
and work-contexts.md (which it loads for policy) say it never commits and never stages the plan. The session either
stops to ask or skips the save. This also breaks the global constraint "Docs ship with the change": claude/docs/* must
be updated in the task that changes behaviour.
Fixed: Task 17's Files gain `work-contexts.md` and `skill-precedence.md`, and its in-place edits the review-input
line, each naming the session-end commit as the one exception.

### R10-31 · minor · consistency

Task 17, Change: When / What a resume sees: The session-end save commits only the index (checkpointed tasks) plus the
plan and its review files. That leaves out the final code review stage, which runs inside `implementing-plans` (§
Finish with the final review) and can span sessions: its fixes stay unstaged leftovers until reviewing-in-rounds
Completion step 1. Its findings file (tracked here) records rounds as fixed. The plan assumes all work in progress
lives in the index, and nothing checks that assumption. Scenario: The user asks to wrap up after code-review round 4.
The session end commits the findings file showing R4 fixes as `Fixed:` but not the unstaged fix edits, and pushes. On
another machine `git pull` resumes round 5 against a tree without those fixes. The log says they are fixed, so nobody
re-applies them.
Refuted: Downgraded from major by the verifier. Partly stands, downgraded. The gap is real: reviewing-in-rounds
Completion step 1 is the only place that stages review fixes, and the final code review runs inside implementing-plans
and can span sessions (this plan's code review ran 12 rounds). A wrap-up request mid-review would push a findings file
marked `Fixed:` without the fixes. On the same machine nothing is lost, because the fixes stay unstaged. The failure
needs both a mid-review wrap-up and a resume on another machine. It is also cheap to settle while implementing, with
one sentence that either stages fix leftovers at a session end during the review or leaves the findings file out. It
is neither a load-bearing assumption nor costly to reverse.

### R10-32 · minor · consistency

Task 15, Tests (Counts bullet), and Task 15b, Tests (Redaction): Task 15's test list holds "at company level the
plan's and branch's words redacted from the introspection (15b)". The redaction and `note` are only built in Task 15b,
and 15b's own Redaction test does not list the company-level plan, heading or branch words. Scenario: The Task 15
implementer cannot write this test because `note` and the redaction don't exist yet. The Task 15b implementer follows
15b's Tests and never adds it. So the company-level word redaction (R7-3, R7-40) ships untested.

### R10-33 · minor · consistency

Task 17, The skill; § Approvals 2026-11-05 ("its skill line is where that yes outlives this plan"): Approvals says
Task 17's skill line is where the user's standing yes to commit and push at session end outlives the plan. Task 17's
skill paragraph lists only trigger, level, steps and customer level: no mention of the standing yes. The landing rule
("work that has such commits lands by a squash-merged PR") also goes into no skill, only into Task 13's
staged-workflow.md. Scenario: After Task 13 deletes the plan, a future personal-level run hits the session-end
paragraph. Under the global "An approval covers what it names" it asks before committing and pushing. Or it finishes
and fast-forwards `main` with the `Work in progress:` commits, which the user's 2026-11-09 ruling forbids.

### R10-34 · nit · consistency

§ Approvals 2026-11-05 ("From Task 15b on…"), Approvals 2026-11-09 ("session ends before Task 17 is built follow Task
17's steps by hand"), Task 15 Tests ("No real record runs here: the first is Task 15b's end to end"), Order (16, 15,
17, 15b): The build order puts 17 before 15b, and the by-hand session-end rule applies once Task 15 exists. So real
`ai-log record` runs, each committing and pushing to the log repo, happen before 15b. That contradicts Task 15's "the
first is Task 15b's end to end" and the log-repo yes scoped "From Task 15b on, after every plan". Scenario: A session
ends after Task 15 is built and before 15b. Task 17's steps (by hand or built) run a real `record` that pushes an
entry, while the plan says no real record runs yet and the push approval starts at 15b. The executor has to choose
which line to break.
Refuted: Downgraded from minor by the verifier. Downgraded. The approval conflict is refuted: Approvals line 85
(2026-11-05) already approves "push to it as Task 15 builds". Task 17's session-end `ai-log record` also rests on the
user's own request, "We should commit and ai log at the end of sessions too", which Task 17 cites as its standing yes.
What is left is a stale factual line in Task 15's Tests, "the first is Task 15b's end to end", which the Order (16,
15, 17, 15b) makes untrue. That is a wording fix and leaves the executor no real dilemma.

### R10-35 · minor · consistency

Task 15b, Files (claude/docs/work-contexts.md addition): The added text says `ai-log` commits and pushes "after a
plan's commit" by `reviewing-in-rounds`. Task 17, built before 15b, also runs `ai-log record` (commit and push to the
log repo) at every session end. The doc describing what leaves the machine and on which standing yes omits it.
Scenario: A reader checking work-contexts.md for what is pushed without asking is told it happens once per plan after
the final commit. In fact every session end pushes an entry, and also pushes the work branch.

### R10-36 · minor · consistency

Task 13, the 2026-11-03 deviation (list of open items for the issue): The enumerated open items do not match the rest
of the plan. They omit what Handover item 6 lists ("the audit's recorded Mediums and Lows, R12-4"), the pending reruns
behind the 🚧 PARTIAL rows of Tasks 5, 8 and 9 (Handover items 1-2), Task 3b's real-settings merge, closing
planechaser#73, and the unfiled learnings. They still include "Task 7's conflict sent to the user", which the status
table and Handover item 5 record as decided and reworded 2026-11-05. Scenario: Task 13 files the issue from its own
list and `git rm`s the plan. The PARTIAL tasks' unrun tests and R12-4 survive only in squashed-away history, and the
issue carries a resolved item.

### R10-37 · minor · consistency

Task 16, Files: Task 16 makes `bin/check-md-limits` stop counting front matter, and updates
claude/docs/markdown-limits.md. The always-loaded rule claude/rules/markdown-limits.md:26 still says "every line of an
agent-loaded file … counts, because it is loaded whole", and it is not in the Files list. Scenario: After Task 16, the
rule Claude loads when editing Markdown contradicts the checker. A session trims front matter to meet an aim the
checker no longer applies, or reports the checker as wrong.

### R10-38 · minor · consistency

Task 17, Line budget: The budget is the 4 front-matter lines Task 16 frees, plus the single named fallback cut (about
2 lines). That has to hold a new paragraph (trigger, level, add/commit/allow-empty/ref delete/push/record steps,
customer level) and the in-place edits. Finding 1's in-place edits (lines 64 and 103) are not in the budget, and if
the edits don't fit there is no path after the one fallback. Scenario: The executor writes the paragraph, finds the
skill at 123 against the 120 pin, makes the one allowed cut, is still over, and has to stop: the pin is "never raised"
and no other cut is sanctioned.

### R10-39 · nit · consistency

Task 16, Interfaces: It says "none", but Task 17 (and the Order line "after 16, which frees the 4 lines its skill edit
fits in") consumes Task 16's checker change. Scenario: An implementer reading only Task 16 sees no consumer and might
reorder or narrow the front-matter exemption (for example, to rules only), which would break Task 17's budget.

### R10-40 · nit · consistency

§ Follow-ups, not tasks of this run (first line): "neither can be built before real entries exist" refers to two
items, but the section holds three (Revisit, 15c, 15d). Scenario: A reader isn't sure whether the Revisit is also
carried into Task 13's issue. Order and Task 13 say it is.

### R10-41 · nit · consistency

Task 17, Change: At personal and company level (`plan-<branch>-review-*`): claude/docs/review-log.md names findings
files `plan-<stem>-review-findings-<kind>.md`. Task 17 uses `<branch>`. They coincide only because implementing-plans
step 4 derives the branch from the stem. Scenario: If the branch was created by hand or renamed, the pathspec misses
the findings file, and the review state isn't pushed for another machine.
Refuted: Dropped by the verifier. Refuted by the repo. implementing-plans SKILL.md step 4 names the branch as "the
plan file's name minus `plan-` and `.md`", and resume step 1 requires the branch "named as in 4", stopping otherwise.
Within implementing-plans, where Task 17's paragraph lives, `<branch>` always equals `<stem>`. A hand-made or renamed
branch makes resume stop before any session end, so the pathspec can't miss the findings file.

### R10-42 · nit · consistency

§ Approvals, 2026-11-05 block, bullet "This run works on branch `ai-framework`… `main` fast-forwarded, pushed and CI
watched": The 2026-11-09 block supersedes this bullet (squash-merged PR instead of fast-forward), but the bullet isn't
marked as superseded where it stands. Scenario: A resuming executor that reads the Approvals top-down acts on the
fast-forward yes before reaching the later block.

### R10-43 · minor · work context

Task 17, Files and Change (the standing commit and push); claude/docs/work-contexts.md § An approval covers one
action, not a policy: Task 17 makes `implementing-plans` commit and push at every personal and company session end on
a standing yes, but its Files list leaves out `claude/docs/work-contexts.md`. That doc says "At every level, the
workflow skills never commit on their own. `implementing-plans` checkpoints in the index and never commits" and "Ask
again, every time". Task 15b adds an exception to that section for `ai-log` only. The global `CLAUDE.md` § Approvals
("An approval covers what it names") gets no pointer either. Scenario: After Task 13 deletes the plan, a future
session at company level reaches a session end. The skill says to commit and push without asking. The work-contexts
doc, which the global CLAUDE.md points to for how a level applies, says the skill never commits and every write needs
a fresh yes. The session either stops to ask, which defeats the rule, or commits against the documented policy. The
user's yes is then recorded only in a skill line that contradicts the reference doc. This also breaks the plan's own
constraint "Docs ship with the change". Fix: add the session-end commit and push to work-contexts.md in Task 17, next
to 15b's `ai-log` exception.
Refuted: Downgraded from major by the verifier. Stands, but downgraded. claude/docs/work-contexts.md:85-86 does say
"At every level, the workflow skills never commit on their own. `implementing-plans` checkpoints in the index and
never commits". Task 17's Files list names only the skill and implementing-plans-reference.md. The plan's file map
(line 566) gives 15b the only work-contexts.md edit in that section, and Task 13 folds in only the split-further
findings. So once Task 17 lands, the reference doc contradicts the skill. Not major: nothing the approach rests on is
unverified and nothing is costly to reverse. The fix is one line in that section beside 15b's ai-log exception, which
is cheap to add while implementing. No forbidden write follows either, because commits are allowed at personal and
company level.

### R10-44 · minor · work context

Task 17, Tests: Resume across a session-end commit: The test's scratch repo has a local bare repo as `origin`. The
session-end steps first run `ai-log level`, whose gate prints `customer` for any origin other than
`github.com/andrelin/…` or `github.com/uptimeconsulting/…` or an `allow` line. So the steps take the customer branch:
no commit, no push. Checked in a mktemp repo: with a local-path origin, `work-context.sh level` prints `company`, so
`ai-log level`'s allowlist rejects it. With `url.insteadOf`, `git remote get-url origin` returns the rewritten local
path too. Only an origin URL of `git@github.com:andrelin/x.git` with `remote.origin.pushurl` pointing at the bare repo
resolves `personal` and still pushes locally. The plan names none of this. Scenario: The executor builds the scratch
repo as the test says and runs the session-end steps "as the skill words them". `ai-log level` prints customer,
nothing is committed, and the assertions fail: "A second session end … still makes a commit" and "the leftover …
absent from the clone" after a push. Or the executor bypasses the level check, and then the personal-level path is
never exercised through its real gate. Fix: specify a personal origin URL with a local `pushurl`, or an `AI_LOG_DIR`
`allow` line for the scratch origin.
Refuted: Downgraded from major by the verifier. Real but downgraded. Task 15's gate (plan lines ~3612-3617) prints
customer for any origin outside github.com/andrelin/… or github.com/uptimeconsulting/… unless an `allow` line names
it. A scratch repo whose origin is a local bare path therefore takes the customer branch, and the personal-level test
as worded commits nothing. But this is test setup: the executor sees the failure on the first run and fixes it by
giving origin a github.com/andrelin URL with a local pushurl, or by adding an allow line. That is cheap to settle
while implementing and checkable in the diff, close to the out-of-scope line on exact test cases. It does not decide
what gets built.

### R10-45 · minor · work context

Task 17, Interfaces / Change: The level: Task 17 gates every commit and push on `ai-log level`, but Task 15 doesn't
say what `level` does when `AI_LOG_DIR` is missing or isn't a git clone. Its `allow` file lives in that clone.
`record` exits 2 in that case; `level` is only specified as "exit 0". Scenario: On a second machine without
`~/.ai-framework-log` cloned, a session end in a company repo on a company Forgejo runs `ai-log level`. It may exit 2
with nothing on stdout, or print `customer` because the `allow` file is missing. Task 17 doesn't say whether that
means skip the save (safe) or carry on. An executor who reads a non-`customer` result as permission to commit could
push from a repo the gate meant to exclude. State that `level` prints `customer` (or that Task 17 treats any failure
as customer) when the clone or `allow` file is unavailable.
Refuted: Dropped by the verifier. Out of scope as error handling, and the scenario doesn't hold. A missing `allow`
file only makes the gate stricter: a company Forgejo origin falls back to `customer` and nothing is committed, which
is the safe direction. A `level` that exits non-zero with empty stdout prints neither `personal` nor `company`, and
Task 17 runs its commit and push only "At personal and company level". So no plausible reading pushes from an excluded
repo. What a failed `level` should report is an error-handling choice for the executor, checkable in the diff.

### R10-46 · minor · work context

Task 17, Change: At personal and company level (`git add -u --` the plan file); implementing-plans SKILL.md:104: The
skill states "The plan file is never staged." Task 17's session end stages the plan file and its review files, but the
edits Task 17 lists in place cover only the opening line and the "A checkpoint commit is safer" red flag. The
never-staged rule is left unedited, so the skill contradicts itself. Scenario: A future run reaches a session end on a
personal repo with a tracked plan. One line of the skill says never stage the plan, another says `git add -u --` it.
An executor who follows line 104 commits without the plan's status updates. On another machine, `git pull` then brings
code whose plan table still shows the tasks as pending, and resume step 1 redoes them.

### R10-47 · nit · work context

Task 15, Tests: Real data, last, by the session ("Record warnings here"): Warnings from the real dry run are written
into this tracked plan in a personal public repo. Task 15 doesn't limit warning text to non-identifying content: a
warning about an unparseable findings heading, or about a line that isn't JSON, could quote a heading or file path.
The Task 15b session-end commit then pushes the plan to the public branch. Scenario: A warning quotes an unparseable
review-log heading or a transcript path under `~/.claude/projects/<dir>`. That path encodes another repo's cwd,
possibly a customer folder. It is pasted into the plan's Task 15 notes, committed at the session end and pushed to the
public `andrelin/dotfiles`. Say to record warnings by kind and count only.

## Round 11

### R11-1 · minor · grounding

Task 17, Change: "The level" (and Task 15 Interfaces, `ai-log level`): The session-end commit and push are gated on
`ai-log level`, which is the log repo's telemetry allowlist (`github.com/andrelin/…`, `github.com/uptimeconsulting/…`,
or a `<host>/<owner>` line in the private log clone's `allow` file), not on `work-context.sh level`. That makes saving
your work depend on a telemetry repo's config and on that clone being present on the machine. The plan never says what
`ai-log level` does when `AI_LOG_DIR` is not a clone: Task 15 only defines exit 2 for `record` in that case. Every
other commit the framework makes, including Completion's step 4 commits at company level, uses `work-context.sh
level`, so only the session-end save gets the stricter gate. The simpler approach is to gate the commit and push on
`work-context.sh level`, as Completion does, and keep `ai-log level` for the `ai-log record` call only. Scenario:
First case: a company plan on the company Forgejo, the setting the global CLAUDE.md's 'Forgejo work' rule describes,
on a machine whose log clone has no `allow` line for that host. `ai-log level` prints `customer`, so at session end
nothing is committed or pushed. That breaks the user's standing rule ("Commit and push the branch", for every future
run at personal and company level), and another machine can't resume. Second case: a fresh machine without
`~/.ai-framework-log`. `ai-log level` has no defined output there, so the save either errors or silently skips.
Refuted: Downgraded from major by the verifier. Downgraded. The stricter gate was chosen on purpose: Task 15
Interfaces and Task 17's 'The level' both cite plan review R9-50, and the reason is stated. An unlisted customer repo
resolves as company under `work-context.sh level`, so gating on it would commit and push a customer's history. The
company-Forgejo case is also covered by design: Task 15's 'Customer level, deferred' names the clone's `allow` file
"for a company Forgejo, say". Adding the host there is the documented fix, so the first scenario is the intended
fail-safe, not wrong behaviour. One part of the finding is real: the plan never says what `ai-log level` prints or
returns when `AI_LOG_DIR` is not a clone and so has no `allow` file. Exit 2 is defined only for `record`. That gap is
cheap to close while implementing (fail safe to `customer` and say so in the report), and Task 17's 'A failure goes in
the report' already covers surfacing it. So it is minor, not major.

### R11-2 · minor · grounding

Task 17, Change: "Line budget" and "The skill": I measured the budget, and it is unlikely to hold the content.
`claude/skills/implementing-plans/SKILL.md` counts exactly 120, its pin in `.md-baseline`, and the 4 lines Task 16
frees are its front matter. The new paragraph has to carry the trigger and its exclusion, the level gate, five steps
(`add -u`, the `--allow-empty` commit, deleting refs, `push -u`, `record` without the introspection), the failure
report, the customer-level listing and the squash-only landing rule. At one sentence per line and 150 characters that
is about 7 to 9 lines. Three in-place edits come on top: line 9 (109 characters), line 64 (111 characters) and the
red-flag row at line 144 (106 characters), and each is likely to wrap once the exception is added. The fallback cut
(resume step 1's last sentence, lines 37 and 38) frees at most about 1.5 lines. Moving the procedure to
`implementing-plans-reference.md` doesn't work either: that file loads only before the approvals step, before a
dispatch or before a by-hand task, and a session end is none of those. The simpler design is a one-line pointer in the
skill to a doc that holds the procedure, with its own read trigger at session end. Scenario: The executor writes the
paragraph and edits, `bin/check-md-limits` reports more than 120 against a pin that is "never raised", and the
fallback cut doesn't close the gap. The run stops mid-task for a ruling the plan should have made.
Refuted: Downgraded from major by the verifier. Downgraded. I confirmed the numbers: `bin/check-md-limits` counts 120,
which excludes blank lines and headings, `.md-baseline` pins it at 120, and the front matter is 4 lines. But the
checker allows 150 characters per line, while the skill's counted lines average about 100 characters, and line 9 is
109 and line 64 about 111. Rewrapping § *Finish with the final review* and the edited bullets toward 150 characters
recovers lines on top of the 4 freed ones and the named fallback cut. A dense draft of the paragraph (trigger and
exclusion, level, the five steps, failure, customer listing, landing rule) comes to about 6 lines at 150 characters.
The red-flag row is a table row, which is exempt from the length check, so it costs no extra line. The plan says the
edits must fit and names a fallback, and `bin/check-md-limits` catches an overrun mechanically, so the shortfall is
cheap to settle in implementation through wording and rewrapping. It is not an approach-level assumption.

### R11-3 · minor · grounding

Task 17, Change: "When": The trigger counts the run's part-way final report, but excludes "a stop to ask". In
`implementing-plans`, almost every part-way stop is a stop to ask: a deviation, a failing baseline, a resume mismatch,
leftovers. So it is unclear which reports trigger the save. Scenario: A run stops on a task deviation and prints `ai implement <plan-file>`,
and the user closes the terminal overnight. One executor reads this as a stop to ask and saves
nothing. Another reads it as the part-way final report and commits and pushes. The two readings give different
behaviour on the very case the save exists for.

### R11-4 · minor · grounding

Task 15b, Files: `claude/docs/work-contexts.md` addition; Task 17, Files: Task 15b's text for work-contexts.md says
that after a plan's commit, `reviewing-in-rounds` runs `ai-log`, which commits and pushes to the private log. Task 17
adds a second writer to that log: `implementing-plans`, at every session end. Task 17 edits a different sentence of
work-contexts.md and never updates the 'what leaves the machine' statement, so the durable doc understates when data
leaves the machine. Scenario: A reader of work-contexts.md concludes that log writes happen only after a plan's final
commit. In fact every wrap-up at personal and company level also pushes an entry.

### R11-5 · nit · grounding

Task 15b, "Why not also `implementing-plans`": This section justifies leaving `implementing-plans` out with "it never
commits". Task 17 makes it commit, and run `ai-log record`, at session end, so the stated reason is stale. The real
reason is that the per-plan introspection belongs after the final commit. Scenario: A later reader of the folded docs
sees "implementing-plans never commits" next to the session-end commit and can't tell which is true.

### R11-6 · minor · scope and slicing

Task 16 (front matter leaves the line count) and Task 17 § Line budget: Task 17's budget assumes Task 16 leaves
`implementing-plans/SKILL.md` 4 lines under its unchanged 120 pin, but the plan never says to keep the pin at 120
between the two tasks. The checker works against that. Once front matter stops counting, `bin/check-md-limits` prints
`NOTE: ... under its pinned 120 — re-pin it: bin/check-md-limits --update-baseline`. CI's markdown job
(`.github/workflows/markdown.yml`, step '.md-baseline matches what the tool would write') regenerates the baseline and
fails when the result differs, so a stale 120 pin fails CI. Scenario: An executor builds Task 16 and follows the
checker's NOTE, or keeps CI green on a session-end push between Tasks 16 and 17 (the order is 16, 15, 17). Either way
they re-pin to 116. Task 17 then has zero free lines, because 'the pin is never raised'. It is pushed onto the cut
fallback, or the executor raises the pin against the rule. If they leave the pin at 120 instead, every session-end
push between Tasks 16 and 17 has a red markdown leg. Task 16 should say to leave the pin alone until Task 17 refills
it, and accept or avoid the stale-pin failure on intermediate pushes. Alternatively, build 16 and 17's skill edit
together.
Refuted: Downgraded from major by the verifier. The mechanism is confirmed. `bin/check-md-limits` prints 'NOTE: ...
under its pinned N — re-pin it'. With no files, `--update-baseline` tightens pins to their current sizes. The CI step
`.md-baseline matches what the tool would write` regenerates the baseline and fails on any diff, and the markdown
workflow runs on every push touching `.md`, which a session-end push does because it carries the plan file. So a pin
left at 120 between Task 16 and Task 17 turns that leg red, and re-pinning to 116 leaves Task 17 no budget. Downgraded
from major because the plan already has a fallback: Task 17 § Line budget names the cut (resume step 1's last
sentence, moved to the reference doc). The worst outcome is that fallback being taken, or a red leg on an intermediate
branch push. Neither builds the wrong thing or is costly to reverse, and one sentence in Task 16 settles it (hold the
pin until 17, or build 16 and 17's skill edit together).

### R11-7 · minor · scope and slicing

Task 15 § Tests, Counts bullet: Task 15's test list includes 'at company level the plan's and branch's words redacted
from the introspection (15b)'. Task 15 has no introspection, no `note` and no redaction. That behaviour is built in
Task 15b, so Task 15 cannot pass this test. Scenario: The Task 15 implementer either fails the task review on a test
it cannot write, or builds part of 15b's redaction early to satisfy it. That widens a task that was already re-sliced
for being too big to review to a finish. Move the test to Task 15b's Redaction tests.

### R11-8 · minor · scope and slicing

Task 15 § Tests, Real data ("No real record runs here: the first is Task 15b's end to end"), with Order (16, 15, 17,
15b) and § Approvals ("session ends before Task 17 is built follow Task 17's steps by hand"): The build order puts
Task 17 before Task 15b, and Task 17's session end runs a real counts-only `ai-log record`. Any session that ends
after Task 15 is built, whether Task 17's steps run by hand or as the skill, therefore writes and pushes real entries
before 15b's end-to-end run. This contradicts 'the first is Task 15b's end to end'. The Revisit's 'Task 15b's first
real entry' is also not the first real entry. A session that ends before Task 15 exists cannot run the by-hand step's
`ai-log record` at all, and the plan does not say to skip it. Scenario: The session ends after Task 15 is built. The
executor reads the Task 15 line and either skips the session-end `record` that Task 17's steps require, or runs it and
pushes an entry the plan said would not exist yet. A session that ends before Task 15 hits a missing command in the
by-hand steps. State which real entries come first, and that the by-hand session end skips `record` until Task 15 is
built.

### R11-9 · minor · scope and slicing

Task 15b § Change (record prints the introspection instruction) and Task 17 § Change ("skipping the introspection it
prints"): After Task 15b, `record` always prints 'write a short introspection ... Pipe it to ai-log note `<id>`', and
the `reviewing-in-rounds` step says 'do what it prints, without asking'. Task 17's session end calls the same command
and relies on prose telling the model to ignore half of what it prints. No test covers the session-end path once 15b
changes the output. Scenario: A session-end save after Task 15b obeys the printed instruction. It writes and pushes a
per-session introspection `.md` that the user ruled should come once per plan, and repeated session ends each add one.
A `--counts-only` flag or a separate summary mode, and a test that the session-end path prints no introspection
request, would make the boundary mechanical. Both are cheap to decide while implementing 15b.
Refuted: Dropped by the verifier. Task 17 § Change states the boundary outright: 'then `ai-log record <plan-file>`,
counts only, skipping the introspection it prints, which comes once per plan after its final commit (Task 15b)'. That
sentence goes into the skill paragraph. Task 15b's 'do what it prints' is a step in `reviewing-in-rounds` § Completion
of a code review, not in the session-end path. What remains, a `--counts-only` flag and a test that no introspection
request is printed, are command flags and exact test cases, which the out-of-scope line leaves to the code.

### R11-10 · minor · scope and slicing

Task 15 § Tests (Real data, last) and Follow-up Revisit: The riskiest assumptions of the Task 15/15b/17 stack are
checked against real transcripts only at the end of Task 15, after the whole script is built. These are: that real
transcripts resolve lens attribution from the `Lens:` line, that resumed or forked files dedupe by `message.id` and
`uuid`, and that the price table matches `cost-state`. The 2026-11-05 inspection recorded field names only. Scenario:
The final dry run shows that real Workflow prompts carry no usable `Lens:` line, or that forked files repeat records
under new ids. The window chaining, per-lens tokens and keyed review counting are then reworked after all their tests
are written. Running a thin dry-run spike over this session's transcripts as Task 15's first step would surface this
before the rest is built on it.
Refuted: Dropped by the verifier. The plan does not rest on unverified shapes in the way described. Lens attribution
reads the Workflow `.meta.json` `description` first, and the `Lens:` fixture 'copies a real Workflow prompt's shape,
the lens mid-line and indented (plan review R10-9)'. The copying of resumed or forked records with ids kept is stated
as observed (R7-1). A price-table mismatch is 'fixed before going on', which is a table edit, not a rework. When to
run a dry run within Task 15 is the executor's choice and checkable in the work, so the out-of-scope line covers it.
The scenario of 'no usable `Lens:` line' is contradicted by the plan's own source for the fixture.

### R11-11 · minor · scope and slicing

Task 17 § When / § The skill: The user asked to 'commit and ai log at the end of sessions'. Task 17 hooks the save
only into `implementing-plans` § Finish. The plan never says that sessions outside an `implementing-plans` run are out
of scope, such as a standalone `ai review` or `writing-plans` stage, or an ad-hoc session on a plan branch. Scenario:
An executor or reviewer reads 'end of sessions' literally. They add the save to `reviewing-in-rounds` or
`writing-plans` too, which are skill changes the user has not approved. Or they flag Task 17 as incomplete. One line
naming the excluded sessions settles it.

### R11-12 · nit · scope and slicing

Task 17 § Change (`--allow-empty`): The empty commit exists only so that Task 15's id, which is keyed on the commit,
differs per session end. That is a log-id convenience paid for with no-content commits on the pushed branch. The
squash removes them in the end, but on the branch it is a commit nothing but the log asks for. Scenario: A session end
with nothing new checkpointed pushes an empty 'Work in progress: Tasks ' commit, possibly with an empty task list. An
alternative is to skip the commit and push when the index equals `HEAD^{tree}` and still record against the existing
`HEAD`. That needs Task 15's same-id replace rule weighed, so the plan should state which way it goes and why.
Refuted: Dropped by the verifier. The plan already states which way it goes and why. Task 17 § Change says to commit
'with `--allow-empty`, so every session end has its own `HEAD` and so its own log entry (plan review R9-4, R9-36)'.
Task 15 § Change ties the non-overlapping window to that ('Task 17's session end commits first, so each session end
has its own `HEAD`, id and window'). Task 17 § Tests asserts that a second session end with nothing new still makes a
commit. The squash-merged PR removes the empty commits, so nothing reaches `main`. What the finding asks for is
already in the plan.

### R11-13 · minor · decisions

§ Approvals, 2026-11-09 block ("Claude opens the PR ... and squash-merges it"); Task 13 deviation; Task 17 *Landing*:
Nothing says what the squash commit on `main` holds: its subject, and its body (the PR description from
`writing-mr-descriptions`, or GitHub's default). The executor would ask: "When I squash-merge, what goes in the commit
message?" I checked `andrelin/dotfiles` with `gh api`: `squash_merge_commit_message` is `COMMIT_MESSAGES`, so a bare
`gh pr merge --squash` writes every branch commit message into the body. That includes `d88b6fa`'s, each `Work in
progress: Tasks …` and the per-task Completion commits. Scenario: The executor runs `gh pr merge --squash` without
`--subject`/`--body`. The commit pushed to public `main`, which can't be rewritten, lists every work-in-progress and
checkpoint message. That defeats the reason given for squashing ("readable history"). The same gap carries into the
landing rule Task 17 writes into `implementing-plans` for every future run.
Refuted: Downgraded from major by the verifier. Downgraded. The gap is real: the plan says the PR description comes
from `writing-mr-descriptions` but not what the squash commit's subject and body are. It is a choice of `gh pr merge`
flags, though, settled in one line at merge time. The worst case is a long body of commit subjects on `main`. Those
messages are already public on the pushed branch and hold nothing sensitive, so it hurts readability only. It builds
nothing wrong and is cheap to settle while implementing, so it is not major.

### R11-14 · minor · decisions

Task 15 *Customer level, deferred* (the private clone's `allow` file) and *Files* (outside this repo); consumed by
Task 17 *The level*: The gate records only `github.com/andrelin/…`, `github.com/uptimeconsulting/…` and the
`<host>/<owner>` lines in the clone's `allow` file. But *Files* never creates `allow`, and no task says what goes in
it. The global `CLAUDE.md` runs company work on Forgejo ("every task has a Forgejo issue"), so a company Forgejo
origin resolves as customer under this gate. The open question: "Which company hosts and owners go into `allow` when
the log repo is created, and who adds them on each machine's clone?" The hostname is private, so only the user can
answer. Scenario: The repo is created with only `entries/` and `README.md`. On a company repo hosted on the company's
Forgejo, `ai-log level` prints `customer`. Task 17's session end then commits and pushes nothing, and `record` prints
"customer level is deferred" for work that is company level. Most company work is never logged or saved across
machines, and the message points the wrong way, so nobody notices.
Refuted: Downgraded from major by the verifier. Downgraded. It is true that nothing creates or documents the `allow`
file (Files lists only `entries/` and `README.md`). But the gate is opt-in on purpose ("for a company Forgejo, say"),
and an absent file fails safe: nothing is recorded and nothing is pushed. Fixing it means adding one line to `allow`
and, if wanted, a sentence in the log repo's README saying how to add one. Nothing has to be rebuilt. The hostname is
the user's to supply whenever they first log Forgejo work, so this is cheap to settle and not an assumption the
approach rests on. The misleading "customer level is deferred" message is part of the same small fix.

### R11-15 · major · decisions

Task 17 *At personal and company level* (`git add -u --` the plan file ... "where tracked") and *Accepted gap*: `git
add -u` never adds an untracked file. At personal level `implementing-plans` doesn't add the plan to `info/exclude`,
but it also never stages or commits it ("The plan file is never staged"). So a newly written personal plan stays
untracked, and the session-end push leaves it on this machine. *Accepted gap* names only company level. The undecided
question is the user's: "At personal level, should the session-end commit add an untracked plan (and its review files)
so another machine can resume, or is that gap accepted too?" On a personal public repo, adding it publishes the plan
on a pushed branch. Scenario: A personal plan is started on machine A and the session ends. The work-in-progress
commit is pushed without the plan. On machine B, `git switch <branch> && git pull` then `ai implement plan-x.md` stops
because there's no plan file. This breaks the cross-machine resume that the user's "Commit and push the branch" was
meant to give, at a level the plan never lists as a gap.
Fixed: the user ruled "Commit it on the branch": at personal level the save adds an untracked plan and its review
files; company level unchanged.

### R11-16 · minor · decisions

Task 15 *The entry* `framework.dotfiles_commit` and *Framework*; Follow-up 15d ("grouped by framework commit"); the
2026-11-09 squash-merge landing: `dotfiles_commit` is the HEAD of `bin/ai-log`'s own tree when it runs. Since
2026-11-09, framework work lands by a squash-merged PR, so any entry recorded while the dotfiles checkout is on a
framework branch stores a sha that never reaches `main` (this run's 15b entry and every session-end entry included).
The stored format was designed before the squash decision and wasn't re-checked. Entries are pushed and permanent, so
this is costly to fix later. The open question: "Should an entry also record the merge-base with the default branch,
or should a branch checkout be flagged, so 15d can still place it?" Scenario: After the PR is squash-merged and the
branch deleted, Follow-up 15d groups entries by `dotfiles_commit`. Every entry from a framework-development run points
to an unreachable sha, so the runs that changed the framework can't be tied to any framework version, which is the
comparison 15d exists to make.
Refuted: Downgraded from major by the verifier. Downgraded. The sha is not lost after the squash. GitHub keeps
`refs/pull/<n>/head` for every PR after the branch is deleted, so the commit stays fetchable and maps to its PR and
squash commit (`gh api repos/.../commits/<sha>/pulls`). The local clone may also still hold it. The issue only affects
entries recorded while the dotfiles checkout is on a framework branch, not runs in other repos with dotfiles on
`main`. 15d is a Sketch that is detailed later, and it can resolve these shas then. Nothing is costly to reverse,
though recording the merge-base would make 15d simpler.

### R11-17 · minor · decisions

Task 15b *The mechanical redaction*, second bullet ("the work repo's remotes' hosts, owners and names, and its
folder's name and those above it"): Only the third bullet is scoped ("at company level"). The repo-name, owner and
folder bullet has no level, so it can be read as applying at personal level too. The two readings build different
redaction rules and different tests. Executor's question: "At personal level, are the repo's own name, owner and
folder redacted from the introspection?" Scenario: At personal level in this repo, every "dotfiles" and "andrelin" in
the introspection becomes `[repo]`/`[customer]`-style placeholders ("[repo] skills cost most"). Introspections become
harder to read for no privacy gain. Under the other reading they stay; a reviewer can't tell which one was meant.
Refuted: Dropped by the verifier. Not ambiguous. The bullets form a list in which only the third carries a level ("at
company level"), so the others apply at every level where `note` runs. `note` never runs at customer level, so that
means personal and company. 15b's own *Redaction* test confirms this: it is set beside "`note` at personal level" and
expects "the origin owner" replaced with a placeholder. The executor can resolve this from the plan.

### R11-18 · minor · decisions

Task 17 *The skill* (landing rule "a branch holding session-end commits lands by a squash-merged PR, never a
fast-forward"): The rule is written into `implementing-plans` for every future run, but it doesn't say who opens and
merges the PR, or under which approval. The global § *Approvals* says opening or merging a PR is a platform write
needing its own yes. The rule also doesn't say which wins when a plan's `## Approvals` says to fast-forward `main`, as
this plan's 2026-10-30 and 2026-11-05 bullets did. Executor's question: "Does the skill open and merge the PR itself
on a recorded yes, ask for one in the up-front approvals, or only tell the user the branch must land by PR?" Scenario:
A later plan's Approvals say "fast-forward `main`" and its run has session-end commits. One executor writes the skill
line as a hard override and stops; another fast-forwards because the plan's yes says so. That pushes work-in-progress
commits to `main`, which is what the rule forbids.

### R11-19 · minor · decisions

Task 16 *Change* (front matter leaves the line count) with Task 17 *Line budget*: Excluding front matter from the
count drops `implementing-plans/SKILL.md` below its 120 pin, and Task 17 spends that headroom. But
`bin/check-md-limits --update-baseline` with no files "tighten[s] existing pins to current". The plan doesn't say
whether Task 16 re-pins. If it does, the 4 freed lines are gone before Task 17 starts. Executor's question: "Does Task
16 run `--update-baseline` after the change, or leave the pins as they are?" Scenario: The Task 16 implementer
tightens pins to tidy up after changing the counting rule. The skill's pin falls to 116, and Task 17 has no room for
its paragraph without the fallback cut, or it fails `check-md-limits`. That contradicts the plan's premise that 16
frees 4 lines for 17.

### R11-20 · minor · decisions

Task 17 *When*: The trigger is "the user's request to wrap up" or the part-way final report. The plan doesn't say
whether a stop inside the final code review counts. There, `reviewing-in-rounds` drives fixes that stay unstaged until
Completion, and Task 17 says that skill is unchanged. Executor's question: "Does the session-end save run when the
session ends during `reviewing-in-rounds code`, and if so, are its unstaged fixes committed or left behind?" Scenario:
A session ends at round 5 of the code review. The session-end commit takes only the index, so another machine resumes
without the review's fixes, which are still unstaged. Or the step is skipped because the paragraph sits in
`implementing-plans`'s *Finish* section. The two readings give different saves.

### R11-21 · nit · decisions

Task 15 *Tests*, *Counts* bullet ("at company level the plan's and branch's words redacted from the introspection
(15b)"): Task 15's tests include a Task 15b behaviour (the introspection's redaction), which Task 15 doesn't build.
The same case is not listed in Task 15b's *Redaction* tests. Scenario: The Task 15 implementer can't make that
assertion pass, because `note` doesn't exist yet. Task 15b's implementer may skip the company-level word redaction
test, since it isn't in their task's list.

### R11-22 · nit · decisions

§ Approvals, 2026-11-05 run block, fourth bullet ("`main` fast-forwarded, pushed and CI watched"): The bullet still
reads as a live yes for fast-forwarding `main`. It is superseded only by a later block's preamble. Unlike the earlier
2026-11-09 private-ref block, it isn't marked inline as superseded. Scenario: An executor reading § Approvals top-down
for "a recorded yes" (as `implementing-plans` instructs) finds a yes to fast-forward `main` for this run before
reaching the block that replaces it.

### R11-23 · nit · consistency

Task 17, Change, 'At personal and company level' (`git add -u --` the plan file and its `plan-<branch>-review-*`
files): Task 17 names the review files by the branch, but `claude/docs/review-log.md:11` produces them as
`plan-<stem>-review-findings-<kind>.md`, named by the plan's stem. Task 13 and Task 15 (`-review-findings-*.md`) both
use the stem form. Scenario: Take a plan `plan-foo.md` worked on branch `issue-42`. The session-end skill text stages
`plan-issue-42-review-*`, which matches nothing, so the WIP commit leaves out the tracked findings and review-log
files. Another machine then resumes from the push without the review state. This run hides the bug because the branch
`ai-framework` happens to equal the stem.
Refuted: Downgraded from major by the verifier. Downgraded. `implementing-plans` step 4
(claude/skills/implementing-plans/SKILL.md:46) always names the branch after the plan's stem (`plan-42-login.md` →
`42-login`), so inside the skill `plan-<branch>-review-*` and `plan-<stem>-review-findings-*` name the same files. A
plan `plan-foo.md` on branch `issue-42` can't come out of the skill's own flow. The naming still differs from
review-log.md:11 and Tasks 13 and 15, so it stays as a wording fix: write `<stem>`.

### R11-24 · minor · consistency

Task 17, Change, 'The skill' (the in-place edits list): The edits Task 17 makes in place cover the opening line's
"nothing is committed", the review-input line's "`BASE..HEAD` is empty" and the "A checkpoint commit is safer" red
flag. They leave out `implementing-plans` § *Checkpoint in the index* "The plan file is never staged", which the
session-end `git add -u --` on the plan file contradicts. Scenario: After Task 17 is built, the skill tells the
session both never to stage the plan file and to stage it at every session end. An executor following the checkpoint
rule skips the plan, or one following the new paragraph breaks the older rule. Neither is marked as the exception.

### R11-25 · minor · consistency

Task 15, Tests, 'Counts' bullet ("at company level the plan's and branch's words redacted from the introspection
(15b)"): Task 15's test list includes a test of Task 15b's company-level redaction in `ai-log note`. Task 15b's own
Redaction test bullet doesn't list the plan- and branch-word case. Scenario: The build order is 16, 15, 17, 15b, so
whoever builds Task 15 must write a test for a `note` subcommand that doesn't exist yet, and the task can't go green.
Whoever builds 15b, reading only 15b's Tests, never adds the plan- and branch-word redaction test.

### R11-26 · minor · consistency

Task 15, Tests, 'Real data' ("No real `record` runs here: the first is Task 15b's end to end"); Follow-ups, Revisit
("After ... Task 15b's first real entry"); § Approvals, 2026-11-05 log-repo yes ("From Task 15b on"): Several places
assume the first real entry comes from Task 15b. Under the build order 16, 15, 17, 15b, Task 17's session-end steps
run a real `ai-log record` before 15b is built. The 2026-11-09 Approvals also say that until Task 17 is built, session
ends follow its steps by hand. Scenario: A session ends between building Tasks 15 and 15b. It runs a real `record`
that commits and pushes to `andrelin/ai-framework-log`, which contradicts Task 15's statement. That write falls before
the 'From Task 15b on' standing yes, and the Revisit's trigger then points at the wrong first entry.

### R11-27 · minor · consistency

§ Implementation status, 'Final code review' row (✅ DONE): The row is ✅ DONE, carried over from Task 14's and the
2026-11-02 run's reviews. The Order, the Handover and Task 13's 2026-11-05 deviation all require a new final code
review after 16, 15, 17, 15b and 13's fold. Scenario: An executor resuming from the status table, as
`implementing-plans` does, reads the final review as already done. It may then skip straight to `ai-log record`, the
`git rm` commit and the PR, or fail to flip the row at Completion.

### R11-28 · minor · consistency

§ Handover, opening paragraph, item 0 and 'Start next session here' ("first round 10 of the plan review"): The
handover says the plan review ran 7 rounds and that round 10 comes next. The task sections already cite round-10
findings that have been folded in (R10-1, R10-9, R10-17, R10-30), so round 10 has run. Scenario: A resuming session
follows the handover and runs round 10 again, or numbers its next round wrongly. Item 0's 'Not yet reviewed, for round
10' no longer says what is actually unreviewed.

### R11-29 · minor · consistency

Task 13, Deviation (2026-11-03), the list of open items for the issue: The list is stale and disagrees with Handover
item 6. It still carries 'Task 7's conflict sent to the user', which was ruled 2026-11-05, and 'Task 11's
CI-on-`main`'. It leaves out what Handover item 6 lists (the audit's recorded Mediums and Lows, R12-4). It also leaves
out the reruns behind the 🚧 PARTIAL rows of Tasks 5, 8 and 9, the open `planechaser#73`, and the unfiled 2026-10-23
learnings. Scenario: At Task 13, the executor files the issue from the enumerated list. That issue carries a resolved
item, and deleting the plan loses the PARTIAL tasks' pending tests and the audit findings.

### R11-30 · minor · consistency

Task 15b, Files, the `claude/docs/work-contexts.md` sentence: The new sentence says only that `reviewing-in-rounds`
runs `ai-log` after a plan's commit. Task 17, built before 15b, also has `implementing-plans` commit, push and run
`ai-log record` at every session end, and Task 17's own `work-contexts.md` edit adds only the commit exception, not
the log write. Scenario: After both tasks, `work-contexts.md` describes when data leaves the machine for the log repo
but leaves out the session-end records. A reader auditing what is pushed, and when, gets an incomplete account.

### R11-31 · nit · consistency

§ Approvals, 2026-11-09 bulk block ("Any PR counts as squashed" (Task 17)): The pointer names Task 17, but Task 17's
text no longer has a PR-versus-fast-forward distinction that consumes this ruling. It was a leftover of the superseded
private-ref design. Scenario: An executor looking in Task 17 for where 'any PR counts as squashed' applies finds
nothing, and the ruling never reaches the skill line it was meant for.

### R11-32 · nit · consistency

§ Approvals, 2026-11-05 block ("main fast-forwarded, pushed and CI watched, as for Task 14"): This bullet was
superseded by the 2026-11-09 post-round-9 block (squash-merged PR) but isn't marked as superseded where it stands,
unlike the private-ref block. Scenario: A reader of the 11-05 block alone lands the run by fast-forward, which
contradicts the later ruling.

### R11-33 · nit · consistency

§ Implementation status table order vs Order paragraph; Task 16 Interfaces; Follow-ups intro: Three small mismatches.
The table lists 15, 15b, 16, 17, while the build order is 16, 15, 17, 15b. Task 16's Interfaces says 'none' although
Task 17 consumes its four freed front-matter lines. The Follow-ups intro says 'neither' over three subsections
(Revisit, 15c, 15d). Scenario: These are cosmetic inconsistencies that a reader has to reconcile by hand. Task 16's
executor doesn't see that Task 17 depends on the line count it frees.
Refuted: Dropped by the verifier. Dropped. The status table isn't a build order: it already lists 14 after 12 and 13
after M, and the Order paragraph is what governs. That paragraph says Task 17 runs after 16 'which frees the 4 lines
its skill edit fits in', and Task 17's Line budget says so too, so the dependency is recorded. Task 16 consumes
nothing and produces no interface, so 'none' is accurate. 'Neither' refers to the two buildable follow-ups, 15c and
15d; the Revisit is a question, not a follow-up. No failure scenario follows.

### R11-34 · minor · work context

Task 17, Change, 'The level' and 'At personal and company level' (plan lines 3841-3850); Task 15 Interfaces, `ai-log
level` and exit codes (3548-3555): The session-end commit and push are gated only on `ai-log level` printing
`personal` or `company`, but the plan never says what happens when `ai-log level` fails, prints nothing, or can't read
the private clone's `allow` file. Exit 2 ('AI_LOG_DIR not a git clone') is listed for `record` and may apply to
`level` as well. Task 17 says only 'A failure goes in the report', which does not say whether the commit and push
still go ahead. The gate needs to fail closed: any output other than exactly `personal` or `company`, a non-zero exit,
or a missing `ai-log` means nothing is committed or pushed. Scenario: On a fresh machine with no `~/.ai-framework-log`
clone, or with `ai-log` not on PATH, a session ends in a customer repo that is not yet listed in
`~/.claude-customers`. The guard resolves that repo as company, so it does not block the write. `ai-log level` exits 2
and the skill treats that as a failure to report, then still runs `git commit` and `git push -u origin <branch>` to
the customer's remote. That is a forbidden write at customer level, and this gate is the only thing that was meant to
stop it.
Refuted: Downgraded from major by the verifier. Partly refuted. The gate in Task 15 (plan lines 3616-3621) already
fails closed on its inputs. Any origin outside github.com/andrelin or github.com/uptimeconsulting that is not listed
in the private clone's `allow` file counts as customer, and `work-context.sh level` exiting non-zero counts as
customer too. A missing clone or `allow` file therefore leaves an unlisted customer origin at customer level. It does
not let it through as company. The gap that is left is narrower: Task 17 does not say what the session end does when
the `ai-log level` command itself errors, either `ai-log` missing from PATH or exit 2 if `level` shares `record`'s
'AI_LOG_DIR not a git clone' check. In that case 'A failure goes in the report' is ambiguous. This is error handling
around one command, and one line settles it while implementing ('anything but personal/company on stdout with exit 0
means customer handling'). It is not an assumption the approach rests on. It stays above nit because the guard does
not cover an unlisted customer repo, so this gate is the only thing between that repo and a push.

### R11-35 · nit · work context

§ Approvals 2026-11-09 (lines 114-119, 'The squash removes `d88b6fa`'; 125-126 'Squash it out'); Task 17 'Landing'
(3859-3862); Task 13 deviation (3922-3928): The plan assumes a squash-merge removes the work-in-progress commits and
keeps a tracked plan out of the default branch's history. On GitHub that holds only for `main`'s history. A pushed
branch's commits stay world-readable for good through the PR's `refs/pull/<n>/head` and its Commits tab, even after
the branch is deleted. On a personal-public repo, Task 17 pushes at every session end: the plan, its review-findings
files and the checkpointed index, before the final code review. Whatever is pushed meets the public bar
('world-readable forever') at that moment, not at merge. `d88b6fa` (4,528 lines of plan and findings files) is already
on `origin/ai-framework`, so it stays public whatever the squash does. Either state that the squash cleans only
`main`, and that the public bar applies to every session-end push, or require a work-context check (no customer names,
hostnames, internal tooling or secrets) on what is staged before each session-end push on a public repo. Scenario: A
future personal-public run copies a real hostname into a review-findings file. The final code review would have caught
it, but a session end pushes first. The user later squash-merges, deletes the branch and believes the content is gone,
yet it is still served from the PR's commits. The user's 'Squash it out' answer and Task 13's 'removed from git before
merging to the default branch' both suggest they expect the content to disappear, and on a public repo it does not.
Refuted: Downgraded from major by the verifier. I confirmed `d88b6fa` is on origin/ai-framework and that
andrelin/dotfiles is PUBLIC. The finding's harm is not introduced by this plan, though. CLAUDE.md sets the
personal-public bar on what you commit, and this plan file and its findings files are tracked on a public repo. They
were bound by the public bar, and pushed publicly, under every design, including Completion's per-task commits and the
push before the PR that Task 13 already describes. Session-end pushes add no new exposure class. The plan's own claims
are accurate: lines 114-126 and 3859 say the squash keeps the commits out of the default branch's history, which is
true, and 'Squash it out' answers a history-readability question, not a secrecy one. What remains is a wording
clarification: the squash cleans `main` only, and pushed branch or PR commits stay public. Nothing gets built wrong.

### R11-36 · nit · work context

Task 13, Deviation (2026-11-03) paragraph (lines 3941-3946); § Approvals 2026-11-09 'Ask me then' (128): Task 13's
GitHub issue does not name its repo. If it is `andrelin/dotfiles`, which is public, the plan does not say the public
bar applies to it. The issue carries Task M 'if still open, with their sketches'. Task M concerns a repo-specific
`autoMode` block whose real contents (the repo's confidentiality, its external mirror folder, customer names) sit in
the machine-local `~/.claude/settings.json`. An executor fleshing out the open item could copy those details into a
world-readable issue. The fix is to name the target repo and say the issue stays as generic as the plan text: no names
from `~/.claude/settings.json` or `~/.claude-customers`. Scenario: At Task 13 the executor reads
`~/.claude/settings.json` to describe Task M's remaining work concretely and files an issue on public
`andrelin/dotfiles` that names the private repo and its customers. The user's 'Ask me then' preview is the only check,
and nothing tells the executor to keep machine-local facts out.
Refuted: Downgraded from minor by the verifier. Mostly refuted. Task 13 says the issue carries the open items 'with
their sketches', and those sketches are the plan's own text, already tracked and pushed on the public repo. Task M's
sketch is generic and says outright 'Keep the customer names in that private repo; none go into the global block'.
Nothing tells the executor to read `~/.claude/settings.json` to build the issue, and the scenario needs the executor
to go beyond the brief. The global personal-public bar governs anything published from this repo, and the user's 'Ask
me then' preview of the draft before filing is an explicit check. The target repo is clear from context: everything in
Task 13 happens on andrelin/dotfiles. Naming the repo would be a small wording improvement.

### R11-37 · nit · work context

Task 15b, Files, the `work-contexts.md` text (lines 3688-3691), and Change, the skill step (3701-3704): The
`work-contexts.md` addition says that after a plan's commit, at every level, `reviewing-in-rounds` runs `ai-log`. At
customer level, though, the commit is the user's: Claude drafts it and never runs it. The skill step runs 'once the
commit has run', so at customer level it either never runs or runs after a commit the user made outside the session.
Saying that at customer level the step is skipped, or that it prints only the deferral line, would stop the doc from
implying Claude commits there. Scenario: A reader of `work-contexts.md` takes 'after a plan's commit, at every level'
to mean the workflow commits at customer level, which contradicts § Work contexts' list of forbidden commands.

## Round 12

### R12-1 · major · grounding

Task 17, Change, **When:** (the trigger): The trigger counts 'the run's part-way final report, the one that prints `ai implement <plan-file>`'
as a session end, but excludes 'a stop to ask'. Those are the same thing in the current skill.
`claude/skills/implementing-plans/SKILL.md:133` says 'A run that stopped part-way runs no code review; it says which
tasks aren't ✅ DONE and prints `ai implement <plan-file>` to resume'. Every stop in that skill ('every stop here stops':
deviations, task reviews sent to the user, a review stopping for a user decision) produces that report. The claim the
trigger rests on, that a part-way report is something other than a stop to ask, does not hold for the skill as written.
Scenario: A run stops at a deviation and asks the user. It prints the part-way report with `ai implement plan-x.md`. One
executor reads the first clause and makes a WIP commit, pushes and records a log entry on every question, which is what
R9-23/R9-27 ruled out. Another reads the exclusion and never saves on a part-way report. The skill paragraph cannot be
written without the executor choosing which rule wins.
Fixed: Task 17's trigger is the user's wrap-up request or a part-way report that asks nothing; every stop to ask prints
that report too and is not a session end.

### R12-2 · major · grounding

Task 17, Change, **Line budget** and **The skill**: The budget claim is unverified, and the arithmetic suggests it
fails. I counted `claude/skills/implementing-plans/SKILL.md` at exactly 120 non-blank, non-heading lines, equal to its
`.md-baseline` pin. Task 16 frees 4 lines (`---`, `name`, `description`, `---`), and the one named fallback cut (the 'On
resume, rewrite each brief…' sentence, lines 37-38) frees about 2 more. That gives roughly 6 lines. The paragraph must
hold the trigger, the `ai-log level` gate, the add rules (personal untracked vs company tracked-only), the `Work in progress: Tasks`
commit with `--allow-empty`, the ref deletion, the push, the counts-only `record`, failure handling, customer level and
the squash-PR landing rule. On top of that come three in-place rewrites, each of which adds words. At 150 characters a
line that is about 9-11 lines. The plan gives no second fallback, and the pin is 'never raised'. Scenario: The executor
writes the paragraph, and `bin/check-md-limits` fails the pin even after moving the resume sentence. The plan forbids
raising the pin and names no other cut, so the run stops for a user decision partway through Task 17. That costs a round
trip a pre-check of the draft against the budget would have avoided.
Fixed: the steps move to a new `claude/docs/session-end-save.md`; the skill keeps a paragraph of about three lines
(trigger, pointer, landing rule), which fits the 4 lines Task 16 frees.

### R12-3 · major · grounding

Task 15, Interfaces, the entry's per-lens tokens (`An agent's lens comes from its Workflow .meta.json description …`):
The `.meta.json` lens source does not produce the lens names the plan assumes. The `###` heading mapping is described
only for the `Lens:` prompt fallback; the meta `description` is taken 'where present' as is. Real Workflow agents in
this repo's transcripts carry ad-hoc names written by each session's workflow script: `review:fit`,
`review:conformance`, `review:docs`, `verify:consistency` next to `verify:Consistency`, and `verify:decisions` next to
`verify:Decisions an executor can't make`. None of these match headings such as 'Fit with the surrounding code' or 'Plan
conformance'. The description is also free text chosen per run, so storing it raw at company level breaks the 'No free
text' rule. Scenario: Two plan reviews record Consistency tokens under both `Consistency` and `consistency`, and
code-review fit tokens under `fit` instead of the heading name. Transcripts are deleted after 30 days, so the stored
aggregates can never be re-split. Task 15d's 'lenses whose cost recurs with no findings' then compares split and
misnamed buckets against findings keyed by the `### R<n>-<m> · <sev> · <lens>` headings, and cut candidates come out
wrong. A workflow description such as `review:<engagement name>` would also be stored verbatim in a company-level entry.
Fixed: a stored lens is always a `###` heading of `review-lenses.md` or `other`, matched from the description or `Lens:`
text by heading prefix, first word or a short alias table, never stored raw.

### R12-4 · minor · grounding

Task 15, Change, **The window** (first appearance) and § What the transcripts hold (`cleanupPeriodDays` 30): The plan
notes the 30-day transcript cleanup but does not check what it does to this plan's own first entry. `cleanupPeriodDays`
is unset in `~/.claude/settings.json`, so the 30-day default applies. The oldest dotfiles transcripts are from
2026-10-13, and this plan began 2026-10-16. The first real `record` runs only at the end of this run, after Tasks 16,
15, 17 and 15b, which is likely more than 30 days after the plan began. The window start is the earliest surviving
record that names the plan, so the loss produces no warning. Scenario: By the time Task 15b's end-to-end `record` runs,
the sessions of 2026-10-13 to 10-16 (Tasks 0-3 and the first review rounds) have been deleted. The first entry silently
starts weeks late and undercounts cost, rounds and majors for the plan the framework is first judged on. Either raise
`cleanupPeriodDays` before building, or warn when the earliest in-scope record is near the retention edge.

### R12-5 · minor · grounding

Task 17, Change, **The skill** (in-place edits) and **Files** (`work-contexts.md`): The in-place edits list covers the
opening line, the review-input line and the red flag. It misses `implementing-plans/SKILL.md:104`, 'The plan file is
never staged', which Task 17's `git add --` of the plan and its review files contradicts directly. It also misses
`work-contexts.md:86`, '`implementing-plans` checkpoints in the index and never commits', a separate line from line 85,
the one Task 17 names. Scenario: After Task 17 the skill tells the session both to stage the plan at a session end and
never to stage it. `work-contexts.md` still says `implementing-plans` never commits. A later session following line 104
skips the plan, so another machine resumes without the plan's status rows.

### R12-6 · minor · grounding

Task 17, Change, **The level**; Task 15, Interfaces (`ai-log level`, exit 2 when `AI_LOG_DIR` is not a git clone): Task
17 gates every session-end commit and push on `ai-log level`. That gate reads the `allow` file inside the private log
clone, and Task 15 defines exit 2 when `AI_LOG_DIR` is not a clone. The plan does not say what `level` prints or exits
without the clone, or what the session end does then. The user works from more than one machine, and the clone is
created only on this one. Scenario: On a second machine without `~/.ai-framework-log`, a session end runs `ai-log level`.
It either exits 2, leaving the save undefined, or treats the repo as customer and skips it. The user's 'Commit and push
the branch' rule then silently does nothing on that machine, and the next machine resumes from stale work.
Refuted: Dropped by the verifier. What `ai-log level` does without a clone is error handling, which the out-of-scope
line leaves to the code. Task 17 also says 'A failure goes in the report', so the save does not fail silently as the
scenario claims. And for github.com/andrelin and uptimeconsulting origins the gate needs no `allow` file, so an executor
can check this in the diff.

### R12-7 · nit · grounding

§ Approvals, 'Added 2026-11-05 by the iteration that detailed Task 15' block; Task 17, Change (`then ai-log record <plan-file>`):
The standing yes to commit and push to `andrelin/ai-framework-log` without asking is worded 'after every plan' and
covers 'every write the step makes', meaning Task 15b's skill step. Task 17 adds a second writer, a `record` at every
session end that commits and pushes to the log repo. That write is named only in the user's 'commit and ai log at the
end of sessions', which said nothing about pushing the log repo. Under the global 'An approval covers what it names',
the session-end push to the log repo is not clearly covered. Scenario: A later run reads § Approvals (or, after Task 13,
the skill line) and finds the log-repo yes scoped to after-plan writes. It either asks at every session end, which
defeats the point, or pushes on an approval that does not name this write. Recording the session-end push explicitly in
the approval removes the doubt.
Refuted: Downgraded from minor by the verifier. Downgraded. The user explicitly asked to 'ai log at the end of
sessions', and `ai-log record` is defined as committing and pushing its entry, which the 2026-11-05 log-repo yes covers
by name. Task 17 cites the standing yes for this write. Stating the session-end push explicitly in the approval would
remove a reader's doubt, but no write goes unapproved.

### R12-8 · nit · grounding

Task 15, Interfaces (`framework.dotfiles_commit`, `commit`, the id) together with the 2026-11-09 squash-merge landing (§
Approvals, Task 17 **Landing**): The new landing rule (every multi-session change lands by a squash-merged PR) was not
checked against what entries store. When the work repo is this dotfiles repo, `dotfiles_commit` and `commit` are branch
shas. The squash removes those shas from `main`'s history, and `deleteBranchOnMerge` is false on `andrelin/dotfiles`,
with no branch deletion approved. Follow-up 15d's 'grouped by framework commit' then groups by shas that sit on no line
of `main`. Scenario: Every entry recorded while the framework itself is being changed (all of this run's) names an
`ai-framework` sha. After the squash, 15d cannot order those entries against later framework commits on `main`, or say
which framework version they measured. They are reachable only through `refs/pull/*` or a leftover branch.
Refuted: Downgraded from minor by the verifier. Downgraded. `deleteBranchOnMerge` is false and no branch deletion is
planned, so the `ai-framework` shas stay reachable on origin, and GitHub also keeps them under refs/pull/`<n>`/head. The
stored shas therefore remain resolvable and entries carry `recorded_at`. 15d is an undetailed follow-up that settles its
grouping when it is detailed, so no data is lost and this is not costly to reverse.

### R12-9 · nit · grounding

Task 15b, **Why not also `implementing-plans`**: The rationale 'it never commits' is out of date once Task 17 is built:
`implementing-plans` then commits and runs `ai-log record` at session ends. The conclusion still holds, since the
introspection is written only once, after the final commit, but the stated reason no longer does. Scenario: A reader of
the folded doc or the skill sees `implementing-plans` committing and recording, and the reason no longer explains why
the introspection step lives only in `reviewing-in-rounds`.

### R12-10 · nit · grounding

§ Approvals, 2026-11-05 run block (lines 91-92) and the superseded 2026-11-09 block (line 109 vs line 121): The
2026-11-05 bullet still says 'committed after the final code review, `main` fast-forwarded, pushed and CI watched' with
no superseded mark, though the later block replaces the fast-forward. The sentence 'This run's session ends before Task
17 is built follow its steps by hand' appears both in the superseded block and in the current one, and neither notes
that `ai-log` does not exist until Task 15 is built. Scenario: An executor scanning § Approvals finds both 'fast-forward
`main`' and 'squash-merge a PR' for this run. A session end before Task 15 is built cannot run the `ai-log record` step
'by hand'.
Refuted: Partly refuted. The 2026-11-09 block explicitly says it replaces 'the fast-forward of `main` for this run', so
the 2026-11-05 bullet is superseded in the text. The remaining point stands as a nit: a session end before Task 15 is
built cannot run `ai-log record` 'by hand', and neither block says so.

### R12-11 · nit · grounding

§ Approvals, 'Asked and answered 2026-11-09, in bulk' (`d88b6fa`: 'Squash it out'): Squash-merging removes `d88b6fa`
from `main` only. The pushed `origin/ai-framework` branch keeps it in this public repo unless the branch is deleted, and
no branch deletion is approved (`deleteBranchOnMerge` is false). Scenario: After the PR merges, `d88b6fa` and the other
WIP commits stay publicly reachable on `ai-framework`. If 'squash it out' meant keeping the WIP commit out of the public
history, that intent is only half met.
Refuted: Dropped by the verifier. `d88b6fa` was already pushed to origin/ai-framework in this public repo, so deleting
the branch would not unpublish it (refs/pull keeps it too). The approval's context shows that 'Squash it out' was about
dropping the planned rebuild and force push in favour of the squash keeping it off `main`, and the squash does that. The
scenario rests on a speculative reading of the user's intent, with no failure or requirement named.

### R12-12 · major · scope and slicing

Task 15, Interfaces, the entry's per-lens tokens ("An agent's lens comes from its Workflow `.meta.json` `description`
(`review:<lens>`, `verify:<lens>`)..."): The per-lens cost data rests on an assumption the 2026-11-05 field inspection
never checked. That inspection lists no `.meta.json` fields. This repo's real Workflow metas carry free-form lens names
that the session's own workflow scripts wrote, not the `###` headings of `review-lenses.md`. A sample of
`~/.claude/projects/-Users-andrelin--dotfiles/*/subagents/workflows/wf_*/agent-*.meta.json` shows `review:Scope and slicing`
and `review:Work context` (headings) next to `review:fit`, `review:whole`, `review:tests`, `verify:correctness` and
`verify:conformance` (slugs). The plan maps only the `Lens:` text to a heading, so either the description value is
stored raw or it falls to `other`. Scenario: Run against real data, the same lens lands under two keys: "fit" in one run
and "Fit with the surrounding code" in another. Or most code-review lenses collapse into `other`. Task 15d's cut
candidates then compare lenses whose costs are split or merged, and the stored entries can't be re-keyed after the
transcripts expire at 30 days. Fix: make inspecting real metas the task's first step, and state how a description value
is normalised to a heading.
Fixed: as R12-3.

### R12-13 · minor · scope and slicing

Task 17, Tests: The tests prove the git mechanics (`grep -c` counts, `write-tree` equals `HEAD^{tree}`, `Base:` is an
ancestor) but not the behaviour the task actually adds: that Claude runs the session-end save when the user asks to wrap
up or when the part-way report is printed, and not at a stop to ask. The git invariants are predictable. The unverified
part is the trigger. Other skill changes in this plan (Tasks 9 and 14) got headless scenario runs; this one gets none.
Scenario: The paragraph reads cleanly and passes its grep tests, but in a real run the model either skips the save on
"let's wrap up" or runs it before an `AskUserQuestion` stop. The result is a missing work-in-progress push (another
machine resumes from stale work) or a stray commit and log entry. Nothing in the task would catch either. Fix: add one
headless scenario pair, a wrap-up request that saves and a question stop that doesn't.
Refuted: Downgraded from major by the verifier. Downgraded. The gap is real: Task 17's tests check the git invariants
but never check that the paragraph fires on a wrap-up request and not at a stop to ask, while Tasks 9 and 14 got
headless scenario runs. Choosing exact test cases is largely out of scope, though, and adding one headless scenario pair
costs little while implementing, under the existing 2026-10-30 yes for headless agents. The approach doesn't rest on it,
since the trigger wording is the user's own ruling.

### R12-14 · minor · scope and slicing

Task 17, Change, "commit the index ... with `--allow-empty`, so every session end has its own `HEAD` and so its own log
entry": The empty commit buys nothing the user asked for. Task 15 already defines a same-`HEAD` re-run as replacing its
own entry, with the window starting at the previous *other* entry's end, so the counts of both sessions survive in one
entry. Task 15's own test says "two runs at the same `HEAD` → one entry, the later window". The empty commit only splits
that entry in two. Scenario: Each idle session end adds an empty `Work in progress` commit and a log entry to the
branch, with no data lost if it were left out. Fix: drop `--allow-empty` and the matching test ("A second session end
with nothing new checkpointed still makes a commit"), or name the requirement that needs one entry per session.

### R12-15 · minor · scope and slicing

Task 15, Tests, Counts bullet ("at company level the plan's and branch's words redacted from the introspection (15b)"):
A test of Task 15b's `note` redaction sits in Task 15's test list. `note` and the redaction are built only in 15b.
Scenario: An executor building Task 15 can't make this test pass, or builds part of 15b's redaction early to satisfy it,
blurring the slice. Fix: move the line to Task 15b's Redaction tests.

### R12-16 · minor · scope and slicing

Task 15, Tests, "Real data, last" ("No real `record` runs here: the first is Task 15b's end to end") versus the Order
line "16, 15, 17, 15b" and Approvals "This run's session ends before Task 17 is built follow Task 17's steps by hand":
Task 17's session-end steps run a real `ai-log record`, which commits and pushes to `andrelin/ai-framework-log`. With 17
built before 15b, and earlier session ends following its steps by hand, the first real push happens at whichever session
end comes first after Task 15 is built, not at 15b's end to end. The 2026-11-05 log-repo yes reads "From Task 15b on,
after every plan", which names neither session ends nor the time before 15b. Scenario: A session ends between Tasks 15
and 15b. The session runs `ai-log record` for real, pushing an entry no test has checked. Either the approval doesn't
name this write (and the session should stop to ask), or the plan's claim about the first real record is wrong. Fix: say
whether session-end records before 15b are covered by the user's "commit and ai log at the end of sessions", and reword
Task 15's sentence to match.
Refuted: Partly refuted. The approval half of the scenario fails: the user's 2026-11-05 'commit and ai log at the end of
sessions', recorded as a standing rule in Approvals, and the yes to 'push to it as Task 15 builds' both cover a real
session-end `record` before Task 15b. The inconsistency half stands. The Order runs 15, 17, 15b, and Approvals says
session ends before Task 17 follow its steps by hand, so a session end between 15 and 15b runs a real `record`. That
contradicts Task 15's 'No real `record` runs here: the first is Task 15b's end to end'. One sentence settles it.

### R12-17 · minor · scope and slicing

Task 15, Tests and Change ordering (the real-data dry run and price check placed last): The real-data dry run is the
cheapest probe of every assumption about the transcripts (lens attribution, `.meta.json` phases, dedup across resumed
sessions, prices against `cost-state`), yet it is the last thing done, after the review-key increments, company hashing
and the plugin allowlist are all built. The order doesn't put the riskiest assumption first. Scenario: The dry run shows
a field shape the parser didn't expect, as the lens metas above already do. The parser, its fixtures and their tests are
then reworked after the fact. Fix: open the task with a read-only probe over real transcripts (field shapes and the lens
and phase values) and build the fixtures from what it finds.

### R12-18 · minor · scope and slicing

Task 17, Change, Landing ("work that has such commits lands by a squash-merged PR ... `reviewing-in-rounds` is
unchanged"): The task says the work lands by a squash-merged PR but doesn't say whether the skill paragraph opens or
merges that PR, or only states the rule. Nothing marks PR creation as out of scope for Task 17, and this run's landing
steps (in Approvals and Task 13) do open and merge one. Scenario: An executor adds `gh pr create` and squash-merge steps
to `implementing-plans`, which would be an unrequested platform write wired into a skill. Or the executor leaves them
out while a reader assumes the skill handles landing. Fix: one line saying the paragraph states the landing rule only,
and the PR is opened per the plan's `## Approvals`.
Refuted: Dropped by the verifier. Refuted by the plan text. Task 17's 'The skill' bullet lists exactly what the
paragraph holds: 'the trigger, the level, the steps, customer level and the landing rule — a branch holding session-end
commits lands by a squash-merged PR, never a fast-forward'. The steps it lists (add, commit, delete refs, push, record)
don't include opening or merging a PR, and the landing item is stated as a rule. Adding `gh pr create` would go beyond
the task's stated content, and the global approvals rule already forbids unrequested platform writes. A reader can check
this in the diff.

### R12-19 · nit · scope and slicing

Task 13, Tests (`git ls-files 'plan-ai-framework*'` prints nothing after the commit) versus the 2026-11-05 deviation
(the `git rm` is a separate commit after the final code review and `ai-log record`): Task 13's fold is task-reviewed
like any task, but its tests include a check that can pass only after the `git rm` commit, which comes later, after the
final review. The task's tests mix the reviewable fold with the post-review delete. Scenario: The task review of Task 13
runs its tests, `git ls-files` still lists the plan, and the task is marked failing or the implementer deletes the plan
early, before `record` reads it. Fix: split the tests into those for the fold (at the task review) and those for the
delete (after the `git rm` commit).
Refuted: Downgraded from minor by the verifier. Mostly refuted, so downgraded. The test is already scoped: 'prints
nothing after the commit', and the only commit Task 13 makes is the `git rm`. The task text says 'Only the delete waits'
and places the `git rm` after the final review and `ai-log record`. An implementer who deletes early would be ignoring
an explicit instruction, not misreading the test. Splitting the test list in two would only make the wording clearer.

### R12-20 · nit · scope and slicing

Task 16, Change ("`bin/check-md-limits` stops counting front matter toward the length aim and cap of every file"):
"Length aim and cap" can be read as the 150-character line-length limit as well as the line-count aim and cap. Only the
line count is meant. Scenario: An executor also exempts front-matter lines from the 150-character check, widening the
change beyond what the user asked for. Fix: say "line-count aim and cap".

### R12-21 · minor · decisions

Task 17, Change, 'At personal and company level' (the plan file committed when untracked at personal level) and
'Landing'; writing-plans § Plans are temporary: Task 17 has the session-end commit add an untracked personal-level plan
to the branch. Doing that turns the plan into a tracked file. But no task says who `git rm`s that plan before the squash
merge, or when relative to 15b's `ai-log record`. Task 17's Files leave out `writing-plans`, whose § Plans are temporary
still says most plans are untracked and get deleted after the work lands. `reviewing-in-rounds` Completion stages 'never
plan-*' and commits only the paths in task Files lists, so it won't make that commit either. The executor would ask: in
a future run, which skill step removes a plan that a session-end commit started tracking, and does writing-plans change
to match? Scenario: A later personal plan has one session-end commit. Completion commits per task, 15b records, and
nothing removes the plan. The squash-merged PR then publishes the plan and its review files on `main` of a public repo,
which breaks writing-plans' delete rule and 'never reference a plan from anything that outlives it'.
Refuted: Downgraded from major by the verifier. Downgraded. `claude/skills/writing-plans/SKILL.md` § Plans are temporary
(lines 121-124) already covers a tracked plan: "a tracked one with a `git rm` commit on the branch before it merges",
after the commit and log step. A plan that a session-end commit started tracking falls under that clause, so
writing-plans needs no change, and the plan's fold task is the step that runs it. What stays open is a one-line pointer
in Task 17's skill paragraph saying the plan is now tracked and needs that `git rm`. That is cheap to add while
implementing.

### R12-22 · minor · decisions

Task 17, Change, personal level, citing the user's 'Commit it on the branch' (2026-11-09, plan review R11-15); §
Approvals 2026-11-09 blocks: Before this change, personal plans stayed untracked and never left the machine. Pushing
them on a branch makes them public, because the PR's commits stay visible on GitHub after a squash. The quote that
approves this appears only inside Task 17 and is missing from § Approvals. That breaks the global rule that an approval
covers only what it names and is recorded up front. The executor would ask: is publishing plan and review-file contents
on a public branch approved for every future personal plan, and where is that recorded? Scenario: A future run pushes a
personal plan that holds review findings or follow-up notes to `origin`. That content stays readable in the PR's commit
list after the squash. Nothing in § Approvals or a durable skill shows the user agreed to that.
Refuted: Downgraded from major by the verifier. Downgraded. The approval exists. Task 17 quotes it and dates it ("Commit
it on the branch", 2026-11-09, R11-15), and § Approvals 2026-11-05 records the standing "Commit and push the branch" for
every future personal and company run, so publishing the branch is approved for all of them. Global § Approvals requires
each approval to be named and asked. It does not require a copy in a § Approvals list, and Task 17 makes the skill line
the place that yes outlives the plan. Mirroring the quote into § Approvals is real but a cheap edit, and nothing here is
built wrong.

### R12-23 · minor · decisions

Task 16, Change (front matter leaves the line count) and Task 17, 'Line budget': Once Task 16 stops counting front
matter, every file's count drops. `.md-baseline` says 'Regenerate with: bin/check-md-limits --update-baseline', and that
command lowers pins to their current size. Task 16 doesn't say whether to re-pin. If the Task 16 executor tightens the
pins, `implementing-plans` drops from 120 to 116. Pins are never raised, so the 4 lines Task 17 relies on are gone for
good. The executor would ask: does Task 16 leave `.md-baseline` untouched? Scenario: Task 16's executor sees every count
fall and runs `--update-baseline` to tidy up. Task 17's edits then can't fit, and the pin can't be raised to make room.
Task 17 is forced into its fallback cut, or it can't pass `check-md-limits` at all.
Refuted: Downgraded from major by the verifier. Downgraded. Nothing in Task 16 tells its executor to run
`--update-baseline`. The Order (line 190) and Task 17 both say Task 16 frees the 4 lines for Task 17. If the pin were
tightened anyway, Task 17 has a named fallback cut, moving resume step 1's last sentence to the reference doc, so it
would not be blocked. A sentence in Task 16 ('leave `.md-baseline` untouched') settles it cheaply. The finding is real
but not major.

### R12-24 · minor · decisions

Task 13, deviation paragraphs (the issue 'filed with writing-issues on the user's yes') and § Approvals 2026-11-09 ('Ask
me then') vs the landing sequence in § Approvals / Implementation status Order: Task 13's issue has to carry the
`Deferred:` lines, and the final code review produces some of those. Yet the fold is 'built and task-reviewed like any
task' before the final review. The landing sequence (final review commits, `ai-log record`, the `git rm` commit, push,
PR) doesn't include the stop to show the issue draft. The executor would ask: is the issue drafted and filed during Task
13's fold, before the final review, or after the final review and before the `git rm`? Scenario: Reading one: the
executor files the issue during the fold, so every `Deferred:` line from the final code review is lost when the plan is
deleted. Reading two: the executor stops mid-landing for the user's look, a step the Order and Approvals sequence never
lists.
Refuted: Downgraded from major by the verifier. Downgraded. Task 13's deviation says the issue is filed "before the
delete". The delete is the `git rm` commit after the final review's commits and `ai-log record`, so the text already
places filing after the final review, which carries its `Deferred:` lines. Handover item 6 gives the same order. The
Order paragraph does leave out the user-look stop, which is worth one clause. But a draft shown early can still be
updated before it is filed, so no data is lost. Cheap to settle.

### R12-25 · minor · decisions

Task 17, Change, 'Landing' and 'The skill' (the landing rule written into implementing-plans): The rule 'a branch
holding session-end commits lands by a squash-merged PR, never a fast-forward' goes into `implementing-plans`. Landing
itself happens in the plan's `## Approvals` and `reviewing-in-rounds` Completion, which Task 17 leaves unchanged.
Opening and merging a PR is a platform write that needs its own approval. The executor would ask: in a future run, who
opens and merges the PR, does the run ask for it, and which wins when a plan's Approvals say 'fast-forward main' (as the
2026-11-02 block did)? Scenario: A future plan's Approvals say 'fast-forward main'. Session-end commits exist on the
branch. The final run either fast-forwards, putting 'Work in progress' commits onto `main`, or opens and merges a PR
nobody approved.
Refuted: Downgraded from major by the verifier. Downgraded. Task 17 states the precedence outright: "a branch holding
session-end commits lands by a squash-merged PR, never a fast-forward". That answers the 'which wins' question. Opening
and merging a PR falls under global § Approvals' ask-in-bulk-up-front rule, which already makes a future run ask for it
with the rest of its approvals. Writing a cross-reference into the skill paragraph is cheap. Nothing gets built wrong in
this run, since this run's own PR landing is approved.

### R12-26 · minor · decisions

Task 17, Change ('At personal and company level' ... `ai-log record <plan-file>`) and the 2026-11-09 Approvals line
'This run's session ends before Task 17 is built follow Task 17's steps by hand'; Task 15 Tests 'No real record runs
here: the first is Task 15b's end to end': The run builds 16, 15, 17, 15b in that order. A session that ends before Task
15 is built can't run `ai-log level` or `record` by hand. A session end after Task 17 does run a real `record`, which
contradicts 'the first is Task 15b's end to end'. The executor would ask: before Task 15 exists, does a session end skip
the log step, and does a real session-end entry count as the first entry for the Revisit? Scenario: The session stops
after Task 16. Following Task 17 by hand, the executor hits `ai-log: command not found` and has no instruction for it,
so they either skip the commit or stop.

### R12-27 · minor · decisions

Task 15, Change ('Customer level, deferred', the clone's `allow` file) and Files ('Outside this repo'): `ai-log level`
reads a `<host>/<owner>` allowlist from an `allow` file in the private clone, but no task creates that file or sets its
first contents. It also duplicates `~/.claude-company-orgs`, which Task M already treats as the list of company owners.
Task 17 consumes this through `ai-log level`. The executor would ask: does the allowlist live in the log clone or in the
existing company-orgs file, and who fills it? Scenario: A company repo on a Forgejo host resolves as company through
`~/.claude-company-orgs`, but `ai-log level` prints `customer`. Session-end saves there then commit and push nothing,
with no warning that the allow file was never written.
Refuted: Partly refuted, kept as minor. The duplication claim is wrong: `claude/hooks/work-context.sh` never reads
`~/.claude-company-orgs`, and the only repo mention is in `test/test_work_context.sh`. A missing `allow` file also has
defined, conservative behaviour (treat as customer, record nothing). The real gap is that Task 15's 'Outside this repo'
creates only `entries/` and `README.md`. So a company Forgejo repo silently gets no session-end commit or push from Task
17 until someone writes the file. Saying who seeds it, and with what, is a cheap decision.

### R12-28 · minor · decisions

Task 15b, Change, 'The mechanical redaction' (company level: plan and branch words, 'plan and generic words aside');
Task 15 Tests ('at company level the plan's and branch's words redacted from the introspection (15b)'): The plan never
defines 'generic words', and that list decides what an introspection keeps at company level. This redaction test also
sits in Task 15's test list, although 15b builds the feature and comes after 17 in the run order. The executor would
ask: which stop-word list applies, and which task's tests own the case? Scenario: With branch
`feature/add-acme-billing`, one executor treats 'add' and 'billing' as generic and keeps them. Another redacts every
word, which also strips 'feature' and 'billing' from the evidence. Meanwhile Task 15's suite either fails or the case
gets skipped.
Refuted: Dropped by the verifier. Out of scope. The stop-word list behind 'generic words' is an executor choice that a
reviewer can check in the diff. The plan already sets its intent (`plan` and generic words aside, mirroring Task 15's
hashing) and gives examples of generic host labels. The test case's placement is labelled '(15b)' in Task 15's list, so
whose test it is was never ambiguous, and exact test cases are out of scope anyway.

### R12-29 · nit · decisions

Task 13, deviation (2026-11-03) list of items for the issue: The list still names 'Task 7's conflict sent to the user',
which was decided and reworded on 2026-11-05 (§ Approvals, Handover item 5). That gives two readings: carry a settled
item into the issue, or drop it. It also doesn't say which repo the 'GitHub issue' goes to. The executor would ask: does
the 2026-11-05 ruling drop the Task 7 item, and is the issue filed on `andrelin/dotfiles` or on the private log repo?
Scenario: The issue shown to the user lists an already-settled conflict as open. Or, if the private log repo is chosen
instead, follow-ups 15c and 15d end up where `writing-issues` and colleagues don't look.
Refuted: Downgraded from minor by the verifier. Downgraded to nit. Task 7's conflict is plainly settled elsewhere: its
status row says ruled and reworded 2026-11-05, § Approvals has the ruling, and Handover item 5 says decided. So the
stale list item is a wording leftover, and the user sees the draft before filing anyway ('Ask me then'). Which repo the
issue goes to is a `writing-issues` choice that the user's look at the draft also checks, and the items concern dotfiles
work.

### R12-30 · minor · decisions

Task 17, Change ('commit the index as `Work in progress: Tasks <list>`' with `--allow-empty`): The plan doesn't say what
the commit message is when nothing has been checkpointed since the last save. That is exactly the case `--allow-empty`
exists for, and the test 'A second session end with nothing new checkpointed' exercises it. The message is a fixed
string the Files-edits test greps for. The executor would ask: is it 'Work in progress: Tasks' with an empty list,
'none', or the last list repeated? Scenario: Two executors write different subjects for an empty save, such as 'Work in
progress: Tasks ' and 'Work in progress: Tasks none'. The PR's commit list then reads inconsistently.
Refuted: Dropped by the verifier. Out of scope. The subject of an empty-list commit is an output-format choice the
executor makes and a reviewer can check in the diff. The Files-edits test greps only the fixed prefix `Work in progress: Tasks`,
which any of the variants satisfies.

### R12-31 · minor · decisions

§ Approvals 2026-11-09 ('Claude opens the PR on andrelin/dotfiles and squash-merges it') and Task 13 deviation: Nothing
says what the squash commit's message on `main` should be. GitHub's default squash body lists every branch commit,
including the 'Work in progress' ones that the squash is meant to keep out of the readable history. The executor would
ask: does the squash commit take the PR description's title and body, or GitHub's default? Scenario: `gh pr merge --squash`
runs without `--subject` or `--body`. Main's single commit then carries a list of 'Work in progress: Tasks …' lines,
which undoes the reason for squashing.
Refuted: Dropped by the verifier. Out of scope. The squash commit's subject and body are command flags and output
format, chosen by the executor and visible to review. The plan already routes the PR description through
`writing-mr-descriptions`, and GitHub repository settings can make the PR title and body the squash default, so nothing
here needs a planning decision.

### R12-32 · minor · consistency

Task 17, Tests (Resume across a session-end commit; Customer level), against Task 15's `ai-log level` gate: Task 17's
personal-level test builds a scratch repo whose `origin` is a local bare repo. But Task 17 gates every commit and push
on `ai-log level`. Task 15 defines that gate to print `customer` for any origin other than `github.com/andrelin/…`,
`github.com/uptimeconsulting/…` or an `allow`-file host. A local-path origin is none of those. Run as the skill words
them, the session-end steps commit nothing and push nothing. The expected new `HEAD`, the empty `refs/checkpoints/` and
the fresh clone's state then never appear. The customer case's 'bare origin's refs unchanged' also assumes a bare origin
behind a `github.com` URL. Neither case says how to set that up, for example `remote.origin.pushurl` or
`url.<bare>.insteadOf`, so that `ai-log level` sees the allowlisted URL while pushes reach the bare repo. Separately,
the steps include `ai-log record`, and the test never sets `AI_LOG_DIR`. Once the level is fixed, the test would commit
and push a fixture entry to the real private log clone. Scenario: The executor builds Task 17 and runs the resume test
with `git remote add origin /tmp/x/bare.git`. `ai-log level` prints `customer`, so the skill's steps skip the commit and
push. Every assertion about the new `HEAD` and the clone fails. If the executor fixes this by pointing origin at
`git@github.com:andrelin/x.git` without a pushurl, the push goes to GitHub. Either way, `ai-log record` writes to
`$HOME/.ai-framework-log` unless `AI_LOG_DIR` is set.
Refuted: Downgraded from major by the verifier. The finding holds but I've downgraded it to minor. Task 15's gate prints
`customer` for any origin outside github.com/andrelin, github.com/uptimeconsulting or the `allow` file. Task 17's
'Resume across a session-end commit' test uses a local bare repo as origin and runs the steps 'as the skill words them',
so as written it commits and pushes nothing and its assertions fail. Task 15's own tests avoid this by using a
github.com URL, but they never push from the work repo, and Task 17 does. The fix is cheap and the executor can settle
it while implementing: set a github.com `url` and push through `remote.origin.pushurl` or `insteadOf` to the bare repo,
and set `AI_LOG_DIR`. A reviewer can check that setup in the diff. The risk of a fixture entry reaching the real log is
also small. `AI_LOG_PROJECTS` defaults to the real transcripts, and a session only counts when its `cwd` is inside the
scratch repo, which the running session's isn't, so `record` most likely exits 1 with nothing written. Nothing here is
costly to reverse, so it doesn't reach major.

### R12-33 · minor · consistency

Task 15, Tests › Counts (last line), and Task 15b, Tests › Redaction: Task 15's test list includes 'at company level the
plan's and branch's words redacted from the introspection (15b)'. That is Task 15b's `note` redaction, which does not
exist when Task 15 is built (build order 16, 15, 17, 15b). Task 15b's own Redaction test list leaves out the
company-level plan and branch words case, even though its Change lists it as a redaction kind. The test sits in a task
that can't run it and is missing from the task that builds the feature. Scenario: Task 15's implementer can't write or
pass a redaction test for `note` and either stalls or skips it. Task 15b's implementer follows 15b's test list and never
tests company-level plan and branch word redaction (R7-3, R7-40).

### R12-34 · minor · consistency

Task 15, Tests › Real data ('No real `record` runs here: the first is Task 15b's end to end'); § Approvals, 2026-11-05
block ('From Task 15b on'); Task 15b, Files (work-contexts.md text): This run builds Task 17 before Task 15b. §
Approvals also says the run's session ends before Task 17 is built follow Task 17's steps by hand. Both run a real
`ai-log record` that commits and pushes to the log repo. So the first real record is a session end after Task 15, not
Task 15b's end-to-end run. The standing yes for log pushes is dated 'From Task 15b on, after every plan', and Task 15b's
`work-contexts.md` text describes only the push after a plan's commit. Neither covers the session-end record that Task
17 adds, at the time it first runs. Scenario: A session ends between Task 15 and Task 15b. Following Task 17 by hand, it
runs `ai-log record`, which pushes to `andrelin/ai-framework-log` before the scope 'From Task 15b on' starts.
Afterwards, `work-contexts.md` tells readers that only post-commit records leave the machine.
Refuted: Partly refuted, the rest stands. The approval side is largely covered. The 2026-11-05 yes includes 'push to it
as Task 15 builds', and the user's own 'commit and ai log at the end of sessions too' covers a session-end `ai-log record`.
Two inconsistencies remain. Task 15 says 'No real `record` runs here: the first is Task 15b's end to end', but a
hand-run session end after Task 15 would be the first. And the `work-contexts.md` text in Task 15b, plus Task 17's edit
to that file, describe only the post-commit log push, not the session-end one. Both are cheap wording fixes.

### R12-35 · minor · consistency

Task 17, Change › At personal and company level ('Commit it on the branch', 2026-11-09, R11-15) vs § Approvals: Task 17
cites the user's 'Commit it on the branch' ruling as the authority for committing an untracked plan file at personal
level. No § Approvals block records that answer. Both 2026-11-09 blocks cover how a session end saves, but not this
point. Scenario: An executor or reviewer checks § Approvals for the yes that permits committing an untracked plan file,
and does not find it. Under the global rule that an approval covers only what it names, they stop to ask again, or treat
the step as unapproved.

### R12-36 · minor · consistency

Handover › Start next session here, item 0 and the opening paragraph: The Handover says the plan review 'ran 7 rounds'
and that the next session starts with 'round 10 of the plan review'. Item 0 lists the Task 17 rewrite as 'Not yet
reviewed, for round 10'. Yet Tasks 15 and 17 already cite R10-1, R10-9, R10-17, R10-30 and R11-15, so rounds 10 and 11
have run. The resume point no longer matches the task sections. Scenario: A resuming session reads 'first round 10' and
believes the Task 17 rewrite is unreviewed. It numbers its next round wrongly, or re-reviews work that rounds 10 and 11
already covered.

### R12-37 · minor · consistency

Implementation status table, rows 'Final code review' and '7': The 'Final code review' row reads ✅ DONE, with notes
about Task 14 and the 2026-11-02 run. This run still needs a final code review for Tasks 16, 15, 17, 15b and 13's fold,
and the Order and Handover both schedule it. Row 7 still says 'checkpointed on `ai-framework`', but the Handover says
that checkpoint was committed (`d88b6fa`) and its ref deleted. Scenario: `implementing-plans` skips rows that are
already ✅ DONE. Reading the stale ✅ on 'Final code review', a resumed run may treat the review as done and go straight
to the record, `git rm` and PR steps without a `Done (code):` for this run's tasks. A reader of row 7 also looks for a
checkpoint ref that no longer exists.
Refuted: The stale rows stand, but the failure scenario is weaker than claimed. The `implementing-plans` skill says the
work isn't finished until the final code review says `Done (code):`, and the Order and Handover both schedule the
review. So a resumed run probably wouldn't skip it just because of the ✅ row. Still, the row shows ✅ DONE with notes
only about earlier runs. Row 7 also still says 'checkpointed on `ai-framework`', though the Handover says that
checkpoint ref was deleted. The status table is what a resume reads, so this is a real but cheap inconsistency.

### R12-38 · minor · consistency

Task 13, Deviation (2026-11-03, code review R3) list of open items: The list is meant to catch every item still open
before the plan is deleted, but it is out of date. It still names 'Task 7's conflict sent to the user', which was ruled
and reworded on 2026-11-05 (§ Approvals, status row 7). It leaves out open items that the Handover's item 6 and items
1–4 name: the audit's recorded Mediums and Lows, R12-4, the unfinished reruns behind Tasks 5, 8 and 9's 🚧 PARTIAL rows,
closing `planechaser#73`, Task 3b's real-settings merge, and the unfiled `filing-learnings` detours. Scenario: The Task
13 executor drafts the issue from Task 13's list. The issue then includes a settled conflict and drops the PARTIAL
reruns and R12-4. After the `git rm`, those open items exist nowhere, which breaks the task's own requirement 'so
deleting the plan loses none of them'.

### R12-39 · minor · consistency

Task 15b, Tests › End to end ('Record here only that it ran, and the id'): The end-to-end check runs only at this plan's
final code review, after its commit. Under Task 13's deviation, the next steps are `ai-log record` and then the `git rm`
commit of this plan. The 'record here' note therefore lands in a file being deleted, and after the commit the review has
already passed. Task 15b also can't reach ✅ DONE on that test, because it runs after every task's review. Scenario: The
run records the id in `plan-ai-framework.md` after the final review's commit, then `git rm`s the file and squash-merges.
The evidence that 15b's step ran is lost unless it goes into the PR or Task 13's issue, which no step says to do.

### R12-40 · minor · consistency

Task 15, Interfaces (entry fields `commit`, `framework.dotfiles_commit`), against the 2026-11-09 squash-merge landing
(Task 17, § Approvals): The squash-merge ruling has not been folded back into Task 15's entry design. Every entry from a
session end, and the 15b record before the PR, stores branch commit shas: `commit` and the `dotfiles_commit` of
`bin/ai-log`'s tree. The squash merge removes those shas from `main`'s history. Follow-up 15d plans to group trends 'by
framework commit', which then points at commits unreachable from `main`. Scenario: After this run's PR is squash-merged
and the branch deleted, Task 15d groups entries by `dotfiles_commit`. None of the recorded shas resolve on `main`, so
the grouping by framework version can't be tied to a commit.
Refuted: Dropped by the verifier. Dropped. Follow-up 15d is a Sketch, not a task of this run, and how it groups by
framework commit is left for when it is detailed. Sketch detail is out of scope. A sha also still works as a grouping
key whether or not `main` reaches it. GitHub keeps PR head commits under `refs/pull/N/head` after a squash merge. And
only work done in the dotfiles repo on a branch records a branch sha as `dotfiles_commit`; entries from other repos
record whatever the dotfiles checkout is at. No concrete failure in this run's scope.

### R12-41 · nit · consistency

Follow-ups, not tasks of this run (opening line); Follow-up 15c notes: The opening line says 'neither can be built', but
the section holds three items: the Revisit, 15c and 15d. Two of 15c's notes now repeat what Task 15 already builds at
every level since R7-39 and R3-2: the plugin allowlist folding to `other`, and the `promptSource` list. Scenario: A
reader counting follow-ups for Task 13's issue is unsure whether the Revisit is included. When 15c is detailed later, it
may plan the plugin folding again as if it were new work.

### R12-42 · nit · consistency

§ Approvals, 2026-11-05 run block ('its skill line is where that yes outlives this plan'): This says Task 17 writes a
'skill line'. Task 17's Change specifies a paragraph in § Finish with the final review, plus three edits in place.
Scenario: A reviewer checking Task 17's diff against § Approvals expects a single line and flags the paragraph as scope
creep.

### R12-43 · minor · work context

Task 17, Tests, 'Resume across a session-end commit' (with Change, 'The level'): The test's work repo pushes to a local
bare repo as `origin`, but Task 17 takes the level from `ai-log level`. That gate prints `customer` for any origin that
is not `github.com/andrelin/…`, `github.com/uptimeconsulting/…` or a `<host>/<owner>` line in the clone's `allow` file.
A filesystem-path origin matches none of these, so the session-end steps 'run as the skill words them' would commit and
push nothing. The plan does not say how the scratch repo is meant to resolve as personal. Checked in a scratch repo:
`work-context.sh level` gives `company` for a local-path origin. On a machine whose `~/.claude-customers` lists
anything, the guard may even treat that origin as customer, as the 2026-10-23 detour in the Handover recorded. Scenario:
The executor builds the scratch repo with `git remote add origin <bare path>` and runs the steps. `ai-log level` prints
`customer`, so no commit and no push happen. `git merge-base`/`write-tree` hold trivially, but 'a second session end
still makes a commit, a new HEAD' fails, and the clone has no branch. The executor then either changes the gate or
improvises (for example `url.<bare>.pushInsteadOf git@github.com:andrelin/x.git`), and a reviewer can't tell whether the
personal path was really exercised. The plan should name the setup: an origin URL of `git@github.com:andrelin/x.git`
with `pushInsteadOf` (or `insteadOf`) to the bare repo, plus a throwaway `HOME` with no `~/.claude-customers`.
Refuted: Downgraded from major by the verifier. The defect is real. Task 15's gate prints `customer` for any origin that
is not on github.com/andrelin, github.com/uptimeconsulting or the clone's `allow` list. A filesystem-path origin matches
none of these, so the 'Resume across a session-end commit' test as written would commit and push nothing. Downgraded
from major: the approach itself doesn't rest on this. Only the test's scratch setup is missing a detail. The executor
finds out on the first run, and the fix is cheap and visible in the diff. One way is an origin of
`git@github.com:andrelin/x.git` with `pushInsteadOf` pointing at the bare repo, plus a throwaway HOME. Plain `insteadOf`
would not work, because `git remote get-url` applies it and the gate would again see a path.

### R12-44 · nit · work context

Task 17, Change, 'At personal and company level' (untracked plan committed at personal level): At personal level the
session end does `git add` on an untracked plan and its review files, commits them, and pushes the branch. It does this
for personal *public* repos too, under a standing yes. The plan relies on the later `git rm` and squash merge to keep
the files off `main`. But on GitHub a pushed branch and the PR's `refs/pull/N/head` keep those commits world-readable
after the squash. Review-findings files carry verbatim reviewer output and user quotes. writing-plans tracks personal
plans by default, so a plan that is untracked at personal level was probably left untracked on purpose. The step has no
check that the files meet the personal-public bar (no customer names, hostnames, internal tooling or secrets) before the
push. Scenario: In a personal public repo, the user keeps `plan-x.md` untracked because its findings quote a customer's
hostname from an earlier comparison. A part-way final report fires the session end. Claude adds the plan, commits, and
runs `git push -u origin <branch>`. The hostname is now public in the branch history and in the PR ref, even though the
squash later drops it from `main`. Either limit the untracked-file add to personal private repos, or run the public-bar
check on those files before the push.
Refuted: Downgraded from minor by the verifier. The user ruled on this exact case: 'Commit it on the branch' for an
untracked plan at personal level (2026-11-09, R11-15). The personal-public bar in the global CLAUDE.md already applies
to every commit Claude makes, so the skill doesn't need to restate it. writing-plans tracks personal plans by default,
so in a public repo they are pushed routinely anyway. The idea that a given untracked plan was left untracked to hide a
customer hostname is speculation. At most a wording reminder.

### R12-45 · minor · work context

Task 15b, Change, the introspection at company level; Approvals, 2026-11-05 'Entries store…': Until Task 15c exists, the
company-level introspection prose goes to the personal account's private repo after only mechanical redaction. That
redaction covers `~/.claude-customers` entries, remotes, folder names, and the words of the plan basename, first heading
and branch. Task 15 itself notes that company repos and plans are often named for an engagement, which is why it hashes
`repo` and `plan`. A client's name in the plan body or the work itself is caught only if the model obeys 'no customer
names'. The model terms pass that would catch it is deferred to 15c. The user chose to store company prose now, so this
is a residual risk, not a forbidden write. Even so, the plan builds and tests nothing to bound it. Scenario: An
`uptimeconsulting/…` repo's plan is named `plan-integration.md`, but its body and findings discuss 'Acme's SSO tenant'.
Acme is not in `~/.claude-customers`, because Uptime's own repo is not customer work. The introspection's 'Didn't'
bullet cites 'Acme SSO setup took 3 rounds'. None of the redaction kinds match, so the line is pushed to
`andrelin/ai-framework-log`. A cheap step now: also redact the words of the plan's `##` headings at company level, or
hold company prose until 15c.
Refuted: Dropped by the verifier. This is the user's explicit decision. The 2026-11-05 approval says the introspection
is stored at personal and company level until 15c, and the user's re-slice defers the model terms pass to Task 15c. The
text goes only to the user's own private repo, `andrelin/ai-framework-log`, and Task 15b's prompt already forbids
customer names. The finding itself calls it a residual risk the user accepted, not a forbidden write. Nothing names a
requirement that is broken.

### R12-46 · nit · work context

Task 17, Files, `claude/docs/work-contexts.md` edit: The doc line 'At every level, the workflow skills never commit on
their own' is to gain the session-end commit as 'its one exception'. That line is about every level, but the plan never
says the exception must be limited to personal and company level in the doc's wording. A reader of the published doc
could take the session-end commit as allowed at customer level. That contradicts the global § Work contexts and Task
17's own customer-level step. Scenario: An executor appends 'except the session-end commit (implementing-plans)' to the
every-level sentence. A later session at customer level reads `work-contexts.md`, takes the session end as permitted,
and tries a commit, which the guard then blocks. Worse, in a customer repo the guard resolves as company, the commit
goes through. The edit should say 'at personal and company level, through `ai-log level`'.
Refuted: Downgraded from minor by the verifier. The doc already carries a customer-level line ('On customer work
reviewing-in-rounds drafts the commit'). The behaviour is gated by the skill's `ai-log level` step, not by this doc
sentence. So the exception's exact wording is a phrasing choice the executor makes and a reviewer can check in the diff.
The scenario where a customer repo resolving as company gets a commit is not caused by the doc: `ai-log level` prints
`customer` for any unlisted origin. Only the wording is left.

### R12-47 · nit · work context

Approvals, 2026-11-09 'A company plan landing by "a PR" counts as squash-merged'; Task 17, Landing: At company level the
skill's landing rule says a branch holding session-end commits 'lands by a squash-merged PR'. The user's ruling treats
any company PR as squashed. A company repo whose PRs use merge commits would then carry the `Work in progress: Tasks …`
commits onto `main`. That conflicts with the company bar of 'a readable history before it reaches `main`'. The skill
line should keep the squash requirement explicit for company repos, or say to squash the PR when the repo allows it.
Scenario: An `uptimeconsulting` repo merges PRs with merge commits by default. Its session-end WIP commits and the
`--allow-empty` commits reach `main` through an ordinary merge, which breaks the showcase-history bar the company level
sets.
Refuted: Dropped by the verifier. Task 17's skill paragraph already states the landing rule outright: 'a branch holding
session-end commits lands by a squash-merged PR, never a fast-forward'. Its Landing bullet also says the work 'lands by
a squash-merged PR'. The squash requirement the finding asks for is therefore already in the skill line. The 'Any PR
counts as squashed' ruling is the user's own decision on reading the Approvals, and it does not weaken that skill text.
