# macOS-only
is_macos || return 1

JETBRAINS_DIR="$HOME/Library/Application Support/JetBrains"

# Find the latest IntelliJ IDEA config directory
IDEA_DIR=$(ls -d "$JETBRAINS_DIR"/IntelliJIdea* 2>/dev/null | sort -V | tail -1)

[[ -d "$IDEA_DIR" ]] || return 1

e_header "Linking IntelliJ IDEA settings"

for subdir in codestyles colors keymaps options options/mac; do
  mkdir -p "$IDEA_DIR/$subdir"

  for file in "$DOTFILES/conf/intellij/$subdir/"*.xml; do
    [[ -f "$file" ]] || continue
    base="$(basename "$file")"
    dest="$IDEA_DIR/$subdir/$base"
    if [[ "$file" -ef "$dest" ]]; then
      e_error "Skipping $base, same file."
      continue
    fi
    if [[ -e "$dest" ]]; then
      e_arrow "Backing up $base."
      # shellcheck disable=SC2154 # backup_dir is defined in bin/dotfiles which sources this script
      mkdir -p "$backup_dir"
      mv "$dest" "$backup_dir"
    fi
    ln -sf "$file" "$dest"
    e_success "Linking $subdir/$base."
  done
done
