#!/bin/zsh
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# Path manipulation functions
# Zsh automatically ties scalar parameters (like PATH) to array parameters (like path).
# These functions manipulate the arrays directly for safety and ease of use.

# Ensure path arrays contain unique values (Zsh feature)
# -U flag makes these arrays keep only unique elements automatically
typeset -U path fpath manpath cdpath

# Add directory to the END of $PATH
# Usage: path_append "/opt/local/bin"
# Returns: 0 on success, 1 on failure
path_append() {
    (( ARGC == 1 )) && [[ -d $1 ]] || return 1
    # Check if already in path (Ie returns index or 0) to avoid re-ordering if exists
    if (( ${path[(Ie)$1]} == 0 )); then
        path+=($1)
    fi
}

# Add directory to the BEGINNING of $PATH
# Usage: path_prepend "/opt/homebrew/bin"
# Returns: 0 on success, 1 on failure
path_prepend() {
    (( ARGC == 1 )) && [[ -d $1 ]] || return 1
    if (( ${path[(Ie)$1]} == 0 )); then
        path=($1 $path)
    fi
}

# Remove directory from $PATH
# Usage: path_remove "/usr/local/bin"
# Returns: 0 on success, 1 on failure
path_remove() {
    (( ARGC == 1 )) || return 1
    # Array filtering: remove elements matching the pattern
    path=("${path[@]:#$1}")
}

# Add directory to $fpath (function path)
# Usage: fpath_append "/path/to/functions"
# Returns: 0 on success, 1 on failure
fpath_append() {
    (( ARGC == 1 )) && [[ -d $1 ]] || return 1
    if (( ${fpath[(Ie)$1]} == 0 )); then
        fpath+=($1)
    fi
}

# Add directory to $manpath
# Usage: manpath_append "/path/to/man"
# Returns: 0 on success, 1 on failure
manpath_append() {
    (( ARGC == 1 )) && [[ -d $1 ]] || return 1
    if (( ${manpath[(Ie)$1]} == 0 )); then
        manpath+=($1)
    fi
}

# Print $PATH separated by newlines (readable)
# Usage: path_print
# Returns: Prints path elements to stdout
path_print() {
    print -l $path
}

# Check if directory is in $PATH
# Usage: is_in_path "/usr/bin"
# Returns: 0 (true) or 1 (false)
is_in_path() {
    (( ARGC == 1 )) || return 1
    # (Ie) returns index of match or 0
    (( ${path[(Ie)$1]} ))
}

# shell files tracking - keep at the end
zfile_track_end ${0:A}