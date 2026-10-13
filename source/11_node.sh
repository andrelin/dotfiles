# fnm (Fast Node Manager) — switch Node.js versions with:
#   fnm install --lts → install the latest LTS
#   fnm use 22        → switch to Node 22
#   fnm list          → list installed versions
# --use-on-cd switches automatically on entering a directory with a .nvmrc or .node-version,
# looking up through parent directories (recursive) so it also works from a monorepo subfolder.
if command -v fnm >/dev/null 2>&1; then
  if [[ -n "$ZSH_VERSION" ]]; then
    eval "$(fnm env --use-on-cd --version-file-strategy=recursive --shell zsh)"
  else
    eval "$(fnm env --use-on-cd --version-file-strategy=recursive --shell bash)"
    # zsh picks up Homebrew's completions from site-functions on its own; bash needs them sourced.
    _fnm_completion="${HOMEBREW_PREFIX:-/usr/local}/etc/bash_completion.d/fnm"
    [[ -f "$_fnm_completion" ]] && source "$_fnm_completion"
    unset _fnm_completion
  fi

  # --use-on-cd only fires on cd, so a shell opened inside a project (a new tab, an IDE terminal) would start on the
  # default instead. Walk up for a version file in the shell itself, and only call fnm when one is found.
  # package.json counts too: fnm reads its engines field, and falls back to the default when there is none, so it
  # only counts once a default exists (fnm env sets FNM_DIR); before that, fnm would print an error in every shell.
  _fnm_dir="$PWD"
  while [[ -n "$_fnm_dir" ]]; do
    if [[ -f "$_fnm_dir/.nvmrc" || -f "$_fnm_dir/.node-version" ]] ||
      [[ -f "$_fnm_dir/package.json" && -e "$FNM_DIR/aliases/default" ]]; then
      # No stdin: a pinned version that isn't installed makes fnm ask to install it, which would hold up the shell.
      fnm use --silent-if-unchanged < /dev/null
      break
    fi
    _fnm_dir="${_fnm_dir%/*}"
  done
  unset _fnm_dir
fi

# pnpm — where globally-installed pnpm packages land. The location is
# platform-specific: macOS uses ~/Library, Linux follows the XDG data dir.
if is_macos; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/pnpm"
fi

# Add to PATH once, and only if pnpm is actually installed.
if [[ -d "$PNPM_HOME" && ":$PATH:" != *":$PNPM_HOME/bin:"* ]]; then
  export PATH="$PNPM_HOME/bin:$PATH"
fi
