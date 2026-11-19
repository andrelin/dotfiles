#!/usr/bin/env bash
source "$DOTFILES/test/helper.sh"

e_header "$(basename "$0" .sh)"

# The cases build their input with jq, and the status line reads it with jq.
if [[ ! "$(type -P jq)" ]]; then
  echo "ERROR: jq is required to build the status line input" >&2
  exit 1
fi

statusline="$DOTFILES/claude/statusline-command.sh"
# Not a git repo until the last case, so the info section is the model alone.
cwd=$(mktemp -d)
cache=$(mktemp -d)
trap 'rm -rf "$cwd" "$cache"' EXIT

# Runs the status line on a session with the given topic, plus any extra JSON fields, at the given COLUMNS
# ("unset" leaves it out of the environment), and prints its output with the colour codes removed.
function render() {
  local columns="$1" topic="$2" extra="${3:-}"
  local input
  input=$(jq -nc --arg cwd "$cwd" --arg topic "$topic" \
    '{cwd: $cwd, model: {display_name: "Opus"}} + (if $topic == "" then {} else {session_name: $topic} end)')
  [ -n "$extra" ] && input=$(jq -c ". + $extra" <<< "$input")
  if [ "$columns" = unset ]; then
    env -u COLUMNS bash "$statusline" <<< "$input"
  else
    COLUMNS="$columns" bash "$statusline" <<< "$input"
  fi | sed $'s/\033\\[[0-9;]*m//g'
}

function line_count() {
  local output="$1"
  printf '%s\n' "$output" | wc -l | tr -d ' '
}

row1="$cwd (Opus)"
# Claude Code cuts the status line this many columns short of COLUMNS, the 4 the script subtracts.
padding=4
one_line="$row1 · Fix the ÆØÅ bug"

out=$(render 500 "Fix the ÆØÅ bug")
assert "$out" "$one_line" "path, info and topic share one row when they fit"

out=$(render $(( ${#row1} + padding )) "Fix the ÆØÅ bug")
assert "$out" "$row1"$'\n'"Fix the ÆØÅ bug" "topic drops to its own row when only path and info fit"

out=$(render $(( ${#row1} + padding - 1 )) "Fix the ÆØÅ bug")
assert "$out" "$cwd"$'\n'"(Opus) · Fix the ÆØÅ bug" "info drops and the topic follows it when it fits"

out=$(render 20 "Fix the ÆØÅ bug")
assert "$out" "$cwd"$'\n'"(Opus)"$'\n'"Fix the ÆØÅ bug" "each section gets its own row when none fit together"

# The boundary counts characters, not bytes: ÆØÅ is six bytes but three columns.
width=$(( ${#row1} + 18 + padding )) # " · Fix the ÆØÅ bug"
out=$(render "$width" "Fix the ÆØÅ bug")
assert "$out" "$one_line" "topic stays on the row at an exact fit"
out=$(render $(( width - 1 )) "Fix the ÆØÅ bug")
assert "$(line_count "$out")" "2" "topic drops one column short of a fit"

out=$(render unset "Fix the ÆØÅ bug")
assert "$out" "$one_line" "everything stays on one row without COLUMNS"
out=$(render 0 "Fix the ÆØÅ bug")
assert "$out" "$one_line" "everything stays on one row when COLUMNS is 0"
out=$(render abc "Fix the ÆØÅ bug")
assert "$out" "$one_line" "everything stays on one row when COLUMNS is not a number"
# A leading zero must not read as octal, where 010 would be 8.
out=$(render "0$(( ${#row1} + padding ))" "Fix the ÆØÅ bug")
assert "$out" "$row1"$'\n'"Fix the ÆØÅ bug" "a zero-padded COLUMNS counts in decimal"

out=$(render 500 "")
assert "$out" "$row1" "no topic leaves path and info alone"

out=$(render 20 "Fix the ÆØÅ bug" '{context_window: {used_percentage: 12}}')
assert "$(line_count "$out")" "4" "dropped sections add rows above the bars"
assert "$(sed -n 4p <<< "$out" | cut -c1-3)" "ctx" "bars stay on the last row"

out=$(render 500 "$(printf 'x%.0s' {1..60})")
assert "$out" "$row1 · $(printf 'x%.0s' {1..49})…" "long topics are cut at 50 characters"
out=$(LC_ALL=C render 500 "$(printf 'Æ%.0s' {1..60})")
assert "$out" "$row1 · $(printf 'Æ%.0s' {1..49})…" "long topics are cut at 50 characters, not bytes, in the C locale"
out=$(render 500 "Fix"$'\e'"[2J"$'\n'"bug")
assert "$out" "$row1 · Fix[2Jbug" "control characters are dropped from the topic"

# Credits: the cost since a window was first seen spent, kept per session under XDG_CACHE_HOME.
export XDG_CACHE_HOME="$cache"
spent='{session_id: "s1", cost: {total_cost_usd: 4.5}, rate_limits: {five_hour: {used_percentage: 40}, seven_day: {used_percentage: 100}}}'
out=$(render 500 "" "$spent")
assert "$(sed -n 2p <<< "$out")" "5h ████░░░░░░ 40% | 7d ██████████ 100% | credits ≈ \$0.00" "a spent week starts credits at zero"
spent='{session_id: "s1", cost: {total_cost_usd: 5.75}, rate_limits: {five_hour: {used_percentage: 40}, seven_day: {used_percentage: 100}}}'
out=$(render 500 "" "$spent")
assert "$(sed -n 2p <<< "$out" | sed 's/.*| //')" "credits ≈ \$1.25" "credits count only the cost since the limit was spent"
out=$(render 500 "" '{session_id: "s1", cost: {total_cost_usd: 6}, rate_limits: {five_hour: {used_percentage: 100}}}')
assert "$(sed -n 2p <<< "$out" | sed 's/.*| //')" "credits ≈ \$1.50" "a spent 5-hour window counts too"
out=$(render 500 "" '{session_id: "s1", cost: {total_cost_usd: 7}, rate_limits: {five_hour: {used_percentage: 3}}}')
assert "$(sed -n 2p <<< "$out")" "5h ░░░░░░░░░░ 3%" "no credits once no window is spent"
out=$(render 500 "" '{session_id: "s1", cost: {total_cost_usd: 8}, rate_limits: {seven_day: {used_percentage: 100}}}')
assert "$(sed -n 2p <<< "$out" | sed 's/.*| //')" "credits ≈ \$0.00" "a new spell of spent limits starts from zero again"
out=$(render 500 "" '{session_id: "s2", cost: {total_cost_usd: 2}, rate_limits: {seven_day: {used_percentage: 99.9}}}')
assert "$(sed -n 2p <<< "$out")" "7d █████████░ 99%" "under 100 % is not spent"
unset XDG_CACHE_HOME

# The branch belongs to the info section, so it drops together with the model.
git -C "$cwd" -c init.defaultBranch=main init -q
out=$(render 20 "")
assert "$out" "$cwd"$'\n'"[main] (Opus)" "branch and model drop together"

test_done
