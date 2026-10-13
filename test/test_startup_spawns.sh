#!/usr/bin/env bash
source "$DOTFILES/test/helper.sh"

e_header "$(basename "$0" .sh)"

# Shell startup must not run brew, gem or kubectl: each costs 25-70 ms on every new shell. The rc files are wrapped
# by ones that first define logging functions with those names, which win over any PATH lookup. brew shellenv by its
# absolute path is the one expected call, and a function can't intercept that.
# The shells run in a temp HOME whose .dotfiles is this checkout, so they test it and not the installed one, and
# whatever they write (omz's completion cache, fnm state) lands in the temp dir instead of the real home.

tmp="$(mktemp -d)"
home="$tmp/home"
log="$tmp/calls"
mkdir -p "$home"
ln -s "$DOTFILES" "$home/.dotfiles"
ln -s "$DOTFILES/link/.omz-custom" "$home/.omz-custom"
[[ -d "$HOME/.oh-my-zsh" ]] && ln -s "$HOME/.oh-my-zsh" "$home/.oh-my-zsh"
touch "$log"

# The omz kubectl and docker plugins generate completions with `<tool> completion zsh` in the background, which
# costs startup nothing; zsh's $funcfiletrace lets exactly those calls through.
stubs="
brew() { echo \"brew \$*\" >> '$log'; }
gem() { echo \"gem \$*\" >> '$log'; }
kubectl() {
  [[ -n \"\$ZSH_VERSION\" && \"\$1\" == completion && \"\${funcfiletrace[1]}\" == */plugins/kubectl/* ]] && return
  echo \"kubectl \$*\" >> '$log'
}
"
# Startup reached the end when functions from the last sourced files exist.
reached_end="type tips > /dev/null 2>&1 && type jdk > /dev/null 2>&1 && echo complete > '$tmp/end'"

in_temp_home() {
  env HOME="$home" ZSH_CACHE_DIR="$tmp/cache" XDG_STATE_HOME="$tmp/state" "$@" > /dev/null 2>&1 < /dev/null
}

if command -v zsh > /dev/null && [[ -d "$HOME/.oh-my-zsh" ]]; then
  printf '%s\nsource "$HOME/.dotfiles/link/.zshrc"\n%s\n' "$stubs" "$reached_end" > "$home/.zshrc"
  rm -f "$tmp/end"
  in_temp_home zsh -i -c exit
  assert "$(cat "$tmp/end" 2> /dev/null)" "complete" "zsh startup runs to the end"
  assert "$(cat "$log")" "" "zsh startup runs no brew, gem or kubectl"
else
  e_error "zsh or oh-my-zsh not found: CI installs both, so the zsh half can't be skipped."
fi

: > "$log"
printf '%s\nsource "$HOME/.dotfiles/link/.bashrc"\n%s\n' "$stubs" "$reached_end" > "$home/.bashrc"
rm -f "$tmp/end"
in_temp_home bash --rcfile "$home/.bashrc" -i -c exit
assert "$(cat "$tmp/end" 2> /dev/null)" "complete" "bash startup runs to the end"
assert "$(cat "$log")" "" "bash startup runs no brew, gem or kubectl"

rm -rf "$tmp"

test_done
