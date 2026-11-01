# Tests for lib/arrays.zsh

local -a arr=(b a c a)

## queries
assert_ok array_contains arr a
assert_fail array_contains arr z
assert_eq "$(array_count arr a)" 2 "array_count"
assert_eq "$(array_length arr)" 4 "array_length"
assert_eq "$(array_first arr)" b "array_first"
assert_eq "$(array_last arr)" a "array_last"

## numeric sort and min/max
local -a nums=(10 9 100 -3) sorted
array_sort -n nums sorted
assert_eq "${sorted[*]}" "-3 9 10 100" "array_sort -n"
array_sort nums sorted
assert_eq "${sorted[*]}" "-3 10 100 9" "array_sort lexicographic"
assert_eq "$(array_min nums)" -3 "array_min"
assert_eq "$(array_max nums)" 100 "array_max"

## modification without eval; caller arrays named like internals are safe
local -a src=(1 2 3)
array_push src 4
assert_eq "${src[*]}" "1 2 3 4" "array_push on 'src'"
array_unshift src 0
assert_eq "${src[*]}" "0 1 2 3 4" "array_unshift"
array_pop src >/dev/null
assert_eq "$REPLY" 4 "array_pop REPLY"
array_insert_at src 2 x
assert_eq "${src[*]}" "0 x 1 2 3" "array_insert_at"
array_remove_at src 2
assert_eq "${src[*]}" "0 1 2 3" "array_remove_at"

## invalid usage returns 2 (audit bug #14); bad names are rejected
assert_rc 2 array_unshift
assert_rc 2 array_push 'x;rm -rf /' 1
assert_rc 2 array_push '1abc' 1

## set operations
local -a a1=(1 2 3) a2=(2 3 4) res
array_intersect a1 a2 res
assert_eq "${res[*]}" "2 3" "intersect"
array_diff a1 a2 res
assert_eq "${res[*]}" "1" "diff"
array_zip a1 a2 res
assert_eq "${res[*]}" "1 2 2 3 3 4" "zip"
