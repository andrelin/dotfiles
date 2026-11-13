#!/usr/bin/env bash
# Resolve the repo before sourcing the helper: bin/dotfiles exports DOTFILES=~/.dotfiles when sourced, so
# afterwards this would test whatever tree lives there rather than the one this file was launched from.
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AI_LOG_SRC="$REPO/bin/ai-log"
FIX="$REPO/test/ai-log"
readonly REPO AI_LOG_SRC FIX

source "$DOTFILES/test/helper.sh"

if [[ ! -x "$AI_LOG_SRC" ]]; then
  echo "ERROR: $AI_LOG_SRC is missing or not executable" >&2
  exit 1
fi

e_header "$(basename "$0" .sh)"

# Every scratch repo, the log clone and its bare origin live under one temp dir; git writes run in a subshell cd.
workdir="$(cd -P "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$workdir"' EXIT
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com
unset AI_LOG_DIR AI_LOG_PROJECTS AI_LOG_PLUGINS AI_LOG_REMOTE TEST_LOG_REMOTE
# An empty throwaway HOME, so the guard never reads the machine's own ~/.claude-customers; the customer block sets its own.
export HOME="$workdir/home0"
mkdir -p "$HOME"

function gitin() { local d="$1"; shift; (cd "$d" && git "$@"); }
function commit_at() { local d="$1" when="$2" msg="$3"; (cd "$d" && git add -A && GIT_COMMITTER_DATE="$when" GIT_AUTHOR_DATE="$when" git commit -q -m "$msg"); }

# The tree ai-log runs from: its own copy of the script, the guard, the lens headings and some skill directories.
function make_tree() {
  local t="$1"
  mkdir -p "$t/bin" "$t/claude/hooks" "$t/claude/docs" "$t/claude/skills/example-dot-skill" "$t/claude/skills/synced/example-synced-skill"
  cp "$AI_LOG_SRC" "$t/bin/ai-log"
  cp "$REPO/claude/hooks/work-context.sh" "$t/claude/hooks/"
  cp "$REPO/claude/docs/review-lenses.md" "$t/claude/docs/"
  touch "$t/claude/skills/example-dot-skill/SKILL.md" "$t/claude/skills/synced/example-synced-skill/SKILL.md"
  git init -q "$t"
  commit_at "$t" 2026-01-01T00:00:00Z tree
}
TREE="$workdir/tree"
make_tree "$TREE"
AI="$TREE/bin/ai-log"
TREE_HEAD="$(gitin "$TREE" rev-parse HEAD)"

# new_projects <name> <cwd>: the fixture transcripts with their cwd rewritten to a scratch work repo.
function new_projects() {
  mkdir -p "$workdir/$1"
  cp -R "$FIX/projects/." "$workdir/$1/"
  find "$workdir/$1" -name '*.jsonl' -exec sed -i.bak "s#__CWD__#$2#g" {} +
  find "$workdir/$1" -name '*.bak' -delete
}

# new_work <name> <origin>: a work repo holding the fixture plan and its findings files, a commit before the plan
# (C0, 2026-01-01) and the commit that adds it (C1, 2026-01-10 12:00 UTC), on a branch carrying a marker.
function new_work() {
  W="$workdir/$1"
  mkdir -p "$W/sub"
  git init -q "$W"
  [[ -z "$2" ]] || gitin "$W" remote add origin "$2"
  echo readme > "$W/README.md"
  commit_at "$W" 2026-01-01T12:00:00Z "first"
  C0="$(gitin "$W" rev-parse HEAD)"
  cp "$FIX"/plan-example* "$W/"
  commit_at "$W" 2026-01-10T12:00:00Z "COMMIT-MARKER c1"
  C1="$(gitin "$W" rev-parse HEAD)"
  gitin "$W" switch -q -c feat/branch-marker-y
}

# new_log <name>: a bare origin and a clone of it holding one commit.
function new_log() {
  BARE="$workdir/$1-bare.git"
  LOG="$workdir/$1"
  git init -q --bare "$BARE"
  git clone -q "$BARE" "$LOG" 2> /dev/null
  echo "log" > "$LOG/README.md"
  gitin "$LOG" add README.md
  gitin "$LOG" commit -q -m "Start the log"
  gitin "$LOG" push -q origin HEAD 2> /dev/null
}

# run_ai <dir> <args...>: ai-log in a work repo; sets rc, with stdout in $workdir/out and stderr in $workdir/err.
function run_ai() {
  local d="$1"
  shift
  (cd "$d" && AI_LOG_DIR="$LOG" AI_LOG_REMOTE="${TEST_LOG_REMOTE:-$(git -C "$LOG" remote get-url origin 2> /dev/null || true)}" AI_LOG_PROJECTS="$PROJ" AI_LOG_PLUGINS="${PLUGINS:-$FIX/installed_plugins.json}" "${AI_BIN:-$AI}" "$@") \
    > "$workdir/out" 2> "$workdir/err" && rc=0 || rc=$?
}
function out() { cat "$workdir/out"; }
function err() { cat "$workdir/err"; }
function j() { jq -c "$1" "$ENTRY"; }
function entry_count() { ls "$LOG/entries" 2> /dev/null | wc -l | tr -d ' '; }
function log_commits() { gitin "$LOG" rev-list --count HEAD; }


# run_note <dir> <id> <text>: ai-log note in a work repo with the text on stdin, exactly as given; sets rc, out and err.
function run_note() {
  local d="$1" id="$2" text="$3"
  (cd "$d" && printf '%s' "$text" | AI_LOG_DIR="$LOG" AI_LOG_REMOTE="${TEST_LOG_REMOTE:-$(git -C "$LOG" remote get-url origin 2> /dev/null || true)}" AI_LOG_PROJECTS="$PROJ" AI_LOG_PLUGINS="${PLUGINS:-$FIX/installed_plugins.json}" "${AI_BIN:-$AI}" note "$id") \
    > "$workdir/out" 2> "$workdir/err" && rc=0 || rc=$?
}

# --- Personal level: the whole entry for the fixture plan ------------------------------------------------------

new_work work1 git@github.com:andrelin/x.git
PROJ_NAME=projects1
new_projects "$PROJ_NAME" "$W"
PROJ="$workdir/$PROJ_NAME"
mkdir -p "$W/.claude/skills/example-project-skill"
new_log log1
W1="$W"

assert "$(cd "$W1" && "$AI" level)" "personal" "ai-log level: a personal origin"

run_ai "$W1" record plan-example.md "$C1"
ID1="$(out | head -1 | sed 's/^entry: //')"
ENTRY="$LOG/entries/$ID1.json"
assert "$rc" "0" "record exits 0 with a warning present"
assert "$(out | head -1 | cut -c1-18)" "entry: 2026-01-10-" "stdout starts with entry: <commit date>-"
assert "$([[ "$ID1" =~ ^2026-01-10-[0-9a-f]{12}$ ]] && echo ok)" "ok" "the id is the date and 12 hex"
assert "$(j '[.schema, .level, .repo, .plan, .commit == "'"$C1"'"]')" '[1,"personal","andrelin/x","plan-example.md",true]' "identity fields"
assert "$(j '.window')" '{"start":"2026-01-09T10:00:00.000Z","end":"2026-01-10T12:00:00.000Z","after":null}' "no earlier entry: the window starts at the plan's first appearance"
assert "$(j '.sessions | length')" "2" "another repo's session, one never naming the plan and one outside the window are left out"
assert "$(j '.totals.tokens["claude-opus-5-5"]')" '{"input":1223,"output":171,"cache_read":1600,"cache_write_5m":200,"cache_write_1h":300}' "opus tokens once per message id and model, records outside the window dropped"
assert "$(j '.totals.tokens["claude-sonnet-5-5"] | [.input, .output]')" "[38,38]" "sonnet tokens: subagents counted, out-of-window subagent records dropped"
assert "$(j '.totals.tokens["claude-haiku-5-5"] | [.input, .output]')" "[5,5]" "haiku tokens"
assert "$(j '.totals.tokens["claude-unknown-9"] | [.input, .output]')" "[7,3]" "any model id keeps its tokens"
assert "$(j '.warnings')" '[]' "a clean run has no warnings"
assert "$(j '.sessions[0] | [.user_turns, .interrupts, .questions, .active_ms, .wall_ms]')" "[5,1,1,90000,1200000]" "user turns of each promptSource and a slash prompt, interrupts, questions, durations"
assert "$(j '.totals | [.user_turns, .interrupts, .questions, .active_ms, .wall_ms]')" "[6,1,1,90000,1201000]" "totals sum the sessions"
assert "$(j '.totals.tools | [.Skill, .Agent, .AskUserQuestion, .Bash, .Read, .["mcp__example_server__do_thing"]]')" "[6,3,1,2,1,1]" "tool counts"
assert "$(j '.totals.skills')" '{"superpowers:brainstorming":1,"example-project-skill":2,"example-synced-skill":1,"example-dot-skill":1,"_other_plugin":1,"simplify":1}' "skills: Skill calls and a slash prompt, an off-allowlist plugin as other"
assert "$(j '.totals.agents')" '{"general-purpose/sonnet":1,"example-custom-agent/default":1,"_other_plugin/default":1}' "agents by type and model"
assert "$(j '.totals.workflows | [.runs, .agents, .ms]')" "[1,2,5000]" "workflow runs, agents and time; a run before the window is left out"
assert "$(j '.totals.workflows.phases | map_values(.["claude-opus-5-5"].input)')" '{"Review":30,"Verify":40}' "tokens per workflow phase, and the summary's totalTokens adds none"
assert "$(j '.totals.by_lens | keys')" '["Consistency","Tests","Work context","other"]' "lenses are headings or other; an agent with no Lens line is under none"
assert "$(j '.totals.by_lens | map_values(map_values(.input))')" '{"Consistency":{"claude-sonnet-5-5":20,"claude-opus-5-5":30},"Tests":{"claude-sonnet-5-5":4},"Work context":{"claude-opus-5-5":40},"other":{"claude-sonnet-5-5":3}}' "tokens per lens: prompt Lens line, workflow description in either case, alias, unknown heading"
assert "$(j '.totals.by_agent_type | keys')" '["Explore","example-custom-agent","general-purpose","main","workflow-subagent"]' "tokens per agent type"
assert "$(j '.framework | [.dotfiles_commit == "'"$TREE_HEAD"'", .dotfiles_dirty, .claude_code_versions]')" '[true,false,["2.1.309"]]' "the framework's commit, dirty flag and Claude Code versions"
assert "$(j '.framework | [.plugins, .plugins_other]')" '[{"superpowers":{"version":"7.0.0","sha":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}},1]' "plugin versions by name for superpowers only, another plugin counted as other"
assert "$(j '.skills_outside')" '{"_other_plugin":"plugin","example-project-skill":"project","example-synced-skill":"synced","simplify":"builtin","superpowers:brainstorming":"plugin"}' "outside skills by source; the dotfiles' own are left out"
assert "$(j '.reviews | map([.kind, .rows, .done_round, .unfixed, .re_evaluations, .user_decisions])')" '[["code",1,1,0,0,0],["plan",2,2,1,1,1]]' "reviews: a log closed before the window start is left out, one closed on that date counted"
assert "$(j '.findings.plan | map_values(map_values(.))')" '{"Consistency":{"major":{"fixed":1,"refuted":0,"open":0}},"other":{"major":{"fixed":1,"refuted":0,"open":0}},"Tests":{"minor":{"fixed":0,"refuted":1,"open":0}},"Grounding":{"major":{"fixed":0,"refuted":0,"open":1}}}' "findings by lens, severity and outcome: Fixed, Refuted, neither"
assert "$(j '.findings.code')" '{"Fit with the surrounding code":{"blocking":{"fixed":1,"refuted":0,"open":0}}}' "findings of a closed log"

# The log clone: written, committed, pushed.
assert "$(gitin "$LOG" log -1 --format=%s)" "Record $ID1" "the entry is committed"
assert "$(gitin "$LOG" status --porcelain)" "" "the log clone is clean afterwards"
assert "$(gitin "$BARE" log -1 --format=%s)" "Record $ID1" "the commit reached the bare origin"
assert "$(out | sed -n 2,3p | head -1)" "level: personal" "the summary follows the entry line"

# A same-commit re-run adds no commit and keeps one entry.
before="$(log_commits)"
run_ai "$W1" record plan-example.md "$C1"
assert "$rc" "0" "a re-run for the same commit exits 0"
assert "$(log_commits)" "$before" "a same-commit re-run adds no commit"
assert "$(entry_count)" "1" "a same-commit re-run keeps one entry"

# --- No free text, at personal level --------------------------------------------------------------------------

markers=(PROMPT-MARKER QUESTION-MARKER ASSISTANT-TEXT-MARKER TOOL-INPUT-MARKER TOOL-OUTPUT-MARKER AGENT-PROMPT-MARKER SECRET-ARGS
  FINDING-MARKER branch-marker COMMIT-MARKER "$W1" "$workdir")
history="$(gitin "$BARE" log -p --all)"
found=""
for m in "${markers[@]}"; do
  if grep -qF -- "$m" "$ENTRY" || grep -qF -- "$m" <<< "$history" || out | grep -qF -- "$m"; then found+="$m "; fi
done
assert "$found" "" "no prompt, question, text, tool input or output, argument, branch, commit message, finding or path in the entry or the origin's history"

# --- Continuing a plan: the second run starts where the first ended ------------------------------------------

edit_plan() { sed -e 's/^## Review log (plan)$/## Review log (plan, closed 2026-01-12)/' \
  -e 's/^| 2 | 3 | 0 | 1 | 0 | 0 | 0 |$/&\n| 3 | 2 | 0 | 0 | 1 | 0 | 1 |/' \
  -e 's/^Done (plan): round 2; unfixed: R2-1$/Re-evaluation after round 3: stop\nDone (plan): round 3; unfixed: none/' "$1"; }
edit_plan "$W1/plan-example.md" > "$workdir/plan.new"
mv "$workdir/plan.new" "$W1/plan-example.md"
mv "$W1/plan-example-review-findings-plan.md" "$W1/plan-example-review-findings-plan-closed-2026-01-12.md"
printf '\n## Round 3\n\n### R3-1 · minor · Tests\nBody.\nFixed: ok.\n' >> "$W1/plan-example-review-findings-plan-closed-2026-01-12.md"
commit_at "$W1" 2026-01-12T12:00:00Z "second"
C2="$(gitin "$W1" rev-parse HEAD)"

run_ai "$W1" record plan-example.md "$C2"
ID2="$(out | head -1 | sed 's/^entry: //')"
ENTRY="$LOG/entries/$ID2.json"
assert "$rc" "0" "the second run exits 0"
assert "$(j '.window')" "{\"start\":\"2026-01-10T12:00:00.000Z\",\"end\":\"2026-01-12T12:00:00.000Z\",\"after\":\"$ID1\"}" "the second window starts at the first's end and names it in after"
assert "$(j '.sessions | length')" "1" "only the session naming the plan inside the new window"
assert "$(j '.totals.tokens["claude-opus-5-5"] | [.input, .output]')" "[300,30]" "the first run's tokens are not counted again"
assert "$(j '.reviews | map([.kind, .rows, .done_round, .unfixed, .re_evaluations, .user_decisions])')" '[["plan",1,3,0,1,0]]' "a log counted, then continued and closed, counts only its new rows"
assert "$(j '.findings')" '{"plan":{"Tests":{"minor":{"fixed":1,"refuted":0,"open":0}}}}' "and only their rounds' findings"
assert "$(jq -r '.reviews[] | select(.kind == "plan") | .key' "$LOG/entries/$ID1.json")" "$(jq -r '.reviews[0].key' "$ENTRY")" "closing a log keeps its key"

# Re-recording the first commit moves neither window.
run_ai "$W1" record --dry-run plan-example.md "$C1"
assert "$(out | jq -c '.window')" '{"start":"2026-01-09T10:00:00.000Z","end":"2026-01-10T12:00:00.000Z","after":null}' "re-recording the first run moves neither window"
assert "$(out | jq -r .id)" "$ID1" "re-recording the first run keeps its id"

# The framework tree's claude/ dirty or not: only a change under claude/ sets dotfiles_dirty.
echo outside > "$TREE/outside-claude.txt"
run_ai "$W1" record --dry-run plan-example.md "$C1"
assert "$(out | jq -c .framework.dotfiles_dirty)" "false" "a change outside claude/ leaves dotfiles_dirty false"
rm "$TREE/outside-claude.txt"
echo edit > "$TREE/claude/docs/dirty-marker.md"
run_ai "$W1" record --dry-run plan-example.md "$C1"
assert "$(out | jq -c .framework.dotfiles_dirty)" "true" "an untracked file under claude/ sets dotfiles_dirty"
rm "$TREE/claude/docs/dirty-marker.md"
echo changed >> "$TREE/claude/docs/review-lenses.md"
run_ai "$W1" record --dry-run plan-example.md "$C1"
assert "$(out | jq -c .framework.dotfiles_dirty)" "true" "a modified tracked file under claude/ sets dotfiles_dirty"
gitin "$TREE" checkout -q -- claude/docs/review-lenses.md
run_ai "$W1" record --dry-run plan-example.md "$C1"
assert "$(out | jq -c .framework.dotfiles_dirty)" "false" "and a clean tree is not dirty again"

# --- The summary sums every entry of the plan, then the introspection is stored -----------------------------------------

# A third window, on a commit that is not HEAD, so the later tests' HEAD stays put.
C3="$(cd "$W1" && GIT_COMMITTER_DATE=2026-01-14T12:00:00Z GIT_AUTHOR_DATE=2026-01-14T12:00:00Z git commit-tree -p "$C2" -m third "$C2^{tree}")"
# Its session: the second window's session again, a day later.
cp -R "$workdir/projects1" "$workdir/projects1b"
sed 's/2026-01-11/2026-01-13/g' "$workdir/projects1/-example-work/s5.jsonl" > "$workdir/projects1b/-example-work/s6.jsonl"
# It also gets two general-purpose agent calls and a workflow agent in the Review phase (12 tokens), so a later window
# adds to the summary's agents and phases too.
P6="$workdir/projects1b/-example-work"
jq -c -n --arg cwd "$W1" '{type: "assistant", uuid: "z-ag", timestamp: "2026-01-13T10:00:02.000Z", isSidechain: false, cwd: $cwd, version: "2.1.309",
  message: {id: "z-ag-m", model: "claude-opus-5-5", content: [range(2) | {type: "tool_use", id: "za\(.)", name: "Agent", input: {subagent_type: "general-purpose", model: "sonnet"}}],
  usage: {input_tokens: 1, output_tokens: 1}}}' >> "$P6/s6.jsonl"
mkdir -p "$P6/s6/workflows" "$P6/s6/subagents/workflows/wf_bbb"
jq -c -n '{runId: "wf_bbb", timestamp: "2026-01-13T10:00:03.000Z", agentCount: 1, durationMs: 1000, status: "completed"}' > "$P6/s6/workflows/wf_bbb.json"
printf '%s\n' '{"agentType":"workflow-subagent","description":"review:TESTS","workflowPhase":"Review","model":"opus"}' > "$P6/s6/subagents/workflows/wf_bbb/agent-w9.meta.json"
jq -c -n --arg cwd "$W1" '{type: "assistant", uuid: "z-w9", timestamp: "2026-01-13T10:00:04.000Z", isSidechain: true, cwd: $cwd, version: "2.1.309",
  message: {id: "z-w9-m", model: "claude-opus-5-5", content: [{type: "text", text: "x"}],
  usage: {input_tokens: 10, output_tokens: 2, cache_read_input_tokens: 0, cache_creation_input_tokens: 0}}}' > "$P6/s6/subagents/workflows/wf_bbb/agent-w9.jsonl"
PROJ="$workdir/projects1b" run_ai "$W1" record plan-example.md "$C3"
ID3="$(out | head -1 | sed 's/^entry: //')"
assert "$rc" "0" "a third window records"
assert "$(entry_count)" "3" "three entries of one plan"
summary="$(out)"
assert "$(grep -c '^  windows: 3$' <<< "$summary")" "1" "the summary counts all three windows"
exp_tok="$(jq -s '[.[] | .sessions[] | .tokens // {} | .[] | .input + .output + .cache_read + .cache_write_5m + .cache_write_1h] | add' "$LOG"/entries/*.json)"
got_tok="$(grep '^  tokens per session:' <<< "$summary" | grep -oE 'w[0-9]+s[0-9]+ [0-9]+' | awk '{ s += $2 } END { print s }')"
assert "$got_tok" "$exp_tok" "tokens per session add up to the tokens of every session of every window"
assert "$(grep '^  tokens per session:' <<< "$summary" | grep -oE 'w[0-9]+s[0-9]+' | cut -c1-2 | sort -u | tr '\n' ' ')" "w1 w2 w3 " "and cover all three windows"
assert "$(grep '^  rounds and majors per review kind:' <<< "$summary")" "  rounds and majors per review kind: code 1 rounds, 0 majors, plan 3 rounds, 3 majors" "rounds and majors are summed over the windows, not the last one's"
exp_turns="$(jq -s '[.[] | .totals.user_turns] | add' "$LOG"/entries/*.json)"
exp_questions="$(jq -s '[.[] | .totals.questions] | add' "$LOG"/entries/*.json)"
assert "$(grep '^  user turns:' <<< "$summary")" "  user turns: $exp_turns, questions: $exp_questions" "user turns and questions are summed"
assert "$(jq -c '[.totals.agents // {} | keys[] | select(startswith("general-purpose/"))] | length' "$LOG/entries/$ID3.json")" "1" "(setup) the third window holds agents of its own"
assert "$(jq -r '.totals.workflows.phases.Review["claude-opus-5-5"] | .input + .output' "$LOG/entries/$ID3.json")" "12" "(setup) and a Review phase of 12 tokens"
exp_gp="$(jq -s '[.[] | .totals.agents // {} | to_entries[] | select(.key | startswith("general-purpose/")) | .value] | add' "$LOG"/entries/*.json)"
assert "$exp_gp" "3" "(setup) three general-purpose agents over the windows"
assert "$(grep '^  agents per type:' <<< "$summary" | grep -o 'general-purpose [0-9]*')" "general-purpose $exp_gp" "agents are summed per type over the windows"
exp_review="$(jq -s '[.[] | .totals.workflows.phases.Review // {} | .[] | .input + .output + .cache_read + .cache_write_5m + .cache_write_1h] | add' "$LOG"/entries/*.json)"
assert "$(grep '^  workflow phases, tokens:' <<< "$summary" | grep -o 'Review [0-9]*')" "Review $exp_review" "workflow phase tokens are summed over the windows"
assert "$([[ "$exp_review" -gt 12 ]] && echo more)" "more" "(setup) and the first window adds to them"
assert "$(grep -ciE 'cost|price|usd|[$]' <<< "$summary")" "0" "the summary has no money in it"
assert "$(tail -1 <<< "$summary")" "Pipe it to: ai-log note $ID3" "the summary ends with the note command"
assert "$(grep -c '^introspect: .*## Worked.*## Didn.t.*## Cut candidates' <<< "$summary")" "1" "and names the three headings"

note_text=$'## Worked\n- Two rounds were enough for the plan (2 rounds)\n## Didn\'t\n- A third window repeated work (3 windows)\n## Cut candidates\n- Nothing to cut yet (no evidence)\n'
head_before="$(gitin "$LOG" rev-parse HEAD)"
run_note "$W1" "$ID1" "$note_text"
assert "$rc" "0" "note exits 0"
assert "$(cmp -s "$LOG/entries/$ID1.md" "$workdir/out" && echo same)" "same" "note prints what it wrote"
assert "$(cat "$LOG/entries/$ID1.md")" "${note_text%$'\n'}" "plain text passes through"
assert "$(gitin "$LOG" log -1 --format=%s):$(gitin "$LOG" status --porcelain)" "Note $ID1:" "the note is committed, the clone clean"
assert "$(gitin "$BARE" show "HEAD:entries/$ID1.md")" "${note_text%$'\n'}" "and pushed to the bare origin"
before="$(log_commits)"
run_note "$W1" "$ID1" "$note_text"
assert "$rc:$(log_commits)" "0:$before" "the same note again adds no commit"
note_text2=$'## Worked\n- Something else (1 round)\n## Didn\'t\n- Nothing (none)\n## Cut candidates\n- Nothing (none)\n'
run_note "$W1" "$ID1" "$note_text2"
assert "$rc" "0" "a re-run exits 0"
assert "$(cat "$LOG/entries/$ID1.md")" "${note_text2%$'\n'}" "a re-run replaces the file"
assert "$(log_commits)" "$((before + 1))" "with one more commit"
assert "$(find "$LOG/entries" -name '*.md' | wc -l | tr -d ' ')" "1" "one .md for the entry"

# The failures: nothing is written, and the file stays.
head_before="$(gitin "$LOG" rev-parse HEAD)"
run_note "$W1" "2026-01-10-000000000000" "$note_text"
assert "$rc" "1" "note: an id with no entry exits 1"
assert "$(err | grep -c 'no entry')" "1" "and says so"
run_note "$W1" "../README" "$note_text"
assert "$rc" "1" "note: an id that is a path exits 1"
run_note "$W1" "$ID1" ""
assert "$rc" "2" "note: no input exits 2"
run_note "$W1" "$ID1" $'  \n\n'
assert "$rc" "2" "note: blank input exits 2"
for h in "Worked" "Didn't" "Cut candidates"; do
  run_note "$W1" "$ID1" "$(grep -v "^## $h\$" <<< "$note_text2")"
  assert "$rc:$(err | grep -c "## $h")" "2:1" "note: no '## $h' heading exits 2 and names it"
done
run_note "$W1" "$ID1" "${note_text2//## Worked/## worked}"
assert "$rc" "2" "note: a heading in another case does not count"
run_note "$W1" "$ID1" "${note_text2//## Worked/### Worked}"
assert "$rc" "2" "note: a heading of another level does not count"
run_note "$W1" "$ID1" "- no heading at all"
assert "$rc" "2" "note: text with no heading exits 2"
(cd "$W1" && "$AI" note > /dev/null 2>&1) && rc=0 || rc=$?
assert "$rc" "2" "note: no id is a usage error"
(cd "$W1" && "$AI" note a b > /dev/null 2>&1) && rc=0 || rc=$?
assert "$rc" "2" "note: two ids are a usage error"
assert "$(gitin "$LOG" rev-parse HEAD):$(cat "$LOG/entries/$ID1.md")" "$head_before:${note_text2%$'\n'}" "the failures changed neither the log nor the file"
mkdir -p "$workdir/badjq2"
printf '#!/bin/sh\nexit 5\n' > "$workdir/badjq2/jq"
chmod +x "$workdir/badjq2/jq"
PATH="$workdir/badjq2:$PATH" run_note "$W1" "$ID1" "$note_text"
assert "$rc" "3" "note: a failing jq is an internal error, exit 3"
assert "$(gitin "$LOG" rev-parse HEAD):$(cat "$LOG/entries/$ID1.md")" "$head_before:${note_text2%$'\n'}" "and writes nothing"
LOG="$workdir/plain-dir" run_note "$W1" "$ID1" "$note_text"
assert "$rc" "2" "note: AI_LOG_DIR that is not a clone exits 2"
LOG="$workdir/log1"

# A record re-run keeps an existing .md; the plan has moved on since, so the entry itself is rewritten.
run_ai "$W1" record plan-example.md "$C1"
assert "$rc:$(cat "$LOG/entries/$ID1.md")" "0:${note_text2%$'\n'}" "a record re-run keeps the .md"
assert "$(gitin "$LOG" ls-files "entries/$ID1.md"):$(gitin "$LOG" status --porcelain)" "entries/$ID1.md:" "and the .md stays tracked in a clean clone"

# No commit given: the window ends now, with --dry-run or not; two runs at one HEAD make one entry, the later window.
new_log log2
run_ai "$W1" record --dry-run plan-example.md
assert "$rc" "0" "--dry-run without a commit exits 0"
assert "$(out | jq -r '.window.end > "2026-06"')" "true" "no commit: the window ends now"
assert "$(out | jq '.sessions | length')" "3" "a window ending now takes in later sessions"
assert "$(out | jq -r .commit)" "$C2" "no commit: HEAD names the entry"
assert "$(entry_count)" "0" "--dry-run writes no entry"
assert "$(gitin "$LOG" status --porcelain)" "" "--dry-run leaves the log clone clean"
run_ai "$W1" record plan-example.md
id_now="$(out | head -1 | sed 's/^entry: //')"
end_first="$(jq -r .window.end "$LOG/entries/$id_now.json")"
sleep 0.05
run_ai "$W1" record plan-example.md
end_second="$(jq -r .window.end "$LOG/entries/$id_now.json")"
assert "$(entry_count)" "1" "two runs at one HEAD make one entry"
assert "$([[ "$end_second" > "$end_first" ]] && echo later)" "later" "the later run's window wins"

# A given commit no newer than the window's start: exit 1, with or without --dry-run.
new_log log3
run_ai "$W1" record plan-example.md "$C0"
assert "$rc" "1" "a commit before the plan's first appearance exits 1"
assert "$(entry_count)" "0" "and writes nothing"
run_ai "$W1" record --dry-run plan-example.md "$C0"
assert "$rc" "1" "--dry-run on such a commit exits 1"

# --- A resumed session repeating earlier records counts them once --------------------------------------------

new_log log4
cp -R "$workdir/$PROJ_NAME" "$workdir/projects-resumed"
cp "$workdir/projects-resumed/-example-work/s1.jsonl" "$workdir/projects-resumed/-example-work/s1b.jsonl"
jq -c -n --arg cwd "$W1" '{type: "assistant", uuid: "r-new", timestamp: "2026-01-09T10:21:00.000Z", cwd: $cwd, version: "2.1.309",
  message: {id: "m-resumed", model: "claude-opus-5-5", content: [{type: "text", text: "x"}], usage: {input_tokens: 5, output_tokens: 0}}}' \
  >> "$workdir/projects-resumed/-example-work/s1b.jsonl"
PROJ="$workdir/projects-resumed"
run_ai "$W1" record --dry-run plan-example.md "$C1"
assert "$(out | jq -c '[(.sessions | length), .totals.tokens["claude-opus-5-5"].input, .sessions[1].tokens["claude-opus-5-5"].input, .totals.user_turns]')" "[3,1228,5,6]" "a resumed session's file counts the repeated records once, each in the session that first holds it"
PROJ="$workdir/$PROJ_NAME"

# --- Drift degrades loudly ----------------------------------------------------------------------------------------

new_log log5
cp -R "$workdir/$PROJ_NAME" "$workdir/projects-nousage"
while IFS= read -r f; do
  jq -c 'if .type == "assistant" then del(.message.usage) else . end' "$f" > "$f.new" && mv "$f.new" "$f"
done < <(find "$workdir/projects-nousage" -name '*.jsonl')
PROJ="$workdir/projects-nousage"
run_ai "$W1" record plan-example.md "$C1"
assert "$rc" "0" "no usage: exit 0"
ENTRY="$LOG/entries/$(out | head -1 | sed 's/^entry: //').json"
assert "$(j '.totals.tokens')" "null" "no usage: the field is null"
assert "$(j '.warnings | map(select(test("had no usage"))) | length')" "1" "no usage: a warning in the entry"
assert "$(err | grep -c 'had no usage')" "1" "no usage: a warning on stderr"

cp -R "$workdir/$PROJ_NAME" "$workdir/projects-garbage"
echo 'this is not json' >> "$workdir/projects-garbage/-example-work/s2.jsonl"
PROJ="$workdir/projects-garbage"
new_log log6
run_ai "$W1" record --dry-run plan-example.md "$C1"
assert "$rc" "0" "a line that is not JSON: exit 0"
assert "$(out | jq -c '.warnings | map(select(test("not JSON"))) | length')" "1" "a line that is not JSON: a warning in the entry"
assert "$(err | grep -c 'not JSON')" "1" "a line that is not JSON: a warning on stderr"
assert "$(out | jq '.totals.tokens["claude-opus-5-5"].input')" "1223" "and the other lines still count"
PROJ="$workdir/$PROJ_NAME"

PLUGINS="$workdir/no-such-plugins.json" run_ai "$W1" record --dry-run plan-example.md "$C1"
assert "$(out | jq -c '[.framework.plugins, (.warnings | map(select(test("installed_plugins"))) | length)]')" "[null,1]" "a missing plugins file: null and a warning"

printf 'unrelated\n' > "$W1/plan-nothing.md"
run_ai "$W1" record plan-nothing.md "$C1"
assert "$rc" "1" "a plan no session names: no session in scope, exit 1"
run_ai "$W1" record plan-missing.md
assert "$rc" "1" "no plan file: exit 1"
assert "$(err | grep -c 'no such plan file')" "1" "no plan file: says so"
assert "$(entry_count)" "0" "exit 1 writes nothing"

# A heading that is not a finding heading (no lens) warns and the entries after it still count: it once crashed the run.
new_work work5 git@github.com:andrelin/x.git
W5="$W"
new_projects projects5 "$W5"
PROJ="$workdir/projects5"
new_log log12
printf '\n### R1-2 · major\nA heading with no lens.\n\n### R1-3 · minor · Tests\nBody.\n' >> "$W5/plan-example-review-findings-code-closed-2026-01-09.md"
run_ai "$W5" record --dry-run plan-example.md "$C1"
assert "$rc" "0" "an unparseable findings heading: exit 0"
assert "$(out | jq -c '.warnings')" '["1 review-log or findings heading(s) could not be parsed"]' "an unparseable findings heading: one warning in the entry"
assert "$(out | jq -c '.findings.code | map_values(keys)')" '{"Fit with the surrounding code":["blocking"],"Tests":["minor"]}' "the findings after it still count"
PROJ="$workdir/$PROJ_NAME"

# A second log closed the same day (inside the window) is headed `closed <date>-2` and pairs with the findings file named so.
new_work work5b git@github.com:andrelin/x.git
W5B="$W"
new_projects projects5b "$W5B"
PROJ="$workdir/projects5b"
new_log log12b
python3 - "$W5B/plan-example.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
s = s.replace("## Review log (plan, closed 2026-01-05)", "## Review log (plan, closed 2026-01-10)")
s = s.replace("## Review log (code, closed 2026-01-09)", """## Review log (plan, closed 2026-01-10-2)

| Round | Lenses | Blocking | Major | Minor | Nit | Fixed |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 3 | 0 | 0 | 1 | 0 | 1 |

Done (plan): round 1; unfixed: none

## Review log (code, closed 2026-01-09)""", 1)
open(p, "w").write(s)
PY
printf '# Review findings\n\n## Round 1\n\n### R1-1 · nit · Consistency\n\nBody.\nFixed: ok.\n' \
  > "$W5B/plan-example-review-findings-plan-closed-2026-01-10-2.md"
mv "$W5B/plan-example-review-findings-plan-closed-2026-01-05.md" "$W5B/plan-example-review-findings-plan-closed-2026-01-10.md"
run_ai "$W5B" record --dry-run plan-example.md "$C1"
assert "$rc" "0" "a log closed a second time that day: exit 0"
assert "$(out | jq -c '.warnings // []')" '[]' "a closed <date>-2 heading parses without a warning"
assert "$(out | jq -c '.findings.plan.Consistency | [.nit.fixed, .major.fixed]')" '[1,2]' "and pairs with its -2 findings file, the first with its own"
# A Done line whose ids pass 150 characters wraps onto the lines below it, the section's last; every id counts.
perl -pi -e 's/^Done \(plan\): round 2; unfixed: R2-1$/Done (plan): round 2; unfixed: R2-1,\nR1-3, R1-4/' "$W5B/plan-example.md"
run_ai "$W5B" record --dry-run plan-example.md "$C1"
assert "$(out | jq -c '[.reviews[] | select(.kind == "plan" and .done_round == 2) | .unfixed]')" '[3]' \
  "a Done line wrapped onto the next line counts every id"
PROJ="$workdir/$PROJ_NAME"

# --- Company level, the edges: free-text names, phases, a broken meta file ------------------------------------------------

new_work work6 git@github.com:uptimeconsulting/x.git
W6="$W"
mkdir -p "$W6/.claude/skills/example-project-skill"
new_projects projects7 "$W6"
PROJ="$workdir/projects7"
p7="$PROJ/-example-work"
jq -c -n --arg cwd "$W6" '{type: "user", uuid: "c-slash", timestamp: "2026-01-09T10:05:40.000Z", cwd: $cwd, version: "2.1.309",
  message: {role: "user", content: "<command-name>/example-command</command-name><command-args>x</command-args>"}}' >> "$p7/s1.jsonl"
jq -c -n --arg cwd "$W6" '{type: "assistant", uuid: "c-skills", timestamp: "2026-01-09T10:05:41.000Z", cwd: $cwd, version: "2.1.309",
  message: {id: "m-c", model: "claude-opus-5-5", content: [{type: "tool_use", id: "t", name: "Skill", input: {skill: "example/nested-skill"}},
  {type: "tool_use", id: "t2", name: "Skill", input: {skill: "example-ghost"}}], usage: {input_tokens: 1, output_tokens: 1}}}' >> "$p7/s1.jsonl"
meta="$p7/s1/subagents/workflows/wf_aaa"
jq '.workflowPhase = "Migrate billing for EXAMPLE-PHASE-MARKER"' "$meta/agent-w1.meta.json" > "$meta/x.json" && mv "$meta/x.json" "$meta/agent-w1.meta.json"
jq '.description = "review:workcontext"' "$meta/agent-w2.meta.json" > "$meta/x.json" && mv "$meta/x.json" "$meta/agent-w2.meta.json"
echo 'not json' > "$p7/s1/subagents/agent-ag4.meta.json"
new_log log15
run_ai "$W6" record --dry-run plan-example.md "$C1"
assert "$rc" "0" "company edges: exit 0"
assert "$(out | jq -c '.totals.skills | [keys[] | select(test("example-command|nested|ghost"))] | length')" "0" "company: a project command, a path-like skill and an unknown skill are not named"
assert "$(out | jq -c '.totals.skills._project')" "5" "company: they count as project skills"
assert "$(out | jq -c '.redacted.project_skills')" "4" "company: four distinct project names counted"
assert "$(out | jq -c '.totals.skills.simplify')" "1" "company: a known built-in keeps its name"
assert "$(out | jq -c '.totals.workflows.phases | keys')" '["Verify","other"]' "a phase outside the known set is other"
assert "$(out | jq -c '.totals.by_lens["Work context"]["claude-opus-5-5"].input')" "40" "the workcontext alias lands in Work context"
assert "$(out | jq -c '.warnings | map(select(test("meta.json could not be read"))) | length')" "1" "a broken .meta.json warns in the entry, not only on stderr"
assert "$(out | grep -c -E 'EXAMPLE-PHASE-MARKER|example-command|nested-skill|example-ghost')" "0" "no phase text or project name in the output"

# --- Candidate scan: only this repo's project directories when some match -------------------------------------------------

new_projects projects8 "$W1"
p8="$workdir/projects8"
enc="$(printf '%s' "$W1" | sed 's/[^A-Za-z0-9]/-/g')"
mkdir -p "$p8/$enc" "$p8/$enc-sub" "$p8/-example-decoy"
mv "$p8/-example-work/s1.jsonl" "$p8/-example-work/s1" "$p8/$enc/"
mv "$p8/-example-work/s2.jsonl" "$p8/$enc-sub/"
jq -c -n --arg cwd "$W1" '{type: "assistant", uuid: "d1", timestamp: "2026-01-09T11:30:00.000Z", cwd: $cwd, version: "2.1.309",
  message: {id: "m-d", model: "claude-opus-5-5", content: [{type: "tool_use", id: "t", name: "Bash", input: {command: "cat plan-example.md"}}],
  usage: {input_tokens: 7777, output_tokens: 1}}}' > "$p8/-example-decoy/s6.jsonl"
PROJ="$p8"
new_log log16
run_ai "$W1" record --dry-run plan-example.md "$C1"
assert "$(out | jq -c '[(.sessions | length), .totals.tokens["claude-opus-5-5"].input]')" "[2,1223]" "a matching project directory and its -suffixed ones are scanned, other directories are not"

# --- A dry run only fetches: it sees origin's newer entries and leaves the clone alone ----------------------------------

new_log log17
git clone -q "$BARE" "$workdir/log17b" 2> /dev/null
PROJ="$workdir/$PROJ_NAME"
run_ai "$W1" record plan-example.md "$C1"
first_id="$(out | head -1 | sed 's/^entry: //')"
LOG="$workdir/log17b"
head_b="$(gitin "$LOG" rev-parse HEAD)"
run_ai "$W1" record --dry-run plan-example.md "$C2"
assert "$(out | jq -c '.window.after')" "\"$first_id\"" "a dry run reads entries newer on origin"
assert "$(gitin "$LOG" rev-parse HEAD):$(gitin "$LOG" status --porcelain):$(ls "$LOG")" "$head_b::README.md" "a dry run leaves the clone's branch and files alone"

# --- bash 3.2 ------------------------------------------------------------------------------------------------------------

if [[ -x /bin/bash ]] && (( $(/bin/bash -c 'echo "${BASH_VERSINFO[0]}"') < 5 )); then
  /bin/bash "$AI" level > "$workdir/out" 2> "$workdir/err" && rc=0 || rc=$?
  assert "$rc" "2" "under bash older than 5: exit 2"
  assert "$(err | grep -c 'needs bash 5')" "1" "under bash older than 5: says what is needed"
fi

# --- Usage errors ---------------------------------------------------------------------------------------------------

run_ai "$W1"
assert "$rc" "2" "no subcommand: exit 2"
run_ai "$W1" record --bogus plan-example.md
assert "$rc" "2" "a bad option: exit 2"
run_ai "$W1" record
assert "$rc" "2" "record without a plan: exit 2"
run_ai "$W1" record a b c
assert "$rc" "2" "too many arguments: exit 2"
run_ai "$W1" record plan-example.md no-such-commit
assert "$rc" "2" "a commit that does not exist: exit 2"
run_ai "$W1" level extra
assert "$rc" "2" "level with an argument: exit 2"
run_ai "$workdir" level
assert "$rc" "2" "level outside a git repository: exit 2"

LOG="$workdir/no-such-clone" run_ai "$W1" record plan-example.md "$C1"
assert "$rc" "2" "a missing AI_LOG_DIR: exit 2"
assert "$(err | grep -c 'gh repo clone andrelin/ai-framework-log')" "1" "and the message names the clone command"
mkdir -p "$workdir/plain-dir"
LOG="$workdir/plain-dir" run_ai "$W1" record plan-example.md "$C1"
assert "$rc" "2" "AI_LOG_DIR that is not a git clone: exit 2"
LOG="$W1/sub" run_ai "$W1" record plan-example.md "$C1"
assert "$rc" "2" "AI_LOG_DIR inside another repository, not its top: exit 2"
LOG="$workdir/log6"

# An internal failure is reported with exit 3, never jq's own status: a stub jq that always fails.
mkdir -p "$workdir/badjq"
printf '#!/bin/sh\nexit 5\n' > "$workdir/badjq/jq"
chmod +x "$workdir/badjq/jq"
new_log log13
PATH="$workdir/badjq:$PATH" run_ai "$W1" record plan-example.md "$C1"
assert "$rc" "3" "a failing jq is an internal error, exit 3"
assert "$(err | grep -c 'internal error')" "1" "and says so once"
assert "$(entry_count)" "0" "and writes nothing"

# A jq that fails only for one call, the rest running the real one: each jq that feeds a loop must fail the run with exit 3,
# not leave the loop an empty stream and an entry with missing parts committed with exit 0.
nlog=0
real_jq="$(command -v jq)"
function stub_jq_failing_on() {
  mkdir -p "$workdir/pickyjq"
  printf '#!/bin/bash\ncase "$*" in *"%s"*) exit 5 ;; esac\nexec %q "$@"\n' "$1" "$real_jq" > "$workdir/pickyjq/jq"
  chmod +x "$workdir/pickyjq/jq"
}
for failing in ".parsed[].keysrc" ".plugins | keys[]" ".slash else empty end | select(. != null)" ".new_warnings[]"; do
  new_log "log13b-$((++nlog))"
  stub_jq_failing_on "$failing"
  PLUGINS="$FIX/installed_plugins.json" PATH="$workdir/pickyjq:$PATH" run_ai "$W1" record plan-example.md "$C1"
  assert "$rc:$(err | grep -c 'internal error')" "3:1" "a jq failing on '$failing' (feeding a loop) is exit 3, not an entry with missing parts"
  assert "$(entry_count):$(gitin "$LOG" status --porcelain)" "0:" "'$failing': nothing is written or staged"
done
# A jq that fails after the entry is written: exit 3, and the message says the entry may already be there.
new_log "log13c-$((++nlog))"
stub_jq_failing_on "windows:"
PATH="$workdir/pickyjq:$PATH" run_ai "$W1" record plan-example.md "$C1"
assert "$rc" "3" "a jq failing while the summary prints, after the write: exit 3"
assert "$(err | grep -c 'the entry may already be written or committed')" "1" "and the message says the entry may already be written"
assert "$(entry_count)" "1" "and the entry is in the log clone"

# --- Origins: ssh and https give the same id ------------------------------------------------------------------------

new_log log7
ids=""
for url in git@github.com:andrelin/x.git https://github.com/andrelin/x ssh://git@GitHub.com:22/Andrelin/X.git https://user@github.com/andrelin/x.git git@github.com-personal:andrelin/x.git git@work_github.com:andrelin/x.git; do
  gitin "$W1" remote set-url origin "$url"
  run_ai "$W1" record --dry-run plan-example.md "$C1"
  ids+="$(out | jq -r .id) "
done
assert "$(printf '%s\n' $ids | sort -u | wc -l | tr -d ' '):$(printf '%s' "$ids" | wc -w | tr -d ' ')" "1:6" "ssh, https, user-qualified, mixed-case and ssh-alias (github.com-personal, work_github.com) origins give the same id"
# A local-path origin is no remote: no origin to hash an id from, so ai-log defers it whatever the guard says.
for url in /srv/git/x.git ./x.git ../x.git; do
  gitin "$W1" remote set-url origin "$url"
  run_ai "$W1" level
  assert "$(out)" "customer" "level: a local-path origin ($url) is not recorded"
  assert "$(err | grep -c 'no origin')" "1" "level: and says the repository has no origin ($url)"
done
gitin "$W1" remote set-url origin git@github.com:andrelin/x.git

# --- The log clone ----------------------------------------------------------------------------------------------------

# An unreachable origin: a warning, exit 0, the commit kept. Then another clone pushes first and ours is rebased over it.
new_log log8
mv "$BARE" "$BARE.gone"
run_ai "$W1" record plan-example.md "$C1"
assert "$rc" "0" "an unreachable origin: exit 0"
assert "$(err | grep -c 'git push from the log clone failed')" "1" "an unreachable origin: a warning"
assert "$(gitin "$LOG" log -1 --format=%s | cut -c1-7)" "Record " "an unreachable origin: the commit is kept"
mv "$BARE.gone" "$BARE"
git clone -q "$BARE" "$workdir/other-clone" 2> /dev/null
echo other > "$workdir/other-clone/other.txt"
gitin "$workdir/other-clone" add other.txt
gitin "$workdir/other-clone" commit -q -m "Another machine's commit"
gitin "$workdir/other-clone" push -q origin HEAD 2> /dev/null
run_ai "$W1" record plan-example.md "$C2"
assert "$rc" "0" "a commit pushed first by another clone: exit 0"
assert "$(gitin "$BARE" log --format=%s | grep -c "Another machine's commit")" "1" "the other clone's commit is in the origin"
assert "$(gitin "$BARE" log --format=%s | grep -c '^Record ')" "2" "both of this clone's commits were rebased over it and pushed"
assert "$(gitin "$LOG" rev-list --count '@{u}..HEAD')" "0" "nothing is left unpushed"

# A dry-run writes nothing.
new_log log9
head_before="$(gitin "$LOG" rev-parse HEAD)"
run_ai "$W1" record --dry-run plan-example.md "$C1"
assert "$(gitin "$LOG" rev-parse HEAD):$(entry_count):$(gitin "$LOG" status --porcelain)" "$head_before:0:" "--dry-run writes nothing and commits nothing"

# --- Company level: names hashed or counted -----------------------------------------------------------------------

new_work work2 git@github.com:uptimeconsulting/x.git
W2="$W"
mkdir -p "$W2/.claude/skills/example-project-skill"
new_projects projects2 "$W2"
PROJ="$workdir/projects2"
new_log log10
assert "$(cd "$W2" && "$AI" level)" "company" "ai-log level: a company origin"
run_ai "$W2" record plan-example.md "$C1"
ENTRY="$LOG/entries/$(out | head -1 | sed 's/^entry: //').json"
assert "$rc" "0" "company level records"
assert "$(j '[.level, (.repo | test("^[0-9a-f]{12}$")), (.plan | test("^[0-9a-f]{12}$"))]')" '["company",true,true]' "company: repo and plan are hashes"
assert "$(j '.totals.skills')" '{"superpowers:brainstorming":1,"_project":2,"example-synced-skill":1,"example-dot-skill":1,"_other_plugin":1,"simplify":1}' "company: project skills counted, not named"
assert "$(j '.totals.agents')" '{"general-purpose/sonnet":1,"_custom_agent/default":1,"_other_plugin/default":1}' "company: custom agent types counted, not named"
assert "$(j '.totals.tools | [has("mcp__example_server__do_thing"), ._mcp]')" "[false,1]" "company: MCP tools counted, not named"
assert "$(j '.totals.by_agent_type | keys')" '["Explore","_custom_agent","general-purpose","main","workflow-subagent"]' "company: agent types in the aggregates are counted too"
assert "$(j '.redacted')" '{"project_skills":1,"other_plugin_skills":1,"custom_agent_types":1,"mcp_tools":1}' "company: the redacted names are counted"
assert "$(j '.skills_outside | has("example-project-skill")')" "false" "company: no project skill name in skills_outside"
history="$(gitin "$BARE" log -p --all)"
found=""
for m in "${markers[@]}" example-project-skill example-custom-agent example_server "$W2"; do
  if grep -qF -- "$m" "$ENTRY" || grep -qF -- "$m" <<< "$history"; then found+="$m "; fi
done
assert "$found" "" "company: no free text and no redacted name in the entry or the origin's history"

# --- note redacts what names a customer, mechanically ------------------------------------------------------------------

home2="$workdir/home2"
mkdir -p "$home2/clients/dirclient"
# shellcheck disable=SC2088
printf '%s\n' '# the customers' '' 'gitlab.example.com/example-owner' 'clienthost.example.net' '~/clients/dirclient' 'Acme Holding' \
  'Zetaco # an abbreviation' 'www.gitlab.zzcorp.example' '"Quoted Corp"' '$HOME/clients/second' \
  'https://git.urlcorp.example.org/urlowner/repo.git' 'git@git.scpcorp.example.org:scpowner/app.git' 'clients/rel-dir' \
  > "$home2/.claude-customers"
new_work workred git@github.com:andrelin/redactrepo.git
W5="$W"
gitin "$W5" remote add mirror https://git.mirror.example.net/mirrorowner/x.git
new_projects projectsred "$W5"
PROJ="$workdir/projectsred"
new_log logred
HOME="$home2" run_ai "$W5" level
assert "$(out)" "personal" "the redaction repo is personal work"
# The records here run without the customers file: its "example" label would, rightly, refuse the fixtures' own example-* names.
run_ai "$W5" record plan-example.md "$C1"
ID5="$(out | head -1 | sed 's/^entry: //')"
assert "$rc" "0" "the redaction repo records"
redact_in=$'## Worked\n'
redact_in+=$'- ACME HOLDING and acme-holding-tools and ZETACO_api, quoted corp and QUOTED-CORP-x were fine (2 rounds).\n'
redact_in+=$'- Checked GitLab.Example.com/Example-Owner and CLIENTHOST.EXAMPLE.NET, then Example-Owner-app and ClientHost-web (see counts).\n'
redact_in+=$'- Notes in ~/clients/DirClient/Notes and ~/clients/second/a and ~/clients/rel-dir/b held up, so did dirclient-x and REL-DIR (1 window).\n'
redact_in+=$'## Didn\'t\n'
redact_in+=$'- Mail bob@mailer.example.org about https://git.urlcorp.example.org/urlowner/repo.git and git@git.scpcorp.example.org:scpowner/app.git failed (0 fixes).\n'
redact_in+=$'- Hosts git.urlcorp.example.org and URLOWNER and scpowner-api and zzcorp-tools leaked (4 words).\n'
redact_in+=$'- Token ghp_abcdefghijklmnopqrstuvwxyz0123456789 and AKIAABCDEFGHIJKLMNOP and github_pat_11ABCDEFG0abcdefghij and glpat-abcdefghij1234 and sk-abcdefghij1234567890abcd and xoxb-123456789012-abcdef and '
redact_in+=$'0123456789abcdef0123456789abcdef01234567 leaked (7 tokens).\n'
redact_in+=$'- andrelin pushed redactrepo and mirrorowner/x to git.mirror.example.net from C:\\Users\\bob\\repo and /var/tmp/some/dir and /etc (1 push).\n'
redact_in+=$'## Cut candidates\n'
redact_in+=$'- Keep SKILL.md, README.md, bin/ai-log, /reviewing-in-rounds, 5.5.0, e.g. gitlab and www and x, marker and branch-marker-y unchanged (no evidence).\n'
run_note_home2() { HOME="$home2" run_note "$@"; }
run_note_home2 "$W5" "$ID5" "$redact_in"
assert "$rc" "0" "note with names exits 0"
redacted="$(cat "$workdir/out")"
assert "$(cmp -s "$LOG/entries/$ID5.md" "$workdir/out" && echo same)" "same" "the file holds what was printed"
assert "$(gitin "$BARE" show "HEAD:entries/$ID5.md")" "$redacted" "and so does the origin"
function redacted_line() { grep -F -- "$1" <<< "$redacted"; }
assert "$(sed -n 1p <<< "$redacted")" "## Worked" "headings stay"
assert "$(redacted_line 'were fine')" "- [customer] and [customer]-tools and [customer]_api, [customer] and [customer]-x were fine (2 rounds)." "a name, a name with a space or quotes, in another case, inside a hyphenated word or after an underscore"
assert "$(redacted_line 'see counts')" "- Checked [customer] and [host], then [customer]-app and [customer]-web (see counts)." "an owner pair, a host and a host's label, in another case and inside a hyphenated word"
assert "$(redacted_line '1 window')" "- Notes in [path] and [path] and [path] held up, so did [customer]-x and [customer] (1 window)." "directory entries: their ~/ paths, a \$HOME one, their last component and a relative one"
assert "$(redacted_line 'failed (0')" "- Mail [email] about [url] and [url] failed (0 fixes)." "an email, a URL and an scp-style URL"
assert "$(redacted_line '4 words')" "- Hosts [host] and [customer] and [customer]-api and [customer]-tools leaked (4 words)." "a host, owners of the URL and scp entries, a label"
assert "$(redacted_line '7 tokens')" "- Token [token] and [token] and [token] and [token] and [token] and [token] and [token] leaked (7 tokens)." "ghp_, AKIA, github_pat_, glpat-, sk-, xox and a 40-character hex run"
assert "$(redacted_line '1 push')" "- [customer] pushed [repo] and [customer]/x to [host] from [path] and [path] and [path] (1 push)." "the origin owner and repo, another remote's host, owner and repo (a one-letter repo name stays), Windows and absolute paths"
assert "$(redacted_line 'unchanged')" "- Keep SKILL.md, README.md, bin/ai-log, /reviewing-in-rounds, 5.5.0, e.g. gitlab and www and x, marker and branch-marker-y unchanged (no evidence)." "file names, relative paths, a slash command, a version, generic labels and short names, and a personal repo's plan and branch words stay"
assert "$(printf '%s' "$redacted" | grep -ciE 'acme|zetaco|quoted|clienthost|example|dirclient|rel-dir|second|urlowner|scpowner|zzcorp|andrelin|redactrepo|mirror|ghp_|akia|glpat|bob|mailer|/var')" "0" "no listed name survives in any case"
assert "$(tail -c 1 "$LOG/entries/$ID5.md" | od -An -tx1 | tr -d ' \n')" "0a" "the file ends with a newline"
history="$(gitin "$BARE" log -p --all -- 'entries/*.md')"
assert "$(grep -ciE 'acme|zetaco|clienthost|example-owner|dirclient|urlowner|scpowner|zzcorp|redactrepo|mirrorowner|ghp_|AKIA|mailer' <<< "$history")" "0" "no listed name reached the origin's notes"

# Edge cases of what counts as a match.
edge_in=$'## Worked\n'$'- forged \001U\002 marks and a lone / and and/or and 1/2 and "/" stay or go as plain text (edge).\n'$'## Didn\'t\n- none (none)\n## Cut candidates\n- none (none)\n'
run_note_home2 "$W5" "$ID5" "$edge_in"
assert "$rc:$(sed -n 2p "$workdir/out")" "0:- forged U marks and a lone / and and/or and 1/2 and \"/\" stay or go as plain text (edge)." "control characters in the input cannot forge a placeholder; a lone slash and and/or stay"
run_note_home2 "$W5" "$ID5" $'## Worked\n- ## Worked in a bullet, ACME HOLDINGX and XACME HOLDING and Acme   Holding and Acme\nHolding (edge)\n## Didn\'t\n- none (none)\n## Cut candidates\n- none (none)\n'
assert "$(sed -n 2,3p "$workdir/out" | tr '\n' '|')" "- ## Worked in a bullet, ACME HOLDINGX and XACME HOLDING and [customer] and [customer] (edge)|## Didn't|" "a name matches whole words only, a space in it any run of blanks or a line break"
run_note_home2 "$W5" "$ID5" $'## Worked\n- ok acme-\nholding and ACME\n\n  holding (edge)\n## Didn\'t\n- none (none)\n## Cut candidates\n- none (none)\n'
assert "$(sed -n 2,3p "$workdir/out" | tr '\n' '|')" "- ok [customer] and [customer] (edge)|## Didn't|" "a name split across lines, with a hyphen or a blank line, is redacted"
run_note_home2 "$W5" "$ID5" $'## Worked\n- Plan  Marker\tstays (edge)\n## Didn\'t\n- none (none)\n## Cut candidates\n- none (none)\n'
assert "$rc:$(sed -n 2p "$workdir/out")" "0:- Plan  Marker"$'\t'"stays (edge)" "whitespace outside a match is kept as written"

# At company level the plan's and branch's words go too, and the heading lines are never touched.
gitin "$W2" switch -q -c feat/worked-cut
PROJ="$workdir/projects2"
new_log logred2
run_ai "$W2" record plan-example.md "$C1"
ID_C="$(out | head -1 | sed 's/^entry: //')"
run_note "$W2" "$ID_C" $'## Worked\n- The Example plan: worked, cut, and WORKED-OUT stay what they are (2 rounds), but uptimeconsulting/x is not (1 repo).\n## Didn\'t\n- The x and the plan stay, work2 does not (0 fixes).\n## Cut candidates\n- Cut the cut (no evidence).\n'
assert "$rc" "0" "note at company level exits 0"
assert "$(sed -n 1p "$workdir/out")" "## Worked" "a heading made of a branch word is kept"
assert "$(sed -n 2p "$workdir/out")" "- The [repo] plan: [repo], [repo], and [repo]-OUT stay what they are (2 rounds), but [customer]/x is not (1 repo)." "the plan's basename and heading words, the branch's words and the owner"
assert "$(sed -n 3,6p "$workdir/out" | tr '\n' '|')" "## Didn't|- The x and the plan stay, [repo] does not (0 fixes).|## Cut candidates|- [repo] the [repo] (no evidence).|" "the folder's name, generic words kept, the other heading kept"
assert "$(cat "$LOG/entries/$ID_C.md")" "$(cat "$workdir/out")" "the company note is stored as printed"
gitin "$W2" switch -q -

# --- Redaction leaks found in review: subdomains, addresses, short labels, plurals, more path forms, plans in subfolders ----

home3="$workdir/home3"
mkdir -p "$home3"
printf '%s\n' 'bigco.example' 'gc.example' 'Acme' 'Foo Bar AS' 'A/S Zedco' 'kunde.test' 'kunde.zip' > "$home3/.claude-customers"
PROJ="$workdir/projectsred"
new_log logred3
run_ai "$W5" record plan-example.md "$C1"
ID6="$(out | head -1 | sed 's/^entry: //')"
assert "$rc" "0" "the leak-test repo records"
leak_in=$'## Worked\n'
leak_in+=$'- secretproj.bigco.example and x.y.bigco.example and BIGCO.example and bigco.example/x (subdomains).\n'
leak_in+=$'- 10.1.2.3 and 192.168.0.1:22 and fe80::1 and ::1 and 2001:db8::ff and 2001:0db8:0000:0000:0000:ff00:0042:8329 (addresses).\n'
leak_in+=$'- Versions 2.1.309 and 5.5 and 1.2.3 and times 10:30:45 and 10:30 stay (versions).\n'
leak_in+=$'- gc and GC-portal and gcs, acmes and ACMES and acme\'s and acmees and acme (short labels, plurals).\n'
leak_in+=$'- c:/Users/bob and C:\\Users\\bob and ~bob/projects and \\\\fileserver\\share\\x and /secretclient (paths).\n'
leak_in+=$'## Didn\'t\n'
leak_in+=$'- deploy@prodbox and a@b.c and kunde.test and Kunde.ZIP and Foo Bar and foo bar as and A/S Zedco and Zedco (forms).\n'
leak_in+=$'## Cut candidates\n- acmecorp stays, a known gap (gap).\n'
HOME="$home3" run_note "$W5" "$ID6" "$leak_in"
assert "$rc" "0" "the leak input is accepted"
leaked="$(cat "$workdir/out")"
function leaked_line() { grep -F -- "$1" <<< "$leaked"; }
assert "$(leaked_line '(subdomains)')" "- [host] and [host] and [host] and [host]/x (subdomains)." "an unlisted subdomain of a listed host is redacted whole"
assert "$(leaked_line '(addresses)')" "- [host] and [host] and [host] and [host] and [host] and [host] (addresses)." "IPv4 with a port, IPv6 short and long forms"
assert "$(leaked_line '(versions)')" "- Versions 2.1.309 and 5.5 and 1.2.3 and times 10:30:45 and 10:30 stay (versions)." "versions and times are not addresses"
assert "$(leaked_line '(short labels, plurals)')" "- [customer] and [customer]-portal and [customer], [customer] and [customer] and [customer]'s and [customer] and [customer] (short labels, plurals)." "a two-letter label, plurals and a possessive"
assert "$(leaked_line '(paths)')" "- [path] and [path] and [path] and [path] and /secretclient (paths)." "a drive path with a forward slash, ~user paths and a UNC path"
assert "$(leaked_line '(forms)')" "- [email] and [email] and [host] and [host] and [customer] and [customer] and [customer] and [customer] (forms)." "a dotless host, a country TLD, a legal form before or after a name"
assert "$(leaked_line '(gap)')" "- acmecorp stays, a known gap (gap)." "a name run into another word is a known gap"

# A plan in a subfolder is found by its hash, at company level.
new_work workdeep git@github.com:uptimeconsulting/deep.git
WD="$W"
mkdir -p "$WD/docs/plans"
for f in "$WD"/plan-example*; do mv "$f" "$WD/docs/plans/"; done
commit_at "$WD" 2026-01-11T12:00:00Z "move the plan"
new_projects projectsdeep "$WD"
PROJ="$workdir/projectsdeep"
new_log logdeep
run_ai "$WD" record docs/plans/plan-example.md "$C1"
IDD="$(out | head -1 | sed 's/^entry: //')"
assert "$rc" "0" "a plan in a subfolder records"
run_note "$WD" "$IDD" $'## Worked\n- The Example plan held (1 round).\n## Didn\'t\n- Nothing (none).\n## Cut candidates\n- Nothing (none).\n'
assert "$(sed -n 2p "$workdir/out")" "- The [repo] plan held (1 round)." "company: the plan's words are found wherever the plan sits in the repo"

# A plan beside the repo, in the folder of a tree of repos: record takes its path relative to where it runs, and note
# finds it in a folder above the repo, short of $HOME.
new_work beside/repo git@github.com:uptimeconsulting/beside.git
WB="$W"
for f in "$WB"/plan-example*; do mv "$f" "$workdir/beside/"; done
commit_at "$WB" 2026-01-11T12:00:00Z "the plan lives beside the repo"
new_projects projectsbeside "$WB"
PROJ="$workdir/projectsbeside"
new_log logbeside
run_ai "$WB/sub" record ../../plan-example.md "$C1"
IDB="$(out | head -1 | sed 's/^entry: //')"
assert "$rc" "0" "a plan beside the repo records, its path relative to the subfolder it runs in"
HOME="$workdir" run_note "$WB" "$IDB" $'## Worked\n- The Example plan held (1 round).\n## Didn\'t\n- Nothing (none).\n## Cut candidates\n- Nothing (none).\n'
assert "$rc:$(sed -n 2p "$workdir/out")" "0:- The [repo] plan held (1 round)." "company: the plan's words are found in a folder above the repo"
HOME="$workdir/beside/repo" run_note "$WB" "$IDB" $'## Worked\n- The Example plan held (1 round).\n## Didn\'t\n- Nothing (none).\n## Cut candidates\n- Nothing (none).\n'
assert "$rc:$(err | grep -c 'or a folder above it is the plan')" "1:1" "but not past \$HOME: a plan there is not looked for, and note refuses"

# --- Redaction leaks, third review: line breaks, address shapes, service labels, token shapes, %40, short folders ---------

# shellcheck disable=SC2088
printf '%s\n' 'bigco.example' 'gc.example' 'Acme' 'Foo Bar AS' 'A/S Zedco' 'kunde.test' 'kunde.zip' 'api.kunde.example' 'kunde2.co.example' 'portal.klient.invalid' > "$home3/.claude-customers"
PROJ="$workdir/projectsred"
new_log logred4
run_ai "$W5" record plan-example.md "$C1"
ID7="$(out | head -1 | sed 's/^entry: //')"
l3=$'## Worked\n'
l3+=$'- worked with Foo\nBar AS fine and foo\n  bar as again (1 round).\n'
l3+=$'- port :8080 and (:30) and ratio 3 :1 and a::b and ab:cd:ef:12:34:56:78:90 stay; [fe80::1]:22 and [::1] and 8.8.8.8 go (v6).\n'
l3+=$'- 1.2.3.4-rc and v1.2.3.4 and node 20.11.1.0 and 256.1.1.1 stay (v4).\n'
l3+=$'- api and API and portal and co and kunde and kunde2 and klient (labels).\n'
l3+=$'- src/main/kotlin/com/example/app/x and xoxo-hugs-and-kisses and sk-something-longer and akiaabcdefghijklmnop and AKIAABCDEFGHIJKLMNOP (tokens).\n'
l3+=$'## Didn\'t\n- bob%40unlisted.no and bob@unlisted.example (mail).\n## Cut candidates\n- none (none)\n'
HOME="$home3" run_note "$W5" "$ID7" "$l3"
assert "$rc" "0" "the third-review input is accepted"
leaked="$(cat "$workdir/out")"
assert "$(sed -n 2,3p <<< "$leaked" | tr '\n' '|')" "- worked with [customer] fine and [customer] again (1 round).|- port :8080 and (:30) and ratio 3 :1 and a::b and ab:cd:ef:12:34:56:78:90 stay; [host] and [host] and [host] go (v6).|" "a name split by a line break; real IPv6 shapes only, bracketed forms whole"
assert "$(leaked_line '(v4)')" "- 1.2.3.4-rc and v1.2.3.4 and node 20.11.1.0 and 256.1.1.1 stay (v4)." "four-part versions and out-of-range octets are not addresses"
assert "$(leaked_line '(labels)')" "- api and API and portal and co and [customer] and [customer] and [customer] (labels)." "service labels and second-level suffixes of a listed host are not customer words"
assert "$(leaked_line '(tokens)')" "- src/main/kotlin/com/example/app/x and xoxo-hugs-and-kisses and sk-something-longer and akiaabcdefghijklmnop and [token] (tokens)." "token shapes are case-sensitive and need their real form; a long relative path is not one"
assert "$(leaked_line '(mail)')" "- [email] and [email] (mail)." "%40 is an @"

# A two-letter folder under $HOME is a repo word.
new_work home3/kd/repo git@github.com:andrelin/kdrepo.git
WK="$W"
new_projects projectskd "$WK"
PROJ="$workdir/projectskd"
new_log logkd
run_ai "$WK" record plan-example.md "$C1"
IDK="$(out | head -1 | sed 's/^entry: //')"
assert "$rc" "0" "a repo under HOME records"
HOME="$home3" run_note "$WK" "$IDK" $'## Worked\n- kd and repo and ~/kd/repo (a).\n## Didn\'t\n- none (none)\n## Cut candidates\n- none (none)\n'
assert "$(sed -n 2p "$workdir/out")" "- [repo] and repo and [path] (a)." "a two-letter folder name is redacted, a generic one is not"

# --- Redaction leaks, fourth review: secret keys with slashes, JWTs, hosts of generic labels ------------------------------

printf '%s\n' 'portal.example' 'mail.docs.test' > "$home3/.claude-customers"
PROJ="$workdir/projectsred"
new_log logred5
run_ai "$W5" record plan-example.md "$C1"
ID8="$(out | head -1 | sed 's/^entry: //')"
l4=$'## Worked\n'
l4+=$'- wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY and src/main/kotlin/com/example/app/x and Zm9vYmFyYmF6cXV4Zm9vYmFyYmF6cXV4Zm9vYmFyYmE= (keys).\n'
l4+=$'- eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dBjftJeZ4CVPmB92K27uhbUJU1p1r_wW1gFWFOEjXk (jwt).\n'
l4+=$'- portal and mail and docs and api and no (generic).\n'
l4+=$'## Didn\'t\n- none (none)\n## Cut candidates\n- none (none)\n'
HOME="$home3" run_note "$W5" "$ID8" "$l4"
assert "$rc" "0" "the fourth-review input is accepted"
leaked="$(cat "$workdir/out")"
assert "$(leaked_line '(keys)')" "- [token] and src/main/kotlin/com/example/app/x and [token] (keys)." "a slashed secret key and a padded base64 run are tokens, a relative path is not"
assert "$(leaked_line '(jwt)')" "- [token] (jwt)." "a JWT is one token"
assert "$(leaked_line '(generic)')" "- [customer] and mail and [customer] and api and no (generic)." "a host of generic labels still has its last word redacted"

# --- Customer level: deferred --------------------------------------------------------------------------------------------

home="$workdir/home"
mkdir -p "$home"
printf 'example--client\n' > "$home/.claude-customers"
new_work work3 git@github.com:example--client/app.git
W3="$W"
new_projects projects3 "$W3"
PROJ="$workdir/projects3"
new_log log11
log_head="$(gitin "$LOG" rev-parse HEAD)"
deferred='ai-log: customer level is deferred, nothing recorded'
function run_home() { HOME="$home" run_ai "$@"; }
for flags in "" "--dry-run"; do
  # shellcheck disable=SC2086
  run_home "$W3" record $flags plan-example.md "$C1"
  assert "$(out)" "$deferred" "customer (a listed owner) $flags: the one line"
  assert "$rc" "0" "customer $flags: exit 0"
  assert "$(gitin "$LOG" rev-parse HEAD):$(gitin "$LOG" status --porcelain):$(ls "$LOG")" "$log_head::README.md" "customer $flags: nothing in the log clone changed"
done
run_home "$W3" level
assert "$(out)" "customer" "level: a listed customer"

HOME="$home" run_note "$W3" "2026-01-10-000000000000" "$note_text"
assert "$(out):$rc" "$deferred:0" "note: a listed customer is deferred, whatever the id"
assert "$(gitin "$LOG" rev-parse HEAD):$(gitin "$LOG" status --porcelain):$(ls "$LOG")" "$log_head::README.md" "note at customer level: nothing in the log clone changed"

# A level the guard can't settle while the file lists anything: a resolver that fails.
TREE2="$workdir/tree2"
make_tree "$TREE2"
printf '#!/bin/bash\nexit 1\n' > "$TREE2/claude/hooks/work-context.sh"
AI_BIN="$TREE2/bin/ai-log" run_home "$W1" level
assert "$(out)" "customer" "level: a resolver that fails counts as customer"
AI_BIN="$TREE2/bin/ai-log" run_home "$W1" record plan-example.md "$C1"
assert "$(out):$rc" "$deferred:0" "record: a resolver that fails defers like a customer"
assert "$(err | grep -c 'customer because the work-context guard failed')" "1" "record: and stderr says the guard failed"
AI_BIN="$TREE2/bin/ai-log" run_home "$W1" level
assert "$(err | grep -c 'customer because the work-context guard failed')" "1" "level: stderr says the guard failed"

# There is no list of owners in ai-log: an origin the guard resolves as company is company and recorded, whoever owns it.
new_work work4 git@github.com:example-org/app.git
W4="$W"
new_projects projects4 "$W4"
PROJ="$workdir/projects4"
new_log log11b
run_ai "$W4" level
assert "$(out):$(err)" "company:" "level: an unlisted github owner, with no customers file, is company by the guard's rule"
run_ai "$W4" record plan-example.md "$C1"
assert "$rc:$(out | head -1 | cut -c1-7)" "0:entry: " "record: an unlisted owner the guard calls company is recorded"
gitin "$W4" remote set-url origin git@git.example.com:uptimeconsulting/app.git
run_ai "$W4" level
assert "$(out):$(err)" "company:" "level: another host's uptimeconsulting is company too"
run_ai "$W4" record --dry-run plan-example.md "$C1"
assert "$rc:$(out | jq -r .level)" "0:company" "record: another host's uptimeconsulting is recorded"
# A listed owner stays customer: the guard's own file decides.
printf 'example-org\n' > "$home/.claude-customers"
gitin "$W4" remote set-url origin git@github.com:example-org/app.git
run_home "$W4" level
assert "$(out)" "customer" "level: an owner the customers file lists is customer"
run_home "$W4" record plan-example.md "$C1"
assert "$(out):$rc" "$deferred:0" "record: a listed owner is deferred"
printf 'example--client\n' > "$home/.claude-customers"
# An allow file in the log clone no longer counts for anything.
printf 'git.example.com/uptimeconsulting\ngithub.com/example-org\n' > "$LOG/allow"
run_home "$W4" level
assert "$(out)" "company" "level: an allow file in the log clone is not read"
rm "$LOG/allow"
gitin "$W4" remote remove origin
run_ai "$W4" level
assert "$(out):$(err | grep -c 'customer because')" "customer:1" "level: no origin is deferred whatever the guard says, and stderr says why"

# --- Plugin MCP tools, customer names in the entry, model ids -------------------------------------------------------------

new_work work7 git@github.com:andrelin/x.git
W7="$W"
new_projects projects8 "$W7"
PROJ="$workdir/projects8"
p8="$PROJ/-example-work"
jq -c -n --arg cwd "$W7" '{type: "assistant", uuid: "p-mcp", timestamp: "2026-01-09T10:05:42.000Z", cwd: $cwd, version: "2.1.309",
  message: {id: "m-mcp", model: "claude-opus-5-5", content: [
    {type: "tool_use", id: "tm1", name: "mcp__plugin_acme-internal_jira__search", input: {}},
    {type: "tool_use", id: "tm2", name: "mcp__plugin_superpowers_srv__go", input: {}},
    {type: "tool_use", id: "tm3", name: "mcp__plugin_superpowers-extras_srv__go", input: {}}], usage: {input_tokens: 1, output_tokens: 1}}}' >> "$p8/s1.jsonl"
new_log log20
run_ai "$W7" record --dry-run plan-example.md "$C1"
assert "$rc" "0" "personal, plugin MCP tools: exit 0"
assert "$(out | jq -c '.totals.tools | [has("mcp__plugin_acme-internal_jira__search"), has("mcp__plugin_superpowers_srv__go"), has("mcp__example_server__do_thing"), ._other_plugin]')" \
  '[false,true,true,2]' "personal: a plugin off the allowlist's MCP tools fold like its skills (also one whose name only starts like an allowed plugin), an allowed plugin's and a plain server's stay"
assert "$(out | jq -r '[.sessions[].tools | keys[]] | map(select(test("acme"))) | length')" "0" "and no per-session tool name carries the plugin"
assert "$(out | grep -c 'acme-internal')" "0" "nor does the rest of the entry"

# A name in the entry that holds a term of ~/.claude-customers refuses the record.
homeL="$workdir/homeL"
mkdir -p "$homeL"
printf '%s\n' 'Acme' > "$homeL/.claude-customers"
jq -c -n --arg cwd "$W7" '{type: "assistant", uuid: "p-acme", timestamp: "2026-01-09T10:05:43.000Z", cwd: $cwd, version: "2.1.309",
  message: {id: "m-acme", model: "claude-opus-5-5", content: [
    {type: "tool_use", id: "ta1", name: "Agent", input: {subagent_type: "acme-reviewer", description: "d", prompt: "p"}}], usage: {input_tokens: 1, output_tokens: 1}}}' >> "$p8/s1.jsonl"
log_head="$(gitin "$LOG" rev-parse HEAD)"
for flags in "" "--dry-run"; do
  # shellcheck disable=SC2086
  HOME="$homeL" run_ai "$W7" record $flags plan-example.md "$C1"
  assert "$rc" "1" "a custom agent named for a listed customer refuses the record $flags"
  assert "$(err | grep -c 'holds a name from ~/.claude-customers')" "1" "$flags: and says why"
  assert "$(out | grep -c acme)" "0" "$flags: nothing printed carries the name"
  assert "$(gitin "$LOG" rev-parse HEAD):$(gitin "$LOG" status --porcelain):$(entry_count)" "$log_head::0" "$flags: nothing written to the log clone"
done
printf '%s\n' 'Zzunrelated' > "$homeL/.claude-customers"
HOME="$homeL" run_ai "$W7" record --dry-run plan-example.md "$C1"
assert "$rc" "0" "a customers file that names nothing in the entry refuses nothing"
printf '# only a comment\n' > "$homeL/.claude-customers"
HOME="$homeL" run_ai "$W7" record --dry-run plan-example.md "$C1"
assert "$rc" "0" "a customers file with no terms refuses nothing"

# Only the names the machine supplies are checked: a listed word that is also a word in a warning, a lens heading or a
# review kind (text the script writes) blocks nothing.
HOME="$homeL" run_ai "$W7" record --dry-run plan-example.md "$C1"
entry_json="$(out)"
lens_words="$(jq -r '[.findings[] | keys[]] | unique[]' <<< "$entry_json" | tr -c 'A-Za-z\n' ' ' | tr ' ' '\n' | awk 'length > 3' | sort -u | head -3)"
kinds="$(jq -r '.reviews[].kind' <<< "$entry_json" | sort -u)"
assert "$([[ -n "$lens_words" && -n "$kinds" ]] && echo ok)" "ok" "(setup) the fixture entry has lens headings and review kinds"
cp "$p8/s1.jsonl" "$workdir/s1.jsonl.keep"
printf 'not json at all\n' >> "$p8/s1.jsonl"
HOME="$homeL" run_ai "$W7" record --dry-run plan-example.md "$C1"
assert "$(out | jq -r '.warnings | map(select(test("not JSON"))) | length')" "1" "(setup) a transcript line that is not JSON puts 'transcript line(s) were not JSON' in the entry"
for word in transcript JSON $lens_words $kinds; do
  # The entry's own repo and plan names are checked too, so a word that is part of them (the kind "plan" is) does block.
  [[ "$(jq -r '"\(.repo) \(.plan)"' <<< "$entry_json")" != *"$word"* ]] || continue
  printf '%s\n' "$word" > "$homeL/.claude-customers"
  HOME="$homeL" run_ai "$W7" record --dry-run plan-example.md "$C1"
  assert "$rc" "0" "a customers line '$word', a word of a warning, lens heading or review kind, refuses nothing"
done
cp "$workdir/s1.jsonl.keep" "$p8/s1.jsonl"
# The name-carrying fields still count: a tool, a skill, a model and a plugin.
for field in '.totals.tools | keys[]' '.totals.skills | keys[]' '.totals.tokens | keys[]' '.framework.plugins // {} | keys[]'; do
  name="$(jq -r "[$field] | map(select(test(\"^[A-Za-z]{4,}\$\"))) | first // empty" <<< "$entry_json")"
  [[ -n "$name" ]] || continue
  printf '%s\n' "$name" > "$homeL/.claude-customers"
  HOME="$homeL" run_ai "$W7" record --dry-run plan-example.md "$C1"
  assert "$rc" "1" "a customers line equal to a name in '$field' ($name) refuses the record"
done

# Company level: a cloud model id with an account number is not stored.
new_work work8 git@github.com:uptimeconsulting/x.git
W8="$W"
new_projects projects9 "$W8"
PROJ="$workdir/projects9"
arn='arn:aws:bedrock:eu-north-1:123456789012:inference-profile/eu.anthropic.claude-opus'
jq -c -n --arg cwd "$W8" --arg arn "$arn" '{type: "assistant", uuid: "p-arn", timestamp: "2026-01-09T10:05:44.000Z", cwd: $cwd, version: "2.1.309",
  message: {id: "m-arn", model: $arn, content: [
    {type: "tool_use", id: "tr1", name: "Agent", input: {subagent_type: "general-purpose", model: $arn, description: "d", prompt: "p"}},
    {type: "tool_use", id: "tr2", name: "Agent", input: {subagent_type: "general-purpose", model: "eu.anthropic.claude-opus-4-5-v1:0", description: "d", prompt: "p"}}],
    usage: {input_tokens: 1, output_tokens: 1}}}' >> "$PROJ/-example-work/s1.jsonl"
new_log log21
run_ai "$W8" record --dry-run plan-example.md "$C1"
assert "$rc" "0" "company, ARN model: exit 0"
assert "$(out | grep -c '123456789012')" "0" "company: an ARN's account number is not in the entry"
assert "$(out | jq -c '[.totals.tokens | has("unknown")] + [.totals.agents | has("general-purpose/default"), has("general-purpose/eu.anthropic.claude-opus-4-5-v1:0")]')" \
  '[true,true,true]' "company: an ARN is unknown, a plain provider id with a :version suffix is kept"

# --- Azure DevOps remotes: every form of one repo gives one id -----------------------------------------------------------

new_work workaz git@ssh.dev.azure.com:v3/Org/Proj/Repo
WAZ="$W"
new_projects projectsaz "$WAZ"
PROJ="$workdir/projectsaz"
new_log logaz
ids=""
for url in git@ssh.dev.azure.com:v3/Org/Proj/Repo https://dev.azure.com/Org/Proj/_git/Repo https://Org@dev.azure.com/Org/Proj/_git/Repo \
  git@vs-ssh.visualstudio.com:v3/Org/Proj/Repo https://Org.visualstudio.com/Proj/_git/Repo; do
  gitin "$WAZ" remote set-url origin "$url"
  run_ai "$WAZ" record --dry-run plan-example.md "$C1"
  ids+="$(out | jq -r .id) "
done
assert "$(printf '%s\n' $ids | sort -u | wc -l | tr -d ' '):$(printf '%s' "$ids" | wc -w | tr -d ' ')" "1:5" "ssh, https, user-qualified, legacy ssh and legacy host Azure origins give the same id"

# --- A later plan reusing a plan's name starts its own chain; a commit equal to an entry's end is no newer ------------------

new_work workre git@github.com:andrelin/y.git
WRE="$W"
new_projects projectsre "$WRE"
PROJ="$workdir/projectsre"
new_log logre
run_ai "$WRE" record plan-example.md "$C1"
IDRE1="$(out | head -1 | sed 's/^entry: //')"
assert "$rc" "0" "the first plan of the name records"
# A second commit at the entry's own end time: no newer than the window's start.
echo same > "$WRE/same.txt"
commit_at "$WRE" 2026-01-10T12:00:00Z "same time"
CSAME="$(gitin "$WRE" rev-parse HEAD)"
head_re="$(gitin "$LOG" rev-parse HEAD)"
for flags in "" "--dry-run"; do
  # shellcheck disable=SC2086
  run_ai "$WRE" record $flags plan-example.md "$CSAME"
  assert "$rc" "1" "a commit at an earlier entry's end time exits 1 $flags"
done
assert "$(gitin "$LOG" rev-parse HEAD):$(entry_count)" "$head_re:1" "and writes nothing"
run_ai "$WRE" record plan-example.md "$CSAME"
assert "$(err | grep -c 'no newer than the window')" "1" "the message says the commit is no newer"
# A commit before the plan's first appearance, no earlier entry: the same message.
LOG0="$LOG"
new_log logre0
run_ai "$WRE" record plan-example.md "$C0"
assert "$rc:$(err | grep -c 'no newer than the window')" "1:1" "a commit before the first appearance names the same reason"
LOG="$LOG0"

# The plan is deleted, then a new plan takes the name; a session names it after the deletion.
gitin "$WRE" rm -q plan-example.md plan-example-review-findings-plan.md plan-example-review-findings-code-closed-2026-01-09.md \
  plan-example-review-findings-plan-closed-2026-01-05.md
commit_at "$WRE" 2026-02-01T12:00:00Z "plan done"
cp "$FIX"/plan-example* "$WRE/"
commit_at "$WRE" 2026-02-05T12:00:00Z "a new plan with the old name"
CRE2="$(gitin "$WRE" rev-parse HEAD)"
jq -c -n --arg cwd "$WRE" '{type: "assistant", uuid: "re-new", timestamp: "2026-02-03T10:00:00.000Z", cwd: $cwd, version: "2.1.309",
  message: {id: "m-re", model: "claude-opus-5-5", content: [{type: "tool_use", id: "tre", name: "Read", input: {file_path: "plan-example.md"}}],
  usage: {input_tokens: 11, output_tokens: 2}}}' > "$PROJ/-example-work/s6.jsonl"
run_ai "$WRE" record plan-example.md "$CRE2"
IDRE2="$(out | head -1 | sed 's/^entry: //')"
assert "$rc" "0" "the reused name records"
assert "$(jq -c '.window' "$LOG/entries/$IDRE2.json")" '{"start":"2026-02-03T10:00:00.000Z","end":"2026-02-05T12:00:00.000Z","after":null}' "its window starts at its own first appearance, with no after"
assert "$(jq -c '[(.sessions | length), .totals.tokens["claude-opus-5-5"].input]' "$LOG/entries/$IDRE2.json")" "[1,11]" "and counts none of the old plan's tokens"
assert "$(out | grep -c '^  windows: 1$')" "1" "the summary covers the new chain only"
assert "$(jq -r .plan_key "$LOG/entries/$IDRE1.json")" "$(jq -r .plan_key "$LOG/entries/$IDRE2.json")" "(the key is the same name's)"
# Re-recording the old plan's commit still sees only its own chain.
run_ai "$WRE" record plan-example.md "$C1"
assert "$(out | grep -c '^  windows: 1$')" "1" "re-recording the old chain's entry summarises the old chain only"
# A plan that was never deleted keeps chaining: a continuation commit on a branch from the first commit.
new_log logre2
run_ai "$WRE" record plan-example.md "$C1"
IDX="$(out | head -1 | sed 's/^entry: //')"
assert "$rc" "0" "(setup) a first entry in a second log"
CCON="$(cd "$WRE" && GIT_COMMITTER_DATE=2026-02-10T12:00:00Z GIT_AUTHOR_DATE=2026-02-10T12:00:00Z git commit-tree -p "$C1" -m continues "$C1^{tree}")"
jq -c -n --arg cwd "$WRE" '{type: "assistant", uuid: "re-cont", timestamp: "2026-02-09T10:00:00.000Z", cwd: $cwd, version: "2.1.309",
  message: {id: "m-cont", model: "claude-opus-5-5", content: [{type: "tool_use", id: "trc", name: "Read", input: {file_path: "plan-example.md"}}],
  usage: {input_tokens: 5, output_tokens: 1}}}' > "$PROJ/-example-work/s7.jsonl"
run_ai "$WRE" record plan-example.md "$CCON"
assert "$rc:$(jq -r '.window.after' "$LOG/entries/$(out | head -1 | sed 's/^entry: //').json")" "0:$IDX" "a plan not deleted since the last entry continues its chain"

# --- Company level: a plan note cannot find ----------------------------------------------------------------------------

new_work workplan git@github.com:uptimeconsulting/planrepo.git
WS="$W"
new_projects projectsplan "$WS"
PROJ="$workdir/projectsplan"
new_log logplan
run_ai "$WS" record plan-example.md "$C1"
IDS1="$(out | head -1 | sed 's/^entry: //')"
nt=$'## Worked\n- the plan held (1).\n## Didn\'t\n- none (none)\n## Cut candidates\n- none (none)\n'
run_note "$WS" "$IDS1" "$nt"
assert "$rc" "0" "note at company level finds the plan that recorded"
head_s="$(gitin "$LOG" rev-parse HEAD)"
rm "$LOG/entries/$IDS1.md"
gitin "$LOG" reset -q --hard "$head_s~1"
head_s="$(gitin "$LOG" rev-parse HEAD)"
mv "$WS/plan-example.md" "$workdir/plan-example.away"
run_note "$WS" "$IDS1" "$nt"
mv "$workdir/plan-example.away" "$WS/plan-example.md"
assert "$rc:$(err | grep -c 'cannot be redacted')" "1:1" "note at company level without the plan in the repository refuses"
assert "$(gitin "$LOG" rev-parse HEAD):$(gitin "$LOG" status --porcelain)" "$head_s:" "and writes nothing"
# A plan outside the repository root.
mkdir -p "$workdir/outside"
cp "$WS/plan-example.md" "$workdir/outside/plan-example.md"
new_log logplan2
run_ai "$WS" record "$workdir/outside/plan-example.md" "$C1"
IDOUT="$(out | head -1 | sed 's/^entry: //')"
assert "$rc" "0" "a plan outside the repository records"
head_o="$(gitin "$LOG" rev-parse HEAD)"
rm "$WS/plan-example.md"
run_note "$WS" "$IDOUT" "$nt"
assert "$rc:$(gitin "$LOG" rev-parse HEAD)" "1:$head_o" "note at company level cannot redact a plan outside the repository and writes nothing"

# --- Words, platform-independent; a repo named for a workflow word -------------------------------------------------------

new_work workoe git@github.com:uptimeconsulting/x.git
WOE="$W"
new_projects projectsoe "$WOE"
PROJ="$workdir/projectsoe"
find "$PROJ" -name '*.jsonl' -exec sed -i.bak 's#plan-example\.md#plan-ørsta-kommune.md#g' {} +
find "$PROJ" -name '*.bak' -delete
cp "$WOE/plan-example.md" "$WOE/plan-ørsta-kommune.md"
commit_at "$WOE" 2026-01-10T13:00:00Z "norwegian plan"
new_log logoe
run_ai "$WOE" record plan-ørsta-kommune.md "$(gitin "$WOE" rev-parse HEAD)"
IDOE="$(out | head -1 | sed 's/^entry: //')"
assert "$rc" "0" "(setup) a company plan with a non-ASCII name records"
oe_text=$'## Worked\n- Ørsta and kommune and ørsta (a).\n## Didn\'t\n- none (none)\n## Cut candidates\n- none (none)\n'
LC_ALL=C run_note "$WOE" "$IDOE" "$oe_text"
assert "$(sed -n 2p "$workdir/out")" "- [repo] and [repo] and [repo] (a)." "a non-ASCII plan word is redacted whole under the C locale (GNU tr's behaviour)"
LC_ALL=en_US.UTF-8 run_note "$WOE" "$IDOE" "$oe_text"
assert "$(sed -n 2p "$workdir/out")" "- [repo] and [repo] and [repo] (a)." "and the same under a UTF-8 locale (BSD tr's behaviour)"

new_work workrev git@github.com:andrelin/review.git
WRV="$W"
new_projects projectsrv "$WRV"
PROJ="$workdir/projectsrv"
new_log logrv
run_ai "$WRV" record plan-example.md "$C1"
IDRV="$(out | head -1 | sed 's/^entry: //')"
assert "$rc" "0" "(setup) a repo named for a workflow word records"
run_note "$WRV" "$IDRV" $'## Worked\n- review rounds ran 3 times (review 3 rounds) and ai-log ran (ai).\n## Didn\'t\n- none (none)\n## Cut candidates\n- none (none)\n'
assert "$(sed -n 2p "$workdir/out")" "- review rounds ran 3 times (review 3 rounds) and ai-log ran (ai)." "a repo named review or ai does not turn those words into placeholders"

# --- Review fixes: by_agent_type, repo and plan names, jq 1.6 paths, dropped findings, models, boundaries ----------------------

new_work workfx git@github.com:andrelin/fx.git
WFX="$W"
new_projects projectsfx "$WFX"
PROJ="$workdir/projectsfx"
pfx="$PROJ/-example-work"
new_log logfx
run_ai "$WFX" record --dry-run plan-example.md "$C1"
base_warn="$(out | jq -c .warnings)"
base_find="$(out | jq -c .findings)"
assert "$base_warn" "[]" "(setup) the fixture entry has no warnings"

# A dropped finding's old heading form, with a status in place of the severity, is known: no warning, no count.
printf '\n### R1-18 · note\n\nBody.\n\n### R1-19 · refuted\n\nBody.\n\n### R2-9 · out of scope, by the bar\n\nBody.\n' >> "$WFX/plan-example-review-findings-plan.md"
run_ai "$WFX" record --dry-run plan-example.md "$C1"
assert "$(out | jq -c '[.warnings, .findings]')" "[$base_warn,$base_find]" "a '· refuted', '· note' or '· out of scope' heading adds no warning and no finding"
printf '\n### R1-20 · bogus\n\nBody.\n' >> "$WFX/plan-example-review-findings-plan.md"
run_ai "$WFX" record --dry-run plan-example.md "$C1"
assert "$(out | jq -c '.warnings | length')" "1" "a heading of any other malformed form still warns"
git -C "$WFX" checkout -q -- plan-example-review-findings-plan.md

# A present subagent_type that fails the name check is unknown; only a missing one is general-purpose.
jq -c -n --arg cwd "$WFX" '{type: "assistant", uuid: "p-st", timestamp: "2026-01-09T10:05:45.000Z", cwd: $cwd, version: "2.1.309",
  message: {id: "m-st", model: "claude-opus-5-5", content: [
    {type: "tool_use", id: "ts1", name: "Agent", input: {subagent_type: "bad name with spaces", description: "d", prompt: "p"}},
    {type: "tool_use", id: "ts2", name: "Agent", input: {description: "d", prompt: "p"}},
    {type: "tool_use", id: "ts3", name: "Agent", input: {subagent_type: 5, description: "d", prompt: "p"}}],
    usage: {input_tokens: 1, output_tokens: 1}}}' >> "$pfx/s1.jsonl"
run_ai "$WFX" record --dry-run plan-example.md "$C1"
assert "$(out | jq -c '.totals.agents | [.["unknown/default"], .["general-purpose/default"]]')" "[2,1]" "a rejected or non-string subagent_type is unknown, a missing one general-purpose"
assert "$(out | grep -c 'bad name')" "0" "and the rejected name is not stored"

# A Bedrock ARN is unknown at every level, not only at company level.
arn='arn:aws:bedrock:eu-north-1:123456789012:inference-profile/eu.anthropic.claude-opus'
jq -c -n --arg cwd "$WFX" --arg arn "$arn" '{type: "assistant", uuid: "p-arn2", timestamp: "2026-01-09T10:05:46.000Z", cwd: $cwd, version: "2.1.309",
  message: {id: "m-arn2", model: $arn, content: [
    {type: "tool_use", id: "tq1", name: "Agent", input: {subagent_type: "general-purpose", model: $arn, description: "d", prompt: "p"}},
    {type: "tool_use", id: "tq2", name: "Agent", input: {subagent_type: "general-purpose", model: "eu.anthropic.claude-opus-4-5-v1:0", description: "d", prompt: "p"}}],
    usage: {input_tokens: 1, output_tokens: 1}}}' >> "$pfx/s1.jsonl"
run_ai "$WFX" record --dry-run plan-example.md "$C1"
assert "$(out | jq -r .level)" "personal" "(setup) the ARN run is at personal level"
assert "$(out | grep -c '123456789012')" "0" "personal: an ARN's account number is not in the entry"
assert "$(out | jq -c '[.totals.tokens | has("unknown")] + [.totals.agents | has("general-purpose/default"), has("general-purpose/eu.anthropic.claude-opus-4-5-v1:0")]')" \
  '[true,true,true]' "personal: an ARN is unknown, a plain provider id with a :version suffix is kept"

# A given commit no newer than the window's start with --dry-run reports the window, not a missing session.
new_log logbw
run_ai "$WFX" record --dry-run plan-example.md "$C0"
assert "$rc:$(err | grep -c 'window is empty or inverted')" "1:1" "--dry-run on a commit before the window start says the window is empty or inverted"
assert "$(err | grep -c 'inside the window')" "0" "and does not claim a missing session"
assert "$(out | wc -c | tr -d ' ')" "0" "and prints no entry"

# A failing git pull (record) or git fetch (dry run) in the log clone warns and carries on.
new_log logpf
gitin "$LOG" remote set-url origin "$workdir/no-such-origin.git"
run_ai "$WFX" record --dry-run plan-example.md "$C1"
assert "$rc:$(out | jq -c '.warnings | map(select(test("git fetch in the log clone failed"))) | length')" "0:1" "dry run: a failing git fetch warns in the entry and exits 0"
run_ai "$WFX" record plan-example.md "$C1"
IDPF="$(out | head -1 | sed 's/^entry: //')"
assert "$rc:$(jq -c '.warnings | map(select(test("git pull in the log clone failed"))) | length' "$LOG/entries/$IDPF.json")" "0:1" "record: a failing git pull warns in the entry and the entry is still written"

# The customers file reaches by_agent_type, the repo name and the plan name, not only tools, skills and models.
homeZ="$workdir/homeZ"
mkdir -p "$homeZ"
new_work workz git@github.com:andrelin/zorbexapp.git
WZ="$W"
new_projects projectsz "$WZ"
PROJ="$workdir/projectsz"
printf '%s\n' 'Zzunrelated' > "$homeZ/.claude-customers"
new_log logz
HOME="$homeZ" run_ai "$WZ" record --dry-run plan-example.md "$C1"
assert "$rc:$(out | jq -r .level):$(out | jq -r .repo)" "0:personal:andrelin/zorbexapp" "(setup) a personal repo with an unrelated customers file records"
printf '%s\n' 'zorbexapp' > "$homeZ/.claude-customers"
HOME="$homeZ" run_ai "$WZ" level
# The guard must resolve this repo as personal (it does not match a customers-file word against the repo name),
# so the refusal below is what runs, never the deferral.
assert "$(out)" "personal" "(setup) the guard resolves a repo whose name holds a listed word as personal"
for flags in "" "--dry-run"; do
  # shellcheck disable=SC2086
  HOME="$homeZ" run_ai "$WZ" record $flags plan-example.md "$C1"
  assert "$rc:$(err | grep -c 'holds a name from ~/.claude-customers')" "1:1" "a customer term in the repo name refuses the record $flags"
done
# The plan name: rename the plan and its findings files, and the transcripts' mentions.
new_work workz2 git@github.com:andrelin/plainapp.git
WZ2="$W"
for f in "$WZ2"/plan-example*; do mv "$f" "${f/plan-example/plan-zorbexplan}"; done
commit_at "$WZ2" 2026-01-10T13:00:00Z "rename the plan"
new_projects projectsz2 "$WZ2"
find "$workdir/projectsz2" -name '*.jsonl' -exec sed -i.bak 's#plan-example\.md#plan-zorbexplan.md#g' {} +
find "$workdir/projectsz2" -name '*.bak' -delete
PROJ="$workdir/projectsz2"
CZ2="$(gitin "$WZ2" rev-parse HEAD)"
new_log logz2
printf '%s\n' 'Zzunrelated' > "$homeZ/.claude-customers"
HOME="$homeZ" run_ai "$WZ2" record --dry-run plan-zorbexplan.md "$CZ2"
assert "$rc:$(out | jq -r .plan)" "0:plan-zorbexplan.md" "(setup) a renamed plan records with an unrelated customers file"
printf '%s\n' 'zorbexplan' > "$homeZ/.claude-customers"
for flags in "" "--dry-run"; do
  # shellcheck disable=SC2086
  HOME="$homeZ" run_ai "$WZ2" record $flags plan-zorbexplan.md "$CZ2"
  assert "$rc:$(err | grep -c 'holds a name from ~/.claude-customers')" "1:1" "a customer term in the plan name refuses the record $flags"
  assert "$(entry_count)" "0" "$flags: and nothing is written"
done

# A custom agentType in a workflow agent's .meta.json reaches only by_agent_type, and that alone refuses the record.
new_work workz3 git@github.com:andrelin/plain3.git
WZ3="$W"
new_projects projectsz3 "$WZ3"
PROJ="$workdir/projectsz3"
printf '%s\n' '{"agentType":"zorbex-agent","description":"review:TESTS","workflowPhase":"Review","model":"opus"}' \
  > "$PROJ/-example-work/s1/subagents/workflows/wf_aaa/agent-w1.meta.json"
new_log logz3
printf '%s\n' 'Zzunrelated' > "$homeZ/.claude-customers"
HOME="$homeZ" run_ai "$WZ3" record --dry-run plan-example.md "$C1"
assert "$rc:$(out | jq -c '[.totals.by_agent_type | has("zorbex-agent")] + [[.totals.tools, .totals.skills, .totals.agents, .totals.tokens, .totals.workflows.phases] | map(keys | any(test("zorbex")))[] ] | unique')" '0:[false,true]' "(setup) the custom agent type sits in by_agent_type and in no other name field"
printf '%s\n' 'zorbex' > "$homeZ/.claude-customers"
for flags in "" "--dry-run"; do
  # shellcheck disable=SC2086
  HOME="$homeZ" run_ai "$WZ3" record $flags plan-example.md "$C1"
  assert "$rc:$(err | grep -c 'holds a name from ~/.claude-customers')" "1:1" "an agent type named for a listed customer refuses the record $flags"
  assert "$(out | grep -c zorbex):$(entry_count)" "0:0" "$flags: nothing printed or written carries it"
done

# Token redaction boundaries: a base64 or hex run of 32 characters is a token, 31 is not; an sk- body of 20, not 19.
function rep() { local n="$1" c="$2" r=""; while ((${#r} < n)); do r+="$c"; done; printf '%s' "${r:0:n}"; }
new_log logbd
PROJ="$workdir/projectsfx"
run_ai "$WFX" record plan-example.md "$C1"
IDBD="$(out | head -1 | sed 's/^entry: //')"
bd_in=$'## Worked\n'
bd_in+="- hex $(rep 31 0123456789abcdef) and $(rep 32 0123456789abcdef) (hex)."$'\n'
bd_in+="- run $(rep 31 a) and $(rep 32 a) (run)."$'\n'
bd_in+="- b64 $(rep 31 'Ab1/') and $(rep 32 'Ab1/') (b64)."$'\n'
bd_in+="- sk sk-$(rep 19 a) and sk-$(rep 20 a) (sk)."$'\n'
bd_in+=$'## Didn\'t\n- none (none)\n## Cut candidates\n- none (none)\n'
run_note "$WFX" "$IDBD" "$bd_in"
assert "$rc" "0" "(setup) the boundary input is accepted"
assert "$(grep -F '(hex)' "$workdir/out")" "- hex $(rep 31 0123456789abcdef) and [token] (hex)." "a 31-character hex run stays, 32 is a token"
assert "$(grep -F '(run)' "$workdir/out")" "- run $(rep 31 a) and [token] (run)." "a 31-character alphanumeric run stays, 32 is a token"
assert "$(grep -F '(b64)' "$workdir/out")" "- b64 $(rep 31 'Ab1/') and [token] (b64)." "a 31-character base64 run with slashes stays, 32 is a token"
assert "$(grep -F '(sk)' "$workdir/out")" "- sk sk-$(rep 19 a) and [token] (sk)." "an sk- body of 19 characters stays, 20 is a token"

# --- The push goes to the log repo only: a push URL elsewhere refuses -------------------------------------------------

notepu=$'## Worked\n- a (1).\n## Didn\'t\n- none (none)\n## Cut candidates\n- none (none)\n'
new_log logpu
git init -q --bare "$workdir/logpu-other.git"
gitin "$LOG" config remote.origin.pushurl "$workdir/logpu-other.git"
head_pu="$(gitin "$LOG" rev-parse HEAD)"
PROJ="$workdir/$PROJ_NAME"
for cmd in record note; do
  if [[ "$cmd" == record ]]; then run_ai "$W1" record plan-example.md "$C1"; else run_note "$W1" 2026-01-10-000000000000 "$notepu"; fi
  assert "$rc:$(err | grep -c 'push URL')" "2:1" "$cmd: a remote.origin.pushurl to another repo refuses"
done
assert "$(gitin "$LOG" rev-parse HEAD):$(entry_count):$(gitin "$workdir/logpu-other.git" rev-list --all --count)" "$head_pu:0:0" "and nothing was written or pushed"
# The same repo spelled differently as the push URL is fine.
gitin "$LOG" config remote.origin.pushurl "$(gitin "$LOG" remote get-url origin)"
run_ai "$W1" record plan-example.md "$C1"
assert "$rc" "0" "a push URL equal to the origin records"
# A bare push would follow a branch's upstream elsewhere: the push is explicit to origin.
new_log logup
git init -q --bare "$workdir/logup-other.git"
gitin "$LOG" remote add elsewhere "$workdir/logup-other.git"
gitin "$LOG" push -q elsewhere HEAD:refs/heads/main-elsewhere 2> /dev/null
gitin "$LOG" branch -q --set-upstream-to=elsewhere/main-elsewhere
run_ai "$W1" record plan-example.md "$C1"
assert "$rc:$(gitin "$workdir/logup-other.git" log --format=%s main-elsewhere | grep -c '^Record ')" "0:0" "an upstream on another remote is not pushed to"
assert "$(gitin "$BARE" log --format=%s | grep -c '^Record ')" "1" "the entry reached origin"

# --- A review kind from free text is stored as other -----------------------------------------------------------------------

new_work workk git@github.com:andrelin/x.git
WK="$W"
new_projects projectsk "$WK"
PROJ="$workdir/projectsk"
new_log logk
sed -i.bak 's/^## Review log (code, closed 2026-01-09)/## Review log (zqkind, closed 2026-01-09)/' "$WK/plan-example.md"
rm -f "$WK/plan-example.md.bak"
mv "$WK/plan-example-review-findings-code-closed-2026-01-09.md" "$WK/plan-example-review-findings-zqkind-closed-2026-01-09.md"
run_ai "$WK" record --dry-run plan-example.md "$C1"
assert "$rc" "0" "a review log of an unknown kind: exit 0"
assert "$(out | jq -c '[.reviews[].kind] | sort')" '["other","plan"]' "its kind is stored as other"
assert "$(out | jq -c '.findings | keys')" '["other","plan"]' "and so are its findings' keys"
assert "$(out | grep -c zqkind)" "0" "and the free-text kind is nowhere in the entry"

# --- Redaction: hosts on a country code that is also a file extension ----------------------------------------------------

new_log logcc
PROJ="$workdir/projectsk"
run_ai "$WK" record plan-example.md "$C1"
IDCC="$(out | head -1 | sed 's/^entry: //')"
cc_in=$'## Worked\n'
cc_in+=$'- build.zqclient.rs and a.b.zqclient.py and ci.zqclient.sh and BUILD.ZQCLIENT.MD host (three labels).\n'
cc_in+=$'- bin/ai-log.sh and test_x.py and setup.sh and README.md and release-1.2.3.md and tsconfig.build.json and a.test.ts stay (files).\n'
cc_in+=$'- zqclient.rs and zqclient.sh are a known gap (two labels).\n'
cc_in+=$'## Didn\'t\n- none (none)\n## Cut candidates\n- none (none)\n'
run_note "$WK" "$IDCC" "$cc_in"
assert "$rc" "0" "the country-code input is accepted"
assert "$(grep -F '(three labels)' "$workdir/out")" "- [host] and [host] and [host] and [host] host (three labels)." "three labels or more ending in rs, py, sh or md are hosts"
assert "$(grep -F '(files)' "$workdir/out")" "- bin/ai-log.sh and test_x.py and setup.sh and README.md and release-1.2.3.md and tsconfig.build.json and a.test.ts stay (files)." "file names stay: two labels, a path, a version, another extension"
assert "$(grep -F '(two labels)' "$workdir/out")" "- zqclient.rs and zqclient.sh are a known gap (two labels)." "a two-label host on those four is the documented gap"

# --- Drift degrades loudly: each path warns in the entry and on stderr, nulls its field, exits 0 -----------------------------

new_work workd git@github.com:andrelin/x.git
WD="$W"
new_projects projectsd "$WD"
PROJ="$workdir/projectsd"
PD_ROOT="$workdir/projectsd/-example-work"
# warned <message fragment> <what>: after a dry run in $WD, the warning is in the entry and on stderr, and the run exited 0.
function warned() {
  assert "$rc:$(out | jq -c --arg m "$1" '.warnings | map(select(test($m))) | length'):$([[ "$(err | grep -c "$1")" -ge 1 ]] && echo warned)" "0:1:warned" "$2: exit 0, a warning in the entry and on stderr"
}

# A corrupt entry file in the log clone, and one on origin.
new_log logd1
printf 'not json {' > "$LOG/entries.tmp"
mkdir -p "$LOG/entries"
mv "$LOG/entries.tmp" "$LOG/entries/2026-01-02-aaaaaaaaaaaa.json"
run_ai "$WD" record --dry-run plan-example.md "$C1"
warned 'an entry file in the log clone is not valid JSON' "a corrupt entry file in the log clone"
assert "$(out | jq -c '.window.after')" "null" "and it is no previous entry"
new_log logd2
git clone -q "$BARE" "$workdir/logd2-other" 2> /dev/null
mkdir -p "$workdir/logd2-other/entries"
printf 'not json {' > "$workdir/logd2-other/entries/2026-01-02-bbbbbbbbbbbb.json"
gitin "$workdir/logd2-other" add entries
gitin "$workdir/logd2-other" commit -q -m "A corrupt entry"
gitin "$workdir/logd2-other" push -q origin HEAD 2> /dev/null
run_ai "$WD" record --dry-run plan-example.md "$C1"
warned 'an entry file on origin is not valid JSON' "a corrupt entry file on origin"

# A transcript that cannot be read (a subagent's: the main one is found by reading it) and an agent lens that cannot be read.
if [[ "$(id -u)" != 0 ]]; then
  new_log logd3
  chmod 000 "$PD_ROOT/s1/subagents/agent-ag1.jsonl"
  run_ai "$WD" record --dry-run plan-example.md "$C1"
  chmod 644 "$PD_ROOT/s1/subagents/agent-ag1.jsonl"
  warned 'a transcript could not be fully read' "an unreadable agent transcript"
  assert "$(err | grep -c "an agent transcript's lens could not be read")" "1" "an unreadable agent transcript: its lens warns too"
fi
new_log logd4
stub_jq_failing_on "def utext"
PATH="$workdir/pickyjq:$PATH" run_ai "$WD" record --dry-run plan-example.md "$C1"
warned "an agent transcript's lens could not be read" "an agent lens that fails to read"
assert "$(out | jq -c '[.reviews, .totals] | map(. != null) | all')" "true" "and the entry still has its reviews and totals"

# An unreadable workflow summary.
new_log logd5
printf 'not json {' > "$PD_ROOT/s1/workflows/wf_aaa.json"
run_ai "$WD" record --dry-run plan-example.md "$C1"
warned 'a workflow summary could not be read' "a workflow summary that is not JSON"
assert "$(out | jq -c '.totals.workflows.runs')" "0" "an unreadable workflow summary: no run is counted from it"
rm -rf "$workdir/projectsd"
new_projects projectsd "$WD"

# A tree with no review-lenses.md and one that is not a git checkout.
TREE3="$workdir/tree3"
make_tree "$TREE3"
rm "$TREE3/claude/docs/review-lenses.md"
new_log logd6
AI_BIN="$TREE3/bin/ai-log" run_ai "$WD" record --dry-run plan-example.md "$C1"
warned 'review-lenses.md not found' "a missing review-lenses.md"
assert "$(out | jq -c '[.findings[] | keys[]] | unique')" '["other"]' "and every finding's lens is other"
TREE4="$workdir/tree4"
make_tree "$TREE4"
rm -rf "$TREE4/.git"
new_log logd7
AI_BIN="$TREE4/bin/ai-log" run_ai "$WD" record --dry-run plan-example.md "$C1"
warned 'is not a git checkout' "a tree that is not a git checkout"
assert "$(out | jq -c '.framework.dotfiles_commit')" "null" "a tree that is not a git checkout: dotfiles_commit is null"

# A failed git pull --rebase in the log clone: a warning on stderr, the commit kept, no rebase left half done.
mkdir -p "$workdir/pickygit"
printf '#!/bin/bash\ncase "$*" in *"pull --rebase"*) exit 1 ;; esac\nPATH="${PATH#*:}"\nexec git "$@"\n' > "$workdir/pickygit/git"
chmod +x "$workdir/pickygit/git"
new_log logd8
PATH="$workdir/pickygit:$PATH" run_ai "$WD" record plan-example.md "$C1"
assert "$rc:$(err | grep -c 'git pull --rebase in the log clone failed')" "0:1" "a failing git pull --rebase: exit 0 and a warning on stderr"
assert "$(gitin "$LOG" log -1 --format=%s | cut -c1-7):$(gitin "$LOG" status --porcelain)" "Record :" "and the commit is kept in a clean clone"
new_log logd9
run_ai "$WD" record plan-example.md "$C1"
IDD9="$(out | head -1 | sed 's/^entry: //')"
PATH="$workdir/pickygit:$PATH" run_note "$WD" "$IDD9" "$notepu"
assert "$rc:$(err | grep -c 'git pull --rebase in the log clone failed')" "0:1" "note: a failing git pull --rebase exits 0 with a warning on stderr"
assert "$(gitin "$LOG" log -1 --format=%s):$(gitin "$LOG" status --porcelain)" "Note $IDD9:" "note: the commit is kept in a clean clone"

# --- The skills and docs that trigger ai-log ------------------------------------------------------------------------------

riskill="$REPO/claude/skills/reviewing-in-rounds/SKILL.md"
assert "$(grep -c 'ai-log record <plan-file>' "$riskill")" "1" "reviewing-in-rounds names ai-log record <plan-file> once"
# Ordinals of the list items of § Completion of a code review: the record step is one item, after the one that runs the commit.
function ord_of() { awk -v pat="$1" '/^## Completion of a code review/ {s=1; next} /^## / {s=0} s && /^[0-9]+\. / {n++} s && index($0, pat) {print n; exit}' "$riskill"; }
ord_commit="$(ord_of 'run it only on a yes')"
ord_after="$(ord_of 'After the commit runs')"
ord_record="$(ord_of 'ai-log record <plan-file>')"
assert "$([[ -n "$ord_commit" && -n "$ord_after" && -n "$ord_record" ]] && echo found)" "found" "the commit, after-commit and record steps are list items of Completion"
assert "$([[ "$ord_commit" -lt "$ord_after" && "$ord_after" -lt "$ord_record" ]] && echo ordered)" "ordered" "the record step comes after the commit step and the one that follows the commit"
assert "$(awk '/^## Completion of a code review/ {s=1; next} /^## / {s=0} s && /^[0-9]+\. / {n++} s && /ai-log record <plan-file>/ {c[n]++} END {for (i in c) k++; print k+0}' "$riskill")" "1" "the record text sits in a single list item"
assert "$(cd "$REPO" && bin/check-md-limits claude/skills/reviewing-in-rounds/SKILL.md claude/docs/work-contexts.md > /dev/null 2>&1 && echo ok)" "ok" "check-md-limits passes on the skill and on work-contexts.md"
assert "$([[ "$(grep -c 'ai-log' "$REPO/claude/docs/work-contexts.md")" -ge 1 ]] && echo ok)" "ok" "work-contexts.md names ai-log"
assert "$([[ "$(grep -c 'ai-log level' "$REPO/claude/docs/session-end-save.md")" -ge 1 ]] && echo ok)" "ok" "session-end-save.md gates on ai-log level"
assert "$([[ "$(grep -c 'Work in progress: Tasks' "$REPO/claude/docs/session-end-save.md")" -ge 1 ]] && echo ok)" "ok" "session-end-save.md names the Work in progress commit"
ipskill="$REPO/claude/skills/implementing-plans/SKILL.md"
assert "$(grep -c 'session-end-save.md' "$ipskill")" "1" "implementing-plans points at session-end-save.md once"
# The pointer sits within the first 100 counted lines (as check-md-limits counts them, over the file up to that line).
ptr_lineno="$(grep -nF -m1 -- 'session-end-save.md' "$ipskill" | cut -d: -f1)"
ptr_prefix="$workdir/ptr-prefix.md"
head -n "${ptr_lineno:-0}" "$ipskill" > "$ptr_prefix"
ptr_line="$("$REPO/bin/check-md-limits" --count-raw "$ptr_prefix" 2> /dev/null || true)"
assert "$([[ -n "$ptr_line" && "$ptr_line" -le 100 ]] && echo ok)" "ok" "the session-end pointer is within the first 100 counted lines of implementing-plans"

# --- A dry run reads origin's version of a re-recorded entry, not a stale local copy ------------------------------------

new_log log31
git clone -q "$BARE" "$workdir/log31b" 2> /dev/null
PROJ="$workdir/$PROJ_NAME"
run_ai "$W1" record plan-example.md "$C1"
id31="$(out | head -1 | sed 's/^entry: //')"
gitin "$workdir/log31b" pull -q 2> /dev/null
jq '.window.end = "2026-01-10T13:00:00.000Z"' "$workdir/log31b/entries/$id31.json" > "$workdir/e31.json"
cp "$workdir/e31.json" "$workdir/log31b/entries/$id31.json"
gitin "$workdir/log31b" commit -q -am "Re-record $id31"
gitin "$workdir/log31b" push -q origin HEAD 2> /dev/null
head31="$(gitin "$LOG" rev-parse HEAD)"
sum31="$(cksum < "$LOG/entries/$id31.json")"
run_ai "$W1" record --dry-run plan-example.md "$C2"
assert "$rc:$(out | jq -c '[.window.start, .window.after]')" "0:[\"2026-01-10T13:00:00.000Z\",\"$id31\"]" "a dry run uses origin's re-recorded entry, with the later window end, over a stale local copy"
assert "$(gitin "$LOG" rev-parse HEAD):$(cksum < "$LOG/entries/$id31.json"):$(gitin "$LOG" status --porcelain)" "$head31:$sum31:" "and writes nothing into the clone"
# A local copy with the later end (an unpushed re-record) beats origin's older one.
jq '.window.end = "2026-01-10T14:00:00.000Z"' "$LOG/entries/$id31.json" > "$workdir/e31b.json"
cp "$workdir/e31b.json" "$LOG/entries/$id31.json"
run_ai "$W1" record --dry-run plan-example.md "$C2"
assert "$rc:$(out | jq -c '.window.start')" "0:\"2026-01-10T14:00:00.000Z\"" "a local copy with the later end still wins"
gitin "$LOG" checkout -q -- "entries/$id31.json"

# --- The log clone's origin must be the log repo ---------------------------------------------------------------------

new_log log15
PROJ="$workdir/$PROJ_NAME"
head15="$(gitin "$LOG" rev-parse HEAD)"
note15=$'## Worked\n- a (1).\n## Didn\'t\n- none (none)\n## Cut candidates\n- none (none)\n'
for cmd in record note; do
  if [[ "$cmd" == record ]]; then
    TEST_LOG_REMOTE=github.com/example-owner/other-log run_ai "$W1" record plan-example.md "$C1"
  else
    TEST_LOG_REMOTE=github.com/example-owner/other-log run_note "$W1" 2026-01-10-000000000000 "$note15"
  fi
  assert "$rc:$(err | grep -c 'is not github.com/example-owner/other-log')" "2:1" "$cmd: a clone whose origin is not the expected remote refuses, naming it"
done
assert "$(gitin "$LOG" rev-parse HEAD):$(entry_count)" "$head15:0" "and nothing was written"
# The default expectation: no AI_LOG_REMOTE at all.
(cd "$W1" && AI_LOG_DIR="$LOG" AI_LOG_PROJECTS="$PROJ" AI_LOG_PLUGINS="$FIX/installed_plugins.json" "$AI" record plan-example.md "$C1") > "$workdir/out" 2> "$workdir/err" && rc=0 || rc=$?
assert "$rc:$(err | grep -c 'is not github.com/andrelin/ai-framework-log')" "2:1" "the default remote is github.com/andrelin/ai-framework-log"
assert "$(entry_count)" "0" "and nothing was written by the default"
# The override accepts an origin that normalizes to it, however the clone spells it (the dry run's fetch of a reserved name only warns).
for pair in "git@github.com-example:Example-Owner/Other-Log.git|github.com/example-owner/other-log" \
  "https://git.example/example-owner/other-log.git|git.example/example-owner/other-log"; do
  gitin "$LOG" remote set-url origin "${pair%%|*}"
  GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND=false TEST_LOG_REMOTE="${pair##*|}" run_ai "$W1" record --dry-run plan-example.md "$C1"
  assert "$rc" "0" "the remote override accepts an origin that normalizes to it (${pair%%|*})"
done

# --- normalize_origin follows the guard's parse_url and host_alias ---------------------------------------------------------

# fn_src <name> <file>: one top-level function of a script, found by its header line.
function fn_src() { awk -v n="$1" '$0 ~ "^(function )?" n "\\(\\) \\{" {p = 1} p {print} p && /^}/ {exit}' "$2"; }
guard_defs="$(for f in parse_url vs_org_host host_alias lower_eq; do fn_src "$f" "$REPO/claude/hooks/work-context.sh"; done)"
ai_defs="$(fn_src normalize_origin "$AI_LOG_SRC")"
assert "$([[ -n "$guard_defs" && -n "$ai_defs" ]] && echo found)" "found" "(setup) the guard's and ai-log's origin functions are found"
function guard_read() { "$BASH" -c "$guard_defs"$'\n''parse_url "$1" && printf "%s %s %s" "$U_HOST" "$U_OWNER" "$U_REPO"' _ "$1"; }
function ai_read() { "$BASH" -c "$ai_defs"$'\n''normalize_origin "$1"' _ "$1"; }
while IFS='|' read -r url want; do
  [[ -n "$url" ]] || continue
  [[ "$want" != "-" ]] || want=""
  got="$(ai_read "$url")"
  assert "$got" "$want" "normalize_origin: $url"
  g="$(guard_read "$url")"
  if [[ -z "$g" ]]; then
    assert "$got" "" "the guard reads $url as no remote, so does ai-log"
  else
    read -r _ gowner grepo <<< "$g"
    assert "$(cut -d/ -f2 <<< "$got"):${got##*/}" "${gowner,,}:${grepo,,}" "ai-log and the guard agree on the owner and repo of $url"
  fi
done << 'EOF'
git@github.com:andrelin/x.git|github.com/andrelin/x
https://GitHub.com/Andrelin/X|github.com/andrelin/x
ssh://git@github.com:22/andrelin/x.git|github.com/andrelin/x
git@github.com-personal:andrelin/x.git|github.com/andrelin/x
git@github.com_personal:andrelin/x.git|github.com/andrelin/x
git@github.com.personal:andrelin/x.git|github.com/andrelin/x
git@work_github.com:andrelin/x.git|github.com/andrelin/x
git@work-github.com:andrelin/x.git|github.com/andrelin/x
git@work.github.com:andrelin/x.git|github.com/andrelin/x
git@gitlab.com-work:grp/x.git|gitlab.com/grp/x
git@acme:grp/x.git|acme/grp/x
git@acme-github:grp/x.git|acme-github/grp/x
git@ado:v3/org/proj/repo|dev.azure.com/org/proj/repo
git@ssh.dev.azure.com:v3/org/proj/repo|dev.azure.com/org/proj/repo
git@ssh.dev.azure.com-work:v3/org/proj/repo|dev.azure.com/org/proj/repo
git@vs-ssh.visualstudio.com:v3/org/proj/repo|dev.azure.com/org/proj/repo
https://org@dev.azure.com/org/proj/_git/repo|dev.azure.com/org/proj/repo
https://org.visualstudio.com/proj/_git/repo|dev.azure.com/org/proj/repo
/srv/git/x.git|-
./x|-
../x|-
ftp://github.com/andrelin/x|-
file:///srv/git/x|-
https://github.com|-
https://github.com/x|-
git@github.com:x|-
git@github.com:|-
|-
EOF

# --- A reused plan name with a different Base: line starts a new chain, with no deletion in git ----------------------------

new_work workb git@github.com:andrelin/b.git
WB="$W"
new_projects projectsb "$WB"
PROJ="$workdir/projectsb"
new_log logb
function b_session() { # <uuid> <timestamp> <input tokens>
  jq -c -n --arg cwd "$WB" --arg u "$1" --arg t "$2" --argjson n "$3" '{type: "assistant", uuid: $u, timestamp: $t, cwd: $cwd, version: "2.1.309",
    message: {id: ("m-" + $u), model: "claude-opus-5-5", content: [{type: "tool_use", id: ("t" + $u), name: "Read", input: {file_path: "plan-example.md"}}],
    usage: {input_tokens: $n, output_tokens: 1}}}' > "$PROJ/-example-work/$1.jsonl"
}
printf '\nBase: %s\n' "$C0" >> "$WB/plan-example.md"
commit_at "$WB" 2026-01-20T12:00:00Z "plan with a base"
CB1="$(gitin "$WB" rev-parse HEAD)"
run_ai "$WB" record plan-example.md "$CB1"
IDB1="$(out | head -1 | sed 's/^entry: //')"
assert "$rc:$(jq -r .plan_base "$LOG/entries/$IDB1.json")" "0:$C0" "the entry holds the plan's Base sha"
# The same Base, spelled short and in backticks, continues the chain.
sed -i.bak "s/^Base: .*/Base: \`${C0:0:7}\`/" "$WB/plan-example.md" && rm "$WB/plan-example.md.bak"
echo b2 > "$WB/b2.txt"
commit_at "$WB" 2026-01-25T12:00:00Z "continues"
CB2="$(gitin "$WB" rev-parse HEAD)"
b_session b-s6 2026-01-22T10:00:00.000Z 11
run_ai "$WB" record plan-example.md "$CB2"
IDB2="$(out | head -1 | sed 's/^entry: //')"
assert "$rc:$(jq -c '[.window.after, .plan_base]' "$LOG/entries/$IDB2.json")" "0:[\"$IDB1\",\"$C0\"]" "the same Base (short, in backticks) continues the chain, and is stored in full"
# An older entry without plan_base counts as the same chain.
LOGB="$LOG"
new_log logb2
run_ai "$WB" record plan-example.md "$CB1"
IDO1="$(out | head -1 | sed 's/^entry: //')"
jq 'del(.plan_base)' "$LOG/entries/$IDO1.json" > "$workdir/eo.json"
cp "$workdir/eo.json" "$LOG/entries/$IDO1.json"
gitin "$LOG" commit -q -am "An older entry"
run_ai "$WB" record plan-example.md "$CB2"
assert "$rc:$(jq -r '.window.after' "$LOG/entries/$(out | head -1 | sed 's/^entry: //').json")" "0:$IDO1" "an older entry without plan_base continues the chain"
LOG="$LOGB"
# A different Base is another plan, though nothing was deleted: a new chain from the old chain's last window end.
sed -i.bak "s/^Base: .*/Base: $C1/" "$WB/plan-example.md" && rm "$WB/plan-example.md.bak"
echo b3 > "$WB/b3.txt"
commit_at "$WB" 2026-02-01T12:00:00Z "a new plan, same name"
CB3="$(gitin "$WB" rev-parse HEAD)"
b_session b-s7 2026-01-28T10:00:00.000Z 7
run_ai "$WB" record plan-example.md "$CB3"
IDB3="$(out | head -1 | sed 's/^entry: //')"
assert "$rc:$(jq -c '[.window.start, .window.after, .plan_base, .totals.tokens["claude-opus-5-5"].input]' "$LOG/entries/$IDB3.json")" "0:[\"2026-01-28T10:00:00.000Z\",null,\"$C1\",7]" "a different Base starts a new chain: its own first window, none of the old tokens"
assert "$(out | grep -c '^  windows: 1$')" "1" "and the summary covers the new chain only"
# No Base line now: the deletion fallback, which sees none, so the chain continues.
grep -v '^Base: ' "$WB/plan-example.md" > "$workdir/plan.nobase"
cp "$workdir/plan.nobase" "$WB/plan-example.md"
echo b4 > "$WB/b4.txt"
commit_at "$WB" 2026-02-10T12:00:00Z "no base line"
CB4="$(gitin "$WB" rev-parse HEAD)"
b_session b-s8 2026-02-05T10:00:00.000Z 3
run_ai "$WB" record plan-example.md "$CB4"
assert "$rc:$(jq -c '[.window.after, .plan_base]' "$LOG/entries/$(out | head -1 | sed 's/^entry: //').json")" "0:[\"$IDB3\",null]" "a plan with no Base line falls back to the deletion check and continues"

# --- Folder names above a repo outside HOME are all repo words --------------------------------------------------------------

new_work zqouter/yqmid/wk git@github.com:andrelin/zqrepo.git
WO="$W"
new_projects projectsout "$WO"
PROJ="$workdir/projectsout"
new_log logout
run_ai "$WO" record plan-example.md "$C1"
IDO="$(out | head -1 | sed 's/^entry: //')"
assert "$rc" "0" "a repo outside HOME records"
run_note "$WO" "$IDO" $'## Worked\n- zqouter and yqmid and wk and zqrepo (a).\n## Didn\'t\n- none (none)\n## Cut candidates\n- none (none)\n'
assert "$(sed -n 2p "$workdir/out")" "- [repo] and [repo] and [repo] and [repo] (a)." "outside HOME every folder above the repo, and its own, is redacted"

# --- Files edits ----------------------------------------------------------------------------------------------------

assert "$(cd "$REPO" && bin/check-md-limits tips/25_ai_framework.md tips.md README.md > /dev/null 2>&1 && echo ok)" "ok" "check-md-limits passes on the tip file, tips.md and README.md"
assert "$(grep -cw 'bin/ai-log' "$REPO/.github/workflows/shellcheck.yml")" "1" "bin/ai-log is in the ShellCheck list once"
assert "$([[ "$(grep -c 'ai-log record' "$REPO/tips/25_ai_framework.md")" -ge 1 ]] && echo ok)" "ok" "the tip names ai-log record"

test_done
