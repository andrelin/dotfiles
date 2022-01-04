# macOS-only stuff. Abort if not macOS.
is_macos || return 1

# Install Homebrew.
if [[ ! "$(type -P brew)" ]]; then
  e_header "Installing Homebrew"
  true | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Exit if, for some reason, Homebrew is not installed.
[[ ! "$(type -P brew)" ]] && e_error "Homebrew failed to install." && return 1

#Warning: Homebrew's sbin was not found in your PATH but you have installed
#formulae that put executables in /usr/local/sbin.
#Consider setting the PATH for example like so:
export PATH="/usr/local/sbin:$PATH"

e_header "Updating Homebrew"
brew doctor
brew update

e_header "Tapping extra casks"
brew tap homebrew/cask-fonts    # For more fonts
brew tap homebrew/cask-drivers  # For driver casks
brew tap homebrew/cask-versions # For old versions
