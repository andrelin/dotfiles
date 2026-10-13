# Node.js versions through fnm, by the same rule as the JDKs in 31_homebrew_recipes.sh: the two latest LTS lines
# plus the latest release. When the latest release is itself an LTS, keep three LTS lines until the next one ships.
# Each line moves to its newest patch, and the newest LTS becomes the default that new shells start with.
# The patch this script installed for each line is recorded, and only that one is removed when the line moves on,
# so one installed by hand (say for an exact .nvmrc pin) stays. The first run has no record and adopts each line's
# highest installed patch, even a hand-installed one, since nothing tells the two apart.
# Lines that drop out of the rule stay installed, like an old openjdk@ formula; `fnm uninstall` removes one.

[[ ! "$(type -P fnm)" ]] && e_arrow "fnm not found — skipping Node versions. It comes from 31_homebrew_recipes.sh." && return 0

remote="$(fnm list-remote)" || { e_error "Couldn't fetch the Node.js release list."; return 1; }

# fnm lists every release in ascending order as `v24.21.0`, with ` (Codename)` appended on LTS releases.
_node_major() { sed -E 's/^v([0-9]+)\..*/\1/'; }
lts_majors=()
while read -r major; do lts_majors+=("$major"); done < <(grep '(' <<< "$remote" | _node_major | uniq)
latest_major="$(tail -n 1 <<< "$remote" | _node_major)"

n=${#lts_majors[@]}
newest_lts=${lts_majors[n-1]}
if [[ "$latest_major" == "$newest_lts" ]]; then
  majors=("${lts_majors[@]:n-3}")
else
  majors=("${lts_majors[@]:n-2}" "$latest_major")
fi

managed_file="$DOTFILES/caches/node/managed"
[[ -f "$managed_file" ]] && first_run= || first_run=1
managed_before="$(cat "$managed_file" 2> /dev/null)"
installed="$(fnm list | sed -nE 's/^\* (v[0-9.]+).*/\1/p')"
default_version="$(fnm list | sed -nE 's/^\* (v[0-9.]+).* default.*/\1/p')"

replaced=()
managed=()
for major in "${majors[@]}"; do
  newest="$(grep -E "^v$major\." <<< "$remote" | tail -n 1 | cut -d ' ' -f 1)"
  previous="$(grep -E "^v$major\." <<< "$managed_before")"
  # Adopted on the first run: the line's highest installed patch, as fnm lists versions in ascending order.
  [[ -n "$first_run" ]] && previous="$(grep -E "^v$major\." <<< "$installed" | tail -n 1)"
  if ! grep -qx "$newest" <<< "$installed"; then
    e_header "Installing Node $newest"
    if fnm install "$newest"; then
      managed+=("$newest")
      [[ -n "$previous" ]] && grep -qx "$previous" <<< "$installed" && replaced+=("$previous")
    else
      # Keep the record, so the patch still in use is replaced once an install succeeds, and keep the default on it.
      [[ -n "$previous" ]] && managed+=("$previous")
      [[ "$major" == "$newest_lts" ]] && newest_lts_version="$previous"
      continue
    fi
  elif [[ "$newest" == "$previous" ]]; then
    managed+=("$newest")
  elif [[ -n "$previous" ]]; then
    # The newest patch was installed by hand: it stays unmanaged, and the record keeps the script's own patch.
    managed+=("$previous")
  fi
  [[ "$major" == "$newest_lts" ]] && newest_lts_version="$newest"
done
mkdir -p "${managed_file%/*}"
printf '%s\n' "${managed[@]}" > "$managed_file"

if [[ -n "$newest_lts_version" && "$default_version" != "$newest_lts_version" ]]; then
  e_success "Setting the default Node to $newest_lts_version."
  fnm default "$newest_lts_version"
fi

# Remove replaced patches only now, and never the default: after a failed install, it can be one of them.
[[ -n "$newest_lts_version" ]] && default_version="$newest_lts_version"
for version in "${replaced[@]}"; do
  [[ "$version" == "$default_version" ]] && continue
  e_arrow "Removing Node $version, replaced by a newer patch."
  fnm uninstall "$version"
done

unset -f _node_major
unset remote lts_majors latest_major n newest_lts majors managed_file first_run managed_before managed installed default_version major newest previous replaced \
  newest_lts_version version
