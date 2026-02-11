#!/usr/bin/env bash
source "$DOTFILES/test/helper.sh"

e_header "$(basename "$0" .sh)"

# Strings
function my_test() {
  setdiff "${desired[*]}" "${installed[*]}"
}

desired=(a b c); installed=(); assert "$(my_test)" "a b c" "none installed"
desired=(a b c); installed=(a); assert "$(my_test)" "b c" "first installed"
desired=(a b c); installed=(b); assert "$(my_test)" "a c" "middle installed"
desired=(a b c); installed=(c); assert "$(my_test)" "a b" "last installed"
desired=(a b c); installed=(a b); assert "$(my_test)" "c" "first two installed"
desired=(a b c); installed=(c a); assert "$(my_test)" "b" "first+last installed"
desired=(a a-b); installed=(a); assert "$(my_test)" "a-b" "prefix match only"
desired=(a a-b); installed=(a-b); assert "$(my_test)" "a" "hyphenated installed"
desired=(a a-b c); installed=(a-b); assert "$(my_test)" "a c" "hyphenated in middle"
desired=(a-b a); installed=(a); assert "$(my_test)" "a-b" "prefix match reversed"
desired=(a-b a); installed=(a-b); assert "$(my_test)" "a" "hyphenated first"
desired=(a a-b); installed=(a-b a); assert "$(my_test)" "" "all installed"
desired=(a-b a); installed=(a-b a); assert "$(my_test)" "" "all installed reversed"
desired=(a a-b); installed=(a a-b); assert "$(my_test)" "" "all installed same order"
desired=(a-b a); installed=(a a-b); assert "$(my_test)" "" "all installed cross order"

# Arrays
unset setdiff_new setdiff_cur setdiff_out
setdiff "a b c" "" >/dev/null
assert "${#setdiff_out[@]}" "0" "string mode: no output array"

unset setdiff_new setdiff_cur setdiff_out
setdiff_new=(a b c); setdiff_cur=(); setdiff
assert "${#setdiff_out[@]}" "3" "array: all new count"
assert "${setdiff_out[0]}" "a" "array: all new [0]"
assert "${setdiff_out[1]}" "b" "array: all new [1]"
assert "${setdiff_out[2]}" "c" "array: all new [2]"

unset setdiff_new setdiff_cur setdiff_out
setdiff_new=(a b c); setdiff_cur=(a); setdiff
assert "${#setdiff_out[@]}" "2" "array: one cur count"
assert "${setdiff_out[0]}" "b" "array: one cur [0]"
assert "${setdiff_out[1]}" "c" "array: one cur [1]"

unset setdiff_new setdiff_cur setdiff_out
setdiff_new=(a b c); setdiff_cur=(c a); setdiff
assert "${#setdiff_out[@]}" "1" "array: two cur count"
assert "${setdiff_out[0]}" "b" "array: two cur [0]"

unset setdiff_new setdiff_cur setdiff_out
setdiff_new=("a b" c); setdiff_cur=(a b c); setdiff
assert "${#setdiff_out[@]}" "1" "array: quoted space count"
assert "${setdiff_out[0]}" "a b" "array: quoted space [0]"

unset setdiff_new setdiff_cur setdiff_out
setdiff_new=(a b "a b" c "c d"); setdiff_cur=(a c); setdiff
assert "${#setdiff_out[@]}" "3" "array: mixed spaces count"
assert "${setdiff_out[0]}" "b" "array: mixed spaces [0]"
assert "${setdiff_out[1]}" "a b" "array: mixed spaces [1]"
assert "${setdiff_out[2]}" "c d" "array: mixed spaces [2]"

unset setdiff_new setdiff_cur setdiff_out
setdiff_new=(a b "a b" c "c d"); setdiff_cur=(b "c d"); setdiff
assert "${#setdiff_out[@]}" "3" "array: quoted cur count"
assert "${setdiff_out[0]}" "a" "array: quoted cur [0]"
assert "${setdiff_out[1]}" "a b" "array: quoted cur [1]"
assert "${setdiff_out[2]}" "c" "array: quoted cur [2]"

test_done
