# Print terminal tips from $DOTFILES/tips/*.md.
#
# Usage: tips [-h|--help] [-l|--list] [<SELECTOR>]
#
# Selectors:
#   <FILE>             — one file by leading prefix (e.g. 22 → tips/22_dev_infra.md)
#   <FILE>.<N>         — one tip (e.g. 22.3)
#   <D>x               — all files in a decade (e.g. 2x → 20–29)
#   <FROM>-<TO>        — explicit file-id range (e.g. 20-24)
#   (none)             — every file
#
# `-l` / `--list` switches the selector's output to titles-only.
tips() {
    local tips_dir="$DOTFILES/tips"

    if [[ ! -d "$tips_dir" ]]; then
        echo "tips: $tips_dir not found" >&2
        return 1
    fi

    # In zsh, empty globs error out by default. Make them expand to nothing.
    [[ -n "$ZSH_VERSION" ]] && setopt local_options null_glob

    # Argument parsing — list flag can appear anywhere, plus one optional selector.
    local list_mode=0
    local selector=""
    local arg
    for arg in "$@"; do
        case "$arg" in
            -h|--help)
                cat <<'EOF'
Usage: tips [-h|--help] [-l|--list] [<SELECTOR>]

Selectors:
  <FILE>          One file by leading prefix (e.g. 'tips 22')
  <FILE>.<N>      One tip (e.g. 'tips 22.3')
  <D>x            All files in a decade (e.g. 'tips 2x' → files 20–29)
  <FROM>-<TO>     Explicit file-id range (e.g. 'tips 20-24')
  (none)          Every file

Modifier:
  -l / --list     List titles only

Examples:
  tips                   Show all tips
  tips -l                List every tip title, grouped by file
  tips 22                Show all of 22_dev_infra.md
  tips 22.3              Show a single tip
  tips 2x                Show every repo-features file
  tips -l 2x             List titles in the 2x decade
  tips 20-24             Explicit-range equivalent of 2x

New here? Run 'tips 20.1'.
EOF
                return 0
                ;;
            -l|--list)
                list_mode=1
                ;;
            *)
                if [[ -n "$selector" ]]; then
                    echo "tips: too many arguments" >&2
                    echo "Run 'tips -h' for usage." >&2
                    return 1
                fi
                selector="$arg"
                ;;
        esac
    done

    # Resolve selector → list of file paths + optional single-tip id/file.
    local -a files=()
    local single_tip=""
    local single_tip_file=""

    if [[ -z "$selector" ]]; then
        local f
        for f in "$tips_dir"/*.md; do
            [[ -e "$f" ]] && files+=("$f")
        done
    else
        case "$selector" in
            *[!0-9.x-]*|.*|*..*|*-*-*)
                echo "tips: invalid selector '$selector'" >&2
                echo "Run 'tips -h' for usage." >&2
                return 1
                ;;
            *.*)
                # <FILE>.<N> — single tip
                local file_id="${selector%.*}"
                local rest="${selector#*.}"
                if [[ -z "$file_id" || -z "$rest" || "$file_id" != "${file_id//[!0-9]/}" || "$rest" != "${rest//[!0-9]/}" ]]; then
                    echo "tips: invalid tip id '$selector'" >&2
                    return 1
                fi
                local f
                f=$(_tips_file_for "$tips_dir" "$file_id")
                if [[ -z "$f" ]]; then
                    echo "tips: no file with prefix '$file_id'" >&2
                    return 1
                fi
                files=("$f")
                single_tip="$selector"
                single_tip_file="$f"
                ;;
            *-*)
                # <FROM>-<TO> range
                local from="${selector%-*}"
                local to="${selector#*-}"
                if [[ -z "$from" || -z "$to" || "$from" != "${from//[!0-9]/}" || "$to" != "${to//[!0-9]/}" ]]; then
                    echo "tips: invalid range '$selector'" >&2
                    return 1
                fi
                local f prefix
                for f in "$tips_dir"/*.md; do
                    [[ -e "$f" ]] || continue
                    prefix=$(_tips_prefix "$f")
                    [[ -z "$prefix" ]] && continue
                    if (( prefix >= from && prefix <= to )); then
                        files+=("$f")
                    fi
                done
                if (( ${#files[@]} == 0 )); then
                    echo "tips: no files in range $selector" >&2
                    return 1
                fi
                ;;
            *x)
                # <D>x decade wildcard
                local decade="${selector%x}"
                if [[ -z "$decade" || "$decade" != "${decade//[!0-9]/}" || ${#decade} -ne 1 ]]; then
                    echo "tips: invalid section selector '$selector' (expected one digit + 'x')" >&2
                    return 1
                fi
                local f
                for f in "$tips_dir"/${decade}?_*.md; do
                    [[ -e "$f" ]] && files+=("$f")
                done
                if (( ${#files[@]} == 0 )); then
                    echo "tips: no files in section ${decade}x" >&2
                    return 1
                fi
                ;;
            *)
                # <FILE> — pure integer
                if [[ "$selector" != "${selector//[!0-9]/}" ]]; then
                    echo "tips: invalid selector '$selector'" >&2
                    return 1
                fi
                local f
                f=$(_tips_file_for "$tips_dir" "$selector")
                if [[ -z "$f" ]]; then
                    echo "tips: no file with prefix '$selector'" >&2
                    if (( ${#selector} == 1 )); then
                        echo "  (hint: '${selector}x' selects the whole decade)" >&2
                    fi
                    return 1
                fi
                files=("$f")
                ;;
        esac
    fi

    # Dispatch.
    if (( list_mode )); then
        _tips_list "${files[@]}"
        return 0
    fi

    if [[ -n "$single_tip" ]]; then
        local section
        section=$(_tips_extract_one "$single_tip_file" "$single_tip")
        if [[ -z "$section" ]]; then
            echo "tips: tip $single_tip not found" >&2
            return 1
        fi
        _tips_render <(printf '%s\n' "$section")
        return 0
    fi

    _tips_render <(_tips_concat "${files[@]}")
}

# Print the file path whose leading numeric prefix matches the given id.
_tips_file_for() {
    local tips_dir="$1" file_id="$2"
    local f
    [[ -n "$ZSH_VERSION" ]] && setopt local_options null_glob
    for f in "$tips_dir"/${file_id}_*.md; do
        [[ -e "$f" ]] || continue
        echo "$f"
        return 0
    done
    return 1
}

# Print the leading numeric prefix from a tips file path.
_tips_prefix() {
    local base prefix
    base="${1##*/}"
    prefix="${base%%_*}"
    if [[ "$prefix" == "${prefix//[!0-9]/}" && -n "$prefix" ]]; then
        echo "$prefix"
    fi
}

# List titles across files, grouped by file H1.
_tips_list() {
    local f h1
    for f in "$@"; do
        h1=$(awk '/^# / { sub(/^# /, ""); print; exit }' "$f")
        echo "$h1"
        awk '
            /^## Tip [0-9]+\.[0-9]+:/ {
                sub(/^## Tip /, "")
                idx = index($0, ":")
                printf "  %s %s\n", substr($0, 1, idx - 1), substr($0, idx + 2)
                next
            }
            /^### Tip [0-9]+\.[0-9]+:/ {
                sub(/^### Tip /, "")
                idx = index($0, ":")
                printf "    %s %s\n", substr($0, 1, idx - 1), substr($0, idx + 2)
                next
            }
            /^## / {
                sub(/^## /, "")
                printf "  [%s]\n", $0
            }
        ' "$f"
        echo
    done
}

# Concatenate multiple tip files for full-content rendering.
_tips_concat() {
    local f first=1
    for f in "$@"; do
        if (( first )); then
            first=0
        else
            echo
            echo
        fi
        cat "$f"
    done
}

# Extract a single tip (## Tip <id>: ... or ### Tip <id>: ...) from a file.
# Tips are H2 in flat files and H3 in files that group tips under H2 group
# headers. Extraction stops at any heading at-or-above the target tip's level
# (so an H3 tip stops at the next H3 tip OR the next H2 group; an H2 tip
# stops at the next H2).
_tips_extract_one() {
    local file="$1" tip_id="$2"
    awk -v target_h2="## Tip $tip_id:" -v target_h3="### Tip $tip_id:" '
        function heading_level(line) {
            if (match(line, /^#+/)) return RLENGTH
            return 0
        }
        {
            level = heading_level($0)
        }
        !in_section && (index($0, target_h2) == 1 || index($0, target_h3) == 1) {
            target_level = level
            in_section = 1
            print
            next
        }
        in_section && level > 0 && level <= target_level {
            exit
        }
        in_section { print }
    ' "$file"
}

_tips_render() {
    if command -v glow >/dev/null 2>&1; then
        glow "$1"
    elif command -v bat >/dev/null 2>&1; then
        bat -l md --style=plain --paging=never "$1"
    else
        cat "$1"
    fi
}
