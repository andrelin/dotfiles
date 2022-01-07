# # Prioritize SB1 stuff if present
# if [ -d  /home/sb1a.sparebank1.no ]; then
#   # Source global definitions
#   if [ -f /etc/bashrc ]; then
# 	   . /etc/bashrc
#   fi

#   # User specific aliases and functions
#   [ -f /home/sb1a.sparebank1.no/a504a4l/opt/etc/shrc ] && . /home/sb1a.sparebank1.no/a504a4l/opt/etc/shrc

# fi

# Where the magic happens.
export DOTFILES=~/.dotfiles

# Source all files in "source"
function src() {
  local file
  if [[ "$1" ]]; then
    source "$DOTFILES/source/$1.sh"
  else
    for file in $DOTFILES/source/*; do
      source "$file"
    done
  fi
}

# Run dotfiles script, then source.
function dotfiles() {
  $DOTFILES/bin/dotfiles "$@" && src
}

src

export PATH="$PATH:/opt/mssql-tools/bin"
