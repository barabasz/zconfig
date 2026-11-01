#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# Miscellaneous helper functions and metaprogramming utilities
# Depends on: print.zsh (printe, printi, prints, yesno), inc/colors.zsh
##

## Debugging and loading

# Check if debug mode is enabled (ZSH_DEBUG=1)
# Usage: is_debug
# Returns: 0 true, 1 false, 2 invalid usage
is_debug() {
    (( ARGC == 0 )) || return 2
    (( ${ZSH_DEBUG:-0} == 1 ))
}

# Source all .zsh files in a directory (alphabetical order)
# Usage: source_zsh_dir <dir>
# Returns: 0 success, 1 any file failed to source, 2 invalid usage
source_zsh_dir() {
    (( ARGC == 1 )) || return 2
    local f
    local -i failed=0
    for f in $1/*.zsh(N.); do
        source "$f" || (( failed++ ))
    done
    (( failed == 0 ))
}

# Concatenate all .zsh files in a directory into a single file
# Full-line comments and empty lines are removed, except inside here-documents
# Usage: concatenate_zsh_dir <dir> <output_file>
# Sets: REPLY to number of files concatenated
# Returns: 0 success, 1 failure, 2 invalid usage
concatenate_zsh_dir() {
    (( ARGC == 2 )) || { _lib_usage "concatenate_zsh_dir <directory> <output_file>"; return }

    local dir="${1:A}"
    local output_file="${2:A}"
    local output_dir="${output_file:h}"

    [[ -d "$dir" ]] || { printe "Directory ${c}${dir}${x} does not exist."; return 1 }
    [[ -w "$output_dir" ]] || { printe "Cannot write to ${c}${output_dir}${x}."; return 1 }

    # .zsh files, excluding _prefixed ones
    local -a files=("$dir"/[^_]*.zsh(N.))
    if (( ${#files} == 0 )); then
        printw "No .zsh files found in ${c}${dir}${x}."
        return 1
    fi

    setopt localoptions extendedglob
    local -a out=('#!/bin/zsh' '')
    local -i count=0
    local f line heredoc_end=""
    for f in $files; do
        out+=('#' "# File: ${f:t}" '#' '')
        for line in "${(@f)$(<$f)}"; do
            if [[ -n $heredoc_end ]]; then
                # Inside a here-document: keep everything verbatim
                out+=("$line")
                [[ ${line##[[:space:]]#} == $heredoc_end ]] && heredoc_end=""
                continue
            fi
            # Skip empty lines and full-line comments
            [[ $line == [[:space:]]# || $line == [[:space:]]#\#* ]] && continue
            out+=("$line")
            # Detect start of a here-document (<<WORD, <<-WORD, <<'WORD', <<"WORD")
            if [[ $line =~ '<<-?[[:space:]]*["'\'']?([A-Za-z_][A-Za-z0-9_]*)' ]]; then
                heredoc_end=$match[1]
            fi
        done
        out+=('')
        (( count++ ))
    done
    print -rl -- $out >| "$output_file" || return 1

    REPLY=$count
    printi "Concatenated ${y}${count}${x} files into ${c}${output_file}${x}."
}

## Timing

# Measure execution time of a command (command output is discarded)
# Usage: etime [-v|--verbose] <command> [args...]
# Output: time in ms (stdout); also sets REPLY to the number of ms
# Returns: exit code of the command, 2 invalid usage
etime() {
    local -a verbose
    # No -E: parsing stops at the command, so its own options are kept
    zparseopts -D v=verbose -verbose=verbose
    (( ARGC >= 1 )) || { _lib_usage "etime [-v] <command> [args...]"; return }

    local -F start=$EPOCHREALTIME
    "$@" >/dev/null 2>&1
    local -i exit_code=$status

    printf -v REPLY "%.2f" $(( (EPOCHREALTIME - start) * 1000 ))
    if (( ${#verbose} )); then
        printi "Command $y'$c$*$y'$x executed in $y$REPLY$x ms."
    else
        print -r -- "$REPLY ms"
    fi
    return $exit_code
}

# Run a command N times and report average, minimum and maximum time
# Usage: bench <count> <command> [args...]
# Output: summary line (stdout); also sets reply=(avg min max) in ms
# Returns: 0 success, 1 command failed at least once, 2 invalid usage
bench() {
    (( ARGC >= 2 )) && [[ $1 == <1-> ]] || { _lib_usage "bench <count> <command> [args...]"; return }
    local -i count=$1 i failed=0
    shift
    local -F start elapsed total=0 min=-1 max=0

    for (( i = 1; i <= count; i++ )); do
        start=$EPOCHREALTIME
        "$@" >/dev/null 2>&1 || (( failed++ ))
        (( elapsed = (EPOCHREALTIME - start) * 1000 ))
        (( total += elapsed ))
        (( min < 0 || elapsed < min )) && min=$elapsed
        (( elapsed > max )) && max=$elapsed
    done

    local avg_s min_s max_s
    printf -v avg_s "%.2f" $(( total / count ))
    printf -v min_s "%.2f" $min
    printf -v max_s "%.2f" $max
    reply=($avg_s $min_s $max_s)
    print -r -- "${count} runs: avg ${avg_s} ms, min ${min_s} ms, max ${max_s} ms"
    (( failed == 0 ))
}

# Retry a command until it succeeds
# Usage: retry <attempts> [delay_seconds] -- <command> [args...]
#        retry <attempts> <command> [args...]
# Returns: exit code of the last attempt, 2 invalid usage
retry() {
    (( ARGC >= 2 )) && [[ $1 == <1-> ]] || { _lib_usage "retry <attempts> [delay] -- <command> [args...]"; return }
    local -i attempts=$1 i
    local delay=1
    shift
    if [[ $1 == (<->|<->.<->) && $2 == -- ]]; then
        delay=$1
        shift 2
    elif [[ $1 == -- ]]; then
        shift
    fi
    (( ARGC >= 1 )) || return 2

    local -i rc=0
    for (( i = 1; i <= attempts; i++ )); do
        "$@" && return 0
        rc=$status
        (( i < attempts )) && sleep $delay
    done
    return $rc
}

## Command detection

# Check if command(s) are installed/available
# Usage: is_installed <command> [command...]
# Returns: 0 all commands exist, 1 otherwise, 2 invalid usage
is_installed() {
    (( ARGC >= 1 )) || return 2
    # Fast path for single argument
    if (( ARGC == 1 )); then
        (( ${+commands[$1]} ))
        return
    fi
    local cmd
    for cmd in $argv; do
        (( ${+commands[$cmd]} )) || return 1
    done
    return 0
}

# Fast command type detector (no subshell, uses zsh/parameter hashes)
# Usage: utype <command>
# Output: file | alias | function | builtin | keyword | notfound (stdout); also sets REPLY
# Returns: 0 found, 1 not found, 2 invalid usage
utype() {
    (( ARGC == 1 )) || return 2
    # Same precedence as command lookup: alias, keyword, function, builtin, file
    if (( ${+aliases[$1]} || ${+galiases[$1]} )); then
        REPLY=alias
    elif (( ${reswords[(Ie)$1]} )); then
        REPLY=keyword
    elif (( ${+functions[$1]} )); then
        REPLY=function
    elif (( ${+builtins[$1]} )); then
        REPLY=builtin
    elif (( ${+commands[$1]} )) || [[ $1 == */* && -x $1 && ! -d $1 ]]; then
        REPLY=file
    else
        REPLY=notfound
        print -r -- "$REPLY"
        return 1
    fi
    print -r -- "$REPLY"
}

## Files and prompts

# Create a backup of a file with timestamp (file.ext -> file.ext.YYYYmmdd_HHMMSS)
# Usage: backup_file <file>
# Sets: REPLY to the backup path
# Returns: 0 success, 1 failure, 2 invalid usage, 127 file not found
backup_file() {
    (( ARGC == 1 )) || return 2
    [[ -f "$1" ]] || { printe "File not found: '$1'"; return 127 }
    local ts
    strftime -s ts "%Y%m%d_%H%M%S" $EPOCHSECONDS

    if cp -a -- "$1" "${1}.${ts}"; then
        REPLY="${1}.${ts}"
        prints "Backup created: $REPLY"
        return 0
    fi
    printe "Failed to create backup of '$1'"
    return 1
}

# Ask for confirmation (y/N, default No)
# Usage: confirm [question]   (default question: "Are you sure?")
# Example: confirm "Delete file?" && rm file
# Returns: 0 yes, 1 no, 2 invalid usage
confirm() {
    (( ARGC <= 1 )) || return 2
    yesno "${1:-Are you sure?}"
}

# Show arguments info (for debugging/learning)
# Usage: argsinfo <arg> [arg...]
# Returns: 0 success, 2 no arguments
argsinfo() {
    (( ARGC >= 1 )) || { printe "No arguments provided."; return 2 }

    print "Number of arguments: ${y}${ARGC}${x}"
    print "List of arguments:"

    local -i i=0
    local arg
    for arg in "$@"; do
        print -r -- "${y}#$(( ++i ))${x}: $arg"
    done
}

# Shell files tracking - keep at the end
zfile_track_end ${0:A}
