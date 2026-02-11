# Git helper functions.

# Merge a branch into another, pulling latest first.
#   merge-from-branch develop staging
merge-from-branch() {
    local from="$1" to="$2"
    git checkout "${from}" && git pull --rebase && git fetch --all && \
    git checkout "${to}" && git pull --rebase && \
    git merge "${from}" && git push
}

# Interactive rebase onto another branch.
#   rebase-from-branch develop my-feature
rebase-from-branch() {
    local from="$1" to="$2"
    git checkout "${from}" && git pull --rebase && git fetch --all && \
    git checkout "${to}" && git pull --rebase && \
    git rebase -i "${from}" && \
    git push --force-with-lease --force-if-includes
}

# Rebase current branch onto main.
#   rebase-cur
rebase-cur() {
    local cur
    cur=$(git rev-parse --abbrev-ref HEAD)
    # shellcheck disable=SC2046 # git_main_branch returns a single branch name; safe unquoted
    rebase-from-branch $(git_main_branch) "${cur}"
}

# Rebase current branch onto a specific branch.
#   rebase-cur-from-branch develop
rebase-cur-from-branch() {
    local from="$1" cur
    cur=$(git rev-parse --abbrev-ref HEAD)
    rebase-from-branch "${from}" "${cur}"
}

# Push current branch and set upstream.
#   gpc
gpc() {
    local cur
    cur=$(git rev-parse --abbrev-ref HEAD)
    git push --set-upstream origin "${cur}"
}

# Force-push current branch (safely) and set upstream.
#   gpfc
gpfc() {
    local cur
    cur=$(git rev-parse --abbrev-ref HEAD)
    git push --set-upstream origin "${cur}" --force-with-lease --force-if-includes
}
