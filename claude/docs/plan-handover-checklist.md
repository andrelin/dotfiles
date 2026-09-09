# Handing a plan over — placeholders and the self-review

The `writing-plans` skill covers what a plan says. This is the pass before it reaches an executor.
Every item here hands a decision the plan was supposed to make back to the implementer, who will guess.

## Never write these

- `TBD`, `TODO`, "implement later", "fill in details".
- "Add appropriate error handling", "add validation", "handle edge cases" — appropriate how, which cases?
- "Write tests for the above", with nothing about what they assert.
- "Same as task 3." Tasks get read out of order and implemented in isolation. Say it again.
- A reference to a type, function or config key that no task defines and that isn't already in the codebase.

## Self-review, three passes

Read the finished plan against the spec with fresh eyes. Do this yourself — it isn't worth a subagent.

1. **Coverage.** Walk the spec's requirements and point at the task implementing each one.
   Add tasks for whatever you can't point at.
2. **Placeholders.** Search for the patterns above.
3. **Name and type consistency.** A helper called `clearLayers()` in task 3 and `clearFullLayers()` in task 7 is a
   bug the executor inherits. Check every symbol a later task consumes against what the earlier task produces.

Fix what you find inline and move on. Don't re-review.
