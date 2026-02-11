#!/usr/bin/env bash
source "$DOTFILES/test/helper.sh"

e_header "$(basename "$0" .sh)"

saved_path="$PATH"

PATH=/a/b:/a/b/c:/a/b:/a/b/d
r1="$(path_remove /a)"
r2="$(path_remove /a/b/c/d)"
r3="$(path_remove /a/b)"
r4="$(path_remove /a/b/c)"
r5="$(path_remove /a/b/d)"

PATH="/a/b:/a/b c/d:/a/b:/a/b c/e"
r6="$(path_remove /a)"
r7="$(path_remove /a/b/c/d)"
r8="$(path_remove /a/b)"
r9="$(path_remove "/a/b c/d")"
r10="$(path_remove "/a/b c/e")"

PATH=/a/b:/a/b/c:/x:/a/b/d:/y:/a/b/e:/z
r11="$(path_remove /a/b/c /a/b/d /a/b/e)"

PATH="$saved_path"

assert "$r1" "/a/b:/a/b/c:/a/b:/a/b/d" "non-matching path unchanged"
assert "$r2" "/a/b:/a/b/c:/a/b:/a/b/d" "non-existent path unchanged"
assert "$r3" "/a/b/c:/a/b/d" "remove duplicates"
assert "$r4" "/a/b:/a/b:/a/b/d" "remove middle"
assert "$r5" "/a/b:/a/b/c:/a/b" "remove last"

assert "$r6" "/a/b:/a/b c/d:/a/b:/a/b c/e" "spaces: non-matching unchanged"
assert "$r7" "/a/b:/a/b c/d:/a/b:/a/b c/e" "spaces: non-existent unchanged"
assert "$r8" "/a/b c/d:/a/b c/e" "spaces: remove non-spaced"
assert "$r9" "/a/b:/a/b:/a/b c/e" "spaces: remove spaced"
assert "$r10" "/a/b:/a/b c/d:/a/b" "spaces: remove last spaced"

assert "$r11" "/a/b:/x:/y:/z" "remove multiple at once"

test_done
