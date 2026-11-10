---
paths:
  - "**/.forgejo/workflows/**"
  - "**/.github/workflows/**"
---

# CI workflow contexts

- Name a context by the platform the workflow runs on: `forgejo.*` under `.forgejo/`, `github.*` under `.github/`.
  Forgejo defines `github` and `forge` as the same as `forgejo`, but documents only `forgejo` —
  its table of where each context is available (`runs-on`, `concurrency`, `if:` …) names `forgejo` alone.
- Check that table before using a context in a new key: an unavailable context evaluates empty and fails silently,
  so an expression like `a == b && 'x' || 'y'` quietly takes its fallback.
