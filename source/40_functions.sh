# mkdir, cd into it
mkcd() {
    mkdir -p "$*"
    cd "$*" || return
}

# Decide which archive type we have, then extract it.
extract() {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)        tar xjf $1        ;;
            *.tar.gz)         tar xzf $1        ;;
            *.bz2)            bunzip2 $1        ;;
            *.rar)            unrar x $1        ;;
            *.gz)             gunzip $1         ;;
            *.tar)            tar xf $1         ;;
            *.tbz2)           tar xjf $1        ;;
            *.tgz)            tar xzf $1        ;;
            *.zip)            unzip $1          ;;
            *.Z)              uncompress $1     ;;
            *)                echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Search the dictionary
dict() {
    ag "$@" /usr/share/dict/words
}

pyclean() {
    find . | grep -E "(__pycache__|\.pyc$|\.egg-info$)" | xargs rm -rf
}
