merge-from-branch() {
    FROM_BRANCH=$1
    TO_BRANCH=$2
    git checkout ${FROM_BRANCH} && git pull --rebase && git fetch --all && \
    git checkout ${TO_BRANCH} && git pull --rebase && \
    git merge ${FROM_BRANCH} && git push
}

rebase-from-branch() {
    FROM_BRANCH=$1
    TO_BRANCH=$2
    git checkout ${FROM_BRANCH} && git pull --rebase && git fetch --all && \
    git checkout ${TO_BRANCH} && git pull --rebase && \
    git rebase -i ${FROM_BRANCH}
}

rebase-from-master() {
    rebase-from-branch master $1
}

rebase-cur() {
    CUR=$(git rev-parse --abbrev-ref HEAD)
    rebase-from-branch master ${CUR}
}

rebase-cur-from-branch() {
    FROM_BRANCH=$1    
    CUR=$(git rev-parse --abbrev-ref HEAD)
    rebase-from-branch ${FROM_BRANCH} ${CUR}
}

merge-test-kpt() {
    CUR=$(git rev-parse --abbrev-ref HEAD)
    merge-from-branch ${CUR} test-kpt
    git checkout ${CUR}
}

alias gc="git commit"
