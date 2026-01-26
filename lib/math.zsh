#!/bin/zsh
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# Load Zsh math functions (sqrt, ceil, floor, sin, cos, etc.)
zmodload zsh/mathfunc

# Get minimum of two or more numbers
# Usage: min 5 3 8 1
# Returns: 1
min() {
    (( ARGC >= 1 )) || return 1
    # Sort arguments numerically (n) and print the first element
    print -- ${${(n)@}[1]}
}

# Get maximum of two or more numbers
# Usage: max 5 3 8 1
# Returns: 8
max() {
    (( ARGC >= 1 )) || return 1
    # Sort arguments numerically (n) and print the last element
    print -- ${${(n)@}[-1]}
}

# Calculate sum of numbers
# Usage: sum 1 2 3 4 5
# Returns: 15
sum() {
    (( ARGC >= 1 )) || return 1
    local total=0
    local num
    
    for num in $@; do
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
    
    for num in $@; do
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
    
    for num in $@; do
        (( total += num ))
    done
    
    # Force float context by multiplying by 1.0 or using typeset -F
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
# Usage: random 1 100
# Returns: random number between 1 and 100
random() {
    (( ARGC == 2 )) || return 1
    local min=$1
    local max=$2
    
    # Swap if min > max
    (( min > max )) && { local tmp=$min; min=$max; max=$tmp; }
    
    # Uses SRANDOM if available (Zsh 5.9+, 32-bit), otherwise RANDOM (15-bit)
    local r=${SRANDOM:-$RANDOM}
    print -- $(( r % (max - min + 1) + min ))
}

# Check if number is even
# Usage: is_even 4
# Returns: 0 (true) or 1 (false)
is_even() {
    (( ARGC == 1 )) || return 1
    (( $1 % 2 == 0 ))
}

# Check if number is odd
# Usage: is_odd 3
# Returns: 0 (true) or 1 (false)
is_odd() {
    (( ARGC == 1 )) || return 1
    (( $1 % 2 != 0 ))
}

# Check if number is positive
# Usage: is_positive 5
# Returns: 0 (true) or 1 (false)
is_positive() {
    (( ARGC == 1 )) || return 1
    (( $1 > 0 ))
}

# Check if number is negative
# Usage: is_negative -5
# Returns: 0 (true) or 1 (false)
is_negative() {
    (( ARGC == 1 )) || return 1
    (( $1 < 0 ))
}

# Check if number is zero
# Usage: is_zero 0
# Returns: 0 (true) or 1 (false)
is_zero() {
    (( ARGC == 1 )) || return 1
    (( $1 == 0 ))
}

# Round number to nearest integer
# Usage: round 3.7
# Returns: 4
round() {
    (( ARGC == 1 )) || return 1
    # rint() is from zsh/mathfunc (round to nearest integer)
    print -- $(( int(rint($1)) ))
}

# Round number up (ceiling)
# Usage: ceil 3.1
# Returns: 4
ceil() {
    (( ARGC == 1 )) || return 1
    # ceil() from zsh/mathfunc
    print -- $(( int(ceil($1)) ))
}

# Round number down (floor)
# Usage: floor 3.9
# Returns: 3
floor() {
    (( ARGC == 1 )) || return 1
    # floor() from zsh/mathfunc
    print -- $(( int(floor($1)) ))
}

# Calculate factorial
# Usage: factorial 5
# Returns: 120
factorial() {
    (( ARGC == 1 )) || return 1
    local num=$1
    local result=1

    if (( num < 0 )); then
        return 1
    fi

    for ((i=2; i<=num; i++)); do
        (( result *= i ))
    done

    print -- $result
}

# Calculate percentage
# Usage: percent 25 200
# Returns: 50.00
percent() {
    (( ARGC == 2 )) || return 1
    # Floating point calculation naturally
    printf "%.2f\n" $(( $1 * $2 / 100.0 ))
}

# Check if number is in range (inclusive)
# Usage: in_range 5 1 10
# Returns: 0 (true) if 5 is between 1 and 10
in_range() {
    (( ARGC == 3 )) || return 1
    (( $1 >= $2 && $1 <= $3 ))
}

# Clamp number to range
# Usage: clamp 15 0 10
# Returns: 10
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

# Calculate GCD (Greatest Common Divisor)
# Usage: gcd 48 18
# Returns: 6
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
# Usage: lcm 12 18
# Returns: 36
lcm() {
    (( ARGC == 2 )) || return 1
    local a=$1
    local b=$2
    local gcd_val
    
    # Calculate GCD inline
    local ta=$a tb=$b tt
    while (( tb != 0 )); do
        (( tt = tb, tb = ta % tb, ta = tt ))
    done
    gcd_val=$ta

    print -- $(( (a * b) / gcd_val ))
}

# Convert degrees to radians
# Usage: deg2rad 180
# Returns: 3.14159...
deg2rad() {
    (( ARGC == 1 )) || return 1
    # 4 * atan(1) is a precise way to get PI using zsh/mathfunc
    printf "%.8f\n" $(( $1 * (4 * atan(1.0)) / 180.0 ))
}

# Convert radians to degrees
# Usage: rad2deg 3.14159
# Returns: 180.00...
rad2deg() {
    (( ARGC == 1 )) || return 1
    printf "%.8f\n" $(( $1 * 180.0 / (4 * atan(1.0)) ))
}

# Calculate fibonacci number at position n
# Usage: fibonacci 10
# Returns: 55
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

    # Zsh optimizes this arithmetic loop well
    for ((i=2; i<=n; i++)); do
        (( temp = b, b = a + b, a = temp ))
    done

    print -- $b
}

# Format bytes into human readable size
# Usage: format_bytes 1536      → "1.50 KiB"
#        format_bytes 1048576   → "1.00 MiB"
#        format_bytes 500       → "500 B"
# Input: bytes (integer or float)
# Returns: formatted string with appropriate unit (B, KiB, MiB, GiB, TiB)
format_bytes() {
    (( ARGC == 1 )) || return 1
    local -F bytes=$1
    local -a units=(B KiB MiB GiB TiB)
    local -i i=1

    while (( bytes >= 1024 && i < ${#units} )); do
        (( bytes /= 1024.0 ))
        (( i++ ))
    done

    if (( i == 1 )); then
        printf "%.0f %s" $bytes $units[i]
    else
        printf "%.2f %s" $bytes $units[i]
    fi
}

# shell files tracking - keep at the end
zfile_track_end ${0:A}