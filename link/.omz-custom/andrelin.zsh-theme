# Portable by design: this file is copied on its own to restricted Linux boxes that have zsh and oh-my-zsh but none
# of these dotfiles and can't install packages, and must give the same prompt there.
# So it needs nothing from source/, bin/ or vendor/, nor any plugin outside the default oh-my-zsh lib; an optional
# tool (kube-ps1, kubectl) is detected at load and given a fallback or skipped. Test changes in a bare omz config.

# Kubernetes context:namespace, shown only while a current context is set.
# kube-ps1 where it's installed; elsewhere a fallback that runs kubectl only when the kubeconfig changes.
if (( $+functions[kube_ps1] )); then
    KUBE_PS1_PREFIX="("
    KUBE_PS1_SEPARATOR=" "
    KUBE_PS1_SUFFIX=") "
    KUBE_PS1_SYMBOL_COLOR=cyan
    KUBE_PS1_CTX_COLOR=cyan
    KUBE_PS1_NS_COLOR=cyan
    KUBE_PS1_HIDE_IF_NOCONTEXT=true
    _kube_segment='$(kube_ps1)'
else
    autoload -Uz add-zsh-hook
    zmodload -F zsh/stat b:zstat 2>/dev/null
    zmodload zsh/datetime 2>/dev/null
    typeset -g _kube_prompt _kube_prompt_key

    # Runs as a precmd hook rather than inside PROMPT, whose $(...) is a subshell that can't keep the cache.
    function _kube_prompt_update() {
        local config mtime key ctx ns recent=
        (( $+commands[kubectl] )) || { _kube_prompt=; return; }
        for config in ${(s.:.)${KUBECONFIG:-$HOME/.kube/config}}; do
            [[ -f $config ]] || continue
            mtime=
            (( $+builtins[zstat] )) && zstat -A mtime +mtime -- $config 2>/dev/null
            # mtime has one-second resolution: a second write in the same second would look unchanged.
            [[ -n $mtime ]] && (( mtime >= ${EPOCHSECONDS:-0} )) && recent=1
            key+="$config:$mtime "
        done
        [[ -z $key ]] && { _kube_prompt=; _kube_prompt_key=; return; }
        # Without zsh/stat there's no mtime to compare, so kubectl runs on every prompt.
        (( $+builtins[zstat] )) && [[ $key == "$_kube_prompt_key" ]] && return
        # Not cached while the kubeconfig was written this second, so the next prompt looks again.
        [[ -n $recent ]] && _kube_prompt_key= || _kube_prompt_key=$key

        ctx=$(kubectl config current-context 2>/dev/null)
        if [[ -n $ctx ]]; then
            ns=$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)
            _kube_prompt="%F{cyan}(⎈ ${ctx}:${ns:-default})%f "
        else
            _kube_prompt=
        fi
    }
    add-zsh-hook precmd _kube_prompt_update
    _kube_segment='${_kube_prompt}'
fi

PROMPT=$'
%{$fg[blue]%}%~%{$reset_color%} $(git_prompt_info)$(virtualenv_prompt_info)'"$_kube_segment"$'[%T]
> '
unset _kube_segment

PROMPT2="_> "

ZSH_THEME_SCM_PROMPT_PREFIX="%{$fg[green]%}["
ZSH_THEME_GIT_PROMPT_PREFIX=$ZSH_THEME_SCM_PROMPT_PREFIX
ZSH_THEME_GIT_PROMPT_SUFFIX="]%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[red]%}*%{$fg[green]%}"
ZSH_THEME_GIT_PROMPT_CLEAN=""

ZSH_THEME_VIRTUALENV_PREFIX="("
ZSH_THEME_VIRTUALENV_SUFFIX=") "
