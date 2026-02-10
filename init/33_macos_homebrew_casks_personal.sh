# macOS-only stuff. Abort if not macOS.
is_macos || return 1

# Exit if Homebrew is not installed.
[[ ! "$(type -P brew)" ]] && e_error "Brew casks need Homebrew to install." && return 1

casks_personal=(
  guitar-pro
  musescore
  steam
)

# Prompt per-cask and install selected ones
casks=$(brew_prompt_optional "personal Homebrew casks" "$brew_cache_dir/casks_personal" "${casks_personal[@]}")
if [[ -n "$casks" ]]; then
  casks=($casks)
  brew_install_casks
fi
