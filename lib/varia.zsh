#!/bin/zsh
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# Miscellaneous helper functions & metaprogramming utilities
# Depends on: print.zsh (for output), bootstrap.zsh (for colors)

# Check if debug mode is enabled
# Usage: is_debug
# Returns: 0 (true) or 1 (false)
is_debug() {
    [[ $ZSH_DEBUG == 1 || $DEBUG == 1 ]]
}

# Measure execution time of a command
# Usage: etime [-v] command [args...]
# Returns: prints time in ms to stdout
etime() {
    [[ "$1" = "-v" ]] && local verbose=1 && shift
    (( ARGC == 0 )) && return 1
    local start=$EPOCHREALTIME
    $@ > /dev/null 2>&1
    local exit_code=$status
    # Calculate duration
    local formatted
    printf -v formatted "%.2f" $(( (EPOCHREALTIME - start) * 1000 ))
    if [[ $verbose == 1 ]]; then
        printi "Command $y'$c$*$y'$x executed in $y$formatted$x ms."
    else
        print "$formatted ms"
    fi
    return $exit_code
}

# Check if command(s) are installed/available
# Usage: is_installed git [curl ...]
# Returns: 0 if all commands exist, 1 otherwise
is_installed() {
    # Fast path for single argument
    if (( ARGC == 1 )); then
        (( ${+commands[$1]} ))
        return
    fi

    # Loop for multiple arguments
    local cmd
    for cmd in $argv; do
        (( ${+commands[$cmd]} )) || return 1
    done
    return 0
}

# Create a backup of a file with timestamp
# Usage: backup_file "config.txt"
# Returns: 0 on success (creates config.txt.20240101_120000)
backup_file() {
    [[ -f "$1" ]] || return 1
    local ts
    strftime -s ts "%Y%m%d_%H%M%S" $EPOCHSECONDS
    
    if cp -a "$1" "${1}.${ts}"; then
        prints "Backup created: ${1}.${ts}"
        return 0
    else
        printe "Failed to create backup of '$1'"
        return 1
    fi
}

# Ask for confirmation (Y/n)
# Usage: confirm "Delete file?" && rm file
# Returns: 0 (yes) or 1 (no)
confirm() {
    # Use yellow color ($y) for question to match printq style
    local prompt_text="${1:-Are you sure?}"
    local prompt="${y}${prompt_text} [y/N]${x} "
    local response
    
    read -q "response?${prompt}" # -q reads single char without enter
    print "" # Print newline after single char input
    
    # Check if response is y or Y
    [[ "$response" == [yY] ]]
}

# shell files tracking - keep at the end
zfile_track_end ${0:A}
