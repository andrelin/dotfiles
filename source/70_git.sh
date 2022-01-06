refresh-from-branch() {
    FROM_BRANCH=$1
    TO_BRANCH=$2
    git checkout ${FROM_BRANCH} && git pull && git fetch --all && \
    git checkout ${TO_BRANCH} && git pull && \
    git merge ${FROM_BRANCH} && git push
}

refresh-from-master() {
    refresh-from-branch master $1
}

refresh-cur() {
    CUR=$(git rev-parse --abbrev-ref HEAD)
    refresh-from-branch master ${CUR}
}

refresh-dev() {
    refresh-from-branch master development
}

alias gc="git commit"
