#!/usr/bin/env bash
source "$DOTFILES/test/helper.sh"

e_header "$(basename "$0" .sh)"

tmp="$(mktemp -d)"
saved_path="$PATH"

# A stand-in fnm that keeps its state in files: the release list, the installed versions in ascending order
# like the real one, and the default. Every command that changes state is logged.
mkdir -p "$tmp/bin"
cat > "$tmp/bin/fnm" << 'EOF'
#!/usr/bin/env bash
state="$FNM_STUB_DIR"
case "$1" in
  list-remote) cat "$state/remote" ;;
  list)
    while read -r v; do
      [[ "$v" == "$(cat "$state/default" 2> /dev/null)" ]] && echo "* $v default" || echo "* $v"
    done < "$state/installed"
    echo "* system"
    ;;
  install)
    [[ "$2" == "$FNM_STUB_FAIL" ]] && exit 1
    echo "install $2" >> "$state/log"
    echo "$2" >> "$state/installed"
    sort -t . -k 1.2,1n -k 2,2n -k 3,3n -o "$state/installed" "$state/installed"
    ;;
  default) echo "default $2" >> "$state/log"; echo "$2" > "$state/default" ;;
  uninstall)
    echo "uninstall $2" >> "$state/log"
    grep -vx "$2" "$state/installed" > "$state/next"
    mv "$state/next" "$state/installed"
    ;;
esac
EOF
chmod +x "$tmp/bin/fnm"
PATH="$tmp/bin:$PATH"
export FNM_STUB_DIR="$tmp/state"

# Runs the init script against a release list, installed versions and the patches it recorded as managed, and
# prints what it changed. DOTFILES points at a temp dir so the record lands there, not in this repo's caches/.
run_node_versions() {
  local repo="$DOTFILES"
  rm -rf "$FNM_STUB_DIR" "$tmp/dotfiles"
  mkdir -p "$FNM_STUB_DIR" "$tmp/dotfiles/caches/node"
  printf '%s\n' "${remote[@]}" > "$FNM_STUB_DIR/remote"
  printf '%s\n' "${installed[@]}" | grep . > "$FNM_STUB_DIR/installed"
  # An empty list means no record at all, as before the script's first run.
  if ((${#managed[@]} > 0)); then printf '%s\n' "${managed[@]}" > "$tmp/dotfiles/caches/node/managed"; fi
  echo "$default" > "$FNM_STUB_DIR/default"
  touch "$FNM_STUB_DIR/log"
  DOTFILES="$tmp/dotfiles"
  source "$repo/init/33_node_versions.sh" > /dev/null
  tr '\n' ',' < "$FNM_STUB_DIR/log"
}

remote=("v20.9.0 (Iron)" "v22.0.0 (Jod)" "v22.1.0 (Jod)" "v22.2.0 (Jod)" "v23.0.0" "v24.0.0 (Krypton)" "v25.1.0")
default=v24.0.0

# The latest release is not an LTS: two LTS lines plus the latest. 22 moves to its newest patch, replacing the
# managed one; v22.0.0 stands in for a patch installed by hand for an exact .nvmrc pin, and must survive.
installed=(v22.0.0 v22.1.0 v24.0.0)
managed=(v22.1.0 v24.0.0)
assert "$(run_node_versions)" "install v22.2.0,install v25.1.0,uninstall v22.1.0," "updates lines, keeps an older pin"
assert "$(tr '\n' ' ' < "$FNM_STUB_DIR/installed")" "v22.0.0 v22.2.0 v24.0.0 v25.1.0 " "installed afterwards"
assert "$(tr '\n' ' ' < "$tmp/dotfiles/caches/node/managed")" "v22.2.0 v24.0.0 v25.1.0 " "new patches recorded"

# A second run has nothing to do.
installed=(v22.0.0 v22.2.0 v24.0.0 v25.1.0)
managed=(v22.2.0 v24.0.0 v25.1.0)
assert "$(run_node_versions)" "" "second run changes nothing"

# A pin newer than the managed patch: only the managed one goes, though the pin is the highest installed.
installed=(v22.0.0 v22.1.0 v24.0.0 v25.1.0)
managed=(v22.0.0 v24.0.0 v25.1.0)
assert "$(run_node_versions)" "install v22.2.0,uninstall v22.0.0," "keeps a newer pin"

# No record yet, as on the first run after this script arrives: each line's highest installed patch is adopted,
# so an outdated one is replaced like any managed patch, and lower ones are left alone.
installed=(v22.0.0 v22.1.0 v24.0.0)
managed=()
assert "$(run_node_versions)" "install v22.2.0,install v25.1.0,uninstall v22.1.0," "first run adopts the highest"
assert "$(tr '\n' ' ' < "$tmp/dotfiles/caches/node/managed")" "v22.2.0 v24.0.0 v25.1.0 " "first run records"

# Once there is a record, a newest patch installed by hand is not adopted: the record keeps the script's own.
installed=(v22.1.0 v22.2.0 v24.0.0 v25.1.0)
managed=(v22.1.0 v24.0.0 v25.1.0)
assert "$(run_node_versions)" "" "hand-installed newest: nothing removed"
assert "$(tr '\n' ' ' < "$tmp/dotfiles/caches/node/managed")" "v22.1.0 v24.0.0 v25.1.0 " "hand-installed newest not adopted"

# The recorded patch was since uninstalled by hand: nothing to remove when the line moves on.
installed=(v24.0.0 v25.1.0)
managed=(v22.1.0 v24.0.0 v25.1.0)
assert "$(run_node_versions)" "install v22.2.0," "recorded patch already gone: no uninstall"

# A failed install keeps the line's record, so its patch is still replaced once an install succeeds.
installed=(v22.1.0 v24.0.0 v25.1.0)
managed=(v22.1.0 v24.0.0 v25.1.0)
assert "$(FNM_STUB_FAIL=v22.2.0 run_node_versions)" "" "failed install removes nothing"
assert "$(tr '\n' ' ' < "$tmp/dotfiles/caches/node/managed")" "v22.1.0 v24.0.0 v25.1.0 " "failed install keeps the record"

# The newest LTS fails to install while another line moves on: the default stays on the LTS patch still in use,
# so removing the replaced patch of the other line, here the hand-set default, never leaves no default.
remote=("v20.9.0 (Iron)" "v22.1.0 (Jod)" "v22.2.0 (Jod)" "v24.0.0 (Krypton)" "v24.1.0 (Krypton)" "v25.1.0")
installed=(v22.1.0 v24.0.0 v25.1.0)
managed=(v22.1.0 v24.0.0 v25.1.0)
default=v22.1.0
assert "$(FNM_STUB_FAIL=v24.1.0 run_node_versions)" "install v22.2.0,default v24.0.0,uninstall v22.1.0," \
  "failed LTS install: default moves to its current patch"

# A line that just became the newest LTS fails, so there is no patch to move the default to: the replaced patch
# that is still the default is kept rather than removed.
remote=("v22.2.0 (Jod)" "v24.0.0 (Krypton)" "v24.1.0 (Krypton)" "v25.1.0" "v26.0.0 (Pilot)")
installed=(v22.2.0 v24.0.0 v25.1.0)
managed=(v22.2.0 v24.0.0 v25.1.0)
default=v24.0.0
assert "$(FNM_STUB_FAIL=v26.0.0 run_node_versions)" "install v24.1.0," "the default is never removed"
default=v24.0.0

# The latest release is itself an LTS: three LTS lines, and the default moves to it.
remote=("v20.9.0 (Iron)" "v22.2.0 (Jod)" "v23.0.0" "v24.0.0 (Krypton)" "v25.1.0" "v26.0.0 (Pilot)")
installed=(v22.2.0 v24.0.0 v25.1.0)
managed=(v22.2.0 v24.0.0 v25.1.0)
assert "$(run_node_versions)" "install v26.0.0,default v26.0.0," "new LTS: installed and made the default"
assert "$(tr '\n' ' ' < "$tmp/dotfiles/caches/node/managed")" "v22.2.0 v24.0.0 v26.0.0 " "latest is an LTS: three LTS lines"

# A fresh machine: everything installed, the newest LTS made the default.
remote=("v20.9.0 (Iron)" "v22.2.0 (Jod)" "v24.0.0 (Krypton)" "v25.1.0")
installed=()
managed=()
default=
assert "$(run_node_versions)" "install v22.2.0,install v24.0.0,install v25.1.0,default v24.0.0," "fresh machine"

PATH="$saved_path"
rm -rf "$tmp"

test_done
