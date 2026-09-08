# Claude Code plugins, installed from the marketplaces the CLI already knows about.
# Skip silently if the claude CLI isn't on PATH yet (installed by 32_macos_homebrew_casks.sh on macOS).

if [[ ! "$(type -P claude)" ]]; then
  e_arrow "claude not found — skipping Claude Code plugins. Install Claude Code and re-run dotfiles to pick them up."
  return 0
fi

plugins=(
  superpowers@claude-plugins-official   # brainstorming, TDD, systematic debugging, skill authoring
)

installed="$(claude plugin list 2>/dev/null)"

for plugin in "${plugins[@]}"; do
  if [[ "$installed" == *"$plugin"* ]]; then
    e_success "$plugin already installed."
    continue
  fi

  e_header "Installing Claude Code plugin: $plugin"
  claude plugin install --yes "$plugin" || e_error "Failed to install $plugin."
done

unset plugins installed plugin
