# Exit if Homebrew is not installed.
[[ ! "$(type -P brew)" ]] && e_error "Brew recipes need Homebrew to install." && return 1

recipes=(
  bash
  bash-completion
  direnv
  git
  git-secret
  gnupg       # GNU Privacy Guard (OpenPGP)
  gnu-units
  gradle
  jq          # command-line JSON processor
  maven
  n           # Node version management
  openjdk@17
  openjdk@21
  openjdk
  the_silver_searcher
  tree
  watch
  wget
  zsh
  zsh-syntax-highlighting
)

recipes_optional=(
  gh
  kafka
  kube-ps1    # Kubernetes prompt info for bash and zsh
  kubectx
  kubernetes-cli
)

# Prompt for optional recipes and append selections
selected_recipes=$(brew_prompt_optional "Homebrew recipes" "$brew_cache_dir/recipes_optional" "${recipes_optional[@]}")
if [[ -n "$selected_recipes" ]]; then
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
