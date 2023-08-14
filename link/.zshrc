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
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

source $ZSH/oh-my-zsh.sh

src

eval export PATH="/Users/ali/.jenv/shims:${PATH}"
export JENV_SHELL=zsh
export JENV_LOADED=1
unset JAVA_HOME
unset JDK_HOME

# source '/opt/homebrew/Cellar/jenv/0.5.5_2/libexec/libexec/../completions/jenv.zsh'

jenv rehash 2>/dev/null
jenv refresh-plugins
jenv() {
  type typeset &> /dev/null && typeset command
  command="$1"
  if [ "$#" -gt 0 ]; then
    shift
  fi

  case "$command" in
  enable-plugin|rehash|shell|shell-options)
    eval `jenv "sh-$command" "$@"`;;
  *)
    command jenv "$command" "$@";;
  esac
}
