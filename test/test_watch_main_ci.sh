#!/usr/bin/env bash
# Resolve the hook before sourcing the helper: bin/dotfiles exports
# DOTFILES=~/.dotfiles when sourced, so afterwards this would test whatever tree
# lives there rather than the one this file was launched from.
SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)/claude/hooks/watch-main-ci.sh"
readonly SCRIPT

source "$DOTFILES/test/helper.sh"

if [[ ! -x "$SCRIPT" ]]; then
  echo "ERROR: $SCRIPT is missing or not executable" >&2
  exit 1
fi
if [[ ! "$(type -P jq)" ]]; then
  echo "ERROR: jq is required to build the hook input" >&2
  exit 1
fi

e_header "$(basename "$0" .sh)"

root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT
export HOME="$root"
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1

# A repo with main and feature both on a bare origin and tracked. The commit lands before origin is added and origin
# fetches it, so a session's work-context shim, which counts a local-path origin as customer work, allows each step.
R="$root/repo"
git init -q -b main "$R"
git -C "$R" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
git -C "$R" branch feature
git init -q --bare -b main "$root/origin.git"
git -C "$root/origin.git" fetch -q "$R" main:main feature:feature
git -C "$R" remote add origin "$root/origin.git"
git -C "$R" fetch -q origin
git -C "$R" branch -q -u origin/main main
git -C "$R" branch -q -u origin/feature feature
git -C "$R" switch -q feature

# reminder <cwd> <command>: the additionalContext the hook gives, or nothing.
function reminder() {
  jq -n --arg c "$2" --arg d "$1" '{tool_name: "Bash", tool_input: {command: $c}, cwd: $d}' |
    /bin/bash "$SCRIPT" | jq -r '.hookSpecificOutput.additionalContext // empty'
}

# fires <cwd> <command> <expected: push|merge|none>
function fires() {
  local out got=none
  out="$(reminder "$1" "$2")"
  [[ $out == "This pushed to"* ]] && got=push
  [[ $out == "This merged"* ]] && got=merge
  assert "$got" "$3" "$2"
}

e_header "explicit refspecs"
fires "$R" "git push origin main" push
fires "$R" "git push origin master" push
fires "$R" "git push origin +main" push
fires "$R" "git push -u origin HEAD:refs/heads/main" push
fires "$R" "git push origin feature:main" push
fires "$R" "git push -u origin HEAD:refs/heads/feature" none
fires "$R" "git push -u origin HEAD:refs/heads/fix-main" none
fires "$R" "git push origin main-fix" none
fires "$R" "git push --all origin" push
fires "$R" "git push --dry-run origin main" none
fires "$R" "git push -n origin main" none
fires "$R" "git push -o ci.skip origin feature" none

e_header "the branch origin/HEAD names is a default branch too"
git -C "$R" remote set-head origin feature
fires "$R" "git push origin feature" push
git -C "$R" remote set-head origin main
fires "$R" "git push origin feature" none

e_header "no refspec: wherever @{push} points"
fires "$R" "git push" none
git -C "$R" switch -q main
fires "$R" "git push" push
fires "$root" "git push" none
fires "$root" "git -C $R push" push
fires "$root" "git -C repo push" push
fires "$root" "cd $R && git push" push
fires "$root" "cd repo && git push" push
# The 2026-10-01 incident: a branch made from origin/main tracks main, and push.default=upstream sends it there.
git -C "$R" switch -q -c tracks-main origin/main 2>/dev/null
git -C "$R" config push.default upstream
fires "$R" "git push" push
git -C "$R" config push.default simple
git -C "$R" switch -q feature

e_header "compound commands"
fires "$R" "git push origin feature && git push origin main" push
fires "$R" "git status; git push origin main 2>&1 | tail -3" push
fires "$R" "GIT_TRACE=0 git push origin main" push
fires "$R" "echo git push origin main" none
fires "$R" "git log --grep push main" none

e_header "merges"
fires "$R" "gh pr merge 83 --squash --delete-branch" merge
fires "$R" "gh pr merge --auto --squash" merge
fires "$R" "glab mr merge 12" merge
fires "$R" "gh pr view 83" none
fires "$R" "gh pr checks 83 --watch && gh pr merge 83 --squash" merge

e_header "input"
assert "$(printf '%s' '{"tool_name":"Bash","tool_input":{}}' | /bin/bash "$SCRIPT")" "" "no command, no output"
out="$(jq -n --arg d "$R" '{tool_input: {command: "git push origin main"}, cwd: $d}' | /bin/bash "$SCRIPT")"
assert "$(jq -r '.hookSpecificOutput.hookEventName' <<<"$out")" "PostToolUse" "the output is PostToolUse JSON"

test_done
