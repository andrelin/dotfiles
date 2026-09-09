# Personal context belongs in `CLAUDE.local.md`

Personal context is anything tied to one person: their team or role, what the agent may do on their behalf,
their personal files and trackers, their standing preferences.

**The default home is a `CLAUDE.local.md` beside the `CLAUDE.md`**, kept out of git.
Claude Code loads it automatically and appends it *after* the `CLAUDE.md` in the same directory, so the personal
half is the last thing read at that level and wins on any conflict.
Nothing personal reaches the history, and the shared file stays adoptable by anyone.

**How you keep it out of git depends on whose repo it is:**

- **A repo the user owns** — add `CLAUDE.local.md` to `.gitignore` and commit that line.
  It also tells the next person the convention exists.
- **A customer's or an employer's repo** — use `.git/info/exclude` instead.
  It ignores the file per-clone and is never committed, where editing their `.gitignore` would commit a personal
  filename into their history — the leak this whole convention exists to prevent.
  Leaving it untracked and unignored is not the third option: it shows up in every `git status` and gets staged
  by accident.

That replaces the older habit of gathering personal context into a marked section of the committed file.
Reach for that only where no local file can be used at all, and then keep it to one clearly-marked section
rather than sprinkling it through.

**Where to put it when the project spans git worktrees.** A gitignored `CLAUDE.local.md` exists only in the
worktree that created it, so one per worktree means three copies drifting apart.
Two ways out, in order of preference:

- **Put it in a directory *above* the worktrees** — a customer or project tree root. Every `CLAUDE.md` and
  `CLAUDE.local.md` from the working directory upward is loaded, so one file there covers every worktree below it.
- **Import a home-directory file** from the local file: `@~/.claude/<project>-instructions.md`.
  Note that an import in a *project*-level file resolving outside the working directory triggers a one-time
  approval dialog; declining disables it permanently for that project.

**`~/.claude/CLAUDE.md`** stays the home for anything that holds across every project rather than this one.

The same test applies to the rest of any `CLAUDE.md`: a sentence that only makes sense from one person's seat
("default to staying in our modules") either moves to the local file, moves out of the repo, or gets rewritten
neutrally.

A shared `CLAUDE.md` that has a local counterpart should say so, in one line, so the next person creates theirs
instead of editing the shared file — and so the sections that refer back to it still read on their own.
