#!/usr/bin/env bash
source "$DOTFILES/test/helper.sh"

e_header "$(basename "$0" .sh)"

# Strings
function my_test() {
  setdiff "${desired[*]}" "${installed[*]}"
}

desired=(a b c); installed=(); assert "$(my_test)" "a b c"
desired=(a b c); installed=(a); assert "$(my_test)" "b c"
desired=(a b c); installed=(b); assert "$(my_test)" "a c"
desired=(a b c); installed=(c); assert "$(my_test)" "a b"
desired=(a b c); installed=(a b); assert "$(my_test)" "c"
desired=(a b c); installed=(c a); assert "$(my_test)" "b"
desired=(a a-b); installed=(a); assert "$(my_test)" "a-b"
desired=(a a-b); installed=(a-b); assert "$(my_test)" "a"
desired=(a a-b c); installed=(a-b); assert "$(my_test)" "a c"
desired=(a-b a); installed=(a); assert "$(my_test)" "a-b"
desired=(a-b a); installed=(a-b); assert "$(my_test)" "a"
desired=(a a-b); installed=(a-b a); assert "$(my_test)" ""
desired=(a-b a); installed=(a-b a); assert "$(my_test)" ""
desired=(a a-b); installed=(a a-b); assert "$(my_test)" ""
desired=(a-b a); installed=(a a-b); assert "$(my_test)" ""

# Arrays
unset setdiff_new setdiff_cur setdiff_out
setdiff "a b c" "" >/dev/null
assert "${#setdiff_out[@]}" "0"

unset setdiff_new setdiff_cur setdiff_out
setdiff_new=(a b c); setdiff_cur=(); setdiff
assert "${#setdiff_out[@]}" "3"
assert "${setdiff_out[0]}" "a"
assert "${setdiff_out[1]}" "b"
assert "${setdiff_out[2]}" "c"

unset setdiff_new setdiff_cur setdiff_out
setdiff_new=(a b c); setdiff_cur=(a); setdiff
assert "${#setdiff_out[@]}" "2"
assert "${setdiff_out[0]}" "b"
assert "${setdiff_out[1]}" "c"

unset setdiff_new setdiff_cur setdiff_out
setdiff_new=(a b c); setdiff_cur=(c a); setdiff
assert "${#setdiff_out[@]}" "1"
assert "${setdiff_out[0]}" "b"

unset setdiff_new setdiff_cur setdiff_out
setdiff_new=("a b" c); setdiff_cur=(a b c); setdiff
assert "${#setdiff_out[@]}" "1"
assert "${setdiff_out[0]}" "a b"

unset setdiff_new setdiff_cur setdiff_out
setdiff_new=(a b "a b" c "c d"); setdiff_cur=(a c); setdiff
assert "${#setdiff_out[@]}" "3"
assert "${setdiff_out[0]}" "b"
assert "${setdiff_out[1]}" "a b"
assert "${setdiff_out[2]}" "c d"

unset setdiff_new setdiff_cur setdiff_out
setdiff_new=(a b "a b" c "c d"); setdiff_cur=(b "c d"); setdiff
assert "${#setdiff_out[@]}" "3"
assert "${setdiff_out[0]}" "a"
assert "${setdiff_out[1]}" "a b"
assert "${setdiff_out[2]}" "c"

test_done
