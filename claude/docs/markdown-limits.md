# Markdown limits — the reasoning behind the caps

The rule itself is `~/.claude/rules/markdown-limits.md`; this is why each number is what it is.

## Scope

**Why plan files and follow-up trackers never have a length cap:** a plan is deleted once the work ships, and a
tracker is as long as what is still open, its review runs already deleting what is done.
Both keep the line cap, which costs nothing to meet and keeps their diffs readable.

**Why required only for permanent, checked-in files:** the caps pay off over a file's lifetime — every load, every reader, every diff.
A scratch note is deleted once the work ships, so restructuring it to fit a cap is effort with nothing to amortise it against.
The cheap habits still carry over: one sentence per line keeps a plan's diffs readable while it changes, and a shorter plan is easier to review.

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
| A skill | 100 | 150 | loads only when its task matches, and carries a procedure end to end |
| Anything else | 100 | 200 | read on purpose, so length costs a reader rather than every task |

`bin/check-md-limits` warns at the aim for every type.

**Why a skill's `description` is capped at 300 characters:** the body loads only when the skill is used, but the
description sits in the skill list of every session, so it is paid for on every task like a `CLAUDE.md` line.
It says when to read the skill and stops; a summary of the body gets followed in its place.

**What counts depends on who reads the file.**

- **Claude-loaded** — `CLAUDE.md`, any `SKILL.md`, anything under `claude/` or `.claude/`: **every line counts**,
  because the file is loaded whole and every line of it is tokens on every task that trips its trigger.
- **Human-facing** — `README.md`, `tips.md`, `tips/`, `docs/`, the `README.md` files beside code: **count the
  content a reader has to get through**, not the scaffolding around it.
  An HTML comment never renders, and four lines of badge definitions are the one row they draw.
  A doctoc table of contents does render, but it exists to help a person navigate a long page — charging for it
  would penalise the thing that keeps the page readable. Agent-loaded files carry no ToC for the same reason:
  navigation aids are for humans, and for a file loaded whole they are only noise.
  The cap holds on what's left: past 200 lines of content a reader stops finding things in it.

**A skill may set a stricter bar for what it governs; none may set a looser one.**
`writing-agent-instructions` restates the two `CLAUDE.md` rows above rather than tightening them.
A project may tighten further in its own `.claude/` tree — the dotfiles repo asks tips files to stay near 50
lines, below the 100 the checker warns at, so nothing signals between the two and you watch that range by eye.

## Files that were already long

A file over its warn line can be pinned at its current size, in a baseline the checker reads.
It then says nothing until it **grows**, and growing past a pin is an error rather than an advisory — a pin is a
commitment, so CI enforces it like any other cap. Re-pinning can only lower a recorded size, and the hard cap
still applies on top.

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
