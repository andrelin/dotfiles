<!-- DOCTOC SKIP -->

# Review findings (plan)

## Round 1

Scoped to Tasks 4, 12, 11 and 7, the rest of the plan read as context only. Five lenses.

### R1-1 · major · grounding, decisions, work context

Task 4's `writing-skills` and `diagnosing-superpowers` rows justify drafting by "a third-party target the guard blocks
at every level"; the guard rates an unlisted owner company and lets `gh issue/pr create -R obra/superpowers` through.
The doc would teach a backstop that isn't there.
Refuted in part (grounding, work context): the "hook blocks the forbidden steps regardless" sentence is about
customer targets, where it holds; kept major by two verifiers for the rows.
Fixed: both rows give "draft it" its own reason and say the guard doesn't catch a third-party target; the hook
sentence is scoped to customer targets. No guard change.

### R1-2 · major · scope

Task 11's CI test can first run on `main`: nothing is pushed before the fast-forward, so the Linux install and its
error scan are first seen there.
Refuted in part (consistency, downgraded to minor): a red leg on a personal repo is fixed by a follow-up commit.
Fixed: Task 11 runs the Ubuntu and RHEL legs' install and error scan in Docker before its task review; CI on `main`
after the push is the last check, which the task review can't tick.

### R1-3 · major · scope, decisions, consistency

Task 7's fold-in asks for a trim of `implementing-plans` into a doc, which its bounded-fix rule forbids (125 counted
lines, under the cap); no doc is named, and "117" is stale.
Fixed: the trim is named as the one exception, into `claude/docs/implementing-plans-reference.md`, in Task 7's
Files and the File map.

### R1-4 · minor · work context

Task 11's manual commit-block check uses origin `example-client/x` with no `~/.claude-customers`, so it resolves as
company and the commit passes. Downgraded from major: a by-hand check, cheap to fix with the approved throwaway `HOME`.

### R1-5 · minor · scope, decisions, consistency

Docker is named in § *Approvals* for Task 11 but no step says what runs in it. Settled by R1-2's fix.

### R1-6 · minor · scope

Task 7 scores stage skills while Tasks 5, 8 and 9's reruns may still change them.

### R1-7 · minor · scope, consistency

Task 7's status notes (scores, the `unslop` choice, the what-and-when result) aren't in Task 13's fold list.

### R1-8 · minor · scope, decisions

Task 7's `unslop` pointer option is a body edit the bounded-fix rule sends to "recorded, not made"; who decides is unsaid.

### R1-9 · minor · decisions

Task 7: if the what-and-when candidate scores best, adopting it and "the user's call" conflict; read as stop and ask.

### R1-10 · minor · consistency, grounding

Task 7 runs `skill-trigger-eval`, which moves the scored skill out of `claude/skills/`, inside the driver that uses
`implementing-plans`, `reviewing-in-rounds` and `writing-plans`; run evals in the foreground, one at a time, and
check `git status -- claude/skills` after.

### R1-11 · minor · scope, consistency

The order paragraph and handover say 4 → 7 → 11; this run builds 11 before 7. The handover's steps 1–3 sit before them.

### R1-12 · minor · consistency

Task 6b's requirement 5, which Task 7 cites, maps `implementing-plans` to `AI_MODEL_IMPLEMENT`; the script now uses
`AI_MODEL_REVIEW`.

### R1-13 · minor · consistency

Task 7's Files line omits the eval JSON files its Change creates.

### R1-14 · minor · consistency, grounding

Task 11's anchors: the source guard is at `bin/dotfiles:311`, the cache read at `:338`.

### R1-15 · minor · grounding

Task 11: `tests-wsl.yml` installs `jq` through `init/31_homebrew_recipes.sh` when `CI` is set, so the no-`jq` path
isn't what runs there.

### R1-16 · minor · grounding

Task 12 doesn't update Tip 24.3's list of pre-commit steps; its `docs/d.md` pre-commit fixture needs a doctoc marker.

### R1-17 · minor · decisions

Task 11's replacement tip sentence is wrong for a Linux machine that ticked the old name by hand.

### R1-18 · minor · decisions

Task 4's new `work-contexts.md` line sits under § *personal private* only, though it holds at every level.

### R1-19 · minor · decisions, consistency

Task 11's `git grep 52_macos_claude` sweep would rewrite the plan's own mentions. Kept as nit by consistency.

### R1-20 · nit · various

Task 4's company sentence after R1-1; `requesting-code-review` "reads only" vs its `git worktree add`;
`CLAUDE.md` naming one counterpart; `migrate_init_selection`'s permanence; the stale "117".

Dropped: Task 7 audit notes leaking machine-local content and the eval-set review's public-repo check (§ *Global
constraints* already bars both); `/doctor prompt-audit`'s existence (present in 2.1.309); Tasks 4 and 12 sharing the
tree (no overlapping files); `--cached` (left to the code); "Task 4 wording" (unsupported).

## Round 2

### R2-1 · major · work context

Task 4 lists `receiving-code-review` among the skills that never write a remote, but its *GitHub Thread Replies*
step posts with `gh api …/replies`, a platform write the global § *Code review* forbids on customer work; the
check's grep can't see `gh api`.

Fixed: a table row for it (draft the replies, post nothing), counts 9 and 6, `gh api` and `glab` in the grep.

### R2-2 · major · scope, consistency

Task 7 runs `skill-trigger-eval`, which hides the scored skill machine-wide, on three skills driving this run;
an agent dispatched meanwhile, or a crash, leaves the run on the plugin's skill or none. R1-10 raised as major.
Refuted in part (scope, downgraded to minor): the batch rule and a foreground eval keep them apart; kept major by
consistency.

Fixed: each eval in the foreground, one at a time, after the trim, no agent in flight, `git status -- claude/skills`
clean after each or the run stops.

### R2-3 · minor · decisions, work context, consistency

Re-raised from round 1 and downgraded by their verifiers: the what-and-when winner (R1-9), the `unslop` owner
(R1-8), Task 11's manual commit-block check (R1-4), machine-local audit findings.
Settled anyway by the user's decisions of 2026-11-02 where they were theirs: what-and-when recorded, never adopted;
the `unslop` pointer made; fixes in tracked files only.

### R2-4 · minor · work context

Task 4's `finishing-a-development-branch` row stops before a merge into base, while the rewritten paragraph names a
clean local merge as allowed.

### R2-5 · minor · work context

The 2026-11-02 approval replaces the bullet that kept the user's own uncommitted edits out of the commit.

### R2-6 · minor · work context

Task 11's Docker run "from this working tree" would copy revealed git-secret files into the containers; build from
tracked files.

### R2-7 · minor · grounding

Task 12's default set skips `claude/skills/unslop/`, the one third-party agent-loaded file; scanning isn't editing.
Downgraded from major: cheap to reverse.

### R2-8 · minor · grounding

Task 4's `brainstorming` row names the spec `plan-*-spec.md`, which reviewers may not open.

### R2-9 · minor · scope, decisions, consistency

Task 7 bundles four deliverables; the trim's target size; `writing-plans.json` extended or not; Task 12's scoped
tests run git in temp repos against "parallel subagents never run git"; the order paragraph, Task 11's "so last" and
the handover's steps 1–3 against the run; Task 6b's requirement 5 model; the sweep over the plan's own mentions.

### R2-10 · nit · various

Stale line numbers in Task 11 and § *Global constraints*; Task 12's "not in parallel with Task 10"; "reads only".

Dropped: Task 4's company sentence (refuted, though the user then ruled customer-only); the eval queries' public-repo
rule (already in § *Global constraints*); `/doctor prompt-audit` runnable by Claude (unsupported);
`migrate_init_selection`'s size (unsupported); Task 11's portability grep scope (no failure scenario).

## Round 3

### R3-1 · blocking · consistency, grounding

Task 7's eval check required `git status -- claude/skills` to be clean after each eval, but the task's own trim,
the `unslop` pointer and any adopted description sit uncommitted there, so the run would stop after the first eval.
Introduced by R2-2's fix.

Fixed: the porcelain status after each eval must match the one taken just before it, and the skill be back.

### R3-2 · minor · grounding, decisions, verified down from major

The `unslop` pointer must have Claude read `~/.claude/skills/unslop/SKILL.md` and apply it, since
`disable-model-invocation: true` blocks a Skill call; `writing-mr-descriptions/SKILL.md` is missing from Task 7's
Files and the File map.

### R3-3 · minor · work context, verified down from major

Task 11's manual commit-block check, raised a third time (R1-4, R2-3); also Task 2's at the same gap.

### R3-4 · minor · decisions, scope, verified down from major

The 52_macos_claude sweep includes the plan; the trim has no behavioural check (rerun one Task 9 toy case after
it); the run order — `implementing-plans` works in plan order, 4 → 7 → 11 → 12, not this run's 4 ∥ 12 → 11 → 7.

### R3-5 · minor · various

Task 7's slicing and hand-offs; the what-and-when result has no home after Task 13; Task 11's row status with CI and
manual checks pending; the WSL `jq` claim; stale anchors; Task 6b's requirement 5 model; the handover's steps 1–3;
Task 4's `CLAUDE.md` line, `work-contexts.md` placement and table scope; Task 7's "audit only", trim target and
"beats" bar.

### R3-6 · nit · various

Eight nits, among them Task 7's bounded-fix checks using plain `git diff`, vacuous once staged.

Dropped: the approval's keep-out clause (`reviewing-in-rounds`' completion already keeps the user's edits out); the
eval queries' and machine-local findings' public-repo rules (already covered); Task 7's hand-offs (covered by
*By hand*); `--platform` and bash 5 under pre-commit (left to the code).

## Round 4

A confirmation round after round 3's re-evaluation. Grounding, consistency and work context found nothing above minor.

### R4-1 · minor · scope, verified down from major

Task 7's trim could move the *Overridden in SDD 7.0.0* paragraph behind a conditional pointer, letting a later driver
follow SDD's setup, final review or model selection. Refuted as major: the no-commit rule also lives in the body, and
the move is cheap to reverse. Settle while implementing: trim the *By hand* and *Models* bullets, keep the overrides.

### R4-2 · minor · decisions, verified down from major

A CI fix on `main` after the push, and `unslop` against `writing-mr-descriptions`' style: both settled by the user on
2026-11-02 and recorded. The plan's status notes and the findings file are never staged (dropped).

### R4-3 · minor · various

The "beats" bar per query kind; "the audit" naming three things; plan files outside Task 12's default set; Task 12's
fallback edit to `tests.yml` outside its Files; the run ending in one commit, since Tasks 11 and 12 share
`tips/24_claude_code.md`; the handover's step 4 still reading 4 → 7 → 11; Task 11's "so last"; the WSL `jq` claim;
Docker on arm64; `migrate_init_selection` against a tip line; the `docs/d.md` fixture needing a doctoc marker.

### R4-4 · nit · various

The File map's `implementing-plans/SKILL.md` row lacks 7; a quoted anchor split across two lines; "13 names" now 14.
