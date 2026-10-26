#!/usr/bin/env bash
# Resolve the guard before sourcing the helper: bin/dotfiles exports
# DOTFILES=~/.dotfiles when sourced, so afterwards this would test whatever tree
# lives there rather than the one this file was launched from.
CHECKOUT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$CHECKOUT/claude/hooks/work-context.sh"
readonly CHECKOUT SCRIPT

source "$DOTFILES/test/helper.sh"

if [[ ! -x "$SCRIPT" ]]; then
  echo "ERROR: $SCRIPT is missing or not executable" >&2
  exit 1
fi
# The cases build their hook input with jq; without it every input is empty and the guard rightly passes it.
if [[ ! "$(type -P jq)" ]]; then
  echo "ERROR: jq is required to build the hook input" >&2
  exit 1
fi

e_header "$(basename "$0" .sh)"

# A developer's own environment must not leak into the fixtures; the env cases set these explicitly.
unset GH_REPO GH_HOST GITLAB_HOST GIT_DIR GIT_WORK_TREE GITLAB_REPO GL_HOST GITLAB_URI
unset WORK_CONTEXT_WAIVE WORK_CONTEXT_GIT CLAUDE_PROJECT_DIR

root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT
# HOME is the un-canonicalised temp root: the marker and shim-dir rules compare canonical paths, and on macOS
# mktemp's /var/folders is a symlink into /private.
export HOME="$root"
# Only scratch/ is a scratch prefix, so fixtures beside it are not exempt from the no-origin rule.
export WORK_CONTEXT_SCRATCH_DIRS="$root/scratch"
mkdir -p "$root/scratch"
# Customer work is only what ~/.claude-customers lists; these fixtures stand in for a customer on each host.
printf '%s\n' '# example customers' github.com/example-client gitlab.com/example-client gitlab.example.com/example-client \
  ghe.example.com/example-client dev.azure.com/example-client forgejo.example.com/example-client > "$HOME/.claude-customers"

# The guard runs under Apple's bash 3.2 as a hook, so the tests run it the same way.
function wc_run() { /bin/bash "$SCRIPT" "$@"; }

# mkrepo <dir> [origin-url]
function mkrepo() {
  mkdir -p "$1"
  git -C "$1" init -q
  [[ -z "$2" ]] || git -C "$1" remote add origin "$2"
}

# push_customers [--off]: saves the customers file, which --off also removes; pop_customers restores the last save,
# reset_customers copies it back and keeps it saved.
customers_depth=0
function push_customers() {
  customers_depth=$((customers_depth + 1))
  cp "$HOME/.claude-customers" "$HOME/customers.$customers_depth"
  [[ ${1-} == --off ]] && rm "$HOME/.claude-customers"
  return 0
}
function pop_customers() {
  mv "$HOME/customers.$customers_depth" "$HOME/.claude-customers"
  customers_depth=$((customers_depth - 1))
}
function reset_customers() { cp "$HOME/customers.$customers_depth" "$HOME/.claude-customers"; }

PERSONAL_URL=git@github.com:andrelin/dotfiles.git
CUSTOMER_URL=git@github.com:example-client/x.git
CUSTOMER_GL_URL=git@gitlab.com:example-client/x.git
COMPANY_URL=git@github.com:uptimeconsulting/x.git

P="$root/personal";   mkrepo "$P" "$PERSONAL_URL"
C="$root/customer";   mkrepo "$C" "$CUSTOMER_URL"
CO="$root/company";   mkrepo "$CO" "$COMPANY_URL"
mkdir -p "$C/sub"

# --- level ---------------------------------------------------------------------------------------------------

e_header "level: URL forms"

n=0
while IFS='|' read -r url expected; do
  n=$((n + 1))
  mkrepo "$root/lv/$n" "$url"
  assert "$(wc_run level "$root/lv/$n")" "$expected" "$url"
done <<'EOF'
git@github.com:andrelin/dotfiles.git|personal
ssh://git@github.com:22/andrelin/dotfiles.git|personal
https://github.com/andrelin/uptime-demo|company
https://github.com/andrelin/UptimeTalk.git|company
git@github.com:uptimeconsulting/x.git|company
https://github.com/uptimeconsulting/x|company
git@gitlab.com:example-client/group/sub/repo.git|customer
https://dev.azure.com/example-client/proj/_git/repo|customer
git@ssh.dev.azure.com:v3/example-client/p/r|customer
git@gitlab.com:andrelin/x.git|company
git@gitlab.com:uptimeconsulting/x.git|company
not a url|company
git@github.com:some-oss-owner/x.git|company
git@github.com:Andrelin/dotfiles.git|personal
https://github.com/UptimeConsulting/x|company
https://gitlab.example.com/uptimeconsulting/sub/x.git|company
https://andrelin@github.com/andrelin/x.git|personal
EOF

mkdir -p "$root/not-a-repo"
assert "$(wc_run level "$root/not-a-repo")" "company" "a directory outside any repo"
mkdir -p "$root/custtree/sub"; mkrepo "$root/custtree/corepo" "$COMPANY_URL"
printf '%s\n' '  ~/custtree   # a customer tree' >> "$HOME/.claude-customers"
assert "$(wc_run level "$root/custtree/sub")" "customer" "a non-repo directory below a listed customer directory"
assert "$(wc_run level "$root/custtree/corepo")" "customer" "a company-origin repo below a customer directory"
assert "$(wc_run level "$root/not-a-repo")" "company" "a non-repo directory outside the listed ones"
mkrepo "$root/scratch/noorigin"
assert "$(wc_run level "$root/scratch/noorigin")" "personal" "a no-origin repo under a scratch prefix"
mkrepo "$root/noorigin"
assert "$(wc_run level "$root/noorigin")" "company" "a no-origin repo beside the scratch prefix"
mkrepo "$root/scratchy/noorigin"
assert "$(wc_run level "$root/scratchy/noorigin")" "company" "a sibling sharing the scratch prefix's name"
assert "$(cd "$P" && wc_run level)" "personal" "level defaults to the working directory"

e_header "level: the user's customers file"

# Owners listed in ~/.claude-customers are customer work, on that host only; an unlisted owner is the user's own.
push_customers
printf '%s\n' '# acquired' 'dev.azure.com/Example-Acquired' '  gitlab.example.com/acq-group   # its GitLab' \
  '# dev.azure.com/commented-out' '' >> "$HOME/.claude-customers"
n=0
while IFS='|' read -r url expected; do
  n=$((n + 1))
  mkrepo "$root/orgs/$n" "$url"
  assert "$(wc_run level "$root/orgs/$n")" "$expected" "listed: $url"
done <<'EOF'
https://dev.azure.com/example-acquired/proj/_git/repo|customer
https://example-acquired@dev.azure.com/example-acquired/proj/_git/repo|customer
git@ssh.dev.azure.com:v3/example-acquired/p/r|customer
https://gitlab.example.com/acq-group/x.git|customer
git@github.com:example-acquired/x.git|company
https://dev.azure.com/commented-out/p/_git/r|company
https://dev.azure.com/example-acquired-two/p/_git/r|company
EOF

# A name or abbreviation marks every folder below $HOME named for the customer, whatever the repo's origin.
printf '%s\n' 'Fjordvik Kraftlag' 'FVK' 'Ærøby' >> "$HOME/.claude-customers"
mkdir -p "$root/work/fjordvik-kraftlag-api" "$root/work/FVK_portal/sub" "$root/work/fvkx" "$root/work/myfvk"
mkrepo "$root/work/fvk-app" "$COMPANY_URL"
assert "$(wc_run level "$root/work/fjordvik-kraftlag-api")" "customer" "a folder containing a listed name"
assert "$(wc_run level "$root/work/FVK_portal/sub")" "customer" "below a folder with the abbreviation as a word"
assert "$(wc_run level "$root/work/fvk-app")" "customer" "a company-origin repo in a folder named for a customer"
assert "$(wc_run level "$root/work/fvkx")" "company" "an abbreviation inside a longer word"
assert "$(wc_run level "$root/work/myfvk")" "company" "an abbreviation ending a longer word"
pop_customers
assert "$(wc_run level "$root/orgs/1")" "company" "unlisted again, the owner is the user's own"

# --- check-argv ----------------------------------------------------------------------------------------------

# argv_rc <dir> <tool> [args...]: the exit status of check-argv.
function argv_rc() { wc_run check-argv "$@" 2>/dev/null; echo $?; }
function expect_argv() {
  local expected="$1"; shift
  assert "$(argv_rc "$@")" "$expected" "check-argv ${1#"$root"/} ${*:2}"
}

e_header "check-argv"

PAB="$root/pab"; mkrepo "$PAB" "$PERSONAL_URL"; mkrepo "$PAB/a/b" "$CUSTOMER_URL"
expect_argv 2 "$PAB" git -C a -C b push
expect_argv 2 "$C" git push
expect_argv 0 "$C" git log
expect_argv 0 "$P" git push
expect_argv 2 "$C" git -c k=v push
expect_argv 2 "$P" git -C "$C" push
assert "$(GH_REPO=example-client/x argv_rc "$P" gh pr create)" 2 "check-argv with GH_REPO in the environment"
expect_argv 0 "$C" git --namespace push log
expect_argv 2 "$P" git --git-dir=.git -C "$C/sub" push
CALIAS="$root/calias"; mkrepo "$CALIAS" "$CUSTOMER_URL"; git -C "$CALIAS" config alias.push log
expect_argv 2 "$CALIAS" git push
expect_argv 0 "$P" git commit -C HEAD --amend
expect_argv 0 "$P" git push . HEAD:main
expect_argv 0 "$C" git
expect_argv 0 "$C" git merge origin/main
expect_argv 2 "$C" git merge --continue
expect_argv 0 "$C" git rebase --abort
git -C "$CALIAS" config alias.shp '!git push'
git -C "$CALIAS" config alias.dp '-p push'
expect_argv 2 "$CALIAS" git shp
expect_argv 2 "$CALIAS" git dp
PALIAS="$root/palias"; mkrepo "$PALIAS" "$PERSONAL_URL"; git -C "$PALIAS" config alias.shp '!git push'
expect_argv 0 "$PALIAS" git shp

e_header "check-argv: push URLs"

PPU="$root/ppushurl"; mkrepo "$PPU" "$PERSONAL_URL"
git -C "$PPU" remote set-url --push origin "$CUSTOMER_URL"
expect_argv 2 "$PPU" git push
PPU2="$root/ppushurl2"; mkrepo "$PPU2" "$PERSONAL_URL"
git -C "$PPU2" remote set-url --push origin "$PERSONAL_URL"
git -C "$PPU2" remote set-url --add --push origin "$CUSTOMER_URL"
expect_argv 2 "$PPU2" git push

# --- pre-tool-use: commands ----------------------------------------------------------------------------------

# bash_json <cwd> <command> [tool]: the PreToolUse input for a shell call.
function bash_json() {
  jq -cn --arg cwd "$1" --arg cmd "$2" --arg tool "${3:-Bash}" \
    '{tool_name: $tool, cwd: $cwd, tool_input: {command: $cmd}}'
}
# hook_rc <json>: the exit status of pre-tool-use on that input.
function hook_rc() { printf '%s' "$1" | wc_run pre-tool-use 2>/dev/null; echo $?; }
# expect_bash <rc> <cwd> <command>
function expect_bash() {
  assert "$(hook_rc "$(bash_json "$2" "$3")")" "$1" "${2#"$root"/}: ${3//"$root"/<tmp>}"
}

e_header "pre-tool-use: blocked in a customer repository"

while IFS= read -r cmd; do
  expect_bash 2 "$C" "$cmd"
done <<'EOF2'
env -u GH_REPO git push
git commit -m x
git commit --amend --no-edit
git push
FOO=1 git push
git -c user.name=x commit -m y
(git push)
{ git push; }
time git push
if true; then git push; fi
true & git push
echo $(git push)
echo `git push`
bash -c "git push"
sh -lc 'cd sub && git push'
xargs -n1 git push
git status && git push
git rebase --continue
gh pr create --fill
gh pr review 1 --approve
gh api repos/o/r/issues -f title=x
gh api -X PATCH repos/o/r
gh api graphql -f query='mutation { x }'
glab mr note 1 -m x
az repos pr create --title x
gh pr update-branch 1
gh repo sync
gh workflow run ci.yml
az devops invoke --http-method POST --area git
gh api -XPOST repos/o/r/issues
git rebase --skip
git subtree push --prefix=x origin main
/usr/bin/git push
gh issue create -t x -b y
git --no-optional-locks push
git --namespace x push
git --bare commit -m x
\git push
eval git push
git --attr-source HEAD push
timeout 60 git push
timeout -s KILL 60 git push
env -i git push
nice -n 5 git push
sudo -u x git push
time -p git push
git push 2>&1 | tail -1
git push >/dev/null 2>&1
git push &>/dev/null
EOF2

expect_bash 2 "$C" "gh api repos/o/r/issues/1/comments \\
  -f body=x"
expect_bash 2 "$C" "gh api graphql -f query='
mutation { x }'"
assert "$(hook_rc "$(bash_json "$C" "git push" Monitor)")" 2 "a Monitor call is parsed like Bash"
expect_bash 2 "$C" "(cd $P && true); git push"
expect_bash 2 "$C" "git --work-tree=$P commit -m x"
CCI="$root/cci"; mkrepo "$CCI" "$CUSTOMER_URL"; git -C "$CCI" config alias.ci commit
expect_bash 2 "$CCI" "git ci -m x"

e_header "pre-tool-use: allowed in a customer repository"

while IFS= read -r cmd; do
  expect_bash 0 "$C" "$cmd"
done <<'EOF2'
git status
git add -A
git rebase origin/main
git rebase --abort
git merge origin/main
git fetch origin main
gh pr view 1
gh api repos/o/r/pulls
gh api -X GET repos/o/r/pulls -f state=open
gh api repos/o/r/pulls | grep -F x
gh api graphql -f query='{ viewer { login } }'
echo "git push"
ls
gh pr create -R andrelin/x
gh pr create -R github.com/andrelin/x
gh pr checks 1
az vm list
az group create -n x -l y
az devops invoke --area git --resource repositories
az repos pr list
EOF2

CNEST="$root/cnest"; mkrepo "$CNEST" "$CUSTOMER_URL"; mkrepo "$CNEST/sub" "$PERSONAL_URL"
expect_bash 0 "$CNEST" "git -C sub push"

e_header "pre-tool-use: blocked from a personal repository"

PUP="$root/pup"; mkrepo "$PUP" "$PERSONAL_URL"; git -C "$PUP" remote add upstream "$CUSTOMER_GL_URL"
PBR="$root/pbranch"; mkrepo "$PBR" "$PERSONAL_URL"; git -C "$PBR" remote add upstream "$CUSTOMER_GL_URL"
git -C "$PBR" config "branch.$(git -C "$PBR" symbolic-ref --short HEAD).remote" upstream
PPD="$root/ppushdefault"; mkrepo "$PPD" "$PERSONAL_URL"; git -C "$PPD" remote add upstream "$CUSTOMER_GL_URL"
git -C "$PPD" config remote.pushDefault upstream

expect_bash 2 "$P" "pushd $C && popd && git push"
expect_bash 2 "$P" "env -C $C git push"
expect_bash 2 "$P" "git -C $C push"
expect_bash 2 "$P" "cd $C && git commit -m x"
expect_bash 2 "$P" 'cd "$UNSET_X" && git commit -m x'
push_customers --off
expect_bash 0 "$P" 'cd "$UNSET_X" && git commit -m x'
pop_customers
expect_bash 2 "$P" "cd - && git push"
expect_bash 2 "$P" "gh pr create -R example-client/x"
expect_bash 2 "$P" "GH_REPO=example-client/x gh pr create"
expect_bash 2 "$PUP" "git push upstream"
expect_bash 2 "$PUP" "gh pr create"
expect_bash 2 "$P" "GIT_DIR=$C/.git git push"
expect_bash 2 "$P" "git --git-dir=$C/.git commit -m x"
expect_bash 2 "$P" "git --git-dir $C/.git push"
expect_bash 2 "$P" "git --work-tree $C --git-dir $C/.git commit -m x"
expect_bash 2 "$P" "git --work-tree=$C --git-dir=$C/.git push"
expect_bash 2 "$P" "cd $C && GIT_DIR=.git git commit -m x"
expect_bash 2 "$P" "git push $CUSTOMER_GL_URL main"
expect_bash 2 "$PBR" "git push"
expect_bash 2 "$PPD" "git push"

e_header "pre-tool-use: allowed in a personal repository"

mkrepo "$root/home-rel/p" "$PERSONAL_URL"
while IFS= read -r cmd; do
  expect_bash 0 "$P" "$cmd"
done <<'EOF2'
git commit -m x
git push
gh pr merge 1
cd "$(git rev-parse --show-toplevel)" && git commit -m x
cd ~/home-rel/p && git push
git -C . push
git push 2>&1 | tail -1
git push >/dev/null 2>&1
git push &>/dev/null
gh pr view https://github.com/example-client/x/pull/1
gh api -X POST repos/andrelin/x/issues -f title=x
gh api -X POST 'repos/{owner}/{repo}/issues' -f title=x
gh pr create --title x --body "see https://github.com/example-client/x/issues/1"
gh issue comment 1 -b https://github.com/example-client/x/issues/2
gh pr create --title x --body "a | b; c"
gh issue close https://github.com/uptimeconsulting/x/issues/3
EOF2

e_header "pre-tool-use: targets named in arguments, from a personal repository"

while IFS= read -r cmd; do
  expect_bash 2 "$P" "$cmd"
done <<'EOF2'
gh pr comment https://github.com/example-client/x/pull/1 -b x
gh issue close https://github.com/example-client/x/issues/3
gh repo delete example-client/x --yes
gh api -X POST repos/example-client/x/issues/1/comments -f body=x
glab api -X POST projects/123/issues
gh api -X PATCH repos/example-client/x -f private=true
gh api -X DELETE repos/example-client/x
glab api -X PUT projects/123
glab api -X POST projects/example-client%2Fx/issues
EOF2

e_header "pre-tool-use: pushing to a path or a named remote"

mkrepo "$root/sib-customer" "$CUSTOMER_URL"
mkrepo "$root/sib-personal" "$PERSONAL_URL"
expect_bash 2 "$P" "git push ../sib-customer main"
expect_bash 0 "$P" "git push ../sib-personal main"
PWEB="$root/pweb"; mkrepo "$PWEB" "$PERSONAL_URL"; git -C "$PWEB" remote add website "$CUSTOMER_URL"
mkdir -p "$PWEB/website"
expect_bash 2 "$PWEB" "git push website"

e_header "pre-tool-use: the company repository"

# Company is not guarded (changed by the user on 2026-10-16): only a customer target blocks.
while IFS= read -r cmd; do
  expect_bash 0 "$CO" "$cmd"
done <<'EOF2'
gh issue create -t x -b y
gh issue comment 1 -b x
gh pr create --fill
git commit -m x
git push
gh pr merge 1
gh label list
glab label list
gh issue create -R ghe.example.com/uptimeconsulting/x -t x
GH_HOST=ghe.example.com gh issue create -t x
gh pr create -R uptimeconsulting/y
EOF2
expect_bash 2 "$CO" "export GH_REPO=example-client/x && gh issue create -t x"
expect_bash 2 "$CO" "gh issue create -R example-client/x -t x"
expect_bash 2 "$CO" "gh issue create -Rexample-client/x -t x"
expect_bash 2 "$CO" "glab issue create -R example-client/sub/x -t x"
expect_bash 2 "$CO" "git push $CUSTOMER_GL_URL main"
expect_bash 2 "$CO" "gh pr create -R example-client/x"
expect_bash 2 "$C" "gh issue create -R uptimeconsulting/y -t x"
COUP="$root/coup"; mkrepo "$COUP" "$COMPANY_URL"; git -C "$COUP" remote add upstream "$CUSTOMER_URL"
expect_bash 2 "$COUP" "gh issue create -t x"
expect_bash 2 "$COUP" "gh pr create --fill"
COGH="$root/cogh"; mkrepo "$COGH" "$COMPANY_URL"; git -C "$COGH" remote add github "$CUSTOMER_URL"
expect_bash 2 "$COGH" "gh issue create -t x"
CORES="$root/cores"; mkrepo "$CORES" "$COMPANY_URL"; git -C "$CORES" remote add cust "$CUSTOMER_URL"
git -C "$CORES" config remote.cust.gh-resolved base
expect_bash 2 "$CORES" "gh issue create -t x"
COGL="$root/cogl"; mkrepo "$COGL" git@gitlab.com:uptimeconsulting/x.git
expect_bash 0 "$COGL" "glab issue create -t x"
expect_bash 0 "$COGL" "git push"
assert "$(GH_HOST=ghe.example.com argv_rc "$CO" gh issue create -t x)" 0 "check-argv on company with GH_HOST set"
assert "$(argv_rc "$CO" git push)" 0 "check-argv git push on company"

PRES="$root/pres"; mkrepo "$PRES" "$PERSONAL_URL"; git -C "$PRES" remote add cust "$CUSTOMER_URL"
git -C "$PRES" config remote.cust.gh-resolved base
expect_bash 2 "$PRES" "gh pr create"
expect_bash 0 "$PRES" "gh pr create -R andrelin/x"

e_header "pre-tool-use: environment"

assert "$(GH_REPO=example-client/x hook_rc "$(bash_json "$P" "gh pr create")")" 2 "GH_REPO in the hook's environment"
assert "$(GH_REPO=example-client/x hook_rc "$(bash_json "$P" "unset GH_REPO; gh pr create")")" 0 \
  "unset clears an inherited GH_REPO"
expect_bash 2 "$P" "env GH_REPO=example-client/x gh pr create"
expect_bash 0 "$P" "export GH_REPO=example-client/x; unset GH_REPO; gh pr create"
expect_bash 2 "$P" "export GH_REPO=example-client/x; gh pr create"
expect_bash 0 "$P" "export GH_REPO; gh pr create"

e_header "pre-tool-use: fail closed"

assert "$(hook_rc "not json git")" 2 "input that isn't JSON"
nojq="$root/nojq"; mkdir -p "$nojq"
ln -s "$(command -v git)" "$nojq/git"; ln -s /bin/bash "$nojq/bash"
function nojq_hook() { printf '%s' "$1" | PATH="$nojq" /bin/bash "$SCRIPT" pre-tool-use; }
assert "$(nojq_hook "$(bash_json "$P" "git push")" 2>/dev/null; echo $?)" 2 "without jq, a git call blocks"
assert "$(nojq_hook "$(bash_json "$P" "git push")" 2>&1 >/dev/null | grep -c jq)" 1 "and names jq"
assert "$(nojq_hook "$(bash_json "$P" "ls
git push")" 2>/dev/null; echo $?)" 2 "without jq, a git call on a second line blocks"
assert "$(nojq_hook "$(bash_json "$P" "ls")" 2>/dev/null; echo $?)" 0 "without jq, a call naming no tool passes"

# --- issue-filing marker -------------------------------------------------------------------------------------

e_header "marker: issue create under .claude-files-issues"

M="$root/mtree"; mkdir -p "$M"; : > "$M/.claude-files-issues"
MGL="$M/gl";   mkrepo "$MGL" "$CUSTOMER_GL_URL"
MGH="$M/gh";   mkrepo "$MGH" "$CUSTOMER_URL"
MUP="$M/glup"; mkrepo "$MUP" "$CUSTOMER_GL_URL"; git -C "$MUP" remote add upstream git@gitlab.com:example-client/y.git
MGHE="$M/ghe"; mkrepo "$MGHE" git@ghe.example.com:example-client/x.git
MGLE="$M/gle"; mkrepo "$MGLE" git@gitlab.example.com:example-client/x.git
MAZ="$M/az";   mkrepo "$MAZ" https://dev.azure.com/example-client/p/_git/r
MNO="$M/noorigin"; mkrepo "$MNO"

expect_bash 0 "$MGL" "glab issue create -t x"
expect_bash 2 "$MGL" "glab issue create -R example-client/y -t x"
expect_bash 2 "$MGL" "glab mr create"
expect_bash 2 "$MGL" "glab issue comment 1 -m x"
expect_bash 2 "$MUP" "glab issue create -t x"
expect_bash 0 "$MGH" "gh issue create -t x"
expect_bash 2 "$MGH" "gh issue create -R example-client/y -t x"
expect_bash 2 "$MGHE" "gh issue create -t x"
expect_bash 2 "$MGL" "GITLAB_HOST=gitlab.example.com glab issue create -t x"
expect_bash 2 "$MGL" "GL_HOST=gitlab.example.com glab issue create -t x"
expect_bash 2 "$MGL" "GITLAB_URI=gitlab.example.com glab issue create -t x"
expect_bash 0 "$MGL" "GITLAB_HOST=gitlab.com glab issue create -t x"
expect_bash 2 "$MGL" "GITLAB_REPO=example-client/y glab issue create -t x"

M2="$root/mtree2"; MHOME="$M2/gl"; mkrepo "$MHOME" "$CUSTOMER_GL_URL"
: > "$root/.claude-files-issues"
expect_bash 2 "$MHOME" "glab issue create -t x"
rm "$root/.claude-files-issues"
MTOP="$root/mtree3/gl"; mkrepo "$MTOP" "$CUSTOMER_GL_URL"; : > "$MTOP/.claude-files-issues"
expect_bash 2 "$MTOP" "glab issue create -t x"

# --- can-file-issue ------------------------------------------------------------------------------------------

e_header "can-file-issue"

PFORK="$root/pfork"; mkrepo "$PFORK" "$PERSONAL_URL"; git -C "$PFORK" remote add upstream "$CUSTOMER_URL"
assert "$(wc_run can-file-issue "$P")" gh "personal"
assert "$(wc_run can-file-issue "$CO")" gh "company on GitHub"
assert "$(wc_run can-file-issue "$COGL")" glab "company on GitLab"
assert "$(wc_run can-file-issue "$COUP")" none "company with a customer upstream"
assert "$(wc_run can-file-issue "$C")" none "customer"
assert "$(wc_run can-file-issue "$MGL")" glab "GitLab under a marker"
assert "$(wc_run can-file-issue "$MGLE")" glab "a GitLab-named host under a marker"
assert "$(wc_run can-file-issue "$MGHE")" none "GitHub Enterprise under a marker"
assert "$(wc_run can-file-issue "$MAZ")" none "Azure under a marker"
assert "$(wc_run can-file-issue "$MGH")" gh "github.com under a marker"
assert "$(wc_run can-file-issue "$PFORK")" none "a personal fork of a customer repo"
assert "$(wc_run can-file-issue "$MNO")" none "no origin"
assert "$(wc_run can-file-issue "$root/not-a-repo")" none "not a repository"

# A stub fj with a login for forgejo.example.com, so only that host counts as Forgejo.
mkdir -p "$root/fjbin"
printf '#!/bin/sh\n[ "$1 $2" = "auth list" ] && echo forgejo.example.com\n' > "$root/fjbin/fj"
chmod +x "$root/fjbin/fj"
FJ="$root/fj-co"; mkrepo "$FJ" git@forgejo.example.com:uptimeconsulting/x.git
FJC="$root/fj-cust"; mkrepo "$FJC" git@forgejo.example.com:example-client/x.git
FJUP="$root/fj-coup"; mkrepo "$FJUP" git@forgejo.example.com:uptimeconsulting/x.git
git -C "$FJUP" remote add upstream "$CUSTOMER_URL"
FJX="$root/fj-other"; mkrepo "$FJX" git@git.example.org:uptimeconsulting/x.git
assert "$(PATH="$root/fjbin:$PATH" wc_run can-file-issue "$FJ")" fj "company on a Forgejo host fj is logged in to"
assert "$(PATH="$root/fjbin:$PATH" wc_run can-file-issue "$FJC")" none "customer on Forgejo"
assert "$(PATH="$root/fjbin:$PATH" wc_run can-file-issue "$FJUP")" none "company on Forgejo with a customer upstream"
assert "$(PATH="$root/fjbin:$PATH" wc_run can-file-issue "$FJX")" none "company on a host fj has no login for"

# --- session-start -------------------------------------------------------------------------------------------

e_header "session-start"

# session_context <cwd>: the additionalContext text, or INVALID when the output isn't the hook's JSON shape.
function session_context() {
  jq -cn --arg cwd "$1" '{hook_event_name: "SessionStart", cwd: $cwd}' | wc_run session-start |
    jq -er '.hookSpecificOutput.additionalContext' 2>/dev/null || echo INVALID
}
# mentions <text>: which of "blocked" and "issue create" the text holds.
function mentions() {
  local out=""
  [[ "$1" == *blocked* ]] && out+="blocked "
  [[ "$1" == *"issue create"* ]] && out+="issue-create"
  echo "${out:-none}"
}
assert "$(mentions "$(session_context "$C")")" "blocked " "customer"
assert "$(mentions "$(session_context "$root/noorigin")")" "none" "no origin outside scratch"
assert "$(mentions "$(session_context "$P")")" "none" "personal"
assert "$(mentions "$(session_context "$CO")")" "none" "company"
assert "$(mentions "$(session_context "$COUP")")" "none" "company with a customer upstream"
assert "$(mentions "$(session_context "$MGL")")" "blocked issue-create" "customer under a marker"
[[ "$(session_context "$CO")" == *"Work context: company"* ]] && e_success "company is named" ||
  e_error "company is named"
[[ "$(session_context "$MGH")" == *"gh issue create"* ]] && e_success "a GitHub marker repo names gh issue create" ||
  e_error "a GitHub marker repo names gh issue create"
[[ "$(session_context "$root/not-a-repo")" == *"no git repository"* ]] && e_success "non-repo says so" ||
  e_error "non-repo says so"

# The Bash tool's PATH comes from a shell snapshot, so the shims reach it only through CLAUDE_ENV_FILE.
env_file="$root/claude-env"
: > "$env_file"
CLAUDE_ENV_FILE="$env_file" session_context "$P" >/dev/null
assert "$(cat "$env_file")" "" "without a shims dir the env file is untouched"
mkdir -p "$HOME/.claude/shims"
CLAUDE_ENV_FILE="$env_file" session_context "$P" >/dev/null
CLAUDE_ENV_FILE="$env_file" session_context "$C" >/dev/null
assert "$(PATH=/usr/bin:/bin; source "$env_file"; echo "$PATH")" "$HOME/.claude/shims:/usr/bin:/bin" \
  "the env file puts the shims first on PATH, once however often it runs"
assert "$(PATH=/usr/bin:/bin; source "$env_file"; source "$env_file"; echo "$PATH")" \
  "$HOME/.claude/shims:/usr/bin:/bin" "sourcing the env file twice adds the shims once"
assert "$(session_context "$P" | wc -l | tr -d ' ')" "1" "without CLAUDE_ENV_FILE nothing else changes"
rmdir "$HOME/.claude/shims"

# --- deny message --------------------------------------------------------------------------------------------

e_header "deny message"

deny="$(printf '%s' "$(bash_json "$C" "git push")" | wc_run pre-tool-use 2>&1 >/dev/null)"
[[ "$deny" == *"$C is customer work"* ]] && e_success "names the directory and level" ||
  e_error "names the directory and level: $deny"
[[ "$deny" == *"! cd $C && git push"* ]] && e_success "offers the plain command" ||
  e_error "offers the plain command: $deny"
mkdir -p "$HOME/.claude/shims"
deny="$(printf '%s' "$(bash_json "$C" "git push")" | wc_run pre-tool-use 2>&1 >/dev/null)"
[[ "$deny" == *"! cd $C && WORK_CONTEXT_WAIVE=1 git push"* ]] && e_success "offers the waiver once shims exist" ||
  e_error "offers the waiver once shims exist: $deny"
rmdir "$HOME/.claude/shims"
deny="$(printf '%s' "$(bash_json "$P" "git -C $C push")" | wc_run pre-tool-use 2>&1 >/dev/null)"
[[ "$deny" == *"! cd $C && git push"* ]] && e_success "folds a global -C into the directory" ||
  e_error "folds a global -C into the directory: $deny"

# --- marker guard --------------------------------------------------------------------------------------------

e_header "marker guard"

# file_json <tool> <path-key> <path> [content-key content]
function file_json() {
  jq -cn --arg tool "$1" --arg key "$2" --arg path "$3" --arg ckey "${4:-content}" --arg c "${5:-}" \
    '{tool_name: $tool, cwd: "/", tool_input: ({($key): $path} + {($ckey): $c})}'
}
mark="$root/t/.claude-files-issues"
assert "$(hook_rc "$(file_json Write file_path "$mark")")" 2 "Write of the marker"
assert "$(hook_rc "$(file_json Write file_path "$root/t/other")")" 0 "Write of another file"
assert "$(hook_rc "$(file_json Edit file_path "$mark" new_string x)")" 2 "Edit of the marker"
assert "$(hook_rc "$(file_json NotebookEdit notebook_path "$mark" new_source x)")" 2 "NotebookEdit of the marker"
expect_bash 2 "$P" "touch $mark"
expect_bash 2 "$P" "echo x > $mark"
expect_bash 2 "$P" "cp /dev/null $mark"
expect_bash 2 "$P" "printf x >\"$mark\""
expect_bash 2 "$P" "sudo touch $mark"
expect_bash 0 "$P" "ls $mark"
expect_bash 0 "$P" "grep -r claude-files-issues ."
assert "$(nojq_hook "$(file_json Write file_path "$mark")" 2>/dev/null; echo $?)" 2 "without jq, a marker write blocks"

head -c 5000000 /dev/zero | tr '\0' a > "$root/big"
jq -cn --rawfile c "$root/big" --arg p "$root/t/big.txt" \
  '{tool_name: "Write", cwd: "/", tool_input: {file_path: $p, content: $c}}' > "$root/big.json"
start=$EPOCHREALTIME
rc="$(wc_run pre-tool-use < "$root/big.json" 2>/dev/null; echo $?)"
elapsed=$(( (${EPOCHREALTIME/./} - ${start/./}) / 1000 ))
assert "$rc" 0 "a 5 MB Write passes"
(( elapsed < 2000 )) && e_success "in under 2 seconds (${elapsed} ms)" || e_error "in under 2 seconds (${elapsed} ms)"

# --- customers file guard -----------------------------------------------------------------------------------

e_header "customers file guard"

# Removing a line from the customers file loosens the guard, so only the user writes it too.
custs="$HOME/.claude-customers"
assert "$(hook_rc "$(file_json Write file_path "$custs")")" 2 "Write of the customers file"
assert "$(hook_rc "$(file_json Edit file_path "$custs" new_string x)")" 2 "Edit of the customers file"
assert "$(hook_rc "$(file_json Write file_path "$root/t/customers")")" 0 "Write of a file merely like it"
expect_bash 2 "$P" "echo github.com/example-client >> $custs"
expect_bash 2 "$P" "printf x >\"$custs\""
expect_bash 2 "$P" "tee -a $custs < /dev/null"
expect_bash 2 "$P" "cp /dev/null $custs"
expect_bash 2 "$P" "sed -i '' 1d $custs"
expect_bash 2 "$P" "rm $custs"
expect_bash 2 "$P" "rm -f $custs"
expect_bash 2 "$P" "unlink $custs"
expect_bash 2 "$P" "chmod 000 $custs"
expect_bash 2 "$P" "trash $custs"
expect_bash 2 "$P" "srm $custs"
expect_bash 2 "$P" "ed $custs"
expect_bash 2 "$P" "ex $custs"
expect_bash 2 "$P" "echo x >| $custs"
expect_bash 2 "$P" "echo x 1>|$custs"
expect_bash 2 "$P" "find $root -maxdepth 1 -name .claude-customers -exec rm {} \\;"
deny="$(printf '%s' "$(file_json Write file_path "$custs")" | wc_run pre-tool-use 2>&1 >/dev/null)"
[[ "$deny" == *'! echo'*'>> ~/.claude-customers'* ]] && e_success "the denial gives the user the command" ||
  e_error "the denial gives the user the command: $deny"
expect_bash 0 "$P" "cat $custs"
assert "$(nojq_hook "$(file_json Write file_path "$custs")" 2>/dev/null; echo $?)" 2 "without jq, a customers-file write blocks"

# A listed customer repo is customer to check-argv too, which the shims call.
push_customers
printf '%s\n' 'dev.azure.com/example-acquired' >> "$HOME/.claude-customers"
expect_argv 2 "$root/orgs/1" git push
pop_customers
expect_argv 0 "$root/orgs/1" git push

# --- customers file: entry forms and repository locations ---------------------------------------------------

e_header "customers file: entry forms and repository locations"

push_customers
mkdir -p "$root/abs-cust/sub" "$root/clients/rel-x/sub" "$root/home-cust/sub" "$root/web#2/sub"
mkrepo "$root/ssh-azure" "git@ssh.dev.azure.com:v3/example-sshco/p/r"
mkrepo "$root/ssh-url" "https://dev.azure.com/example-sshurl/p/_git/r"
mkrepo "$root/url-cust" "git@github.com:example-urlco/x.git"
mkrepo "$root/gitat-cust" "git@github.com:example-gitatco/x.git"
mkrepo "$root/uptime-listed" "git@github.com:uptimeconsulting/listed.git"
# shellcheck disable=SC2088 # entries as the user writes them, for the guard to expand
printf '%s\n' "$root/abs-cust" 'clients/rel-x   # relative to HOME' '$HOME/home-cust' 'ssh.dev.azure.com/example-sshco' \
  'https://github.com/example-urlco' 'git@github.com:example-gitatco.git' '~/web#2' 'github.com/uptimeconsulting' \
  'git@ssh.dev.azure.com:v3/example-sshurl/p/r' \
  >> "$HOME/.claude-customers"
assert "$(wc_run level "$root/abs-cust/sub")" "customer" "an absolute directory entry"
assert "$(wc_run level "$root/clients/rel-x/sub")" "customer" "a path entry without a dot is relative to HOME"
assert "$(wc_run level "$root/home-cust/sub")" "customer" "a \$HOME directory entry"
assert "$(wc_run level "$root/ssh-azure")" "customer" "an ssh. host entry"
assert "$(wc_run level "$root/ssh-url")" "customer" "an Azure DevOps SSH URL entry, v3 skipped"
assert "$(wc_run level "$root/url-cust")" "customer" "an https URL entry"
assert "$(wc_run level "$root/gitat-cust")" "customer" "a git@ URL entry"
assert "$(wc_run level "$root/web#2/sub")" "customer" "a # inside an entry is not a comment"
assert "$(wc_run level "$root/uptime-listed")" "customer" "a listed owner wins over the company org"
reset_customers

printf '%s\n' 'Fjordvik Kraftlag' 'FVK' 'Ærøby' >> "$HOME/.claude-customers"

# A repo is customer by its own location, however a command reaches it.
mkdir -p "$root/norepo-home"
CREPO="$root/custtree/repo"; mkrepo "$CREPO" "$COMPANY_URL"
REAL_GIT=$(type -ap git | grep -v '/shims/' | head -n 1)
"$REAL_GIT" -C "$CREPO" -c user.name=t -c user.email=t@example.com commit -q --allow-empty -m init
"$REAL_GIT" -C "$CREPO" worktree add -q "$root/outside-wt"
[[ -e "$root/outside-wt/.git" ]] && e_success "the outside worktree exists" || e_error "the outside worktree exists"
mkdir -p "$root/plain"
expect_bash 2 "$CREPO" "git push"
expect_bash 2 "$CREPO" "gh pr create"
expect_bash 2 "$root/plain" "git --git-dir=$CREPO/.git commit -m x"
expect_bash 2 "$root/plain" "GIT_DIR=$CREPO/.git git commit -m x"
assert "$(wc_run level "$root/outside-wt")" "customer" "a linked worktree outside the customer tree"
expect_argv 2 "$root/outside-wt" git commit -m x
mkrepo "$root/work/fvk-gh" "$COMPANY_URL"
expect_bash 2 "$root/work/fvk-gh" "git push"
mkrepo "$root/mine/lib/fvk" "$COMPANY_URL"; rm -rf "$root/mine/lib/fvk/.git"; mkrepo "$root/mine" "$COMPANY_URL"
assert "$(wc_run level "$root/mine/lib/fvk")" "company" "a name on a subfolder inside a company repo"

# Names only mark folders below HOME: a scratch path outside it never becomes customer.
OUT="$(mktemp -d)"; mkrepo "$OUT/-Users-x-src-fjordvik-kraftlag-app/scratchpad/r"
assert "$(wc_run level "$OUT/-Users-x-src-fjordvik-kraftlag-app/scratchpad/r")" "company" "a name outside HOME"
rm -rf "$OUT"

# Nordic letters match with or without their ASCII spelling.
mkdir -p "$root/work/ærøby-app" "$root/work/aeroby-tools" "$root/work/b-tools"
assert "$(wc_run level "$root/work/ærøby-app")" "customer" "a name with æ and ø"
assert "$(wc_run level "$root/work/aeroby-tools")" "customer" "the ASCII spelling of a Nordic name"
assert "$(wc_run level "$root/work/b-tools")" "company" "a Nordic name does not shrink to a stray letter"

# Forgejo issue filing respects listed folders.
FJCUST="$root/custtree/fj"; mkrepo "$FJCUST" git@forgejo.example.com:uptimeconsulting/x.git
FJNAMED="$root/work/fvk-fj"; mkrepo "$FJNAMED" git@forgejo.example.com:uptimeconsulting/x.git
assert "$(PATH="$root/fjbin:$PATH" wc_run can-file-issue "$FJCUST")" none "Forgejo in a listed customer directory"
assert "$(PATH="$root/fjbin:$PATH" wc_run can-file-issue "$FJNAMED")" none "Forgejo in a folder named for a customer"

# fj: anything but a known read is a write, judged by the directory it runs in.
expect_bash 2 "$C" "fj issue create x --body y"
expect_bash 2 "$C" "fj pr create x"
expect_bash 2 "$P" "fj -C $C issue comment 1 x"
expect_bash 0 "$C" "fj issue view 1"
expect_bash 0 "$C" "fj -H forgejo.example.com issue search x"
expect_bash 0 "$CO" "fj pr create x"
expect_argv 2 "$C" fj issue create x

# A lone ~ lists the whole home directory; a remote that is a missing local path is the user's own.
push_customers; printf '%s\n' '~' >> "$HOME/.claude-customers"
assert "$(wc_run level "$root/norepo-home")" "customer" "a lone ~ entry"
pop_customers
mkrepo "$root/localorigin" "../no-such-dir"
assert "$(wc_run level "$root/localorigin")" "company" "an origin that is a missing local path"

# Targets the guard cannot resolve fail closed only while a customer is listed.
mkdir -p "$root/norepo"
expect_bash 2 "$P" 'git push "$UNSET_R" main'
expect_bash 2 "$P" "cd - && git push"
push_customers --off
expect_bash 0 "$P" 'git push "$UNSET_R" main'
expect_bash 0 "$P" "cd - && git push"
expect_bash 0 "$root/norepo" "gh pr create"
expect_bash 0 "$root/norepo" "az repos pr create"
expect_bash 0 "$P" "gh pr create -R foo"
assert "$(wc_run level "$root/norepo")" "company" "a non-repo folder with no customers file"
printf '%s\n' '# only comments' '   ' > "$HOME/.claude-customers"
expect_bash 0 "$P" 'cd "$UNSET_X" && git commit -m x'
pop_customers
pop_customers

# --- customers file: URL forms, case, boundaries and fj -------------------------------------------------------

e_header "customers file: URL forms, case, boundaries and fj"

push_customers
# shellcheck disable=SC2088 # entries as the user writes them, for the guard to expand
printf '%s\n' 'ssh://git@forgejo.example.com:2222/example-port/x.git' 'forgejo@code.example.com:example-scp/r.git' \
  'host.example.org' '${HOME}/brace-cust' '~/trail-cust/' '~other' '"$HOME/quoted-cust"' '.work/hidden-cust' \
  '~/MixedCase' 'Sundstrøm' 'Åsen' 'Abcd' 'Abcde' 'FVK' >> "$HOME/.claude-customers"
mkrepo "$root/port-cust" "https://forgejo.example.com/example-port/x.git"
mkrepo "$root/scp-cust" "ssh://forgejo@code.example.com:22/example-scp/r.git"
mkrepo "$root/host-cust" "git@host.example.org:anyone/x.git"
mkdir -p "$root/brace-cust/s" "$root/trail-cust/s" "$root/quoted-cust/s" "$root/.work/hidden-cust/s" "$root/mixedcase/s" \
  "$root/work/sundstroem-app" "$root/work/aasen-api" "$root/work/xabcdx" "$root/work/xabcdex"
assert "$(wc_run level "$root/port-cust")" "customer" "a URL entry with a port"
assert "$(wc_run level "$root/scp-cust")" "customer" "an scp entry with a user other than git"
assert "$(wc_run level "$root/host-cust")" "customer" "a bare host covers every owner"
assert "$(wc_run level "$root/brace-cust/s")" "customer" "a \${HOME} entry"
assert "$(wc_run level "$root/trail-cust/s")" "customer" "a directory entry with a trailing slash"
assert "$(wc_run level "$root/quoted-cust/s")" "customer" "a quoted entry"
assert "$(wc_run level "$root/.work/hidden-cust/s")" "customer" "a relative path under a hidden folder"
assert "$(wc_run level "$root/mixedcase/s")" "customer" "a directory entry in another letter case"
assert "$(wc_run level "$root/work/sundstroem-app")" "customer" "ø spelled oe"
assert "$(wc_run level "$root/work/aasen-api")" "customer" "å spelled aa"
assert "$(wc_run level "$root/work/xabcdx")" "company" "a four-letter name inside a word"
assert "$(wc_run level "$root/work/xabcdex")" "customer" "a five-letter name inside a word"

# Session start names a listed folder.
assert "$(mentions "$(session_context "$root/brace-cust/s")")" "blocked " "session start in a listed folder"
[[ "$(session_context "$root/brace-cust/s")" == *"a listed customer folder"* ]] && e_success "session start says why" ||
  e_error "session start says why"

# A listed directory that is a subfolder of an unlisted repo counts where a command runs in it.
mkrepo "$root/outer" "$COMPANY_URL"; mkdir -p "$root/outer/clientdir"
printf '%s\n' "$root/outer/clientdir" >> "$HOME/.claude-customers"
expect_bash 2 "$root/outer/clientdir" "git commit -m x"
expect_bash 0 "$root/outer" "git commit -m x"

# A name on a subfolder of a company repo does not make commands there customer work.
mkrepo "$root/site" "$COMPANY_URL"; mkdir -p "$root/site/docs/fvk-case"
expect_bash 0 "$root/site/docs/fvk-case" "git commit -m x"

# Protected-file variants.
expect_bash 2 "$P" "chflags uchg ~/.claude-customers"
expect_bash 2 "$P" "xattr -c ~/.claude-customers"
expect_bash 2 "$P" "rm ~/.claude-cust*"
expect_bash 2 "$P" "find ~ -maxdepth 1 -name .claude-customers -delete"
expect_bash 2 "$P" "shred -u ~/.claude-customers"
assert "$(hook_rc "$(file_json Write file_path "$HOME/.Claude-Customers")")" 2 "Write of the file in another letter case"

# fj: option forms and relative -C, and the no-jq fallback.
expect_bash 2 "$P" "fj --cwd $C issue create x"
expect_bash 2 "$P" "fj --cwd=$C issue create x"
expect_bash 2 "$P" "fj -C$C issue create x"
expect_bash 2 "$C" "fj -C $P issue create x"
expect_bash 2 "$root" "cd customer && fj -C . issue create x"
expect_bash 0 "$C" "fj -R origin issue view 1"
expect_bash 0 "$C" "fj"
assert "$(nojq_hook "$(bash_json "$P" "fj issue create x")" 2>/dev/null; echo $?)" 2 "without jq, an fj call blocks"

# An unexpanded push target is unresolved; glab's numeric project endpoint passes when nobody is listed.
expect_bash 2 "$P" 'git push "$DIR/repo" main'
push_customers --off
expect_bash 0 "$P" "glab api -X POST projects/123/issues"
pop_customers
pop_customers

# --- customers file: repo flags, remotes and owners -----------------------------------------------------------

e_header "customers file: repo flags, remotes, owners and globs"

push_customers
printf '%s\n' 'Fjordvik Kraftlag' 'FVK' 'Ærøby' 'Havbris.example' '~someone' >> "$HOME/.claude-customers"

# A repo flag or variable from inside a listed folder is still customer work.
FLAGREPO="$root/work/fvk-flags"; mkrepo "$FLAGREPO" "git@github.com:somebody/portal.git"
expect_bash 2 "$FLAGREPO" "gh pr merge 5 -R somebody/portal"
expect_bash 2 "$FLAGREPO" "GH_REPO=somebody/portal gh pr merge 5"
expect_bash 2 "$FLAGREPO" "glab mr merge 5 -R somebody/portal"
# And from a directory the guard can't resolve, which could be a listed one.
expect_bash 2 "$P" 'cd "$UNSET_X" && gh pr merge 5 -R somebody/portal'
expect_bash 2 "$P" "cd - && gh pr merge 5 -R somebody/portal"

# A userless scp-style entry names its owner, not its repo.
printf '%s\n' 'github.com:scp-owner/app.git' >> "$HOME/.claude-customers"
mkrepo "$root/scp/owner" "git@github.com:scp-owner/other.git"
mkrepo "$root/scp/repo" "git@github.com:app/x.git"
assert "$(wc_run level "$root/scp/owner")" "customer" "a userless scp entry covers its owner"
assert "$(wc_run level "$root/scp/repo")" "company" "and not an owner named like its repo"
# A port after the host is a port, never an owner.
printf '%s\n' 'git.portco.example:2222' 'git.portteam.example:2222/team-p' >> "$HOME/.claude-customers"
mkrepo "$root/port/host" "ssh://git@git.portco.example:2222/anyone/app.git"
mkrepo "$root/port/team" "ssh://git@git.portteam.example:2222/team-p/app.git"
mkrepo "$root/port/other" "ssh://git@git.portteam.example:2222/other/app.git"
assert "$(wc_run level "$root/port/host")" "customer" "host:port is the whole host"
assert "$(wc_run level "$root/port/team")" "customer" "host:port/owner is that owner"
assert "$(wc_run level "$root/port/other")" "company" "and not another owner on the host"

# fj --repo is judged on the -H host, or else origin's.
expect_bash 2 "$P" "fj -H forgejo.example.com issue create x --repo example-client/r"
expect_bash 2 "$P" "fj -H https://forgejo.example.com issue close 3 --repo=example-client/r"
expect_bash 0 "$P" "fj -H forgejo.example.com issue create x --repo someone/r"
# An fj -C or push target the guard can't resolve could be a listed customer's.
expect_bash 2 "$P" 'fj -C "$UNSET_F" issue create x'
expect_bash 2 "$P" 'fj --cwd="$UNSET_F" issue create x'
expect_bash 2 "$P" 'git push https://github.com/`echo example-client`/x main'

# A bare or separate git dir in a named folder, from a folder that isn't customer work.
"$REAL_GIT" init -q --bare "$root/work/fvk.git"
expect_bash 2 "$root/plain" "git --git-dir=$root/work/fvk.git push"

# Accented names, single-quoted entries and a bare $HOME.
printf '%s\n' 'Médica' "'~/sq-cust'" >> "$HOME/.claude-customers"
mkdir -p "$root/work/medica-app" "$root/sq-cust/s"
assert "$(wc_run level "$root/work/medica-app")" "customer" "an accented name matches its ASCII spelling"
assert "$(wc_run level "$root/sq-cust/s")" "customer" "a single-quoted entry"
for h in '$HOME' '${HOME}'; do
  push_customers
  printf '%s\n' "$h" >> "$HOME/.claude-customers"
  assert "$(wc_run level "$root/not-a-repo")" "customer" "a bare $h entry covers all of HOME"
  pop_customers
done

# An unreadable customers file is reported; root reads it anyway, so the case needs another user.
if (( EUID != 0 )); then
  chmod 000 "$HOME/.claude-customers"
  ctx=$(session_context "$P")
  chmod 644 "$HOME/.claude-customers"
  [[ "$ctx" == *"can't be read"* ]] && e_success "session start reports an unreadable file" ||
    e_error "session start reports an unreadable file: $ctx"
fi

# The customers file in another letter case, and a find pattern that reaches it without a leading dot.
expect_bash 2 "$P" "rm ~/.Claude-Customers"
expect_bash 2 "$P" "unlink $HOME/.CLAUDE-CUSTOMERS"
expect_bash 2 "$P" "find ~ -maxdepth 1 -name '*customers' -delete"
expect_bash 0 "$P" "find build -name '*' -delete"
expect_bash 0 "$P" "find build -name '*.log' -delete"

# A git dir the guard can't expand could be a listed customer's.
mkrepo "$root/work/fvk-gd" "$COMPANY_URL"
expect_bash 2 "$P" 'GIT_DIR=$HOME/work/fvk-gd/.git git commit -m x'
expect_bash 2 "$P" 'git --git-dir=~/work/fvk-gd/.git commit -m x'

# A literal path that doesn't exist yet is judged by its path, so a new scratch repo can commit in one call.
expect_bash 0 "$root/scratch" "mkdir -p $root/scratch/new1 && cd $root/scratch/new1 && git init -q && git commit -m x"
expect_bash 2 "$root/scratch" "mkdir -p $root/work/fvk-new && cd $root/work/fvk-new && git init -q && git commit -m x"

# Attached short fj options, and a -H host with a user.
expect_bash 2 "$P" "fj -Hforgejo.example.com issue create x --repo example-client/r"
expect_bash 2 "$P" "fj -H=forgejo.example.com issue create x --repo example-client/r"
expect_bash 2 "$P" "fj -H forgejo.example.com pr create x -rexample-client/r"
expect_bash 2 "$P" "fj -H forgejo.example.com pr create x -r=example-client/r"
expect_bash 2 "$P" "fj -H git@forgejo.example.com issue create x --repo example-client/r"
# --repo with no host to judge it on.
mkdir -p "$root/nohost"
expect_bash 2 "$root/nohost" "fj issue create x --repo example-client/r"

# A dotted entry in any letter case is a host and a name.
printf '%s\n' 'Git.Kystlag.example' 'st.olav' >> "$HOME/.claude-customers"
mkrepo "$root/dotted/host" "git@git.kystlag.example:anyone/x.git"
mkrepo "$root/dotted/owner" "git@github.com:stolav-hf/app.git"
mkdir -p "$root/work/kystlag-portal"
assert "$(wc_run level "$root/dotted/host")" "customer" "a capitalised dotted entry covers its host"
assert "$(wc_run level "$root/work/kystlag-portal")" "customer" "and marks folders named for its label"
assert "$(wc_run level "$root/dotted/owner")" "customer" "a lowercase dotted entry marks owners named for it"

# A directory entry naming no existing folder is reported.
# shellcheck disable=SC2088 # an entry as the user writes it, for the guard to expand
printf '%s\n' '~/no-such-tree' >> "$HOME/.claude-customers"
ctx=$(session_context "$P")
[[ "$ctx" == *"name no existing folder"* ]] && e_success "session start reports a directory entry that doesn't exist" ||
  e_error "session start reports a directory entry that doesn't exist: $ctx"

mkrepo "$root/fjorigin" "git@forgejo.example.com:someone/x.git"
expect_bash 2 "$root/fjorigin" "fj issue create x --repo example-client/r"
expect_bash 0 "$root/fjorigin" "fj issue create x --repo someone/r"

# On a case-insensitive file system, a folder reached in another letter case is still below HOME.
mkdir -p "$root/work/fvk-norepo"
UPROOT=$(printf '%s' "$root" | tr '[:lower:]' '[:upper:]')
if [[ -d "$UPROOT/work/fvk-norepo" ]]; then
  assert "$(wc_run level "$UPROOT/work/fvk-norepo")" "customer" "a named folder reached in another letter case"
fi

# fj is judged by every remote, not only origin.
FJFORK="$root/fjfork"; mkrepo "$FJFORK" "$COMPANY_URL"
git -C "$FJFORK" remote add upstream git@forgejo.example.com:example-client/x.git
expect_bash 2 "$FJFORK" "fj -R upstream issue create x"
expect_bash 2 "$FJFORK" "fj pr create x"

# A linked worktree named for a customer, its main repo not.
MAINR="$root/plainmain"; mkrepo "$MAINR" "$COMPANY_URL"
"$REAL_GIT" -C "$MAINR" -c user.name=t -c user.email=t@example.com commit -q --allow-empty -m init
"$REAL_GIT" -C "$MAINR" worktree add -q "$root/work/fvk-wt"
expect_argv 2 "$root/work/fvk-wt" git commit -m x
# Its own location counts however the git dir is given, from a folder that isn't customer work.
expect_bash 2 "$root/plain" "GIT_DIR=$root/work/fvk-wt/.git git push"
expect_bash 2 "$root/plain" "git --git-dir=$root/work/fvk-wt/.git commit -m x"

# fj -C resolves against the directory the command runs in, and judges the remotes there.
expect_bash 2 "$root" "fj -C customer issue create x"
expect_bash 2 "$root" "fj --cwd=customer issue create x"
expect_bash 0 "$root" "fj -C personal issue create x"
expect_bash 2 "$P" "fj -C $FJFORK issue create x"
expect_bash 0 "$root/plain" 'fj -C $HOME/personal issue create x'
expect_bash 0 "$root/plain" 'fj -C ${HOME}/personal issue create x'
expect_bash 0 "$C" "fj --style fancy issue view 1"

# A name also matches a remote's owner: a clone outside HOME, or behind an SSH host alias.
OUT2="$(mktemp -d)"; mkrepo "$OUT2/clone" "git@github.com:fvk/app.git"
assert "$(wc_run level "$OUT2/clone")" "customer" "a name matching the remote's owner, outside HOME"
rm -rf "$OUT2"
mkrepo "$root/aliased" "git@github-fvk:fvk/app.git"
assert "$(wc_run level "$root/aliased")" "customer" "a clone behind an SSH host alias"

# A dotted brand name is a name, not a host.
mkdir -p "$root/work/havbris-example-app"
assert "$(wc_run level "$root/work/havbris-example-app")" "customer" "a dotted brand name marks folders"
printf '%s\n' 'stormkast.example' 'ssh.git.example.net' >> "$HOME/.claude-customers"
mkdir -p "$root/work/stormkast-app"; mkrepo "$root/sshhost" "git@git.example.net:anyone/x.git"
assert "$(wc_run level "$root/work/stormkast-app")" "customer" "a host entry marks folders named for its label before the TLD"
assert "$(wc_run level "$root/sshhost")" "customer" "a bare host entry with ssh. covers the host"

# A folder name stored decomposed, as Finder writes it.
NFD="$root/work/$(printf 'A\xcc\x8asen-app')"; mkdir -p "$NFD"
printf '%s\n' 'Åsen' >> "$HOME/.claude-customers"
assert "$(wc_run level "$NFD")" "customer" "a decomposed folder name"
printf '%s\n' "$(printf 'Ha\xcc\x8aland')" 'Mørk' >> "$HOME/.claude-customers"
mkdir -p "$root/work/haaland-app" "$root/work/moerkeroed" "$root/work/moerk-app"
assert "$(wc_run level "$root/work/haaland-app")" "customer" "a decomposed entry in its long spelling"
assert "$(wc_run level "$root/work/moerkeroed")" "company" "a short name stays an abbreviation in its long spelling"
assert "$(wc_run level "$root/work/moerk-app")" "customer" "and matches as a whole word"

# Session start reports lines it cannot read.
ctx=$(session_context "$P")
[[ "$ctx" == *"not understood"* ]] && e_success "session start reports unread lines" ||
  e_error "session start reports unread lines: $ctx"

# Globs: a dotfile glob or brace reaching the customers file blocks; ordinary globs and finds do not.
expect_bash 2 "$P" "rm ~/.c*"
expect_bash 2 "$P" "mv ~/.claude-{customers,x} /tmp"
expect_bash 2 "$P" "perl -e 'unlink \"$HOME/.claude-customers\"'"
expect_bash 0 "$P" "chmod +x .git/hooks/*"
expect_bash 0 "$P" "rm -rf build/*"
expect_bash 0 "$P" "find . ( -path '*/objects/*' ) -prune -o -type d -print"
expect_bash 0 "$P" "find ~ -name .claude-customers"

# fj -C with a tilde resolves to HOME, reaching the listed tree.
expect_bash 2 "$P" "fj -C ~/custtree/sub issue create x"

# A listed folder without a repo blocks gh and az; a bare-word push target is unresolved.
mkdir -p "$root/custtree/norepo"
expect_bash 2 "$root/custtree/norepo" "gh pr create"
expect_bash 2 "$root/custtree/norepo" "az repos pr create"
expect_bash 2 "$P" "git push nosuchremote main"
push_customers --off
expect_bash 0 "$P" "git push nosuchremote main"
ctx=$(session_context "$P")
[[ "$ctx" == *"nothing here is treated as customer work"* ]] && e_success "session start says no customers are listed" ||
  e_error "session start says no customers are listed: $ctx"
pop_customers
[[ "$(session_context "$P")" != *"nothing here is treated"* ]] && e_success "and says nothing once they are" ||
  e_error "and says nothing once they are"

# The old company orgs file is no longer read.
printf '%s\n' github.com/example-client > "$HOME/.claude-company-orgs"
assert "$(wc_run level "$C")" "customer" "a leftover company orgs file changes nothing"
rm "$HOME/.claude-company-orgs"
pop_customers

# --- waiver guard --------------------------------------------------------------------------------------------

e_header "waiver guard"

# Built at runtime, so this file never holds a line that sets the variable.
w=WORK_CONTEXT_
waive="${w}WAIVE"
function hook_err() { { printf '%s' "$1" | wc_run pre-tool-use >/dev/null; } 2>&1; }

expect_bash 2 "$P" "${waive}=1 git push"
[[ "$(hook_err "$(bash_json "$P" "${waive}=1 git push")")" == *"! ${waive}=1 git push"* ]] &&
  e_success "names the waived command for the user" || e_error "names the waived command for the user"
expect_bash 2 "$P" "export ${waive}=1"
expect_bash 2 "$P" "env ${waive}=1 git push"
expect_bash 2 "$P" "ls; declare -x ${waive}=1"
[[ "$(hook_err "$(bash_json "$P" "export ${waive}=1")")" == *"! ${waive}=1"* ]] &&
  e_success "export names the waiver form" || e_error "export names the waiver form"
assert "$(hook_rc "$(bash_json "$P" "${waive}=1 git push" Monitor)")" 2 "a Monitor command setting it"
expect_bash 0 "$P" "grep -r ${waive} ~/.claude"
expect_bash 0 "$P" "grep '${waive}=1' f"
assert "$(hook_rc "$(file_json Write file_path "$root/t/x.sh" content "${waive}=1 git push")")" 2 \
  "Write outside the checkout setting it"
assert "$(hook_rc "$(file_json Write file_path "$root/t/s.json" content "{\"env\": {\"${waive}\": \"1\"}}")")" 2 \
  "Write of a settings env entry"
assert "$(hook_rc "$(file_json Edit file_path "$root/t/x.sh" new_string "export FOO ${waive}")")" 2 \
  "Edit exporting it"
assert "$(hook_rc "$(file_json Write file_path "$root/t/x.md" content "mentions ${waive} only")")" 0 \
  "Write that only names it"
assert "$(hook_rc "$(file_json Write file_path "$CHECKOUT/test/test_claude_shims.sh" content "${waive}=1 git push")")" \
  0 "Write of the shim test in the checkout"
assert "$(hook_rc "$(file_json Edit file_path "$CHECKOUT/claude/hooks/work-context.sh" new_string \
  "export[^\\n]*${waive}")")" 0 "Edit of the guard in the checkout"
assert "$(hook_rc "$(file_json Write file_path "$CHECKOUT/docs/new-page.md" content "${waive}=1 git push")")" 0 \
  "Write of a doc in the checkout"
mkdir -p "$HOME/.claude"; ln -s "$CHECKOUT/claude/hooks" "$HOME/.claude/hooks"
assert "$(hook_rc "$(file_json Edit file_path "$HOME/.claude/hooks/work-context.sh" new_string \
  "export[^\\n]*${waive}")")" 0 "Edit of the guard through the ~/.claude/hooks link"
assert "$(hook_rc "$(file_json Write file_path "$CHECKOUT/source/99_x.sh" content "${waive}=1 git push")")" 2 \
  "Write of another script in the checkout"
assert "$(hook_rc "$(file_json Write file_path "$CHECKOUT/source/99_x.sh" content "export ${waive}=1")")" 2 \
  "Write exporting it in another script in the checkout"
assert "$(nojq_hook "$(file_json Write file_path "$root/t/x.md" content "${waive}")" 2>/dev/null; echo $?)" 2 \
  "without jq, a Write mentioning it blocks"
export "${waive}=1"
assert "$(hook_rc "$(bash_json "$P" "git status")")" 2 "a session launched with it blocks every guarded call"
[[ "$(hook_err "$(bash_json "$P" "git status")")" == *"restart Claude without"* ]] &&
  e_success "and names the restart" || e_error "and names the restart"
unset "$waive"

# --- git-secret ----------------------------------------------------------------------------------------------

e_header "git-secret: revealed files, at every level"

GS="$root/gsecret"; mkrepo "$GS" "$PERSONAL_URL"
mkdir -p "$GS/.gitsecret/paths" "$GS/conf"
printf '%s\n' 'conf/secret.env:0123abcd' 'top.key:4567ef01' > "$GS/.gitsecret/paths/mapping.cfg"
: > "$GS/conf/secret.env"; : > "$GS/conf/other.env"; : > "$GS/top.key"
ln -s "$GS/conf" "$root/gsconf"
: > "$P/notes.txt"

# grep_json <cwd> [path]: a Grep call, with no path key when none is given.
function grep_json() {
  jq -cn --arg cwd "$1" --arg p "${2-}" \
    '{tool_name: "Grep", cwd: $cwd, tool_input: ({pattern: "x"} + (if $p == "" then {} else {path: $p} end))}'
}

assert "$(hook_rc "$(file_json Read file_path "$GS/conf/secret.env")")" 2 "Read of a listed file"
assert "$(hook_rc "$(file_json Read file_path "$root/gsconf/secret.env")")" 2 "Read of a listed file via a symlinked parent"
assert "$(hook_rc "$(file_json Read file_path "$GS/conf/other.env")")" 0 "Read of an unlisted file beside it"
assert "$(hook_rc "$(file_json Read file_path "$P/notes.txt")")" 0 "Read in a repo with no .gitsecret"
assert "$(hook_rc "$(grep_json "$GS" top.key)")" 2 "Grep whose relative path is a listed file"
assert "$(hook_rc "$(grep_json "$GS" "$GS")")" 0 "Grep over the repo"
assert "$(hook_rc "$(grep_json "$GS")")" 0 "Grep with no path"
assert "$(hook_rc "$(file_json Edit file_path "$GS/top.key" new_string x)")" 2 "Edit of a listed file"
assert "$(hook_rc "$(file_json Write file_path "$GS/top.key")")" 2 "Write of a listed file"
assert "$(hook_rc "$(file_json NotebookEdit notebook_path "$GS/top.key" new_source x)")" 2 "NotebookEdit of a listed file"
[[ "$(hook_err "$(file_json Read file_path "$GS/top.key")")" == *"$GS/top.key\` is a git-secret file"* ]] &&
  e_success "the message names the file" || e_error "the message names the file"

while IFS= read -r cmd; do
  expect_bash 2 "$GS" "$cmd"
done <<'EOF2'
cat conf/secret.env
head -1 ./top.key
cd conf && cat secret.env
grep x < top.key
grep x <top.key
cp top.key /tmp/x
python3 -c 1 top.key
diff --from-file=top.key x
echo $(cat top.key)
bash -c 'cat top.key'
cat ~/gsecret/top.key
EOF2
assert "$(hook_rc "$(bash_json "$GS" "echo top.key")")" 2 \
  "echo top.key: an accepted false block, since any word naming a revealed file counts"
expect_bash 2 "$P" "cat $GS/top.key"
expect_bash 2 "$P" "cd $GS && cat top.key"
assert "$(hook_rc "$(bash_json "$GS" "tail -f top.key" Monitor)")" 2 "a Monitor command reading a listed file"
expect_bash 2 "$GS" "cat 'conf/secret.env'"
expect_bash 2 "$GS" "git status; cat \"top.key\""
expect_bash 0 "$GS" "cat conf/other.env"
expect_bash 0 "$GS" "ls conf"
expect_bash 0 "$GS" "cd conf && cat other.env"

# Every line holds a path, so every line is scanned; the guard once took 90 seconds over this, past the hook timeout.
NL=$'\n'
heredoc="git status; cat > out.txt <<'EOF'$NL"
for (( i = 0; i < 2000; i++ )); do heredoc+="text naming src/dir/file$i.txt and more words$NL"; done
heredoc+="EOF"
start=$EPOCHREALTIME
rc="$(hook_rc "$(bash_json "$GS" "$heredoc")")"
elapsed=$(( (${EPOCHREALTIME/./} - ${start/./}) / 1000 ))
assert "$rc" 0 "a 2000-line heredoc passes"
(( elapsed < 5000 )) && e_success "in under 5 seconds (${elapsed} ms)" || e_error "in under 5 seconds (${elapsed} ms)"

e_header "git-secret: commands that reveal"

while IFS= read -r cmd; do
  expect_bash 2 "$GS" "$cmd"
done <<'EOF2'
git secret reveal
git secret cat top.key
git secret changes
git-secret reveal -f
/usr/local/bin/git-secret reveal
EOF2
expect_bash 2 "$P" "git -C $GS secret reveal"
expect_bash 0 "$GS" "git secret hide"
expect_bash 0 "$GS" "git secret list"
expect_bash 0 "$GS" "git-secret whoknows"
expect_argv 2 "$GS" git secret reveal
expect_argv 0 "$GS" git secret hide
[[ "$(hook_err "$(bash_json "$GS" "git secret reveal")")" == *"! cd $GS && git secret reveal"* ]] &&
  e_success "the reveal message offers the user's command" || e_error "the reveal message offers the user's command"

test_done
