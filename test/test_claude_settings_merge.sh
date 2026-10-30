#!/usr/bin/env bash
# Resolve the script before sourcing the helper: bin/dotfiles exports
# DOTFILES=~/.dotfiles when sourced, so afterwards this would test whatever tree
# lives there rather than the one this file was launched from.
SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bin/claude-settings-merge"
readonly SCRIPT

source "$DOTFILES/test/helper.sh"

if [[ ! -x "$SCRIPT" ]]; then
  echo "ERROR: $SCRIPT is missing or not executable" >&2
  exit 1
fi

e_header "$(basename "$0" .sh)"

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
settings="$workdir/settings.json"
# The script refuses to register a hook script that isn't there, so HOME holds stand-ins.
export HOME="$workdir/home"
mkdir -p "$HOME/.claude/hooks"
touch "$HOME/.claude/hooks/work-context.sh" "$HOME/.claude/hooks/watch-main-ci.sh"

# The guard's two hook entries and the main-CI reminder's, exactly as the init script must register them.
pre_tool_use='{"matcher":"Bash|Monitor|Read|Grep|Write|Edit|MultiEdit|NotebookEdit","hooks":[{"type":"command","command":"/bin/bash ~/.claude/hooks/work-context.sh pre-tool-use","timeout":10,"onFailure":"block"}]}'
session_start='{"hooks":[{"type":"command","command":"/bin/bash ~/.claude/hooks/work-context.sh session-start","timeout":10}]}'
post_tool_use='{"matcher":"Bash","hooks":[{"type":"command","command":"/bin/bash ~/.claude/hooks/watch-main-ci.sh","timeout":10}]}'
cc_pre='{"matcher":"","hooks":[{"type":"command","command":"cc-status pre"}]}'
cc_start='{"hooks":[{"type":"command","command":"cc-status start"}]}'

function merge() { "$SCRIPT" hooks "$settings"; }

# The entries for one event whose commands run one of our hook scripts.
function owned() {
  jq -c --arg e "$1" '[.hooks[$e][]? | select(any(.hooks[]?; .command | contains("work-context.sh") or contains("watch-main-ci.sh")))]' "$settings"
}

echo '{}' > "$settings"
merge
assert "$(owned PreToolUse)" "[$pre_tool_use]" "{} gains the PreToolUse entry"
assert "$(owned SessionStart)" "[$session_start]" "{} gains the SessionStart entry"
assert "$(owned PostToolUse)" "[$post_tool_use]" "{} gains the PostToolUse entry"

rm -f "$settings"
merge
assert "$(owned SessionStart)" "[$session_start]" "a missing file is created with the entries"

: > "$settings"
merge
assert "$(owned PreToolUse)" "[$pre_tool_use]" "an empty file is treated as {}"

printf '{"hooks":{"PreToolUse":[%s],"SessionStart":[%s]}}\n' "$cc_pre" "$cc_start" > "$settings"
merge
assert "$(jq -c '.hooks.PreToolUse' "$settings")" "[$cc_pre,$pre_tool_use]" "foreign PreToolUse entry kept, ours appended"
assert "$(jq -c '.hooks.SessionStart' "$settings")" "[$cc_start,$session_start]" "foreign SessionStart entry kept, ours appended"

merge
assert "$(owned PreToolUse | jq length)" "1" "a second run leaves one PreToolUse entry"
assert "$(owned SessionStart | jq length)" "1" "a second run leaves one SessionStart entry"
assert "$(owned PostToolUse | jq length)" "1" "a second run leaves one PostToolUse entry"
assert "$(jq -c '.hooks.PreToolUse[0]' "$settings")" "$cc_pre" "a second run still keeps the foreign entry"

stale='{"matcher":"Bash","hooks":[{"type":"command","command":"/bin/bash ~/.claude/hooks/work-context.sh pre-tool-use","timeout":5}]}'
printf '{"hooks":{"PreToolUse":[%s]}}\n' "$stale" > "$settings"
merge
assert "$(owned PreToolUse)" "[$pre_tool_use]" "an outdated owned entry is replaced by the canonical one"

# A group holding a foreign hook beside ours keeps the foreign one.
printf '{"hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"cc-status pre"},{"type":"command","command":"bash ~/.claude/hooks/work-context.sh pre-tool-use"}]}]}}\n' > "$settings"
merge
assert "$(jq -c '.hooks.PreToolUse' "$settings")" \
  "[{\"matcher\":\"Bash\",\"hooks\":[{\"type\":\"command\",\"command\":\"cc-status pre\"}]},$pre_tool_use]" \
  "a shared group loses only the guard's hook"

# An install from before Read and Grep were guarded picks them up on its next run.
old_matcher='{"matcher":"Bash|Monitor|Write|Edit|MultiEdit|NotebookEdit","hooks":[{"type":"command","command":"/bin/bash ~/.claude/hooks/work-context.sh pre-tool-use","timeout":10,"onFailure":"block"}]}'
printf '{"hooks":{"PreToolUse":[%s]}}\n' "$old_matcher" > "$settings"
merge
assert "$(owned PreToolUse)" "[$pre_tool_use]" "an entry with the old matcher gains Read and Grep"

others='{"model":"opus","autoMode":{"enabled":true},"enabledPlugins":{"superpowers@x":true},"hooks":{"Stop":[{"hooks":[{"type":"command","command":"say done"}]}]}}'
printf '%s\n' "$others" > "$settings"
merge
assert "$(jq -S 'del(.hooks.PreToolUse, .hooks.SessionStart, .hooks.PostToolUse)' "$settings")" "$(jq -S . <<< "$others")" \
  "other keys and other hook events are untouched"

printf '{"model": "opus",\n' > "$settings"
before="$(cksum < "$settings")"
merge 2>/dev/null && rc=0 || rc=$?
assert "$rc" "1" "invalid JSON exits 1"
assert "$(cksum < "$settings")" "$before" "invalid JSON leaves the file byte-identical"
assert "$(find "$workdir" -name '*.tmp' | wc -l | tr -d ' ')" "0" "invalid JSON leaves no temp file"

echo '{}' > "$settings"
nojq="$workdir/nojq"
mkdir -p "$nojq"
ln -s "$(type -P bash)" "$nojq/bash"
PATH="$nojq" "$nojq/bash" "$SCRIPT" hooks "$settings" 2>/dev/null && rc=0 || rc=$?
assert "$rc" "1" "missing jq exits 1"
assert "$(cat "$settings")" "{}" "missing jq leaves the file untouched"

echo '{}' > "$settings"
mv "$HOME/.claude/hooks/work-context.sh" "$workdir/guard"
merge 2>/dev/null && rc=0 || rc=$?
assert "$rc" "1" "a missing guard script exits 1"
assert "$(cat "$settings")" "{}" "a missing guard script leaves the file untouched"
ln -s "$workdir/nowhere" "$HOME/.claude/hooks/work-context.sh"
merge 2>/dev/null && rc=0 || rc=$?
assert "$rc" "1" "a dangling link to the guard exits 1"
rm "$HOME/.claude/hooks/work-context.sh"
mv "$workdir/guard" "$HOME/.claude/hooks/work-context.sh"
mv "$HOME/.claude/hooks/watch-main-ci.sh" "$workdir/reminder"
merge 2>/dev/null && rc=0 || rc=$?
assert "$rc" "1" "a missing main-CI reminder script exits 1"
assert "$(cat "$settings")" "{}" "a missing main-CI reminder script leaves the file untouched"
mv "$workdir/reminder" "$HOME/.claude/hooks/watch-main-ci.sh"

"$SCRIPT" bogus "$settings" 2>/dev/null && rc=0 || rc=$?
assert "$rc" "2" "an unknown subcommand is a usage error"

e_header "hardening"

function harden() { "$SCRIPT" hardening "$settings"; }
function deny_has() { jq -e --arg r "$1" '.permissions.deny | index($r) != null' "$settings" >/dev/null && echo yes || echo no; }
instruction_files='.pluginConfigs["cc-plugin-agents-md@builtin"].options.instructionFiles'

dots="$workdir/dots"
mkdir -p "$dots"
export DOTFILES="$dots"
keys_rule="Read(/$dots/link/.ssh/keys/**)"

echo '{}' > "$settings"
harden
assert "$(jq '.permissions.deny | length' "$settings")" "19" "{} gains the nineteen deny rules"
# The ~/ anchor is what makes the Edit rule reach a marker above the repo; a bare or **/ path would not.
assert "$(deny_has 'Edit(~/**/.claude-files-issues)')" "yes" "the marker Edit rule is anchored at ~/"
assert "$(deny_has 'Bash(touch *.claude-files-issues*)')" "yes" "the marker touch rule is added verbatim"
assert "$(deny_has 'Edit(~/.claude-customers)')" "yes" "the customers file Edit rule is added"
assert "$(deny_has 'Read(~/.ssh/id_*)')" "yes" "a credential Read rule is added"
assert "$(jq -r "$instruction_files" "$settings")" "claude-md-and-agents-md" "instructionFiles is set when absent"
assert "$(deny_has 'Read(~/.ssh/config_private)')" "yes" "the revealed git-secret ssh config is denied"
assert "$(deny_has 'Read(~/.ssh/allowed_signers)')" "yes" "the revealed git-secret allowed_signers is denied"
# // anchors a rule at the filesystem root; a single / would be relative to the settings file.
assert "$(deny_has "$keys_rule")" "yes" "a checkout outside HOME is denied by its absolute path"

# A checkout under HOME gets a ~/ rule, so no username is written, and it replaces the rule of an earlier
# checkout: a moved checkout or a renamed user leaves no stale rule behind.
mkdir -p "$HOME/src/dots"
DOTFILES="$HOME/src/dots/" harden
assert "$(deny_has 'Read(~/src/dots/link/.ssh/keys/**)')" "yes" "a checkout under HOME is denied by a ~/ path"
assert "$(deny_has "$keys_rule")" "no" "the earlier checkout's rule is removed"
assert "$(jq '[.permissions.deny[] | select(contains("link/.ssh/keys"))] | length' "$settings")" "1" \
  "one checkout rule remains"
assert "$(jq '[.permissions.deny[] | select(contains("'"$HOME"'"))] | length' "$settings")" "0" \
  "no rule names the home directory"

echo '{}' > "$settings"
out="$(env -u DOTFILES "$SCRIPT" hardening "$settings" 2>&1)" && rc=0 || rc=$?
assert "$rc" "0" "without DOTFILES hardening still succeeds"
assert "$(jq '.permissions.deny | length' "$settings")" "18" "without DOTFILES the other rules still merge"
assert "$(jq '[.permissions.deny[] | select(contains("link/.ssh/keys"))] | length' "$settings")" "0" \
  "without DOTFILES no checkout rule is written"
assert "${out/*DOTFILES*/found}" "found" "without DOTFILES it says the checkout rule was skipped"

printf '{"permissions":{"deny":["%s"]}}\n' "$keys_rule" > "$settings"
env -u DOTFILES "$SCRIPT" hardening "$settings" 2>/dev/null
assert "$(deny_has "$keys_rule")" "yes" "without DOTFILES an existing checkout rule is kept"

printf '{"permissions":{"allow":["Bash(ls *)"],"deny":["Bash(rm -rf *)","Edit(~/.zshrc)"]}}\n' > "$settings"
harden
harden
assert "$(deny_has 'Bash(rm -rf *)')" "yes" "an existing deny entry is kept"
assert "$(jq '.permissions.deny | length' "$settings")" "20" "two runs over an overlapping list duplicate nothing"
assert "$(jq -c '.permissions.allow' "$settings")" '["Bash(ls *)"]' "the allow list is untouched"

printf '{"pluginConfigs":{"cc-plugin-agents-md@builtin":{"options":{"instructionFiles":"claude-md-or-agents-md","x":1}}}}\n' > "$settings"
harden
assert "$(jq -r "$instruction_files" "$settings")" "claude-md-or-agents-md" "a deliberate instructionFiles choice is left alone"
assert "$(jq -r '.pluginConfigs["cc-plugin-agents-md@builtin"].options.x' "$settings")" "1" "sibling plugin options are kept"

rm -f "$settings"
mv "$HOME/.claude/hooks/work-context.sh" "$workdir/guard"
harden && rc=0 || rc=$?
assert "$rc" "0" "hardening runs without the guard script, since it registers no hook"
assert "$(jq '.permissions.deny | length' "$settings")" "19" "hardening creates a missing file"
mv "$workdir/guard" "$HOME/.claude/hooks/work-context.sh"

printf '{"permissions": \n' > "$settings"
before="$(cksum < "$settings")"
harden 2>/dev/null && rc=0 || rc=$?
assert "$rc" "1" "hardening on invalid JSON exits 1"
assert "$(cksum < "$settings")" "$before" "hardening on invalid JSON leaves the file byte-identical"

"$SCRIPT" hardening 2>/dev/null && rc=0 || rc=$?
assert "$rc" "2" "hardening without a file is a usage error"

e_header "allows"

function allow() { "$SCRIPT" allows "$settings"; }

echo '{}' > "$settings"
allow
assert "$(jq -c '.permissions.allow' "$settings")" \
  '["Bash(git branch -D *)","Bash(git push origin --delete *)","Bash(git worktree remove *)"]' "{} gains the three clean-up rules"

printf '{"permissions":{"allow":["Bash(ls *)","Bash(git branch -D *)"],"deny":["Bash(rm -rf *)"]}}\n' > "$settings"
allow
allow
assert "$(jq '.permissions.allow | length' "$settings")" "4" "two runs over an overlapping list duplicate nothing"
assert "$(jq -c '.permissions.deny' "$settings")" '["Bash(rm -rf *)"]' "the deny list is untouched"

test_done
