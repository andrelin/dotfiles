---
paths:
  - "**/*.sh"
  - "**/*.bash"
---

# Shell scripts on macOS and Linux

- Give `mktemp` a template (`mktemp -d "${TMPDIR:-/tmp}/name.XXXXXX"`) wherever a test redirects `TMPDIR`: without one,
  macOS's BSD `mktemp` ignores `TMPDIR`, so a "`TMPDIR` is empty afterwards" leak check passes vacuously on the Mac.
