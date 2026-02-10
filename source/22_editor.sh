# Default editor (used by git commit, crontab, etc.)
export EDITOR=vim
export VISUAL="$EDITOR"

# Quick edit: open files in $EDITOR, or pipe stdin into it.
#   q file.txt       → vim file.txt
#   cat log | q      → view stdin in vim
function q() {
  if [[ -t 0 ]]; then
    $EDITOR "$@"
  else
    $EDITOR - > /dev/null
  fi
}

# qv — edit vim config files
# qs — open dotfiles directory
alias qv="q $DOTFILES/link/.{,g}vimrc +'cd $DOTFILES'"
alias qs="q $DOTFILES"

# For when you have vim on the brain
alias :q=exit
