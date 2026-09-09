# unslop — vendored, do not edit

`SKILL.md` in this directory is a **byte-for-byte copy** of `pstack/skills/unslop` from
<https://github.com/cursor/plugins> at commit `df3fb15`.
Everything this repo needs to say about it lives here instead, so the copy stays diffable against its source.

## Re-syncing

```sh
base=https://raw.githubusercontent.com/cursor/plugins/<commit>/pstack/skills/unslop
curl -sS "$base/SKILL.md" -o /tmp/unslop-upstream.md
diff /tmp/unslop-upstream.md claude/skills/unslop/SKILL.md
```

Replace `SKILL.md` wholesale with the new file and update the commit named above.
Never edit it in place — a local change makes the next diff unreadable and silently forks the skill.

## Licence

MIT, like this repo. The copyright line in the root `LICENSE` comes from `pstack/LICENSE` upstream, which is
per-plugin (the `cursor/plugins` root has none), so re-check the holder and year when re-syncing.

## Our conventions do not apply to it

The presence of this file tells `bin/check-md-limits` to skip every markdown file in this directory, and the
`.markdownlint.json` beside it disables every lint rule, so neither the pre-commit hook nor CI can rewrite
upstream's text. Reformatting `SKILL.md` to match `~/.claude/rules/markdown-limits.md` would be the bug.

Upstream's rule numbers are stable ids that its own text cites, and its gaps at 4, 6 and 21 are upstream's —
not something removed here.
