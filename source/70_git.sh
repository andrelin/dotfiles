merge-from-branch() {
    FROM_BRANCH=$1
    TO_BRANCH=$2
    git checkout ${FROM_BRANCH} && git pull --rebase && git fetch --all && \
    git checkout ${TO_BRANCH} && git pull --rebase && \
    git merge ${FROM_BRANCH} && git push
}

merge-test-kpt() {
    CUR=$(git rev-parse --abbrev-ref HEAD)
    merge-from-branch ${CUR} test-kpt
    git checkout ${CUR}
}

rebase-from-branch() {
    FROM_BRANCH=$1
    TO_BRANCH=$2
    git checkout ${FROM_BRANCH} && git pull --rebase && git fetch --all && \
    git checkout ${TO_BRANCH} && git pull --rebase && \
    git rebase -i ${FROM_BRANCH} && \
    git push --force-with-lease --force-if-includes
}

rebase-from-main() {
    rebase-from-branch $(git_main_branch) $1
}

rebase-cur() {
    CUR=$(git rev-parse --abbrev-ref HEAD)
    rebase-from-main ${CUR}
}

rebase-cur-from-branch() {
    FROM_BRANCH=$1    
    CUR=$(git rev-parse --abbrev-ref HEAD)
    rebase-from-branch ${FROM_BRANCH} ${CUR}
}

gpc() {
  CUR=$(git rev-parse --abbrev-ref HEAD)
  git push --set-upstream origin ${CUR}
}

gpfc() {
  CUR=$(git rev-parse --abbrev-ref HEAD)
  git push --set-upstream origin ${CUR} --force-with-lease --force-if-includes
}
