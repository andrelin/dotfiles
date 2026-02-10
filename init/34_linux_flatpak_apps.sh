# Flatpak apps for Linux desktop. Skip on macOS and WSL.
is_macos && return 0
is_wsl && return 0

# Exit if Flatpak is not installed.
[[ ! "$(type -P flatpak)" ]] && e_error "Flatpak apps need Flatpak to install." && return 1

apps=(
  com.onepassword.1Password
  com.google.Chrome
  com.getpostman.Postman

  com.slack.Slack
  com.spotify.Client
  com.sublimetext.three
  com.jetbrains.IntelliJ-IDEA-Ultimate
)

apps_optional=(
  org.musescore.MuseScore
  com.valvesoftware.Steam
)

# Install apps not already installed.
installed="$(flatpak list --app --columns=application 2>/dev/null)"
for app in "${apps[@]}"; do
  if ! echo "$installed" | grep -q "^${app}$"; then
    e_header "Installing Flatpak: $app"
    flatpak install -y flathub "$app"
  fi
done

# Prompt for optional apps
for app in "${apps_optional[@]}"; do
  if ! echo "$installed" | grep -q "^${app}$"; then
    read -p "  Install ${app}? [y/N] " answer < /dev/tty
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      e_header "Installing Flatpak: $app"
      flatpak install -y flathub "$app"
    fi
  fi
done

unset installed
