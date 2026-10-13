# Small tool hooks that don't warrant their own file.

# direnv: auto-load .envrc when cd'ing into directories.
# The hook is shell-specific: zsh's code aborts bash part-way through startup, losing every file after this one.
if [[ "$(command -v direnv)" ]]; then
  if [[ -n "$ZSH_VERSION" ]]; then
    eval "$(direnv hook zsh)"
  elif [[ -n "$BASH_VERSION" ]]; then
    eval "$(direnv hook bash)"
  fi
fi

# kube-ps1: Kubernetes context/namespace in prompt.
_kube_ps1="$(brew --prefix kube-ps1 2>/dev/null)/share/kube-ps1.sh"
[[ -f "$_kube_ps1" ]] && source "$_kube_ps1"
unset _kube_ps1

# iTerm2 shell integration (macOS).
if is_macos; then
  [[ -e "${HOME}/.iterm2_shell_integration.zsh" ]] && source "${HOME}/.iterm2_shell_integration.zsh"
fi

# fzf: key bindings and fuzzy completion.
if command -v fzf >/dev/null 2>&1; then
  if [[ -n "$ZSH_VERSION" ]]; then
    source <(fzf --zsh)
  elif [[ -n "$BASH_VERSION" ]]; then
    eval "$(fzf --bash)"
  fi
fi
