#!/bin/bash
# Command shim for git, gh, glab and az, linked under each name in ~/.claude/shims, which the guard's session-start
# puts first on PATH inside Claude Code only, through CLAUDE_ENV_FILE. The PreToolUse guard sees only the literal
# command, so a shell alias, function or script that pushes slips past it; the shim sees the real argv and asks the
# same guard, `check-argv`.
#
# Must stay bash 3.2-compatible: Claude Code's Bash tool may run it under macOS's /bin/bash. Builtins only, so it
# works under a PATH that holds nothing but itself and the real tool.

tool=${0##*/}
src=${BASH_SOURCE[0]}
case $src in
  */*) src_dir=${src%/*} ;;
  *) src_dir=. ;;
esac
# Physical, so a PATH entry spelt through the ~/.claude/shims symlink still matches.
shim_dir=$(cd -P -- "$src_dir" && pwd -P) || { echo "$tool: shim can't find its own directory" >&2; exit 2; }
guard=$shim_dir/../hooks/work-context.sh

# PATH without any entry that is the shim dir, however it is spelt; one subshell for the whole walk.
real_path=$(
  out=""
  IFS=:
  set -f
  start=$PWD
  for e in $PATH; do
    # Each cd moves this subshell, so a relative entry resolves against where the shim started. An if, not a case:
    # bash 3.2 can't parse a case pattern's `)` inside $( ).
    p=$e
    [[ $e == /* ]] || p=$start/${e:-.}
    if cd -P -- "$p" 2>/dev/null && [[ $PWD == "$shim_dir" ]]; then continue; fi
    out=${out:+$out:}$e
  done
  printf '%s' "$out"
)

# find_in <name>: the first executable <name> on real_path, in REPLY.
find_in() {
  local e IFS=:
  REPLY=""
  set -f
  for e in $real_path; do
    if [[ -f ${e:-.}/$1 && -x ${e:-.}/$1 ]]; then REPLY=${e:-.}/$1; break; fi
  done
  set +f
}

find_in "$tool"
real=$REPLY
if [[ -z $real ]]; then
  echo "$tool: not found" >&2
  exit 127
fi

# The user's own waiver, set per command with `! WORK_CONTEXT_WAIVE=1 …`; the guard blocks Claude from setting it.
# The shim dir leaves PATH too, so a waived gh's own git push reaches real git, and the waiver reaches nothing else.
if [[ ${WORK_CONTEXT_WAIVE-} == 1 ]]; then
  unset WORK_CONTEXT_WAIVE
  PATH=$real_path
  exec "$real" "$@"
fi

if [[ $tool == git ]]; then
  real_git=$real
else
  find_in git
  real_git=$REPLY
fi

# The guard runs with the shim off its PATH, so its own git calls can never recurse through here.
PATH=$real_path WORK_CONTEXT_GIT=${WORK_CONTEXT_GIT:-${real_git:-git}} \
  /bin/bash "$guard" check-argv "$PWD" "$tool" "$@"
rc=$?
case $rc in
  0) exec "$real" "$@" ;;
  2) exit 2 ;;
  *)
    echo "work-context guard failed (exit $rc); blocking to stay safe" >&2
    exit 2
    ;;
esac
