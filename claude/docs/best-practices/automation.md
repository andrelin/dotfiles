# Automation: unattended agents, and agents writing to trackers

## Where unattended agents run

- **Cloud routines** run on a schedule (hourly at most), an API call or GitHub events, with **no permission mode**:
  connector writes run without asking, and every action appears as *you* **[A]** (routines). All your connectors are
  attached by default — remove the ones a routine doesn't need. A green run means "no infrastructure error", not
  "the task succeeded".
- **Desktop scheduled tasks** run locally with a per-task permission mode and can see local, gitignored files; the
  machine must be awake, and a missed run fires once on wake — guard the prompt against running late **[A]**.
- **GitHub Actions** (`claude-code-action`): output goes to the run log unless the prompt and allowed tools say to
  post; bot actors are refused unless listed, which prevents bot loops; scheduled workflows run only from the default
  branch, and GitHub disables them on a public repo after 60 days without activity **[A]**.
- **Scripted calls:** `--bare` is the recommended `-p` mode — it skips hooks, skills, plugins and `CLAUDE.md`, so any
  guard a hook provides is gone **[A]**. Pass the permission mode explicitly; unattended prompts must say what success
  looks like, since they can't ask **[A]**.

## Writes go through a gate

- **Split reading from writing.** GitHub Agentic Workflows run the agent read-only and hand structured write
  requests to a separate job holding the token, with per-type caps, label allow- and blocklists, a target-repo
  allowlist and an attribution footer **[O, vendor]** (gh-aw safe outputs).
- **Rehearse before writing:** gh-aw's staged mode does a full run with every write replaced by a preview; stage,
  review, tune, unstage, and re-stage when adding a new kind of write **[O]**.
- **Tiers per action, per project:** automatic, draft (the exact command or text, for a person to run), suggest, or
  off — and a global ceiling a project's config can tighten but never loosen.
- **Name the target explicitly** (`-R owner/repo`), resolved from config and checked: CLIs infer the repo from the
  directory and remotes, and forks, worktrees and `upstream` remotes make that guess wrong.

## Facts from scripts, narrative from the model

- **LLM status summaries fabricate and omit:** one study found 12.3% fabricated content and 47.9% missing information
  in bug-report summaries **[S]**. Compute status, counts, dates and links with scripts — zero tokens, nothing to
  hallucinate — and let the model write only the prose around them, citing an issue, PR or commit for every claim.
  The ccpm project's `status`, `standup` and `blocked` commands are plain bash for this reason **[O]**.

## Don't be the noisy bot

- **Never auto-close.** Anthropic's own duplicate bot, which closed issues after a grace period, built dozens of
  circular duplicate chains with no open original, merged unrelated issues, and was silently down for about two
  months **[U]** (anthropics/claude-code issues). Stale bots raise duplicates and erode trust **[O]**. Label and
  suggest; a person closes.
- **Cap writes per run, comment rarely, batch into one digest,** and skip items a person has already labelled or
  assigned **[O]** (gh-aw's triage example). Bots have filed 125+ reports to one project in minutes **[O]**.
- **Be idempotent:** mark every bot-written item (`<!-- job:key -->`), search for the marker before writing and
  update in place, keep one rolling report rather than a new one per run, and query "since last cursor" **[O]**.
- **Prove liveness:** write a per-run audit record and alert on a missing heartbeat **[O]**.

## Privacy across trackers

- **Never quote private content into a public target.** Check the target's visibility and a denylist of
  customer names and hosts before anything leaves the machine — the cross-repo injection in [safety.md](safety.md)
  is this failure with an attacker behind it.
- **Least privilege:** fine-grained tokens per repo, read-only MCP modes for read jobs, a narrow allowed-tools list,
  and a custom GitHub App scoped to what the job needs rather than the broad default **[A]** **[O]**.
