# Lightweight kube-ps1 replacement
function get_kube_prompt() {
    # Get current context
    local ctx=$(kubectl config current-context 2>/dev/null)
    if [[ -n "$ctx" ]]; then
        # Get current namespace (defaults to 'default' if not set)
        local ns=$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)
        ns=${ns:-default}
        # Format the output (⎈ context:namespace)
        echo "%F{cyan}(⎈ ${ctx}:${ns})%f "
    fi
}

PROMPT=$'
%{$fg[blue]%}%~%{$reset_color%} $(git_prompt_info)$(virtualenv_prompt_info)$(get_kube_prompt)[%T]
> '

PROMPT2="_> "

ZSH_THEME_SCM_PROMPT_PREFIX="%{$fg[green]%}["
ZSH_THEME_GIT_PROMPT_PREFIX=$ZSH_THEME_SCM_PROMPT_PREFIX
ZSH_THEME_GIT_PROMPT_SUFFIX="]%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[red]%}*%{$fg[green]%}"
ZSH_THEME_GIT_PROMPT_CLEAN=""

ZSH_THEME_VIRTUALENV_PREFIX="("
ZSH_THEME_VIRTUALENV_SUFFIX=") "

KUBE_PS1_SYMBOL_ENABLE=false
