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
# The script refuses to register a guard that isn't there, so HOME holds a stand-in.
export HOME="$workdir/home"
mkdir -p "$HOME/.claude/hooks"
touch "$HOME/.claude/hooks/work-context.sh"

# The guard's two hook entries, exactly as the init script must register them.
pre_tool_use='{"matcher":"Bash|Monitor|Write|Edit|MultiEdit|NotebookEdit","hooks":[{"type":"command","command":"/bin/bash ~/.claude/hooks/work-context.sh pre-tool-use","timeout":10,"onFailure":"block"}]}'
session_start='{"hooks":[{"type":"command","command":"/bin/bash ~/.claude/hooks/work-context.sh session-start","timeout":10}]}'
cc_pre='{"matcher":"","hooks":[{"type":"command","command":"cc-status pre"}]}'
cc_start='{"hooks":[{"type":"command","command":"cc-status start"}]}'

function merge() { "$SCRIPT" hooks "$settings"; }

# The entries for one event whose commands run the guard.
function owned() {
  jq -c --arg e "$1" '[.hooks[$e][]? | select(any(.hooks[]?; .command | contains("work-context.sh")))]' "$settings"
}

echo '{}' > "$settings"
merge
assert "$(owned PreToolUse)" "[$pre_tool_use]" "{} gains the PreToolUse entry"
assert "$(owned SessionStart)" "[$session_start]" "{} gains the SessionStart entry"

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

others='{"model":"opus","autoMode":{"enabled":true},"enabledPlugins":{"superpowers@x":true},"hooks":{"Stop":[{"hooks":[{"type":"command","command":"say done"}]}]}}'
printf '%s\n' "$others" > "$settings"
merge
assert "$(jq -S 'del(.hooks.PreToolUse, .hooks.SessionStart)' "$settings")" "$(jq -S . <<< "$others")" \
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

"$SCRIPT" bogus "$settings" 2>/dev/null && rc=0 || rc=$?
assert "$rc" "2" "an unknown subcommand is a usage error"

test_done
