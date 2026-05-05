ZSH_CUSTOM="$HOME/.omz-custom"
ZSH_THEME="andrelin"

plugins=(
    1password
    alias-finder
    colored-man-pages
    colorize
    command-not-found
    docker
    docker-compose
    encode64
    extract
    gh
    git
    git-extras
    gradle
    kubectl
    mvn
    npm
    pip
    python
    safe-paste
    sublime
    sudo
    urltools
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
