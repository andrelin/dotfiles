# NVM (Node Version Manager) — switch Node.js versions with:
#   nvm install 20    → install Node 20
#   nvm use 18        → switch to Node 18
#   nvm ls            → list installed versions

# Where NVM stores Node versions.
export NVM_DIR="$HOME/.nvm"

# Find Homebrew's NVM install (Linux, macOS ARM, macOS x86).
if [[ -d /home/linuxbrew/.linuxbrew/opt/nvm ]]; then
  _nvm_prefix="/home/linuxbrew/.linuxbrew/opt/nvm"
elif [[ -d /opt/homebrew/opt/nvm ]]; then
  _nvm_prefix="/opt/homebrew/opt/nvm"
elif [[ -d /usr/local/opt/nvm ]]; then
  _nvm_prefix="/usr/local/opt/nvm"
fi

# Load NVM and its tab completions.
if [[ -n "$_nvm_prefix" ]]; then
  [ -s "$_nvm_prefix/nvm.sh" ] && \. "$_nvm_prefix/nvm.sh"
  [ -s "$_nvm_prefix/etc/bash_completion.d/nvm" ] && \. "$_nvm_prefix/etc/bash_completion.d/nvm"
fi
unset _nvm_prefix
