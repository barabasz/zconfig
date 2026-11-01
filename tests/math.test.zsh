# Tests for lib/math.zsh

## min / max (numeric, not lexical: audit bug #4)
assert_eq "$(min -2 -10 3)" -10 "min negative"
assert_eq "$(min 1.5 1.25)" 1.25 "min float"
assert_eq "$(max 2 10 3)" 10 "max"
assert_rc 2 min
assert_rc 2 min 1 abc

## sum / avg / median
assert_eq "$(sum 1 2 3)" 6 "sum"
assert_eq "$(median 3 1 2)" 2 "median odd"
assert_eq "$(median 4 1 2 3)" 2.5 "median even"

## mod is never negative
assert_eq "$(mod -7 3)" 2 "mod negative"
assert_rc 1 mod 1 0

## predicates validate input (audit bug #16)
assert_ok is_even 4
assert_fail is_even 3
assert_rc 2 is_even abc
assert_ok is_prime 97
assert_fail is_prime 91
assert_ok is_number -1.5
assert_fail is_number 1.2.3

## base conversions (audit bug #15)
assert_eq "$(dec2bin 5)" 0b101 "dec2bin"
assert_eq "$(dec2bin -5)" -0b101 "dec2bin negative"
assert_eq "$(hex2dec FF)" 255 "hex2dec uppercase"
assert_eq "$(bin2dec 1010)" 10 "bin2dec"
assert_eq "$(dec2oct 8)" 0o10 "dec2oct"
assert_eq "$(oct2dec 17)" 15 "oct2dec"

## rounding
assert_eq "$(round 2.5)" 3 "round half up"
assert_eq "$(round 3.14159 2)" 3.14 "round decimals"

## overflow and division guards
assert_rc 1 factorial 21
assert_rc 1 percent 1 0
assert_eq "$(lcm 0 0)" 0 "lcm zero"

## calc (renamed from zcalc so zsh's own zcalc is not shadowed)
assert_eq "$(calc '2 + 3 * 4')" 14 "calc"
assert_rc 1 calc '1 / 0'
assert_eq "${+functions[zcalc]}" 0 "zcalc not defined by lib"

## random stays within range and can exceed 15 bits
local -i i n big=0
for i in {1..50}; do
    n=$(random 1 100000)
    (( n >= 1 && n <= 100000 )) || assert_eq "$n" "in range" "random range"
    (( n > 32768 )) && big=1
done
assert_eq $big 1 "random above 32768"

## format_bytes
assert_eq "$(format_bytes 1536)" "1.50 KiB" "format_bytes"
