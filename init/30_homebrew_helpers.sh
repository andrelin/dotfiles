# Shared Homebrew helper functions used by recipe/cask scripts.

# Exit if Homebrew is not installed.
[[ ! "$(type -P brew)" ]] && e_error "Brew helpers need Homebrew to install." && return 1

# Cache directory for optional brew choices (per-machine).
# Delete caches/brew/ to re-prompt for all optional items.
brew_cache_dir="$DOTFILES/caches/brew"
mkdir -p "$brew_cache_dir"


###############################################
# Optional item prompting (with persistent cache)
###############################################

# Prompt the user for each optional item, caching answers so they're
# only asked once. Returns selected items to stdout (space-separated).
#
# Usage: brew_prompt_optional <label> <cache_file> <item1> [item2 ...]
#
# Cache file format: one line per item, "item=yes" or "item=no".
# Items already in the cache are read silently; new items are prompted.
function brew_prompt_optional() {
  local label="$1" cache_file="$2"
  shift 2
  local items=("$@")
  local selected=()
  local needs_prompt=()

  for item in "${items[@]}"; do
    local cached
    cached=$(grep "^${item}=" "$cache_file" 2>/dev/null)
    if [[ -n "$cached" ]]; then
      # Already answered — add to selected if "yes", skip otherwise.
      [[ "$cached" == "${item}=yes" ]] && selected+=("$item")
    else
      # Not in cache — will need to ask the user.
      needs_prompt+=("$item")
    fi
  done

  if ((${#needs_prompt[@]} > 0)); then
    echo "" >&2
    e_header "Optional ${label}:" >&2
    for item in "${needs_prompt[@]}"; do
      local answer
      read -p "  Install ${item}? [y/n/skip] " answer < /dev/tty
      if [[ "$answer" =~ ^[Yy](es)?$ ]]; then
        selected+=("$item")
        echo "${item}=yes" >> "$cache_file"
      elif [[ "$answer" =~ ^[Nn]o?$ ]]; then
        echo "${item}=no" >> "$cache_file"
      fi
      # Any other response: skip without caching (will be asked again next run).
    done
  fi

  echo "${selected[*]}"
}


###############################################
# Recipe (formulae) installation
###############################################

# Install Homebrew formulae from the $recipes array, skipping any
# that are already installed.
function brew_install_recipes() {
  # setdiff "A" "B" returns items in A that are not in B.
  recipes=($(setdiff "${recipes[*]}" "$(brew list --formulae)"))
  if ((${#recipes[@]} > 0)); then
    e_header "Installing Homebrew recipes: ${recipes[*]}"
    for recipe in "${recipes[@]}"; do
      brew install $recipe
    done
    brew upgrade
    brew cleanup
  fi
}


###############################################
# Cask (GUI app) installation — macOS only
###############################################

# Map cask names to their /Applications/*.app names so we can detect
# apps that were installed outside of Homebrew (e.g. Company Portal).
function cask_app_name() {
  case "$1" in
    1password)          echo "1Password.app" ;;
    bettertouchtool)    echo "BetterTouchTool.app" ;;
    claude-code)        echo "Claude.app" ;;
    fantastical)        echo "Fantastical.app" ;;
    google-chrome)      echo "Google Chrome.app" ;;
    guitar-pro)         echo "Guitar Pro 8.app" ;;
    intellij-idea)      echo "IntelliJ IDEA.app" ;;
    iterm2)             echo "iTerm.app" ;;
    microsoft-teams)    echo "Microsoft Teams.app" ;;
    musescore)          echo "MuseScore 4.app" ;;
    pocket-casts)       echo "Pocket Casts.app" ;;
    postman)            echo "Postman.app" ;;
    rectangle)          echo "Rectangle.app" ;;
    slack)              echo "Slack.app" ;;
    spotify)            echo "Spotify.app" ;;
    steam)              echo "Steam.app" ;;
    sublime-text)       echo "Sublime Text.app" ;;
    *)                  echo "" ;;
  esac
}

# Install Homebrew casks from the $casks array, skipping any that are
# already managed by Homebrew or present in /Applications/.
function brew_install_casks() {
  # Remove casks already managed by Homebrew.
  casks=($(setdiff "${casks[*]}" "$(brew list --casks)"))

  # Also skip casks whose apps are already in /Applications/.
  local filtered=()
  for cask in "${casks[@]}"; do
    local app_name
    app_name="$(cask_app_name "$cask")"
    if [[ -n "$app_name" ]] && [[ -d "/Applications/${app_name}" ]]; then
      e_arrow "Skipping ${cask}: ${app_name} already installed in /Applications"
    else
      filtered+=("$cask")
    fi
  done
  casks=("${filtered[@]}")

  if ((${#casks[@]} > 0)); then
    e_header "Installing Homebrew casks: ${casks[*]}"
    for cask in "${casks[@]}"; do
      brew install --cask $cask
    done
    brew cleanup
  fi
}
