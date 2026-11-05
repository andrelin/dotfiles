# Asking questions

No `paths:` frontmatter on purpose: every question to the user needs this, so it loads in every session.

- State what is being decided in plain words, a sentence or two, in every question to the user.
  That covers `AskUserQuestion`, the end of a message, and a question logged or drafted for later,
  such as a review log's `user decision needed`, a stop in the `implementing-plans` skill or a subagent's draft.
- For a choice, add what each option does and which you recommend and why, plus a cost or risk where that is what tells the options apart.
- The test: could the user make an informed decision from only what is written with the question? If not, add what is missing.
- A yes/no or information question needs only what is decided and why you ask.
- Put a finding id (`R13-2`), task number, file reference or "the issue above" only beside that plain-words statement,
  never in its place — the user reads the question cold, without the session in their head.
- Find what a reference stands for yourself before asking the user for it, in every source you can reach —
  findings file, plan, code, `git log`, and after a context summary the session's transcript under `~/.claude/projects/`,
  which keeps what the summary dropped — unless your brief forbids opening it.
- Ask the user for it only when those come up empty, naming what you tried; never ask a bare-id choice such as "R13-2 vs R14-6, which wins?".
- Keep it a summary, not the analysis: the user asks when they want more.
