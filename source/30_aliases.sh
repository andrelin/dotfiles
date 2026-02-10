# Files will be created with these permissions:
# files 644 -rw-r--r-- (666 minus 022)
# dirs  755 drwxr-xr-x (777 minus 022)
export LC_ALL=en_US.UTF-8

umask 022

alias dot="cd ~/.dotfiles"
alias grep='grep --color=auto'

alias ls='ls -F'
alias ll='ls -lh'
alias l='ls -Alh'

# Aliasing eachdir like this allows you to use aliases/functions as commands.
alias eachdir=". eachdir"
