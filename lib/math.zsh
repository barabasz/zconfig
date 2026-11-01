#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# Math helper functions
# Depends on: strings.zsh (is_numeric, is_integer), zsh/mathfunc, zsh/random (optional),
#             zsh/datetime and zsh/system (reseeding $RANDOM in subshells)
# All functions print the result and also set REPLY. Numeric arguments are
# validated, so non-numbers are rejected with exit code 2 (invalid usage).
##

# Check that all arguments are numbers (internal)
# Usage: _math_args_ok <arg> [arg...]
# Returns: 0 all numeric, 1 otherwise
_math_args_ok() {
    local n
    for n in "$@"; do
        [[ "$n" =~ '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$' ]] || return 1
    done
    return 0
}

# Check that all arguments are integers (internal)
# Usage: _math_int_ok <arg> [arg...]
# Returns: 0 all integers, 1 otherwise
_math_int_ok() {
    local n
    for n in "$@"; do
        [[ "$n" =~ '^[+-]?[0-9]+$' ]] || return 1
    done
    return 0
}

# Set REPLY and print it (internal)
# Usage: _math_out <value>
_math_out() {
    REPLY="$1"
    print -r -- "$REPLY"
}

## Basic operations

# Evaluate mathematical expression and print result
# (named calc, so it does not shadow zsh's interactive zcalc)
# Usage: calc <expression...>
# Example: calc 2 + 2 -> 4, calc "sqrt(16)" -> 4.
# Output: result (stdout); also sets REPLY
# Returns: 0 success, 1 evaluation error, 2 invalid usage
calc() {
    (( ARGC >= 1 )) || return 2
    local expr="${(j: :)argv}"
    local result
    # A math error is fatal for the current command, so evaluate in a subshell
    result=$( { print -r -- $(( ${expr} )) } 2>/dev/null )
    [[ -n $result ]] || return 1
    _math_out "$result"
}

# Get minimum of numbers (integers or decimals, negative allowed)
# Usage: min <number> [number...]
# Example: min 5 -3 8 1.5 -> -3
# Output: minimum (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
min() {
    (( ARGC >= 1 )) && _math_args_ok "$@" || return 2
    local v m=$1
    for v in "$@"; do (( v < m )) && m=$v; done
    _math_out "$m"
}

# Get maximum of numbers (integers or decimals, negative allowed)
# Usage: max <number> [number...]
# Example: max 5 -3 8 1.5 -> 8
# Output: maximum (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
max() {
    (( ARGC >= 1 )) && _math_args_ok "$@" || return 2
    local v m=$1
    for v in "$@"; do (( v > m )) && m=$v; done
    _math_out "$m"
}

# Calculate sum of numbers
# Usage: sum <number> [number...]
# Example: sum 1 2 3 4 5 -> 15
# Output: sum (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
sum() {
    (( ARGC >= 1 )) && _math_args_ok "$@" || return 2
    local total=0 num
    for num in "$@"; do
        (( total += num ))
    done
    _math_out "$total"
}

# Calculate average (mean) of numbers, integer division
# Usage: avg <number> [number...]
# Example: avg 1 2 3 4 5 -> 3
# Output: average (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
avg() {
    (( ARGC >= 1 )) && _math_int_ok "$@" || return 2
    local -i total=0 num
    for num in "$@"; do
        (( total += num ))
    done
    _math_out $(( total / ARGC ))
}

# Calculate average (mean) of numbers with 2 decimal places
# Usage: avgf <number> [number...]
# Example: avgf 1 2 3 4 -> 2.50
# Output: average (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
avgf() {
    (( ARGC >= 1 )) && _math_args_ok "$@" || return 2
    local -F total=0
    local num
    for num in "$@"; do
        (( total += num ))
    done
    local out
    LC_NUMERIC=C printf -v out "%.2f" $(( total / ARGC ))
    _math_out "$out"
}

# Calculate median of numbers
# Usage: median <number> [number...]
# Example: median 3 1 2 -> 2, median 1 2 3 4 -> 2.5
# Output: median (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
median() {
    (( ARGC >= 1 )) && _math_args_ok "$@" || return 2
    # Insertion sort with arithmetic comparison (works for decimals and negatives)
    local -a sorted=()
    local v
    local -i i
    for v in "$@"; do
        for (( i = 1; i <= ${#sorted}; i++ )); do
            (( v < sorted[i] )) && break
        done
        sorted[i,i-1]=($v)
    done
    local -i n=${#sorted}
    if (( n % 2 )); then
        _math_out "${sorted[n/2+1]}"
    else
        local out
        # %g prints integers without a decimal part (2.0 -> 2, 2.5 -> 2.5)
        LC_NUMERIC=C printf -v out "%g" $(( (sorted[n/2] + sorted[n/2+1]) / 2.0 ))
        _math_out "$out"
    fi
}

# Get absolute value
# Usage: abs <number>
# Example: abs -5 -> 5
# Output: absolute value (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
abs() {
    (( ARGC == 1 )) && _math_args_ok "$1" || return 2
    _math_out "${1#[-+]}"
}

# Calculate power
# Usage: pow <base> <exponent>
# Example: pow 2 8 -> 256
# Output: result (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
pow() {
    (( ARGC == 2 )) && _math_args_ok "$@" || return 2
    _math_out $(( $1 ** $2 ))
}

# Calculate square root
# Usage: sqrt <number>
# Example: sqrt 16 -> 4, sqrt 2 -> 1.414214
# Output: result (stdout); also sets REPLY
# Returns: 0 success, 1 negative number, 2 invalid usage
sqrt() {
    (( ARGC == 1 )) && _math_args_ok "$1" || return 2
    (( $1 >= 0 )) || return 1
    local -F result=$(( sqrt($1) ))
    if (( result == int(result) )); then
        _math_out $(( int(result) ))
    else
        local out
        LC_NUMERIC=C printf -v out "%.6f" $result
        _math_out "$out"
    fi
}

# Positive modulo (result always has the sign of the divisor, like Python)
# Usage: mod <dividend> <divisor>
# Example: mod -7 3 -> 2 (while $(( -7 % 3 )) gives -1)
# Output: result (stdout); also sets REPLY
# Returns: 0 success, 1 division by zero, 2 invalid usage
mod() {
    (( ARGC == 2 )) && _math_int_ok "$@" || return 2
    (( $2 != 0 )) || return 1
    _math_out $(( (($1 % $2) + $2) % $2 ))
}

# Generate random integer between min and max (inclusive)
# Uses zsh/random (zrand_int, 32-bit, unbiased) when available; otherwise a
# 30-bit value from two $RANDOM calls with rejection sampling (no modulo bias).
# Note: not cryptographically secure.
# Usage: random <min> <max>
# Example: random 1 100
# Output: random number (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
random() {
    (( ARGC == 2 )) && _math_int_ok "$@" || return 2
    local -i lo=$1 hi=$2 range r limit
    (( lo > hi )) && (( r = lo, lo = hi, hi = r ))
    (( range = hi - lo + 1 ))

    if zmodload -e zsh/random; then
        _math_out $(( zrand_int(hi, lo, 1) ))
        return
    fi

    # Subshells, e.g. $(random 1 6), inherit the parent's RANDOM state and would
    # repeat the same values; reseed from the clock and the real process id
    if (( ZSH_SUBSHELL )); then
        local usec=${EPOCHREALTIME#*.}
        RANDOM=$(( 10#${usec:-0} ^ ${sysparams[pid]:-$$} ))
    fi
    # 30-bit generator: values >= largest multiple of range are rejected (no modulo bias)
    (( limit = (1 << 30) - ((1 << 30) % range) ))
    while true; do
        (( r = (RANDOM << 15) | RANDOM ))
        (( r < limit )) && break
    done
    _math_out $(( lo + r % range ))
}

## Number properties and checks

# Check if number is even
# Usage: is_even <integer>
# Returns: 0 true, 1 false, 2 invalid usage
is_even() {
    (( ARGC == 1 )) && _math_int_ok "$1" || return 2
    (( $1 % 2 == 0 ))
}

# Check if number is odd
# Usage: is_odd <integer>
# Returns: 0 true, 1 false, 2 invalid usage
is_odd() {
    (( ARGC == 1 )) && _math_int_ok "$1" || return 2
    (( $1 % 2 != 0 ))
}

# Check if number is positive (> 0)
# Usage: is_positive <number>
# Returns: 0 true, 1 false, 2 invalid usage
is_positive() {
    (( ARGC == 1 )) && _math_args_ok "$1" || return 2
    (( $1 > 0 ))
}

# Check if number is negative (< 0)
# Usage: is_negative <number>
# Returns: 0 true, 1 false, 2 invalid usage
is_negative() {
    (( ARGC == 1 )) && _math_args_ok "$1" || return 2
    (( $1 < 0 ))
}

# Check if number is zero
# Usage: is_zero <number>
# Returns: 0 true, 1 false, 2 invalid usage
is_zero() {
    (( ARGC == 1 )) && _math_args_ok "$1" || return 2
    (( $1 == 0 ))
}

# Check if argument is a valid number (alias for is_numeric from strings.zsh)
# Usage: is_number <text>
# Returns: 0 true, 1 false, 2 invalid usage
is_number() {
    (( ARGC == 1 )) || return 2
    _math_args_ok "$1"
}

# Check if number is prime
# Usage: is_prime <integer>
# Returns: 0 true, 1 false, 2 invalid usage
is_prime() {
    (( ARGC == 1 )) && _math_int_ok "$1" || return 2
    local -i n=$1 i
    (( n < 2 )) && return 1
    (( n < 4 )) && return 0
    (( n % 2 == 0 || n % 3 == 0 )) && return 1
    for (( i = 5; i * i <= n; i += 6 )); do
        (( n % i == 0 || n % (i + 2) == 0 )) && return 1
    done
    return 0
}

# Check if number is in range (inclusive)
# Usage: in_range <number> <min> <max>
# Example: in_range 5 1 10 -> 0 (true)
# Returns: 0 true, 1 false, 2 invalid usage
in_range() {
    (( ARGC == 3 )) && _math_args_ok "$@" || return 2
    (( $1 >= $2 && $1 <= $3 ))
}

## Rounding and integer arithmetic

# Round number to nearest value, halves away from zero (2.5 -> 3, -2.5 -> -3)
# Usage: round <number> [decimals]
# Example: round 3.7 -> 4, round 3.14159 2 -> 3.14
# Output: result (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
round() {
    (( ARGC >= 1 && ARGC <= 2 )) && _math_args_ok "$1" && [[ ${2:-0} == <-> ]] || return 2
    local -i decimals=${2:-0}
    local -F factor=$(( 10.0 ** decimals ))
    local -F scaled=$(( $1 * factor ))
    # Round half away from zero (rint() would round half to even)
    if (( scaled >= 0 )); then
        (( scaled = floor(scaled + 0.5) ))
    else
        (( scaled = ceil(scaled - 0.5) ))
    fi
    if (( decimals == 0 )); then
        _math_out $(( int(scaled) ))
    else
        local out
        LC_NUMERIC=C printf -v out "%.${decimals}f" $(( scaled / factor ))
        _math_out "$out"
    fi
}

# Round number up (ceiling)
# Usage: ceil <number>
# Example: ceil 3.1 -> 4
# Output: integer (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
ceil() {
    (( ARGC == 1 )) && _math_args_ok "$1" || return 2
    _math_out $(( int(ceil($1)) ))
}

# Round number down (floor)
# Usage: floor <number>
# Example: floor 3.9 -> 3
# Output: integer (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
floor() {
    (( ARGC == 1 )) && _math_args_ok "$1" || return 2
    _math_out $(( int(floor($1)) ))
}

# Calculate factorial (64-bit integers: 0..20)
# Usage: factorial <n>
# Example: factorial 5 -> 120
# Output: integer (stdout); also sets REPLY
# Returns: 0 success, 1 overflow (n > 20), 2 invalid usage
factorial() {
    (( ARGC == 1 )) && [[ $1 == <-> ]] || return 2
    local -i num=$1 result=1 i
    (( num <= 20 )) || return 1
    for (( i = 2; i <= num; i++ )); do
        (( result *= i ))
    done
    _math_out $result
}

# Calculate GCD (Greatest Common Divisor)
# Usage: gcd <a> <b>
# Example: gcd 48 18 -> 6
# Output: integer (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
gcd() {
    (( ARGC == 2 )) && _math_int_ok "$@" || return 2
    local -i a=${1#[-+]} b=${2#[-+]} temp
    while (( b != 0 )); do
        (( temp = b, b = a % b, a = temp ))
    done
    _math_out $a
}

# Calculate LCM (Least Common Multiple)
# Usage: lcm <a> <b>
# Example: lcm 12 18 -> 36
# Output: integer (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
lcm() {
    (( ARGC == 2 )) && _math_int_ok "$@" || return 2
    local -i a=${1#[-+]} b=${2#[-+]}
    (( a == 0 || b == 0 )) && { _math_out 0; return 0 }
    gcd $a $b >/dev/null
    _math_out $(( a / REPLY * b ))
}

# Clamp number to range
# Usage: clamp <number> <min> <max>
# Example: clamp 15 0 10 -> 10
# Output: number (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
clamp() {
    (( ARGC == 3 )) && _math_args_ok "$@" || return 2
    if (( $1 < $2 )); then
        _math_out "$2"
    elif (( $1 > $3 )); then
        _math_out "$3"
    else
        _math_out "$1"
    fi
}

# Calculate percentage
# Usage: percent <part> <total>
# Example: percent 25 200 -> 12.50
# Output: percentage with 2 decimals (stdout); also sets REPLY
# Returns: 0 success, 1 division by zero, 2 invalid usage
percent() {
    (( ARGC == 2 )) && _math_args_ok "$@" || return 2
    (( $2 != 0 )) || return 1
    local out
    LC_NUMERIC=C printf -v out "%.2f" $(( $1 * 100.0 / $2 ))
    _math_out "$out"
}

## Base conversions

# Convert decimal to hexadecimal
# Usage: dec2hex <integer>
# Example: dec2hex 255 -> 0xFF, dec2hex -255 -> -0xFF
# Output: string (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
dec2hex() {
    (( ARGC == 1 )) && _math_int_ok "$1" || return 2
    # [##16] prints the number in base 16 without the "16#" prefix
    local hex=$(( [##16] ${1#+} ))
    [[ $hex == -* ]] && _math_out "-0x${hex#-}" || _math_out "0x$hex"
}

# Convert hexadecimal to decimal (with or without 0x prefix)
# Usage: hex2dec <hex>
# Example: hex2dec 0xFF -> 255, hex2dec ff -> 255
# Output: integer (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
hex2dec() {
    (( ARGC == 1 )) || return 2
    local hex=${1#0[xX]}
    [[ $hex =~ '^[[:xdigit:]]+$' ]] || return 2
    _math_out $(( 16#$hex ))
}

# Convert decimal to binary
# Usage: dec2bin <integer>
# Example: dec2bin 10 -> 0b1010, dec2bin -5 -> -0b101
# Output: string (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
dec2bin() {
    (( ARGC == 1 )) && _math_int_ok "$1" || return 2
    local bin=$(( [##2] ${1#+} ))
    [[ $bin == -* ]] && _math_out "-0b${bin#-}" || _math_out "0b$bin"
}

# Convert binary to decimal (with or without 0b prefix)
# Usage: bin2dec <binary>
# Example: bin2dec 0b1010 -> 10
# Output: integer (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
bin2dec() {
    (( ARGC == 1 )) || return 2
    local bin=${1#0[bB]}
    [[ $bin =~ '^[01]+$' ]] || return 2
    _math_out $(( 2#$bin ))
}

# Convert decimal to octal
# Usage: dec2oct <integer>
# Example: dec2oct 8 -> 0o10
# Output: string (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
dec2oct() {
    (( ARGC == 1 )) && _math_int_ok "$1" || return 2
    local oct=$(( [##8] ${1#+} ))
    [[ $oct == -* ]] && _math_out "-0o${oct#-}" || _math_out "0o$oct"
}

# Convert octal to decimal (with or without 0o / 0 prefix)
# Usage: oct2dec <octal>
# Example: oct2dec 0o755 -> 493, oct2dec 755 -> 493
# Output: integer (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
oct2dec() {
    (( ARGC == 1 )) || return 2
    local oct=${1#0[oO]}
    [[ $oct =~ '^[0-7]+$' ]] || return 2
    _math_out $(( 8#$oct ))
}

## Trigonometry and sequences

# Convert degrees to radians
# Usage: deg2rad <degrees>
# Example: deg2rad 180 -> 3.14159265
# Output: float with 8 decimals (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
deg2rad() {
    (( ARGC == 1 )) && _math_args_ok "$1" || return 2
    local out
    LC_NUMERIC=C printf -v out "%.8f" $(( $1 * (4 * atan(1.0)) / 180.0 ))
    _math_out "$out"
}

# Convert radians to degrees
# Usage: rad2deg <radians>
# Example: rad2deg 3.14159265 -> 179.99999979
# Output: float with 8 decimals (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
rad2deg() {
    (( ARGC == 1 )) && _math_args_ok "$1" || return 2
    local out
    LC_NUMERIC=C printf -v out "%.8f" $(( $1 * 180.0 / (4 * atan(1.0)) ))
    _math_out "$out"
}

# Calculate fibonacci number at position n (64-bit integers: 0..92)
# Usage: fibonacci <n>
# Example: fibonacci 10 -> 55
# Output: integer (stdout); also sets REPLY
# Returns: 0 success, 1 overflow (n > 92), 2 invalid usage
fibonacci() {
    (( ARGC == 1 )) && [[ $1 == <-> ]] || return 2
    local -i n=$1 a=0 b=1 temp i
    (( n <= 92 )) || return 1
    (( n == 0 )) && { _math_out 0; return 0 }
    for (( i = 2; i <= n; i++ )); do
        (( temp = b, b = a + b, a = temp ))
    done
    _math_out $b
}

## Formatting

# Format bytes into human readable size (IEC units, base 1024)
# Usage: format_bytes <bytes>
# Example: format_bytes 1048576 -> "1.00 MiB"
# Output: string (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
format_bytes() {
    (( ARGC == 1 )) && _math_args_ok "$1" || return 2
    local -F bytes=$1
    local -a units=(B KiB MiB GiB TiB PiB EiB)
    local -i i=1
    local out

    while (( bytes >= 1024 && i < ${#units} )); do
        (( bytes /= 1024.0 ))
        (( i++ ))
    done

    if (( i == 1 )); then
        LC_NUMERIC=C printf -v out "%.0f %s" $bytes $units[i]
    else
        LC_NUMERIC=C printf -v out "%.2f %s" $bytes $units[i]
    fi
    _math_out "$out"
}

# Format number with SI metric prefixes (k, M, G, T, P, E), base 1000
# Usage: format_metric <number>
# Example: format_metric 1500 -> "1.50 k"
# Output: string (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
format_metric() {
    (( ARGC == 1 )) && _math_args_ok "$1" || return 2
    local -F val=$1
    local -a units=("" k M G T P E)
    local -i i=1
    local out

    while (( val >= 1000 && i < ${#units} )); do
        (( val /= 1000.0 ))
        (( i++ ))
    done

    LC_NUMERIC=C printf -v out "%.2f %s" $val $units[i]
    _math_out "${out% }"
}

# Shell files tracking - keep at the end
zfile_track_end ${0:A}
