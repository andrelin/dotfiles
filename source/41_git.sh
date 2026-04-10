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
#   rebase-onto-branch develop my-feature
rebase-onto-branch() {
    local onto="$1" branch="$2"
    git checkout "${onto}" && git pull --rebase && git fetch --all && \
    git checkout "${branch}" && git pull --rebase && \
    git rebase -i "${onto}" && \
    git push --force-with-lease --force-if-includes
}

# Rebase current branch onto main.
#   rebase-cur
rebase-cur() {
    local cur
    cur=$(git rev-parse --abbrev-ref HEAD)
    # shellcheck disable=SC2046 # git_main_branch returns a single branch name; safe unquoted
    rebase-onto-branch $(git_main_branch) "${cur}"
}

# Rebase current branch onto a specific branch.
#   rebase-cur-onto-branch develop
rebase-cur-onto-branch() {
    local onto="$1" cur
    cur=$(git rev-parse --abbrev-ref HEAD)
    rebase-onto-branch "${onto}" "${cur}"
}

# Push current branch and set upstream. Extra args are passed to git push.
#   gpc
gpc() {
    local cur
    cur=$(git rev-parse --abbrev-ref HEAD)
    git config "branch.${cur}.remote" origin
    git config "branch.${cur}.merge" "refs/heads/${cur}"
    git push origin "${cur}" "$@"
}

# Force-push current branch (safely) and set upstream.
#   gpfc
gpfc() {
    gpc --force-with-lease --force-if-includes
}

# Git History Diagnostics Tools

# Check what files changes the most often
#   git_most_changed_files [since] [count]
git_most_changed_files() {
  local since="${1:-1 year ago}" count="${2:-20}"
  git log --format=format: --name-only --since="$since" \
    | grep . | sort | uniq -c | sort -nr | head -"$count"
}

# Check where the biggest clusters of bugs are.
#   git_bugs_cluster [count]
git_bugs_cluster() {
  local count="${1:-20}"
  git log -i -E --grep="fix|bug|broken" --name-only --format='' \
    | grep . | sort | uniq -c | sort -nr | head -"$count"
}

# Check who actually wrote most of the code.
# Lists Authors by number of commits
#   git_who_built_this
git_who_built_this() {
  git shortlog -sn --no-merges
}

# Check if the project is growing or dying.
# Lists commit count by month
#   git_momentum
git_momentum() {
  git log --format='%ad' --date=format:'%Y-%m' | sort | uniq -c
}

# How often are they firefighting against the code?
#   git_firefighting
git_firefighting() {
  git log --oneline --since="1 year ago" \
    | grep -iE 'revert|hotfix|emergency|rollback|urgent|bugfix|fix(es)? bug' || true
}
