#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# Command information helper functions (used by zinfo, zwhere, zver)
# All functions set REPLY and also print the result.
# Depends on: files.zsh (get_file_size), strings.zsh (get_version),
#             system.zsh (is_debian_based), zsh/parameter (functions_source)
##

## Internal helpers

# Resolve an alias to the command it runs (internal)
# Usage: _cmd_unalias <command>
# Output: none; sets REPLY to the first word of the alias, or the command itself
_cmd_unalias() {
    if (( ${+aliases[$1]} )); then
        REPLY=${${(z)aliases[$1]}[1]}
    else
        REPLY=$1
    fi
}

# Follow a small wrapper script to its exec target (internal)
# Homebrew and others install bin/ scripts that only `exec "/path/libexec/..."`.
# Usage: _cmd_follow_wrapper <path>
# Output: none; sets REPLY to the target, or the original path
_cmd_follow_wrapper() {
    REPLY=$1
    [[ -f $1 && -r $1 ]] || return 0
    local -a size
    zstat -A size +size -- "$1" 2>/dev/null || return 0
    (( size[1] < 1024 )) || return 0
    local content=$(<$1)
    if [[ $content =~ 'exec "([^"]+)"' && -x $match[1] ]]; then
        REPLY=$match[1]
    fi
}

# Find the file that defines a function (internal)
# Uses $functions_source (zsh/parameter), with a lib/ scan as fallback.
# Usage: _cmd_func_file <function>
# Output: none; sets REPLY to the file path (empty if unknown)
# Returns: 0 found, 1 not found
_cmd_func_file() {
    setopt localoptions extendedglob
    REPLY=""
    local zsh_dir=${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}
    local src=${functions_source[$1]}
    if [[ -n $src && -f $src ]]; then
        REPLY=$src
        return 0
    fi
    # Autoloaded function files: zconfig functions/ first, then fpath
    local dir
    for dir in $zsh_dir/functions $fpath; do
        [[ -f $dir/$1 ]] && { REPLY=$dir/$1; return 0 }
    done
    # Function defined in lib/: literal match on "name() {" or "name () {"
    local file line
    for file in $zsh_dir/lib/*.zsh(N.); do
        for line in "${(@f)$(<$file)}"; do
            # (b) escapes pattern characters, so names like g++ are safe
            [[ $line == ${(b)1}[[:space:]]#\(\)* ]] && { REPLY=$file; return 0 }
        done
    done
    return 1
}

## Location and size

# Get command path (resolves aliases and wrapper scripts)
# Usage: get_cmd_path <command>
# Output: path to binary or source file, or type ("builtin", "alias: ...", "function")
#         (stdout); also sets REPLY
# Returns: 0 success, 1 command not found, 2 invalid usage
get_cmd_path() {
    (( ARGC == 1 )) || return 2
    local cmd=$1
    _cmd_unalias "$cmd"
    local real_cmd=$REPLY
    REPLY=""

    # External command: (( ${+commands[x]} )) avoids a fork
    if (( ${+commands[$real_cmd]} )) && [[ -x ${commands[$real_cmd]} ]]; then
        _cmd_follow_wrapper "${commands[$real_cmd]:A}"
        print -r -- "$REPLY"
        return 0
    fi

    local cmd_type=${"$(whence -w -- "$cmd" 2>/dev/null)"##*: }
    case $cmd_type in
        function)
            _cmd_func_file "$cmd" || REPLY=function
            ;;
        alias)    REPLY="alias: ${aliases[$cmd]}" ;;
        builtin)  REPLY=builtin ;;
        reserved) REPLY="reserved word" ;;
        none|"")  return 1 ;;
        *)        REPLY=$cmd_type ;;
    esac
    print -r -- "$REPLY"
}

# Get size of a function definition in bytes
# Usage: get_func_size <function>
# Output: size in bytes (stdout); also sets REPLY
# Returns: 0 success, 1 function not defined, 2 invalid usage
get_func_size() {
    (( ARGC == 1 )) || return 2
    if (( ! ${+functions[$1]} )); then
        REPLY=0
        print -r -- "$REPLY"
        return 1
    fi
    # nomultibyte: ${#var} counts bytes instead of characters (no wc fork)
    setopt localoptions nomultibyte
    REPLY=${#functions[$1]}
    print -r -- "$REPLY"
}

# Get size of the command target in bytes
# File size for binaries and scripts, code size for functions without a file
# Usage: get_cmd_size <command>
# Output: size in bytes (stdout); also sets REPLY
# Returns: 0 success, 1 no size (builtin, alias, not found), 2 invalid usage
get_cmd_size() {
    (( ARGC == 1 )) || return 2
    _cmd_unalias "$1"
    local real_cmd=$REPLY

    # get_cmd_path already follows wrapper scripts
    get_cmd_path "$1" >/dev/null
    local target=$REPLY

    if [[ -n $target && -f $target ]]; then
        get_file_size "$target"
        return
    fi
    if [[ $target == function ]]; then
        get_func_size "$real_cmd"
        return
    fi
    REPLY=0
    print -r -- "$REPLY"
    return 1
}

# Get path to the manual page file
# Usage: get_cmd_manpath <command>
# Output: path, e.g. /usr/share/man/man1/ls.1.gz (stdout); also sets REPLY
# Returns: 0 success, 1 no manual page, 2 invalid usage
get_cmd_manpath() {
    (( ARGC == 1 )) || return 2
    _cmd_unalias "$1"
    # man -w works on Linux (man-db) and macOS (mandoc)
    local man_path
    man_path=$(command man -w "$REPLY" 2>/dev/null)
    REPLY=""
    [[ -n $man_path && -f ${man_path%%$'\n'*} ]] || return 1
    REPLY=${man_path%%$'\n'*}
    print -r -- "$REPLY"
}

## Version

# Get command version number
# Only well-known version flags are tried; stdin is /dev/null and each try is
# limited by `timeout` (when available), so interactive commands cannot hang.
# Usage: get_cmd_version <command> [version_flag]
# Output: version string or "unknown" (stdout); also sets REPLY
# Returns: 0 success, 1 version not found, 2 invalid usage
get_cmd_version() {
    (( ARGC >= 1 && ARGC <= 2 )) || return 2
    local cmd=$1 version_flag=$2
    _cmd_unalias "$cmd"
    local real_cmd=$REPLY
    local cmd_path=${commands[$real_cmd]}

    if [[ -z $cmd_path || ! -x $cmd_path ]]; then
        # Maybe it is a zconfig function with _fn metadata
        local func_file=${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/functions/$cmd
        if [[ -f $func_file && "$(<$func_file)" =~ '\[version\]="([^"]+)"' ]]; then
            REPLY=$match[1]
            print -r -- "$REPLY"
            return 0
        fi
        REPLY=unknown
        print -r -- "$REPLY"
        return 1
    fi

    local -a runner=()
    if (( ${+commands[timeout]} )); then
        runner=(timeout 3)
    elif (( ${+commands[gtimeout]} )); then
        runner=(gtimeout 3)
    fi

    local -a flags=(--version -V version -version -v)
    [[ -n $version_flag ]] && flags=("$version_flag")
    local flag output
    local -a lines
    for flag in $flags; do
        output=$($runner "$cmd_path" "$flag" </dev/null 2>&1) || [[ $output == *[0-9].[0-9]* ]] || continue
        # Look only at the first 5 lines (an array, so [1,5] counts lines, not characters)
        lines=("${(@f)output}")
        if get_version "${(F)lines[1,5]}" >/dev/null; then
            print -r -- "$REPLY"
            return 0
        fi
    done

    REPLY=unknown
    print -r -- "$REPLY"
    return 1
}

## Description

# The _cmdinfo_try_* helpers below are called only from get_cmd_info and use
# its local variables through dynamic scoping: cmd, real_cmd, cmd_path, zsh_dir
# (read) and description, source_name (set on success).

# Source 1: zconfig functions/ (_fn metadata) or lib/ (comment above definition) (internal)
# Usage: _cmdinfo_try_zconfig
# Returns: 0 found, 1 not found
_cmdinfo_try_zconfig() {
    local func_file=$zsh_dir/functions/$cmd
    if [[ -f $func_file && "$(<$func_file)" =~ '\[info\]="([^"]+)"' ]]; then
        description=$match[1]
        source_name=zconfig
        return 0
    fi

    # Only for loaded functions (skip binaries/aliases)
    (( ${+functions[$cmd]} )) || return 1
    _cmd_func_file "$cmd" || return 1
    [[ $REPLY == *.zsh ]] || return 1

    # First line of the comment block directly above "name() {"
    setopt localoptions extendedglob
    local line
    local -a block=()
    for line in "${(@f)$(<$REPLY)}"; do
        if [[ $line == ${(b)cmd}[[:space:]]#\(\)* ]]; then
            (( ${#block} )) || return 1
            description=${${block[1]#\#}# }
            [[ -n $description ]] || return 1
            source_name=zconfig
            return 0
        elif [[ $line == \#* ]]; then
            block+=("$line")
        else
            block=()
        fi
    done
    return 1
}

# Source 2: brew info, only for Homebrew-installed commands (internal)
# Usage: _cmdinfo_try_brew
# Returns: 0 found, 1 not found
_cmdinfo_try_brew() {
    [[ -n $HOMEBREW_PREFIX && $cmd_path == $HOMEBREW_PREFIX/Cellar/* ]] || return 1
    # Formula name is the first directory under Cellar/
    local formula=${${cmd_path#$HOMEBREW_PREFIX/Cellar/}%%/*}
    [[ -n $formula ]] || return 1
    local output
    output=$(brew info "$formula" 2>/dev/null) || return 1
    local -a lines=("${(@f)output}")
    local line=${lines[2]}
    [[ -n $line && $line != "Not installed" ]] || return 1
    description=$line
    source_name=brew
}

# Source 3: apt show, only on Debian-based systems (internal)
# Usage: _cmdinfo_try_apt
# Returns: 0 found, 1 not found
_cmdinfo_try_apt() {
    is_debian_based && (( ${+commands[apt]} )) || return 1
    local output line
    output=$(command apt show "$real_cmd" 2>/dev/null) || return 1
    for line in "${(@f)output}"; do
        if [[ $line == "Description: "* ]]; then
            description=${line#Description: }
            description="${(U)description[1]}${description[2,-1]}"
            source_name=apt
            return 0
        fi
    done
    return 1
}

# Source 4: tldr page (internal)
# Usage: _cmdinfo_try_tldr
# Returns: 0 found, 1 not found
_cmdinfo_try_tldr() {
    (( ${+commands[tldr]} )) || return 1
    local output line
    local -i in_desc=0
    output=$(command tldr "$real_cmd" 2>/dev/null) || return 1
    for line in "${(@f)output}"; do
        line=${line##[[:space:]]#}
        [[ -z $line ]] && continue
        if [[ $line == $real_cmd ]]; then
            in_desc=1
            continue
        fi
        if (( in_desc )); then
            # Skip tldr disambiguation pages
            [[ $line == *"can refer to"* ]] && return 1
            description=${line%.}
            source_name=tldr
            return 0
        fi
    done
    return 1
}

# Get one-line description of a command
# Sources in order: zconfig (local) → tldr (fast) → brew/apt (slow)
# Usage: get_cmd_info <command> [all|local]   (local: zconfig lookup only)
# Output: description or "No description available" (stdout);
#         also sets REPLY (description) and reply[1] (source name)
# Returns: 0 found, 1 not found, 2 invalid usage
get_cmd_info() {
    (( ARGC >= 1 && ARGC <= 2 )) || return 2
    setopt localoptions extendedglob
    local cmd=$1 mode=${2:-all}
    [[ $mode == (all|local) ]] || return 2
    local zsh_dir=${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}
    local description="" source_name=""

    _cmd_unalias "$cmd"
    local real_cmd=$REPLY
    local cmd_path=${commands[$real_cmd]}
    [[ -n $cmd_path ]] && cmd_path=${cmd_path:A}

    if [[ $mode == local ]]; then
        _cmdinfo_try_zconfig
    else
        _cmdinfo_try_zconfig || _cmdinfo_try_tldr || _cmdinfo_try_brew || _cmdinfo_try_apt
    fi

    if [[ -n $description ]]; then
        REPLY=$description
        reply=("$source_name")
        print -r -- "$REPLY"
        return 0
    fi
    REPLY="No description available"
    reply=("")
    print -r -- "$REPLY"
    return 1
}

# Shell files tracking - keep at the end
zfile_track_end ${0:A}
