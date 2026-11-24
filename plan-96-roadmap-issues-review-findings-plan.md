<!-- DOCTOC SKIP -->
# Review findings — plan-96-roadmap-issues.md (plan)

## Round 1

### R1-1 · major · grounding, decisions an executor can't make

dotfiles#98 says the config holds roadmap status "`derived` by default" and `pm config` merges, defaults and validates.
Once #98 lands, `pm config | jq -r '.roadmap.status // empty'` prints `derived` in every repo,
so the ruling's precedence never reaches a repo's own status practice, such as status labels on the user's company Forgejo.
Verifiers: kept by both; the ruling answers it (#98 must leave `roadmap.status` absent unless a file sets it),
but telling #98, which is being implemented in another worktree, is a platform write the user approves.
Fixed: on the user's decision of 2026-11-24, the Spec's status precedence states the constraint on #98,
§ Approvals records the comment, and the comment is posted on andrelin/dotfiles#98.

### R1-2 · major · grounding, decisions an executor can't make

Status moves (in-progress at start, in-review at PR open, the project Status edit) and the assignee that Forgejo `derived` reads
are written by `managing-roadmaps`, but a phase is worked through `ai plan`, `implementing-plans` and `writing-mr-descriptions`,
where the skill isn't loaded; only the closing line is routed through the phase plan's `## Approvals`.
In real use `labels` and `project` modes never advance and Forgejo `derived` never shows in progress; Task 6 hides it.
Verifiers: kept by both.
Fixed: on the user's decision of 2026-11-24, Task 5 has a phase plan record its status writes in `## Approvals`
and `implementing-plans` run them from that yes, at the start and when the PR opens; the file map adds `implementing-plans`.

### R1-3 · major · work context

Task 6's subagents can't put the skill's approval question to the user, and an agent's brief is never the user's consent,
so "creates it after approval" either blocks the run or tests no gate; the same holds for the one-question write list in all three runs.
Verifier: kept, scope widened to all three runs. (Grounding's verifier downgraded its twin to minor: the 2026-11-24 approval exists.)
Fixed: Task 6 now says each subagent stops at its proposal and write list and hands back; the session checks it against
§ Approvals, and resumes the subagent with the recorded approval named, or asks the user for anything not covered.

### R1-4 · major · consistency

Task 6 expects `kind/`, `area/` and `status/` in use on both scratch repos and checks derived status on both,
but live state differs: on GitHub issue 4 is open in project 2 with a Status, which implies `project` mode;
on both repos almost nothing open carries the labels; Forgejo, with no open status labels, does give `derived`.
Verifier: kept, scenario corrected from live state.
Fixed: Task 6 now has the session read each repo's live state before dispatch and state the expected mapping and status mode
in the brief; the pass is the skill choosing that mode, with the derived check only where the expected mode is `derived`.

### Minor and nit, not fixed this round

- minor · decisions: R1 F2 tree-level `.claude-pm.json` vs repo practice (one line in the skill); F5 propose only the roles
  the request uses; F7 `Part of` line only by convention; F11 #98's write tiers out of scope, said in one line.
- minor · grounding: GitHub default labels (`bug`, `enhancement`) aren't a type scheme unless in use; issue-commands forms hard-code
  fallback names (also consistency 2); 32–34 leftover open issues flood ready work; epic/phase bodies vs `writing-issues` sections.
- minor · consistency: Task 5's test pins `managing-roadmaps` once though `writing-plans` names it twice.
- minor · scope: practice run late in order; GitHub side of the ruling unexercised; no discovery form for linking convention;
  GitHub issue types out of scope unstated; `## Forgejo limits` duplicates other sections.
- nit: stale "pending"/conditional practice-approval wording; "company Forgejo instance" wording; worked-example heading;
  query 1.5 misquoted; Goal not reframed; Approvals "a fresh subagent" singular; Approach line; closing-line example.
- Dropped by verifiers: platform PR-body read (needed); pm-missing reading (answered by the plan); ready-signal reading (intersect);
  Task 5 test count and Task 6 milestone (left to the code); heading pin of the migration section (test assertion).

## Round 2

### R2-1 · blocking · decisions, grounding (D7, G1)

Task 5's `implementing-plans` line runs a phase plan's recorded status writes (labels, project Status, assignment) from a recorded yes,
and its `writing-plans` line records them, with no work-context check; at customer level on Forgejo the `fj` label edit is unguarded,
yet the global § *Work contexts* allows only `issue create` there.
Fixed: Task 5 — both lines hold the work-context line themselves; at customer level status writes are drafted, never recorded or run; pinned.

### R2-2 · major · scope, decisions (S1, D2; grounding G2 downgraded to minor)

The Spec calls the settled model the user's recorded convention for their personal repos, but nothing records it where the skill reads;
an executor either applies it unasked (the fallback the ruling forbids) or asks on every personal repo, contradicting the claim.
Fixed: Spec and Task 3 — the model is recorded in the personal layer (the skill's section says so) and applied at personal level unasked;
the bulk question is for company and customer contexts; Task 6's GitHub run now fails if it asks.

### R2-3 · major · work context (W1)

The Forgejo scratch repos resolve as company level (`work-context.sh` classifies personal only for the personal account on github.com),
yet Task 6 records their answers in a pushed `CLAUDE.md`; a correct run writes an excluded `CLAUDE.local.md` and is judged a failure.
Fixed: Task 6 — levels confirmed before dispatch; Forgejo answers in an excluded `CLAUDE.local.md`, read back by a fresh subagent;
the approved `CLAUDE.md` push applies to the GitHub repo only.

### Minor and nit, verified, left to the implementation

Minor: S3 status-writes path never exercised; S4 and C5 `issue-commands.md` `### Status` calls `derived` the default;
S5 GitHub new phases in no project need status label names; C2 the skill must carry the practice-detection rules Task 6 grades on;
C4 and D8 Task 5's stale "by default `Closes #<phase>`" beside the no-fallback deviation; C6 practice repo lacks area and milestones;
W2 (same as R2-1); W4 plan text names the company Forgejo instance and its status practice; D1 and G4 `pm config` above context practice;
D4 how a personal record lands; D6 ambiguous roles in the bulk question; D11 wiki never read; G3 company record per clone and machine;
G5 the cross-repo `pm config` destination rests on #98 changing.
Nit: S8, C3, C7, D10, D13, W5, G8.
Refuted: S2, S6, S7 (scope); C1 (issue 4 is open in project 2, no status label), C8, C9; W3, W6; D3, D5, D9, D12; G6, G7.

## Round 3

### R3-1 · major · consistency (C1; decisions D1 downgraded to minor)

Task 6's GitHub expectation read "`project` mode via project 2, else `derived`", against Task 3 § *Status*, the 2026-11-10 decision
and Task 6's own earlier line, all of which send a new phase in no project to `labels`; a correct run would fail it.
Fixed: Task 6 now expects `labels` for a new phase in no project, and fails the run only if it asks the conventions bulk question.

### R3-2 · major · grounding (G1)

Every GitHub repo carries default labels (`bug`, `enhancement`, `documentation`), dotfiles and the GitHub scratch repo included,
and "in use on open issues" was defined only for status; read literally, type has two candidate schemes, the recommended `kind/` set is
a parallel scheme everywhere, and the personal GitHub run asks and fails.
Fixed: Spec § *The repo's own practice first* ruling — a label is the repo's practice only when open issues carry it, for every role;
an unused set such as GitHub's defaults covers no role; Task 3's section states the rule.

### Minor and nit, verified, left to the implementation

Minor: S1 Forgejo discovery forms have `fj` stand-ins (`milestone search`, `pr view <id> body`); S2 the `implementing-plans` status path
is never run in Task 6; S3 two owners of the status moves; S4 the ten sections' fit within 100 lines; S6 wiki scope;
D1 (same as R3-1), D2 `pm config` above context practice, D3 Task 3 drops the "until #98, record per repo" clause, D4 (covered by R3-2),
D5 Task 5's unmarked "by default `Closes #<phase>`", D6 whether the label-set answer approves creation;
C2 `issue-commands.md` forms hard-code the recommended names, C3 practice repo "proposes only `Type/Epic`", C6 (same as D5), C8 (same as D3);
G2 prefer the tree-root `CLAUDE.local.md` for company, G3 `project`-mode threshold, G4 the cross-repo `pm config` record is the user's write;
work context, unverified as it reported no major: label examples may echo a real scheme, grep the log and PR body for the host,
`## Setting up` and `## Closing an epic` should restate the customer-level draft rule.
Nit: S5, S9, D9, D10, C4, G5, G6, G7, and two work-context nits (Global constraints omit the #98 comment; read closing lines from git log first).
Refuted: S7, S8, S10; D7, D8; C5, C7, C9–C12.
