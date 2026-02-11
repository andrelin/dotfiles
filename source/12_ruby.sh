# Homebrew Ruby
_ruby_bin="$(brew --prefix ruby 2>/dev/null)/bin"
if [[ -d "$_ruby_bin" ]]; then
  export PATH="$_ruby_bin:$PATH"
  # shellcheck disable=SC2155 # gem's return value is irrelevant; PATH assignment always succeeds
  export PATH="$(gem environment gemdir)/bin:$PATH"
fi
unset _ruby_bin
