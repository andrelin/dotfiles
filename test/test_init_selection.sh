#!/usr/bin/env bash
# Resolve the checkout before sourcing the helper: bin/dotfiles sets DOTFILES to ~/.dotfiles when sourced,
# so afterwards this would test whatever tree lives there rather than the one this file was launched from.
checkout="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES="$checkout"
source "$DOTFILES/test/helper.sh"

e_header "$(basename "$0" .sh)"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
out_file="$tmp/out"
cache="$tmp/selected"

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
# Run in this shell, not a command substitution, so the count reads what the function left behind.
menu_selects=()
migrate_init_selection > "$out_file" 2>&1
assert "$(cat "$out_file")" "" "empty selection prints nothing"
assert "${#menu_selects[@]}" "0" "empty selection stays empty"

# A chain of renames is followed to the latest name, whichever order the entries are in.
renamed_init_scripts=(a.sh:b.sh b.sh:c.sh)
assert "$(migrate a.sh)" "c.sh" "a chain of renames reaches the latest name"
renamed_init_scripts=(b.sh:c.sh a.sh:b.sh)
assert "$(migrate a.sh 10_x.sh c.sh)" $'c.sh\n10_x.sh' "a chain listed in reverse, the latest name already ticked: one entry"
renamed_init_scripts=(52_macos_claude.sh:52_claude.sh)

# init_files itself, lifted out of bin/dotfiles past the source-mode return, with the menu stubbed:
# a cache naming the old script comes back with the new one ticked, and is rewritten that way.
eval "$(sed -n '/^function init_files() {$/,/^}$/p' "$DOTFILES/bin/dotfiles")"
function prompt_menu() { :; }
init_file="$cache"
printf '10_a.sh\n52_macos_claude.sh\n' > "$init_file"
got="$(init_files /x/init/10_a.sh /x/init/52_claude.sh /x/init/60_b.sh)"
assert "$got" $'/x/init/10_a.sh\n/x/init/52_claude.sh' "init_files: a cached old name runs the renamed script"
assert "$(cat "$init_file")" $'10_a.sh\n52_claude.sh' "init_files: the cache is rewritten with the new name"

# With no cache, the defaults: on Linux the renamed script is ticked and a macOS one isn't.
rm -f "$init_file"
function get_os() { echo macos; }
# The Claude script's name comes from init/, so renaming it back to a macOS-marked name fails this.
claude_script="$(basename "$(ls "$DOTFILES"/init/52_*claude*.sh)")"
got="$(init_files /x/init/10_a.sh /x/init/50_macos_x.sh "/x/init/$claude_script")"
assert "$got" $'/x/init/10_a.sh\n'"/x/init/$claude_script" "init_files with no cache: the Claude script, as named in init/, ticked on Linux"

# The function is sourced into every interactive zsh as well.
if command -v zsh >/dev/null; then
  got="$(DOTFILES="$DOTFILES" zsh -f -c 'source "$DOTFILES/bin/dotfiles" source
    menu_selects=(52_macos_claude.sh 10_a.sh 52_claude.sh)
    migrate_init_selection
    print -l -- "${menu_selects[@]}"' 2>&1)"
  assert "$got" $'52_claude.sh\n10_a.sh' "zsh: old name renamed, the new one not selected twice"
  got="$(DOTFILES="$DOTFILES" zsh -f -c 'source "$DOTFILES/bin/dotfiles" source
    renamed_init_scripts=(b.sh:c.sh a.sh:b.sh)
    menu_selects=(a.sh 10_x.sh c.sh)
    migrate_init_selection
    print -l -- "${menu_selects[@]}"' 2>&1)"
  assert "$got" $'c.sh\n10_x.sh' "zsh: a chain listed in reverse reaches the latest name, selected once"
fi

# The init script exists under its new name only.
assert "$([[ -f "$DOTFILES/init/52_claude.sh" && ! -e "$DOTFILES/init/52_macos_claude.sh" ]] && echo yes)" "yes" "init script is renamed"

test_done
