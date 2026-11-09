#!/usr/bin/env bash
# Guards the wording of the staged-workflow docs and skills that nothing else executes:
# a dropped pointer or reworded command leaves every other test green while the workflow
# silently stops doing what the user asked.
CHECKOUT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
readonly CHECKOUT

source "$DOTFILES/test/helper.sh"

e_header "$(basename "$0" .sh)"

SAVE="$CHECKOUT/claude/docs/session-end-save.md"
IMPL="$CHECKOUT/claude/skills/implementing-plans/SKILL.md"
ROUNDS="$CHECKOUT/claude/skills/reviewing-in-rounds/SKILL.md"
PRECEDENCE="$CHECKOUT/claude/docs/skill-precedence.md"
WRITING_CODE="$CHECKOUT/claude/rules/writing-code.md"
PLANS="$CHECKOUT/claude/skills/writing-plans/SKILL.md"

for f in "$SAVE" "$IMPL" "$ROUNDS" "$PRECEDENCE" "$WRITING_CODE" "$PLANS"; do
  if [[ ! -f "$f" ]]; then
    echo "ERROR: $f is missing" >&2
    exit 1
  fi
done

# Occurrences of a fixed string in a file.
function count() {
  grep -cF -- "$1" "$2" || true
}

# The counted line a fixed string first sits on, counted by bin/check-md-limits itself (--count-raw)
# over the file up to that line, so a fence, front matter or heading rule is never restated here.
# A prefix cut inside an open fence would miscount, so the needle must sit outside one.
function counted_line() {
  local lineno prefix n
  lineno="$(grep -nF -m1 -- "$1" "$2" | cut -d: -f1)"
  [[ -n "$lineno" ]] || return 0
  prefix="$(mktemp)"
  head -n "$lineno" "$2" > "$prefix"
  n="$("$CHECKOUT/bin/check-md-limits" --count-raw "$prefix")" || n=""
  rm -f "$prefix"
  echo "$n"
}

# --- session-end-save.md ----------------------------------------------------

# The level check must be ai-log's, which answers exactly what work-context.sh level does.
assert "$([[ $(count 'ai-log level' "$SAVE") -ge 1 ]] && echo yes)" "yes" "the save names ai-log level"
assert "$([[ $(count 'Work in progress: Tasks' "$SAVE") -ge 1 ]] && echo yes)" "yes" "the save names its commit message"
assert "$([[ $(count 'ai-log record <plan-file>' "$SAVE") -ge 1 ]] && echo yes)" "yes" "the save records the session end"
assert "$([[ $(count '--others --cached' "$SAVE") -ge 1 ]] && echo yes)" "yes" \
  "the save lists plan files with a quoted pathspec that finds untracked ones"
assert "$([[ $(count 'never an unquoted glob' "$SAVE") -ge 1 ]] && echo yes)" "yes" "the save warns off an unquoted glob, which aborts on no match"
assert "$([[ $(count 'git rm -f' "$SAVE") -ge 1 ]] && echo yes)" "yes" "the landing step removes a modified tracked plan with -f"
assert "$([[ $(count 'world-readable' "$SAVE") -ge 1 ]] && echo yes)" "yes" "the save checks plan text before pushing it from a public repo"

# The commit, ref deletion and push are pinned, and the refs are kept when a checkpointed path was restored.
assert "$([[ $(count 'git commit --allow-empty -m' "$SAVE") -ge 1 ]] && echo yes)" "yes" "the save commits with --allow-empty, one HEAD per session end"
assert "$([[ $(count 'git update-ref -d' "$SAVE") -ge 1 ]] && echo yes)" "yes" "the save deletes the checkpoint refs it holds"
assert "$([[ $(count 'git push -u origin <branch>' "$SAVE") -ge 1 ]] && echo yes)" "yes" "the save pushes with -u to the named branch, never a bare push"
assert "$([[ $(count 'keep every ref' "$SAVE") -ge 1 ]] && echo yes)" "yes" "the save keeps the refs when a checkpointed path was restored"
assert "$([[ $(count 'Leftovers before round 1:' "$SAVE") -ge 1 ]] && echo yes)" "yes" "a session end in a code review adds the review's fixes"

assert "$(count 'Stop and report if `HEAD` is detached, or if the branch is not the plan' "$SAVE")" "1" "the save stops on a detached HEAD or another branch"
assert "$(count '<!-- DOCTOC SKIP -->' "$SAVE")" "1" "the save adds the doctoc marker to a plan before staging it"
assert "$(count 'Work in progress: Tasks (none new)' "$SAVE")" "1" "the save has a commit form for no new tasks"
assert "$(count 'git restore --staged -- <path>' "$SAVE")" "1" "the save leaves out what fails the public-repo check with git restore --staged"
assert "$([[ $(grep -ciE 'allow file|allowlist|`allow`' "$SAVE") -eq 0 ]] && echo yes)" "yes" "the save mentions no allow file"

# Order: commit, then ref deletion, then push and record; the deletion is conditional on the commit having run.
function first_line() { grep -nF -m1 -- "$1" "$2" | cut -d: -f1; }
l_commit="$(first_line 'git commit --allow-empty -m' "$SAVE")"
l_del="$(first_line 'git update-ref -d' "$SAVE")"
l_push="$(first_line 'git push -u origin <branch>' "$SAVE")"
l_rec="$(first_line 'ai-log record <plan-file>' "$SAVE")"
assert "$([[ -n $l_commit && -n $l_del && -n $l_push && -n $l_rec && $l_commit -lt $l_del && $l_del -lt $l_push && $l_del -lt $l_rec ]] && echo yes)" "yes" \
  "the save commits, then deletes the refs, then pushes and records (lines $l_commit, $l_del, $l_push, $l_rec)"
assert "$(grep -F 'git update-ref -d' "$SAVE" | grep -cF 'the commit now holds')" "1" "the ref deletion covers only what the commit now holds"
assert "$([[ $(count 'A failed commit' "$SAVE") -ge 1 && $(count 'keeps the refs' "$SAVE") -ge 1 ]] && echo yes)" "yes" "a failed commit keeps the refs"
assert "$([[ $(count 'ai-log level' "$SAVE") -ge 1 && $(count 'quotes that reason' "$SAVE") -ge 1 ]] && echo yes)" "yes" \
  "a customer level with a reason is quoted in the report"

# --- the skills ------------------------------------------------------------

assert "$([[ $(count 'session-end-save.md' "$IMPL") -ge 1 ]] && echo yes)" "yes" "implementing-plans points at the session-end doc"
line="$(counted_line 'session-end-save.md' "$IMPL")"
assert "$([[ -n $line && $line -le 100 ]] && echo yes)" "yes" "that pointer stays within the first 100 counted lines (is at ${line:-none})"

assert "$(count 'follows `~/.claude/docs/session-end-save.md`' "$ROUNDS")" "1" "reviewing-in-rounds carries the session-end trigger"
line="$(counted_line 'follows `~/.claude/docs/session-end-save.md`' "$ROUNDS")"
assert "$([[ -n $line && $line -le 100 ]] && echo yes)" "yes" "the session-end trigger stays within the first 100 counted lines (is at ${line:-none})"
assert "$(count 'reviewing-in-rounds/SKILL.md' "$SAVE")" "1" "the save names the reviewing-in-rounds trigger"
assert "$(count 'A session end during the review may already have committed fixes' "$ROUNDS")" "1" "Completion step 1 allows earlier session-end commits"
assert "$(count 'offer and run no commit' "$ROUNDS")" "1" "Completion step 4 offers no commit when nothing is staged"

# Another test greps this text: it has to appear once, so the record happens in one place.
assert "$(count 'ai-log record <plan-file>' "$ROUNDS")" "1" "reviewing-in-rounds records once"
line="$(counted_line 'ai-log record <plan-file>' "$ROUNDS")"
assert "$([[ -n $line && $line -le 100 ]] && echo yes)" "yes" "the record step stays within the first 100 counted lines (is at ${line:-none})"
assert "$(grep -cE 'or when there was nothing to commit' "$ROUNDS")" "1" \
  "a final review with nothing to commit still records and introspects"
assert "$(grep -cF 'A declined commit records nothing' "$ROUNDS")" "1" "a declined commit still records nothing"
assert "$(grep -cF 'never a fast-forward' "$ROUNDS")" "1" "Completion carries the landing rule"
assert "$(grep -cF 'never a fast-forward' "$IMPL")" "1" "implementing-plans carries the landing rule"
assert "$(grep -cF 'a fast-forward' "$PRECEDENCE")" "1" "skill-precedence carries the landing rule for finishing-a-development-branch"
assert "$(grep -cF 'git rm -f' "$ROUNDS")" "1" "Completion owns the tracked plan's removal"
assert "$(grep -cF 'git rm -f' "$PLANS")" "1" "writing-plans removes a tracked plan with -f"

# --- writing-code.md's globs -----------------------------------------------

# A glob that never matches loads nothing and reports nothing, so each extension is pinned.
for ext in kt java ts tsx js mjs cjs mts cts jsx py sh zsh kts cs razor cshtml go rs rb swift c cpp cc cxx h hpp php scala gradle; do
  assert "$(grep -cxF "  - \"**/*.$ext\"" "$WRITING_CODE")" "1" "writing-code.md globs *.$ext once"
done

# --- the ls-files commands the save relies on --------------------------------

# The commands are taken from the doc itself, so a reworded one is the one tested.
# Step 2 adds plan files, Landing removes the tracked ones.
function doc_command() {
  # shellcheck disable=SC2016  # backticks here are literal markdown
  grep -F -- "$1" "$SAVE" | head -n1 | sed -e 's/^[^`]*`//' -e 's/`[^`]*$//' -e "s/<stem>/plan-x/g"
}
ADD_CMD="$(doc_command 'xargs -0 -r git add --')"
# The company-level variant drops --others: the doc must say so, and the command is the personal one minus it.
assert "$(grep -cF 'At company level drop `--others`' "$SAVE")" "1" "the save tells company level to drop --others"
ADD_CMD_CO="${ADD_CMD/--others /}"
assert "$([[ $ADD_CMD_CO != "$ADD_CMD" && $ADD_CMD_CO == *--cached* && $ADD_CMD_CO != *--others* ]] && echo yes)" "yes" "the company add command is the personal one minus --others"
RM_CMD="$(doc_command 'xargs -0 -r git rm -f --')"
assert "$([[ $ADD_CMD == git\ ls-files* && $ADD_CMD == *"':(top)plan-x.md'"* && $ADD_CMD == *'--exclude-standard'* ]] && echo yes)" "yes" \
  "the doc's add command is rooted, quoted and skips ignored files"
assert "$([[ $RM_CMD == git\ ls-files* && $RM_CMD == *"':(top)plan-x.md'"* ]] && echo yes)" "yes" "the doc's landing command is rooted and quoted"

# Scratch repo: init in its own call, every write goes through a subshell (repo_git; test_ai_log.sh's repo_git takes a directory).
repo="$(cd -P "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$repo"' EXIT
git init -q "$repo"
function repo_git() { (cd "$repo" && git -c user.name=t -c user.email=t@t -c commit.gpgsign=false "$@"); }
mkdir "$repo/sub"
printf x >"$repo/keep.txt"
repo_git add keep.txt
repo_git commit -q -m base

# From a subdirectory, under each shell the user may have, with nothing to match: not an error, and nothing staged.
for shell in bash zsh; do
  type -P "$shell" >/dev/null || continue
  out="$(cd "$repo/sub" && "$shell" -c "$ADD_CMD && echo ok" 2>&1)"
  assert "$out" "ok" "under $shell, no plan file at all is not an error"
  out="$(cd "$repo/sub" && "$shell" -c "$RM_CMD >/dev/null && echo ok" 2>&1)"
  assert "$out" "ok" "under $shell, landing with no tracked plan is not an error"
done
assert "$(repo_git diff --cached --name-only | paste -sd, -)" "" "nothing matched, nothing staged"

printf a >"$repo/plan-x.md"
printf b >"$repo/plan-x-review-findings-code.md"
printf c >"$repo/plan-xy-review-findings-code.md"
printf d >"$repo/sub/plan-x.md"
out="$(cd "$repo/sub" && bash -c "$ADD_CMD && echo ok" 2>&1)"
assert "$out" "ok" "adding from a subdirectory succeeds"
assert "$(repo_git diff --cached --name-only | paste -sd, -)" "plan-x-review-findings-code.md,plan-x.md" \
  "from a subdirectory the root's untracked plan files are found, another plan's and a nested one are not"

# Company level: a tracked plan is added; an untracked one is not, because the command lacks --others (the info/exclude
# entries mirror the real setup but add nothing here, since --others is what would list the untracked file).
repo_git reset -q
printf 'plan-x.md\nplan-x-review-findings-*.md\n' >"$repo/.git/info/exclude"
repo_git add -f plan-x.md
repo_git commit -q -m tracked-plan
printf e >"$repo/plan-x-review-findings-plan.md"
printf more >>"$repo/plan-x.md"
out="$(cd "$repo/sub" && bash -c "$ADD_CMD_CO && echo ok" 2>&1)"
assert "$out" "ok" "the company add command succeeds from a subdirectory"
assert "$(repo_git diff --cached --name-only | paste -sd, -)" "plan-x.md" "at company level the tracked plan is added and an untracked excluded one is not"
repo_git reset -q
repo_git rm -q --cached plan-x.md
: >"$repo/.git/info/exclude"
repo_git reset -q
repo_git add plan-x.md plan-x-review-findings-code.md
repo_git commit -q -m plans
printf more >>"$repo/plan-x.md"
out="$(cd "$repo/sub" && bash -c "$RM_CMD >/dev/null && echo ok" 2>&1)"
assert "$out" "ok" "landing removes a tracked plan from a subdirectory, edited or not"
assert "$(repo_git diff --cached --name-only | paste -sd, -)" "plan-x-review-findings-code.md,plan-x.md" \
  "landing stages the removal of the modified plan and its findings, nothing else"
assert "$([[ ! -e $repo/plan-x.md && -e $repo/plan-xy-review-findings-code.md ]] && echo yes)" "yes" "another plan's file stays"

# --- the session end, executed ------------------------------------------------

# The commit and ref deletion are taken from the doc, so a reworded flag or message form is the one tested.
COMMIT_CMD="$(doc_command 'git commit --allow-empty -m "Work in progress: Tasks <list>"')"
DEL_CMD="$(doc_command 'git update-ref -d <ref>')"
assert "$([[ $COMMIT_CMD == 'git commit --allow-empty -m "Work in progress: Tasks '* ]] && echo yes)" "yes" "the doc's commit command is extracted"
assert "$([[ $DEL_CMD == 'git update-ref -d '* ]] && echo yes)" "yes" "the doc's ref deletion is extracted"
COMMIT_CMD="${COMMIT_CMD//<list>/1, 2}"
sess="$(cd -P "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$repo" "$sess"' EXIT
git init -q "$sess"
function sess_git() { (cd "$sess" && git -c user.name=t -c user.email=t@t -c commit.gpgsign=false "$@"); }
function sess_run() { (cd "$sess" && GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t \
  GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=commit.gpgsign GIT_CONFIG_VALUE_0=false bash -c "$1"); }
printf base >"$sess/a.txt"
sess_git add a.txt
sess_git commit -q -m base
base="$(sess_git rev-parse HEAD)"
sess_git switch -q -c work
for t in 1 2; do
  printf "task $t" >"$sess/t$t.txt"
  sess_git add "t$t.txt"
  sess_git update-ref "refs/checkpoints/work/$t" "$(sess_git stash create)"
done
refs="$(sess_git for-each-ref --format='%(refname)' refs/checkpoints/work/)"
assert "$(wc -l <<<"$refs" | tr -d ' ')" "2" "two checkpoint refs exist before the session end"
before="$(sess_git rev-parse HEAD)"
sess_run "$COMMIT_CMD" >/dev/null
for ref in $refs; do sess_run "${DEL_CMD//<ref>/$ref}"; done
assert "$(sess_git for-each-ref refs/checkpoints/ | wc -l | tr -d ' ')" "0" "no checkpoint ref is left after the session end"
assert "$(sess_git write-tree)" "$(sess_git rev-parse 'HEAD^{tree}')" "the index equals HEAD's tree after the session end"
assert "$(sess_git log -1 --format=%s)" "Work in progress: Tasks 1, 2" "the commit message names the tasks"
assert "$(sess_git merge-base --is-ancestor "$base" HEAD && echo yes)" "yes" "the Base commit is still an ancestor of HEAD"
first="$(sess_git rev-parse HEAD)"
sess_run "${COMMIT_CMD//1, 2/(none new)}" >/dev/null
assert "$([[ $(sess_git rev-parse HEAD) != "$first" && $first != "$before" ]] && echo yes)" "yes" "an empty second session end still makes a new HEAD"

# --- the Completion gates ----------------------------------------------------

assert "$(grep -cF 'offered and run only on the user' "$SAVE")" "1" "the save's landing commit waits for a yes"
assert "$(grep -cF 'offered and run only on a yes' "$ROUNDS")" "1" "Completion's plan-removal commit waits for a yes"
assert "$(grep -cF 'git diff --cached <Base:>' "$SAVE")" "1" "a public repo's push is checked against the bar first"

test_done
