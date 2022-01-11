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
# setopt SHARE_HISTORY

#
# zsh-history-substring-search
#
# Load from Brew
# As per `brew info zsh-history-substring-search`
# source `brew --prefix`/share/zsh-history-substring-search/zsh-history-substring-search.zsh
# Bind UP and DOWN arrow keys
# Copied from https://github.com/zsh-users/zsh-history-substring-search/tree/47a7d416c652a109f6e8856081abc042b50125f4#usage
# bindkey '^[[A' history-substring-search-up
# bindkey '^[[B' history-substring-search-down