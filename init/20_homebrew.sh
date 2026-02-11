# Install Homebrew (macOS, Ubuntu, WSL, RHEL).

# On Linux, install build dependencies required by Homebrew.
if ! is_macos; then
  if is_ubuntu || is_wsl; then
    e_header "Installing Homebrew build dependencies (apt)"
    sudo apt-get update -qq
    sudo apt-get install -qq -y build-essential procps curl file git
  elif is_rhel; then
    e_header "Installing Homebrew build dependencies (yum)"
    sudo yum groupinstall -y 'Development Tools' 2>/dev/null || sudo yum install -y gcc gcc-c++ make
    sudo yum install -y --skip-broken procps-ng curl file git
  fi
fi

# Install Homebrew.
if [[ ! "$(type -P brew)" ]]; then
  e_header "Installing Homebrew"
  true | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Add brew to PATH for this session if not already available.
if [[ ! "$(type -P brew)" ]]; then
  if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  elif [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi

# Exit if, for some reason, Homebrew is not installed.
[[ ! "$(type -P brew)" ]] && e_error "Homebrew failed to install." && return 1

# macOS x86: Homebrew sbin is not on PATH by default.
if is_macos; then
  export PATH="/usr/local/sbin:$PATH"
fi

e_header "Updating Homebrew"

[[ ! "$CI" ]] && brew doctor

brew update
