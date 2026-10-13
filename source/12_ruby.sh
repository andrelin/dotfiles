# Homebrew Ruby. Paths are built by hand rather than asking `brew --prefix ruby` and `gem environment gemdir`,
# which together cost about 100 ms per shell; /usr/local covers Intel macOS, where HOMEBREW_PREFIX is unset.
_brew_prefix="${HOMEBREW_PREFIX:-/usr/local}"
_ruby_bin="$_brew_prefix/opt/ruby/bin"
if [[ -d "$_ruby_bin" ]]; then
  export PATH="$_ruby_bin:$PATH"
  # The gem dir is lib/ruby/gems/<ABI version>; after an upgrade the old one can linger, so take the last.
  # A function so zsh's nullglob stays local: without it an empty match aborts the rest of this file.
  _ruby_gemdir() {
    local dir last=
    [[ -n "$ZSH_VERSION" ]] && setopt localoptions nullglob
    for dir in "$1"/lib/ruby/gems/*; do last="$dir"; done
    [[ -d "$last" ]] && echo "$last"
  }
  _gemdir="$(_ruby_gemdir "$_brew_prefix")"
  [[ -n "$_gemdir" ]] && export PATH="$_gemdir/bin:$PATH"
  unset -f _ruby_gemdir
fi
unset _brew_prefix _ruby_bin _gemdir
