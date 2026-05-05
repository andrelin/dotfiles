# Navigation
alias dot="cd ~/.dotfiles"   # jump to the dotfiles repo
alias -- -='cd -'            # toggle back to the previous directory

# Listing — base `ls` is colorized per platform; the rest inherit it via alias expansion.
if is_macos; then
  alias ls='ls -FG'          # append file-type markers, colorize (BSD ls)
else
  alias ls='ls -F --color=auto'  # append file-type markers, colorize (GNU ls)
fi
alias l='ls -Alh'            # all entries except . and .., long, human-readable sizes
alias ll='ls -lh'            # long listing, human-readable sizes
alias lt='ls -lhtr'          # long listing by mtime, newest last

# Search
alias grep='grep --color=auto'  # highlight matches in output

# Sourcing `eachdir` (rather than executing it) keeps it in the current shell,
# so it can call your aliases and functions.
alias eachdir=". eachdir"

# Reload shell config after editing dotfiles.
if [[ -n "$ZSH_VERSION" ]]; then
  alias reload='source ~/.zshrc'
elif [[ -n "$BASH_VERSION" ]]; then
  alias reload='source ~/.bashrc'
fi
