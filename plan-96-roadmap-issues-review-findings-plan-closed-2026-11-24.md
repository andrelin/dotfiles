<!-- DOCTOC SKIP -->
# Review findings — plan-96-roadmap-issues.md (plan)

## Round 1

### R1-1 · major · scope and slicing, decisions, grounding

Task 6's fresh session on a scratch clone loads `~/.claude`, which links to the `~/.dotfiles` main checkout:
no `managing-roadmaps`, its `issue-commands.md` pointer lands on a copy with no § Roadmaps, and the installed
`writing-mr-descriptions` still bans `Closes`. Task 4's re-score of `writing-issues` and `writing-plans` can't see the
new skill either, and with the default `DOTFILES` it moves the live copies out machine-wide, unapproved;
the skill's own run needs `DOTFILES="$PWD"`.
User decision 2026-11-10: Task 6 runs its session under a scratch `HOME` whose `.claude/` links to the worktree's `claude/` entries.
Fixed: Task 6 checks login under a scratch `HOME` linking the worktree's `claude/` entries, else runs after the merge;
Task 4 runs with `DOTFILES="$PWD"` and drops the re-score of `writing-issues` and `writing-plans`; recorded in § Approvals.

### R1-2 · major · decisions

Task 2 makes a closing keyword mandatory in a PR that ships an issue's work; the user's decision and the acceptance
criterion only allow it in every non-bot PR, and the skill is global.
Fixed: Task 2 allows a closing keyword in any PR not targeting a bot PR, never requires one, with `Closes andrelin/dotfiles#96` as the example.

### R1-3 · minor · decisions

Whether the skill spells out per-level behaviour like `writing-issues`, or defers to dotfiles#99 and dotfiles#106.
Refuted as major: § Work contexts and § Approvals outrank the skill and the guard blocks, so no forbidden write follows.

### R1-4 · minor · decisions

The model bullet's "a feature is an epic" wording should match the dotfiles labels (`kind/feature` = a phase or piece of new behaviour).
Refuted as major: the worked example's labels settle the reading.

### R1-5 · minor · decisions

Which Projects v2 Status option means in progress and in review; a default board has no "In review".

### R1-6 · minor · decisions

Making an existing Forgejo label exclusive is a separate write from creating one; `kind/*` beside or instead of `bug`/`enhancement` on GitHub.

### R1-7 · minor · decisions

If a re-score drops, revise the new description, never the other skills'.

### R1-8 · minor · scope, consistency, grounding

Where `roadmap.md` belongs: `writing-plans` (description, body, eval 1.5) and `plan-files.md`'s `paths:` claim it, while Task 5 says a
long-lived roadmap never lives in a plan file; one line must separate a work-scoped `roadmap.md` from a product roadmap.

### R1-9 · minor · scope

Task 6, the only behavioural test of the skill, runs after Task 4's costly eval; cheap to reorder.

### R1-10 · minor · work context

Only a policy forbids the Forgejo host in the verification log; add a mechanical host check of the plan and PR body before each session-end commit.
Refuted as major: the global constraints already cover every committed cell.

### R1-11 · minor · work context

The Forgejo scratch repo resolves to company level, not personal; name it and exempt the scratch repo from the showcase bar;
Task 1 step 1 checks each clone's level, not only `can-file-issue`.

### R1-12 · minor · consistency

Task 3 and the Revisit don't carry the user's `project` and `labels` mode decisions.

### R1-13 · minor · consistency

Task 5's test pins the skill name once per file, but the sketched edits give two in `writing-plans` and none in `staged-workflow.md`.

### R1-14 · minor · consistency

Task 2's line references in `dependency-bot-prs` are off by one.

### R1-15 · minor · grounding

Acceptance criterion 4 says every form in `issue-commands.md`; Task 1 verifies only § Roadmaps.

### R1-16 · minor · grounding

What the skill does on a Forgejo repo with dependencies disabled.

### R1-17 · minor · grounding

§ Roadmaps could push `issue-commands.md`, which every filing loads, toward its 200-line cap; a split needs the user's nod.

### R1-18 · nit · several

Placeholders `Closes #<n>` beside the no-placeholder rule; Task 2's rule under § Title mechanics; Revisit restates the decided pin;
Task 1's claim about Task 3 naming subsections; bare-number references;
"company Forgejo instance" wording; Task 3 should name Task 6 as its behavioural test.

### R1-19 · dropped

Refuted: Task 1 slicing (already first, gated by the Revisit); Forgejo exclusive-label edit not asked for (it is, for existing labels);
duplicate closing checks (different requirements); Task 6 brief approvals (a sketch's detail); phase-to-epic lookup (no flow needs it);
blocker-closed ready case, `--exclusive` flag, `labels --add` pin (left to the code).

## Round 2

### R2-1 · major · grounding, work context

Under a scratch `HOME` (verified in a temp dir) `gh` and `fj` are logged out, git has no identity, `~/.ssh` is gone and
`~/.claude/settings.json`, which registers the guard's hooks, is not among the linked `claude/` entries: Task 6's only gate,
Claude's login, passes and the session then can't push, file or open a PR, or runs unguarded, inviting credential copying.
User decision 2026-11-10: Task 6 runs as a fresh subagent in the implementing session, told to follow the worktree's skill and docs by path.
Fixed: Task 6 is one fresh subagent per scratch clone, reading the worktree's `claude/` for every `~/.claude/` path;
the scratch-`HOME` approval and decision replaced.

### R2-2 · major · decisions

The Revisit only folds Task 1's results into Task 3; where an acceptance operation (an epic's phases with state, ready work,
a linked open PR) has no Forgejo form, or only a stand-in the user hasn't seen,
the executor narrows the issue silently while the PR says `Closes #96`.
Fixed: the Revisit stops for the user on such an operation, listing what Forgejo can and can't do, and on any result contradicting a settled decision.

### R2-3 · minor · several

Cite dotfiles#98's `pm config` contract in Task 3; status transitions and Project option mapping for `labels` and `project`;
write down a phase's `kind/`, `area/` and milestone rule; closing keywords in titles and commits; who picks among ready phases;
`area/` names, colours and descriptions proposed for approval; guard absence and host grep before each push;
"company Forgejo instance" wording; Forgejo scratch repo private and `fj` writes from its clone only; login check and PR body at Completion;
a stop for results contradicting a settled decision; `labels` and `project` not exercised end to end; setup step not exercised;
temporary versus long-lived `roadmap.md`; Task 3's dropped `project` fallback and stale "unpinned"; Task 5's name-count test;
Forgejo limits inside the first 100 lines; the worked example must not name the retired plan file; the migration's retiring PR not exercised;
ready work returns the Renovate dashboard, so define it positively; eval 1.5's owner.

### R2-4 · nit · several

Neutral example string; GitHub counterpart of the cross-epic rule; reason for the extra pointers; line references; rule placement under
§ Title mechanics; "never required" against the skill's use.

### R2-5 · dropped

Refuted: Task 1 split (acceptance needs every `gh` form anyway); dangling skill name before Task 3 (squash merge); Task 2's position;
the `fj` target rule (depend's targets are new); the `labels --add` pin and `command -v pm` (left to the code); Forgejo ready-work Revisit
(already decided); eval JSON and scores (already covered).

## Round 3

### R3-1 · major · decisions

The Goal says a phase's PR closes its issue, but Task 2 makes a closing keyword optional and only `managing-roadmaps` says a phase PR
uses one; the PR is drafted through `ai plan` → `writing-plans` → `implementing-plans` → `writing-mr-descriptions`, where that skill
isn't loaded, so a phase PR merges with `(#n)` and the phase stays open; Task 6's by-path subagent would hide it.
Fixed: Task 5's `writing-plans` § Writing one line has a phase's plan record in `## Approvals` that the PR carries `Closes #<phase>`,
pinned by its test.

### R3-2 · minor · several

The skill's customer-level rule for writes beyond `issue create` (`fj` unguarded); ready work returns the Renovate dashboard
(`-is:blocked has:parent-issue` verified as the fix); `roadmap.md` owner wording (fourth time, always minor); host grep before push;
`Closes andrelin/dotfiles#96` copied into a scratch PR would close dotfiles#96; one subagent or two in the approval; status timing;
ready work vs in-progress issues; milestone placement; converting Forgejo labels; Task 6 after Task 4; a stop past 200 lines.

### R3-3 · nit · several

Task 1's claim about Task 3 naming subsections; line references; file map row; stale "unpinned"; worked example true once
dotfiles#108 merges; scratch Forgejo repo resolves company; private visibility for the Forgejo repo and project; untraced pointers.

### R3-4 · dropped

Refuted: the `pm config` interface (pinned by dotfiles#98); a phase's labels (worked example); `ai plan` on an epic, test phrase,
name counts, `fj milestone` editor (left to the code); Task 3's missing decisions (a sketch's detail); commits (covered by
`dependency-bot-prs`); `labels` timing (sketch); a `level` call per clone (the guard blocks); Task 6 vs Task 1 (different requirements).

## Round 4

### R4-1 · minor · several

The skill's work-context line for writes beyond `issue create` (fj unguarded; raised every round, minor each time); every `fj` write in Tasks 1 and 6
names the scratch `<owner>/<repo>` explicitly; "never required" against a phase PR's `Closes`; closing keywords on customer MRs;
the `Closes andrelin/dotfiles#96` example copied into a scratch PR; host grep over the plan and PR body; a phase's labels for a standalone feature;
status timing and Project option mapping; ready work vs assigned issues; when to offer closing an epic; how to tell a repo uses milestones;
Forgejo exclusivity fallback; phase body contents; Task 6 order and log ownership; Task 1 docs before the Revisit gate; Task 1 pins;
Task 3's missing decisions; `project` mode not exercised end to end; the migration's retiring PR not exercised.

### R4-2 · nit · several

Inline `pm config` command vs the pointer rule; a generic `pm` name; completion work inside Task 6; a pointer before its target; Task 5 extras
and test count; line references; stale "unpinned"; the intro's `can-file-issue` precondition; the Forgejo version in public text; scratch repo level.

### R4-3 · dropped

Refuted: the `pm config` interface (dotfiles#98 pins JSON, exit 0 with no file);
the `## Labels` creation ban (scoped to filing); the Task 5 count (left to the code).

User decision after round 4: a roadmap of any lifespan goes to issues under `managing-roadmaps`; `writing-plans` drops `roadmap.md`
from its description, which is re-scored, and eval query 1.5 moves to the new skill's should-fire set.
