#!/usr/bin/env bash
source "$DOTFILES/test/helper.sh"

e_header "$(basename "$0" .sh)"

# At shell start source/11_node.sh calls `fnm use` itself, since --use-on-cd only fires on cd, but only when it
# finds a version file in the working directory or a parent, so most shells spawn nothing. A stand-in fnm logs
# each `use` and whether it got input: fnm asks to install a missing pin, and that prompt must not hold up a shell.

tmp="$(mktemp -d)"
mkdir -p "$tmp/bin" "$tmp/fnm/aliases"
cat > "$tmp/bin/fnm" << EOF
#!/usr/bin/env bash
case "\$1" in
  env) echo 'export FNM_DIR="$tmp/fnm"' ;;
  use) read -r answer; echo "use \${answer:-no-input}" >> "$tmp/calls" ;;
esac
EOF
chmod +x "$tmp/bin/fnm"

# Sources the node setup in a shell started in $2, with input waiting on stdin, and prints the logged fnm calls.
# The parents of a mktemp dir carry no version files, so only the ones a case creates are found.
startup_calls() {
  rm -f "$tmp/calls"
  (cd "$2" && echo y | PATH="$tmp/bin:$PATH" HOMEBREW_PREFIX="$tmp/nobrew" "$1" -c \
    'is_macos() { false; }; source "$DOTFILES/source/11_node.sh"' > /dev/null 2>&1)
  if [[ -f "$tmp/calls" ]]; then tr '\n' ',' < "$tmp/calls"; fi
}

mkdir -p "$tmp/nvmrc/sub/deeper" "$tmp/nodeversion" "$tmp/package" "$tmp/plain"
echo 22 > "$tmp/nvmrc/.nvmrc"
echo 22 > "$tmp/nvmrc/sub/.nvmrc"
echo 22 > "$tmp/nodeversion/.node-version"
echo '{"name": "x"}' > "$tmp/package/package.json"

shells=(bash)
if command -v zsh > /dev/null; then
  shells+=(zsh)
else
  e_error "zsh not found: CI installs it, so the zsh half of this test can't be skipped."
fi

for shell in "${shells[@]}"; do
  rm -f "$tmp/fnm/aliases/default"
  assert "$(startup_calls "$shell" "$tmp/nvmrc/sub/deeper")" "use no-input," \
    "$shell: .nvmrc in a parent switches, once though two are found"
  assert "$(startup_calls "$shell" "$tmp/nodeversion")" "use no-input," "$shell: .node-version switches"
  assert "$(startup_calls "$shell" "$tmp/plain")" "" "$shell: no version file, no fnm call"
  assert "$(startup_calls "$shell" "$tmp/package")" "" "$shell: package.json before any default, no fnm call"
  ln -s "$tmp" "$tmp/fnm/aliases/default"
  assert "$(startup_calls "$shell" "$tmp/package")" "use no-input," "$shell: package.json once a default exists"
done

rm -rf "$tmp"

test_done
