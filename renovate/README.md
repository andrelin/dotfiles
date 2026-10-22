<!-- DOCTOC SKIP -->

# Renovate presets

Shared [Renovate](https://docs.renovatebot.com/) config for my repos, so each one carries only what is particular to it.
A repo extends one merge policy, optionally a schedule, and adds its own holds in `packageRules`:

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "github>andrelin/dotfiles//renovate/automerge-minor",
    "github>andrelin/dotfiles//renovate/weekly"
  ]
}
```

| Preset | What it does |
| --- | --- |
| `recommended` | The base every other preset extends: digest-pinned actions, manifest bumps, a 3-day release-age hold on npm and Maven, security fixes merged at any time. |
| `automerge-minor` | One grouped PR of non-major updates, merged on green checks. Majors wait for review. |
| `automerge-all` | Everything merged on green checks, majors included. |
| `weekly` | PRs opened Monday mornings, Oslo time. |
| `daily` | PRs opened weekday mornings, Oslo time. |
| `weekly-automerge-all`, `daily-automerge-all` | `automerge-all` with that schedule. |
| `renovate-comments(…)` | Opt-in: bumps versions annotated with a `# renovate: datasource=… depName=…` comment, in files matching the regexes passed as arguments, e.g. `renovate-comments(\\.ya?ml$)`. |

Without a schedule, Renovate opens PRs whenever it runs.
For grouping without automerge, extend `automerge-minor` and set `"automerge": false` in a `packageRules` entry matching `"*"`.

This repo is public so the Renovate app can read these presets from any of my repos, private ones included.
