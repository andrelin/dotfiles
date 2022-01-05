export ZSH=$HOME/.oh-my-zsh
ZSH_CUSTOM="$HOME/.config/omz"
ZSH_THEME="frisk"

plugins=(
    aws
    colored-man-pages
    colorize
    docker
    git
    git-extras
    git-flow
    github
    gradle
    kubectl
    jira
    ng
    npm
    pip
    python
    sublime
    sudo
    theme
    web-search
    z
    zsh-syntax-highlighting
)


if is_macos; then
	plugins+=(
		brew
		macos
	)

	source "/usr/local/opt/kube-ps1/share/kube-ps1.sh"

	test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

	export LC_ALL=en_US.UTF-8
fi
