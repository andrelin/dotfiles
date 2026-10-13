#!/usr/bin/env bash
source "$DOTFILES/test/helper.sh"

e_header "$(basename "$0" .sh)"

# source/12_ruby.sh puts Homebrew Ruby and its gem executables on PATH from directory names alone, without running
# brew or gem. Run in both shells: under zsh an unmatched glob is an error by default that aborts the whole file.

tmp="$(mktemp -d)"

# Prints the PATH entries the file added in front of /usr/bin, then "done" if it ran to the end, plus any errors.
ruby_path() {
  local shell="$1" prefix="$2"
  # shellcheck disable=SC2016 # Expanded by the inner shell
  "$shell" -c 'HOMEBREW_PREFIX="$1"; PATH=/usr/bin; source "$DOTFILES/source/12_ruby.sh"
    echo "${PATH%%/usr/bin}" | sed "s|$1/||g"; echo done' _ "$prefix" 2>&1 | tr '\n' ' '
}

mkdir -p "$tmp/gems/opt/ruby/bin" "$tmp/gems/lib/ruby/gems/3.4.0" "$tmp/gems/lib/ruby/gems/4.0.0"
mkdir -p "$tmp/nogems/opt/ruby/bin"
mkdir -p "$tmp/noruby"

shells=(bash)
if command -v zsh > /dev/null; then
  shells+=(zsh)
else
  e_error "zsh not found: CI installs it, so the zsh half of this test can't be skipped."
fi

for shell in "${shells[@]}"; do
  assert "$(ruby_path "$shell" "$tmp/gems")" "lib/ruby/gems/4.0.0/bin:opt/ruby/bin: done " \
    "$shell: Ruby and the newest gem dir"
  assert "$(ruby_path "$shell" "$tmp/nogems")" "opt/ruby/bin: done " "$shell: no gem dir yet, file still finishes"
  assert "$(ruby_path "$shell" "$tmp/noruby")" " done " "$shell: no Ruby, PATH untouched"
done

rm -rf "$tmp"

test_done
