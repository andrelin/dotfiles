export ZSH=$HOME/.oh-my-zsh
ZSH_CUSTOM="$HOME/.omz-custom"
ZSH_THEME="andrelin"

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
    mvn
    ng
    npm
    pip
    python
    sublime
    sudo
    web-search
    z
)

if is_macos; then
	plugins+=(
		brew
		macos
	)

	# source "/usr/local/opt/kube-ps1/share/kube-ps1.sh"

	test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

	export LC_ALL=en_US.UTF-8
fi

source $ZSH/oh-my-zsh.sh

if [ ! -z "\${which mvnd}" ]; then
    unalias mvnd
fi
