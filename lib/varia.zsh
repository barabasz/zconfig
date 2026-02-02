#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# Miscellaneous helper functions & metaprogramming utilities
# Depends on: print.zsh (for output), bootstrap.zsh (for colors)

# Check if debug mode is enabled
# Usage: is_debug
# Returns: 0 on true, 1 on false, 2 on invalid usage
is_debug() {
    (( ARGC == 0 )) || return 2
    [[ $ZSH_DEBUG == 1 || $DEBUG == 1 ]]
}

# Source all .zsh files in a directory
# Usage: source_zsh_dir "/path/to/dir"
# Returns: 0 on success, 1 on failure, 2 on invalid usage
source_zsh_dir() {
    (( ARGC == 1 )) || return 2
    local f
    for f in $1/*.zsh(N); do
        source "$f"
    done
}

# Concatenate all .zsh files in a directory into a single file
# Usage: concatenate_zsh_dir "/path/to/dir" "/path/to/output.zsh"
# Returns: 0 on success, 1 on failure, 2 on invalid usage
# Sets: REPLY to number of files concatenated
concatenate_zsh_dir() {
    (( ARGC == 2 )) || { printe "Usage: concatenate_zsh_dir <directory> <output_file>"; return 2 }

    local dir="${1:A}"
    local output_file="${2:A}"
    local output_dir="${output_file:h}"

    # Validate inputs
    [[ -d "$dir" ]] || { printe "Directory ${c}${dir}${x} does not exist."; return 1 }
    [[ -w "$output_dir" ]] || { printe "Cannot write to ${c}${output_dir}${x}."; return 1 }

    # Check for .zsh files (excluding _prefixed)
    local -a files=("$dir"/*.zsh(N))
    files=(${files:#$dir/_*})  # Exclude _prefixed files

    if (( ${#files} == 0 )); then
        printw "No .zsh files found in ${c}${dir}${x}."
        return 1
    fi

    # Truncate and write shebang
    print '#!/bin/zsh\n' > "$output_file"

    local -i count=0
    local f name
    for f in "${files[@]}"; do
        name="${f:t}"
        print "#\n# File: ${name}\n#\n" >> "$output_file"
        # Skip comment lines and empty lines
        grep -v '^\s*#' "$f" | grep -v '^\s*$' >> "$output_file"
        print "" >> "$output_file"
        (( count++ ))
    done

    REPLY=$count
    printi "Concatenated ${y}${count}${x} files into ${c}${output_file}${x}."
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

# Ultra-fast command type detector
# Wrapper around 'whence -w' that normalizes output for programmatic use.
# Usage: utype <command>
# Returns: file | alias | function | builtin | keyword | notfound
# Exit: 0 if found, 1 if notfound or error
utype() {
    (( ARGC == 1 )) || return 1
    case $(whence -w -- "$1" 2>/dev/null) in
        *:\ command) print file ;;
        *:\ hashed)  print file ;;
        *:\ alias)   print alias ;;
        *:\ function) print function ;;
        *:\ builtin) print builtin ;;
        *:\ reserved) print keyword ;;
        *) print notfound; return 1 ;;
    esac
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

# Show arguments info (for debugging/learning)
# Usage: argsinfo arg1 arg2 ... argN
# Returns: 0 on success, 1 if no arguments
argsinfo() {
    (( ARGC == 0 )) && { printe "No arguments provided."; return 1 }

    print "Number of arguments: ${y}${ARGC}${x}"
    print "List of arguments:"

    local i=0
    for arg in "$@"; do
        print "${y}#$((++i))${x}: $arg"
    done
}

# shell files tracking - keep at the end
zfile_track_end ${0:A}
