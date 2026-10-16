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

# The guard runs under Apple's bash 3.2 as a hook, so the tests run it the same way.
function wc_run() { /bin/bash "$SCRIPT" "$@"; }

# mkrepo <dir> [origin-url]
function mkrepo() {
  mkdir -p "$1"
  git -C "$1" init -q
  [[ -z "$2" ]] || git -C "$1" remote add origin "$2"
}

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
git@gitlab.com:andrelin/x.git|customer
git@gitlab.com:uptimeconsulting/x.git|company
not a url|customer
git@github.com:Andrelin/dotfiles.git|personal
https://github.com/UptimeConsulting/x|company
https://gitlab.example.com/uptimeconsulting/sub/x.git|company
https://andrelin@github.com/andrelin/x.git|personal
EOF

mkdir -p "$root/not-a-repo"
assert "$(wc_run level "$root/not-a-repo")" "customer" "a directory outside any repo"
mkrepo "$root/scratch/noorigin"
assert "$(wc_run level "$root/scratch/noorigin")" "personal" "a no-origin repo under a scratch prefix"
mkrepo "$root/noorigin"
assert "$(wc_run level "$root/noorigin")" "customer" "a no-origin repo beside the scratch prefix"
mkrepo "$root/scratchy/noorigin"
assert "$(wc_run level "$root/scratchy/noorigin")" "customer" "a sibling sharing the scratch prefix's name"
assert "$(cd "$P" && wc_run level)" "personal" "level defaults to the working directory"

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
assert "$(mentions "$(session_context "$root/noorigin")")" "blocked " "no origin outside scratch"
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
[[ "$deny" == *"$C is a customer repository"* ]] && e_success "names the directory and level" ||
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

test_done
