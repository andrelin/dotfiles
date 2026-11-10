<!-- DOCTOC SKIP -->
# Review findings — plan-98-pm-config.md (plan)

## Round 1

### R1-1 · major · consistency, grounding

Task 4 needs origin as `<host>/<path>`, but no task produces it: `work-context.sh` prints no origin, and `parse_url` keeps only
host, owner and repo (losing GitLab subgroups). `bin/pm` would need its own URL parser, which the repo `CLAUDE.md` forbids,
and it could drift from the guard's.
Fixed: Task 3 adds `work-context.sh origin [dir]` printing `<host>/<path>` via a new `U_PATH` in `parse_url`; Task 4 uses it (Deviation 17).

### R1-2 · major · decisions, consistency

Task 1 deep-merges every object with `*`, so `tracker` merges key by key: a tree `{kind: jira, repo: ACME}` under a repo
`{kind: github}` yields a GitHub tracker with repo `ACME`, never re-validated, and the "no `repo` takes origin" rule never fires.
dotfiles#106 runs the filter verbatim, so the goldens would lock it in.
Fixed: a nearer `tracker` (and `follow_ups`) replaces the farther whole, and the merged `tracker` is validated again (Deviation 16).

### R1-3 · major · decisions

The end-to-end "`Write` attempted with the worktree's guard" reads two ways; the live hook is the main checkout's, so a real
`Write` succeeds and overwrites the user's scratch config, or the executor repoints the hook config without approval.
Fixed: the check pipes a synthetic PreToolUse JSON into the worktree's `work-context.sh pre-tool-use`, never a real `Write`;
the approval's reason reworded.

### R1-4 · minor · scope

Push right after Task 1 for an earlier jq 1.6 verdict.
Refuted as major: Tasks 2 and 3 don't consume the filter; the grounding reviewer verified jq 1.6 mechanics in `redhat/ubi9`.

### R1-5 · minor · scope

`adjustments` tier-clamp entries go beyond the Forgejo `project` resolve the user asked to report.

### R1-6 · minor · scope

Task 2 needs an out-of-scope line: the `has_marker` / `can-file-issue` opt-in stays untouched, dotfiles#106's to change.

### R1-7 · minor · scope, decisions

Task 4's `pm-config.md` must state that a `cp` from the config stays allowed (Decision 2), not the spec's sentence.

### R1-8 · minor · decisions, consistency

Task 5: a tree root's level and `guard_files` — the spec takes the repos below (or customer) and includes `dir`'s own file;
`no_repo_class` makes a dir outside any repo `company`, so "strictest of dir's own" breaks the personal-only tree test.

### R1-9 · minor · decisions

A relative `decisions_dir` from a tree file has no stated base.

### R1-10 · minor · grounding

Deviation 14 (unknown keys are an error) was never put to the user; a key from a newer checkout makes an older machine's `pm config` exit 1.

### R1-11 · minor · work context

The approval's reason "Claude can't write that name after Task 2" is false until the merge and a pull.
Refuted as major: the scratch repo is personal level and the user placing the file stays right.

### R1-12 · nit · several

Bare "PR #108"; Task 2 test-section line; table names vs headings; `shellcheck.yml` path; contradictory sample output;
"`auto` from dotfiles#106" and "`draft`, also after dotfiles#106" wording; "above or outside `$HOME`"; E2E bullet reads like text not JSON;
`schedule` keys free-form; shared exit 1 in `redact-check`; strict unknown keys reversible.

### R1-13 · dropped

Refuted: `fj` in host-kind tests (prints a kind word only, CI has no `fj`); Task 1 too wide (coherent, one file); Task 2 for all three
names (named in Deviation 4, spec asks it); `adjustments` contents, origin normalisation, `vocabulary` test, `jira` repo shape (left to the code);
a push after Task 1 (nothing depends on it).

## Round 2

### R2-1 · major · consistency

Task 1 accepts any `tracker.repo` holding a `/`, but Task 4 sends it to `level --url https://<tracker.repo>`: the natural
`owner/name` (or `example-client/x`) passes, `parse_url` misreads the host, `url_class` falls to `company`, and a customer tracker escapes its clamp.
Fixed: Task 1 validates a code-host `tracker.repo` as `<host>/<path>`, a dot in the host and two path segments; `owner/name` is an error, tested.

### R2-2 · major · decisions

Task 5 makes a tree root's level the strictest of `dir`'s own and the repos below; `no_repo_class` gives a non-repo directory `company`,
so a tree of personal repos comes out `company` and Task 5's own test fails; the spec takes the repos below only, or `customer` with none.
Fixed: Task 5 takes the strictest level of the repos below, or `customer` with none, then the tracker clamp; never `level <dir>`.

### R2-3 · major · decisions

Task 5's "`guard_files` as in Task 4" has no toplevel at a tree root: read literally it drops the root's own file, which a customer tree
keeps there, and its trigger differs from the spec's ("when that level came from the repos below, or the default"); dotfiles#106 reuses it verbatim.
Fixed: Task 5 states the spec's rule: chain files strictly below `$HOME`, `dir`'s own included,
or the whole chain when only the tracker clamp made it customer.

### R2-4 · major · decisions

A nearer `follow_ups` replaces the farther whole, against the spec's deep merge, with no Deviation;
a repo file setting only `backlog` loses the tree's `in_flight`.
Fixed: `follow_ups` objects deep-merge per the spec; a nearer value replaces only when the forms differ; test changed accordingly.

### R2-5 · minor · several

Grounding (late reviewer, no major): Deviations 14–16 are design choices never put to the user; Task 4 vs Deviation 13 on a repo outside `$HOME`;
strict `roadmap` keys against dotfiles#96's docs.
`owner/name` validation; ignored non-guard tiers in `adjustments`; `ai-log record` approval; customer `label` meaning; real-`HOME` `pm` output kept
out of tracked text; push after Task 1 needs an approval; narrower first slice; "`draft` now, dotfiles#106 raises it"; a "Not in this phase" list.

### R2-6 · nit · several

Relative `decisions_dir` base; E2E phrasing as JSON; table rows vs headings; dangling § citations; Task 2 test anchor; Deviation 13's condition;
`ACME` placeholder; customers-file extension named in the PR; `adjustments` as an interface; Task 4 sketch could split.

### R2-7 · dropped

Refuted: Task 5 `guard_files` as a consistency finding (a sketch's detail);
`origin` placement and `U_PATH` locals (left to the code; `main` runs in a subshell);
the "other non-merged values" sub-point (one plausible reading); `pm config` output format (JSON per spec).

## Round 3

### R3-1 · major · decisions, grounding

SSH host aliases: the guard supports them (`host_alias`, `customer_org`, around `work-context.sh:397-406`), but `origin` prints the alias
host verbatim and `host-kind` says `github` only for `github.com`, so an aliased GitHub clone (`git@github.com-work:owner/x.git`) gets
`origin_kind none`, `tracker.kind none` and every tier `draft`; a dotless alias containing `gitlab` gets kind `gitlab` and a defaulted
`repo` that fails the dot-in-host rule, so `pm config` exits 1 in a repo with no config file;
later phases can't use an alias host in `gh`/`glab`/`fj`.
Options: resolve the alias (`ssh -G <host>`'s `hostname`, or `host_alias` against the known hosts),
or accept and document that an aliased origin gives `none`.
User decision 2026-11-10: resolve with `ssh -G`.
Fixed: Task 3's `origin` resolves an scp or `ssh://` host via `ssh -G` (test override `WORK_CONTEXT_SSH_CONFIG`), with alias tests;
 Task 4 adds an aliased case.

### R3-2 · minor · several

Deviation 15 vs Task 1's `adjustments` scope; Deviation 14's unknown-key errors across machines (third time raised, never put to the user);
Deviation 13 vs Task 4 outside `$HOME`; Task 2 tests cover all three names; Decision 1 tested on a non-Forgejo kind; E2E assumes no
`~/.claude-pm.json`; customer ceiling wording in the reference doc; push after Task 1; an out-of-scope list for dotfiles#106; split Task 4;
`host-kind` running `fj` on every hook call once dotfiles#106 lands.

### R3-3 · nit · several

Table rows vs titles; dangling § references; one name for the tracker clamp; `origin` exit 1 mapped to an empty origin; `test_pm.sh` needs
its own `fj` stub; `vocabulary` in tests; references without titles;
`IN`/`INDEX` exist in jq 1.6; real `fj` in a host-kind test; scratch repo location.

### R3-4 · dropped

Refuted: the home file excluded at customer level (the spec decides it, parity with the guard); tie reasons, `repo` for other kinds,
E2E phrasing, `vocabulary` tests, `redact-check` exits (left to the code or already decided).

User decision after round 3: unknown keys in `.claude-pm.json` warn, never fail — applied as Deviation 14 and a `warnings` output list.

## Round 4

### R4-1 · minor · several

Every `origin` and `pm config` test sets `WORK_CONTEXT_SSH_CONFIG` (an empty scratch file outside the alias cases), since `ssh -G` reads the
real `~/.ssh/config` whatever `$HOME` is; the "without the stub" `fj` case uses a second stub or an `fj`-free `PATH`; the end-to-end
`pm config` runs with a temp `HOME` or checks named keys only, never quoting output that may hold redact names; Deviation 13 vs Task 4
outside `$HOME`, and Deviation 13 as a user-visible choice; `adjustments` silent on keys dropped by the customer restriction and on
tracker-kind clamps of defaults; a relative `decisions_dir`'s base; the tie reason between ceilings; push or a `ubi9` run after Task 1;
the Revisit checks the two-pass flow against Task 1's call form; this phase builds only the `draft` ceiling; out of scope: the guard
reading the config and `bin/pm` beyond `config` and `redact-check`; move the git-tracked `redact` check to Task 6; Task 1 size;
`jq empty` doesn't name the file on 1.6, so `pm` prefixes it; git writes of a tracked config are an accepted gap; dangling § names.

### R4-2 · nit · several

Status table rows vs headings; Task 2 tightens the existing names (say so in the commit); fixture inputs vs goldens globs; bare "PR #108";
the end-to-end step reads like YAML; `IN`/`INDEX` exist in jq 1.6; GitHub Enterprise gets `none`; scratch repo location.
