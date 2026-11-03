#!/usr/bin/env bash
source "$DOTFILES/test/helper.sh"

e_header "$(basename "$0" .sh)"

statusline="$DOTFILES/claude/statusline-command.sh"
# Outside any git repo, so row 1 carries no branch segment.
cwd=$(mktemp -d)
trap 'rm -rf "$cwd"' EXIT

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
# Claude Code cuts the status line this many columns short of COLUMNS.
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

out=$(render 500 "")
assert "$out" "$row1" "no topic leaves path and info alone"

out=$(render 20 "Fix the ÆØÅ bug" '{context_window: {used_percentage: 12}}')
assert "$(line_count "$out")" "4" "dropped sections add rows above the bars"
assert "$(sed -n 4p <<< "$out" | cut -c1-3)" "ctx" "bars stay on the last row"

out=$(render 500 "$(printf 'x%.0s' {1..60})")
assert "$out" "$row1 · $(printf 'x%.0s' {1..49})…" "long topics are cut at 50 characters"

# The branch belongs to the info section, so it drops together with the model.
git -C "$cwd" -c init.defaultBranch=main init -q
out=$(render 20 "")
assert "$out" "$cwd"$'\n'"[main] (Opus)" "branch and model drop together"

test_done
