#!/usr/bin/env bash
source "$DOTFILES/test/helper.sh"

e_header "$(basename "$0" .sh)"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

printf 'line1\n' > "$tmp/dest"
printf 'line1\n' > "$tmp/same"
printf 'line1\nline2\n' > "$tmp/longer"
printf 'line2\n' > "$tmp/other"
touch -t 202001010000 "$tmp/dest"

assert "$(copy_test "$tmp/same" "$tmp/dest")" "same file" "identical contents are skipped"
assert "$(copy_test "$tmp/other" "$tmp/dest")" "" "different contents are copied"
# cmp reports a prefix match only on stderr, which once made these look identical.
assert "$(copy_test "$tmp/longer" "$tmp/dest")" "" "a source that extends the destination is copied"
assert "$(copy_test "$tmp/dest" "$tmp/longer")" "destination file newer" \
  "a destination that extends an older source is kept"
assert "$(copy_test "$tmp/same" "$tmp/missing")" "" "a missing destination is copied"

test_done
