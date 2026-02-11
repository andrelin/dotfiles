# Set up SSH config and private keys.
[[ ! -d ~/.ssh ]] && return 1

# Symlink the platform-specific SSH config.
if is_macos; then
  ln -sf ~/.ssh/config_macos ~/.ssh/config
else
  ln -sf ~/.ssh/config_linux ~/.ssh/config
fi

# Add all private keys in ~/.ssh/keys to the agent.
if is_macos; then
  find -L ~/.ssh/keys -type f ! -name "*.pub" ! -name ".gitkeep" -exec ssh-add --apple-use-keychain {} +
else
  find -L ~/.ssh/keys -type f ! -name "*.pub" ! -name ".gitkeep" -exec ssh-add {} +
fi
