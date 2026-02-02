#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# --- Collatz-Weyl Generator (CWG) Module ---
# A fast and simple Pseudo-Random Number Generator (PRNG) based on the Collatz conjecture
# and Weyl sequences. This implementation is designed for Zsh scripts.

# Define Module Version
typeset -gr _CWG_VERSION="1.3.0"

# Initialize generator state (global variables)
# We use 'typeset -gi' (global + integer).
typeset -gi _cwg_x=123456789  # Seed - Collatz state
typeset -gi _cwg_w=0          # Weyl state

# Magic constant (Golden Ratio for 64-bit): 0x9E3779B97F4A7C15
typeset -gi _cwg_inc=-7046029254386353131

# Function to initialize the generator with a custom seed
# Usage: cwg_seed [seed]
# If no seed is provided, uses current time for entropy
cwg_seed() {
    if (( ARGC > 0 )); then
        (( _cwg_x = $1 ))
    else
        # Use EPOCHREALTIME (remove dot) for high entropy seeding
        (( _cwg_x = ${EPOCHREALTIME/./} ))
    fi
    (( _cwg_w = 0 ))
}

# Core function returning a raw random number
# Usage: cwg_next
# Optimized for speed: No argument parsing, just math.
# Returns a pseudo-random number in REPLY.
# Returns error code 2 on invalid usage
cwg_next() {
    (( ARGC == 0 )) || return 2 # Invalid usage
    (( _cwg_w += _cwg_inc ))
    if (( _cwg_x % 2 == 0 )); then
        (( _cwg_x >>= 1 ))
    else
        (( _cwg_x = 3 * _cwg_x + _cwg_w ))
    fi
    # Mask to positive 64-bit integer
    (( REPLY = _cwg_x & 9223372036854775807 ))
}

# shell files tracking - keep at the end
zfile_track_end ${0:A}