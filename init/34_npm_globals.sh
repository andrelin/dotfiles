# Global npm packages used across the dotfiles workflow.
# Skip silently if npm isn't on PATH yet (fresh machine, no Node installed).

# Node comes from fnm, which this (bash) process hasn't loaded — load it the way the shell does.
[[ ! "$(type -P npm)" ]] && source "$DOTFILES/source/11_node.sh"

if [[ ! "$(type -P npm)" ]]; then
  e_arrow "npm not found — skipping global npm packages. Install Node ('fnm install --lts') and re-run dotfiles to pick them up."
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

# Each Node ships the npm current at its release, and a project's `engines` can ask for a newer one than any Node
# bundles, so bring every fnm-installed Node's npm to the latest. --engine-strict leaves a Node it doesn't support alone.
latest_npm="$(npm view npm version 2>/dev/null)"
if [[ "$latest_npm" && "$(type -P fnm)" ]]; then
  for version in $(fnm list | sed -nE 's/^\* (v[0-9.]+).*/\1/p'); do
    current_npm="$(fnm exec --using="$version" npm --version 2>/dev/null)"
    [[ "$current_npm" == "$latest_npm" ]] && continue
    e_header "Updating npm $current_npm → $latest_npm for Node $version"
    fnm exec --using="$version" npm install -g --engine-strict "npm@$latest_npm" ||
      e_arrow "npm $latest_npm doesn't support Node $version — leaving its npm $current_npm."
  done
fi

unset latest_npm version current_npm
