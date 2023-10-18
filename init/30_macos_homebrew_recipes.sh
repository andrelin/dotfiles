# macOS-only stuff. Abort if not macOS.
is_macos || return 1

# Exit if Homebrew is not installed.
[[ ! "$(type -P brew)" ]] && e_error "Brew recipes need Homebrew to install." && return 1

# Install Homebrew recipes.
function brew_install_recipes() {
  recipes=($(setdiff "${recipes[*]}" "$(brew list --formulae)"))
  if ((${#recipes[@]} > 0)); then
    e_header "Installing Homebrew recipes: ${recipes[*]}"
    for recipe in "${recipes[@]}"; do
      brew install $recipe
    done
    brew cleanup
  fi
}

# Install Homebrew casks.
function brew_install_casks() {
  casks=($(setdiff "${casks[*]}" "$(brew list --casks)"))
  if ((${#casks[@]} > 0)); then
    e_header "Installing Homebrew casks: ${casks[*]}"
    for cask in "${casks[@]}"; do
      brew install --cask $cask
    done
    brew cleanup
  fi
}

# Homebrew recipes
recipes=(
  bash
  bash-completion
  curl
  git
  git-secret
  gnupg
  gnu-units
  gradle
  java
  jenv
  jq
  kube-ps1
  kubectx
  kubernetes-cli # (part of Docker-cask)
  maven
  mas
  n
  openjdk@17
  openjdk
  the_silver_searcher
  tree
  watch
  wget
  zsh
  zsh-syntax-highlighting
)

brew_install_recipes

# Homebrew casks
casks=(
  # Applications
  1password
  aerial
  alfred
  bettertouchtool
  discord
  docker
  fantastical
  firefox
  font-fontawesome
  font-jetbrains-mono
  #  flux
  google-chrome
  intellij-idea
  # intellij-idea-ce
  iterm2
  microsoft-teams
  pocket-casts
  postman
  rectangle
  slack
  spotify
  sublime-text
  tableplus
  vlc
  whatsapp
)

brew_install_casks
