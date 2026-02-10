# Verify winget.exe is available (WSL only).
is_wsl || return 1

if [[ ! "$(type -P winget.exe 2>/dev/null)" ]]; then
  e_error "winget.exe not found. Install App Installer from the Microsoft Store."
  return 1
fi

e_success "winget.exe found"
