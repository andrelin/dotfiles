<!-- DOCTOC SKIP -->

# Renovate presets

Shared [Renovate](https://docs.renovatebot.com/) config for my repos, so each one carries only what is particular to it.
A repo extends one merge policy, optionally a schedule, and adds its own holds in `packageRules`:

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "github>andrelin/dotfiles//renovate/automerge-non-major",
    "github>andrelin/dotfiles//renovate/weekly"
  ]
}
```

| Preset | What it does |
| --- | --- |
| `recommended` | The base every other preset extends: digest-pinned actions, manifest bumps, a 3-day release-age hold on npm and Maven, security fixes merged at any time. |
| `automerge-non-major` | One grouped PR of non-major updates, merged on green checks. Majors wait for review. |
| `grouped-non-major` | The same grouping, with nothing merged automatically. |
| `automerge-all` | Two PRs, one with every non-major update and one with every major, each merged once checks pass. |
| `weekly` | Schedule only: PRs opened Mondays before 13:00, Oslo time. Pair it with one of the presets above, which brings the grouping and the base. |
| `daily` | Schedule only: PRs opened weekdays before 13:00, Oslo time. Pair it as with `weekly`. |
| `weekly-automerge-all`, `daily-automerge-all` | Shorthand for `automerge-all` plus that schedule. |
| `renovate-comments(…)` | Opt-in: bumps a version followed by a `# renovate: github-releases=cli/cli`-style comment (datasource, then package), in files matching the regexes passed as arguments, e.g. `renovate-comments(\\.ya?ml$)`. |

Without a schedule, Renovate opens PRs whenever it runs.

This repo is public so the Renovate app can read these presets from any of my repos, private ones included.

## Attribution

The layout and names follow the [Statens pensjonskasse presets](https://github.com/statens-pensjonskasse/renovate-presets).
`renovate-comments.json` is copied from them and `.github/workflows/renovate-presets.yml` adapted from their validation workflow,
both under the MIT licence; their copyright is in the repo's `LICENSE`.
