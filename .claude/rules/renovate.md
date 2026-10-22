---
paths:
  - "renovate/**"
  - "test/test_renovate_presets.mjs"
---

# Renovate presets

**Other repos extend `renovate/*.json` by name** and resolve them from `main`, so a change here reaches all of them
on push. Push preset changes to a branch first and let `Renovate presets` CI pass before they reach `main`.
The Renovate app reads them only while this repo is public. Renaming, removing and the local checks: `renovate/README.md`.
