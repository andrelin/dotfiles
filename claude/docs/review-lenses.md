# Review lenses

One lens per reviewer: a reviewer given every question skims all of them, one given a lens reads for it.
`reviewing-in-rounds` runs the set matching what is reviewed; `reviewing-for-feedback` picks from both.

## Severity

Every finding carries one, chosen by its worst plausible outcome, not by how sure the reviewer is.

| Severity | Means |
| --- | --- |
| `blocking` | a wrong result, data loss, a secret or a forbidden write, or an executor who can't proceed |
| `major` | a likely wrong guess by an executor, a bug on a plausible path, or a requirement with no test that can fail |
| `minor` | real, but cheap to live with |
| `nit` | wording and style |

A finding names a concrete failure scenario or the requirement it violates; one that names neither is unsupported.

## Plan lenses

### Scope

- Is each task the narrowest change that meets its requirement?
- Is what is out of scope stated, where an executor would otherwise reach for it?
- What is built that no requirement asks for?
- What obvious part is missing — a migration, a doc, the other platform, the error path?

### Clarify

- Where would an executor have to guess? Write each as the question they would ask.
- Which name, path, value or version is left for the executor to choose?
- Which instruction has two plausible readings that produce different code?

### Data flow and failure modes

- For each new boundary — a file, a process, a network call, user input — what crosses it, in what shape?
- What happens when it is missing, empty, malformed, too large or slow?
- Which failure is silent, and who notices it?

### Test matrix

- Which requirement has no named test, or only a test that cannot fail (`writing-tests`)?
- Does each test name its input and its expected result exactly?
- Are the boundaries tested: empty, one, many, the limit and one past it?

### Consistency

- Does every spec requirement map to a task, and every task to a requirement?
- Does every name a later task consumes match what the earlier task produces, exactly?
- Do the status table, the order and the task sections agree?

### Work context

- Does any step write where the level forbids it (`~/.claude/CLAUDE.md` § *Work contexts*)?
- On a public repo, does anything name a customer, a hostname, internal tooling or a secret?
- Does any step read from or post to the platform where the local clone would do?

## Code lenses

### Correctness and failure modes

- Which input produces a wrong result? Name it.
- What happens on the error path, the empty case and the boundary?
- What breaks under the other platform, shell or locale the project supports?

### Tests

- Does each changed behaviour have a test that fails without the change (`writing-tests`)?
- Was an assertion removed, loosened or skipped? That is always `blocking`.
- Does a test assert a literal it restates, or a stub's own return value?

### Security and work context

- Is a secret, token or credential written, logged or committed?
- On a public repo, does anything name a customer, a hostname or internal tooling?
- Does a script or CI step write where the level forbids it?

### Plan conformance

- Does the diff do what its task says — all of it?
- Does it do anything its task doesn't say?
- Is a test the task names missing from the diff?

### Fit with the surrounding code

- Do naming, idiom and structure match the neighbouring code?
- Does a comment restate the code, or narrate the change (`cutting-comments`)?
- Does it add a helper the codebase already has under another name?

### Docs ship with the change

- Does a user-facing change update its README, tip or reference doc in the same change?
- Does any doc now describe behaviour the diff removed?
- Does a changed convention update the `CLAUDE.md` or rule that states it?
