# Install Flatpak and add Flathub (Linux desktop only). Skip on macOS and WSL.
is_macos && return 0
is_wsl && return 0

# Install flatpak if not available.
if [[ ! "$(type -P flatpak)" ]]; then
  if is_ubuntu; then
    e_header "Installing Flatpak"
    sudo apt-get install -qq -y flatpak
  elif is_rhel; then
    e_header "Installing Flatpak"
    sudo yum install -y flatpak
  else
    e_error "Flatpak not found and no known install method for this OS."
    return 1
  fi
fi

[[ ! "$(type -P flatpak)" ]] && e_error "Flatpak failed to install." && return 1

# Add Flathub repo if not already configured.
if ! flatpak remotes --columns=name 2>/dev/null | grep -q '^flathub$'; then
  e_header "Adding Flathub repository"
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
fi
