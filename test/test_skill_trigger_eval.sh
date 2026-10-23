#!/usr/bin/env bash
# Resolve the script before sourcing the helper: bin/dotfiles exports
# DOTFILES=~/.dotfiles when sourced, so afterwards this would test whatever tree
# lives there rather than the one this file was launched from.
SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bin/skill-trigger-eval"
readonly SCRIPT

source "$DOTFILES/test/helper.sh"

if [[ ! -x "$SCRIPT" ]]; then
  echo "ERROR: $SCRIPT is missing or not executable" >&2
  exit 1
fi

e_header "$(basename "$0" .sh)"

# Nothing here runs the real claude or run_eval: a stub python stands in for run_eval and drives a stub claude
# through the script's recording wrapper, the way run_eval does, so each failure mode can be forced on demand.

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
export HOME="$workdir/home" DOTFILES="$workdir/dots"
export SKILL_TRIGGER_EVAL_SKILLS_DIR="$workdir/skills"
export STUB_LOG="$workdir/log"
stubs="$workdir/stubs"
mkdir -p "$HOME/.claude/plugins" "$workdir/plugin/skills/skill-creator/scripts" "$DOTFILES/test/skill-triggers" \
  "$DOTFILES/caches" "$stubs" "$STUB_LOG"
touch "$workdir/plugin/skills/skill-creator/scripts/run_eval.py"
jq -n --arg p "$workdir/plugin" '{plugins: {"skill-creator@claude-plugins-official": [{installPath: $p}]}}' \
  > "$HOME/.claude/plugins/installed_plugins.json"
for s in fixture writing-plans; do
  mkdir -p "$SKILL_TRIGGER_EVAL_SKILLS_DIR/$s"
  printf -- '---\nname: %s\ndescription: Read when testing.\n---\n' "$s" > "$SKILL_TRIGGER_EVAL_SKILLS_DIR/$s/SKILL.md"
  echo '[]' > "$DOTFILES/test/skill-triggers/$s.json"
done

# The stub python passes the version probe unless STUB_PY_OLD is set. As run_eval it records what it was given and
# whether the skill was hidden, then runs `claude -p x` twice from PATH and prints {}. STUB_PY_MODE forces a failure:
# kill-before kills a claude before it prints, kill-after kills one after a tool_use event, each closing the pipe as
# run_eval does, and kill-after then waits past the time the killed claude would act; query-failed prints run_eval's
# warning. Two leave a lingering claude to the script: orphan exits with one running, hang never returns.
cat > "$stubs/python" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == -c ]]; then [[ -z "${STUB_PY_OLD:-}" ]]; exit; fi
printf '%s\n' "$@" > "$STUB_LOG/argv"
pwd -P > "$STUB_LOG/cwd"
printf '%s\n' "$PYTHONPATH" > "$STUB_LOG/pythonpath"
[[ -e "$SKILL_TRIGGER_EVAL_SKILLS_DIR/${STUB_SKILL:-fixture}" ]] && echo present > "$STUB_LOG/during" \
  || echo hidden > "$STUB_LOG/during"
[[ -n "${STUB_PY_PAUSE:-}" ]] && sleep "$STUB_PY_PAUSE"
case "${STUB_PY_MODE:-}" in
  kill-before)
    rm -f "$STUB_LOG/started"
    exec 3< <(STUB_CLAUDE_DELAY=2 exec claude -p x)
    for _ in {1..50}; do [[ -e "$STUB_LOG/started" ]] && break; sleep 0.1; done
    kill -9 $!
    exec 3<&- ;;
  kill-after)
    exec 3< <(STUB_CLAUDE_LINGER=1 exec claude -p x)
    read -r -u 3 _
    kill -9 $!
    exec 3<&-
    sleep 3 ;;
  orphan)
    STUB_CLAUDE_LINGER=1 claude -p x > /dev/null &
    for _ in {1..50}; do [[ -s "$STUB_LOG/pids" ]] && break; sleep 0.1; done
    echo '{}'
    exit ;;
  hang)
    exec 3< <(STUB_CLAUDE_LINGER=1 exec claude -p x)
    sleep 30 ;;
  query-failed)
    echo "Warning: query failed: boom" >&2 ;;
esac
claude -p x > /dev/null
claude -p x > /dev/null
echo '{}'
EOF
# The stub claude keeps its arguments and settings file, prints one stream event, after STUB_CLAUDE_DELAY seconds,
# then exits with STUB_CLAUDE_RC. With a delay set it holds on afterwards, as a real run does until it is killed.
# With STUB_CLAUDE_LINGER it goes on with the query as a real run would: it starts a tool shell in a process group of
# its own, logging both pids, and marks that it acted two seconds after its event, so a killed run never marks.
cat > "$stubs/claude" <<'EOF'
#!/usr/bin/env bash
touch "$STUB_LOG/started"
printf '%s\n' "$@" > "$STUB_LOG/claude-argv"
settings="$(grep -A1 -x -- --settings "$STUB_LOG/claude-argv" | tail -1)"
[[ -f "$settings" ]] && cp "$settings" "$STUB_LOG/settings.json"
sleep "${STUB_CLAUDE_DELAY:-0}"
echo '{"type":"stream_event","event":{"type":"content_block_start","content_block":{"type":"tool_use","name":"Skill"}}}'
if [[ -n "${STUB_CLAUDE_LINGER:-}" ]]; then
  echo "$$" >> "$STUB_LOG/pids"
  set -m
  sleep 30 &
  echo "$!" >> "$STUB_LOG/pids"
  set +m
  sleep 2
  touch "$STUB_LOG/acted"
  sleep 30
fi
[[ -n "${STUB_PY_MODE:-}" ]] && sleep 2
exit "${STUB_CLAUDE_RC:-0}"
EOF
chmod +x "$stubs/python" "$stubs/claude"
export SKILL_TRIGGER_EVAL_PYTHON="$stubs/python"
PATH="$stubs:$PATH"

function run() { "$SCRIPT" "$@" > "$workdir/stdout" 2> "$workdir/stderr" && rc=0 || rc=$?; }
function arg_after() { grep -A1 -x -- "$1" "$STUB_LOG/argv" | tail -1; }
# How many of the lingering claudes and their tool shells are still alive.
function alive() {
  local n=0 p
  while read -r p; do kill -0 "$p" 2>/dev/null && n=$((n + 1)); done < "$STUB_LOG/pids"
  echo "$n"
}
function fresh_linger() { : > "$STUB_LOG/pids"; rm -f "$STUB_LOG/acted"; }

run fixture
assert "$rc" "0" "a clean run exits 0"
assert "$(cat "$workdir/stdout")" "{}" "a clean run prints run_eval's JSON"
assert "$(grep -c -x -e -m -e scripts.run_eval "$STUB_LOG/argv")" "2" "run_eval runs as a module"
assert "$(cat "$STUB_LOG/pythonpath")" "$workdir/plugin/skills/skill-creator" "PYTHONPATH is the plugin's skill-creator"
assert "$(arg_after --eval-set)" "$(cd "$DOTFILES" && pwd -P)/test/skill-triggers/fixture.json" "the eval set is passed by absolute path"
assert "$(arg_after --skill-path | cut -c1)" "/" "the skill path is absolute"
assert "$(arg_after --timeout)" "120" "each query gets 120 seconds"
assert "$(arg_after --runs-per-query)" "3" "each query runs three times"
cwd="$(cat "$STUB_LOG/cwd")"
assert "$([[ "$cwd" != "$workdir"* && "$cwd" != "$DOTFILES"* && ! -e "$cwd" ]] && echo yes)" "yes" \
  "run_eval runs in a temp project, removed afterwards"
assert "$(arg_after --model)" "opus" "a skill outside the stages runs on opus"
assert "$(grep -c -x -- --description "$STUB_LOG/argv")" "0" "no --description unless one is given"

run fixture --description "Read when X."
assert "$(arg_after --description)" "Read when X." "--description is passed through"

STUB_SKILL=writing-plans AI_MODEL_PLAN=haiku run writing-plans
assert "$(arg_after --model)" "haiku" "a stage skill runs on its bin/ai model"
STUB_SKILL=writing-plans run writing-plans
assert "$(arg_after --model)" "opus" "writing-plans defaults to opus"
STUB_SKILL=writing-plans AI_MODEL_PLAN=haiku run writing-plans --model sonnet
assert "$(arg_after --model)" "sonnet" "--model beats the stage's model"

e_header "hiding the installed copy"

run fixture
assert "$(cat "$STUB_LOG/during")" "hidden" "the skill is hidden while run_eval runs"
assert "$([[ -f "$SKILL_TRIGGER_EVAL_SKILLS_DIR/fixture/SKILL.md" ]] && echo back)" "back" "the skill is back after a run"
assert "$([[ -e "$DOTFILES/caches/.skill-trigger-eval-moved" ]] && echo left || echo gone)" "gone" \
  "no marker is left after a run"

STUB_PY_PAUSE=10 "$SCRIPT" fixture > /dev/null 2>&1 &
pid=$!
for _ in {1..50}; do [[ ! -e "$SKILL_TRIGGER_EVAL_SKILLS_DIR/fixture" ]] && break; sleep 0.1; done
SECONDS=0
kill "$pid"
wait "$pid" 2>/dev/null
assert "$((SECONDS < 5))" "1" "a kill mid-run stops the run without waiting for run_eval"
assert "$([[ -f "$SKILL_TRIGGER_EVAL_SKILLS_DIR/fixture/SKILL.md" ]] && echo back)" "back" "the skill is back after a kill mid-run"

echo "fixture $workdir/elsewhere" > "$DOTFILES/caches/.skill-trigger-eval-moved"
run fixture
assert "$rc" "1" "a marker left by an earlier run makes the next one refuse"
assert "$(grep -c 'elsewhere' "$workdir/stderr")" "1" "the refusal says where the skill was left"
rm "$DOTFILES/caches/.skill-trigger-eval-moved"

e_header "failures are never scores"

STUB_CLAUDE_RC=1 run fixture
assert "$rc/$(wc -c < "$workdir/stdout" | tr -d ' ')" "1/0" "a claude run exiting 1 fails with nothing on stdout"
assert "$(grep -c '2 of 2' "$workdir/stderr")" "1" "the failure counts the failed runs"

STUB_PY_MODE=kill-before run fixture
assert "$rc/$(wc -c < "$workdir/stdout" | tr -d ' ')" "1/0" "a run killed before any stream event fails"

STUB_PY_MODE=kill-after run fixture
assert "$rc" "0" "a run killed after a stream event is a normal decided run"
assert "$(cat "$workdir/stdout")" "{}" "a decided run still prints the JSON"

STUB_PY_MODE=query-failed run fixture
assert "$rc/$(wc -c < "$workdir/stdout" | tr -d ' ')" "1/0" "run_eval's query-failed warning fails the run"
assert "$(grep -c 'query failed' "$workdir/stderr")" "1" "run_eval's stderr is passed through"

e_header "no run acts or outlives the script"

run fixture
assert "$(grep -c -x -- --settings "$STUB_LOG/claude-argv")" "1" "each claude gets a settings file"
hook="$(jq -r '.hooks.PreToolUse[] | select(.matcher == "*") | .hooks[0].command' "$STUB_LOG/settings.json")"
bash -c "$hook" 2>/dev/null && hook_rc=0 || hook_rc=$?
assert "$hook_rc" "2" "its PreToolUse hook blocks every tool call"

fresh_linger
STUB_PY_MODE=kill-after run fixture
assert "$rc" "0" "a decided run with a lingering claude still scores"
assert "$([[ -e "$STUB_LOG/acted" ]] && echo acted || echo stopped)" "stopped" \
  "a decided run's claude is killed when run_eval kills the run, not when the script ends"
assert "$(alive)" "0" "nothing of a decided run is left, its tool shell included"

fresh_linger
STUB_PY_MODE=orphan run fixture
assert "$rc" "0" "a claude still running when run_eval returns does not fail the score"
sleep 3
assert "$(alive)/$([[ -e "$STUB_LOG/acted" ]] && echo acted || echo stopped)" "0/stopped" \
  "a claude still running when the script exits is killed with its tool shell"

for sig in TERM INT; do
  fresh_linger
  # With job control on, so the script does not start with SIGINT ignored, as a background job otherwise would.
  set -m
  STUB_PY_MODE=hang "$SCRIPT" fixture > /dev/null 2>&1 &
  pid=$!
  set +m
  for _ in {1..50}; do [[ $(wc -l < "$STUB_LOG/pids") -ge 2 ]] && break; sleep 0.1; done
  kill "-$sig" "$pid"
  wait "$pid" 2>/dev/null
  sleep 3
  assert "$(alive)/$([[ -e "$STUB_LOG/acted" ]] && echo acted || echo stopped)" "0/stopped" \
    "SIG$sig to the script kills a running claude and its tool shell"
done

e_header "missing prerequisites"

run nosuchskill
assert "$rc" "1" "a skill with no SKILL.md exits 1"
rm "$DOTFILES/test/skill-triggers/fixture.json"
run fixture
assert "$rc" "1" "a missing eval set exits 1"
assert "$([[ -d "$SKILL_TRIGGER_EVAL_SKILLS_DIR/fixture" ]] && echo kept)" "kept" "a refused run never moves the skill"
echo '[]' > "$DOTFILES/test/skill-triggers/fixture.json"

STUB_PY_OLD=1 run fixture
assert "$rc" "1" "a python older than 3.10 exits 1"

mv "$HOME/.claude/plugins/installed_plugins.json" "$workdir/installed"
run fixture
assert "$rc" "1" "a missing plugin exits 1"
assert "$(grep -c '53_claude_plugins' "$workdir/stderr")" "1" "a missing plugin names the init script"
mv "$workdir/installed" "$HOME/.claude/plugins/installed_plugins.json"

# A PATH with jq and the system tools but no claude.
mkdir -p "$workdir/noclaude"
ln -s "$stubs/python" "$workdir/noclaude/python"
ln -s "$(type -P jq)" "$workdir/noclaude/jq"
PATH="$workdir/noclaude:/usr/bin:/bin" run fixture
assert "$rc" "1" "a missing claude exits 1"

mkdir -p "$workdir/nopgrep"
for tool in /usr/bin/* /bin/*; do
  [[ "${tool##*/}" == pgrep || -e "$workdir/nopgrep/${tool##*/}" ]] || ln -s "$tool" "$workdir/nopgrep/"
done
ln -sf "$(type -P bash)" "$workdir/nopgrep/bash"
ln -sf "$(type -P jq)" "$workdir/nopgrep/jq"
PATH="$stubs:$workdir/nopgrep" run fixture
assert "$rc/$(grep -c pgrep "$workdir/stderr")" "1/1" "a missing pgrep exits 1 naming it"

run
assert "$rc" "2" "no skill is a usage error"

test_done
