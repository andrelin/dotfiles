# Shell commands run in zsh

No `paths:` frontmatter on purpose: the Bash tool runs zsh in every session, whatever the project's language.

- Send a multi-pid kill (`kill $pids`) through bash or a script file, never zsh's Bash tool directly: zsh doesn't
  word-split `$pids`, so the kill silently signals only part of the list.
- Gate a commit or push on the commands' exit codes, never on grep finding a line in their output:
  `grep FAILED` succeeds too, which once let a commit through on a failing suite.
