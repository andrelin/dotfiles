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
| `automerge-all` | Two PRs, one with every non-major update and one with every major, each merged once checks pass. |
| `weekly` | Schedule only: PRs opened Mondays before 13:00, Oslo time. Pair it with a merge policy, which brings the grouping and the base. |
| `daily` | Schedule only: PRs opened weekdays before 13:00, Oslo time. Pair it with a merge policy, as with `weekly`. |
| `weekly-automerge-all`, `daily-automerge-all` | Shorthand for `automerge-all` plus that schedule. |
| `renovate-comments(…)` | Opt-in: bumps versions annotated with a `# renovate: datasource=… depName=…` comment, in files matching the regexes passed as arguments, e.g. `renovate-comments(\\.ya?ml$)`. |

Without a schedule, Renovate opens PRs whenever it runs.
For grouping without automerge, extend `automerge-minor` and set `"automerge": false` in a `packageRules` entry matching `"*"`.

This repo is public so the Renovate app can read these presets from any of my repos, private ones included.

## Attribution

The layout and names follow the [Statens pensjonskasse presets](https://github.com/statens-pensjonskasse/renovate-presets), and `renovate-comments.json` is copied from them, under this licence:

```text
MIT License

Copyright (c) 2025 Statens pensjonskasse

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
