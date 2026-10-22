#!/bin/bash
# PostToolUse hook: after a Bash call that pushes to a default branch or merges a PR, tells Claude to watch that
# branch's CI to green and to fix a failure at once. A red main branch is never okay unless the user says it is;
# the rule only matters at this moment, so it lives here rather than in CLAUDE.md.
#
# A reminder, not a guard: a false positive costs a line of context and a miss leaves main red, so it errs towards
# firing. Must stay bash 3.2-compatible, like work-context.sh.
#
# Usage: watch-main-ci.sh < hook-input-json

LC_ALL=C
GIT=${WATCH_MAIN_CI_GIT:-git}

input=$(cat)
if type -P jq >/dev/null; then
  cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
  dir=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
else
  # The raw JSON still holds the command's words; only its escaping differs.
  cmd=$input
  dir=""
fi
[[ -n $cmd ]] || exit 0
dir=${dir:-$PWD}

# Separators become their own words, so a segment's first word is the command it runs. Quotes are dropped, which
# can split a quoted argument but never joins two words.
cmd=${cmd//\\$'\n'/ }
for sep in '&&' '||' ';' '|' '&' $'\n' '(' ')'; do cmd=${cmd//"$sep"/ ; }; done
cmd=${cmd//\"/}
cmd=${cmd//\'/}
set -f
# shellcheck disable=SC2206 # word splitting is the point; globbing is off
words=($cmd)
set +f
n=${#words[@]}

pushed=""
merged=0

abs() {
  case $2 in
    /*) printf '%s' "$2" ;;
    \~) printf '%s' "$HOME" ;;
    \~/*) printf '%s' "$HOME/${2#\~/}" ;;
    *) printf '%s' "$1/$2" ;;
  esac
}

# is_default <git-dir> <branch>: main, master, or whatever origin/HEAD names.
is_default() {
  [[ $2 == main || $2 == master ]] && return 0
  local head
  head=$("$GIT" -C "$1" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null) || return 1
  [[ $2 == "${head#origin/}" ]]
}

# check_push <git-dir> <first-arg-index>: sets pushed to the default branch the push reaches, if any.
check_push() {
  local gdir=$1 j=$2 w ref positional=0 refspecs=0 dry=0 all=0 upstream
  while (( j < n )); do
    w=${words[j]}
    case $w in
      ";") break ;;
      -n|--dry-run) dry=1 ;;
      --all|--mirror|--branches) all=1 ;;
      -o|--push-option|--receive-pack|--exec|--repo) (( j++ )) ;;
      -*|*">"*|"<"*) ;;
      *)
        (( positional++ ))
        if (( positional > 1 )); then
          (( refspecs++ ))
          ref=${w#+}
          ref=${ref##*:}
          ref=${ref#refs/heads/}
          if is_default "$gdir" "$ref"; then pushed=$ref; fi
        fi
        ;;
    esac
    (( j++ ))
  done
  (( dry )) && { pushed=""; return; }
  if (( all )); then pushed=${pushed:-main}; return; fi
  (( refspecs )) && return
  # No refspec: the push goes wherever @{push} points, which for a branch made from origin/main can be main.
  upstream=$("$GIT" -C "$gdir" rev-parse --abbrev-ref '@{push}' 2>/dev/null) || return
  upstream=${upstream#*/}
  if is_default "$gdir" "$upstream"; then pushed=$upstream; fi
}

check_git() {
  local j=$(( $1 + 1 )) gdir=$dir w
  while (( j < n )); do
    w=${words[j]}
    case $w in
      -C) (( j++ )); gdir=$(abs "$dir" "${words[j]}") ;;
      -c) (( j++ )) ;;
      -*) ;;
      push) check_push "$gdir" $(( j + 1 )); return ;;
      *) return ;;
    esac
    (( j++ ))
  done
}

start=1
i=0
while (( i < n )); do
  w=${words[i]}
  if [[ $w == ";" ]]; then
    start=1
  elif (( start )); then
    case $w in
      *=*|command|env|sudo|time) ;;
      cd) (( i++ )); dir=$(abs "$dir" "${words[i]}"); start=0 ;;
      git) check_git "$i"; start=0 ;;
      gh|glab)
        [[ ${words[i+1]} == pr || ${words[i+1]} == mr ]] && [[ ${words[i+2]} == merge ]] && merged=1
        start=0
        ;;
      *) start=0 ;;
    esac
  fi
  (( i++ ))
done

rule="and fix a failure at once, even one this change didn't cause: a red main branch is never okay unless the user says it is."
if [[ -n $pushed ]]; then
  pushed=${pushed//[\"\\]/}
  msg="This pushed to \`$pushed\`, a default branch. Watch its CI until every run on the new commit is green, $rule"
elif (( merged )); then
  msg="This merged a PR, or queued it with --auto. Once it lands, watch the base branch's CI until every run on the merge commit is green, $rule"
else
  exit 0
fi
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$msg"
