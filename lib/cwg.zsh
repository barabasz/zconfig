#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# Collatz-Weyl Generator (CWG)
# A fast and simple pseudo-random number generator (PRNG) based on the
# Collatz conjecture and Weyl sequences. Not cryptographically secure.
# Depends on: zsh/datetime (EPOCHREALTIME, for time-based seeding)
##

## State

# Module version (plain global, so re-sourcing the file does not fail)
typeset -g _CWG_VERSION="1.3.1"

# Generator state (global integers); keep the current state when re-sourced
(( ${+_cwg_x} )) || typeset -gi _cwg_x=123456789  # Collatz state (seed)
(( ${+_cwg_w} )) || typeset -gi _cwg_w=0          # Weyl state

# Magic constant (golden ratio for 64-bit): 0x9E3779B97F4A7C15
typeset -gi _cwg_inc=-7046029254386353131

## Functions

# Initialize the generator with a seed
# Usage: cwg_seed [seed]   (default: current time in microseconds)
# Returns: 0 success, 2 invalid usage
cwg_seed() {
    (( ARGC <= 1 )) || return 2
    if (( ARGC )); then
        [[ $1 == (-|)<-> ]] || return 2
        (( _cwg_x = $1 ))
    else
        # EPOCHREALTIME without the dot: microsecond resolution entropy
        (( _cwg_x = ${${EPOCHREALTIME/./}[1,16]} ))
    fi
    (( _cwg_w = 0 ))
}

# Get the next raw pseudo-random number
# Optimized for speed: no output and no subshell needed.
# Usage: cwg_next
# Output: none; sets REPLY to a non-negative 63-bit integer
# Returns: 0 success, 2 invalid usage
cwg_next() {
    (( ARGC == 0 )) || return 2
    (( _cwg_w += _cwg_inc ))
    if (( _cwg_x % 2 == 0 )); then
        (( _cwg_x >>= 1 ))
    else
        (( _cwg_x = 3 * _cwg_x + _cwg_w ))
    fi
    # Mask to a positive 64-bit integer
    (( REPLY = _cwg_x & 9223372036854775807 ))
    return 0
}

# Shell files tracking - keep at the end
zfile_track_end ${0:A}
