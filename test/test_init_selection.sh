#!/usr/bin/env bash
# Resolve the checkout before sourcing the helper: bin/dotfiles sets DOTFILES to ~/.dotfiles when sourced,
# so afterwards this would test whatever tree lives there rather than the one this file was launched from.
checkout="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES="$checkout"
source "$DOTFILES/test/helper.sh"

e_header "$(basename "$0" .sh)"

# Runs the migration on the given selection and prints the result one entry per line, plus anything it wrote.
function migrate() {
  menu_selects=("$@")
  migrate_init_selection 2>&1
  printf '%s\n' "${menu_selects[@]}"
}

assert "$(migrate 10_a.sh 52_macos_claude.sh)" $'10_a.sh\n52_claude.sh' "old name is renamed"
assert "$(migrate 52_macos_claude.sh 52_claude.sh)" "52_claude.sh" "old name before the new one: one entry"
assert "$(migrate 52_claude.sh 52_macos_claude.sh)" "52_claude.sh" "new name before the old one: one entry"
assert "$(migrate 52_claude.sh)" "52_claude.sh" "new name alone is unchanged"
assert "$(migrate 52_macos_claude.sh 10_a.sh 60_b.sh)" $'52_claude.sh\n10_a.sh\n60_b.sh' "order is kept"
assert "$(migrate 10_a.sh 60_b.sh)" $'10_a.sh\n60_b.sh' "a selection with no renamed script is unchanged"
assert "$(migrate 52_macos_claude.sh 10_a.sh 52_macos_claude.sh)" $'52_claude.sh\n10_a.sh' "old name twice: one entry"
assert "$(migrate 52_macos_claude.sh.bak 52_macos_claude)" $'52_macos_claude.sh.bak\n52_macos_claude' "near-miss names are untouched"

# An empty selection stays empty and says nothing, so the helper's wrapped e_error is not hit either.
menu_selects=()
out="$(migrate_init_selection 2>&1)"
assert "$out" "" "empty selection prints nothing"
assert "${#menu_selects[@]}" "0" "empty selection stays empty"

# The init script exists under its new name only, 
assert "$([[ -f "$DOTFILES/init/52_claude.sh" && ! -e "$DOTFILES/init/52_macos_claude.sh" ]] && echo yes)" "yes" "init script is renamed"

test_done
