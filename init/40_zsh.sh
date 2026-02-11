
# Set the default shell to zsh if it isn't currently set to zsh
if ! is_zsh; then
  # Add Homebrew zsh to allowed shells if not already listed
  zsh_path="$(which zsh)"
  if ! grep -qx "$zsh_path" /etc/shells; then
    echo "Adding $zsh_path to /etc/shells"
    echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  fi

  echo "Setting default shell to zsh"
  if [[ "$CI" ]]; then
    sudo chsh -s "$zsh_path" "$(whoami)" 2>/dev/null || true
  else
    chsh -s "$zsh_path"
  fi

  # Update shell export for other scripts (i.e. volta)
  SHELL=$(which zsh)
  export SHELL
  export ZSH=$HOME/.oh-my-zsh

  if [[ ! -d $ZSH ]]; then
    echo "Installing oh-my-zsh"
    KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
fi
