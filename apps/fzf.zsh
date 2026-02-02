#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# fzf (fuzzy finder) integration

# Guard
is_installed fzf || return

# Cache paths
local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
local cache_file="$cache_dir/fzf_init.zsh"
local zwc_file="${cache_file}.zwc"

# Ensure cache directory exists
[[ -d "$cache_dir" ]] || mkdir -p "$cache_dir"

# Check if cache needs update:
# 1. Cache file missing
# 2. OR fzf binary is newer than cache file
# 3. OR compiled file (.zwc) is missing or older than cache file
if [[ ! -f "$cache_file" || "${commands[fzf]}" -nt "$cache_file" ]]; then
    # 1. Generate init script
    fzf --zsh >| "$cache_file"
    
    # 2. Compile to wordcode (files: cache_file)
    # This creates fzf_init.zsh.zwc which Zsh automatically prefers over the .zsh file
    zcompile "$cache_file"
fi

# Safety check: if .zwc is missing/deleted manually but .zsh exists, compile it
if [[ -f "$cache_file" && ! -f "$zwc_file" ]]; then
    zcompile "$cache_file"
fi

# Source the cached file (Zsh will implicitly use .zwc if present)
source "$cache_file"

# shell files tracking - keep at the end
zfile_track_end ${0:A}