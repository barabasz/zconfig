#!/bin/zsh
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# --- Basic Math Operations ---

# Evaluate mathematical expression and print result
# Usage: zcalc 2 + 2      -> 4
#        zcalc "sqrt(16)" -> 4.0
zcalc() {
    (( ARGC >= 1 )) || return 1
    # Check if arguments need joining. Using arithmetic expansion directly.
    print -- $(( $* ))
}

# Get minimum of two or more numbers
# Usage: min 5 3 8 1
# Returns: 1
min() {
    (( ARGC >= 1 )) || return 1
    # Sort arguments numerically (n) and print the first element
    print -- ${${(n)argv}[1]}
}

# Get maximum of two or more numbers
# Usage: max 5 3 8 1
# Returns: 8
max() {
    (( ARGC >= 1 )) || return 1
    # Sort arguments numerically (n) and print the last element
    print -- ${${(n)argv}[-1]}
}

# Calculate sum of numbers
# Usage: sum 1 2 3 4 5
# Returns: 15
sum() {
    (( ARGC >= 1 )) || return 1
    local total=0
    local num
    
    for num in $argv; do
        (( total += num ))
    done
    print -- $total
}

# Calculate average (mean) of numbers (integer)
# Usage: avg 1 2 3 4 5
# Returns: 3
avg() {
    (( ARGC >= 1 )) || return 1
    local total=0
    local num
    
    for num in $argv; do
        (( total += num ))
    done
    
    # Integer division
    print -- $(( total / ARGC ))
}

# Calculate average with floating point
# Usage: avgf 1 2 3 4 5
# Returns: 3.00
avgf() {
    (( ARGC >= 1 )) || return 1
    local total=0
    local num
    
    for num in $argv; do
        (( total += num ))
    done
    
    # Force float context by multiplying by 1.0
    printf "%.2f\n" $(( total * 1.0 / ARGC ))
}

# Get absolute value
# Usage: abs -5
# Returns: 5
abs() {
    (( ARGC == 1 )) || return 1
    local num=$1
    # Ternary operator inside arithmetic expansion
    print -- $(( num < 0 ? -num : num ))
}

# Calculate power
# Usage: pow 2 8
# Returns: 256
pow() {
    (( ARGC == 2 )) || return 1
    # Zsh has a built-in power operator
    print -- $(( $1 ** $2 ))
}

# Calculate square root
# Usage: sqrt 16
# Returns: 4.0
sqrt() {
    (( ARGC == 1 )) || return 1
    # Uses zsh/mathfunc
    print -- $(( sqrt($1) ))
}

# Generate random number between min and max (inclusive)
# Note: Simple implementation. For cryptographic quality, use lib/cwg.zsh
# Usage: random 1 100
random() {
    (( ARGC == 2 )) || return 1
    local min=$1
    local max=$2
    
    # Swap if min > max
    (( min > max )) && { local tmp=$min; min=$max; max=$tmp; }
    
    # Uses SRANDOM if available (Zsh 5.9+, 32-bit), otherwise RANDOM
    local r=${SRANDOM:-$RANDOM}
    print -- $(( r % (max - min + 1) + min ))
}

# --- Number Properties & Checks ---

# Check if number is even
# Usage: is_even 4
is_even() {
    (( ARGC == 1 )) || return 1
    (( $1 % 2 == 0 ))
}

# Check if number is odd
# Usage: is_odd 3
is_odd() {
    (( ARGC == 1 )) || return 1
    (( $1 % 2 != 0 ))
}

# Check if number is positive
# Usage: is_positive 5
is_positive() {
    (( ARGC == 1 )) || return 1
    (( $1 > 0 ))
}

# Check if number is negative
# Usage: is_negative -5
is_negative() {
    (( ARGC == 1 )) || return 1
    (( $1 < 0 ))
}

# Check if number is zero
# Usage: is_zero 0
is_zero() {
    (( ARGC == 1 )) || return 1
    (( $1 == 0 ))
}

# Check if argument is a valid number (integer or float)
# Usage: is_number "3.14" -> 0 (true)
# Usage: is_number "abc"  -> 1 (false)
is_number() {
    (( ARGC == 1 )) || return 1
    # Regex check: optional minus, digits, optional dot and decimal part
    [[ $1 =~ ^-?[0-9]+([.][0-9]+)?$ ]]
}

# Check if number is in range (inclusive)
# Usage: in_range 5 1 10
# Returns: 0 (true) if 5 is between 1 and 10
in_range() {
    (( ARGC == 3 )) || return 1
    (( $1 >= $2 && $1 <= $3 ))
}

# --- Rounding & Integer Arithmetic ---

# Round number to nearest integer
# Usage: round 3.7 -> 4
round() {
    (( ARGC == 1 )) || return 1
    print -- $(( int(rint($1)) ))
}

# Round number up (ceiling)
# Usage: ceil 3.1 -> 4
ceil() {
    (( ARGC == 1 )) || return 1
    print -- $(( int(ceil($1)) ))
}

# Round number down (floor)
# Usage: floor 3.9 -> 3
floor() {
    (( ARGC == 1 )) || return 1
    print -- $(( int(floor($1)) ))
}

# Calculate factorial
# Usage: factorial 5 -> 120
factorial() {
    (( ARGC == 1 )) || return 1
    local num=$1
    local result=1

    if (( num < 0 )); then
        return 1
    fi

    # Loop is efficient enough for typical shell usage
    local i
    for ((i=2; i<=num; i++)); do
        (( result *= i ))
    done

    print -- $result
}

# Calculate GCD (Greatest Common Divisor)
# Usage: gcd 48 18 -> 6
gcd() {
    (( ARGC == 2 )) || return 1
    local a=$1
    local b=$2
    local temp

    while (( b != 0 )); do
        (( temp = b, b = a % b, a = temp ))
    done

    print -- $a
}

# Calculate LCM (Least Common Multiple)
# Usage: lcm 12 18 -> 36
lcm() {
    (( ARGC == 2 )) || return 1
    local a=$1
    local b=$2
    local ta=$a tb=$b tt

    # Calculate GCD inline
    while (( tb != 0 )); do
        (( tt = tb, tb = ta % tb, ta = tt ))
    done

    # LCM = abs(a * b) / GCD
    print -- $(( (a * b) / ta ))
}

# Clamp number to range
# Usage: clamp 15 0 10 -> 10
clamp() {
    (( ARGC == 3 )) || return 1
    local val=$1
    local min=$2
    local max=$3

    if (( val < min )); then
        print -- $min
    elif (( val > max )); then
        print -- $max
    else
        print -- $val
    fi
}

# Calculate percentage
# Usage: percent 25 200 -> 12.50
percent() {
    (( ARGC == 2 )) || return 1
    printf "%.2f\n" $(( $1 * 100.0 / $2 ))
}

# --- Base Conversions ---

# Convert Decimal to Hexadecimal
# Usage: dec2hex 255 -> 0xFF
dec2hex() {
    (( ARGC == 1 )) || return 1
    print -- $(( [#16] $1 ))
}

# Convert Hexadecimal to Decimal
# Usage: hex2dec 0xFF -> 255
hex2dec() {
    (( ARGC == 1 )) || return 1
    print -- $(( $1 ))
}

# Convert Decimal to Binary
# Usage: dec2bin 10 -> 2#1010
dec2bin() {
    (( ARGC == 1 )) || return 1
    print -- $(( [#2] $1 ))
}

# --- Trigonometry / Geometry ---

# Convert degrees to radians
# Usage: deg2rad 180 -> 3.14159...
deg2rad() {
    (( ARGC == 1 )) || return 1
    printf "%.8f\n" $(( $1 * (4 * atan(1.0)) / 180.0 ))
}

# Convert radians to degrees
# Usage: rad2deg 3.14159 -> 180.00...
rad2deg() {
    (( ARGC == 1 )) || return 1
    printf "%.8f\n" $(( $1 * 180.0 / (4 * atan(1.0)) ))
}

# Calculate fibonacci number at position n
# Usage: fibonacci 10 -> 55
fibonacci() {
    (( ARGC == 1 )) || return 1
    local n=$1

    if (( n <= 0 )); then
        print 0
        return 0
    elif (( n == 1 )); then
        print 1
        return 0
    fi

    local a=0 b=1 temp
    local i
    for ((i=2; i<=n; i++)); do
        (( temp = b, b = a + b, a = temp ))
    done

    print -- $b
}

# --- Formatting ---

# Format bytes into human readable size (IEC)
# Usage: format_bytes 1048576 -> "1.00 MiB"
format_bytes() {
    (( ARGC == 1 )) || return 1
    local -F bytes=$1
    local -a units=(B KiB MiB GiB TiB PiB)
    local i=1

    while (( bytes >= 1024 && i < 6 )); do
        (( bytes /= 1024.0 ))
        (( i++ ))
    done

    if (( i == 1 )); then
        printf "%.0f %s" $bytes $units[$i]
    else
        printf "%.2f %s" $bytes $units[$i]
    fi
}

# Format number with SI metric prefixes (k, M, G, T) - Base 1000
# Usage: format_metric 1500 -> "1.50 k"
format_metric() {
    (( ARGC == 1 )) || return 1
    local -F val=$1
    local -a units=("" k M G T P E)
    local i=1

    while (( val >= 1000 && i < 7 )); do
        (( val /= 1000.0 ))
        (( i++ ))
    done

    printf "%.2f %s\n" $val $units[$i]
}

# Shell files tracking - keep at the end
zfile_track_end ${0:A}