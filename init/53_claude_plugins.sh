# Claude Code plugins, installed from the marketplaces the CLI already knows about.
# Skip if the claude CLI can't be found (installed by 32_macos_homebrew_casks.sh on macOS).
# The native installer puts it in ~/.local/bin, which isn't on the installer's PATH.

claude_bin="$(type -P claude)"
[[ ! "$claude_bin" && -x "$HOME/.local/bin/claude" ]] && claude_bin="$HOME/.local/bin/claude"

if [[ ! "$claude_bin" ]]; then
  e_arrow "claude not found — skipping Claude Code plugins. Install Claude Code and re-run dotfiles to pick them up."
  unset claude_bin
  return 0
fi

plugins=(
  superpowers@claude-plugins-official   # brainstorming, TDD, systematic debugging, skill authoring
)

installed="$("$claude_bin" plugin list 2>/dev/null)"

for plugin in "${plugins[@]}"; do
  if [[ "$installed" == *"$plugin"* ]]; then
    e_success "$plugin already installed."
    continue
  fi

  e_header "Installing Claude Code plugin: $plugin"
  "$claude_bin" plugin install --yes "$plugin" || e_error "Failed to install $plugin."
done

unset claude_bin plugins installed plugin
