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
| `weekly` | Schedule only: PRs opened Mondays before 13:00, Oslo time. Open PRs are still rebased, and merge when green, outside it. Pair it with one of the presets above, which brings the grouping and the base. |
| `daily` | As `weekly`, on weekdays. |
| `weekly-automerge-all`, `daily-automerge-all` | Shorthand for `automerge-all` plus that schedule. |
| `renovate-comments(…)` | Opt-in: bumps a version followed by a `# renovate: github-releases=cli/cli`-style comment (datasource, then package; `//` works too), in files matching the regexes passed as arguments, e.g. `renovate-comments(\\.ya?ml$)`. Up to ten arguments, split on commas, so a regex can't contain one, not even in a `{1,3}` quantifier. |

Without a schedule, Renovate opens PRs whenever it runs.
Public repos use `daily`; private ones use `weekly`, because their CI minutes are paid for.

## Changing a preset

Other repos extend these by file name, so a rename or removal breaks them and a change alters them all.
To rename or remove one, add its replacement, move every repo that extends it over, then delete it.
`test/test_renovate_presets.mjs` checks references, enum values and what each preset does once merged, with Renovate's own code;
the `Renovate presets` workflow runs it and the validator on every push that touches a preset, the test, or any markdown or JSON file.
Both match regexes with RE2, as the hosted Renovate does. To run them locally, with the version the workflow pins:

```sh
version=$(sed -n 's/^  RENOVATE_VERSION: \([0-9.]*\).*/\1/p' .github/workflows/renovate-presets.yml)
dir=$(mktemp -d)
npm install --prefix "$dir" --no-save --ignore-scripts "renovate@$version" && npm rebuild --prefix "$dir" re2
"$dir/node_modules/.bin/renovate-config-validator" --strict --no-global renovate/*.json .github/renovate.json
RENOVATE_DIR="$dir" node test/test_renovate_presets.mjs
```

This repo is public so the Renovate app can read these presets from any of my repos, private ones included.

## Attribution

These presets are derived from the [Statens pensjonskasse (SPK) presets](https://github.com/statens-pensjonskasse/renovate-presets):
the naming, much of `recommended` and the merge-policy rules, and `renovate-comments.json` near verbatim, from their commit `9a17938`.
`.github/workflows/renovate-presets.yml` is adapted from their validation workflow.
Their copyright, under the same MIT licence, is in the repo's `LICENSE`.

A repo moving over from them gets Oslo time rather than UTC, unwindowed merging through a PR rather than onto the branch,
the 3-day hold on every release, and security fixes at any time. Only the combos my repos use exist here;
`:disableRateLimiting`, `hold_back`, `github-runner-tag`, `spring-boot-patch-updates-only`, the GAL groups
and the self-service-bot preset aren't carried over.
