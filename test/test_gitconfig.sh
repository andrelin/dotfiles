#!/usr/bin/env bash
source "$DOTFILES/test/helper.sh"

e_header "$(basename "$0" .sh)"

# A throwaway HOME holding only the committed configs, so the machine's own settings can't decide the result.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cp "$DOTFILES/copy/.gitconfig" "$DOTFILES/copy/.gitconfig_uptime" "$tmp/"
export HOME="$tmp" GIT_CONFIG_NOSYSTEM=1

email_in() { # repo dir, remote url or empty
  mkdir -p "$1"
  git -C "$1" init -q
  [ -z "$2" ] || git -C "$1" remote add origin "$2"
  git -C "$1" config user.email
}

assert "$(email_in "$tmp/elsewhere/personal" git@github.com:andrelin/dotfiles.git)" "andreas@lindjo.no" \
  "a personal repo commits as the personal address"
n=0
for url in git@github.com:uptimeconsulting/website.git ssh://git@github.com/UptimeConsulting/website.git \
  https://github.com/uptimeconsulting/website.git; do
  n=$((n + 1))
  assert "$(email_in "$tmp/elsewhere/gh-$n" "$url")" "andreas.lind-johansen@uptimeconsulting.no" \
    "a repo in Uptime's GitHub org commits as the company address ($url)"
done
assert "$(email_in "$tmp/elsewhere/other-org" git@github.com:uptimeconsulting-fork/website.git)" "andreas@lindjo.no" \
  "an org whose name only starts like Uptime's doesn't count"
assert "$(email_in "$tmp/src/uptime/new" "")" "andreas.lind-johansen@uptimeconsulting.no" \
  "a repo under ~/src/uptime without a remote commits as the company address"
assert "$(email_in "$tmp/src/uptime-notes" "")" "andreas@lindjo.no" "a directory that only starts like ~/src/uptime doesn't count"

test_done
