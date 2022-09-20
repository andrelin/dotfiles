export DOTFILES=~/.dotfiles
export ZSH=$HOME/.oh-my-zsh

# fpath
fpath=($DOTFILES/zfunctions $DOTFILES/vendor/zsh-completions/src $fpath)

# Source all files in "source"
function src() {
  local file

  # local file
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

export PATH="~/.vdi-tools/bin:$PATH"
export PATH="$PATH:/opt/mssql-tools/bin"

source $ZSH/oh-my-zsh.sh

src
