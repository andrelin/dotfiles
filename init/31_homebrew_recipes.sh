# Exit if Homebrew is not installed.
[[ ! "$(type -P brew)" ]] && e_error "Brew recipes need Homebrew to install." && return 1

# In CI, only install recipes needed by downstream scripts.
if [[ "$CI" ]]; then
  recipes=(bash zsh)
  brew_install_recipes
  return 0
fi

recipes=(
  bash
  bash-completion
  direnv
  fnm         # Node version management
  fzf
  git
  git-secret
  gnupg       # GNU Privacy Guard (OpenPGP)
  gnu-units
  gradle
  jq          # command-line JSON processor
  maven
  shellcheck
  the_silver_searcher
  tree
  watch
  wget
  zsh
  zsh-syntax-highlighting
)

# JDKs by the rule in java_recipes (30_homebrew_helpers.sh), from the version openjdk is about to install rather
# than a fixed list: openjdk upgrades in place, so when it moves on from an LTS (25 → 26) openjdk@25 must be
# installed in that same run or the LTS silently disappears. The newest LTS is the default JAVA_HOME (10_java.sh).
java_latest="$(brew info --json=v2 openjdk | grep -o '"stable": *"[0-9]*' | head -n 1 | grep -o '[0-9]*$')"
if [[ "$java_latest" =~ ^[0-9]+$ ]]; then
  # shellcheck disable=SC2207 # Formula names have no spaces; word splitting is safe
  recipes+=($(java_recipes "$java_latest"))
else
  e_error "Couldn't read the openjdk version from Homebrew, so no JDKs will be installed."
fi
unset java_latest

recipes_optional=(
  actionlint
  bats-core
  gh
  k9s         # Kubernetes terminal UI
  kafka
  kube-ps1    # Kubernetes prompt info for bash and zsh
  kubectx
  kubernetes-cli
  pipx
  poppler
  ruby
  xcbeautify
  xcode-build-server
)

# Prompt for optional recipes and append selections
# shellcheck disable=SC2154 # brew_cache_dir is defined in sourced 30_homebrew_helpers.sh
selected_recipes=$(brew_prompt_optional "Homebrew recipes" "$brew_cache_dir/recipes_optional" "${recipes_optional[@]}")
if [[ -n "$selected_recipes" ]]; then
  # shellcheck disable=SC2206 # Package names have no spaces; word splitting is safe
  recipes+=($selected_recipes)
fi

brew_install_recipes

# Set up OpenJDK symlinks so /usr/libexec/java_home can find Homebrew JDKs (macOS only)
if is_macos; then
  brew_prefix="$(brew --prefix)"
  jvm_dir="/Library/Java/JavaVirtualMachines"
  for jdk in "${brew_prefix}"/opt/openjdk*/libexec/openjdk.jdk; do
    [[ -d "$jdk" ]] || continue
    name="$(basename "$(dirname "$(dirname "$jdk")")")"
    link="${jvm_dir}/${name/@/-}.jdk"
    if [[ ! -L "$link" ]] || [[ "$(readlink "$link")" != "$jdk" ]]; then
      e_header "Linking OpenJDK: $link"
      sudo ln -sfn "$jdk" "$link"
    fi
  done
  unset brew_prefix jvm_dir jdk name link
fi
unset selected_recipes
