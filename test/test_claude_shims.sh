#!/usr/bin/env bash
# Resolve the shim before sourcing the helper: bin/dotfiles exports
# DOTFILES=~/.dotfiles when sourced, so afterwards this would test whatever tree
# lives there rather than the one this file was launched from.
CHECKOUT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SHIM="$CHECKOUT/claude/shims/shim.sh"
readonly CHECKOUT SHIM

# The real git, found before HOME moves: inside a Claude session `command -v git` names the shim.
real_git=""
skip_a="$(cd -P -- "$CHECKOUT/claude/shims" 2>/dev/null && pwd -P)"
skip_b="$(cd -P -- "$HOME/.claude/shims" 2>/dev/null && pwd -P)"
IFS=: read -ra path_entries <<<"$PATH"
for e in "${path_entries[@]}"; do
  c="$(cd -P -- "${e:-.}" 2>/dev/null && pwd -P)" || continue
  [[ -n $skip_a && $c == "$skip_a" || -n $skip_b && $c == "$skip_b" ]] && continue
  if [[ -f $c/git && -x $c/git ]]; then real_git="$c/git"; break; fi
done
readonly real_git

source "$DOTFILES/test/helper.sh"

if [[ ! -x "$SHIM" ]]; then
  echo "ERROR: $SHIM is missing or not executable" >&2
  exit 1
fi
if [[ -z "$real_git" ]]; then
  echo "ERROR: no git on PATH outside the shim directories" >&2
  exit 1
fi

e_header "$(basename "$0" .sh)"

unset GH_REPO GH_HOST GITLAB_HOST GIT_DIR GIT_WORK_TREE GITLAB_REPO GL_HOST GITLAB_URI
unset WORK_CONTEXT_WAIVE WORK_CONTEXT_GIT CLAUDE_PROJECT_DIR

root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT
export HOME="$root"
export WORK_CONTEXT_SCRATCH_DIRS="$root/scratch"
mkdir -p "$root/scratch"

# mkrepo <dir> [origin-url]
function mkrepo() {
  mkdir -p "$1"
  "$real_git" -C "$1" init -q
  [[ -z "$2" ]] || "$real_git" -C "$1" remote add origin "$2"
}

P="$root/personal";  mkrepo "$P" git@github.com:andrelin/dotfiles.git
C="$root/customer";  mkrepo "$C" git@github.com:example-client/x.git
# Customer work is only what the customers file lists.
printf '%s\n' github.com/example-client > "$HOME/.claude-customers"
S="$root/scratch/s"; mkrepo "$S"

# The shim dir is built here rather than using the committed symlinks, which a Windows checkout turns into text
# files. The shim finds the guard as $shim_dir/../hooks.
shims="$root/claude/shims"
mkdir -p "$shims"
ln -s "$CHECKOUT/claude/hooks" "$root/claude/hooks"
for t in git gh glab az fj; do ln -s "$SHIM" "$shims/$t"; done
# Every tool the guard checks has its committed link, read from the index so a Windows checkout counts too.
for t in git gh glab az fj; do
  mode="$("$real_git" -C "$CHECKOUT" ls-files -s -- "claude/shims/$t")"
  assert "${mode%% *}" 120000 "claude/shims/$t is a committed link"
done

# Stubs stand in for the real tools, so a test sees whether the shim reached them and with what.
stubs="$root/stubs"
mkdir -p "$stubs"
cat >"$stubs/git" <<'EOF'
#!/bin/sh
echo "real git $*"
[ -z "${WORK_CONTEXT_WAIVE+x}" ] || echo "waiver leaked"
EOF
cat >"$stubs/gh" <<'EOF'
#!/bin/sh
[ -z "$GH_STUB_DIR" ] || cd "$GH_STUB_DIR" || exit
git push
EOF
cat >"$stubs/fj" <<'EOF'
#!/bin/sh
echo "real fj $*"
EOF
chmod +x "$stubs/git" "$stubs/gh" "$stubs/fj"

# The guard's own remote lookups use real git; the shim's exec reaches the stub.
export WORK_CONTEXT_GIT="$real_git"
TEST_PATH="$shims:$stubs"

# shim_call <dir> <path> <command...>: run a command from <dir> with only <path> to find tools on, killed after
# 10 seconds, so a shim that execs itself can't hang the suite. The exec keeps the whole shim chain on the pid the
# watchdog kills.
function shim_call() {
  local dir=$1 path=$2
  shift 2
  ( cd "$dir" && export PATH="$path" && exec "$@" ) &
  local pid=$! dog rc
  ( sleep 10; kill -9 "$pid" ) >/dev/null 2>&1 &
  dog=$!
  wait "$pid"
  rc=$?
  kill "$dog" 2>/dev/null
  wait "$dog" 2>/dev/null
  return "$rc"
}

# through: shim_call with stderr dropped.
function through() { shim_call "$@" 2>/dev/null; }

# --- the guard decides ---------------------------------------------------------------------------------------

e_header "guarded calls"

out="$(through "$C" "$TEST_PATH" git push)"; rc=$?
assert "$rc" 2 "customer: git push exits 2"
assert "$out" "" "customer: git push never reaches git"

err="$(shim_call "$C" "$TEST_PATH" git push 2>&1 >/dev/null)"
assert "${err/*is customer work*/found}" found "customer: git push prints the guard's deny message"

out="$(through "$C" "$TEST_PATH" git log)"; rc=$?
assert "$out" "real git log" "customer: git log reaches git"
assert "$rc" 0 "customer: git log exits 0"

out="$(through "$P" "$TEST_PATH" git push)"
assert "$out" "real git push" "personal: git push reaches git"

out="$(through "$C" "$TEST_PATH" fj issue create x)"; rc=$?
assert "$rc" 2 "customer: fj issue create exits 2"
assert "$out" "" "customer: fj issue create never reaches fj"
out="$(through "$C" "$TEST_PATH" fj issue view 1)"
assert "$out" "real fj issue view 1" "customer: fj issue view reaches fj"
out="$(through "$P" "$TEST_PATH" fj issue create x)"
assert "$out" "real fj issue create x" "personal: fj issue create reaches fj"

out="$(through "$P" "$TEST_PATH" git -C "$C" push)"; rc=$?
assert "$rc" 2 "personal cwd: git -C <customer> push exits 2"
assert "$out" "" "personal cwd: git -C <customer> push never reaches git"

through "$C" "$TEST_PATH" git -c k=v push >/dev/null
assert "$?" 2 "customer: git -c k=v push exits 2"

out="$(through "$S" "$TEST_PATH" git commit --allow-empty -m x)"
assert "$out" "real git commit --allow-empty -m x" "scratch repo without origin: commit reaches git"

# --- finding the real tool -----------------------------------------------------------------------------------

e_header "finding the real tool"

# A second spelling of the shim dir, so a walk that compared PATH entries as written would exec itself forever.
ln -s "$shims" "$root/shims-link"
through "$P" "$shims:$root/shims-link" git log >/dev/null
assert "$?" 127 "no real git on PATH: exits 127"

err="$(shim_call "$P" "$shims" git log 2>&1 >/dev/null)"
assert "$err" "git: not found" "no real git on PATH: says so"

# A shim dir with no guard beside it: the guard can't run, so the call must block rather than pass.
mkdir -p "$root/broken/claude/shims"
ln -s "$SHIM" "$root/broken/claude/shims/git"
out="$(through "$P" "$root/broken/claude/shims:$stubs" git log)"; rc=$?
assert "$rc" 2 "guard missing: exits 2"
assert "$out" "" "guard missing: never reaches git"
err="$(shim_call "$P" "$root/broken/claude/shims:$stubs" git log 2>&1 >/dev/null)"
assert "${err/*blocking to stay safe*/found}" found "guard missing: prints the fail-closed message"

# --- the waiver ----------------------------------------------------------------------------------------------

e_header "the user's waiver"

out="$(WORK_CONTEXT_WAIVE=1 through "$C" "$TEST_PATH" git push)"
assert "$out" "real git push" "customer: waived git push reaches git, without the waiver in its environment"

# gh's own git push must reach real git too: the shim dir is off the waived tool's PATH.
out="$(WORK_CONTEXT_WAIVE=1 through "$C" "$TEST_PATH" gh pr create)"
assert "$out" "real git push" "customer: waived gh pr create's inner git push reaches git"

# Without the waiver the shim stays on gh's PATH: gh passes in a personal repo, its git push in a customer one doesn't.
out="$(GH_STUB_DIR="$C" through "$P" "$TEST_PATH" gh pr create)"; rc=$?
assert "$rc" 2 "unwaived gh: its inner git push in a customer repo exits 2"
assert "$out" "" "unwaived gh: its inner git push never reaches git"

test_done
