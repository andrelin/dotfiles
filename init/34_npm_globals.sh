# Global npm packages used across the dotfiles workflow.
# Skip silently if npm isn't on PATH yet (fresh machine, no Node installed).

# Node comes from nvm, which this (bash) process hasn't loaded — load it the way the shell does.
[[ ! "$(type -P npm)" ]] && source "$DOTFILES/source/11_node.sh"

if [[ ! "$(type -P npm)" ]]; then
  e_arrow "npm not found — skipping global npm packages. Install Node ('nvm install --lts') and re-run dotfiles to pick them up."
  return 0
fi

packages=(
  doctoc              # Markdown ToC generator
  markdownlint-cli2   # Markdown linter
)

to_install=()
for pkg in "${packages[@]}"; do
  if ! npm ls -g --depth=0 "$pkg" >/dev/null 2>&1; then
    to_install+=("$pkg")
  fi
done

if ((${#to_install[@]} > 0)); then
  e_header "Installing global npm packages: ${to_install[*]}"
  npm install -g "${to_install[@]}"
fi

unset to_install
