# Asking questions

No `paths:` frontmatter on purpose: every question to the user needs this, so it loads in every session.

- State what is being decided in plain words, a sentence or two, in every question to the user.
  That covers `AskUserQuestion`, the end of a message, and a question logged or drafted for later,
  such as a review log's `user decision needed`, a stop in the `implementing-plans` skill or a subagent's draft.
- For a choice, add what each option does and what it costs or risks, and which you recommend and why: enough to decide on without asking back.
- A yes/no or information question needs only what is decided and why you ask.
- Put a finding id (`R13-2`), task number, file reference or "the issue above" only beside that plain-words statement,
  never in its place — the user reads the question cold, without the session in their head.
- Look up what a reference stands for (findings file, plan, code) when you can no longer see it, as after a context summary,
  unless your brief forbids opening it.
- Say what is missing if you can't look it up or find nothing, rather than asking a bare-id choice such as "R13-2 vs R14-6, which wins?".
- Keep it a summary, not the analysis: the user asks when they want more.
