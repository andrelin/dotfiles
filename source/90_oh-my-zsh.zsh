ZSH_CUSTOM="$HOME/.omz-custom"
ZSH_THEME="andrelin"

plugins=(
    aws
    colored-man-pages
    colorize
    git
    git-extras
    git-flow
    github
    gradle
    kubectl
    mvn
    npm
    pip
    python
    sublime
    sudo
    web-search
    z           # fast directory jumping: z foo → cd to most-used dir matching "foo"
    brew
)

if is_macos; then
	plugins+=(
		macos
	)
fi

source $ZSH/oh-my-zsh.sh
