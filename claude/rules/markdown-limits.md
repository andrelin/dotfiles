---
paths:
  - "*.md"
  - "**/*.md"
---

# Markdown limits

- **One sentence per line**, wrapping mid-sentence only past the 150-character cap, at a comma or em-dash.
  Never wrap inside a code fence, a URL or a table cell, and never anywhere in YAML front matter, where a break
  changes what the YAML parses to.
- **Shorter is always better** — nothing below is a length to fill. Both numbers tighten with how easily the
  file loads:

| File | Aim under | Never past |
| --- | --- | --- |
| A rule, or a project `CLAUDE.md` | 30 | 50 |
| The global `~/.claude/CLAUDE.md` | 60 | 75 |
| A skill | 50 | 100 |
| Anything else | 50 | 150 |

- **Counting differs by audience.** Every line of an agent-loaded file (`CLAUDE.md`, `SKILL.md`, `claude/`,
  `.claude/`) counts, because it is loaded whole; a human-facing page counts the content a reader gets through, so
  comments, badge blocks and a doctoc ToC are free. **Past the aim, look for the seam** rather than trimming words.

**A file over its warn line can be pinned** at a length you decided not to shorten; growing past a pin is then
an error, and the hard cap still applies. **A directory holding a `VENDORED.md` is exempt from all of it**, its
files being kept byte-for-byte in step with upstream.

Only if a file is near a cap, or you need the reasoning: `~/.claude/docs/markdown-limits.md`.
