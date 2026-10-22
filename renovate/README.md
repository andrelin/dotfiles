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
| `recommended` | The base the merge policies extend: digest-pinned actions, manifest bumps, a 3-day hold on every release that has a publish date, security fixes merged at any time. |
| `automerge-non-major` | One grouped PR of non-major updates, merged on green checks. Majors wait for review, except security fixes. |
| `grouped-non-major` | `automerge-non-major`'s grouping, with nothing merged automatically, security fixes included. Use it in a repo without CI, where automerge would merge untested. |
| `automerge-all` | Two PRs, one with every non-major update and one with every major, each merged once checks pass. A failing major holds back the other majors in its PR. |
| `weekly` | Schedule only: PRs opened Mondays before 13:00, Oslo time; open PRs are still rebased outside it. Pair it with one of the presets above, which brings the grouping and the base. |
| `daily` | Schedule only: PRs opened weekdays before 13:00, Oslo time. Pair it as with `weekly`. |
| `weekly-automerge-all`, `daily-automerge-all` | Shorthand for `automerge-all` plus that schedule. |
| `renovate-comments(…)` | Opt-in: bumps a version followed by a `# renovate: github-releases=cli/cli`-style comment (datasource, then package; `//` works too), in files matching the regexes passed as arguments, e.g. `renovate-comments(\\.ya?ml$)`. Up to ten arguments, split on commas, so a regex can't contain one, not even in a `{1,3}` quantifier. |

Without a schedule, Renovate opens PRs whenever it runs.
Public repos use `daily`; private ones use `weekly`, because their CI minutes are paid for.

Moving a repo over from the [Statens pensjonskasse (SPK) presets](https://github.com/statens-pensjonskasse/renovate-presets) changes more than the prefix:
times are Oslo time rather than UTC, merging isn't windowed, automerge goes through a PR rather than straight onto the branch,
every release waits 3 days, and security fixes merge at any time.
`:disableRateLimiting` and their SPK-specific rules (`hold_back`, `github-runner-tag`, the GAL groups) aren't carried over,
and only the combos my repos use exist here.

## Changing a preset

Other repos extend these by file name, so a rename or removal breaks them and a change alters them all.
To rename or remove one, add its replacement, move every repo that extends it over, then delete it.
`test/renovate_presets.mjs` checks references, enum values and what each preset resolves to; the workflow runs it on every change here.

This repo is public so the Renovate app can read these presets from any of my repos, private ones included.

## Attribution

These presets are derived from the SPK presets: the naming, much of `recommended` and the merge-policy rules,
and `renovate-comments.json` near verbatim, from their commit `9a17938`.
`.github/workflows/renovate-presets.yml` is adapted from their validation workflow.
Their copyright, under the same MIT licence, is in the repo's `LICENSE`.
