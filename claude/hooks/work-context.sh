#!/bin/bash
# Work-context guard: resolves whether a repository is personal, company or customer work, and blocks history and
# remote writes whose strictest target is a customer repository. The rules it enforces are claude/CLAUDE.md § Work contexts.
#
# Must stay bash 3.2-compatible: Claude Code runs hooks under macOS's /bin/bash, and a hook's PATH may hold no
# Homebrew bash. So no mapfile, associative arrays, ${var,,} or |&. `level` and `check-argv` use only builtins and
# git, so Task 2b's shim can call them under a PATH holding nothing else.
#
# It also keeps revealed git-secret files out of Claude's reach at every level: their paths, and the commands that
# reveal them.
#
# Usage: work-context.sh level [dir] | check-argv <dir> <tool> [args...] | pre-tool-use | can-file-issue [dir]
#        | session-start

# Byte semantics, so substring offsets into a command stay cheap and match the separator scan.
LC_ALL=C

MARKER=.claude-files-issues
CUSTOMERS=.claude-customers
SECRET_MAPPING=.gitsecret/paths/mapping.cfg
WAIVE_VAR=WORK_CONTEXT_WAIVE
TRACKED="GH_REPO GH_HOST GITLAB_HOST GL_HOST GITLAB_URI GITLAB_REPO GIT_DIR GIT_WORK_TREE"
GIT=${WORK_CONTEXT_GIT:-git}
UNKNOWN_DIR="<unknown directory>"
TILDE='~'
C_LOADED=0
FORCE_WRITE=0
X1=$'\001'
NL=$'\n'
BSNL=$'\\\n'
TOOL_RE='(^|[^[:alnum:]_-])(git|gh|glab|az|fj)([^[:alnum:]_-]|$)'
# A dotfile glob or brace word, which can reach a protected file without spelling its name.
DOT_GLOB_RE='(^|[[:space:]/="'\''])\.[^[:space:]]*[]*?[{]'

# --- helpers -------------------------------------------------------------------------------------------------

canon() { ( cd -P -- "$1" 2>/dev/null && printf '%s' "$PWD" ); }

# canon_loose <absolute-path>: canon of a path that may not exist yet, its deepest existing ancestor canonical.
canon_loose() {
  local p=$1 rest="" c
  [[ $p == /* ]] || return 1
  until c=$(canon "$p"); do
    rest=/${p##*/}$rest
    p=${p%/*}
    [[ -n $p ]] || p=/
  done
  [[ $c == / ]] && c=""
  printf '%s' "$c$rest"
}

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

# --- git-secret ----------------------------------------------------------------------------------------------

# find_mapping <canonical-dir> -> MAP_ROOT, the nearest ancestor holding a git-secret mapping ("" for /).
find_mapping() {
  local d=$1
  while :; do
    if [[ -f ${d%/}/$SECRET_MAPPING ]]; then MAP_ROOT=${d%/}; return 0; fi
    [[ -n $d && $d != / ]] || return 1
    d=${d%/*}
    [[ -n $d ]] || d=/
  done
}

# secret_names <dir> -> SECRET_NAMES, the basenames the mapping above dir lists, one per line; cached per dir.
secret_names() {
  local cdir line rel
  [[ $1 == "${SN_DIR-}" && -n $1 ]] && return 0
  SN_DIR=$1 SECRET_NAMES=""
  [[ -n $1 ]] || return 0
  cdir=$(canon "$1") || return 0
  find_mapping "$cdir" || return 0
  while IFS= read -r line || [[ -n $line ]]; do
    rel=${line%%:*}
    [[ -n $rel ]] && SECRET_NAMES+=${rel##*/}$NL
  done < "$MAP_ROOT/$SECRET_MAPPING"
}

# is_secret <absolute-path>: the path, its parent canonicalised, is one the nearest mapping lists.
is_secret() {
  local p=$1 base cp line rel lp
  base=${p##*/}
  [[ -n $base && $base != . && $base != .. ]] || return 1
  cp=$(canon "${p%/*}/") || return 1
  cp=${cp%/}
  find_mapping "${cp:-/}" || return 1
  while IFS= read -r line || [[ -n $line ]]; do
    rel=${line%%:*}
    rel=${rel#./}
    [[ ${rel##*/} == "$base" ]] || continue
    [[ $MAP_ROOT/$rel == "$cp/$base" ]] && return 0
    if [[ $rel == */* ]]; then
      lp=$(canon "$MAP_ROOT/${rel%/*}") && [[ ${lp%/}/$base == "$cp/$base" ]] && return 0
    fi
  done < "$MAP_ROOT/$SECRET_MAPPING"
  return 1
}

deny_secret() {
  echo "Blocked by the work-context guard: \`$1\` is a git-secret file, revealed in plaintext; only the user reads it." >&2
  exit 2
}

# check_secret_path <path> <base-dir>: a tool's path, relative ones resolved against base-dir.
check_secret_path() {
  local p=$1
  case $p in
    /*) ;;
    "$TILDE"/*) p=$HOME/${p#"$TILDE"/} ;;
    *) [[ -n $2 ]] || return 0; p=$2/$p ;;
  esac
  is_secret "$p" && deny_secret "$1"
  return 0
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

# customer_entry <line> -> ENTRY_KIND (org, host, dir or name) and ENTRY: one line of the user's ~/.claude-customers,
# which lists customer work explicitly; nothing else is. A line is a host/owner, or a clone URL reduced to one the way
# parse_url reduces a remote; a bare host, all of whose owners are customer work, and a name too; a directory (/, ~ or
# $HOME, or a slash path whose first part has no dot, taken from $HOME) whose whole tree is; or a name or abbreviation.
# A # starting the line, or after a space, begins a comment. Fails with 1 on a blank or comment line, 2 on a line it
# can't read. Builtins only, for the shims.
customer_entry() {
  local line=${1#"${1%%[![:space:]]*}"} first rest port U_HOST U_OWNER U_REPO
  [[ $line == "#"* ]] && return 1
  line=${line%%[[:space:]]#*}
  line=${line%"${line##*[![:space:]]}"}
  [[ -n $line ]] || return 1
  [[ $line == \"*\" || $line == \'*\' ]] && line=${line:1:${#line}-2}
  case $line in
    '$HOME' | '${HOME}') line=$TILDE ;;
    '$HOME/'* | '${HOME}/'*) line=$TILDE/${line#*/} ;;
  esac
  line=${line%/}
  [[ -n $line ]] || return 2
  # A userless host:owner/repo is scp-style, which https:// would misread as a port; host:port[/path] is ssh://.
  first=${line%%:*}
  if [[ $line == *:* && $line != *@* && $line != *://* && $first == *.* && $first != */* ]]; then
    rest=${line#*:}
    port=${rest%%/*}
    if [[ -n $port && -z ${port//[0-9]/} ]]; then
      if [[ $rest == */* ]]; then line="ssh://git@$line"; else line=$first; fi
    else
      line="git@$line"
    fi
  fi
  case $line in
    "$TILDE") ENTRY_KIND=dir; ENTRY=$HOME ;;
    "$TILDE"/*) ENTRY_KIND=dir; ENTRY=$HOME/${line#"$TILDE"/} ;;
    "$TILDE"*) return 2 ;;
    /*) ENTRY_KIND=dir; ENTRY=$line ;;
    *://* | *@*:*)
      parse_url "$line" || parse_url "${line%.git}/x" || return 2
      customer_org_entry ;;
    */*)
      first=${line%%/*}
      if [[ $first == *.* && $first != .* ]]; then
        parse_url "https://$line" || parse_url "https://${line%.git}/x" || return 2
        customer_org_entry
      else
        ENTRY_KIND=dir; ENTRY=$HOME/$line
      fi
      ;;
    *)
      if [[ $line =~ ^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$ ]]; then
        ENTRY_KIND=host; ENTRY=$line
        [[ ${ENTRY:0:4} == [sS][sS][hH]. ]] && ENTRY=${ENTRY:4}
      else
        ENTRY_KIND=name; ENTRY=$line
      fi
      ;;
  esac
  return 0
}

# customer_org_entry: the U_HOST/U_OWNER customer_entry's parse_url call set, as an org entry, ssh. dropped.
customer_org_entry() {
  local host=$U_HOST
  [[ ${host:0:4} == [sS][sS][hH]. ]] && host=${host:4}
  ENTRY_KIND=org; ENTRY=$host/$U_OWNER
}

# load_customers -> C_KIND, C_ENTRY, C_DIR (a dir entry's canonical path, or empty), C_UNREAD (lines it can't read),
# C_NODIR (dir entries naming no existing folder): ~/.claude-customers, parsed once per run.
load_customers() {
  local line rc nc=0 i=0
  (( C_LOADED )) && return 0
  C_LOADED=1 C_KIND=() C_ENTRY=() C_DIR=() C_UNREAD=0 C_NODIR=0
  [[ -r $HOME/$CUSTOMERS ]] || return 0
  # The host pattern in customer_entry must see letter case.
  shopt -q nocasematch && nc=1
  shopt -u nocasematch
  while IFS= read -r line || [[ -n $line ]]; do
    customer_entry "$line"; rc=$?
    if (( rc == 0 )); then
      C_KIND[i]=$ENTRY_KIND C_ENTRY[i]=$ENTRY C_DIR[i]=""
      if [[ $ENTRY_KIND == dir ]]; then
        C_DIR[i]=$(canon "$ENTRY") || C_NODIR=$((C_NODIR + 1))
      fi
      i=$((i + 1))
    elif (( rc == 2 )); then
      C_UNREAD=$((C_UNREAD + 1))
    fi
  done < "$HOME/$CUSTOMERS"
  (( nc )) && shopt -s nocasematch
  return 0
}

# customer_org <host> <owner>: listed in ~/.claude-customers, as an owner, a whole host, or a name the owner is
# named for, which also catches a clone behind an SSH host alias. Builtins only, for the shims.
customer_org() {
  local host=$1 i
  [[ ${host:0:4} == [sS][sS][hH]. ]] && host=${host:4}
  load_customers
  for (( i = 0; i < ${#C_KIND[@]}; i++ )); do
    case ${C_KIND[i]} in
      org) lower_eq "${C_ENTRY[i]}" "$host/$2" && return 0 ;;
      host)
        lower_eq "${C_ENTRY[i]}" "$host" && return 0
        named_for "$2" "${C_ENTRY[i]}" && return 0
        ;;
      name) named_for "$2" "${C_ENTRY[i]}" && return 0 ;;
    esac
  done
  return 1
}

# ascii <text> [long] -> ASCII: Nordic and common accented letters spelled in ASCII, as folder names often are, so a
# customer named Fjærvik matches fjaervik-app and fjærvik-app alike under the guard's C locale. The short spelling writes
# ø and å as o and a, the long one as oe and aa; names are matched in both.
ascii() {
  local s=$1
  # Finder stores names decomposed: compose the letters spelled two ways, then drop the other combining marks.
  s=${s//a$'\xcc\x8a'/å}; s=${s//A$'\xcc\x8a'/Å}; s=${s//o$'\xcc\x88'/ö}; s=${s//O$'\xcc\x88'/Ö}
  s=${s//a$'\xcc\x88'/ä}; s=${s//A$'\xcc\x88'/Ä}
  s=${s//$'\xcc'?/}; s=${s//$'\xcd'?/}
  s=${s//æ/ae}; s=${s//Æ/AE}; s=${s//ä/ae}; s=${s//Ä/AE}; s=${s//ü/u}; s=${s//Ü/U}; s=${s//ß/ss}; s=${s//þ/th}
  s=${s//é/e}; s=${s//è/e}; s=${s//ê/e}; s=${s//É/E}; s=${s//á/a}; s=${s//à/a}; s=${s//â/a}; s=${s//Á/A}
  s=${s//í/i}; s=${s//ì/i}; s=${s//Í/I}; s=${s//ó/o}; s=${s//ò/o}; s=${s//ô/o}; s=${s//Ó/O}; s=${s//ú/u}
  s=${s//ù/u}; s=${s//Ú/U}; s=${s//ç/c}; s=${s//Ç/C}; s=${s//ñ/n}; s=${s//Ñ/N}; s=${s//ð/d}; s=${s//Ð/D}
  if [[ -n ${2-} ]]; then
    s=${s//ø/oe}; s=${s//Ø/OE}; s=${s//ö/oe}; s=${s//Ö/OE}; s=${s//å/aa}; s=${s//Å/AA}
  else
    s=${s//ø/o}; s=${s//Ø/O}; s=${s//ö/o}; s=${s//Ö/O}; s=${s//å/a}; s=${s//Å/A}
  fi
  ASCII=$s
}

# named_for <component> <name>: a folder name names a customer. A name of five or more letters and digits matches
# anywhere in the component, ignoring case and punctuation; a shorter abbreviation must be a whole word of it, so
# FVK marks fvk-portal but not fvkx.
named_for() {
  local spelling
  for spelling in "" long; do
    named_as "$1" "$2" "$spelling" && return 0
  done
  return 1
}

# named_as <component> <name> <spelling>: named_for in one ASCII spelling, applied to both sides.
named_as() {
  local comp name word short r=1 IFS=" "
  ascii "$1" "$3"; comp=$ASCII
  ascii "$2" "$3"; name=${ASCII//[^[:alnum:]]/}
  [[ -n $name ]] || return 1
  # Which rule applies is decided on the short spelling, so Mørk is an abbreviation in both.
  ascii "$2"; short=${ASCII//[^[:alnum:]]/}
  shopt -s nocasematch
  if (( ${#short} >= 5 )); then
    [[ ${comp//[^[:alnum:]]/} == *"$name"* ]] && r=0
  else
    set -f
    for word in ${comp//[^[:alnum:]]/ }; do
      [[ $word == "$name" ]] && r=0
    done
    set +f
  fi
  shopt -u nocasematch
  return $r
}

# customer_dir <dir> [names]: at or below a directory listed in ~/.claude-customers, or, with a second argument,
# below $HOME in a folder whose name names a listed customer or host. Names are checked only against a repository's own
# location, never a subfolder a command runs in, and never outside $HOME, where Claude's scratch paths live.
customer_dir() {
  local d home rel comp i e
  local -a comps=()
  load_customers
  (( ${#C_KIND[@]} )) || return 1
  d=$(canon_loose "$1") || return 1
  home=$(canon "$HOME") || home=$HOME
  rel=""
  if [[ -n ${2-} ]] && lower_eq "${d:0:${#home}+1}" "$home/"; then
    rel=${d:${#home}+1}
    set -f
    IFS=/ read -r -a comps <<< "$rel"
    set +f
  fi
  for (( i = 0; i < ${#C_KIND[@]}; i++ )); do
    case ${C_KIND[i]} in
      dir)
        e=${C_DIR[i]}
        [[ -n $e ]] || continue
        { lower_eq "$d" "$e" || lower_eq "${d:0:${#e}+1}" "$e/"; } && return 0
        ;;
      name|host)
        e=${C_ENTRY[i]}
        for comp in ${comps[@]+"${comps[@]}"}; do
          named_for "$comp" "$e" && return 0
        done
        # A dotted entry is a host and a name: its label before the TLD also names folders, so acme.no marks acme-portal.
        if [[ ${C_KIND[i]} == host ]]; then
          e=${e%.*}; e=${e##*.}
          for comp in ${comps[@]+"${comps[@]}"}; do
            named_for "$comp" "$e" && return 0
          done
        fi
        ;;
    esac
  done
  return 1
}

# customer_repo <dir> [git-dir]: the repository's own locations, its toplevel and its main worktree, which a linked
# worktree or a --git-dir from elsewhere still writes to, sit in customer work; or <dir> is in a listed directory.
customer_repo() {
  local top common
  customer_dir "$1" && return 0
  # With --git-dir and no work tree, git reports the directory it runs in as the toplevel, so take it from the git dir.
  if [[ -n ${2-} ]]; then
    if [[ ${2##*/} == .git ]]; then
      if [[ $2 == */* ]]; then top=${2%/*}; else top=.; fi
      [[ $top == /* ]] || top=$1/$top
    fi
  else
    top=$( unset GIT_DIR GIT_WORK_TREE; "$GIT" -C "$1" rev-parse --show-toplevel 2>/dev/null )
  fi
  [[ -n $top ]] && customer_dir "$top" names && return 0
  common=$( unset GIT_WORK_TREE; "$GIT" -C "$1" ${2:+"--git-dir=$2"} rev-parse --git-common-dir 2>/dev/null )
  [[ -n $common ]] || return 1
  [[ $common == /* ]] || common=$1/$common
  [[ ${common##*/} == .git ]] && common=${common%/*}
  customer_dir "$common" names
}

# has_customers: ~/.claude-customers lists at least one entry.
has_customers() {
  load_customers
  (( ${#C_KIND[@]} ))
}

# unresolved_class -> CL: a target the guard cannot resolve could be a listed customer's, so it is customer while any
# customer is listed, and the user's own otherwise.
unresolved_class() {
  if has_customers; then CL=customer; else CL=company; fi
}

# no_repo_class <dir> -> CL: a directory outside any repository is the user's own unless a customer directory, judged
# by its path even before it exists. One the guard cannot resolve (a cd to a variable, cd -) could be a listed
# customer's, so it fails closed, but only while any customer is listed.
no_repo_class() {
  if customer_dir "$1" names; then CL=customer
  elif ! canon_loose "$1" >/dev/null; then unresolved_class
  else CL=company
  fi
}

# classify <host> <owner> <repo> -> CL
classify() {
  if customer_org "$1" "$2"; then
    CL=customer
    return
  fi
  shopt -s nocasematch
  if [[ $2 == uptimeconsulting ]]; then
    CL=company
  elif [[ $2 == andrelin && $1 == github.com ]]; then
    if [[ $3 == *uptime* ]]; then CL=company; else CL=personal; fi
  else
    CL=company
  fi
  shopt -u nocasematch
}

url_class() {
  if parse_url "$1"; then classify "$U_HOST" "$U_OWNER" "$U_REPO"; else CL=company; fi
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
  if [[ -d $p ]]; then level_of_dir "$p"; else CL=company; fi
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

# level_of_dir <dir> -> CL, LV_URL (origin, or empty), LV_REPO (1 when dir is in a repository), LV_LISTED (1 when
# a listed customer directory or name made it customer).
level_of_dir() {
  local dir=$1 top url
  LV_URL="" LV_REPO=0 LV_LISTED=0
  ( unset GIT_DIR GIT_WORK_TREE; "$GIT" -C "$dir" rev-parse --absolute-git-dir >/dev/null 2>&1 ) && LV_REPO=1
  if (( ! LV_REPO )); then
    no_repo_class "$dir"
    [[ $CL == customer ]] && canon "$dir" >/dev/null && LV_LISTED=1
    return
  fi
  url=$( unset GIT_DIR GIT_WORK_TREE; "$GIT" -C "$dir" remote get-url origin 2>/dev/null )
  LV_URL=$url
  load_customers # here, not in the subshell below, where the parse would be lost
  if ( unset GIT_DIR; customer_repo "$dir" ); then
    CL=customer LV_LISTED=1
    return
  fi
  if [[ -n $url ]]; then
    url_class "$url"
    return
  fi
  top=$( unset GIT_DIR GIT_WORK_TREE; "$GIT" -C "$dir" rev-parse --show-toplevel 2>/dev/null )
  if [[ -n $top ]] && in_scratch "$top"; then CL=personal; else CL=company; fi
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
    bump company "no origin remote" ""
    T_LEVEL+=(company); T_HOST+=("")
  fi
  if customer_repo "$R_DIR" "${1:-${GIT_DIR-}}"; then
    bump customer "a listed customer folder" ""
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
  if [[ $t == *'$'* || $t == *'`'* ]]; then
    unresolved_class
    bump "$CL" "$t" "(an unexpanded target)"
  elif [[ -d $p ]]; then
    level_of_dir "$p"
    bump "$CL" "$t" "$p"
  elif [[ $t == *:* || $t == */* ]]; then
    url_class "$t"
    bump "$CL" "$t" "$t"
  else
    unresolved_class
    bump "$CL" "$t" "(not a remote, directory or URL)"
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
  if [[ $sub == secret ]]; then
    reveals_secret "${rest[@]}" || return 0
    deny_reveal "$dir" git "${shown[@]}" "$orig_sub" "${rest[@]}"
    return 2
  fi
  (( forced )) && forbidden=1
  (( forbidden )) || return 0

  reset_worst
  T_LEVEL=() T_HOST=()
  if ! resolve_repo "$dir" "$gitdir"; then
    # A git dir the guard can't resolve, such as one holding $HOME, could be a listed customer's.
    if [[ -n $gitdir || -n ${GIT_DIR-} ]]; then
      unresolved_class
      bump "$CL" "a git dir the guard cannot resolve" ""
    else
      level_of_dir "$dir"
      bump "$CL" "no git repository" ""
    fi
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
      if [[ $path == */* ]]; then classify "$host" "${path%%/*}" "${path##*/}"; else CL=company; fi
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
      level_of_dir "$dir"
      bump "$CL" "no git repository" ""
      T_LEVEL+=("$CL"); T_HOST+=("")
    fi
  fi
  if (( FLAG_USED && ! issue_create )); then
    level_of_dir "$dir"
    if (( LV_LISTED )); then
      bump customer "a listed customer folder" ""
      T_LEVEL+=(customer); T_HOST+=("")
    elif (( ! LV_REPO )) && [[ $CL == customer ]]; then
      bump customer "a directory the guard cannot resolve" ""
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
          unresolved_class
          bump "$CL" "endpoint" "${pos[1]}"
          T_LEVEL+=("$CL"); T_HOST+=("$host")
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
  if resolve_repo "$dir" ""; then origin_target ""; else level_of_dir "$dir"; bump "$CL" "no git repository" ""; fi
  [[ $W_LEVEL != customer ]] && return 0
  deny "$dir" az "$@"
  return 2
}

# --- fj --------------------------------------------------------------------------------------------------------

# fj_read_allowed <word> <word>: the first two words of an fj call that only reads.
fj_read_allowed() {
  case "$1 $2" in
    "whoami "* | "version "* | "completion "* | "auth list" | \
    "issue search" | "issue view" | "issue browse" | "issue templates" | \
    "pr search" | "pr view" | "pr status" | "pr browse" | "pr checkout" | \
    "repo view" | "repo readme" | "repo clone" | "repo browse" | "repo star-status" | "repo watch-status" | \
    "org list" | "org view" | "org members" | "user search" | "user view" | "user repos" | \
    "release list" | "release view" | "tag list" | "tag view" | "actions tasks" | "wiki view" | "wiki list" | \
    "milestone list" | "milestone view")
      return 0 ;;
  esac
  return 1
}

# no_customer_remote <dir>: every remote of the repository at <dir> is personal or company work.
no_customer_remote() {
  local r url
  for r in $( unset GIT_DIR GIT_WORK_TREE; "$GIT" -C "$1" remote 2>/dev/null ); do
    url=$( unset GIT_DIR GIT_WORK_TREE; "$GIT" -C "$1" remote get-url "$r" 2>/dev/null )
    url_class_at "$url" "$1"
    [[ $CL == customer ]] && return 1
  done
  return 0
}

# check_fj <dir> [args...]: forgejo-cli. Anything but a known read is a write, judged by the worse of the directory it
# runs in, the one -C names, every remote of the repository there, any of which fj can aim at, and the repo --repo
# names. A positional owner/repo (fj repo delete) is not parsed.
check_fj() {
  local dir=$1 cwd=$1 a next="" host="" repo="" url
  shift
  local -a words=()
  for a in "$@"; do
    if [[ -n $next ]]; then
      case $next in
        cwd) resolve_cd "$dir" "$a"; cwd=${NEWDIR:-$UNKNOWN_DIR} ;;
        host) host=$a ;;
        repo) repo=$a ;;
      esac
      next=""
      continue
    fi
    case $a in
      -C | --cwd) next=cwd ;;
      --cwd=* | -C?*)
        a=${a#--cwd=}; a=${a#-C}; a=${a#=}
        resolve_cd "$dir" "$a"; cwd=${NEWDIR:-$UNKNOWN_DIR}
        ;;
      -H | --host) next=host ;;
      --host=*) host=${a#*=} ;;
      -H?*) host=${a#-H}; host=${host#=} ;;
      -r | --repo) next=repo ;;
      --repo=*) repo=${a#*=} ;;
      -r?*) repo=${a#-r}; repo=${repo#=} ;;
      -R | --remote | --style) next=skip ;;
      -*) ;;
      *) words+=("$a") ;;
    esac
  done
  (( ${#words[@]} )) || return 0
  fj_read_allowed "${words[0]}" "${words[1]-}" && return 0
  reset_worst
  level_of_dir "$dir"
  bump "$CL" "the directory fj runs in" ""
  if [[ $cwd != "$dir" ]]; then
    level_of_dir "$cwd"
    bump "$CL" "the -C directory $cwd" ""
  fi
  no_customer_remote "$cwd" || bump customer "a customer remote" ""
  # The repo --repo names, on the host -H names or else origin's.
  if [[ $repo == */* ]]; then
    if [[ -z $host ]]; then
      url=$( unset GIT_DIR GIT_WORK_TREE; "$GIT" -C "$cwd" remote get-url origin 2>/dev/null )
      parse_url "$url" && host=$U_HOST
    fi
    host=$(host_only "$host")
    if [[ -n $host ]]; then
      classify "$host" "${repo%%/*}" "${repo##*/}"
    else
      unresolved_class
    fi
    bump "$CL" "the repo --repo names" ""
  fi
  [[ $W_LEVEL != customer ]] && return 0
  deny "$dir" fj "$@"
  return 2
}

check_argv() {
  local dir=$1 tool=${2##*/}
  shift 2
  case $tool in
    git) check_git "$dir" "$@" ;;
    gh|glab) check_platform "$dir" "$tool" "$@" ;;
    az) check_az "$dir" "$@" ;;
    fj) check_fj "$dir" "$@" ;;
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
  printf '%s\n' "Blocked by the work-context guard: $dir is $W_LEVEL work ($W_REMOTE${W_URL:+ $W_URL}), and \`$seg\` writes to its history or remote, or isn't on the guard's read allowlist; both belong to the user." \
    "Prepare the working tree, then give the user the exact command to run:" \
    "\`! cd $qdir && $waive$seg\`. Rules: ~/.claude/CLAUDE.md § Work contexts." >&2
}

# reveals_secret <args after git secret>: a subcommand that decrypts, to disk or to stdout.
reveals_secret() {
  local a
  for a in "$@"; do
    [[ $a == -* ]] && continue
    case $a in reveal|cat|changes) return 0 ;; esac
    return 1
  done
  return 1
}

# deny_reveal <dir> <tool> <args...>: at every level, since a revealed file is plaintext wherever it lands.
deny_reveal() {
  local dir=$1 seg waive="" qdir
  shift
  seg=$(quote_words "$@")
  if [[ $dir == "$UNKNOWN_DIR" ]]; then qdir=$dir; else qdir=$(quote_words "$dir"); fi
  [[ $2 == git && -d "$HOME/.claude/shims" ]] && waive="$WAIVE_VAR=1 "
  printf '%s\n' "Blocked by the work-context guard: \`$seg\` decrypts git-secret files into plaintext; only the user reveals them." \
    "Give the user the exact command to run: \`! cd $qdir && $waive$seg\`." >&2
}

deny_protected() {
  if [[ ${1##*/} == "$CUSTOMERS" ]]; then
    echo "Only the user edits ~/$CUSTOMERS: ask them to run \`! echo '<entry>' >> ~/$CUSTOMERS\`," \
      "where the entry is one of a host/owner, a directory or a customer's name." >&2
  else
    echo "Only the user creates $MARKER: ask them to run \`! touch $1\`" >&2
  fi
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
(.tool_input.path | s), "\u0000",
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
    IFS= read -r -d '' GPATH
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
  [[ $input == *"$CUSTOMERS"* ]] && deny_jq "it names $CUSTOMERS"
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
  [[ $CMD =~ $TOOL_RE ]] && deny_jq "it runs git, gh, glab, az or fj"
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

# The issue marker and the customers file: each loosens the guard, so only the user writes them.
# A word that is the name or a glob matching it, in any letter case, as macOS's file system ignores case.
# With a second argument the word is a find -name pattern, which matches dotfiles whether or not it starts with a dot.
basename_is_protected() {
  local base=${1##*/} r=1 name
  base=${base//[\"\']/}
  # A glob or brace word only reaches a dotfile when it starts with a dot, as the protected files' names do.
  [[ $base == .* || -n ${2-} ]] && base=${base//\{*\}/*}
  # A pattern of wildcards alone names no file; find build -name '*' -delete is a cleanup.
  [[ -n ${2-} && -z ${base//[*?]/} ]] && return 1
  shopt -s nocasematch
  for name in "$MARKER" "$CUSTOMERS"; do
    [[ $base == "$name" ]] && r=0
    # shellcheck disable=SC2053 # unquoted on purpose: a glob in the word matches the name it would expand to
    [[ ( $base == .* || -n ${2-} ) && $name == $base ]] && r=0
  done
  shopt -u nocasematch
  return $r
}

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
    '>|'*) ROP='>|' ;;
    '<&'*) ROP='<&' ;;
    '>'*) ROP='>' ;;
    '<'*) ROP='<' ;;
    *) return 1 ;;
  esac
  RTGT=${rw#"$ROP"}
  return 0
}

# A protected file, written by a redirection or a file-writing command.
check_protected_segment() {
  local i j w
  for (( i = NI; i < NW; i++ )); do
    w=${WORDS[i]}
    if redirect_op "$w" && [[ $ROP == *'>'* ]]; then
      if [[ -n $RTGT ]]; then basename_is_protected "$RTGT" && deny_protected "$RTGT"
      else basename_is_protected "${WORDS[i+1]-}" && deny_protected "${WORDS[i+1]}"; fi
    fi
  done
  case $FIRST in
    find)
      # find only writes with -delete or -exec; a find that names the file to look for it is a read.
      for (( i = NI + 1; i < NW; i++ )); do
        case ${WORDS[i]} in -delete | -exec | -execdir | -ok | -okdir) ;; *) continue ;; esac
        for (( j = NI + 1; j < NW; j++ )); do
          basename_is_protected "${WORDS[j]}" && deny_protected "${WORDS[j]}"
          case ${WORDS[j-1]} in
            -name | -iname | -path | -ipath | -wholename | -iwholename)
              basename_is_protected "${WORDS[j]}" pattern && deny_protected "${WORDS[j]}" ;;
          esac
        done
        break
      done
      ;;
    touch|cp|mv|tee|install|ln|sed|perl|dd|truncate|rm|unlink|chmod|chflags|xattr|shred|trash|srm|ed|ex)
      for (( i = NI + 1; i < NW; i++ )); do
        basename_is_protected "${WORDS[i]}" && deny_protected "${WORDS[i]}"
      done
      ;;
  esac
}

# secret_word <word>: a word of the segment, resolved by the cd rules, that names a revealed git-secret file.
secret_word() {
  local w=$1
  [[ $w == -* ]] && return 0
  # A bare name resolves into SEG_DIR, whose mapping's names SECRET_NAMES holds, so only those need a lookup.
  if [[ $w != */* ]]; then [[ $NL$SECRET_NAMES == *"$NL$w$NL"* ]] || return 0; fi
  resolve_cd "$SEG_DIR" "$w"
  [[ -n $NEWDIR && -e $NEWDIR && ! -d $NEWDIR ]] || return 0
  is_secret "$NEWDIR" && deny_secret "$w"
  return 0
}

# Every word counts, redirection targets and the value of a --opt=value word included.
check_secret_segment() {
  local i w
  secret_names "$SEG_DIR"
  for (( i = 0; i < NW; i++ )); do
    w=${WORDS[i]-}
    redirect_op "$w" && w=$RTGT
    [[ -n $w ]] || continue
    secret_word "$w"
    [[ $w == *=* ]] && secret_word "${w#*=}"
  done
  return 0
}

# quick_secret_scan <segment>: the secret check alone, for a segment nothing else needs parsed. Bash's own word
# split runs in C, where split_words' loop would take seconds over a long heredoc; the cost is that a quoted path
# holding whitespace is split apart and missed.
quick_secret_scan() {
  local w IFS=$' \t\r'
  SEG_DIR=$DIR
  secret_names "$DIR"
  set -f
  for w in $1; do
    w=${w//\'/}
    w=${w//\"/}
    redirect_op "$w" && w=$RTGT
    w=${w#\(}
    w=${w%\)}
    [[ -n $w ]] || continue
    secret_word "$w"
    [[ $w == *=* ]] && secret_word "${w#*=}"
  done
  set +f
  return 0
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

# guard_segment: a git, gh, glab, az or fj call, with the segment's directory and environment.
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

# secret_relevant <text>: could the text name a revealed git-secret file, from the current directory or by a path.
secret_relevant() {
  local n r=1
  [[ $1 == */* || $1 == *"$TILDE"* ]] && return 0
  secret_names "$DIR"
  [[ -n $SECRET_NAMES ]] || return 1
  local IFS=$NL
  set -f
  for n in $SECRET_NAMES; do
    [[ $1 == *"$n"* ]] && { r=0; break; }
  done
  set +f
  return $r
}

segment_relevant() {
  [[ $1 =~ $TOOL_RE ]] && return 0
  [[ $1 =~ $DOT_GLOB_RE ]] && return 0
  [[ $1 == *find* && $1 =~ -(delete|exec|execdir|ok|okdir)([[:space:]]|$) ]] && return 0
  case $1 in
    *cd*|*pushd*|*popd*|*export*|*unset*|*declare*|*typeset*|*readonly*|*'('*|*')'*) return 0 ;;
    *"$MARKER"*|*"$CUSTOMERS"*|*"$WAIVE_VAR"*|*git-secret*|*[.][Cc][Ll][Aa][Uu][Dd][Ee]-*) return 0 ;;
  esac
  return 1
}

# process_command <text> <nested>: splits, normalises and guards every segment. Exits 2 on the first block.
process_command() {
  local text=$1 nested=$2 s seglen seg k opens closes net p
  local -a seg_off=() seg_len=() dstack=() ib_text=() ib_off=() ib_done=()
  # Line by line, because bash 3.2's ${s//x/y} is quadratic in the number of matches: a 2000-line heredoc took
  # 90 seconds as one substitution. Within a line, separators become \001 in a copy of the same length, so offsets
  # map back to the text; the & or | of a redirection (>&, &>, <&, >|) is protected first.
  local line lpos=0 lp llen
  while IFS= read -r line || [[ -n $line ]]; do
    s=${line//'>&'/'>_'}
    s=${s//'>|'/'>_'}
    s=${s//'&>'/'_>'}
    s=${s//'<&'/'<_'}
    s=${s//[;|&]/$X1}
    llen=${#s}
    lp=0
    while (( lp <= llen )); do
      seg=${s:lp}
      seg=${seg%%"$X1"*}
      seglen=${#seg}
      if [[ -n ${seg//[[:space:]]/} ]]; then
        seg_off+=("$((lpos + lp))")
        seg_len+=("$seglen")
      fi
      lp=$((lp + seglen + 1))
    done
    lpos=$((lpos + ${#line} + 1))
  done <<< "$text"

  if (( ! nested )); then
    find_inner "$text"
    ib_text=("${IB_TEXT[@]}")
    ib_off=("${IB_OFF[@]}")
  fi

  for (( k = 0; k < ${#seg_off[@]}; k++ )); do
    seg=${text:seg_off[k]:seg_len[k]}
    if ! segment_relevant "$seg"; then
      secret_relevant "$seg" && quick_secret_scan "$seg"
    else
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

  check_protected_segment
  check_secret_segment
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
    git-secret)
      if reveals_secret "${ARGV[@]:1}"; then
        deny_reveal "${SEG_DIR:-$UNKNOWN_DIR}" "${ARGV[@]}"
        exit 2
      fi
      ;;
    git|gh|glab|az|fj)
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
        [[ -n $f ]] && basename_is_protected "$f" && deny_protected "$f"
      done
      ;;
  esac
  case $TOOL in
    Read|Write|Edit|MultiEdit|NotebookEdit)
      for f in "$FPATH" "$NBPATH"; do
        [[ -n $f ]] && check_secret_path "$f" "$CWD"
      done
      ;;
    Grep) [[ -n $GPATH ]] && check_secret_path "$GPATH" "${CWD:-$PWD}" ;;
  esac
  if [[ $SETS_WAIVER == 1 ]] && ! exempt_path "${FPATH:-$NBPATH}"; then
    deny_waiver ""
  fi

  [[ -n $CMD ]] || exit 0
  DIR=${CWD:-$PWD}
  segment_relevant "$CMD" || secret_relevant "$CMD" || exit 0
  init_env
  process_command "${CMD//"$BSNL"/}" 0
  exit 0
}

# --- can-file-issue and session-start ------------------------------------------------------------------------

# forgejo_host <host>: fj holds a login for the host, which makes it a Forgejo instance.
forgejo_host() {
  local h
  command -v fj >/dev/null 2>&1 || return 1
  while IFS= read -r h; do
    lower_eq "$h" "$1" && return 0
  done < <(fj auth list 2>/dev/null)
  return 1
}

can_file_issue() {
  local dir=$1 url tool
  url=$( unset GIT_DIR GIT_WORK_TREE; "$GIT" -C "$dir" remote get-url origin 2>/dev/null )
  if [[ -z $url ]] || ! parse_url "$url"; then echo none; return 0; fi
  if lower_eq "$U_HOST" github.com; then tool=gh
  elif is_gitlab_host "$U_HOST"; then tool=glab
  elif forgejo_host "$U_HOST"; then
    # fj's target isn't parsed, so no marker opens a customer's Forgejo: any customer remote means none.
    level_of_dir "$dir"
    if [[ $CL != customer ]] && no_customer_remote "$dir"; then echo fj; else echo none; fi
    return 0
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
  load_customers
  if (( LV_LISTED )); then
    text="Work context: customer (a listed customer folder${LV_URL:+, origin $LV_URL}), resolved by"
    text+=" ~/.claude/hooks/work-context.sh. $blocked"
  elif (( ! LV_REPO )); then
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
  if [[ ! -e $HOME/$CUSTOMERS ]]; then
    text+=" No ~/$CUSTOMERS on this machine, so nothing here is treated as customer work."
  elif [[ ! -r $HOME/$CUSTOMERS ]]; then
    text+=" Note: ~/$CUSTOMERS can't be read, so it protects nothing; tell the user."
  fi
  (( C_NODIR )) && text+=" Note: $C_NODIR directory line(s) of ~/$CUSTOMERS name no existing folder (letter case counts on a case-sensitive file system) and protect nothing until it exists; tell the user."
  (( C_UNREAD )) && text+=" Note: $C_UNREAD line(s) of ~/$CUSTOMERS are not understood and protect nothing; tell the user."
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
