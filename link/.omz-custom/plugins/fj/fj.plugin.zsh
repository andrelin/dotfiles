# Autocompletion for the Forgejo CLI (fj), modelled on oh-my-zsh's gh plugin.
if (( ! $+commands[fj] )); then
  return
fi

# If the completion file doesn't exist yet, we need to autoload it and
# bind it to `fj`. Otherwise, compinit will have already done that.
if [[ ! -f "$ZSH_CACHE_DIR/completions/_fj" ]]; then
  typeset -g -A _comps
  autoload -Uz _fj
  _comps[fj]=_fj
fi

zmodload -F zsh/files b:zf_mv
() {
  local TMPPREFIX="$ZSH_CACHE_DIR/completions/._fj"
  zf_mv -f -- =( fj completion zsh ) "$ZSH_CACHE_DIR/completions/_fj"
} &|
