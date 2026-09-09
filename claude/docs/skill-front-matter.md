# Skill front matter — stay on the portable six

Claude Code accepts many front-matter fields; only six are in the [Agent Skills](https://agentskills.io) spec:
`name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`.
**Use only these.** Anything else makes the skill Claude Code-only — uploading it to claude.ai (Cowork, cloud
sessions, the Skills API) then fails with a hard `Unexpected key(s) in SKILL.md frontmatter` error rather than
ignoring the field.

That list is a snapshot so the rule can be followed without fetching anything; the spec is the authority if the
two ever disagree. Being a field behind is safe in both directions — a field the spec added and this list lacks
just goes unused, and a field it dropped surfaces as the upload error above.

The tempting non-spec ones are `when_to_use` (a separate trigger field), `user-invocable: false` (hide from the
`/` menu) and `paths` (glob-gated auto-loading). Do without them:

- **All trigger text goes in `description`**, since `when_to_use` is off the table.
  Lead with the key use case — `description` is truncated at 1,536 characters in the skill listing.
- **A `description` that names the task precisely** does the job `paths` would, without suppressing the
  cross-cutting triggers a glob can't express.

Front matter is exempt from the markdown line-length rule — see `~/.claude/rules/markdown-limits.md`.

## Vendored skills are exempt from all of this

A skill vendored from upstream — `unslop`, whose directory carries a `VENDORED.md` naming the source, commit and
licence — is kept byte-for-byte in step with that source and re-synced by diffing, never edited in place.
Provenance goes in that sidecar rather than in the skill, so the copy stays diffable and the exemption is granted
from outside the file it exempts.
So a non-spec field, an over-long line or a 300-line body in one of these is not a finding: bringing it in line
with our conventions would break the diff that keeps it current, and is the actual mistake.
Say what upstream does if it matters; don't "fix" it, and don't report it again.
