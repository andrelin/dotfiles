export DOTFILES=~/.dotfiles

# Source all files in "source"
function src() {
  local file
  if [[ "$1" ]]; then
    source "$DOTFILES/source/$1"
  else
    # Source only .sh files (skip .zsh files)
    for file in $DOTFILES/source/*.sh; do
      source "$file"
    done
  fi
}

# Run dotfiles script, then source.
function dotfiles() {
  $DOTFILES/bin/dotfiles "$@" && src
}

src
