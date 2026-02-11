# macOS-only stuff. Abort if not macOS.
is_macos || return 1

# Exit if Homebrew is not installed.
[[ ! "$(type -P brew)" ]] && e_error "Brew casks need Homebrew to install." && return 1

# In CI, install one cask to verify Homebrew cask support works.
if [[ "$CI" ]]; then
  casks=(sublime-text)
  brew_install_casks
  return 0
fi

casks=(
  1password
  font-jetbrains-mono
  google-chrome
  intellij-idea
  iterm2
  microsoft-teams
  pocket-casts
  postman
  rectangle
  slack
  spotify
  sublime-text
)

casks_optional=(
  bettertouchtool
  claude-code
  fantastical
)

# Prompt for optional casks and append selections
selected_casks=$(brew_prompt_optional "Homebrew casks" "$brew_cache_dir/casks_optional" "${casks_optional[@]}")
if [[ -n "$selected_casks" ]]; then
  casks+=($selected_casks)
fi

brew_install_casks

unset selected_casks
