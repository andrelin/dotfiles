---
paths:
  - "**/*.md"
---

# Markdown in this repo

**Every human-facing file carries doctoc start/end markers or a `<!-- DOCTOC SKIP -->` comment** — never a silent
default, and doctoc only recognises the **uppercase** form.
Rule of thumb: markers once a file passes five H2/H3 headings, otherwise SKIP.

**`claude/` and `.claude/` are exempt**, and `hooks/pre-commit` and `.github/workflows/markdown.yml` exclude them:
a ToC helps a person navigate a page, and for a file an agent loads whole it is only noise.
Don't add `<!-- DOCTOC SKIP -->` there either.

The pre-commit hook runs doctoc, `markdownlint-cli2 --fix` and `bin/check-md-limits` over staged markdown, so an
unformatted hand-off rewrites itself under the user. `init/34_npm_globals.sh` installs the npm tools.
