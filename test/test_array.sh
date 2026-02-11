#!/usr/bin/env bash
source "$DOTFILES/test/helper.sh"

e_header "$(basename "$0" .sh)"

# Fixtures
empty=()
fixture1=(a b "" "c d" " e " "  'f'  " " \"g'h\" " i "")

# Tests
e_header array_map

IFS= read -rd '' actual < <(array_map empty)
expected=$''
assert "$actual" "$expected" "empty array"

IFS= read -rd '' actual < <(array_map fixture1)
expected=$'a\nb\n\nc d\n e \n  \'f\'  \n \"g\'h\" \ni\n\n'
assert "$actual" "$expected" "all items"

function map() { echo "<$2:${1:-X}>"; }
IFS= read -rd '' actual < <(array_map fixture1 map)
expected=$'<0:a>\n<1:b>\n<2:X>\n<3:c d>\n<4: e >\n<5:  \'f\'  >\n<6: \"g\'h\" >\n<7:i>\n<8:X>\n'
assert "$actual" "$expected" "with map_fn"

e_header array_print

IFS= read -rd '' actual < <(array_print empty)
expected=$''
assert "$actual" "$expected" "empty array"

IFS= read -rd '' actual < <(array_print fixture1)
expected=$'0 <a>\n1 <b>\n2 <>\n3 <c d>\n4 < e >\n5 <  \'f\'  >\n6 < \"g\'h\" >\n7 <i>\n8 <>\n'
assert "$actual" "$expected" "all items"


e_header array_filter

IFS= read -rd '' actual < <(array_filter empty)
expected=$''
assert "$actual" "$expected" "empty array"

IFS= read -rd '' actual < <(array_filter fixture1)
expected=$'a\nb\nc d\n e \n  \'f\'  \n \"g\'h\" \ni\n'
assert "$actual" "$expected" "remove empty"

function filter() { [[ "$1" && ! "$1" =~ [[:space:]] ]]; }
IFS= read -rd '' actual < <(array_filter fixture1 filter)
expected=$'a\nb\ni\n'
assert "$actual" "$expected" "no-space filter"

function filter() { [[ "$1" && "$1" =~ [[:space:]] ]]; }
IFS= read -rd '' actual < <(array_filter fixture1 filter)
expected=$'c d\n e \n  \'f\'  \n \"g\'h\" \n'
assert "$actual" "$expected" "has-space filter"

function filter() { [[ $(($2 % 2)) == 0 ]]; }
IFS= read -rd '' actual < <(array_filter fixture1 filter)
expected=$'a\n\n e \n \"g\'h\" \n\n'
assert "$actual" "$expected" "even-index filter"

function filter() { [[ $(($2 % 2)) == 1 ]]; }
IFS= read -rd '' actual < <(array_filter fixture1 filter)
expected=$'b\nc d\n  \'f\'  \ni\n'
assert "$actual" "$expected" "odd-index filter"


e_header array_filter_i

IFS= read -rd '' actual < <(array_filter_i empty)
expected=$''
assert "$actual" "$expected" "empty array"

IFS= read -rd '' actual < <(array_filter_i fixture1)
expected=$'0\n1\n3\n4\n5\n6\n7\n'
assert "$actual" "$expected" "non-empty indices"

function filter() { [[ "$1" && ! "$1" =~ [[:space:]] ]]; }
IFS= read -rd '' actual < <(array_filter_i fixture1 filter)
expected=$'0\n1\n7\n'
assert "$actual" "$expected" "no-space indices"

function filter() { [[ "$1" && "$1" =~ [[:space:]] ]]; }
IFS= read -rd '' actual < <(array_filter_i fixture1 filter)
expected=$'3\n4\n5\n6\n'
assert "$actual" "$expected" "has-space indices"

function filter() { [[ $(($2 % 2)) == 0 ]]; }
IFS= read -rd '' actual < <(array_filter_i fixture1 filter)
expected=$'0\n2\n4\n6\n8\n'
assert "$actual" "$expected" "even indices"

function filter() { [[ $(($2 % 2)) == 1 ]]; }
IFS= read -rd '' actual < <(array_filter_i fixture1 filter)
expected=$'1\n3\n5\n7\n'
assert "$actual" "$expected" "odd indices"


e_header array_join

IFS= read -rd '' actual < <(array_join empty ',')
expected=$''
assert "$actual" "$expected" "empty array"

IFS= read -rd '' actual < <(array_join fixture1 ',')
expected=$'a,b,,c d, e ,  \'f\'  , \"g\'h\" ,i,\n'
assert "$actual" "$expected" "comma separator"

IFS= read -rd '' actual < <(array_join fixture1 ', ')
expected=$'a, b, , c d,  e ,   \'f\'  ,  \"g\'h\" , i, \n'
assert "$actual" "$expected" "comma-space separator"


e_header array_join_filter

IFS= read -rd '' actual < <(array_join_filter empty ',')
expected=$''
assert "$actual" "$expected" "empty array"

IFS= read -rd '' actual < <(array_join_filter fixture1 ',')
expected=$'a,b,c d, e ,  \'f\'  , \"g\'h\" ,i\n'
assert "$actual" "$expected" "comma separator"

IFS= read -rd '' actual < <(array_join_filter fixture1 ', ')
expected=$'a, b, c d,  e ,   \'f\'  ,  \"g\'h\" , i\n'
assert "$actual" "$expected" "comma-space separator"

test_done
