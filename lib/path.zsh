#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# Path manipulation functions
# Zsh automatically ties scalar parameters (like PATH) to array parameters (like path).
# These functions manipulate the arrays directly for safety and ease of use.

# Ensure path arrays contain unique values (Zsh feature)
# -U flag makes these arrays keep only unique elements automatically
typeset -U path fpath manpath cdpath

# --- PATH (Executables) ---

# Add directory to the END of $PATH
# Usage: path_append "/opt/local/bin"
# Returns: 0 on success, 1 if not a directory, 2 on invalid usage
path_append() {
    (( ARGC == 1 )) || return 2 # Invalid usage
    [[ -d $1 ]] || return 1 # Not a directory
    # Check if already in path using Reverse Subscripting (I) with Exact match (e)
    # Returns 0 if not found (index 0)
    if (( ${path[(Ie)$1]} == 0 )); then
        path+=($1)
    fi
}

# Add directory to the BEGINNING of $PATH
# Usage: path_prepend "/opt/homebrew/bin"
# Returns: 0 on success, 1 if not a directory, 2 on invalid usage
path_prepend() {
    (( ARGC == 1 )) || return 2 # Invalid usage
    [[ -d $1 ]] || return 1 # Not a directory
    if (( ${path[(Ie)$1]} == 0 )); then
        path=($1 $path)
    fi
}

# Remove directory from $PATH
# Usage: path_remove "/usr/local/bin"
# Returns: 0 on success, 2 on invalid usage
path_remove() {
    (( ARGC == 1 )) || return 2 # Invalid usage
    # Zsh array filtering operator :# removes matching elements
    path=(${path:#$1})
}

# --- FPATH (Functions/Completions) ---

# Add directory to the END of $fpath
# Usage: fpath_append "/path/to/functions"
# Returns: 0 on success, 1 if not a directory, 2 on invalid usage
fpath_append() {
    (( ARGC == 1 )) || return 2
    [[ -d $1 ]] || return 1
    if (( ${fpath[(Ie)$1]} == 0 )); then
        fpath+=($1)
    fi
}

# Add directory to the BEGINNING of $fpath
# Usage: fpath_prepend "/path/to/my-functions"
# Returns: 0 on success, 1 if not a directory, 2 on invalid usage
fpath_prepend() {
    (( ARGC == 1 )) || return 2
    [[ -d $1 ]] || return 1
    if (( ${fpath[(Ie)$1]} == 0 )); then
        fpath=($1 $fpath)
    fi
}

# Remove directory from $fpath
# Usage: fpath_remove "/path/to/remove"
# Returns: 0 on success, 2 on invalid usage
fpath_remove() {
    (( ARGC == 1 )) || return 2
    fpath=(${fpath:#$1})
}

# --- MANPATH (Manual pages) ---

# Add directory to $manpath
# Usage: manpath_append "/path/to/man"
# Returns: 0 on success, 1 if not a directory, 2 on invalid usage
manpath_append() {
    (( ARGC == 1 )) || return 2
    [[ -d $1 ]] || return 1
    # Note: manpath might not be set in all environments, verify existence
    if (( ${manpath[(Ie)$1]} == 0 )); then
        manpath+=($1)
    fi
}

# --- CDPATH (Directory navigation) ---

# Add directory to $cdpath
# Usage: cdpath_append "~/Projects"
# Returns: 0 on success, 1 if not a directory, 2 on invalid usage
cdpath_append() {
    (( ARGC == 1 )) || return 2
    [[ -d $1 ]] || return 1
    if (( ${cdpath[(Ie)$1]} == 0 )); then
        cdpath+=($1)
    fi
}

# --- Utilities ---

# Remove non-existing directories from all path arrays
# Usage: path_clean
# Returns: 0 on success, 2 on invalid usage
path_clean() {
    (( ARGC == 0 )) || return 2
    # Advanced Zsh Globbing:
    # $^path   -> distribute logic to all elements
    # (N-/)    -> Nullglob (removes if no match), follow symlinks (-), directories only (/)
    # Effectively keeps only elements that are valid directories

    path=($^path(N-/))
    fpath=($^fpath(N-/))
    manpath=($^manpath(N-/))
    cdpath=($^cdpath(N-/))
}

# Pretty print path variables
# Usage: path_print [path|fpath|manpath|cdpath]
# Returns: 0 on success, 2 on invalid usage
path_print() {
    (( ARGC <= 1 )) || return 2
    local var=${1:-path}
    # (P) is indirect expansion flag
    print -l -- "${(@P)var}"
}

# Shell files tracking - keep at the end
zfile_track_end ${0:A}