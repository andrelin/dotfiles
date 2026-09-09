---
paths:
  - ".github/workflows/**"
---

# CI workflows

This repo has no PRs and one user: pushes go straight to `main`, and production is whatever is on the user's
machine. CI exists to say "this needs your attention" promptly, not to gate a merge.

- **Every workflow runs on `push`** and **fails hard** on any violation.
- **No `continue-on-error`, no informational-only modes.** Don't propose one.
- **A warning nobody intends to act on gets fixed or switched off**, never left standing: noise trains everyone
  to skim past the warnings that matter. Where a limit has a baseline or opt-out, record the decision there.
- **Scheduled runs supplement push runs**, catching drift while the repo sits idle — external link rot is the
  standing example.
- Keep a workflow's triggers narrow enough that irrelevant changes don't fire it.
