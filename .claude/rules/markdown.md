---
paths:
  - "*.md"
  - "**/*.md"
---

# Markdown in this repo

**Every human-facing file carries doctoc start/end markers or a `<!-- DOCTOC SKIP -->` comment** — never a silent
default, and doctoc only recognises the **uppercase** form.
Rule of thumb: markers once a file passes five H2/H3 headings, otherwise SKIP.
Most `tips/*.md` SKIP whatever their heading count, because `tips` cats them into a terminal where a ToC is a
wall of links nobody can click. Three (`30_zsh`, `50_intellij_config`, `51_intellij_usage`) carry markers
instead, from the older convention. Converting them changes what `tips` prints, so it is a deliberate change
rather than a tidy-up to fold into other work.

**`claude/` and `.claude/` are exempt from doctoc only** — the hook and the workflow exclude them from the ToC
steps, while markdownlint and `bin/check-md-limits` still cover them.
A ToC helps a person navigate a page; for a file an agent loads whole it is only noise.
Don't add `<!-- DOCTOC SKIP -->` there either.

The pre-commit hook runs doctoc, `markdownlint-cli2 --fix` and `bin/check-md-limits` over staged markdown, so an
unformatted hand-off rewrites itself under the user. `init/34_npm_globals.sh` installs the npm tools.
Running the CI form by hand needs the site's generated tree excluded:
`markdownlint-cli2 '**/*.md' '#node_modules' '#website/node_modules' '#website/docs-generated' '#vendor'`.
