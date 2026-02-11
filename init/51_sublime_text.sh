# Link Sublime Text settings and install Package Control.

# Detect Sublime Text settings directory per platform.
if is_macos && [[ -d "$HOME/Library/Application Support/Sublime Text" ]]; then
  ST_BASE="$HOME/Library/Application Support/Sublime Text"
elif [[ -d "$HOME/.config/sublime-text" ]]; then
  ST_BASE="$HOME/.config/sublime-text"
else
  return 0
fi

ST_USER="$ST_BASE/Packages/User"
ST_INSTALLED_PACKAGES="$ST_BASE/Installed Packages"

e_header "Setting up Sublime Text"

# Install Package Control if not already present.
if [[ ! -f "$ST_INSTALLED_PACKAGES/Package Control.sublime-package" ]]; then
  e_arrow "Installing Package Control"
  mkdir -p "$ST_INSTALLED_PACKAGES"
  curl -fsSL "https://packagecontrol.io/Package%20Control.sublime-package" \
    -o "$ST_INSTALLED_PACKAGES/Package Control.sublime-package"
fi

e_header "Linking Sublime Text settings"

mkdir -p "$ST_USER"
mkdir -p "$ST_USER/ANSIescape"

for file in "$DOTFILES/conf/sublime-text/"*; do
  base="$(basename "$file")"
  [[ -d "$file" ]] && continue  # skip directories, handle separately
  dest="$ST_USER/$base"
  # Package Control needs to write to its settings file, so copy instead of link.
  if [[ "$base" == "Package Control.sublime-settings" ]]; then
    if [[ ! -e "$dest" ]]; then
      cp "$file" "$dest"
      e_success "Copying $base."
    else
      e_error "Skipping $base, already exists."
    fi
    continue
  fi
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
  e_success "Linking $base."
done

# Handle ANSIescape subdirectory
for file in "$DOTFILES/conf/sublime-text/ANSIescape/"*; do
  base="$(basename "$file")"
  dest="$ST_USER/ANSIescape/$base"
  if [[ "$file" -ef "$dest" ]]; then
    e_error "Skipping ANSIescape/$base, same file."
    continue
  fi
  if [[ -e "$dest" ]]; then
    e_arrow "Backing up ANSIescape/$base."
    mkdir -p "$backup_dir"
    mv "$dest" "$backup_dir"
  fi
  ln -sf "$file" "$dest"
  e_success "Linking ANSIescape/$base."
done
