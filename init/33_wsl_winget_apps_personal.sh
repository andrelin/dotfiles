# Personal Windows apps for WSL via winget.exe. Skip on non-WSL.
is_wsl || return 1

# Exit if winget.exe is not available.
[[ ! "$(type -P winget.exe 2>/dev/null)" ]] && e_error "Winget apps need winget.exe." && return 1

# Skip in CI.
[[ "$CI" ]] && return 0

apps_personal=(
  "Musescore.Musescore"
  "Valve.Steam"
)

# Prompt per-app and install selected ones.
installed="$(winget.exe list --disable-interactivity 2>/dev/null)"
for app in "${apps_personal[@]}"; do
  if ! echo "$installed" | grep -q "$app"; then
    read -p "  Install ${app}? [y/N] " answer < /dev/tty
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      e_header "Installing (winget): $app"
      winget.exe install --id "$app" --accept-package-agreements --accept-source-agreements
    fi
  fi
done

unset installed
