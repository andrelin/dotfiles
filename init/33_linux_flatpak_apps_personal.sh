# Personal Flatpak apps for Linux desktop. Skip on macOS and WSL.
is_macos && return 0
is_wsl && return 0

# Exit if Flatpak is not installed.
[[ ! "$(type -P flatpak)" ]] && e_error "Flatpak apps need Flatpak to install." && return 1

# Skip in CI.
[[ "$CI" ]] && return 0

apps_personal=(
  org.musescore.MuseScore
  com.valvesoftware.Steam
)

# Prompt per-app and install selected ones.
installed="$(flatpak list --app --columns=application 2>/dev/null)"
for app in "${apps_personal[@]}"; do
  if ! echo "$installed" | grep -q "^${app}$"; then
    read -p "  Install ${app}? [y/N] " answer < /dev/tty
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      e_header "Installing Flatpak: $app"
      flatpak install -y flathub "$app"
    fi
  fi
done

unset installed
