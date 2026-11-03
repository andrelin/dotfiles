#!/usr/bin/env bash

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "Unknown model"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
# The /rename or --name name if set, else the AI-generated session title; absent before either exists.
topic=$(echo "$input" | jq -r '.session_name // empty')
ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
session_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_hour_resets_at=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# ANSI colour codes — yellow at 75 %+, red at 90 %+.
YELLOW=$'\033[33m'
RED=$'\033[31m'
BLUE=$'\033[34m'
GREEN=$'\033[32m'
CYAN=$'\033[36m'
RESET=$'\033[0m'
BOLD=$'\033[1m'
BOLD_OFF=$'\033[22m'

# Build a compact progress bar: ████░░░░ nn%
make_bar() {
  local pct="$1"
  local width="${2:-10}"
  local filled=$(( pct * width / 100 ))
  local empty=$(( width - filled ))
  local bar=""
  [ "$filled" -gt 0 ] && bar=$(printf '%0.s█' $(seq 1 "$filled"))
  [ "$empty"  -gt 0 ] && bar="${bar}$(printf '%0.s░' $(seq 1 "$empty"))"
  printf "%s" "$bar"
}

# Columns a string takes on screen: colour codes take none, and only a UTF-8 character's lead byte counts.
visible_width() {
  printf '%s' "$1" | sed $'s/\033\\[[0-9;]*m//g' | LC_ALL=C tr -d '\200-\277' | wc -c | tr -d ' '
}

# Wrap a segment in colour based on its percentage.
colourise() {
  local pct="$1"
  local segment="$2"
  if [ "$pct" -ge 90 ] 2>/dev/null; then
    printf '%s%s%s' "$RED" "$segment" "$RESET"
  elif [ "$pct" -ge 75 ] 2>/dev/null; then
    printf '%s%s%s' "$YELLOW" "$segment" "$RESET"
  else
    printf '%s' "$segment"
  fi
}

# Path and branch, matching the zsh prompt in link/.omz-custom/andrelin.zsh-theme:
# a blue %~-style path, then the branch in green with a red * when the tree is dirty.
prompt_dir=""
git_segment=""
if [ -n "$cwd" ]; then
  case "$cwd" in
    "$HOME")   prompt_dir="~" ;;
    "$HOME"/*) prompt_dir="~${cwd#"$HOME"}" ;;
    *)         prompt_dir="$cwd" ;;
  esac

  # Detached HEAD falls back to the short SHA, the same as the theme's git_prompt_info.
  branch=$(git -C "$cwd" symbolic-ref --quiet --short HEAD 2>/dev/null \
    || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)

  if [ -n "$branch" ]; then
    dirty=""
    if [ -n "$(git -C "$cwd" status --porcelain --ignore-submodules=dirty 2>/dev/null | head -n 1)" ]; then
      dirty=" ${RED}*${GREEN}"
    fi
    git_segment="${GREEN}[${branch}${dirty}]${RESET}"
  fi
fi

# The rows above the bars hold three sections, in order: the path, the info (branch and model), and the topic.
# They share a row while it fits the terminal, and the next one starts a new row when it wouldn't:
# Claude Code sets COLUMNS for this script, and without a usable width everything stays on one row.
# The model wears the theme's cyan-parenthesis idiom, the one its kube and
# virtualenv segments use for "what this shell is currently pointed at".
info_segment="${CYAN}(${model})${RESET}"
[ -n "$git_segment" ] && info_segment="${git_segment} ${info_segment}"

# The topic, in bold, tells several open sessions apart at a glance; long titles are cut at 50 characters.
topic_segment=""
if [ -n "$topic" ]; then
  [ "${#topic}" -gt 50 ] && topic="${topic:0:49}…"
  topic_segment="${BOLD}${topic}${BOLD_OFF}"
fi

# Claude Code pads the status line and cuts a row with … a few columns short of COLUMNS;
# measured in iTerm2, 4 columns is enough that a section drops before it is cut.
columns="${COLUMNS:-0}"
if [ "$columns" -gt 4 ] 2>/dev/null; then
  columns=$(( columns - 4 ))
else
  columns=0
fi
info_rows=""
row=""
row_width=0

# Appends a section to the current row after the separator, or starts a new row with it when it wouldn't fit.
place() {
  local separator="$1" segment="$2" width
  width=$(visible_width "$segment")
  if [ -z "$row" ]; then
    row="$segment"
    row_width=$width
  elif [ "$columns" -gt 0 ] && [ $(( row_width + $(visible_width "$separator") + width )) -gt "$columns" ]; then
    info_rows="${info_rows}${row}"$'\n'
    row="$segment"
    row_width=$width
  else
    row="${row}${separator}${segment}"
    row_width=$(( row_width + $(visible_width "$separator") + width ))
  fi
}

[ -n "$prompt_dir" ] && place " " "${BLUE}${prompt_dir}${RESET}"
place " " "$info_segment"
[ -n "$topic_segment" ] && place " · " "$topic_segment"
info_rows="${info_rows}${row}"
row2=""

# Context window bar
if [ -n "$ctx_pct" ]; then
  ctx_int=$(echo "$ctx_pct" | awk '{printf "%d", $1}')
  bar=$(make_bar "$ctx_int" 20)
  segment="ctx ${bar} ${BOLD}${ctx_int}%${BOLD_OFF}"
  row2="$(colourise "$ctx_int" "$segment")"
fi

# 5-hour session usage bar (only shown once the API has returned rate-limit data)
if [ -n "$session_pct" ]; then
  sess_int=$(echo "$session_pct" | awk '{printf "%d", $1}')
  bar=$(make_bar "$sess_int")
  reset_suffix=""
  if [ -n "$five_hour_resets_at" ]; then
    reset_time=$(date -r "$five_hour_resets_at" "+%H:%M" 2>/dev/null \
      || date -d "@$five_hour_resets_at" "+%H:%M" 2>/dev/null)
    [ -n "$reset_time" ] && reset_suffix="  🔄 ${reset_time}"
  fi
  segment="5h ${bar} ${BOLD}${sess_int}%${BOLD_OFF}${reset_suffix}"
  [ -n "$row2" ] && row2="${row2} | "
  row2="${row2}$(colourise "$sess_int" "$segment")"
fi

# 7-day limit bar (shown alongside 5h bar when available)
if [ -n "$week_pct" ]; then
  week_int=$(echo "$week_pct" | awk '{printf "%d", $1}')
  bar=$(make_bar "$week_int")
  segment="7d ${bar} ${BOLD}${week_int}%${BOLD_OFF}"
  [ -n "$row2" ] && row2="${row2} | "
  row2="${row2}$(colourise "$week_int" "$segment")"
fi

if [ -n "$row2" ]; then
  printf "%s\n%s" "$info_rows" "$row2"
else
  printf "%s" "$info_rows"
fi
