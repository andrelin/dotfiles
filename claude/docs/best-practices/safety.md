# Safety: what an agent may do, and how to enforce it

## Enforce deterministically

- **Instructions advise; hooks enforce.** "Use hooks for actions that must happen every time with zero exceptions";
  "an instruction like 'never edit .env'… is a request, not a guarantee" **[A]** (Claude Code best practices).
  Agents have been seen bypassing pre-commit checks with `--no-verify` and `git stash` despite instructions **[U]**.
- **Contain at the environment layer first, steer at the model layer second:** "the deterministic boundary is what
  gets hit when everything probabilistic misses"; model-layer defences catch about 83% of risky behaviour **[A]**
  (how we contain Claude).
- **Permission rules match command text, so they are not a boundary on their own:** `Bash(git push *)` misses
  `git -C . push` and `git -c push.default=current push` **[A]** (permissions). A PreToolUse hook that parses the
  command sees more; sandboxing and scoped credentials don't depend on the text at all **[A]**.
- **A PreToolUse hook blocks only on exit 2;** any other failure — a crash, a wrong path, a timeout — lets the call
  through unless the entry sets `onFailure: "block"` **[A]** (hooks). A policy hook must fail closed.
- **Hooks don't run everywhere:** they wait for the workspace-trust prompt in an interactive session, and `--bare`
  skips them **[A]**. Credentials the agent can't reach are the only control that holds in every mode.
- **Return a denial with a reason and a safer route,** so the agent re-plans instead of retrying **[A]** (auto mode).
- **Hooks run with your full user permissions** — quote variables, use absolute paths **[A]**.

## The lethal trifecta

- **Private data + untrusted content + a way to send data out** in one session is the exploitable combination
  **[C]** (Willison; Meta's "Rule of Two"). Remove one leg, or put a fresh session or a human approval between them.
- **Prompt injection is unsolved:** "no browser agent is immune"; Opus 4.5 held adaptive attackers to about 1%
  success **[A]** — low, not zero.
- **Repo content is input too:** hidden Unicode in rules files has steered agents into inserting malicious code
  **[S]**, and 24+ CVEs across agent tools came mostly from prompt-injected writes to settings and config **[S]**
  (IDEsaster). Scan agent-loaded files for invisible and bidirectional characters.
- **A malicious public issue hijacked an agent with cross-repo scope** into publishing private-repo data **[S]**
  (Invariant Labs, GitHub MCP). One repo per run and read-only tokens for reading untrusted text prevent it.

## Supply chain

- **Plugins, skills and MCP servers are code you run.** 13.4% of about 4,000 public skills had critical issues
  **[S]**; the first malicious MCP server in the wild BCC'd every email it sent **[O]** (postmark-mcp). Pin versions,
  read updates, install from sources you trust **[A]** **[C]**.
- **OWASP's Top 10 for Agentic Applications (2026)** is the checklist: goal hijacking, tool misuse, privilege abuse,
  supply chain and the rest **[C]**.

## People in the loop

- **Ask before hard-to-reverse or shared-system actions** — force-push, `reset --hard`, amending published commits,
  pushing, commenting on PRs — and "don't bypass safety checks (e.g. --no-verify)" **[A]** (prompting best practices).
- **Approval fatigue is measured:** users approve 93% of permission prompts **[A]** (auto mode). A prompt that is
  always approved protects nothing; move the decision into a hook or a sandbox and prompt only for what is rare.
- **Sandboxing cut permission prompts by 84%** **[A]** — and isolate network as well as filesystem, or a compromised
  agent can exfiltrate what it reads **[A]**.
- **An approval covers one action.** Treat "the user said yes last time" as no approval at all.
