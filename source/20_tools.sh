# Small tool hooks that don't warrant their own file.

# direnv: auto-load .envrc when cd'ing into directories.
if [[ "$(command -v direnv)" ]]; then
  eval "$(direnv hook zsh)"
fi

# kube-ps1: Kubernetes context/namespace in prompt.
_kube_ps1="$(brew --prefix kube-ps1 2>/dev/null)/share/kube-ps1.sh"
[[ -f "$_kube_ps1" ]] && source "$_kube_ps1"
unset _kube_ps1

# iTerm2 shell integration (macOS).
if is_macos; then
  [[ -e "${HOME}/.iterm2_shell_integration.zsh" ]] && source "${HOME}/.iterm2_shell_integration.zsh"
fi
