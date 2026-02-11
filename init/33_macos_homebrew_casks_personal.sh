# macOS-only stuff. Abort if not macOS.
is_macos || return 1

# Exit if Homebrew is not installed.
[[ ! "$(type -P brew)" ]] && e_error "Brew casks need Homebrew to install." && return 1

# Nothing to verify in CI that isn't already covered by the casks script.
[[ "$CI" ]] && return 0

casks_personal=(
  guitar-pro
  musescore
  steam
)

# Prompt per-cask and install selected ones
# shellcheck disable=SC2154 # brew_cache_dir is defined in sourced 30_homebrew_helpers.sh
casks=$(brew_prompt_optional "personal Homebrew casks" "$brew_cache_dir/casks_personal" "${casks_personal[@]}")
if [[ -n "$casks" ]]; then
  # shellcheck disable=SC2206 # Cask names have no spaces; word splitting is safe
  casks=($casks)
  brew_install_casks
fi
