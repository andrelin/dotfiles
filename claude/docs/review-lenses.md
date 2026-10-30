# Review lenses

One lens per reviewer: a reviewer given every question skims all of them, one given a lens reads for it.
`reviewing-in-rounds` runs the set matching what is reviewed; `reviewing-for-feedback` picks from both.

## Severity

Every finding carries one, chosen by its worst plausible outcome, not by how sure the reviewer is.

| Severity | In a code review | In a plan review |
| --- | --- | --- |
| `blocking` | a wrong result, data loss, a secret or a forbidden write | builds the wrong thing, a forbidden write, or an executor who can't start |
| `major` | a bug on a plausible path, or a requirement with no test that can fail | an unverified assumption the approach rests on, or a decision costly to reverse once built |
| `minor` | real, but cheap to live with | real, but cheap to settle while implementing |
| `nit` | wording and style | wording and style |

A finding names a concrete failure scenario or the requirement it violates; one that names neither is unsupported.

## What a plan review leaves to the code

Plans are cut into small tasks that are implemented, tested, reviewed and learned from, so a plan review asks
whether the plan is sound, not whether it has foreseen every bug: the task reviews and the code review meet those
in real code, where they can be fixed for real.
**Out of scope in a plan review**, and dropped by the verifier as `left to the code`: exact test cases and
assertions, edge-case inputs, error handling, command flags and output formats, any choice the executor can
make and a reviewer can check in the diff, and a `Sketch:` task's missing detail.
Left to the code is never left out: the implementer handles every error path and tests the edge cases of each task,
the task review checks it, and the code review hunts down what slipped through.

## Plan lenses

### Grounding

- Is the problem real, and does the approach solve it? Name the simpler approach it should have taken, if any.
- Which claim about the codebase, a tool or a platform does the approach rest on unverified? Check it.
- Does every spec requirement trace back to the issue or the user, and every task to a requirement?

### Scope and slicing

- Is each task the narrowest change that meets its requirement, and is anything built that nothing asks for?
- Does each task end in something that runs, and name the behaviour its tests prove?
- Does the order put the riskiest assumption first, so it is learned from before the rest is built on it?
- Is what is out of scope stated, where an executor would otherwise reach for it?

### Decisions an executor can't make

- Which decision is left open that is the user's, visible to users, or costly to reverse — an interface, a data
  format, a name another task consumes? Write each as the question the executor would ask.
- Which instruction has two plausible readings that build different things?

### Consistency

- Does every name a later task consumes match what the earlier task produces, exactly?
- Has an iteration folded in what the built tasks taught — their deviations and `Deferred:` lines?
- Do the status table, the order and the task sections agree?

### Work context

- Does any step write where the level forbids it (`~/.claude/CLAUDE.md` § *Work contexts*)?
- On a public repo, does anything name a customer, a hostname, internal tooling or a secret?
- Does any step read from or post to the platform where the local clone would do?

## Code lenses

The thorough review is this one: everything a plan review left to the code is in scope here.

### Correctness and failure modes

- Which input produces a wrong result? Name it.
- For each new boundary — a file, a process, a network call, user input — what happens when what crosses it is
  missing, empty, malformed, too large or slow? Which failure is silent?
- What happens on the error path, the empty case and the boundary?
- What breaks under the other platform, shell or locale the project supports?

### Tests

- Does each changed behaviour and each spec requirement have a test that fails without the change (`writing-tests`)?
- Are the boundaries tested: empty, one, many, the limit and one past it?
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

### The change as a whole

- Do the tasks work together end to end? Run the plan's end-to-end verification, and the path between two tasks.
- Which plan assumption did the code prove wrong, and does anything still rest on it?
- Is each `Deferred:` line and deviation in the plan handled, or named in the report?

### Fit with the surrounding code

- Do naming, idiom and structure match the neighbouring code?
- Does a comment restate the code, or narrate the change (`cutting-comments`)?
- Does it add a helper the codebase already has under another name?

### Docs ship with the change

- Does a user-facing change update its README, tip or reference doc in the same change?
- Does any doc now describe behaviour the diff removed?
- Does a changed convention update the `CLAUDE.md` or rule that states it?
