#!/usr/bin/env bash
source "$DOTFILES/test/helper.sh"

e_header "$(basename "$0" .sh)"

# ssh rejects the other platform's options (UseKeychain is macOS-only), so each config is resolved where it applies.
if [[ "$OSTYPE" == darwin* ]]; then config=config_macos; else config=config_linux; fi

# Without its Include: the machine's private config comes first, so its settings would win over the committed ones.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
grep -v '^Include ' "$DOTFILES/link/.ssh/$config" > "$tmp/config"
resolved="$(ssh -G -F "$tmp/config" example.com 2>&1)"
assert "$(grep -ix 'stricthostkeychecking .*' <<< "$resolved")" "stricthostkeychecking accept-new" \
  "$config trusts a new host but refuses a changed key"
assert "$(grep -ix 'forwardagent .*' <<< "$resolved")" "forwardagent no" "$config forwards no agent"

test_done
