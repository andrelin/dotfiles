# Symlink custom git hooks into .git/hooks/.
[[ -d "$DOTFILES/.git/hooks" ]] || return 1

for hook in "$DOTFILES"/hooks/*; do
  [[ -f "$hook" ]] || continue
  name="$(basename "$hook")"
  dest="$DOTFILES/.git/hooks/$name"
  if [[ "$hook" -ef "$dest" ]]; then
    e_arrow "Already linked: $name"
    continue
  fi
  ln -sf "$hook" "$dest"
  e_success "Linked git hook: $name"
done
