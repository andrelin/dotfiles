#
# History
# https://kevinjalbert.com/more-shell-history/
# https://unix.stackexchange.com/a/273863
#

# How many we load (?)
export HISTSIZE=100000
# How many we can hold (?)
export SAVEHIST=$HISTSIZE
# History won't be saved without the following command
# This isn't set by default.
export HISTFILE="$HOME/.zsh_history"

# Do not display a line previously found.
setopt HIST_FIND_NO_DUPS
# Delete old recorded entry if new entry is a duplicate.
setopt HIST_IGNORE_ALL_DUPS
# Write to the history file immediately, not when the shell exits.
setopt INC_APPEND_HISTORY
# Share history between all sessions.
setopt SHARE_HISTORY
