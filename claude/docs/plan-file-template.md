# The shape of a plan file on disk

The conventions this fills in are the `writing-plans` skill; this is the skeleton to copy.

```markdown
# <Feature> — plan
**Goal:** one sentence.
**Approach:** two or three sentences.
**Spec:** path or link, where there is one.

## Global constraints
- version floors, dependency limits, naming rules, platform targets — exact values

## Implementation status
| Task | Status |

## Task 1 · <name>
**Files:** created / modified (`path:line-range`) / test
**Interfaces:** consumes … | produces …
**Tests:** …
<the change itself>
```

`Files` names the test file alongside the source ones.
`Interfaces` is what an agent executor reads instead of the neighbouring tasks, so it carries exact names and
types rather than a description of the dependency.
