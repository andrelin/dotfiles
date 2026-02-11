# Windows apps for WSL via winget.exe. Skip on non-WSL.
is_wsl || return 1

# Exit if winget.exe is not available.
[[ ! "$(type -P winget.exe 2>/dev/null)" ]] && e_error "Winget apps need winget.exe." && return 1

# In CI, install one app to verify winget works.
if [[ "$CI" ]]; then
  winget.exe install --id "SublimeHQ.SublimeText.4" --accept-package-agreements --accept-source-agreements
  return 0
fi

apps=(
  "AgileBits.1Password"
  "Google.Chrome"
  "JetBrains.IntelliJ-IDEA.Ultimate"
  "Microsoft.Teams"
  "Postman.Postman"
  "SlackTechnologies.Slack"
  "Spotify.Spotify"
  "SublimeHQ.SublimeText.4"
)

apps_optional=(
  "Musescore.Musescore"
  "Valve.Steam"
)

# Install apps not already present.
installed="$(winget.exe list --disable-interactivity 2>/dev/null)"
for app in "${apps[@]}"; do
  if ! echo "$installed" | grep -q "$app"; then
    e_header "Installing (winget): $app"
    winget.exe install --id "$app" --accept-package-agreements --accept-source-agreements
  fi
done

# Prompt for optional apps
for app in "${apps_optional[@]}"; do
  if ! echo "$installed" | grep -q "$app"; then
    read -p "  Install ${app}? [y/N] " answer < /dev/tty
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      e_header "Installing (winget): $app"
      winget.exe install --id "$app" --accept-package-agreements --accept-source-agreements
    fi
  fi
done

unset installed
