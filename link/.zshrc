export DOTFILES=~/.dotfiles
export ZSH=$HOME/.oh-my-zsh

# fpath
fpath=($DOTFILES/vendor/zsh-completions/src $fpath)

# Source all files in "source"
function src() {
  local file
  if [[ "$1" ]]; then
    source "$DOTFILES/source/$1"
  else
    # Source all .sh and .zsh files
    for file ($DOTFILES/source/*sh); do
      source $file
    done
  fi
}

# Run dotfiles script, then source.
function dotfiles() {
  $DOTFILES/bin/dotfiles "$@" && src
}

src
