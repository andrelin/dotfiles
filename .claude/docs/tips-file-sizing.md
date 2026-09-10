# How big a tips file may get, and where to cut

The decade meanings and the rest of the conventions are the `writing-tips` skill.
This is the sizing policy for `tips/*.md`, which is stricter than the repo-wide markdown cap because `tips`
prints these files into a terminal.

## Sizing

**Group similar tools** — text-processing, project-workflow CLIs — to avoid both over-large files *and* a scatter
of tiny ones.

**Size by length, not by tool count.** A shared file should stay under about 50 lines — an aim, not a length to
grow into. `bin/check-md-limits` warns at 80 and fails at 150 like any other human-facing page, so between 50 and
80 nothing will tell you; that is the range to watch by eye.
Past 50, check whether the file should split: the question is whether the tools still read as one grouping, not
how many there are.

**A single-tool file may run past the soft cap: its length follows the tool.**
`tips/30_zsh.md` is correct as it stands — breaking one tool across files costs more than the length does.

**Four tips files are pinned in `.md-baseline`** at the length they had when the limits landed:
`10_terminal`, `30_zsh`, `50_intellij_config` and `51_intellij_usage`.
A pinned file may not grow at all — adding a line fails the check until you shorten it or re-pin it lower.
That is a tighter bar than the 150-line cap below, and the one you meet first.

**Hard cap: 150 lines, no exemption.** Past that a file stops being skimmable and `tips` prints a wall.

## Splitting

A single-tool file that reaches the cap splits along a seam in the tool itself.
Find that seam in the content — the existing H2 groups usually show where it is — rather than cutting at the
halfway mark.
Rename both halves so neither keeps the old undifferentiated name, and cross-link them from each other's intro so
neither is a dead end.

The one split so far: the IntelliJ tips hit 199 lines and divided into `50_intellij_config.md` and
`51_intellij_usage.md`, pushing Sublime Text to `52`.
Configuration-versus-usage was the seam that fitted *that* tool; don't assume it fits the next one.

Splitting renumbers tips, which is the user's call — see the skill.
