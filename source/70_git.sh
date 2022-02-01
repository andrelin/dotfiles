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

refresh-from-dev() {
    refresh-from-branch develop $1
}

refresh-cur() {
    CUR=$(git rev-parse --abbrev-ref HEAD)
    refresh-from-branch master ${CUR}
}

refresh-cur-from-branch() {
    FROM_BRANCH=$1    
    CUR=$(git rev-parse --abbrev-ref HEAD)
    refresh-from-branch ${FROM_BRANCH} ${CUR}
}

refresh-dev() {
    refresh-from-branch master develop
}

merge-test-kpt() {
    CUR=$(git rev-parse --abbrev-ref HEAD)
    refresh-from-branch ${CUR} test-kpt
    git checkout ${CUR}
}

alias gc="git commit"
