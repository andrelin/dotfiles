# The customers file — what `~/.claude-customers` lists, and how it matches

The reasoning behind the levels is `~/.claude/docs/work-contexts.md`; this file is the syntax and the matching rules
the work-context guard applies.

- **One entry per line;** `#` at line start or after a space begins a comment.
  The file is untracked because it names customers, and machine-local because paths differ per machine.
  Only the user writes it: removing a line loosens the guard, so the guard blocks Claude writing, deleting or
  `chmod`-ing it, in any letter case or through a glob starting with a dot or a brace list.
- **The entry forms:**
  - a `<host>/<owner>`, or a clone URL (https, ssh with any user or port, scp-style), reduced as a remote is; an `ssh.`
    host prefix is dropped, a GitHub org or enterprise page (`github.com/orgs/<org>/…`) names its org, and every Azure DevOps form —
    `v3/` SSH paths on its own hosts or a dotless SSH alias for them, and a legacy `<org>.visualstudio.com` — reads
    as `dev.azure.com/<org>`.
    It matches that host, or an SSH host alias holding the same owner (one with no dot, or the host with a suffix
    such as `github.com-work`), and its first path
    segment only: a GitLab subgroup's entry covers its whole top-level group, and a name matches a remote's first
    segment, never a subgroup below it;
  - a bare host, every owner on which, and on its subdomains, is customer work (`acme.no` covers `gitlab.acme.no`), in
    any letter case; it is also a name, and its label before the TLD, past any `co.` or `kommune.`-style level and of three letters
    or more, marks folders and owners too (`acme.co.uk` marks `acme-portal` and `github.com/acme`), as does a hosting
    service's tenant (`acme.ghe.com`, `acme.gitlab.io`); `host:port` is read as the host;
  - a directory: `/…`, `~`, `~/…`, `$HOME/…`, or a slash path whose first part has no dot or starts with one
    (`.work/acme`), taken from `$HOME`. Its whole tree is customer work whatever its repos' origins, matched in any
    letter case; session start reports an absolute one naming no existing folder as written, and a relative one
    naming none is read as a name too, as `A/S Acme` is, and reported as well unless it has a space, as a name may;
  - a bare name or abbreviation, which marks every folder below `$HOME` named for it, and every remote whose owner is
    named for it — wherever the clone sits, and behind an SSH host alias such as `git@github-acme:acme/app.git`.
- **A line the guard can't read protects nothing,** such as `~someone`, a note after an entry without its `#`
  (`Acme - main customer`, `Acme (2024)`), a list bullet, or several entries on one line;
  session start counts such lines and says so, and says when the file is missing or unreadable.
- **Names match loosely, abbreviations strictly.** A name of five or more letters and digits matches anywhere in a
  folder name, ignoring case, punctuation and a legal form such as `AS`, `A/S`, `Ltd` or `GmbH` (`Fjordvik Kraftlag`
  marks `fjordvik-kraftlag-api`); a shorter one must be a whole word of it, camel case split, so `FVK` marks
  `fvk-portal` and `FvkPortal` but not `fvkx`.
  A name of several words needs them all, in order, so list the short form a folder would use as well (`Fjordvik`).
  Accented and Nordic letters match their ASCII spellings, ø, å and ü as both o/oe, a/aa and u/ue, and æ as ae or a.
  A false match only blocks — a worktree or folder of the user's own named for a customer included.
- **A repository is customer work by its own location:** its toplevel and its main worktree, so a linked worktree or a
  `--git-dir` or `GIT_DIR` from elsewhere still counts.
  Names are matched against those, or against a folder outside any repository, never against a subfolder of a
  repository a command runs in, and never outside `$HOME` — where Claude's scratch paths live — including a folder
  reached through a link from `$HOME` to another volume, which only a directory or owner entry covers.
- **Fail closed only while customers are listed:** a target the guard cannot resolve — a `cd` to a variable, `cd -`, a
  push target holding a variable, `glab api projects/<id>` — could be a listed customer's, so it is customer while
  the file lists anything; with no customers listed there is nothing to protect.
- **`fj` is not checked at all** until a customer uses Forgejo, so customer work on a Forgejo host guards `git`
  there but not `fj` (`~/.claude/docs/work-contexts.md` § *Enforcement*); session start says so where `fj` is logged
  in to that host.
