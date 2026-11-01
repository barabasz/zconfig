#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# Path array manipulation functions
# zsh ties scalars (PATH, FPATH, MANPATH, CDPATH) to arrays (path, fpath,
# manpath, cdpath); these functions work on the arrays directly.
# The arrays are made unique (typeset -U) in inc/path.zsh, so adding a
# directory that is already present moves it instead of duplicating it.
##

## Generic helpers

# Add a directory to a path array (internal)
# Trailing slashes are removed, so "/usr/bin/" and "/usr/bin" are the same entry.
# Usage: _patharr_add <array_name> <dir> [prepend]
# Returns: 0 success, 1 not a directory, 2 invalid usage
_patharr_add() {
    (( ARGC >= 2 && ARGC <= 3 )) || return 2
    [[ $1 == (path|fpath|manpath|cdpath) ]] || return 2
    local dir=$2
    while [[ $dir == ?*/ ]]; do dir=${dir%/}; done
    [[ -d $dir ]] || return 1
    local -a current=("${(@P)1}")
    if [[ $3 == prepend ]]; then
        # Remove first, so an existing entry moves to the front
        set -A $1 "$dir" "${(@)current:#$dir}"
    else
        (( ${current[(Ie)$dir]} )) || set -A $1 "${current[@]}" "$dir"
    fi
}

# Remove a directory from a path array (internal)
# Usage: _patharr_remove <array_name> <dir>
# Returns: 0 success, 2 invalid usage
_patharr_remove() {
    (( ARGC == 2 )) || return 2
    [[ $1 == (path|fpath|manpath|cdpath) ]] || return 2
    local dir=$2
    while [[ $dir == ?*/ ]]; do dir=${dir%/}; done
    local -a current=("${(@P)1}")
    set -A $1 "${(@)current:#$dir}"
}

## PATH (executables)

# Add directory to the END of $PATH (no-op if already present)
# Usage: path_append <dir>
# Returns: 0 success, 1 not a directory, 2 invalid usage
path_append() {
    (( ARGC == 1 )) || return 2
    _patharr_add path "$1"
}

# Add directory to the BEGINNING of $PATH (moves it there if already present)
# Usage: path_prepend <dir>
# Returns: 0 success, 1 not a directory, 2 invalid usage
path_prepend() {
    (( ARGC == 1 )) || return 2
    _patharr_add path "$1" prepend
}

# Remove directory from $PATH
# Usage: path_remove <dir>
# Returns: 0 success, 2 invalid usage
path_remove() {
    (( ARGC == 1 )) || return 2
    _patharr_remove path "$1"
}

## FPATH (functions and completions)

# Add directory to the END of $fpath (no-op if already present)
# Usage: fpath_append <dir>
# Returns: 0 success, 1 not a directory, 2 invalid usage
fpath_append() {
    (( ARGC == 1 )) || return 2
    _patharr_add fpath "$1"
}

# Add directory to the BEGINNING of $fpath (moves it there if already present)
# Usage: fpath_prepend <dir>
# Returns: 0 success, 1 not a directory, 2 invalid usage
fpath_prepend() {
    (( ARGC == 1 )) || return 2
    _patharr_add fpath "$1" prepend
}

# Remove directory from $fpath
# Usage: fpath_remove <dir>
# Returns: 0 success, 2 invalid usage
fpath_remove() {
    (( ARGC == 1 )) || return 2
    _patharr_remove fpath "$1"
}

## MANPATH (manual pages)

# Add directory to the END of $manpath (no-op if already present)
# Usage: manpath_append <dir>
# Returns: 0 success, 1 not a directory, 2 invalid usage
manpath_append() {
    (( ARGC == 1 )) || return 2
    _patharr_add manpath "$1"
}

# Add directory to the BEGINNING of $manpath (moves it there if already present)
# Usage: manpath_prepend <dir>
# Returns: 0 success, 1 not a directory, 2 invalid usage
manpath_prepend() {
    (( ARGC == 1 )) || return 2
    _patharr_add manpath "$1" prepend
}

# Remove directory from $manpath
# Usage: manpath_remove <dir>
# Returns: 0 success, 2 invalid usage
manpath_remove() {
    (( ARGC == 1 )) || return 2
    _patharr_remove manpath "$1"
}

## CDPATH (directory navigation)

# Add directory to the END of $cdpath (no-op if already present)
# Usage: cdpath_append <dir>
# Example: cdpath_append ~/Projects   (no quotes, so ~ is expanded)
# Returns: 0 success, 1 not a directory, 2 invalid usage
cdpath_append() {
    (( ARGC == 1 )) || return 2
    _patharr_add cdpath "$1"
}

# Add directory to the BEGINNING of $cdpath (moves it there if already present)
# Usage: cdpath_prepend <dir>
# Returns: 0 success, 1 not a directory, 2 invalid usage
cdpath_prepend() {
    (( ARGC == 1 )) || return 2
    _patharr_add cdpath "$1" prepend
}

# Remove directory from $cdpath
# Usage: cdpath_remove <dir>
# Returns: 0 success, 2 invalid usage
cdpath_remove() {
    (( ARGC == 1 )) || return 2
    _patharr_remove cdpath "$1"
}

## Utilities

# Remove non-existing directories from all path arrays
# Usage: path_clean
# Returns: 0 success, 2 invalid usage
path_clean() {
    (( ARGC == 0 )) || return 2
    # $^arr applies the glob qualifier to every element;
    # (N-/): nullglob, follow symlinks, directories only
    path=($^path(N-/))
    fpath=($^fpath(N-/))
    manpath=($^manpath(N-/))
    cdpath=($^cdpath(N-/))
}

# Pretty print a path array, one entry per line
# Usage: path_print [path|fpath|manpath|cdpath]   (default: path)
# Returns: 0 success, 2 invalid usage
path_print() {
    (( ARGC <= 1 )) || return 2
    local var=${1:-path}
    [[ $var == (path|fpath|manpath|cdpath) ]] || return 2
    print -rl -- "${(@P)var}"
}

# Shell files tracking - keep at the end
zfile_track_end ${0:A}
