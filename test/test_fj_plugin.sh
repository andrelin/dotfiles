#!/usr/bin/env bash
source "$DOTFILES/test/helper.sh"

e_header "$(basename "$0" .sh)"

# A stub fj stands in for forgejo-cli, which CI doesn't install, so the plugin's completion step runs. The shell runs
# in a temp HOME whose .dotfiles is this checkout, as in test_startup_spawns.sh.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
home="$tmp/home"
mkdir -p "$home" "$tmp/bin" "$tmp/cache/completions"
ln -s "$DOTFILES" "$home/.dotfiles"
ln -s "$DOTFILES/link/.omz-custom" "$home/.omz-custom"
printf '#!/bin/sh\n[ "$1 $2" = "completion zsh" ] && echo "#compdef fj"\n' > "$tmp/bin/fj"
chmod +x "$tmp/bin/fj"

if command -v zsh > /dev/null && [[ -d "$HOME/.oh-my-zsh" ]]; then
  ln -s "$HOME/.oh-my-zsh" "$home/.oh-my-zsh"
  printf 'path=(%q $path)\nsource "$HOME/.dotfiles/link/.zshrc"\n' "$tmp/bin" > "$home/.zshrc"
  # On a first run the plugin binds _fj itself, before its background job has cached it. Sourced alone under zsh -f,
  # where no compinit or Homebrew completion can bind it instead.
  bound="$(env ZSH_CACHE_DIR="$tmp/first" PATH="$tmp/bin:$PATH" zsh -f -c \
    "source '$DOTFILES/link/.omz-custom/plugins/fj/fj.plugin.zsh'; print -r -- \"comps=\${_comps[fj]-unbound}\"" \
    2> /dev/null < /dev/null)"
  assert "${bound##*comps=}" "_fj" "the plugin binds fj's completion on a first run"
  env HOME="$home" ZSH_CACHE_DIR="$tmp/cache" XDG_STATE_HOME="$tmp/state" zsh -i -c exit > /dev/null 2>&1 < /dev/null
  # The cache is written by a job the plugin disowns, so wait for it, generously for a loaded CI runner.
  for _ in {1..300}; do [[ -s "$tmp/cache/completions/_fj" ]] && break; sleep 0.1; done
  assert "$(head -1 "$tmp/cache/completions/_fj" 2> /dev/null)" "#compdef fj" "the plugin caches fj completion zsh"
else
  e_error "zsh or oh-my-zsh not found: CI installs both, so this test can't be skipped."
fi

test_done
