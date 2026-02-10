# Homebrew Ruby
_ruby_bin="$(brew --prefix ruby 2>/dev/null)/bin"
if [[ -d "$_ruby_bin" ]]; then
  export PATH="$_ruby_bin:$PATH"
  export PATH="$(gem environment gemdir)/bin:$PATH"
fi
unset _ruby_bin
