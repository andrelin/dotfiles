<!-- DOCTOC SKIP -->

# AI framework

Tools that measure how the staged Claude workflow (`ai`, `implementing-plans`, the review skills) performs.

## Tip 25.1: `ai-log`

Records counts for one plan into the private log repo `andrelin/ai-framework-log`: tokens, user turns,
tools, skills, agents, workflow phases and review-log findings per lens, never prompts or any other text.
`record` ends by asking for a short introspection (`## Worked`, `## Didn't`, `## Cut candidates`, each point with its evidence),
and `note` redacts it before it is stored: customers in `~/.claude-customers`, the repo's remotes and folders, hostnames,
emails, addresses, paths, URLs and tokens each become a placeholder such as `[customer]`, and at company level so do the plan's and branch's words.
Plurals match, but a name run into another word (`acmecorp`) and a lone `/secretclient` path are known gaps.
Other known gaps: a two-label unlisted host whose TLD is `md`, `sh`, `py` or `rs` (`unlisted.md`; three labels or more are caught),
unicode lookalikes and an unlisted single-label host.
Customer work is deferred: nothing is read or written.
Needs bash 5 and `jq`: on a stock macOS shell `env bash` is 3.2 and `ai-log` exits 2 with a bash-version message,
so install bash with Homebrew.
Exit codes: 0 written (or customer work deferred), 1 nothing written (no plan, no session or assistant record, a given
commit no newer than the window start, a record whose tool, skill, agent, model, plugin or workflow-phase names hold a
customer from `~/.claude-customers`, an unknown `note` id, or `note` at company level that finds no plan in the repo to
redact by), 2 usage, a missing clone or one whose origin is not the log repo, or `note` with empty input or a missing
heading, 3 an internal failure.
At personal level tool, agent and skill names are stored as they are: a user-scope MCP server, agent or command named for a
customer is stored unless `~/.claude-customers` lists that name, which then refuses the record.

```sh
gh repo clone andrelin/ai-framework-log "$HOME/.ai-framework-log"   # once per machine
ai-log record plan-foo.md            # in the work repo, after the commit (and at every session end); commits and pushes entries/<id>.json
ai-log record --dry-run plan-foo.md  # print the entry's JSON, write nothing
ai-log level                         # personal, company or customer, by the rule record applies
echo "$text" | ai-log note <id>      # the introspection record asks for: redacts it, prints it, commits and pushes entries/<id>.md
```

A plan gets one entry per run, so a plan has several entries: each window starts where the last ended,
the introspection comes once after the final commit, and a session-end `record` skips it.
A new plan reusing an earlier plan's file name starts a new chain: the entry keeps the plan's `Base:` sha as `plan_base`,
and a different `Base:` than the last entry's is another plan (a plan with no `Base:` line, or an older entry
without `plan_base`, falls back to the plan's file having been deleted in git since that entry's commit).
Windows chain by wall clock, so a session overlapping a window's end on another machine
has its earlier records counted in neither entry: an accepted undercount.
Pass a commit as a second argument to end the window at that commit's time instead of now.
`AI_LOG_DIR`, `AI_LOG_PROJECTS` and `AI_LOG_PLUGINS` move the clone, the transcripts and the plugin list.
`record` and `note` refuse (exit 2, nothing written) unless the clone's origin and its push URL are
`github.com/andrelin/ai-framework-log`; `AI_LOG_REMOTE=<host>/<owner>/<name>` names another. They push to `origin` explicitly.
The level is the one `claude/hooks/work-context.sh` gives, with no list of its own: customer when it says customer or fails, and
when the repo has no origin to name it by (`ai-log level` says on stderr why).
A `record` with nothing committed since a session end takes that session end's id and replaces it with one merged window.
An SSH alias that is a well-known host with a `-`, `_` or `.` suffix or prefix (`github.com-personal`) reads as that
host, as it does for the work-context guard, so two machines' clones of one repo chain;
a dotless alias cannot be resolved (bar an Azure DevOps `v3/` path), and a local-path origin counts as no origin.

From `bin/ai-log`.
