#!/usr/bin/env bash
# Resolve the script before sourcing the helper: bin/dotfiles exports
# DOTFILES=~/.dotfiles when sourced, so afterwards this would test whatever tree
# lives there rather than the one this file was launched from.
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AI="$REPO/bin/ai"
readonly REPO AI

source "$DOTFILES/test/helper.sh"

if [[ ! -x "$AI" ]]; then
  echo "ERROR: $AI is missing or not executable" >&2
  exit 1
fi

e_header "$(basename "$0" .sh)"

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
mkdir -p "$workdir/run" "$workdir/empty"
touch "$workdir/run/p.md"
cat > "$workdir/stub" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@"
EOF
printf '#!/usr/bin/env bash\nexit 3\n' > "$workdir/stub3"
chmod +x "$workdir/stub" "$workdir/stub3"
unset CLAUDECODE AI_MODEL_ISSUE AI_MODEL_PLAN AI_MODEL_IMPLEMENT AI_MODEL_REVIEW
export AI_CLAUDE="$workdir/stub"
cd "$workdir/run" || exit 1

function run() { "$AI" "$@" > "$workdir/stdout" 2> "$workdir/stderr" && rc=0 || rc=$?; }
function out() { cat "$workdir/stdout"; }
function model() { grep -A1 -x -- --model "$workdir/stdout" | tail -1; }
function prompt() { tail -1 "$workdir/stdout"; }
usage_line='usage: ai [--model <m>] <stage> [args…]'

# The stages, their default models and their prompts.
run plan 12
assert "$(out)" $'--model\nopus\n/writing-plans 12' "ai plan 12"
run issue
assert "$(model)" "sonnet" "the issue stage defaults to sonnet"
run implement p.md
assert "$(out)" $'--model\nsonnet\n/implementing-plans p.md' "ai implement p.md"
run review plan p.md
assert "$(out)" $'--model\nopus\n/reviewing-in-rounds plan p.md' "ai review plan p.md"

# A stage's variable beats its default, --model beats the variable, and an empty variable counts as unset.
AI_MODEL_PLAN=sonnet run plan 12
assert "$(model)" "sonnet" "AI_MODEL_PLAN beats the default"
AI_MODEL_ISSUE=haiku run issue
assert "$(model)" "haiku" "AI_MODEL_ISSUE beats the default"
AI_MODEL_IMPLEMENT=opus run implement p.md
assert "$(model)" "opus" "AI_MODEL_IMPLEMENT beats the default"
AI_MODEL_REVIEW=sonnet run review plan p.md
assert "$(model)" "sonnet" "AI_MODEL_REVIEW beats the default"
AI_MODEL_REVIEW=sonnet run --model haiku review code
assert "$(out)" $'--model\nhaiku\n/reviewing-in-rounds code' "--model beats AI_MODEL_REVIEW"
AI_MODEL_PLAN='' run plan 12
assert "$(model)" "opus" "an empty AI_MODEL_PLAN counts as unset"
AI_MODEL_ISSUE='' run issue
assert "$(model)" "sonnet" "an empty AI_MODEL_ISSUE counts as unset"
AI_MODEL_IMPLEMENT='' run implement p.md
assert "$(model)" "sonnet" "an empty AI_MODEL_IMPLEMENT counts as unset"
AI_MODEL_REVIEW='' run review code
assert "$(model)" "opus" "an empty AI_MODEL_REVIEW counts as unset"
run review code p.md
assert "$(prompt)" "/reviewing-in-rounds code p.md" "review code takes a plan file"

# Arguments are joined into one prompt argument, empty ones dropped, with no trailing space when none are left.
run issue
assert "$(prompt)" "/writing-issues" "no args give the bare skill"
run issue "login fails" on Safari
assert "$(out | wc -l | tr -d ' ')/$(prompt)" "3//writing-issues login fails on Safari" "args make one prompt argument"
run issue a "" b
assert "$(prompt)" "/writing-issues a b" "an empty arg in the middle is dropped"
run review "" code
assert "$(prompt)" "/reviewing-in-rounds code" "an empty arg is dropped before review's check"
run plan ""
assert "$(out)" $'--model\nopus\n/writing-plans' "an empty last arg leaves no trailing space"
run plan 12 --model x
assert "$(out)" $'--model\nopus\n/writing-plans 12 --model x' "--model after the stage is part of the prompt"

# Bad usage prints the usage and never runs claude.
function bad() {
  run "$@"
  assert "$rc/$(head -1 "$workdir/stderr")/$(out)" "2/$usage_line/" "ai ${*@Q} is bad usage"
}
bad
bad bogus
bad --model
bad --model haiku
bad --model a --model b plan
bad --model "" plan
bad review
bad review foo
bad review plan
bad review plan ""
bad implement
bad implement ""
bad "" plan 12

# A plan file that isn't a file is named, and claude never runs.
for words in "implement missing.md" "review plan missing.md" "review code missing.md" "implement ."; do
  read -r -a words <<< "$words"
  run "${words[@]}"
  assert "$rc/$(cat "$workdir/stderr")/$(out)" "2/ai: no such plan file: ${words[-1]}/" "ai ${words[*]} names the missing file"
done

# A plan file resolves against the repo root, not the cwd.
git init -q "$workdir/repo"
mkdir -p "$workdir/repo/d"
touch "$workdir/repo/plan-x.md"
(cd "$workdir/repo/d" && run implement plan-x.md && echo "$rc" > "$workdir/rc")
assert "$(cat "$workdir/rc")/$(prompt)" "0//implementing-plans plan-x.md" "a plan file resolves against the repo root"

# Inside a Claude session, even with CLAUDECODE empty, it refuses.
for value in 1 ""; do
  CLAUDECODE="$value" run plan 12
  assert "$rc/$(cat "$workdir/stderr")/$(out)" "2/ai: run this in a terminal, not inside Claude/" \
    "CLAUDECODE='$value' refuses"
done

# claude's exit status is ai's, and a missing claude is 127.
AI_CLAUDE="$workdir/stub3" run plan 12
assert "$rc" "3" "ai exits with claude's status"
AI_CLAUDE=/nonexistent run plan
assert "$rc" "127" "a missing AI_CLAUDE exits 127"
for value in unset empty; do
  rc=0
  if [[ "$value" == unset ]]; then
    (unset AI_CLAUDE; PATH="$workdir/empty" "$BASH" "$AI" plan) > /dev/null 2> "$workdir/stderr" || rc=$?
  else
    AI_CLAUDE='' PATH="$workdir/empty" "$BASH" "$AI" plan > /dev/null 2> "$workdir/stderr" || rc=$?
  fi
  assert "$rc/$(grep -c claude "$workdir/stderr")" "127/1" "no claude on PATH with AI_CLAUDE $value exits 127, naming claude"
done

# skill-trigger-eval copies the four defaults.
assert "$(grep -o 'AI_MODEL_[A-Z]*:-[a-z]*' "$AI" | sort -u)" \
  "$(grep -o 'AI_MODEL_[A-Z]*:-[a-z]*' "$REPO/bin/skill-trigger-eval" | sort -u)" \
  "bin/skill-trigger-eval has the same stage defaults"

# The docs ship with the script.
assert "$(grep -cw 'bin/ai' "$REPO/.github/workflows/shellcheck.yml")" "1" "bin/ai is in the ShellCheck list"
for name in ai claude-settings-merge skill-trigger-eval; do
  assert "$(sed -n '/^## Scripts/,/^## /p' "$REPO/README.md" | grep -c "^- \[$name\]")" "1" "README § Scripts lists $name"
done
assert "$(grep '^- \[24\.' "$REPO/tips.md" -A3 | grep -c "\`ai\`")" "1" "tips.md's 24 entry names ai"
assert "$(grep -cF 'export AI_MODEL_PLAN=' "$REPO/tips/24_claude_code.md")" "1" "the tip shows a per-shell override"
assert "$(grep -qF 'ai plan' "$REPO/tips/24_claude_code.md" && echo yes)" "yes" "the tip shows ai plan"

test_done
