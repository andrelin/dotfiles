#!/usr/bin/env bash
source "$DOTFILES/test/helper.sh"

e_header "$(basename "$0" .sh)"

tmp="$(mktemp -d)"
saved_path="$PATH"

# Stand-ins for fnm and npm that keep their state in files: one npm version per installed Node, and the latest npm
# on the registry. `fnm exec --using=<v>` runs npm as that Node's; every npm install is logged.
mkdir -p "$tmp/bin"
cat > "$tmp/bin/fnm" << 'EOF'
#!/usr/bin/env bash
state="$NPM_STUB_DIR"
case "$1" in
  list) for f in "$state"/node/*; do echo "* $(basename "$f")"; done; echo "* system" ;;
  exec) NPM_STUB_NODE="${2#--using=}" "${@:3}" ;;
esac
EOF
cat > "$tmp/bin/npm" << 'EOF'
#!/usr/bin/env bash
state="$NPM_STUB_DIR"
node="${NPM_STUB_NODE:-default}"
case "$*" in
  "view npm version") cat "$state/latest" ;;
  "ls -g --depth=0 "*) exit 0 ;;
  --version) cat "$state/node/$node" ;;
  "install -g --engine-strict npm@"*)
    [[ "$node" == "$NPM_STUB_UNSUPPORTED" ]] && exit 1
    echo "$node npm@${4#npm@}" >> "$state/log"
    echo "${4#npm@}" > "$state/node/$node"
    ;;
esac
EOF
chmod +x "$tmp/bin/fnm" "$tmp/bin/npm"
PATH="$tmp/bin:$PATH"
export NPM_STUB_DIR="$tmp/state"

# Runs the init script with each Node's npm version and the registry's latest, and prints the npm installs it ran.
run_npm_globals() {
  rm -rf "$NPM_STUB_DIR"
  mkdir -p "$NPM_STUB_DIR/node"
  echo "$latest" > "$NPM_STUB_DIR/latest"
  local pair
  for pair in "${nodes[@]}"; do echo "${pair#*=}" > "$NPM_STUB_DIR/node/${pair%%=*}"; done
  touch "$NPM_STUB_DIR/log"
  source "$DOTFILES/init/34_npm_globals.sh" > /dev/null
  tr '\n' ',' < "$NPM_STUB_DIR/log"
}

latest=12.2.2
nodes=(v22.23.3=10.9.9 v24.22.2=12.2.2 v26.13.0=11.20.0)
assert "$(run_npm_globals)" "v22.23.3 npm@12.2.2,v26.13.0 npm@12.2.2," "behind Nodes updated, a current one left alone"

nodes=(v22.23.3=12.2.2 v24.22.2=12.2.2)
assert "$(run_npm_globals)" "" "every npm current: nothing to do"

nodes=(v18.0.0=9.0.0 v24.22.2=11.19.0)
assert "$(NPM_STUB_UNSUPPORTED=v18.0.0 run_npm_globals)" "v24.22.2 npm@12.2.2," "a Node the new npm doesn't support keeps its npm"

PATH="$saved_path"
rm -rf "$tmp"

test_done
