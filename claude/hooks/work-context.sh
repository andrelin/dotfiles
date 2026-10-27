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
# The guard judges a repository git would refuse as dubiously owned too, since a command's own -c safe.directory=*
# opens it; an environment pair is command-line scope, which safe.directory honours.
n=${GIT_CONFIG_COUNT:-0}
export GIT_CONFIG_COUNT=$((n + 1)) "GIT_CONFIG_KEY_$n=safe.directory" "GIT_CONFIG_VALUE_$n=*"
unset n
UNKNOWN_DIR="<unknown directory>"
TILDE='~'
C_LOADED=0
LV_DEPTH=0
NA_KEY=() NA_NAME=() NA_SHORT=()
GIT_COPTS=()
FORCE_WRITE=0
X1=$'\001'
NL=$'\n'
BSNL=$'\\\n'
TOOL_RE='(^|[^[:alnum:]_-])(git|gh|glab|az)([^[:alnum:]_-]|$)'
# A removal or move, which could take $HOME and the protected files in it.
REMOVERS='g?rm|g?mv|trash|srm'
REMOVE_RE="(^|[^[:alnum:]_-])($REMOVERS)[[:space:]]"
# A dotfile glob or brace word, which can reach a protected file without spelling its name.
DOT_GLOB_RE='(^|[[:space:]/="'\''])\.[^[:space:]]*[]*?[{(]'

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

# drop_ssh <host> -> NOSSH: the host without an ssh. prefix, so ssh.dev.azure.com is dev.azure.com.
drop_ssh() {
  NOSSH=$1
  [[ ${NOSSH:0:4} == [sS][sS][hH]. ]] && NOSSH=${NOSSH:4}
  return 0
}

# host_label <host> -> H_LABEL: the label before the TLD and any co./com.-style second level, which also names folders
# and owners, so acme.no and acme.co.uk mark acme-portal; a hosting service's tenant, so acme.ghe.com does
# too; empty under three letters, so st.havnvik marks no st-app, and empty for an IP address, a cloud provider's default
# name (acme.westeurope.cloudapp.azure.com) or a word any git host has (git.bergen.kommune.no gives bergen, not git).
host_label() {
  local h=${1%.*}
  shopt -s nocasematch
  case $1 in
    *.ghe.com | *.gitlab.io | *.github.io | *.gitlab-dedicated.com) h=${1%%.*} ;;
    *) case ${h##*.} in co|com|org|net|gov|ac|edu|kommune|fylkeskommune) [[ $h == *.* ]] && h=${h%.*} ;; esac ;;
  esac
  H_LABEL=${h##*.}
  case $1 in
    *.amazonaws.com | *.azure.com | *.azurewebsites.net | *.cloudapp.net | *.googleusercontent.com) H_LABEL="" ;;
  esac
  case $H_LABEL in
    git | gitlab | github | gitea | forgejo | code | src | scm | dev) H_LABEL="" ;;
    *[!0-9]*) ;;
    *) H_LABEL="" ;;
  esac
  shopt -u nocasematch
  (( ${#H_LABEL} >= 3 )) || H_LABEL=""
}

# no_creds <url> -> NOCREDS: an http(s) URL without its user info, so a token in it is never printed.
no_creds() {
  local rest=${1#*://}
  NOCREDS=$1
  case $1 in http://* | https://*) [[ ${rest%%/*} == *@* ]] && NOCREDS=${1%%://*}://${rest#*@} ;; esac
  return 0
}

# The worst target seen so far: level, and the remote and URL that named it, for the deny message.
reset_worst() { W_RANK=0; W_LEVEL=personal; W_REMOTE=""; W_URL=""; }
bump() {
  local r
  case $1 in personal) r=1 ;; company) r=2 ;; *) r=3 ;; esac
  if (( r > W_RANK )); then no_creds "$3"; W_RANK=$r; W_LEVEL=$1; W_REMOTE=$2; W_URL=$NOCREDS; fi
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
  # Azure DevOps' SSH path is v3/<org>/<project>/<repo>, on its own hosts or an SSH alias for them, which has no dot;
  # its legacy hosts are one org each.
  if [[ $path == v3/*/*/* ]] && { [[ $host != *.* ]] || host_alias "$host" ssh.dev.azure.com ||
    host_alias "$host" vs-ssh.visualstudio.com; }; then
    path=${path#v3/}
  fi
  if lower_eq "$host" vs-ssh.visualstudio.com; then
    host=dev.azure.com
  elif vs_org_host "$host"; then
    path=${host%%.*}/$path; host=dev.azure.com
  fi
  [[ $path == */* ]] || return 1
  U_HOST=$host U_OWNER=${path%%/*} U_REPO=${path##*/}
  [[ -n $U_OWNER && -n $U_REPO ]]
}

# vs_org_host <host>: a legacy Azure DevOps host, <org>.visualstudio.com, one org each.
vs_org_host() {
  local r=1
  shopt -s nocasematch
  [[ $1 == [!.]*.visualstudio.com && $1 != vs-ssh.visualstudio.com ]] && r=0
  shopt -u nocasematch
  return $r
}

# customer_entry <line> -> ENTRY_KIND (org, host, dir or name), ENTRY and ENTRY_NAME (a relative dir as written): one line of the user's ~/.claude-customers,
# which lists customer work explicitly; nothing else is. A line is a host/owner, or a clone URL reduced to one the way
# parse_url reduces a remote; a bare host, all of whose owners are customer work, and a name too; a directory (/, ~ or
# $HOME, or a slash path whose first part has no dot, taken from $HOME) whose whole tree is; or a name or abbreviation.
# A # starting the line, or after a space, begins a comment. Fails with 1 on a blank or comment line, 2 on a line it
# can't read. Builtins only, for the shims.
customer_entry() {
  local line=${1#$'\xEF\xBB\xBF'} first rest port U_HOST U_OWNER U_REPO
  line=${line#"${line%%[![:space:]]*}"}
  ENTRY_NAME=""
  [[ $line == "#"* ]] && return 1
  line=${line%%[[:space:]]#*}
  line=${line%"${line##*[![:space:]]}"}
  [[ -n $line ]] || return 1
  [[ $line == \"*\" || $line == \'*\' ]] && line=${line:1:${#line}-2}
  case $line in '"$HOME"'* | '"${HOME}"'*) line='$HOME'${line#\"*\"} ;; esac
  case $line in
    '$HOME' | '${HOME}') line=$TILDE ;;
    '$HOME/'* | '${HOME}/'*) line=$TILDE/${line#*/} ;;
  esac
  line=${line%/}
  [[ -n $line ]] || return 2
  # A URL copied from a browser: its query and fragment name nothing, an org or group page names the org after
  # orgs/ or groups/, and a host alone is a whole host.
  if [[ $line == *://* ]]; then
    line=${line%%[?#]*}
    line=${line/\/orgs\//\/}; line=${line/\/groups\//\/}; line=${line/\/enterprises\//\/}
    rest=${line#*://}; rest=${rest%/}
    [[ $rest == */* ]] || line=${rest##*@}
  elif [[ ${line%%/*} == *.* && ${line%%/*} != .* ]]; then
    line=${line/\/orgs\//\/}; line=${line/\/groups\//\/}; line=${line/\/enterprises\//\/}
  fi
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
      customer_org_entry || return 2 ;;
    */*)
      first=${line%%/*}
      if [[ $first == *.* && $first != .* ]]; then
        parse_url "https://$line" || parse_url "https://${line%.git}/x" || return 2
        customer_org_entry || return 2
      else
        ENTRY_KIND=dir; ENTRY=$HOME/$line; ENTRY_NAME=$line
      fi
      ;;
    *)
      if vs_org_host "$line"; then
        # A legacy Azure DevOps host is one org, which parse_url reads as dev.azure.com/<org>.
        parse_url "https://$line/p/r" || return 2
        customer_org_entry || return 2
      elif [[ $line =~ ^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$ ]]; then
        ENTRY_KIND=host; ENTRY=$line
        drop_ssh "$ENTRY"; ENTRY=$NOSSH
      else
        # A comma lists several names on one line, which reads as one name that matches nothing; a legal form after
        # one (Acme, Inc.) is still one name.
        if [[ $line == *,* ]]; then
          rest=${line#*,}; rest=${rest#"${rest%%[![:space:]]*}"}
          is_legal_form "$rest" || return 2
          line=${line%%,*}
        fi
        # A note after the name (Acme - main customer, Acme (2024)), two names (Acme; Fjordvik), a user@host, or a
        # name with no letter or digit the guard can spell matches nothing.
        [[ $line == *[\(\)\;:@\[\]\<\>\|=!?]* || $line == *' - '* || $line == *' -- '* || $line == *' – '* || $line == *' — '* ]] && return 2
        ascii "$line"; [[ -n ${ASCII//[^[:alnum:]]/} ]] || return 2
        ENTRY_KIND=name; ENTRY=$line
      fi
      ;;
  esac
  return 0
}

# customer_org_entry: the U_HOST/U_OWNER customer_entry's parse_url call set, as an org entry, ssh. dropped.
customer_org_entry() {
  # A note after the entry without its #, a list bullet, several entries on one line or an owner no forge allows
  # (acme#note) match nothing.
  [[ $U_HOST == *[[:space:],]* || $U_OWNER == *[!A-Za-z0-9._-]* ]] && return 1
  drop_ssh "$U_HOST"
  ENTRY_KIND=org; ENTRY=$NOSSH/$U_OWNER
}

# load_customers -> C_KIND, C_ENTRY, C_DIR (a dir entry's canonical path, or empty), C_UNREAD (lines it can't read),
# C_NODIR (dir entries naming no folder as written): ~/.claude-customers, parsed once per run.
load_customers() {
  local line rc i=0
  (( C_LOADED )) && return 0
  C_LOADED=1 C_KIND=() C_ENTRY=() C_DIR=() C_UNREAD=0 C_NODIR=0
  [[ -f $HOME/$CUSTOMERS && -r $HOME/$CUSTOMERS ]] || return 0
  while IFS= read -r line || [[ -n $line ]]; do
    customer_entry "$line"; rc=$?
    if (( rc == 0 )); then
      C_KIND[i]=$ENTRY_KIND C_ENTRY[i]=$ENTRY C_DIR[i]=""
      if [[ $ENTRY_KIND == dir ]]; then
        # One not found as written, as in another letter case on Linux, still matches by its path in any case;
        # a relative one is also a name, as A/S Acme is.
        if ! C_DIR[i]=$(canon "$ENTRY"); then
          C_DIR[i]=$(canon_loose "$ENTRY")
          if [[ -n $ENTRY_NAME ]]; then
            i=$((i + 1)); C_KIND[i]=name C_ENTRY[i]=$ENTRY_NAME C_DIR[i]=""
            [[ $ENTRY_NAME == *[[:space:]]* ]] || C_NODIR=$((C_NODIR + 1))
          else
            C_NODIR=$((C_NODIR + 1))
          fi
        fi
      fi
      i=$((i + 1))
    elif (( rc == 2 )); then
      C_UNREAD=$((C_UNREAD + 1))
    fi
  done < "$HOME/$CUSTOMERS"
  return 0
}

# host_alias <host> <listed host>: an SSH host alias that stands for the listed host: one with no dot, or the listed host
# with a suffix, as github.com-work is.
host_alias() {
  local r=1
  [[ $1 != *.* ]] && return 0
  shopt -s nocasematch
  [[ $1 == "$2" || $1 == "$2"[-_.]* || $1 == *[-_.]"$2" ]] && r=0
  shopt -u nocasematch
  return $r
}

# is_own_owner <owner>: one of the user's own accounts, which no customer's name marks, as an owner or a folder, so
# Time Consulting doesn't take every uptimeconsulting repo.
is_own_owner() { lower_eq "$1" uptimeconsulting || lower_eq "$1" andrelin; }

# customer_org <host> <owner>: listed in ~/.claude-customers, as an owner, a whole host, or a name the owner is
# named for, which also catches a clone behind an SSH host alias. Builtins only, for the shims.
customer_org() {
  local host i own=0
  drop_ssh "$1"; host=$NOSSH
  is_own_owner "$2" && own=1
  load_customers
  for (( i = 0; i < ${#C_KIND[@]}; i++ )); do
    case ${C_KIND[i]} in
      org)
        lower_eq "${C_ENTRY[i]}" "$host/$2" && return 0
        # The listed owner behind an SSH host alias, dotless or the host with a suffix (github.com-work), is the same org.
        host_alias "$host" "${C_ENTRY[i]%%/*}" && lower_eq "${C_ENTRY[i]#*/}" "$2" && return 0
        ;;
      host)
        lower_eq "${C_ENTRY[i]}" "$host" && return 0
        # An alias for the host, its name with a suffix or a dotless one named for its label (acme-gitlab for
        # gitlab.acme.no), is the host.
        [[ $host == *.* ]] && host_alias "$host" "${C_ENTRY[i]}" && return 0
        host_label "${C_ENTRY[i]}"
        [[ $host != *.* && -n $H_LABEL ]] && named_for "$host" "$H_LABEL" && return 0
        # A domain covers its hosts, so acme.no covers gitlab.acme.no.
        lower_eq "${host: -${#C_ENTRY[i]}-1}" ".${C_ENTRY[i]}" && return 0
        (( own )) && continue
        named_for "$2" "${C_ENTRY[i]}" && return 0
        [[ -n $H_LABEL ]] && named_for "$2" "$H_LABEL" && return 0
        ;;
      name) (( ! own )) && named_for "$2" "${C_ENTRY[i]}" && return 0 ;;
    esac
  done
  return 1
}

# ascii <text> [long|flat] -> ASCII: Nordic and common accented letters spelled in ASCII, as folder names often are, so a
# customer named Fjærvik matches fjaervik-app and fjærvik-app alike under the guard's C locale. The short spelling writes
# ø, å and ü as o, a and u, the long one as oe, aa and ue, and the flat one as the short with æ as a; names are matched
# in each.
ascii() {
  local s=$1
  if [[ $s != *[![:ascii:]]* ]]; then ASCII=$s; return; fi
  # Finder stores names decomposed: compose the letters spelled two ways, then drop the other combining marks.
  s=${s//a$'\xcc\x8a'/å}; s=${s//A$'\xcc\x8a'/Å}; s=${s//o$'\xcc\x88'/ö}; s=${s//O$'\xcc\x88'/Ö}
  s=${s//a$'\xcc\x88'/ä}; s=${s//A$'\xcc\x88'/Ä}; s=${s//u$'\xcc\x88'/ü}; s=${s//U$'\xcc\x88'/Ü}
  s=${s//$'\xcc'?/}; s=${s//$'\xcd'?/}
  s=${s//ä/ae}; s=${s//Ä/AE}; s=${s//ß/ss}; s=${s//þ/th}
  s=${s//é/e}; s=${s//è/e}; s=${s//ê/e}; s=${s//É/E}; s=${s//á/a}; s=${s//à/a}; s=${s//â/a}; s=${s//Á/A}
  s=${s//í/i}; s=${s//ì/i}; s=${s//Í/I}; s=${s//ó/o}; s=${s//ò/o}; s=${s//ô/o}; s=${s//Ó/O}; s=${s//ú/u}
  s=${s//ù/u}; s=${s//Ú/U}; s=${s//ç/c}; s=${s//Ç/C}; s=${s//ñ/n}; s=${s//Ñ/N}; s=${s//ð/d}; s=${s//Ð/D}
  s=${s//ë/e}; s=${s//Ë/E}; s=${s//È/E}; s=${s//Ê/E}; s=${s//ï/i}; s=${s//Ï/I}; s=${s//î/i}; s=${s//Î/I}
  s=${s//À/A}; s=${s//Â/A}; s=${s//Ò/O}; s=${s//Ô/O}; s=${s//Ù/U}; s=${s//û/u}; s=${s//Û/U}; s=${s//ł/l}
  s=${s//Ł/L}; s=${s//č/c}; s=${s//Č/C}; s=${s//š/s}; s=${s//Š/S}; s=${s//ž/z}; s=${s//Ž/Z}; s=${s//ć/c}
  s=${s//ń/n}; s=${s//ś/s}; s=${s//ź/z}; s=${s//ż/z}; s=${s//ę/e}; s=${s//ą/a}; s=${s//ř/r}; s=${s//ě/e}
  s=${s//ů/u}; s=${s//ő/o}; s=${s//ű/u}; s=${s//ý/y}; s=${s//Ý/Y}; s=${s//ş/s}; s=${s//ğ/g}; s=${s//ı/i}
  s=${s//đ/d}; s=${s//Đ/D}; s=${s//Ś/S}; s=${s//Ż/Z}; s=${s//œ/oe}; s=${s//Œ/OE}; s=${s//ŋ/ng}; s=${s//Ŋ/NG}
  s=${s//ŧ/t}; s=${s//Ŧ/T}; s=${s//İ/I}; s=${s//Ő/O}; s=${s//Ř/R}; s=${s//Ě/E}; s=${s//Ů/U}; s=${s//Ć/C}
  s=${s//Ń/N}; s=${s//Ź/Z}; s=${s//Ę/E}; s=${s//Ą/A}; s=${s//Ş/S}; s=${s//Ğ/G}; s=${s//Ű/U}; s=${s//č/c}
  if [[ ${2-} == long ]]; then
    s=${s//ø/oe}; s=${s//Ø/OE}; s=${s//ö/oe}; s=${s//Ö/OE}; s=${s//å/aa}; s=${s//Å/AA}; s=${s//ü/ue}; s=${s//Ü/UE}
  else
    s=${s//ø/o}; s=${s//Ø/O}; s=${s//ö/o}; s=${s//Ö/O}; s=${s//å/a}; s=${s//Å/A}; s=${s//ü/u}; s=${s//Ü/U}
  fi
  # æ is ae, and a in the flat spelling, as Fjærvik is often written Fjarvik.
  if [[ ${2-} == flat ]]; then s=${s//æ/a}; s=${s//Æ/A}; else s=${s//æ/ae}; s=${s//Æ/AE}; fi
  ASCII=$s
}

# named_for <component> <name>: a folder name names a customer. A name of five or more letters and digits matches
# anywhere in the component, ignoring case and punctuation; a shorter abbreviation must be a whole word of it, so
# FVK marks fvk-portal but not fvkx.
named_for() {
  named_as "$1" "$2" "" && return 0
  # Plain ASCII on both sides spells one way only.
  [[ $1$2 == *[![:ascii:]]* ]] || return 1
  named_as "$1" "$2" long || named_as "$1" "$2" flat
}

# is_legal_form <word>: a company's legal form, with or without a trailing dot, in any letter case.
is_legal_form() {
  local r=1
  shopt -s nocasematch
  case ${1%.} in
    as|asa|ans|da|nuf|a/s|ab|aps|oy|oyj|ltd|limited|gmbh|inc|llc|bv|nv|sa|plc|ag|corp|corporation|co|company) r=0 ;;
  esac
  shopt -u nocasematch
  return $r
}

# no_legal_form <name> -> NOLEGAL: the name without its legal-form words, so Acme AS and A/S Acme are Acme.
no_legal_form() {
  local w out="" IFS=" "
  set -f
  for w in $1; do
    is_legal_form "$w" || out+=${out:+ }$w
  done
  set +f
  NOLEGAL=${out:-$1}
}

# named_as <component> <name> <spelling>: named_for in one ASCII spelling, applied to both sides.
named_as() {
  local comp name word short r=1 IFS=" " bare k
  # The name's spellings, kept per spelling while the same name is checked against each folder in turn.
  case $3 in long) k=1 ;; flat) k=2 ;; *) k=0 ;; esac
  if [[ ${NA_KEY[k]-$X1} != "$2" ]]; then
    no_legal_form "$2"; bare=$NOLEGAL
    ascii "$bare" "$3"; NA_NAME[k]=${ASCII//[^[:alnum:]]/}
    # Which rule applies is decided on the short spelling, so Mørk is an abbreviation in both.
    ascii "$bare"; NA_SHORT[k]=${ASCII//[^[:alnum:]]/}
    NA_KEY[k]=$2
  fi
  name=${NA_NAME[k]} short=${NA_SHORT[k]}
  [[ -n $name ]] || return 1
  ascii "$1" "$3"; comp=$ASCII
  # Camel case splits into words, so FVK marks FvkPortal and FVKPortal.
  while [[ $comp =~ ^(.*[a-z])([A-Z].*)$ || $comp =~ ^(.*[A-Z])([A-Z][a-z].*)$ ]]; do
    comp="${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
  done
  shopt -s nocasematch
  # A spelling under five letters matches as a whole word only, so Mære's flat mare isn't found inside nightmare.
  if (( ${#short} >= 5 && ${#name} >= 5 )); then
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
# below $HOME in a folder whose name names a listed customer or host: a repository's own location, or a folder outside
# any repository, never a subfolder of a repository a command runs in, and never outside $HOME, where Claude's scratch
# paths live.
customer_dir() {
  local d home rel comp i e
  local -a comps=()
  has_customers || return 1
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
        # A link into the listed folder counts by its path as given, wherever the link points.
        for e in "${C_ENTRY[i]}" "${C_DIR[i]}"; do
          [[ $1 == /* ]] && { lower_eq "$1" "$e" || lower_eq "${1:0:${#e}+1}" "$e/"; } && return 0
        done
        ;;
      name|host)
        e=${C_ENTRY[i]}
        for comp in ${comps[@]+"${comps[@]}"}; do
          is_own_owner "$comp" || ! named_for "$comp" "$e" || return 0
        done
        if [[ ${C_KIND[i]} == host ]]; then
          host_label "$e"
          [[ -n $H_LABEL ]] || continue
          for comp in ${comps[@]+"${comps[@]}"}; do
            is_own_owner "$comp" || ! named_for "$comp" "$H_LABEL" || return 0
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
  local common
  customer_dir "$1" && return 0
  gitdir_top "$1" "${2-}"
  [[ -n $TOP ]] && customer_dir "$TOP" names && return 0
  common=$( unset GIT_WORK_TREE; "$GIT" -C "$1" ${2:+"--git-dir=$2"} rev-parse --git-common-dir 2>/dev/null )
  [[ -n $common ]] || return 1
  [[ $common == /* ]] || common=$1/$common
  [[ ${common##*/} == .git ]] && common=${common%/*}
  customer_dir "$common" names
}

# gitdir_top <dir> [git-dir] -> TOP: the repository's own toplevel, or empty. With --git-dir and no work tree, git
# reports the directory it runs in as the toplevel, so it is taken from a git dir named .git, and is unknown otherwise.
gitdir_top() {
  TOP=""
  if [[ -n ${2-} ]]; then
    if [[ ${2##*/} == .git ]]; then
      if [[ $2 == */* ]]; then TOP=${2%/*}; else TOP=.; fi
      [[ $TOP == /* ]] || TOP=$1/$TOP
    fi
  else
    TOP=$( unset GIT_DIR GIT_WORK_TREE; "$GIT" -C "$1" rev-parse --show-toplevel 2>/dev/null )
  fi
}

# has_customers: ~/.claude-customers lists at least one entry.
has_customers() {
  load_customers
  (( ${#C_KIND[@]} ))
}

# is_resolved <dir>: an absolute path, which the guard can judge, whether or not it exists yet; a cd to a variable or
# cd - leaves the unknown-directory marker instead.
is_resolved() { [[ $1 == /* ]]; }

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
  elif ! is_resolved "$1"; then unresolved_class
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
  local dir=$1 top url up own
  LV_URL="" LV_REPO=0 LV_LISTED=0
  # A folder not made yet is judged by the entries naming it, else by the nearest folder above it that exists, so a
  # new subfolder of a customer repository is customer work too.
  if [[ $dir == /?* && ! -e $dir ]]; then
    if customer_dir "$dir" names; then CL=customer LV_LISTED=1; return; fi
    up=${dir%/*}
    while [[ -n $up && ! -e $up ]]; do up=${up%/*}; done
    level_of_dir "${up:-/}"
    return
  fi
  ( unset GIT_DIR GIT_WORK_TREE; "$GIT" -C "$dir" rev-parse --absolute-git-dir >/dev/null 2>&1 ) && LV_REPO=1
  if (( ! LV_REPO )); then
    no_repo_class "$dir"
    [[ $CL == customer ]] && is_resolved "$dir" && LV_LISTED=1
    return
  fi
  url=$( unset GIT_DIR GIT_WORK_TREE; "$GIT" -C "$dir" remote get-url origin 2>/dev/null )
  no_creds "$url"; LV_URL=$NOCREDS own=$NOCREDS
  load_customers # here, not in the subshell below, where the parse would be lost
  if ( unset GIT_DIR; customer_repo "$dir" ); then
    CL=customer LV_LISTED=1
    return
  fi
  if [[ -n $url ]]; then
    # A local-path origin is judged by where it points; a chain of them that loops is unresolved.
    if (( LV_DEPTH > 8 )); then
      unresolved_class
    else
      LV_DEPTH=$((LV_DEPTH + 1))
      url_class_at "$url" "$dir"
      LV_DEPTH=$((LV_DEPTH - 1))
    fi
    LV_URL=$own LV_REPO=1 LV_LISTED=0
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

# rgit: git on the resolved repository, with the command's own -c settings, which pick its push target too.
rgit() { ( unset GIT_DIR GIT_WORK_TREE; "$GIT" ${GIT_COPTS[@]+"${GIT_COPTS[@]}"} --git-dir="$R_GITDIR" "$@" ) 2>/dev/null; }

# repo_top <git-dir-override> -> R_TOP, the resolved repository's own toplevel.
repo_top() {
  gitdir_top "$R_DIR" "${1:-${GIT_DIR-}}"
  R_TOP=$TOP
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
  resolve_cd "$R_DIR" "$t"
  p=$NEWDIR
  if [[ -z $p ]]; then
    unresolved_class
    bump "$CL" "$t" "(an unexpanded target)"
  elif [[ -d $p ]]; then
    level_of_dir "$p"
    bump "$CL" "$t" "$p"
  elif [[ $t == *:* || $t == */* ]]; then
    # A file:// URL is a path, judged by where it points, as a remote's would be.
    url_class_at "$t" "$R_DIR"
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
  local n=$# i=0 w gitdir="" sub="" orig_sub val forced=0 forbidden=0 r first="" cdir k
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
      -c|--namespace|--config-env|--attr-source|--work-tree)
        # Only the settings that pick a push target: a malformed one would fail every read the guard makes.
        [[ $w == -c && ${a[i+1]} =~ ^([Rr][Ee][Mm][Oo][Tt][Ee]|[Bb][Rr][Aa][Nn][Cc][Hh]|[Uu][Rr][Ll])\.([^=]+\.)?[A-Za-z][A-Za-z0-9-]*= ]] &&
          GIT_COPTS+=(-c "${a[i+1]}")
        shown+=("$w" "${a[i+1]}"); i=$((i + 2)); continue ;;
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

  # An alias can name another; where the directory is unknown, the global ones still apply.
  cdir=$dir
  [[ -d $cdir ]] || cdir=/
  for (( k = 0; k < 5; k++ )); do
    [[ $COMMON_BUILTINS != *" $sub "* ]] || break
    val=$( "$GIT" -C "$cdir" ${gitdir:+"--git-dir=$gitdir"} config --get "alias.$sub" 2>/dev/null )
    if [[ -z $val ]] || is_builtin "$sub"; then break; fi
    case $val in
      '!'*|-*) forced=1; break ;;
      *) sub=${val%%[[:space:]]*} ;;
    esac
  done

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

# names_origin <owner/repo values>: one of them is the repository LV_URL is the origin of.
names_origin() {
  local v
  parse_url "$LV_URL" || return 1
  for v in "$@"; do
    v=${v#*://}; v=${v%.git}
    [[ $v == */*/* ]] && v=${v#*/}
    lower_eq "$v" "$U_OWNER/$U_REPO" && return 0
  done
  return 1
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
  # A named repo replaces the directory's own, so only a listed directory, the folder's own repo named for a customer,
  # or a directory the guard can't resolve still counts.
  if (( FLAG_USED && ! issue_create )); then
    level_of_dir "$dir"
    if customer_dir "$dir" || { (( LV_LISTED )) && names_origin "${flag_values[@]}"; }; then
      bump customer "a listed customer folder" ""
      T_LEVEL+=(customer); T_HOST+=("")
    elif ! is_resolved "$dir"; then
      unresolved_class
      if [[ $CL == customer ]]; then
        bump customer "a directory the guard cannot resolve" ""
        T_LEVEL+=(customer); T_HOST+=("")
      fi
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
    re='^/?(orgs|users|groups)/([^/?]+)([/?]|$)'
    if [[ ${pos[1]} =~ $re ]]; then
      case ${BASH_REMATCH[2]} in
        *'{'*|:*) ;;
        *%2[Ff]*) id=${BASH_REMATCH[2]}; named_target "$host" "${id%%\%2[Ff]*}" "" "endpoint" "${pos[1]}" ;;
        *) named_target "$host" "${BASH_REMATCH[2]}" "" "endpoint" "${pos[1]}" ;;
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

  if [[ ${pos[0]} == api ]] && (( ! NAMED && ! REPO_OK && ! FLAG_USED )); then
    unresolved_class
    bump "$CL" "an endpoint naming no repository, sent from outside one" "${pos[1]-}"
    T_LEVEL+=("$CL"); T_HOST+=("")
  fi
  (( W_RANK <= 2 )) && return 0
  (( issue_create )) && marker_ok "$tool" && return 0
  deny "$dir" "$tool" "${args[@]}"
  return 2
}

# --- az ------------------------------------------------------------------------------------------------------

check_az() {
  local dir=$1 a last next="" write=1 org=""
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
  for a in "$@"; do
    if [[ -n $next ]]; then org=$a; next=""; continue; fi
    case $a in
      --org|--organization) next=1 ;;
      --org=*|--organization=*) org=${a#*=} ;;
    esac
  done
  reset_worst
  T_LEVEL=() T_HOST=()
  if [[ -n $org ]]; then
    if parse_url "${org%/}/p/r"; then classify "$U_HOST" "$U_OWNER" ""; else unresolved_class; fi
    bump "$CL" "--org" "$org"
    # As with gh -R, the org replaces the directory's repository, but not a listed directory or an unresolvable one.
    if customer_dir "$dir"; then
      bump customer "a listed customer folder" ""
    elif ! is_resolved "$dir"; then
      unresolved_class
      bump "$CL" "a directory the guard cannot resolve" ""
    fi
  elif resolve_repo "$dir" ""; then
    origin_target ""
  else
    # Outside a repository az falls back to the default org az devops configure set, which the guard doesn't read.
    unresolved_class
    bump "$CL" "no git repository" ""
  fi
  [[ $W_LEVEL != customer ]] && return 0
  deny "$dir" az "$@"
  return 2
}

check_argv() {
  local dir=$1 tool=${2##*/}
  shift 2
  GIT_COPTS=()
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
  local base=${1##*/}
  base=${base//[\"\']/}
  if [[ $base == *[*?[\{\(]* ]]; then
    echo "\`$1\` could match ~/$CUSTOMERS or $MARKER, which only the user writes: narrow it, or give the user the" \
      "command to run with \`! \`." >&2
  elif lower_eq "$base" "$CUSTOMERS"; then
    echo "Only the user edits ~/$CUSTOMERS: ask them to run \`! echo '<entry>' >> ~/$CUSTOMERS\`," \
      "where the entry is one of a host/owner, a directory or a customer's name." >&2
  else
    echo "Only the user creates $MARKER: ask them to run \`! touch $1\`" >&2
  fi
  exit 2
}

deny_home() {
  echo "\`$1\` reaches \$HOME, and would take ~/$CUSTOMERS and $MARKER with it: narrow it, or give the user the" \
    "command to run with \`! \`." >&2
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

# The issue marker and the customers file: each loosens the guard, so only the user writes them.
# A word that is the name or a glob matching it, in any letter case, as macOS's file system ignores case.
# With a second argument the word is a find -name pattern, which matches dotfiles whether or not it starts with a dot.
basename_is_protected() {
  local base=${1##*/} r=1 name pre post alts re='^(.*)\{([^{}]*,[^{}]*)\}(.*)$'
  # A brace list names each of its words, so x{,.y} and {x,.y} are .y too.
  if [[ $1 =~ $re ]]; then
    pre=${BASH_REMATCH[1]} alts=${BASH_REMATCH[2]}, post=${BASH_REMATCH[3]}
    while [[ -n $alts ]]; do
      basename_is_protected "$pre${alts%%,*}$post" ${2+"$2"} && return 0
      alts=${alts#*,}
    done
    return 1
  fi
  base=${base//[\"\']/}
  # A glob, brace or zsh alternation word only reaches a dotfile when it starts with a dot, as the protected files'
  # names do.
  # The | of an alternation splits the word as a pipe would, so its part from the ( on reads as *.
  [[ $base == .* || -n ${2-} ]] && { base=${base//\{*\}/*}; [[ $base == *'('* ]] && base="${base%%'('*}*"; }
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
  NI=0 EVAL_BODY=""
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
      eval)
        # eval re-parses its arguments, so they are a command of their own; a leading -- ends its options.
        [[ ${WORDS[NI+1]-} == -- ]] && NI=$((NI + 1))
        EVAL_BODY="${WORDS[*]:NI+1:n-NI-1}"
        NI=$((NI + 1))
        ;;
      command|builtin|exec|nohup|then|do|else|elif|if|while|until|'!'|'{'|time)
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

# reaches_home <word> <rc-if-unresolved>: a path at or above $HOME, which holds the protected files; one the guard
# can't resolve returns <rc-if-unresolved>.
reaches_home() {
  local d h
  resolve_cd "$SEG_DIR" "$1"
  [[ -n $NEWDIR ]] || return "$2"
  d=$(canon_loose "$NEWDIR") || return "$2"
  h=$(canon "$HOME") || h=$HOME
  [[ $d == / || $h == "$d" || $h == "$d"/* ]]
}

# link_target <path> -> LINKED: where a chain of symlinks from the path ends, else the path itself.
link_target() {
  local t i=0
  LINKED=$1
  while [[ -L $LINKED ]] && (( i++ < 16 )); do
    t=$(readlink "$LINKED") || break
    [[ $t == /* ]] || t=${LINKED%/*}/$t
    LINKED=$t
  done
  return 0
}

# redirect_target <word> -> RPRE (a word glued before the redirection, as in cat<f), ROUT (1 when it writes), RTGT
# (its target, empty when the next word is); fails when the word holds none. A >&N, <&N or >&- names a descriptor,
# not a file, so its RTGT is that &N.
redirect_target() {
  local rest op=""
  [[ $1 == *[\<\>]* ]] || return 1
  RPRE=${1%%[<>]*}
  rest=${1#"$RPRE"}
  RPRE=${RPRE%&}
  # The descriptor of 2>&1 or 2>err is no word of its own.
  [[ -n $RPRE && -z ${RPRE//[0-9]/} ]] && RPRE=""
  while [[ $rest == [\<\>\&\|]* ]]; do op+=${rest:0:1}; rest=${rest:1}; done
  ROUT=0
  [[ $op == *'>'* ]] && ROUT=1
  RTGT=$rest
  if [[ $op == ?*'&' && ( $rest == - || ( -n $rest && -z ${rest//[0-9]/} ) ) ]]; then RTGT="&$rest"; fi
  return 0
}

# A protected file, written by a redirection or a file-writing command.
check_protected_segment() {
  local i j w reach roots named negated last=0
  # Any > writes, glued to the word before it (x>f, :>f) or not, <> and >& included; one in a quoted argument blocks
  # falsely.
  for (( i = NI; i < NW; i++ )); do
    redirect_target "${WORDS[i]}" && (( ROUT )) || continue
    if [[ -n $RTGT ]]; then basename_is_protected "$RTGT" && deny_protected "$RTGT"
    else basename_is_protected "${WORDS[i+1]-}" && deny_protected "${WORDS[i+1]}"; fi
  done
  case $FIRST in
    find)
      # find only writes with -delete or -exec; a find that names the file to look for it is a read. A pattern only
      # reaches the protected files from a root at or above $HOME, or one the guard can't resolve.
      for (( i = NI + 1; i < NW; i++ )); do
        case ${WORDS[i]} in -delete | -exec | -execdir | -ok | -okdir) ;; *) continue ;; esac
        reach=0 roots=0
        # find's own leading options (-L, -H, -P, -E, -x, -D <debug>, -O<level>) come before its roots.
        for (( j = NI + 1; j < NW; j++ )); do
          case ${WORDS[j]} in -[HLPEXdsx] | -O*) ;; -D) j=$((j + 1)) ;; *) break ;; esac
        done
        for (( ; j < NW; j++ )); do
          case ${WORDS[j]} in -* | '(' | '!') break ;; esac
          roots=1
          reaches_home "${WORDS[j]}" 0 && reach=1
        done
        (( roots )) || { reaches_home . 0 && reach=1; }
        named=0 negated=0
        for (( j = NI + 1; j < NW; j++ )); do
          basename_is_protected "${WORDS[j]}" && deny_protected "${WORDS[j]}"
          (( reach )) || continue
          case ${WORDS[j-1]} in
            -name | -iname | -path | -ipath | -wholename | -iwholename)
              named=1
              # A pattern of wildcards alone names every file, the protected ones included.
              [[ -z ${WORDS[j]//[*?\'\"]/} ]] && deny_home "find ${WORDS[j]}"
              basename_is_protected "${WORDS[j]}" pattern && deny_protected "${WORDS[j]}" ;;
            -regex | -iregex) deny_home "find ${WORDS[j-1]}" ;;
          esac
          case ${WORDS[j]} in
            # Negated or alternative tests (! -name x, -o) let other files through to -delete.
            '!' | -not | -o | -or) named=0; negated=1 ;;
          esac
        done
        # With no name test, find writes every file below its roots.
        (( reach && ( ! named || negated ) )) && deny_home "find"
        break
      done
      ;;
    sed|gsed|awk|gawk)
      # These only read the files they're given, unless they edit in place (sed -i, gawk -i inplace).
      for (( i = NI + 1; i < NW; i++ )); do
        case ${WORDS[i]} in -i* | --in-place* | -[!-]*i*) last=1 ;; esac
      done
      (( last )) || return 0
      for (( i = NI + 1; i < NW; i++ )); do
        basename_is_protected "${WORDS[i]}" && deny_protected "${WORDS[i]}"
      done
      ;;
    cp|gcp|install|ginstall|ditto|rsync)
      # These write only their last operand.
      for (( i = NI + 1; i < NW; i++ )); do
        [[ ${WORDS[i]} == -* ]] || last=$i
      done
      (( last )) && basename_is_protected "${WORDS[last]}" && deny_protected "${WORDS[last]}"
      ;;
    touch|tee|ln|perl|dd|truncate|unlink|chmod|chflags|xattr|shred|ed|ex|curl|wget|gtouch|gtee|gln|gdd|gtruncate|gunlink|\
    gchmod|gshred|vi|vim|nvim)
      for (( i = NI + 1; i < NW; i++ )); do
        basename_is_protected "${WORDS[i]}" && deny_protected "${WORDS[i]}"
      done
      ;;
    *)
      [[ $FIRST =~ ^($REMOVERS)$ ]] || return 0
      # Removing or moving $HOME, or a folder above it, takes the protected files with it; a move's destination is
      # only where it goes.
      if [[ $FIRST == *mv ]]; then
        for (( i = NI + 1; i < NW; i++ )); do
          [[ ${WORDS[i]} == -* ]] || last=$i
        done
      fi
      for (( i = NI + 1; i < NW; i++ )); do
        (( i != last )) && [[ ${WORDS[i]} != -* ]] && reaches_home "${WORDS[i]}" 1 && deny_home "${WORDS[i]}"
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
    if redirect_target "$w"; then
      [[ -n $RPRE ]] && secret_word "$RPRE"
      w=$RTGT
    fi
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
    if redirect_target "$w"; then
      [[ -n $RPRE ]] && secret_word "$RPRE"
      w=$RTGT
    fi
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
    # A redirection glued to a word (push>out) leaves the word an argument of its own. A word ending in the operator,
    # or holding a space, is a quoted argument ("a >"), which must not swallow the word after it.
    if redirect_target "$w" && [[ $w != *[[:space:]]* ]] && [[ -z $RPRE || -n $RTGT ]]; then
      [[ -n $RPRE ]] && ARGV+=("$RPRE")
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
          if [[ -n $val && ( -n $dir || $val == /* ) ]]; then
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
  local bare line
  [[ $1 =~ $TOOL_RE ]] && return 0
  [[ $1 =~ $REMOVE_RE ]] && return 0
  [[ $1 =~ $DOT_GLOB_RE ]] && return 0
  [[ $1 == *find* && $1 =~ -(delete|exec|execdir|ok|okdir)([[:space:]]|$) ]] && return 0
  case $1 in
    *cd*|*pushd*|*popd*|*export*|*unset*|*declare*|*typeset*|*readonly*|*'('*|*')'*) return 0 ;;
    *"$MARKER"*|*"$CUSTOMERS"*|*"$WAIVE_VAR"*|*git-secret*|*[.][Cc][Ll][Aa][Uu][Dd][Ee]-*) return 0 ;;
  esac
  # A protected name spelt with quotes or backslashes inside it (.cla''ude-). Line by line, since bash 3.2's ${s//x/y}
  # is quadratic over a long text such as a heredoc.
  [[ $1 == *[\'\"\\]* ]] || return 1
  while IFS= read -r line; do
    bare=${line//[\'\"\\]/}
    [[ $bare == *[.][Cc][Ll][Aa][Uu][Dd][Ee]-* ]] && return 0
  done <<< "$1"
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

  if [[ -n $EVAL_BODY ]]; then
    # Not in a subshell: a cd inside the eval moves the segments after it, as it does in the shell.
    DIR=$SEG_DIR
    process_command "$EVAL_BODY" 1 || exit $?
    return 0
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
        [[ -n $f ]] || continue
        basename_is_protected "$f" && deny_protected "$f"
        link_target "$f"
        basename_is_protected "$LINKED" && deny_protected "$LINKED"
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

# forgejo_host <host>: fj holds a login for the host, which makes it a Forgejo instance.
forgejo_host() {
  local h
  command -v fj >/dev/null 2>&1 || return 1
  while IFS= read -r h; do
    lower_eq "$(host_only "$h")" "$1" && return 0
  done < <(fj auth list 2>/dev/null)
  return 1
}

# forgejo_listed: an org or host entry is on a host fj holds a login for, where fj's writes pass unchecked.
forgejo_listed() {
  local i
  command -v fj >/dev/null 2>&1 || return 1
  load_customers
  for (( i = 0; i < ${#C_KIND[@]}; i++ )); do
    case ${C_KIND[i]} in
      org) forgejo_host "${C_ENTRY[i]%%/*}" && return 0 ;;
      host) forgejo_host "${C_ENTRY[i]}" && return 0 ;;
    esac
  done
  return 1
}

can_file_issue() {
  local dir=$1 url tool
  url=$( unset GIT_DIR GIT_WORK_TREE; "$GIT" -C "$dir" remote get-url origin 2>/dev/null )
  if [[ -z $url ]] || ! parse_url "$url"; then echo none; return 0; fi
  if lower_eq "$U_HOST" github.com; then tool=gh
  elif is_gitlab_host "$U_HOST"; then tool=glab
  elif forgejo_host "$U_HOST"; then
    # fj is unguarded, so no marker opens a customer's Forgejo: any customer remote means none.
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
    tool=$(can_file_issue "$cwd")
    [[ $tool != none ]] && text+=" Filing an issue with $tool issue create is allowed."
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
  elif [[ ! -f $HOME/$CUSTOMERS || ! -r $HOME/$CUSTOMERS ]]; then
    text+=" Note: ~/$CUSTOMERS can't be read, so it protects nothing; tell the user."
  elif [[ $CL != customer ]]; then
    text+=" A customer's work that ~/$CUSTOMERS doesn't list is not guarded."
  fi
  (( C_NODIR )) && text+=" Note: $C_NODIR directory line(s) of ~/$CUSTOMERS name no existing folder as written; they match by path in any letter case, but check their spelling; tell the user."
  (( C_UNREAD )) && text+=" Note: $C_UNREAD line(s) of ~/$CUSTOMERS are not understood and protect nothing; tell the user."
  if forgejo_listed || { [[ $CL == customer ]] && parse_url "$LV_URL" && forgejo_host "$U_HOST"; }; then
    text+=" Note: ~/$CUSTOMERS lists a Forgejo host fj is logged in to, or customer work on one, and fj is unguarded,"
    text+=" so its writes there aren't blocked; tell the user."
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

abs_path() { if [[ $1 == /* ]]; then printf '%s' "$1"; else printf '%s' "$PWD/$1"; fi; }

main() {
  strip_shims
  local cmd=$1
  shift
  case $cmd in
    level) level_of_dir "$(abs_path "${1:-$PWD}")"; echo "$CL" ;;
    check-argv) (( $# >= 2 )) || return 64; check_argv "$@" ;;
    pre-tool-use) pre_tool_use ;;
    can-file-issue) can_file_issue "$(abs_path "${1:-$PWD}")" ;;
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
