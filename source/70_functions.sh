# mkdir, cd into it
mkcd() {
    mkdir -p "$*"
    cd "$*"
}

# Decide which archive type we have, then extract it.
# NB: Does not handle additional flags.
extract () {
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

# Words are hard
dict() {
    ag "$@" /usr/share/dict/words
}

# directory LS
dls () {
 echo `ls -l | grep "^d" | awk '{ print $9 }' | tr -d "/"`
}

# A recursive, case-insensitive grep that excludes binary files
dgrep() {
    grep -iR "$@" * | grep -v "Binary"
}

# A recursive, case-insensitive grep that excludes binary files
# and returns only unique filenames
dfgrep() {
    grep -iR "$@" * | grep -v "Binary" | sed 's/:/ /g' | awk '{ print $1 }' | sort | uniq
}

# Process grep
psgrep() {
    if [ ! -z $1 ] ; then
        echo "Grepping for processes matching $1..."
        ps aux | grep $1 | grep -v grep
    else
        echo "!! Need name to grep for"
    fi
}

# If we dont have tree, make a simple one ourselves!
if [ -z "\${which tree}" ]; then
  tree () {
      find $@ -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'
  }
fi

# Which shell is this?!
shell () {
  ps | grep `echo $$` | awk '{ print $4 }'
}

function connect-spk() {
    globalprotect connect --portal vpn-tu-linux.pensjonskassa.no
}

ad ()
{
    ldapsearch "(&(|(objectclass=person)(objectclass=group))(|(cn=${1}*)(samAccountName=${1}*)))"
}
