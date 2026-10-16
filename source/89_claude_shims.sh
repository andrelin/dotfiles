# Inside Claude Code only, put the git, gh, glab and az shims first on PATH, so the work-context guard also sees
# the calls aliases, functions and scripts make. Last of the .sh files, so no later PATH change lands in front.
if [[ -n "$CLAUDECODE" && -d "$HOME/.claude/shims" && ":$PATH:" != *":$HOME/.claude/shims:"* ]]; then
  export PATH="$HOME/.claude/shims:$PATH"
fi
