# Turn on strict line breaks in every Obsidian vault on this machine.
#
# Markdown here is hard-wrapped, and Obsidian renders each single line break as a break unless
# "Strict line breaks" is on. It is a per-vault setting with no global default, so this walks the
# vaults Obsidian has registered. A vault opened for the first time later needs another run.

if is_macos; then
  obsidian_json="$HOME/Library/Application Support/obsidian/obsidian.json"
elif [[ -f "$HOME/.var/app/md.obsidian.Obsidian/config/obsidian/obsidian.json" ]]; then
  obsidian_json="$HOME/.var/app/md.obsidian.Obsidian/config/obsidian/obsidian.json"
else
  obsidian_json="$HOME/.config/obsidian/obsidian.json"
fi

[[ -f "$obsidian_json" ]] || return 0

e_header "Setting strict line breaks in Obsidian vaults"

if [[ ! "$(type -P jq)" ]]; then
  e_error "jq not found — skipping Obsidian."
  unset obsidian_json
  return 0
fi

while IFS= read -r vault; do
  [[ -d "$vault" ]] || continue
  app="$vault/.obsidian/app.json"
  mkdir -p "$vault/.obsidian"
  [[ -s "$app" ]] || echo '{}' > "$app"
  if [[ "$(jq '.strictLineBreaks' "$app" 2>/dev/null)" == "true" ]]; then
    e_success "Already set in $vault."
  elif jq '.strictLineBreaks = true' "$app" > "$app.tmp"; then
    mv "$app.tmp" "$app"
    e_success "Setting strict line breaks in $vault."
  else
    rm -f "$app.tmp"
    e_error "Couldn't update $app — is it valid JSON?"
  fi
done < <(jq -r '.vaults[].path' "$obsidian_json")

unset obsidian_json vault app
