---
paths:
  - "**/*.sh"
  - "**/*.bash"
---

# Shell scripts on macOS and Linux

- Give `mktemp` a template (`mktemp -d "${TMPDIR:-/tmp}/name.XXXXXX"`) wherever a test redirects `TMPDIR`: without one,
  macOS's BSD `mktemp` ignores `TMPDIR`, so a "`TMPDIR` is empty afterwards" leak check passes vacuously on the Mac.
- A pass-through fake (one that hands most calls to the real command) calls it through a PATH without the fake's directory,
  never `$(command -v cmd)`: that path can be a wrapper (Claude Code's shims) that looks the command up on PATH again,
  finds the fake and loops forever.
