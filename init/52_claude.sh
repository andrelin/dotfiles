# Link shared Claude Code config into ~/.claude/.
#
# Not handled by link/, because that maps flat into $HOME and ~/.claude also holds
# machine-local state (projects/, sessions/, history.jsonl) that must not be replaced
# by a symlink. Same reason 10_ssh_private_keys.sh exists alongside link/.ssh/.

e_header "Linking Claude Code config"

mkdir -p "$HOME/.claude"

for src in "$DOTFILES"/claude/*; do
  [[ -f "$src" ]] || continue
  base="$(basename "$src")"
  dest="$HOME/.claude/$base"

  if [[ "$src" -ef "$dest" ]]; then
    e_error "Skipping $base, same file."
    continue
  fi

  if [[ -e "$dest" ]]; then
    e_arrow "Backing up ~/.claude/$base."
    # Read by bin/dotfiles after all init scripts run, to report where backups went.
    export backup=1
    # shellcheck disable=SC2154 # backup_dir is defined in bin/dotfiles which sources this script
    mkdir -p "$backup_dir"
    mv "$dest" "$backup_dir"
  fi

  ln -sf "$src" "$dest"
  e_success "Linking ~/.claude/$base."
done
