---
paths:
  - "website/**"
---

# The Docusaurus site

`website/` renders the repo's docs to GitHub Pages. It is build-time tooling, not part of the `dotfiles`
install flow, so nothing here runs on a user's machine.

**Never edit anything under `website/docs-generated/`.** It is gitignored and rebuilt from the canonical files
on every build — edit the source in its own location instead, and the change flows through.

`docs/` holds the long-form guide pages split out of the README; they render as the site's **Guide** section.
A top-level directory has to be registered in `website/scripts/gather-docs.ts` before links into it resolve —
`docs/` is the exception, gathered by its own loop, so only the README's links into it are rewritten.
Link to a guide page from anywhere else and it will 404 on the site until that is handled.
Registering paths, the MDX pitfalls and the deploy trigger are the `docs-site` skill.
