#!/usr/bin/env bash
source "$DOTFILES/test/helper.sh"

e_header "$(basename "$0" .sh)"

tmp="$(mktemp -d)"
saved_path="$PATH"

# The helpers refuse to load without brew; a stub on PATH is enough, since java_recipes never calls it.
mkdir -p "$tmp/bin"
printf '#!/bin/sh\n' > "$tmp/bin/brew"
chmod +x "$tmp/bin/brew"
PATH="$tmp/bin:$PATH"
source "$DOTFILES/init/30_homebrew_helpers.sh"

# Which formulae the rule installs as plain openjdk moves through a release cycle.
assert "$(java_recipes 25)" "openjdk openjdk@21 openjdk@17" "latest is an LTS: three LTS releases"
assert "$(java_recipes 26)" "openjdk openjdk@25 openjdk@21" "first release after an LTS keeps that LTS"
assert "$(java_recipes 28)" "openjdk openjdk@25 openjdk@21" "last release before the next LTS"
assert "$(java_recipes 29)" "openjdk openjdk@25 openjdk@21" "next LTS ships as plain openjdk"
assert "$(java_recipes 30)" "openjdk openjdk@29 openjdk@25" "release after it drops the oldest LTS"

# A fake Homebrew prefix: openjdk@N kegs in opt/, and plain openjdk's version as its Cellar directory.
fake_brew() {
  local root="$tmp/$1" jdk
  shift
  mkdir -p "$root/opt"
  for jdk in "$@"; do
    case "$jdk" in
      @*) mkdir -p "$root/opt/openjdk$jdk" ;;
      *) mkdir -p "$root/opt/openjdk" "$root/Cellar/openjdk/$jdk" ;;
    esac
  done
  echo "$root"
}

default_java_home() {
  (
    unset JAVA_HOME
    HOMEBREW_PREFIX="$1"
    # The macOS symlink check looks at the real /Library/Java, which has nothing to do with a fake prefix.
    is_macos() { false; }
    source "$DOTFILES/source/10_java.sh"
    echo "${JAVA_HOME#"$1"/}"
  )
}

assert "$(default_java_home "$(fake_brew a @21 @25 27)")" "opt/openjdk@25" "default skips a newer non-LTS"
assert "$(default_java_home "$(fake_brew b @17 @21 25.0.1)")" "opt/openjdk" "default is plain openjdk while it is the LTS"
assert "$(default_java_home "$(fake_brew c @21 25_1)")" "opt/openjdk" "Homebrew revision suffix still reads as 25"
assert "$(default_java_home "$(fake_brew d)")" "" "no JDK leaves JAVA_HOME unset"
# An unmatched glob once stayed literal in bash, and the shell expanded it against the working directory's
# files and evaluated their names as arithmetic: errors on every startup, or code run by a crafted filename.
assert "$(cd "$tmp" && touch my-notes.txt && default_java_home "$(fake_brew g)" 2>&1)" "" "no JDK: no stray output"
# 25.0.2 lingers in the Cellar after an upgrade to 26, before openjdk@25 is installed: 25 is not really there.
assert "$(default_java_home "$(fake_brew f @21 25.0.2 26)")" "opt/openjdk@21" "lingering Cellar dir is not counted"

# The same file is sourced by zsh, where an unmatched glob is an error by default (NOMATCH) that aborts the file.
# Stderr is included, so an abort or a stray message fails the comparison too.
zsh_java_home() {
  (cd "$tmp" && zsh -c 'unset JAVA_HOME; HOMEBREW_PREFIX="$1"; is_macos() { false; }
    source "$DOTFILES/source/10_java.sh"; print -r -- "${JAVA_HOME#$1/}"' _ "$1" 2>&1)
}
if command -v zsh > /dev/null; then
  assert "$(zsh_java_home "$(fake_brew za @21 @25 27)")" "opt/openjdk@25" "zsh: default skips a newer non-LTS"
  assert "$(zsh_java_home "$(fake_brew zb @21 25_1)")" "opt/openjdk" "zsh: plain openjdk while it is the LTS"
  assert "$(zsh_java_home "$(fake_brew zc)")" "" "zsh: no JDK, no output and no error"
else
  e_error "zsh not found: CI installs it, so the zsh cases can't be skipped."
fi

# On macOS the keg root holds only bin/ symlinks; tools that check for a real JDK (IntelliJ) need the nested home.
mkdir -p "$(fake_brew h @25)/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home"
assert "$(default_java_home "$tmp/h")" "opt/openjdk@25/libexec/openjdk.jdk/Contents/Home" "macOS JDK layout: nested home"

# Plain jdk lists what is installed; an unmatched glob once showed up there as "*".
assert "$(cd "$tmp" && HOMEBREW_PREFIX="$(fake_brew i)" bash -c 'is_macos() { false; }
  source "$DOTFILES/source/10_java.sh"; jdk | sed -n "s/^Installed: *//p"')" "" "jdk with no JDK lists nothing"

prefix="$(fake_brew e @21 @25 27)"
(
  HOMEBREW_PREFIX="$prefix"
  source "$DOTFILES/source/10_java.sh"
  assert "$(_jdk_prefix 27)" "$prefix/opt/openjdk" "jdk finds the latest release as plain openjdk"
  assert "$(_jdk_prefix 21)" "$prefix/opt/openjdk@21" "jdk finds an openjdk@N keg"
  assert "$(_jdk_prefix 26)" "" "jdk finds nothing for a version not installed"
  # A subshell's failure count is lost when it exits, so hand it back through the exit status.
  ((__test_failures == 0))
) || ((__test_failures++))

PATH="$saved_path"
rm -rf "$tmp"

test_done
