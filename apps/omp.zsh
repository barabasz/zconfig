#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# Oh My Posh configuration

# Guard: Fast check using hash table instead of function call
(( ${+commands[oh-my-posh]} )) || return

# Define paths 
# matches your current config path:
local omp_config="$ZSH_APPS_DIR/omp.json"
local cache_dir=$ZSH_CACHE_DIR
local cache_file="$cache_dir/omp_init.zsh"
local zwc_file="${cache_file}.zwc"

# Export the theme variable (just in case some segments rely on it)
export OMP_THEME="$omp_config"

# Ensure cache directory exists
[[ -d "$cache_dir" ]] || mkdir -p "$cache_dir"

# Smart Cache Update Logic
# Rebuild if:
# 1. Cache file missing
# 2. OMP binary is newer than cache
# 3. Config file (my.omp.json) is newer than cache (so edits apply immediately)
local rebuild=0
if [[ ! -f "$cache_file" || "${commands[oh-my-posh]}" -nt "$cache_file" ]]; then
    rebuild=1
elif [[ -f "$omp_config" && "$omp_config" -nt "$cache_file" ]]; then
    rebuild=1
fi

if (( rebuild )); then
    # Generate init script directly to file
    if [[ -f "$omp_config" ]]; then
        oh-my-posh init zsh --config "$omp_config" >| "$cache_file"
    else
        # Fallback if config is missing (safety)
        oh-my-posh init zsh >| "$cache_file"
    fi
    
    # Compile to wordcode for maximum speed
    zcompile "$cache_file"
fi

# Safety check: ensure .zwc exists if .zsh exists (in case it was deleted)
if [[ -f "$cache_file" && ! -f "$zwc_file" ]]; then
    zcompile "$cache_file"
fi

# Source the cached file (Zsh will implicitly use .zwc if present)
source "$cache_file"

# shell files tracking - keep at the end
zfile_track_end ${0:A}