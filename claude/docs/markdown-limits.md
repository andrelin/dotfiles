# Markdown limits — the reasoning behind the caps

The rule itself is `~/.claude/rules/markdown-limits.md`; this is why each number is what it is.

## Line breaks

**Why one sentence per line:** long lines force horizontal scrolling in editors and terminals, but mid-sentence
wraps fragment reading flow. One sentence per line also gives a diff-friendly history — changing one sentence is
a one-line diff.
End each sentence with a newline in new markdown, and reflow any paragraph you touch in an existing file.

**Why front matter is exempt** from both the cap and the breaks: a wrapped value becomes a different YAML
structure. A break inside `description:` either parses as a new key or folds into a scalar, so every value stays
on one line however long it runs, for the whole block between the opening and closing `---`.

**Why table rows are exempt:** a row that runs long is shortened, not wrapped — a break inside a cell ends the row.

## File length

**Shorter is always better.** These are ceilings, not targets — there is no number a file is supposed to reach,
and a file that says what it needs in 15 lines is finished at 15 lines.
Both numbers tighten with how easily the file loads.

| File | Aim under | Never past | Why that one |
| --- | --- | --- | --- |
| A rule, or a project `CLAUDE.md` | 30 | 50 | a rule loads on a bare path match, a `CLAUDE.md` on nothing at all |
| The global `~/.claude/CLAUDE.md` | 60 | 75 | same, plus permission rules that cannot live anywhere else |
| A skill | 50 | 100 | loads only when its task matches, and carries a procedure end to end |
| Anything else | 50 | 150 | read on purpose, so length costs a reader rather than every task |

`bin/check-md-limits` warns at the aim for the three strict types, where few enough files sit between aim and cap
that each warning is worth acting on. Skills and everything else warn at 80 instead of their 50-line aim:
warning at the aim there would fire on most of the repo, and a warning that common is one nobody reads.

**What counts depends on who reads the file.**

- **Claude-loaded** — `CLAUDE.md`, any `SKILL.md`, anything under `claude/` or `.claude/`: **every line counts**,
  because the file is loaded whole and every line of it is tokens on every task that trips its trigger.
- **Human-facing** — `README.md`, `TIPS.md`, `tips/`, `docs/`, the `README.md` files beside code: **count the
  content a reader has to get through**, not the scaffolding around it.
  An HTML comment never renders, and four lines of badge definitions are the one row they draw.
  A doctoc table of contents does render, but it exists to help a person navigate a long page — charging for it
  would penalise the thing that keeps the page readable. Agent-loaded files carry no ToC for the same reason:
  navigation aids are for humans, and for a file loaded whole they are only noise.
  The cap holds on what's left: past 150 lines of content a reader stops finding things in it.

**A skill may set a stricter bar for what it governs; none may set a looser one.**
`writing-claude-md` holds `CLAUDE.md` to tighter numbers, and `writing-tips` does the same for tips files.

## Files that were already long

A file over its warn line can be pinned at its current size, in a baseline the checker reads.
It then warns only if it **grows**, so a file whose length is accepted stops nagging without being exempted: the
hard cap still applies, and re-pinning can only lower the recorded size.

**Pin anything you have decided not to shorten.** A warning nobody intends to act on trains everyone to skim past
the warnings that matter, so the choice is fix it or pin it — never leave it standing.
Pinning is a decision on the record, and it stays honest because the file cannot grow behind it.
`claude/CLAUDE.md` is pinned for exactly this reason: what pushes it over its aim is the permission block, which
has nowhere else to live.

## Splitting

**Past the aim, look for the seam rather than trimming words.**
The usual finds: a second subject that wants its own trigger, reasoning that belongs in a doc the file points at,
or an excuses table that has grown past the rule it defends.
Splitting on a real boundary leaves two files that each stand alone; cutting at the midpoint leaves two halves
that always have to be read together.

`bin/check-md-limits` in the dotfiles repo enforces both caps, in a `PostToolUse` hook at edit time, in
`hooks/pre-commit`, and in CI.
