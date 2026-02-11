#!/usr/bin/env bash
# Shared test infrastructure. Source this instead of source/01_dotfiles.sh.
# Wraps e_error to count failures and provides test_done for exit codes.

source "$DOTFILES/source/01_dotfiles.sh"

__test_failures=0

# Wrap e_error so that every assertion failure increments the counter.
eval "$(declare -f e_error | sed '1s/e_error/_original_e_error/')"
function e_error() {
  ((__test_failures++))
  _original_e_error "$@"
}

# Call at the end of every test script. Exits non-zero if any assertions failed.
function test_done() {
  if (( __test_failures > 0 )); then
    echo "$__test_failures test failure(s)" >&2
    exit 1
  fi
  exit 0
}
