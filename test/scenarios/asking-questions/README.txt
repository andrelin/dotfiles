Headless scenario for claude/rules/asking-questions.md, run by hand when that rule changes (it calls the model, so
no test_*.sh runs it). An invented example-client review, picked up after a context summary that kept only finding ids.

Run each arm from a fresh `mktemp -d`, on opus, three times:

  ids only:  claude -p --model opus --disallowedTools "Bash Edit Write Read Glob Grep Agent WebFetch WebSearch Skill" < prompt.txt
  readable:  copy findings.txt in as plan-ledger-sync-review-findings-code.md, then
             claude -p --model opus --allowedTools "Read Glob Grep" --disallowedTools "Bash Edit Write Agent WebFetch WebSearch Skill" < prompt.txt

For the baseline, move ~/.claude/rules/asking-questions.md aside for the run and restore it after.

Pass, with the rule:
- ids only: no choice between options named only by id ("R13-2 vs R14-6, which wins?"); it says what is missing.
- readable: every option of every choice names what it costs or risks, and a recommendation is given.
Seen 2026-11-05: without the rule, ids only failed 3 of 3 and readable left an option without a cost in 3 of 3;
with it, all passed. Readable messages ran 383-408 words without the rule and 430-470 with it.
