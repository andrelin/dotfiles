#!/bin/bash
# Work-context guard: resolves whether a repository is personal, company or customer work, and blocks history and
# remote writes whose strictest target is a customer repository. The rules it enforces are claude/CLAUDE.md § Work contexts.
#
# Must stay bash 3.2-compatible: Claude Code runs hooks under macOS's /bin/bash, and a hook's PATH may hold no
# Homebrew bash. So no mapfile, associative arrays, ${var,,} or |&. `level` and `check-argv` use only builtins and
# git, so Task 2b's shim can call them under a PATH holding nothing else.
#
# Usage: work-context.sh level [dir] | check-argv <dir> <tool> [args...] | pre-tool-use | can-file-issue [dir]
#        | session-start

# Byte semantics, so substring offsets into a command stay cheap and match the separator scan.
LC_ALL=C

MARKER=.claude-files-issues
WAIVE_VAR=WORK_CONTEXT_WAIVE
TRACKED="GH_REPO GH_HOST GITLAB_HOST GL_HOST GITLAB_URI GITLAB_REPO GIT_DIR GIT_WORK_TREE"
GIT=${WORK_CONTEXT_GIT:-git}
UNKNOWN_DIR="<unknown directory>"
TILDE='~'
FORCE_WRITE=0
X1=$'\001'
NL=$'\n'
BSNL=$'\\\n'
TOOL_RE='(^|[^[:alnum:]_-])(git|gh|glab|az)([^[:alnum:]_-]|$)'

# --- helpers -------------------------------------------------------------------------------------------------

canon() { ( cd -P -- "$1" 2>/dev/null && printf '%s' "$PWD" ); }

# Drop PATH entries that are ~/.claude/shims, so the guard's own git calls never recurse through Task 2b's shim.
strip_shims() {
  [[ -d "$HOME/.claude/shims" ]] || return 0
  PATH=$(
    shims=$(canon "$HOME/.claude/shims") || { printf '%s' "$PATH"; exit 0; }
    out=""
    IFS=:
    set -f
    for e in $PATH; do
      if [[ -n $e ]] && cd -P -- "$e" 2>/dev/null && [[ $PWD == "$shims" ]]; then continue; fi
      out=${out:+$out:}$e
    done
    printf '%s' "$out"
  )
}

lower_eq() {
  local r=1
  shopt -s nocasematch
  [[ $1 == "$2" ]] && r=0
  shopt -u nocasematch
  return $r
}

is_gitlab_host() {
  local r=1
  shopt -s nocasematch
  [[ $1 == gitlab.com || $1 == *gitlab* ]] && r=0
  shopt -u nocasematch
  return $r
}

# A host variable may hold a URL (GITLAB_URI=https://gitlab.example.com); keep the host alone.
host_only() {
  local h=$1
  h=${h#*://}
  h=${h%%/*}
  h=${h##*@}
  printf '%s' "${h%%:*}"
}

# The worst target seen so far: level, and the remote and URL that named it, for the deny message.
reset_worst() { W_RANK=0; W_LEVEL=personal; W_REMOTE=""; W_URL=""; }
bump() {
  local r
  case $1 in personal) r=1 ;; company) r=2 ;; *) r=3 ;; esac
  if (( r > W_RANK )); then W_RANK=$r; W_LEVEL=$1; W_REMOTE=$2; W_URL=$3; fi
}

# --- level resolution ----------------------------------------------------------------------------------------

# parse_url <url> -> U_HOST U_OWNER U_REPO; fails when it isn't a remote URL.
parse_url() {
  local u=$1 rest host path
  U_HOST="" U_OWNER="" U_REPO=""
  case $u in
    *://*)
      case ${u%%://*} in ssh|git+ssh|ssh+git|https|http|git) ;; *) return 1 ;; esac
      rest=${u#*://}
      [[ $rest == */* ]] || return 1
      host=${rest%%/*}
      path=${rest#*/}
      host=${host##*@}
      host=${host%%:*}
      ;;
    /*|./*|../*) return 1 ;;
    *:*)
      host=${u%%:*}
      [[ $host == */* ]] && return 1
      host=${host##*@}
      path=${u#*:}
      ;;
    *) return 1 ;;
  esac
  [[ -n $host ]] || return 1
  path=${path#/}
  path=${path%/}
  path=${path%.git}
  if lower_eq "$host" ssh.dev.azure.com && [[ $path == v3/* ]]; then path=${path#v3/}; fi
  [[ $path == */* ]] || return 1
  U_HOST=$host U_OWNER=${path%%/*} U_REPO=${path##*/}
  [[ -n $U_OWNER && -n $U_REPO ]]
}

# classify <host> <owner> <repo> -> CL
classify() {
  shopt -s nocasematch
  if [[ $2 == uptimeconsulting ]]; then
    CL=company
  elif [[ $2 == andrelin && $1 == github.com ]]; then
    if [[ $3 == *uptime* ]]; then CL=company; else CL=personal; fi
  else
    CL=customer
  fi
  shopt -u nocasematch
}

url_class() {
  if parse_url "$1"; then classify "$U_HOST" "$U_OWNER" "$U_REPO"; else CL=customer; fi
}

# url_class_at <url> <base-dir>: a remote URL, or a local path (file://, absolute, relative to base-dir).
url_class_at() {
  local u=$1 p
  U_HOST=""
  case $u in
    file://*) p=${u#file://} ;;
    /*|./*|../*|.) p=$u ;;
    *:*) url_class "$u"; return ;;
    *) p=$u ;;
  esac
  [[ $p == /* ]] || p=$2/$p
  if [[ -d $p ]]; then level_of_dir "$p"; else CL=customer; fi
}

in_scratch() {
  local t p prefix list
  t=$(canon "$1") || return 1
  list=${WORK_CONTEXT_SCRATCH_DIRS-${TMPDIR:-/tmp}:/tmp:/private/tmp}
  local IFS=:
  set -f
  for p in $list; do
    [[ -n $p ]] || continue
    prefix=$(canon "$p") || continue
    if [[ $t/ == "$prefix"/* ]]; then set +f; return 0; fi
  done
  set +f
  return 1
}

# level_of_dir <dir> -> CL, LV_URL (origin, or empty), LV_REPO (1 when dir is in a repository).
level_of_dir() {
  local dir=$1 top url
  LV_URL="" LV_REPO=0
  if ! ( unset GIT_DIR GIT_WORK_TREE; "$GIT" -C "$dir" rev-parse --absolute-git-dir >/dev/null 2>&1 ); then
    CL=customer
    return
  fi
  LV_REPO=1
  url=$( unset GIT_DIR GIT_WORK_TREE; "$GIT" -C "$dir" remote get-url origin 2>/dev/null )
  if [[ -n $url ]]; then
    LV_URL=$url
    url_class "$url"
    return
  fi
  top=$( unset GIT_DIR GIT_WORK_TREE; "$GIT" -C "$dir" rev-parse --show-toplevel 2>/dev/null )
  if [[ -n $top ]] && in_scratch "$top"; then CL=personal; else CL=customer; fi
}

# --- the repository a git or platform call acts on -----------------------------------------------------------

# resolve_repo <dir> [git-dir] -> R_GITDIR, R_DIR. Only --git-dir and GIT_DIR select it, as in git.
resolve_repo() {
  R_DIR=$1
  R_GITDIR=$( "$GIT" -C "$1" ${2:+"--git-dir=$2"} rev-parse --absolute-git-dir 2>/dev/null )
  [[ -n $R_GITDIR ]]
}

rgit() { ( unset GIT_DIR GIT_WORK_TREE; "$GIT" --git-dir="$R_GITDIR" "$@" ) 2>/dev/null; }

# repo_top <git-dir-override> -> R_TOP, the resolved repository's own toplevel.
repo_top() {
  R_TOP=""
  if [[ ${R_GITDIR##*/} == .git ]]; then
    R_TOP=${R_GITDIR%/*}
  elif [[ -z $1 && -z ${GIT_DIR-} ]]; then
    R_TOP=$( unset GIT_WORK_TREE; "$GIT" -C "$R_DIR" rev-parse --show-toplevel 2>/dev/null )
  fi
  [[ -n $R_TOP ]]
}

# origin_target [git-dir-override]: counts origin, or the no-origin rule. Sets ORIGIN_URL and ORIGIN_HOST.
origin_target() {
  ORIGIN_URL=$(rgit remote get-url origin)
  ORIGIN_HOST=""
  if [[ -n $ORIGIN_URL ]]; then
    url_class_at "$ORIGIN_URL" "$R_DIR"
    ORIGIN_HOST=$U_HOST
    bump "$CL" origin "$ORIGIN_URL"
    T_LEVEL+=("$CL"); T_HOST+=("$ORIGIN_HOST")
  elif repo_top "$1" && in_scratch "$R_TOP"; then
    bump personal "no origin remote" ""
    T_LEVEL+=(personal); T_HOST+=("")
  else
    bump customer "no origin remote" ""
    T_LEVEL+=(customer); T_HOST+=("")
  fi
}

remote_target() {
  local url
  url=$(rgit remote get-url "$1") || return 0
  [[ -n $url ]] || return 0
  url_class_at "$url" "$R_DIR"
  bump "$CL" "$1" "$url"
  T_LEVEL+=("$CL"); T_HOST+=("$U_HOST")
}

# --- git -----------------------------------------------------------------------------------------------------

# Builtins can't be shadowed by an alias; listing the common ones skips a git call on most reads.
COMMON_BUILTINS=" add am apply bisect blame branch cat-file checkout cherry-pick clean clone commit config describe
  diff fetch for-each-ref grep help init log ls-files ls-remote merge mv pull push rebase reflog remote reset restore
  rev-list rev-parse revert rm show show-ref stash status switch symbolic-ref tag version worktree "

is_builtin() {
  local list
  list=$( "$GIT" --list-cmds=builtins 2>/dev/null ) || return 0
  [[ -n $list ]] || return 0
  case "$NL$list$NL" in *"$NL$1$NL"*) return 0 ;; esac
  return 1
}

# push_targets <args after push>: the write's own target, checked in git's order.
push_targets() {
  local a skip="" repo_opt="" pos="" opts=1 name branch
  for a in "$@"; do
    if [[ -n $skip ]]; then
      [[ $skip == repo ]] && repo_opt=$a
      skip=""
      continue
    fi
    if (( opts )); then
      case $a in
        --) opts=0; continue ;;
        -o|--push-option|--receive-pack|--exec) skip=value; continue ;;
        --repo) skip=repo; continue ;;
        --repo=*) repo_opt=${a#--repo=}; continue ;;
        -*) continue ;;
      esac
    fi
    pos=$a
    break
  done
  name=${pos:-$repo_opt}
  if [[ -z $name ]]; then
    branch=$(rgit symbolic-ref --short -q HEAD)
    [[ -n $branch ]] && name=$(rgit config --get "branch.$branch.pushRemote")
    [[ -z $name ]] && name=$(rgit config --get remote.pushDefault)
    [[ -z $name && -n $branch ]] && name=$(rgit config --get "branch.$branch.remote")
    [[ -z $name ]] && name=origin
    # git push fails without that remote, and origin's own rule has already counted.
    rgit remote get-url "$name" >/dev/null || [[ $name == . ]] || return 0
  fi
  push_target "$name"
}

push_target() {
  local t=$1 urls u p
  urls=$(rgit remote get-url --push --all "$t")
  if [[ -n $urls ]]; then
    while IFS= read -r u; do
      [[ -n $u ]] || continue
      url_class_at "$u" "$R_DIR"
      bump "$CL" "$t" "$u"
    done <<< "$urls"
    return
  fi
  p=$t
  [[ $p == /* ]] || p=$R_DIR/$p
  if [[ -d $p ]]; then
    level_of_dir "$p"
    bump "$CL" "$t" "$p"
  elif [[ $t == *:* || $t == */* ]]; then
    url_class "$t"
    bump "$CL" "$t" "$t"
  else
    bump customer "$t" "(not a remote, directory or URL)"
  fi
}

check_git() {
  local dir=$1
  shift
  local -a a=("$@") shown=() rest=()
  local n=$# i=0 w gitdir="" sub="" orig_sub val forced=0 forbidden=0 r first=""
  while (( i < n )); do
    w=${a[i]}
    case $w in
      -C)
        val=${a[i+1]}
        if [[ -n $val ]]; then
          if [[ $val == /* ]]; then dir=$val; else dir=$dir/$val; fi
        fi
        i=$((i + 2))
        continue
        ;;
      --git-dir) gitdir=${a[i+1]}; shown+=("$w" "${a[i+1]}"); i=$((i + 2)); continue ;;
      --git-dir=*) gitdir=${w#--git-dir=} ;;
      -c|--namespace|--config-env|--attr-source|--work-tree) shown+=("$w" "${a[i+1]}"); i=$((i + 2)); continue ;;
      -*) ;;
      *) break ;;
    esac
    shown+=("$w")
    i=$((i + 1))
  done
  (( i < n )) || return 0
  sub=${a[i]}
  orig_sub=$sub
  rest=("${a[@]:i+1}")

  if [[ $COMMON_BUILTINS != *" $sub "* ]]; then
    val=$( "$GIT" -C "$dir" ${gitdir:+"--git-dir=$gitdir"} config --get "alias.$sub" 2>/dev/null )
    if [[ -n $val ]] && ! is_builtin "$sub"; then
      case $val in
        '!'*|-*) forced=1 ;;
        *) sub=${val%%[[:space:]]*} ;;
      esac
    fi
  fi

  case $sub in
    commit|commit-tree|cherry-pick|revert|am|push) forbidden=1 ;;
    rebase|merge)
      for r in "${rest[@]}"; do
        [[ $r == --continue || $r == --skip ]] && forbidden=1
      done
      ;;
    subtree)
      for r in "${rest[@]}"; do
        [[ $r == -* ]] && continue
        first=$r
        break
      done
      [[ $first == push ]] && forbidden=1
      ;;
  esac
  (( forced )) && forbidden=1
  (( forbidden )) || return 0

  reset_worst
  T_LEVEL=() T_HOST=()
  if ! resolve_repo "$dir" "$gitdir"; then
    bump customer "no git repository" ""
  else
    origin_target "$gitdir"
    [[ $sub == push ]] && push_targets "${rest[@]}"
  fi
  [[ $W_LEVEL != customer ]] && return 0
  deny "$dir" git "${shown[@]}" "$orig_sub" "${rest[@]}"
  return 2
}

# --- gh and glab ---------------------------------------------------------------------------------------------

# platform_host <tool>: the host a bare owner/repo names, from the tool's host variables.
platform_host() {
  local v
  if [[ $1 == gh ]]; then
    [[ -n ${GH_HOST-} ]] && { host_only "$GH_HOST"; return; }
    printf github.com
  else
    for v in "${GITLAB_HOST-}" "${GL_HOST-}" "${GITLAB_URI-}"; do
      [[ -n $v ]] && { host_only "$v"; return; }
    done
    printf gitlab.com
  fi
}

# repo_value_target <tool> <value> <label>: an -R / GH_REPO / positional owner/repo value, added as a target.
repo_value_target() {
  local tool=$1 v=$2 host path first
  case $v in
    *://*|*@*:*)
      url_class "$v"
      host=$U_HOST
      ;;
    *)
      first=${v%%/*}
      if [[ $v == */* && $first == *.* ]]; then
        host=$first
        path=${v#*/}
      else
        host=$(platform_host "$tool")
        path=$v
      fi
      if [[ $path == */* ]]; then classify "$host" "${path%%/*}" "${path##*/}"; else CL=customer; fi
      ;;
  esac
  bump "$CL" "$3" "$v"
  T_LEVEL+=("$CL"); T_HOST+=("$host")
}

named_target() {
  classify "$1" "$2" "$3"
  bump "$CL" "$4" "$5"
  T_LEVEL+=("$CL"); T_HOST+=("$1")
  NAMED=1
}

has_marker() {
  local t h p
  t=$(canon "$1") || return 1
  h=$(canon "$HOME") || return 1
  [[ $t == "$h"/* ]] || return 1
  p=${t%/*}
  while [[ $p == "$h"/* ]]; do
    [[ -e $p/$MARKER ]] && return 0
    p=${p%/*}
  done
  return 1
}

# The marker: the repo's own issues only, on a host can-file-issue maps, under an opted-in tree.
marker_ok() {
  local tool=$1 remotes v
  (( FLAG_USED || NAMED )) && return 1
  (( REPO_OK )) || return 1
  remotes=$(rgit remote)
  [[ $remotes == origin ]] || return 1
  [[ -n $ORIGIN_HOST ]] || return 1
  if [[ $tool == gh ]]; then
    lower_eq "$ORIGIN_HOST" github.com || return 1
    [[ -z ${GH_HOST-} ]] || lower_eq "$(host_only "$GH_HOST")" "$ORIGIN_HOST" || return 1
  else
    is_gitlab_host "$ORIGIN_HOST" || return 1
    for v in "${GITLAB_HOST-}" "${GL_HOST-}" "${GITLAB_URI-}"; do
      [[ -z $v ]] || lower_eq "$(host_only "$v")" "$ORIGIN_HOST" || return 1
    done
  fi
  repo_top "" || return 1
  has_marker "$R_TOP"
}

gh_read_allowed() {
  case "$1 $2" in
    "pr view"|"pr list"|"pr status"|"pr diff"|"pr checks"|"pr checkout") return 0 ;;
    "issue view"|"issue list"|"issue status") return 0 ;;
    "repo view"|"repo clone") return 0 ;;
    "release view"|"release list"|"release download") return 0 ;;
    "run view"|"run list"|"run watch"|"run download") return 0 ;;
    "workflow view"|"workflow list"|"label list"|"auth status") return 0 ;;
  esac
  case $1 in help|search|browse|status) return 0 ;; esac
  return 1
}

glab_read_allowed() {
  case "$1 $2" in
    "mr view"|"mr list"|"mr diff"|"mr checkout") return 0 ;;
    "issue view"|"issue list"|"repo view"|"repo clone") return 0 ;;
    "ci view"|"ci list"|"ci status"|"ci trace") return 0 ;;
    "release view"|"release list"|"release download"|"label list"|"auth status") return 0 ;;
  esac
  [[ $1 == help ]]
}

# api_read <methods...> -- uses FIELDS and the args: GET explicitly, or no method and no fields.
api_read() {
  local m
  if (( $# )); then
    for m in "$@"; do lower_eq "$m" GET || return 1; done
    return 0
  fi
  (( FIELDS == 0 ))
}

check_platform() {
  local dir=$1 tool=$2
  shift 2
  local -a args=("$@") pos=() repo_flags=() methods=()
  local a next="" opts=1 hostname="" read=0 issue_create=0 m id re host i
  FIELDS=0
  for a in "$@"; do
    if [[ -n $next ]]; then
      case $next in
        repo) repo_flags+=("$a") ;;
        method) methods+=("$a") ;;
        hostname) hostname=$a ;;
      esac
      next=""
      continue
    fi
    if (( opts )); then
      case $a in
        --) opts=0; continue ;;
        -R|--repo) next=repo; continue ;;
        -R?*) repo_flags+=("${a#-R}"); continue ;;
        --repo=*) repo_flags+=("${a#--repo=}"); continue ;;
        -X|--method) next=method; continue ;;
        -X?*) methods+=("${a#-X}"); continue ;;
        --method=*) methods+=("${a#--method=}"); continue ;;
        --hostname) next=hostname; continue ;;
        --hostname=*) hostname=${a#--hostname=}; continue ;;
        -f|-F|--field|--raw-field|--input) FIELDS=1; next=value; continue ;;
        -f?*|-F?*|--field=*|--raw-field=*|--input=*) FIELDS=1; continue ;;
        -b|--body|-t|--title|-m|--message|-d|--description|-H|--header|--head|-B|--base|-q|--jq|--template|-T) next=value; continue ;;
        -a|--assignee|-l|--label|-r|--reviewer|-M|--milestone|-p|--project|--body-file) next=value; continue ;;
        -*) continue ;;
      esac
    fi
    pos+=("$a")
  done

  if (( ${#pos[@]} == 0 )); then
    read=1
  elif [[ ${pos[0]} == api ]]; then
    if [[ ${pos[1]-} == graphql ]]; then
      read=1
      (( FORCE_WRITE )) && read=0
      shopt -s nocasematch
      for a in "${args[@]}"; do [[ $a == *mutation* ]] && read=0; done
      shopt -u nocasematch
    elif (( ${#methods[@]} )); then
      api_read "${methods[@]}" && read=1
    else
      api_read && read=1
    fi
  elif [[ $tool == gh ]]; then
    gh_read_allowed "${pos[0]}" "${pos[1]-}" && read=1
  else
    glab_read_allowed "${pos[0]}" "${pos[1]-}" && read=1
  fi
  (( read )) && return 0

  [[ ${pos[0]} == issue && ${pos[1]-} == create ]] && issue_create=1
  reset_worst
  T_LEVEL=() T_HOST=()
  NAMED=0 FLAG_USED=0 REPO_OK=0 ORIGIN_HOST=""

  local -a flag_values=()
  if (( ${#repo_flags[@]} )); then
    flag_values=("${repo_flags[@]}")
  elif [[ $tool == gh && -n ${GH_REPO-} ]]; then
    flag_values=("$GH_REPO")
  elif [[ $tool == glab && -n ${GITLAB_REPO-} ]]; then
    flag_values=("$GITLAB_REPO")
  fi
  (( ${#flag_values[@]} )) && FLAG_USED=1

  # A named repo replaces the directory's remotes, except for issue create, where it is added.
  if (( ! FLAG_USED || issue_create )); then
    if resolve_repo "$dir" ""; then
      REPO_OK=1
      origin_target ""
      remote_target upstream
      if [[ $tool == gh ]]; then
        remote_target github
        while IFS= read -r a; do
          a=${a%% *}
          a=${a#remote.}
          a=${a%.gh-resolved}
          [[ -n $a && $a != origin && $a != upstream && $a != github ]] && remote_target "$a"
        done <<< "$(rgit config --get-regexp '^remote\..*\.gh-resolved$')"
      fi
    else
      bump customer "no git repository" ""
      T_LEVEL+=(customer); T_HOST+=("")
    fi
  fi
  for a in "${flag_values[@]}"; do
    repo_value_target "$tool" "$a" "-R"
  done

  # Targets named in arguments.
  for a in "${pos[@]}"; do
    case $a in
      http://*|https://*)
        m=${a#*://}
        host=${m%%/*}
        m=${m#*/}
        named_target "$host" "${m%%/*}" "$(i=${m#*/}; printf '%s' "${i%%/*}")" "argument" "$a"
        ;;
    esac
  done
  if [[ ${pos[0]} == repo && -n ${pos[2]-} && ${pos[2]} == */* && ${pos[2]} != *://* ]]; then
    repo_value_target "$tool" "${pos[2]}" "argument"
    NAMED=1
  fi
  if [[ ${pos[0]} == api && -n ${pos[1]-} ]]; then
    host=$hostname
    [[ -n $host ]] || host=$(platform_host "$tool")
    re='^/?repos/([^/?]+)/([^/?]+)([/?]|$)'
    if [[ ${pos[1]} =~ $re ]]; then
      case "${BASH_REMATCH[1]}${BASH_REMATCH[2]}" in
        *'{'*|:*|*:*) ;;
        *) named_target "$host" "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "endpoint" "${pos[1]}" ;;
      esac
    fi
    re='^/?projects/([^/?]+)([/?]|$)'
    if [[ $tool == glab && ${pos[1]} =~ $re ]]; then
      id=${BASH_REMATCH[1]}
      case $id in
        '{'*|:*) ;;
        *%2[Ff]*)
          id=${id//%2F//}
          id=${id//%2f//}
          named_target "$host" "${id%%/*}" "${id##*/}" "endpoint" "${pos[1]}"
          ;;
        *)
          bump customer "endpoint" "${pos[1]}"
          T_LEVEL+=(customer); T_HOST+=("$host")
          NAMED=1
          ;;
      esac
    fi
  fi

  (( W_RANK <= 2 )) && return 0
  (( issue_create )) && marker_ok "$tool" && return 0
  deny "$dir" "$tool" "${args[@]}"
  return 2
}

# --- az ------------------------------------------------------------------------------------------------------

check_az() {
  local dir=$1 a last next="" write=1
  shift
  local -a cmdw=()
  for a in "$@"; do
    [[ $a == -* ]] && break
    cmdw+=("$a")
  done
  (( ${#cmdw[@]} )) || return 0
  case ${cmdw[0]} in repos|pipelines|boards|devops) ;; *) return 0 ;; esac
  last=${cmdw[${#cmdw[@]}-1]}
  case $last in list|show) return 0 ;; esac
  if [[ ${cmdw[0]} == devops && $last == invoke ]]; then
    write=0
    for a in "$@"; do
      if [[ -n $next ]]; then lower_eq "$a" GET || write=1; next=""; continue; fi
      case $a in
        --http-method) next=1 ;;
        --http-method=*) lower_eq "${a#*=}" GET || write=1 ;;
      esac
    done
    (( write )) || return 0
  fi
  reset_worst
  T_LEVEL=() T_HOST=()
  if resolve_repo "$dir" ""; then origin_target ""; else bump customer "no git repository" ""; fi
  [[ $W_LEVEL != customer ]] && return 0
  deny "$dir" az "$@"
  return 2
}

check_argv() {
  local dir=$1 tool=${2##*/}
  shift 2
  case $tool in
    git) check_git "$dir" "$@" ;;
    gh|glab) check_platform "$dir" "$tool" "$@" ;;
    az) check_az "$dir" "$@" ;;
    *) return 0 ;;
  esac
}

# --- messages ------------------------------------------------------------------------------------------------

quote_words() {
  local out
  (( $# )) || return 0
  printf -v out '%q ' "$@"
  printf '%s' "${out% }"
}

# deny <dir> <tool> <args...>
deny() {
  local dir=$1 seg prefix="" v waive="" qdir
  shift
  for v in $TRACKED; do
    [[ -n ${!v+x} ]] && prefix+="$v=$(quote_words "${!v}") "
  done
  seg=$prefix$(quote_words "$@")
  if [[ $dir == "$UNKNOWN_DIR" ]]; then qdir=$dir; else qdir=$(quote_words "$dir"); fi
  [[ -d "$HOME/.claude/shims" ]] && waive="$WAIVE_VAR=1 "
  printf '%s\n' "Blocked by the work-context guard: $dir is a $W_LEVEL repository ($W_REMOTE${W_URL:+ $W_URL}), and \`$seg\` writes to its history or remote, or isn't on the guard's read allowlist; both belong to the user." \
    "Prepare the working tree, then give the user the exact command to run:" \
    "\`! cd $qdir && $waive$seg\`. Rules: ~/.claude/CLAUDE.md § Work contexts." >&2
}

deny_marker() {
  echo "Only the user creates $MARKER: ask them to run \`! touch $1\`" >&2
  exit 2
}

deny_waiver() {
  echo "Only the user waives the guard: give them the command with \`! $WAIVE_VAR=1 ${1:-<command>}\`" >&2
  exit 2
}

deny_jq() {
  echo "work-context guard: jq is required to check this call ($1); install jq, or ask the user to run it." >&2
  exit 2
}

# --- pre-tool-use: input -------------------------------------------------------------------------------------

JQ_PROG='
def s: if type == "string" then . else "" end;
def sets_waiver: test("WORK_CONTEXT_WAIVE[[:space:]]*=") or test("export[^\\n]*WORK_CONTEXT_WAIVE")
  or test("\"WORK_CONTEXT_WAIVE\"[[:space:]]*:");
(.tool_name | s), "\u0000",
(.tool_input.command | s), "\u0000",
(.tool_input.file_path | s), "\u0000",
(.tool_input.notebook_path | s), "\u0000",
(.cwd | s), "\u0000",
([.tool_input.content, .tool_input.new_string, .tool_input.new_source,
  (.tool_input.edits | if type == "array" then .[] | objects | .new_string else empty end)]
  | map(select(type == "string")) | if any(sets_waiver) then "1" else "0" end), "\u0000",
"OK", "\u0000"'

read_input() {
  local sentinel=""
  { IFS= read -r -d '' TOOL
    IFS= read -r -d '' CMD
    IFS= read -r -d '' FPATH
    IFS= read -r -d '' NBPATH
    IFS= read -r -d '' CWD
    IFS= read -r -d '' SETS_WAIVER
    IFS= read -r -d '' sentinel
  } < <(jq -j "$JQ_PROG" 2>/dev/null)
  [[ $sentinel == OK ]]
}

# Without jq: block anything that could need the full parse, pass the rest so a session keeps working.
no_jq_path() {
  local input="" re
  IFS= read -r -d '' input
  [[ $input == *"$MARKER"* ]] && deny_jq "it names $MARKER"
  [[ $input == *"$WAIVE_VAR"* ]] && deny_jq "it names $WAIVE_VAR"
  re='"command"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)"'
  if [[ $input =~ $re ]]; then
    CMD=${BASH_REMATCH[1]}
    CMD=${CMD//\\n/ }
    CMD=${CMD//\\t/ }
    CMD=${CMD//\\r/ }
  elif [[ $input == *'"command"'* ]]; then
    deny_jq "its command could not be read"
  else
    exit 0
  fi
  [[ $CMD =~ $TOOL_RE ]] && deny_jq "it runs git, gh, glab or az"
  exit 0
}

exempt_path() {
  local p=$1 guard_dir top parent full
  guard_dir=${BASH_SOURCE[0]%/*}
  [[ $guard_dir == "${BASH_SOURCE[0]}" ]] && guard_dir=.
  guard_dir=$(canon "$guard_dir") || return 1
  case $guard_dir in */claude/hooks) top=${guard_dir%/claude/hooks} ;; *) return 1 ;; esac
  [[ $p == /* ]] || return 1
  parent=${p%/*}
  full=$(canon "${parent:-/}") || return 1
  full=$full/${p##*/}
  case $full in
    "$top"/claude/hooks/work-context.sh|"$top"/claude/shims/shim.sh) return 0 ;;
    "$top"/test/test_work_context.sh|"$top"/test/test_claude_shims.sh) return 0 ;;
    "$top"/*.md) return 0 ;;
  esac
  return 1
}

# --- pre-tool-use: command parsing ---------------------------------------------------------------------------

init_env() {
  local v
  for v in $TRACKED; do
    if [[ -n ${!v+x} ]]; then printf -v "CE_$v" '%s' "${!v}"; printf -v "CS_$v" 1; else printf -v "CS_$v" 0; fi
  done
}

seg_env_from_current() {
  local v e s
  for v in $TRACKED; do
    e=CE_$v s=CS_$v
    printf -v "SE_$v" '%s' "${!e-}"
    printf -v "SS_$v" '%s' "${!s}"
  done
}

is_tracked() { [[ " $TRACKED " == *" $1 "* ]]; }

# seg_assign <name> <value>: a VAR=value prefix or env word.
seg_assign() {
  [[ $1 == "$WAIVE_VAR" ]] && WAIVER_SET=1
  if is_tracked "$1"; then printf -v "SE_$1" '%s' "$2"; printf -v "SS_$1" 1; fi
}

# split_words <text> -> WORDS: quote-aware, one layer of quotes removed; an unterminated quote runs to the end.
split_words() {
  local s=$1 n=${#1} i=0 c w="" inw=0 q="" nx
  WORDS=()
  while (( i < n )); do
    c=${s:i:1}
    if [[ -n $q ]]; then
      if [[ $c == "$q" ]]; then
        q=""
      elif [[ $q == '"' && $c == '\' ]] && (( i + 1 < n )); then
        nx=${s:i+1:1}
        case $nx in '"'|'\'|'$'|'`') w+=$nx; i=$((i + 1)) ;; *) w+=$c ;; esac
      else
        w+=$c
      fi
    else
      case $c in
        [[:space:]]) if (( inw )); then WORDS+=("$w"); w=""; inw=0; fi ;;
        "'"|'"') q=$c; inw=1 ;;
        '\') i=$((i + 1)); w+=${s:i:1}; inw=1 ;;
        *) w+=$c; inw=1 ;;
      esac
    fi
    i=$((i + 1))
  done
  (( inw )) && WORDS+=("$w")
}

# resolve_cd <current-dir> <target> -> NEWDIR, empty when unknown.
resolve_cd() {
  local cur=$1 t=$2 top
  NEWDIR=""
  case $t in
    -) return 0 ;;
  esac
  case $t in
    '~') t=$HOME ;;
    "$TILDE"/*) t=$HOME/${t#"$TILDE"/} ;;
    '$HOME'|'$HOME/'*) t=$HOME${t#'$HOME'} ;;
    '${HOME}'|'${HOME}/'*) t=$HOME${t#'${HOME}'} ;;
    '$PWD'|'$PWD/'*) [[ -n $cur ]] || return 0; t=$cur${t#'$PWD'} ;;
    '${PWD}'|'${PWD}/'*) [[ -n $cur ]] || return 0; t=$cur${t#'${PWD}'} ;;
    '$CLAUDE_PROJECT_DIR'|'$CLAUDE_PROJECT_DIR/'*)
      [[ -n ${CLAUDE_PROJECT_DIR-} ]] || return 0; t=$CLAUDE_PROJECT_DIR${t#'$CLAUDE_PROJECT_DIR'} ;;
    '${CLAUDE_PROJECT_DIR}'|'${CLAUDE_PROJECT_DIR}/'*)
      [[ -n ${CLAUDE_PROJECT_DIR-} ]] || return 0; t=$CLAUDE_PROJECT_DIR${t#'${CLAUDE_PROJECT_DIR}'} ;;
    '$(git rev-parse --show-toplevel)'*)
      [[ -n $cur ]] || return 0
      top=$( unset GIT_DIR GIT_WORK_TREE; "$GIT" -C "$cur" rev-parse --show-toplevel 2>/dev/null )
      [[ -n $top ]] || return 0
      t=$top${t#'$(git rev-parse --show-toplevel)'}
      ;;
    '~'*) return 0 ;;
  esac
  case $t in *'$'*|*'*'*|*'?'*|*'['*|*'`'*) return 0 ;; esac
  if [[ $t == /* ]]; then
    NEWDIR=$t
  elif [[ -n $cur ]]; then
    NEWDIR=$cur/$t
  fi
}

# cd_target <words after cd...>: the target word, joining a split $( ... ) back together.
cd_target() {
  local w
  while (( $# )); do
    case $1 in -P|-L|-e|-@|--) shift ;; *) break ;; esac
  done
  if (( $# == 0 )); then CD_TARGET='~'; return; fi
  if [[ $1 == '$('* ]]; then
    w=$*
    CD_TARGET=$w
    return
  fi
  CD_TARGET=$1
}

basename_is_marker() { [[ ${1##*/} == "$MARKER" ]]; }

# normalise: strips wrappers and prefixes from WORDS, from the front. Sets NI (first real word), SEG_DIR,
# WAIVER_SET, and trims trailing group closers.
normalise() {
  local n=${#WORDS[@]} w name opens closes
  NI=0
  while (( n > 0 )); do
    w=${WORDS[n-1]}
    case $w in
      '}'|')') n=$((n - 1)); unset "WORDS[$n]" ;;
      *')')
        # Only a closer the word doesn't open itself: $(...) and (...) stay whole.
        while [[ $w == *')' ]]; do
          opens=${w//[!(]/}
          closes=${w//[!)]/}
          (( ${#closes} > ${#opens} )) || break
          w=${w%)}
        done
        [[ $w == "${WORDS[n-1]}" ]] && break
        WORDS[n-1]=$w
        [[ -n $w ]] && break
        n=$((n - 1))
        unset "WORDS[$n]"
        ;;
      *) break ;;
    esac
  done
  while (( NI < n )); do
    w=${WORDS[NI]}
    case $w in
      '('*) WORDS[NI]=${w#(}; [[ -n ${WORDS[NI]} ]] || NI=$((NI + 1)); continue ;;
    esac
    if [[ $w == [A-Za-z_]*=* ]]; then
      name=${w%%=*}
      if [[ $name =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
        seg_assign "$name" "${w#*=}"
        NI=$((NI + 1))
        continue
      fi
    fi
    case $w in
      command|exec|nohup|eval|then|do|else|elif|if|while|until|'!'|'{'|time)
        NI=$((NI + 1))
        while (( NI < n )) && [[ ${WORDS[NI]} == -* ]]; do NI=$((NI + 1)); done
        ;;
      env)
        NI=$((NI + 1))
        while (( NI < n )); do
          w=${WORDS[NI]}
          case $w in
            -u|--unset) is_tracked "${WORDS[NI+1]}" && printf -v "SS_${WORDS[NI+1]}" 0; NI=$((NI + 2)) ;;
            -u?*) is_tracked "${w#-u}" && printf -v "SS_${w#-u}" 0; NI=$((NI + 1)) ;;
            --unset=*) is_tracked "${w#*=}" && printf -v "SS_${w#*=}" 0; NI=$((NI + 1)) ;;
            -C|--chdir) resolve_cd "$SEG_DIR" "${WORDS[NI+1]}"; SEG_DIR=$NEWDIR; NI=$((NI + 2)) ;;
            -C?*) resolve_cd "$SEG_DIR" "${w#-C}"; SEG_DIR=$NEWDIR; NI=$((NI + 1)) ;;
            --chdir=*) resolve_cd "$SEG_DIR" "${w#*=}"; SEG_DIR=$NEWDIR; NI=$((NI + 1)) ;;
            -i|-|--ignore-environment)
              for name in $TRACKED; do printf -v "SS_$name" 0; done
              NI=$((NI + 1))
              ;;
            -P|-S) NI=$((NI + 2)) ;;
            -*) NI=$((NI + 1)) ;;
            [A-Za-z_]*=*) seg_assign "${w%%=*}" "${w#*=}"; NI=$((NI + 1)) ;;
            *) break ;;
          esac
        done
        ;;
      sudo)
        NI=$((NI + 1))
        while (( NI < n )); do
          w=${WORDS[NI]}
          case $w in
            -D|--chdir) resolve_cd "$SEG_DIR" "${WORDS[NI+1]}"; SEG_DIR=$NEWDIR; NI=$((NI + 2)) ;;
            -u|-g|-h|-p|-C|-r|-t|-U|-T|-R) NI=$((NI + 2)) ;;
            -*) NI=$((NI + 1)) ;;
            *) break ;;
          esac
        done
        ;;
      nice)
        NI=$((NI + 1))
        while (( NI < n )); do
          case ${WORDS[NI]} in
            -n|--adjustment) NI=$((NI + 2)) ;;
            -*) NI=$((NI + 1)) ;;
            *) break ;;
          esac
        done
        ;;
      timeout)
        NI=$((NI + 1))
        while (( NI < n )); do
          case ${WORDS[NI]} in
            -s|-k|--signal|--kill-after) NI=$((NI + 2)) ;;
            -*) NI=$((NI + 1)) ;;
            *) break ;;
          esac
        done
        NI=$((NI + 1))
        ;;
      xargs)
        NI=$((NI + 1))
        while (( NI < n )); do
          case ${WORDS[NI]} in
            -n|-L|-P|-I|-s|-d|-E|-a) NI=$((NI + 2)) ;;
            -*) NI=$((NI + 1)) ;;
            *) break ;;
          esac
        done
        ;;
      *) break ;;
    esac
  done
  NW=$n
  if (( NI < n )); then
    w=${WORDS[NI]}
    w=${w#\\}
    WORDS[NI]=$w
    FIRST=${w##*/}
  else
    FIRST=""
  fi
}

# redirect_op <word> -> ROP and RTGT (attached target); fails when the word isn't a redirection.
redirect_op() {
  local w=$1 rw
  rw=${w#"${w%%[!0-9]*}"}
  case $rw in
    '&>>'*) ROP='&>>' ;;
    '&>'*) ROP='&>' ;;
    '>>'*) ROP='>>' ;;
    '>&'*) ROP='>&' ;;
    '<&'*) ROP='<&' ;;
    '>'*) ROP='>' ;;
    '<'*) ROP='<' ;;
    *) return 1 ;;
  esac
  RTGT=${rw#"$ROP"}
  return 0
}

# A file named after the marker, written by a redirection or a file-creating command.
check_marker_segment() {
  local i w
  for (( i = NI; i < NW; i++ )); do
    w=${WORDS[i]}
    if redirect_op "$w" && [[ $ROP == *'>'* ]]; then
      if [[ -n $RTGT ]]; then basename_is_marker "$RTGT" && deny_marker "$RTGT"
      else basename_is_marker "${WORDS[i+1]-}" && deny_marker "${WORDS[i+1]}"; fi
    fi
  done
  case $FIRST in
    touch|cp|mv|tee|install|ln)
      for (( i = NI + 1; i < NW; i++ )); do
        basename_is_marker "${WORDS[i]}" && deny_marker "${WORDS[i]}"
      done
      ;;
  esac
}

# argv without redirections, from the first real word.
build_argv() {
  local i w
  ARGV=()
  for (( i = NI; i < NW; i++ )); do
    w=${WORDS[i]}
    if redirect_op "$w"; then
      [[ -z $RTGT ]] && i=$((i + 1))
      continue
    fi
    ARGV+=("$w")
  done
}

# run_check <dir> <tool> <args...>: check-argv in a subshell holding the segment's environment.
run_check() {
  local rc
  (
    for v in $TRACKED; do
      s=SS_$v e=SE_$v
      if [[ ${!s} == 1 ]]; then export "$v=${!e}"; else unset "$v"; fi
    done
    check_argv "$@"
  )
  rc=$?
  (( rc == 0 )) && return 0
  exit "$rc"
}

# guard_segment: a git, gh, glab or az call, with the segment's directory and environment.
guard_segment() {
  local tool=$FIRST dir=$SEG_DIR i w val
  local -a args=()
  if [[ -n ${WORK_CONTEXT_WAIVE+x} ]]; then
    echo "Blocked by the work-context guard: $WAIVE_VAR is set in this session, so the shims would waive every check; restart Claude without $WAIVE_VAR." >&2
    exit 2
  fi
  if [[ $tool == git ]]; then
    i=1
    while (( i < ${#ARGV[@]} )); do
      w=${ARGV[i]}
      case $w in
        -C)
          val=${ARGV[i+1]-}
          if [[ -n $val && -n $dir ]]; then
            resolve_cd "$dir" "$val"
            dir=$NEWDIR
          elif [[ -n $val ]]; then
            dir=""
          fi
          i=$((i + 2))
          continue
          ;;
        --git-dir|-c|--namespace|--config-env|--attr-source|--work-tree) args+=("$w" "${ARGV[i+1]-}"); i=$((i + 2)); continue ;;
        -*) args+=("$w") ;;
        *) break ;;
      esac
      i=$((i + 1))
    done
    args+=("${ARGV[@]:i}")
  else
    args=("${ARGV[@]:1}")
  fi
  [[ -n $dir ]] || dir=$UNKNOWN_DIR
  run_check "$dir" "$tool" "${args[@]}"
}

# shell_c_body <text> <segment-offset> <segment-text>: the -c argument of bash/sh/zsh, read from the joined text
# because the separator split may have cut it.
shell_c_body() {
  local text=$1 off=$2 seg=$3 re c t j n
  BODY=""
  re='^(.*[^[:alnum:]_.-])?(bash|sh|zsh|dash|ksh)([[:space:]]+-[[:alnum:]]+)*[[:space:]]+-[[:alnum:]]*c[[:space:]]+'
  [[ $seg =~ $re ]] || return 1
  off=$((off + ${#BASH_REMATCH[0]}))
  c=${text:off:1}
  if [[ $c == "'" ]]; then
    t=${text:off+1}
    BODY=${t%%"'"*}
  elif [[ $c == '"' ]]; then
    n=${#text}
    j=$((off + 1))
    while (( j < n )); do
      c=${text:j:1}
      if [[ $c == '\' ]]; then j=$((j + 2)); continue; fi
      [[ $c == '"' ]] && break
      j=$((j + 1))
    done
    BODY=${text:off+1:j-off-1}
    BODY=${BODY//\\\"/\"}
  else
    t=${text:off}
    BODY=${t%%[[:space:];|&]*}
  fi
  return 0
}

# find_inner <text> -> IB_TEXT, IB_OFF: bodies of $( ... ) and backticks.
find_inner() {
  local s=$1 n=${#1} rest base pre start depth j c body
  IB_TEXT=() IB_OFF=()
  rest=$s base=0
  while [[ $rest == *'$('* ]]; do
    pre=${rest%%'$('*}
    start=$((base + ${#pre} + 2))
    depth=1
    j=$start
    while (( j < n )); do
      c=${s:j:1}
      if [[ $c == '(' ]]; then depth=$((depth + 1))
      elif [[ $c == ')' ]]; then depth=$((depth - 1)); (( depth == 0 )) && break
      fi
      j=$((j + 1))
    done
    IB_TEXT+=("${s:start:j-start}")
    IB_OFF+=("$start")
    base=$start
    rest=${s:start}
  done
  rest=$s base=0
  while [[ $rest == *'`'*'`'* ]]; do
    pre=${rest%%'`'*}
    start=$((base + ${#pre} + 1))
    body=${s:start}
    body=${body%%'`'*}
    IB_TEXT+=("$body")
    IB_OFF+=("$start")
    base=$((start + ${#body} + 1))
    rest=${s:base}
  done
}

segment_relevant() {
  [[ $1 =~ $TOOL_RE ]] && return 0
  case $1 in
    *cd*|*pushd*|*popd*|*export*|*unset*|*declare*|*typeset*|*readonly*|*'('*|*')'*) return 0 ;;
    *"$MARKER"*|*"$WAIVE_VAR"*) return 0 ;;
  esac
  return 1
}

# process_command <text> <nested>: splits, normalises and guards every segment. Exits 2 on the first block.
process_command() {
  local text=$1 nested=$2 s pos len seglen seg k opens closes net p
  local -a seg_off=() seg_len=() dstack=() ib_text=() ib_off=() ib_done=()
  # Separators become \001 in a copy of the same length, so offsets map back to the text; the & of a
  # redirection (>&, &>, <&) is protected first.
  s=$text
  s=${s//'>&'/">$X1$X1"}
  s=${s//'&>'/"$X1$X1>"}
  s=${s//'<&'/"<$X1$X1"}
  s=$text
  local prot=${text//'>&'/'>_'}
  prot=${prot//'&>'/'_>'}
  prot=${prot//'<&'/'<_'}
  s=${prot//[;|&]/$X1}
  s=${s//"$NL"/$X1}
  len=${#s}
  pos=0
  while (( pos <= len )); do
    seg=${s:pos}
    seg=${seg%%"$X1"*}
    seglen=${#seg}
    if [[ -n ${seg//[[:space:]]/} ]]; then
      seg_off+=("$pos")
      seg_len+=("$seglen")
    fi
    pos=$((pos + seglen + 1))
  done

  if (( ! nested )); then
    find_inner "$text"
    ib_text=("${IB_TEXT[@]}")
    ib_off=("${IB_OFF[@]}")
  fi

  for (( k = 0; k < ${#seg_off[@]}; k++ )); do
    seg=${text:seg_off[k]:seg_len[k]}
    if segment_relevant "$seg"; then
      opens=${seg//[!(]/}
      closes=${seg//[!)]/}
      net=$(( ${#opens} - ${#closes} ))
      for (( p = 0; p < net; p++ )); do dstack+=("$DIR"); done
      process_segment "$text" "${seg_off[k]}" "$seg"
      for (( p = 0; p < -net; p++ )); do
        if (( ${#dstack[@]} )); then
          DIR=${dstack[${#dstack[@]}-1]}
          unset "dstack[${#dstack[@]}-1]"
        fi
      done
    fi
    if (( ! nested )); then
      for (( p = 0; p < ${#ib_off[@]}; p++ )); do
        [[ -z ${ib_done[p]-} ]] || continue
        (( ib_off[p] < seg_off[k] + seg_len[k] )) || continue
        ib_done[p]=1
        ( process_command "${ib_text[p]}" 1 ) || exit $?
      done
    fi
  done
  if (( ! nested )); then
    for (( p = 0; p < ${#ib_off[@]}; p++ )); do
      [[ -z ${ib_done[p]-} ]] || continue
      ( process_command "${ib_text[p]}" 1 ) || exit $?
    done
  fi
  return 0
}

process_segment() {
  local text=$1 off=$2 seg=$3 i w name rest_words
  split_words "$seg"
  seg_env_from_current
  SEG_DIR=$DIR
  WAIVER_SET=0
  normalise

  case $FIRST in
    export|declare|typeset|readonly|local)
      for (( i = NI + 1; i < NW; i++ )); do
        w=${WORDS[i]}
        [[ ${w%%=*} == "$WAIVE_VAR" ]] && WAIVER_SET=1
      done
      ;;
  esac
  if (( WAIVER_SET )); then
    rest_words=""
    case $FIRST in
      export|declare|typeset|readonly|local|"") ;;
      *) rest_words=$(quote_words "${WORDS[@]:NI:NW-NI}") ;;
    esac
    deny_waiver "$rest_words"
  fi

  check_marker_segment
  build_argv
  (( ${#ARGV[@]} )) || return 0

  case $FIRST in
    cd|pushd)
      if [[ $FIRST == pushd && ${#ARGV[@]} -lt 2 ]]; then DIR=""; return 0; fi
      if [[ $FIRST == pushd && ${ARGV[1]} == [+-]* ]]; then DIR=""; return 0; fi
      cd_target "${ARGV[@]:1}"
      if [[ -n $DIR ]]; then resolve_cd "$DIR" "$CD_TARGET"; DIR=$NEWDIR
      else resolve_cd "" "$CD_TARGET"; DIR=$NEWDIR; fi
      ;;
    popd) DIR="" ;;
    export)
      for (( i = 1; i < ${#ARGV[@]}; i++ )); do
        w=${ARGV[i]}
        [[ $w == *=* ]] || continue
        name=${w%%=*}
        if is_tracked "$name"; then printf -v "CE_$name" '%s' "${w#*=}"; printf -v "CS_$name" 1; fi
      done
      ;;
    unset)
      for (( i = 1; i < ${#ARGV[@]}; i++ )); do
        name=${ARGV[i]}
        is_tracked "$name" && printf -v "CS_$name" 0
      done
      ;;
    bash|sh|zsh|dash|ksh)
      if shell_c_body "$text" "$off" "$seg"; then
        local saved=$DIR
        DIR=$SEG_DIR
        ( process_command "$BODY" 1 ) || exit $?
        DIR=$saved
      fi
      ;;
    git|gh|glab|az)
      FORCE_WRITE=0
      if [[ $FIRST == gh || $FIRST == glab ]] && [[ ${ARGV[1]-} == api && ${ARGV[2]-} == graphql ]]; then
        # A multi-line query puts the mutation on a later line, past the separator split.
        rest_words=${text:off}
        shopt -s nocasematch
        [[ $rest_words == *mutation* ]] && FORCE_WRITE=1
        shopt -u nocasematch
      fi
      guard_segment
      FORCE_WRITE=0
      ;;
  esac
  return 0
}

pre_tool_use() {
  local f
  if ! command -v jq >/dev/null 2>&1; then
    no_jq_path
  fi
  read_input || { echo "work-context guard: could not parse the hook input" >&2; exit 2; }

  case $TOOL in
    Write|Edit|MultiEdit|NotebookEdit)
      for f in "$FPATH" "$NBPATH"; do
        [[ -n $f ]] && basename_is_marker "$f" && deny_marker "$f"
      done
      ;;
  esac
  if [[ $SETS_WAIVER == 1 ]] && ! exempt_path "${FPATH:-$NBPATH}"; then
    deny_waiver ""
  fi

  [[ -n $CMD ]] || exit 0
  if ! [[ $CMD =~ $TOOL_RE ]] && [[ $CMD != *"$MARKER"* && $CMD != *"$WAIVE_VAR"* ]]; then
    exit 0
  fi
  DIR=${CWD:-$PWD}
  init_env
  process_command "${CMD//"$BSNL"/}" 0
  exit 0
}

# --- can-file-issue and session-start ------------------------------------------------------------------------

can_file_issue() {
  local dir=$1 url tool
  url=$( unset GIT_DIR GIT_WORK_TREE; "$GIT" -C "$dir" remote get-url origin 2>/dev/null )
  if [[ -z $url ]] || ! parse_url "$url"; then echo none; return 0; fi
  if lower_eq "$U_HOST" github.com; then tool=gh
  elif is_gitlab_host "$U_HOST"; then tool=glab
  else echo none; return 0
  fi
  if ( check_argv "$dir" "$tool" issue create ) 2>/dev/null; then echo "$tool"; else echo none; fi
}

json_string() {
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//"$NL"/ }
  s=${s//$'\t'/ }
  s=${s//$'\r'/ }
  printf '"%s"' "$s"
}

session_start() {
  local input="" cwd="" re text blocked tool
  IFS= read -r -d '' input
  re='"cwd"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)"'
  if command -v jq >/dev/null 2>&1; then
    cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
  elif [[ $input =~ $re ]]; then
    cwd=${BASH_REMATCH[1]}
  fi
  cwd=${cwd:-$PWD}
  blocked="Commits, pushes and platform writes are blocked here; draft them for the user."
  level_of_dir "$cwd"
  if (( ! LV_REPO )); then
    text="Work context: no git repository at $cwd; resolve per repository before any git write."
  elif [[ -n $LV_URL ]]; then
    text="Work context: $CL (origin $LV_URL), resolved by ~/.claude/hooks/work-context.sh."
    if [[ $CL == customer ]]; then
      text+=" $blocked"
      tool=$(can_file_issue "$cwd")
      [[ $tool != none ]] && text+=" Filing an issue with $tool issue create is allowed."
    fi
  else
    text="Work context: $CL (no origin remote)."
    [[ $CL == customer ]] && text+=" $blocked"
  fi
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":%s}}\n' "$(json_string "$text")"
  # The Bash tool's PATH comes from a shell snapshot taken before CLAUDECODE is set, so source/ can't add the
  # shims; Claude Code sources CLAUDE_ENV_FILE before each Bash call instead.
  if [[ -n ${CLAUDE_ENV_FILE-} && -d $HOME/.claude/shims ]]; then
    printf 'case ":$PATH:" in *":%s:"*) ;; *) export PATH="%s:$PATH" ;; esac\n' \
      "$HOME/.claude/shims" "$HOME/.claude/shims" >> "$CLAUDE_ENV_FILE"
  fi
}

# --- main ----------------------------------------------------------------------------------------------------

main() {
  strip_shims
  local cmd=$1
  shift
  case $cmd in
    level) level_of_dir "${1:-$PWD}"; echo "$CL" ;;
    check-argv) (( $# >= 2 )) || return 64; check_argv "$@" ;;
    pre-tool-use) pre_tool_use ;;
    can-file-issue) can_file_issue "${1:-$PWD}" ;;
    session-start) session_start ;;
    *) echo "usage: work-context.sh level|check-argv|pre-tool-use|can-file-issue|session-start" >&2; return 64 ;;
  esac
}

# A subshell, so an exit in any helper still lands in the fail-closed mapping below: Claude Code treats every
# exit status but 2 as non-blocking, so a crash would otherwise let a push through.
( main "$@" )
rc=$?
case $1 in
  pre-tool-use|check-argv)
    if (( rc != 0 && rc != 2 )); then
      echo "work-context guard failed (exit $rc); blocking to stay safe" >&2
      exit 2
    fi
    ;;
  session-start) exit 0 ;;
esac
exit "$rc"
