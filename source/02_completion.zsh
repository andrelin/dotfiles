# #
# # Completion
# # https://github.com/robbyrussell/oh-my-zsh/blob/master/lib/completion.zsh
# #

# autoload -U compinit
# compinit

# # fixme - the load process here seems a bit bizarre
# zmodload -i zsh/complist

# WORDCHARS=''

# unsetopt menu_complete   # do not autoselect the first completion entry
# unsetopt flowcontrol
# setopt auto_menu         # show completion menu on successive tab press
# setopt complete_in_word
# setopt always_to_end

# # should this be in keybindings?
# bindkey -M menuselect '^o' accept-and-infer-next-history
# zstyle ':completion:*:*:*:*:*' menu select

# zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'

# # Complete . and .. special directories
# zstyle ':completion:*' special-dirs true

# zstyle ':completion:*' list-colors ''
# zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'

# zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"

# # disable named-directories autocompletion
# zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories

# # Use caching so that commands like apt and dpkg complete are useable
# zstyle ':completion::complete:*' use-cache 1
# zstyle ':completion::complete:*' cache-path $DOTFILES/caches

# # Don't complete uninteresting users
# zstyle ':completion:*:*:*:users' ignored-patterns \
#         adm amanda apache at avahi avahi-autoipd beaglidx bin cacti canna \
#         clamav daemon dbus distcache dnsmasq dovecot fax ftp games gdm \
#         gkrellmd gopher hacluster haldaemon halt hsqldb ident junkbust kdm \
#         ldap lp mail mailman mailnull man messagebus  mldonkey mysql nagios \
#         named netdump news nfsnobody nobody nscd ntp nut nx obsrun openvpn \
#         operator pcap polkitd postfix postgres privoxy pulse pvm quagga radvd \
#         rpc rpcuser rpm rtkit scard shutdown squid sshd statd svn sync tftp \
#         usbmux uucp vcsa wwwrun xfs '_*'

# # ... unless we really want to.
# zstyle '*' single-ignored show

# # Delete Git's official completions to allow Zsh's official Git completions to work.
# # Git ships with really bad Zsh completions. Zsh provides its own completions
# # for Git, and they are much better.
# # https://github.com/Homebrew/homebrew-core/issues/33275#issuecomment-432528793
# # https://twitter.com/OliverJAsh/status/1068483170578964480
# # Unfortunately it's not possible to install Git without completions (since
# # https://github.com/Homebrew/homebrew-core/commit/f710a1395f44224e4bcc3518ee9c13a0dc850be1#r30588883),
# # so in order to use Zsh's own completions, we must delete Git's completions.
# # This is also necessary for hub's Zsh completions to work:
# # https://github.com/github/hub/issues/1956.
# # function () {
# #   GIT_ZSH_COMPLETIONS_FILE_PATH="$(brew --prefix)/share/zsh/site-functions/_git"
# #   if [ -f $GIT_ZSH_COMPLETIONS_FILE_PATH ]
# #   then
# #   rm $GIT_ZSH_COMPLETIONS_FILE_PATH
# #   fi
# # }

# # Don't autocomplete tags on git-checkout + gc function alias
# # zstyle ':completion::complete:git-checkout:argument-rest:commit-tag-refs' command "echo"
# # zstyle ':completion::complete:git-checkout:argument-rest:blob-tag-refs' command "echo"
# # zstyle ':completion::complete:gc:argument-rest:commit-tag-refs' command "echo"
# # zstyle ':completion::complete:gc:argument-rest:blob-tag-refs' command "echo"

# [[ $commands[kubectl] ]] && source <(kubectl completion zsh)
