#!/usr/bin/env bash
source "$DOTFILES/test/helper.sh"

e_header "$(basename "$0" .sh)"

# The theme is copied on its own to restricted boxes with only zsh and oh-my-zsh. So it is loaded here the same way:
# a copy of just the theme file, a bare omz config, no dotfiles in the environment, and no kube-ps1, which leaves
# the kubectl fallback. A stand-in kubectl reads the context and namespace out of the kubeconfig and logs each call.

if ! command -v zsh > /dev/null || [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  e_error "zsh and oh-my-zsh not found: CI installs both, so the theme check can't be skipped."
  test_done
fi

tmp="$(mktemp -d)"
mkdir -p "$tmp/bin" "$tmp/custom" "$tmp/zdotdir"
cp "$DOTFILES/link/.omz-custom/andrelin.zsh-theme" "$tmp/custom/"

cat > "$tmp/bin/kubectl" << 'EOF'
#!/bin/sh
echo "$*" >> "$KUBECTL_LOG"
case "$*" in
  "config current-context") sed -n 's/^current-context: *//p' "$KUBECONFIG" ;;
  "config view --minify"*) sed -n 's/^ *namespace: *//p' "$KUBECONFIG" ;;
esac
EOF
chmod +x "$tmp/bin/kubectl"

cat > "$tmp/zdotdir/.zshrc" << EOF
export ZSH="$HOME/.oh-my-zsh" ZSH_CUSTOM="$tmp/custom" ZSH_THEME=andrelin DISABLE_AUTO_UPDATE=true
plugins=(git)
source "\$ZSH/oh-my-zsh.sh"
EOF

kubeconfig="$tmp/kubeconfig"
write_kubeconfig() { printf 'current-context: %s\ncontexts:\n- context:\n    namespace: %s\n' "$1" "$2" > "$kubeconfig"; }
age_kubeconfig() { touch -t 202001010000 "$kubeconfig"; }

# Runs zsh commands in the bare setup with an otherwise empty environment, so nothing from these dotfiles leaks in.
in_theme_shell() {
  env -i HOME="$HOME" TERM=xterm PATH="$tmp/bin:/usr/bin:/bin:$(dirname "$(command -v zsh)")" \
    ZDOTDIR="$tmp/zdotdir" ZSH_CACHE_DIR="$tmp/cache" KUBECONFIG="$kubeconfig" KUBECTL_LOG="$tmp/calls" \
    zsh -i -c "$1" 2> /dev/null < /dev/null | sed $'s/\x1b\\][^\x07]*\x07//g'
}
prompt_kube='print -rn -- "$_kube_prompt"'
calls() { if [[ -f "$tmp/calls" ]]; then wc -l < "$tmp/calls" | tr -d ' '; else echo 0; fi; }

write_kubeconfig dev payments
age_kubeconfig

# Anything the theme needs from these dotfiles shows up here as an error, such as a call to one of their functions.
errors="$(env -i HOME="$HOME" TERM=xterm PATH="$tmp/bin:/usr/bin:/bin:$(dirname "$(command -v zsh)")" \
  ZDOTDIR="$tmp/zdotdir" ZSH_CACHE_DIR="$tmp/cache" KUBECONFIG="$kubeconfig" KUBECTL_LOG="$tmp/calls" \
  zsh -i -c 'print -P "$PROMPT"; _kube_prompt_update' 2>&1 > /dev/null < /dev/null)"
assert "$errors" "" "loads and renders without errors"
assert "$(in_theme_shell "_kube_prompt_update; $prompt_kube")" "%F{cyan}(⎈ dev:payments)%f " "shows context:namespace"
assert "$(in_theme_shell '(( $+functions[kube_ps1] )) || echo fallback')" "fallback" "kube-ps1 absent: fallback in use"

rm -f "$tmp/calls"
in_theme_shell '_kube_prompt_update; _kube_prompt_update; _kube_prompt_update' > /dev/null
assert "$(calls)" "2" "three prompts, one lookup (context and namespace)"

rm -f "$tmp/calls"
in_theme_shell "_kube_prompt_update; touch -t 202101010000 '$kubeconfig'; _kube_prompt_update" > /dev/null
assert "$(calls)" "4" "a changed kubeconfig is read again"

# Written within the current second: a second write in that same second would keep the mtime, so no caching yet.
# The write lands on a fresh second, and the run is retried if the clock moves on before the first prompt's check.
# Prints the kubectl calls the two prompts made: 4 when the first did not cache, 2 when it did.
same_second='
  zmodload zsh/datetime zsh/stat
  for attempt in 1 2 3 4 5; do
    : > "$KUBECTL_LOG"
    mtime=; while (( mtime != EPOCHSECONDS )); do touch "$KUBECONFIG"; zstat -A mtime +mtime "$KUBECONFIG"; done
    _kube_prompt_update
    (( EPOCHSECONDS == mtime )) || continue
    _kube_prompt_update
    wc -l < "$KUBECTL_LOG" | tr -d " "
    break
  done'
assert "$(in_theme_shell "$same_second")" "4" "a kubeconfig written this second is not cached"

write_kubeconfig dev ""
age_kubeconfig
assert "$(in_theme_shell "_kube_prompt_update; $prompt_kube")" "%F{cyan}(⎈ dev:default)%f " "no namespace: default"

write_kubeconfig "" ""
age_kubeconfig
assert "$(in_theme_shell "_kube_prompt_update; $prompt_kube")" "" "no current context: nothing shown"

rm -f "$kubeconfig" "$tmp/calls"
assert "$(in_theme_shell "_kube_prompt_update; $prompt_kube")" "" "no kubeconfig: nothing shown"
assert "$(calls)" "0" "no kubeconfig: kubectl never runs"

# With kube-ps1 loaded, the theme hands the segment to it and adds no hook of its own.
sed -i.bak '1i\
kube_ps1() { :; }
' "$tmp/zdotdir/.zshrc"
assert "$(in_theme_shell 'print -r -- "${PROMPT//$'"'\n'"'/ }" | grep -o "\$(kube_ps1)"; (( ${precmd_functions[(I)_kube_prompt_update]} )) && echo hook')" \
  '$(kube_ps1)' "kube-ps1 loaded: prompt uses it, no fallback hook"

rm -rf "$tmp"

test_done
