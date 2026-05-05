# https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md
source $DOTFILES/vendor/zsh-autosuggestions/zsh-autosuggestions.zsh
# shellcheck disable=SC2034 # Read by zsh-autosuggestions plugin
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#777777"

source $DOTFILES/vendor/zsh-completions/zsh-completions.plugin.zsh

source $DOTFILES/vendor/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# zsh-history-substring-search must load AFTER zsh-syntax-highlighting (per its docs).
# https://github.com/zsh-users/zsh-history-substring-search#usage
source $DOTFILES/vendor/zsh-history-substring-search/zsh-history-substring-search.zsh
# Bind ↑/↓ to substring-search through current shell's keymap.
if [[ -n "$ZSH_VERSION" ]]; then
  bindkey "${terminfo[kcuu1]:-^[[A}" history-substring-search-up
  bindkey "${terminfo[kcud1]:-^[[B}" history-substring-search-down
fi
