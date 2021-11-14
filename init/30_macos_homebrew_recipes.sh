# macOS-only stuff. Abort if not macOS.
is_macos || return 1

# Exit if Homebrew is not installed.
[[ ! "$(type -P brew)" ]] && e_error "Brew recipes need Homebrew to install." && return 1

# Install Homebrew recipes.
function brew_install_recipes() {
  recipes=($(setdiff "${recipes[*]}" "$(brew list --formulae)"))
  if (( ${#recipes[@]} > 0 )); then
    e_header "Installing Homebrew recipes/casks: ${recipes[*]}"
    for recipe in "${recipes[@]}"; do
      brew install $recipe
    done
    brew cleanup
  fi
}

# Install Homebrew casks.
function brew_install_casks() {
  casks=($(setdiff "${casks[*]}" "$(brew list --casks)"))
  if (( ${#casks[@]} > 0 )); then
    e_header "Installing Homebrew casks: ${casks[*]}"
    for cask in "${casks[@]}"; do
      brew install --cask $cask
    done
    brew cleanup
  fi
}

# Homebrew recipes
recipes=(
  act
  aws-iam-authenticator
  awscli
  bash-completion
  bat
  curl
  dos2unix
  git
  git-secret
  gnupg
  gradle
  httpie
  jenv
  # kubernetes-cli # (part of Docker-cask)
  kubectx
  # kubernetes-helm@2.11.0 #Ruter-version
  mas
  n
  # datawire/blackbird/telepresence
  tree
  watch
  wget
)

brew_install_recipes

# Homebrew casks
casks=(
  # Applications
  1password
  # adoptopenjdk11 # Ruter
  alfred
  docker
  disk-inventory-x
  dropbox
  evernote
  firefox
  flux
  freemind
  google-chrome
  intellij-idea
  iterm2
  kindle
  kiwi-for-gmail
  mailplane
  # macpass # Ruter
  microsoft-office
  # osxfuse # Telepresence
  postman
  remember-the-milk
  skype
  slack
  snagit
  spotify
  sublime-text
  the-unarchiver
  vlc
)

brew_install_casks

# Misc cleanup!
