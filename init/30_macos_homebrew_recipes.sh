# macOS-only stuff. Abort if not macOS.
is_macos || return 1

# Exit if Homebrew is not installed.
[[ ! "$(type -P brew)" ]] && e_error "Brew recipes need Homebrew to install." && return 1

# Install Homebrew recipes.
function brew_install_recipes() {
  recipes=($(setdiff "${recipes[*]}" "$(brew list --formulae)"))
  if ((${#recipes[@]} > 0)); then
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
  if ((${#casks[@]} > 0)); then
    e_header "Installing Homebrew casks: ${casks[*]}"
    for cask in "${casks[@]}"; do
      brew install --cask $cask
    done
    brew cleanup
  fi
}

# Install Homebrew casks.
function brew_install_fonts() {
  fonts=($(setdiff "${fonts[*]}" "$(brew list --fonts)"))
  if ((${#fonts[@]} > 0)); then
    e_header "Installing Homebrew fonts: ${fonts[*]}"
    for font in "${fonts[@]}"; do
      brew install --cask $font
    done
    brew cleanup
  fi
}

# Homebrew recipes
recipes=(
  #  act
  #  aws-iam-authenticator
  #  awscli
  bash-completion
  #  bat
  curl
  #  dos2unix
  git
  git-secret
  gnupg
  gnu-units
  google-java-format
  gradle
  #  httpie
  java11
  jenv
  kube-ps1
  kubectx
  kubernetes-cli # (part of Docker-cask)
  maven
  mas
  n
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
  #  asana
  bettertouchtool
  discord
  #  disk-inventory-x
  docker
  #  dropbox
  #  evernote
  firefox
  #  flux
  #  freemind
  google-chrome
  guitar-pro
  harvest
  intellij-idea
  intellij-idea-ce
  iterm2
  #  kindle
  #  kiwi-for-gmail
  #  mailplane
  #  microsoft-office
  microsoft-teams
  musescore
  pocket-casts
  #  postman
  #  remember-the-milk
  rectangle
  #  skype
  slack
  #  snagit
  spotify
  steam
  sublime-text
  #  tableplus
  #  the-unarchiver
  vlc
  whatsapp
  #  zoom
)

brew_install_casks

fonts=(
  font-fontawesome
  font-jetbrains-mono
)

brew_install_fonts
