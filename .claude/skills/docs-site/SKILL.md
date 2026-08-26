---
name: docs-site
description: How the Docusaurus site under website/ renders this repo's docs to GitHub Pages - source-of-truth docs stay in their canonical locations and are gathered at build time, which top-level directories must be registered for links to resolve, and the MDX pitfalls that break the build. Read before editing anything under website/, before adding a top-level directory or root file that a gathered doc links to, and when a docs deploy reports broken links.
---

# Documentation site

`website/` is a Docusaurus site rendering the repo's docs to GitHub Pages, served from the custom domain
`https://dotfiles.lindjo.no`.
It is build-time tooling, not part of the `dotfiles` install flow.

## Source of truth stays put

`README.md`, `TIPS.md`, `tips/*.md`, `init/README.md` and `source/README.md` are edited in their canonical
locations — never in `website/`.
`website/scripts/gather-docs.ts` copies them into `website/docs-generated/` (gitignored) at build time, adding
front-matter and rewriting links.

Editing a generated copy is always wrong: the next build overwrites it.

## Link rewriting — register new top-level paths

The gather script rewrites repo-internal markdown links (`bin/foo`, `init/12_git_hooks.sh`, `.gitignore`) to
`https://github.com/andrelin/dotfiles/blob/main/...` so they resolve on the rendered site.

**If you add a top-level directory or root-level file that a gathered doc links to, add it to `SOURCE_DIRS` or
`ROOT_FILES` in `website/scripts/gather-docs.ts`** — otherwise the build reports a broken link.

The rewrite only fires on markdown *links*, so a path mentioned in backticks needs no registration.
Register when you link it, not before.

### `](tips/)` — the trailing slash is load-bearing

`README.md` links the tips directory as `[tips/](tips/)`.
An editor may flag that as an unresolvable file; it isn't a defect.
The link resolves on GitHub (a directory renders as a listing) and `gather-docs.ts` has a rule matching that exact
string, rewriting it to the gathered `./tips/index.md`.

**Don't "fix" the warning by dropping the slash.** `](tips)` matches none of the tips rewrite rules, so the site
would ship a relative link to a path that doesn't exist there — trading a cosmetic editor warning for a real
broken link.

## MDX gotcha

Docusaurus parses markdown as MDX, which treats `<...>` as JSX.
The gather script rewrites autolinks (`<https://example.com>` → `[url](url)`); inline `<placeholder>` text inside
fenced code blocks is fine.
New MDX-incompatible markdown outside code blocks means extending the rewrites.

## Deploy

`.github/workflows/deploy-docs.yml` builds and publishes on push to main, when any source-of-truth doc or
`website/` itself changes.
