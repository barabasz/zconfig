#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Command information helper functions
# Used by zinfo, zwhere, zver

# Shell files tracking
zfile_track_start ${0:A}

# Get command path (resolves aliases)
# Usage: get_cmd_path <command>
# Returns: path to binary, or type info for non-binaries
# Sets: $REPLY with the result
get_cmd_path() {
    local cmd="$1"
    [[ -z "$cmd" ]] && { REPLY=""; return 1; }

    # Resolve alias to actual command
    local real_cmd="$cmd"
    if (( ${+aliases[$cmd]} )); then
        real_cmd="${aliases[$cmd]%% *}"
    fi

    # Try to get binary path
    local cmd_path
    cmd_path=$(whence -p "$real_cmd" 2>/dev/null)

    if [[ -n "$cmd_path" && -x "$cmd_path" ]]; then
        cmd_path="${cmd_path:A}"
        # Follow small wrapper scripts (e.g. Homebrew bin/ → libexec/ pattern)
        if [[ -f "$cmd_path" ]] && (( $(wc -c < "$cmd_path") < 1024 )); then
            local _exec_target
            _exec_target=$(grep -o 'exec "[^"]*"' "$cmd_path" 2>/dev/null)
            _exec_target="${_exec_target#exec \"}"
            _exec_target="${_exec_target%\"}"
            [[ -x "$_exec_target" ]] && cmd_path="$_exec_target"
        fi
        REPLY="$cmd_path"
        print -r -- "$REPLY"
        return 0
    fi

    # Check command type for non-binaries (use zsh string ops, not external commands)
    local whence_out=$(whence -w "$cmd" 2>/dev/null)
    local cmd_type="${whence_out##*: }"  # Extract type after ": "

    case "$cmd_type" in
        function)
            # Try to find function source
            local zsh_dir="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
            # 1. Check functions/ directory (autoloaded functions)
            if [[ -f "$zsh_dir/functions/$cmd" ]]; then
                REPLY="$zsh_dir/functions/$cmd"
                print -r -- "$REPLY"
                return 0
            fi
            # 2. Search in fpath
            local dir
            for dir in $fpath; do
                if [[ -f "$dir/$cmd" ]]; then
                    REPLY="$dir/$cmd"
                    print -r -- "$REPLY"
                    return 0
                fi
            done
            # 3. Search in lib/*.zsh files for function definition
            local lib_file
            lib_file=$(grep -l "^${cmd}[[:space:]]*(" "$zsh_dir"/lib/*.zsh 2>/dev/null)
            if [[ -n "$lib_file" ]]; then
                REPLY="$lib_file"
                print -r -- "$REPLY"
                return 0
            fi
            REPLY="function"
            print -r -- "$REPLY"
            return 0
            ;;
        alias)
            REPLY="alias: ${aliases[$cmd]}"
            print -r -- "$REPLY"
            return 0
            ;;
        builtin)
            REPLY="builtin"
            print -r -- "$REPLY"
            return 0
            ;;
        reserved)
            REPLY="reserved word"
            print -r -- "$REPLY"
            return 0
            ;;
        none|"")
            REPLY=""
            return 1
            ;;
        *)
            REPLY="$cmd_type"
            print -r -- "$REPLY"
            return 0
            ;;
    esac
}

# Get size of function definition in bytes
# Usage: get_func_size <function_name>
# Returns: size in bytes (calculated from function body)
# Sets: $REPLY with the result
get_func_size() {
    local cmd="$1"
    
    # Check if function exists in memory
    if (( ${+functions[$cmd]} )); then
        local func_body="${functions[$cmd]}"
        
        # Calculate size in bytes.
        # Note: ${#func_body} returns character count. For strict byte count
        # (considering multibyte chars), we use wc -c via a pipe.
        REPLY=$(print -rn -- "$func_body" | wc -c | tr -d '[:space:]')
        
        print -r -- "$REPLY"
        return 0
    fi

    REPLY=0
    print -r -- "$REPLY"
    return 1
}

# Get size of the command target in bytes
# Usage: get_cmd_size <command>
# Returns: size in bytes (file size for binaries, code size for functions)
# Sets: $REPLY with the result
# Dependencies: get_cmd_path, get_file_size, get_func_size
get_cmd_size() {
    local cmd="$1"
    [[ -z "$cmd" ]] && { REPLY=0; return 1; }

    # Resolve alias to actual command name first (needed for function lookup)
    local real_cmd="$cmd"
    if (( ${+aliases[$cmd]} )); then
        real_cmd="${aliases[$cmd]%% *}"
    fi

    # Use existing helper to resolve path or type
    # We suppress stdout because get_cmd_path prints the result,
    # but we only need the value set in $REPLY.
    get_cmd_path "$cmd" >/dev/null
    local target="$REPLY"

    # Case 1: Target is a file (binary, script, or function source file)
    # get_cmd_path returns the absolute path if found.
    if [[ -n "$target" && -f "$target" ]]; then
        # Follow small wrapper scripts (e.g. Homebrew bin/ → libexec/ pattern)
        if (( $(get_file_size "$target") < 1024 )); then
            local _exec_target
            _exec_target=$(grep -o 'exec "[^"]*"' "$target" 2>/dev/null)
            _exec_target="${_exec_target#exec \"}"
            _exec_target="${_exec_target%\"}"
            [[ -x "$_exec_target" ]] && target="$_exec_target"
        fi
        get_file_size "$target"
        return $?
    fi

    # Case 2: Target is a function loaded in memory without a tracked source file
    # (get_cmd_path returned "function")
    if [[ "$target" == "function" ]]; then
        get_func_size "$real_cmd"
        return $?
    fi

    # Case 3: Builtins, aliases (that don't resolve to files), reserved words
    # These effectively have 0 size in this context.
    REPLY=0
    print -r -- "$REPLY"
    return 1
}

# Get command version number
# Usage: get_cmd_version <command> [version_flag]
# Returns: version string or "unknown"
# Sets: $REPLY with the result
get_cmd_version() {
    local cmd="$1"
    local vercmd="$2"
    [[ -z "$cmd" ]] && { REPLY="unknown"; return 1; }

    # Resolve alias to actual command
    local real_cmd="$cmd"
    if (( ${+aliases[$cmd]} )); then
        real_cmd="${aliases[$cmd]%% *}"
    fi

    # Get binary path
    local cmd_path
    cmd_path=$(whence -p "$real_cmd" 2>/dev/null)

    if [[ -z "$cmd_path" || ! -x "$cmd_path" ]]; then
        # Maybe it's a zconfig function with version
        local zsh_dir="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
        if [[ -f "$zsh_dir/functions/$cmd" ]]; then
            local content=$(<"$zsh_dir/functions/$cmd")
            if [[ "$content" =~ '\[version\]="([^"]+)"' ]]; then
                REPLY="${match[1]}"
                print -r -- "$REPLY"
                return 0
            fi
        fi
        REPLY="unknown"
        print -r -- "$REPLY"
        return 1
    fi

    local output="" version=""

    # If explicit version flag provided, use it
    if [[ -n "$vercmd" ]]; then
        output=$("$cmd_path" "$vercmd" 2>&1)
        version=$(get_version "$output")
        REPLY="${version:-unknown}"
        print -r -- "$REPLY"
        return 0
    fi

    # Auto-detect: try common version flags
    local -a version_flags=("--version" "-v" "-V" "version" "-version")

    for flag in "${version_flags[@]}"; do
        output=$("$cmd_path" "$flag" 2>&1)
        if [[ $? -eq 0 || "$output" == *[0-9].[0-9]* ]]; then
            version=$(get_version "$output")
            if [[ -n "$version" ]]; then
                REPLY="$version"
                print -r -- "$REPLY"
                return 0
            fi
        fi
    done

    # Last resort: try running command with no args (limit to first 5 lines, no external head)
    output=$("$cmd_path" 2>&1)
    output="${(F)${(f)output}[1,5]}"  # Split by newlines, take first 5, rejoin
    version=$(get_version "$output")

    REPLY="${version:-unknown}"
    print -r -- "$REPLY"
    [[ -n "$version" ]] && return 0 || return 1
}

# Get path to the manual page file
# Usage: get_cmd_manpath <command>
# Returns: path to the man page file (e.g., /usr/share/man/man1/ls.1.gz)
# Sets: $REPLY with the result
get_cmd_manpath() {
    local cmd="$1"
    [[ -z "$cmd" ]] && { REPLY=""; return 1; }

    # Resolve alias to actual command
    local real_cmd="$cmd"
    if (( ${+aliases[$cmd]} )); then
        real_cmd="${aliases[$cmd]%% *}"
    fi

    # Use 'man -w' to locate the file.
    # This works on both Linux (man-db) and macOS (mandoc).
    # We redirect stderr to suppress "No manual entry for..." messages.
    local man_path
    man_path=$(man -w "$real_cmd" 2>/dev/null)

    if [[ -n "$man_path" && -f "$man_path" ]]; then
        REPLY="$man_path"
        print -r -- "$REPLY"
        return 0
    fi

    # Fallback/Fail
    REPLY=""
    return 1
}

# Get one-line description of a command
# Usage: get_cmd_info <command> [mode]
#   mode: "all" (default) - try all sources
#         "local" - only fast zconfig lookup (no external commands)
# Returns: description string or "No description available"
# Sets: $REPLY with description, $reply[1] with source name
get_cmd_info() {
    local cmd="$1"
    local mode="${2:-all}"
    [[ -z "$cmd" ]] && { REPLY="No description available"; reply=(""); return 1; }

    local zsh_dir="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
    local description="" source_name=""

    # Resolve alias for external lookups
    local real_cmd="$cmd"
    if (( ${+aliases[$cmd]} )); then
        real_cmd="${aliases[$cmd]%% *}"
    fi

    # Resolve command path (with symlink resolution) for brew/apt checks
    local cmd_path=$(whence -p "$real_cmd" 2>/dev/null)
    [[ -n "$cmd_path" ]] && cmd_path="${cmd_path:A}"

    # Source 1: zconfig functions (functions/ with _fn metadata, lib/ with comments)
    _info_try_zconfig() {
        local func_dir="$zsh_dir/functions"
        local lib_dir="$zsh_dir/lib"

        # Check functions/ directory (autoloaded functions with _fn metadata)
        if [[ -f "$func_dir/$cmd" ]]; then
            local content=$(<"$func_dir/$cmd")
            if [[ "$content" =~ '\[info\]="([^"]+)"' ]]; then
                description="${match[1]}"
                source_name="zconfig"
                return 0
            fi
        fi

        # Check lib/*.zsh files (first comment line above function definition)
        # Only if command is a loaded function (skip for binaries/aliases)
        if (( ${+functions[$cmd]} )); then
            local _lib_file
            _lib_file=$(grep -l "^${cmd}[[:space:]]*(" "$lib_dir"/*.zsh 2>/dev/null)
            if [[ -n "$_lib_file" ]]; then
                local _line
                local -a _cblock=()
                while IFS= read -r _line; do
                    if [[ "$_line" =~ "^${cmd}\\s*\\(\\)" ]]; then
                        if (( ${#_cblock} > 0 )); then
                            local _desc="${_cblock[1]#\#}"
                            _desc="${_desc# }"
                            if [[ -n "$_desc" ]]; then
                                description="$_desc"
                                source_name="zconfig"
                                return 0
                            fi
                        fi
                        break
                    elif [[ "$_line" == \#* ]]; then
                        _cblock+=("$_line")
                    else
                        _cblock=()
                    fi
                done < "$_lib_file"
            fi
        fi
        return 1
    }

    # Source 2: brew info (only for Homebrew-installed commands)
    _info_try_brew() {
        [[ -n "$HOMEBREW_PREFIX" && "$cmd_path" == ${HOMEBREW_PREFIX}/Cellar/* ]] || return 1
        # Extract formula name from Cellar path
        local formula="${cmd_path#${HOMEBREW_PREFIX}/Cellar/}"
        formula="${formula%%/*}"
        [[ -n "$formula" ]] || return 1

        local output
        output=$(brew info "$formula" 2>/dev/null) || return 1

        local line_num=0
        local line
        while IFS= read -r line; do
            ((line_num++))
            if (( line_num == 2 )); then
                [[ -n "$line" && "$line" != "Not installed" ]] || return 1
                description="$line"
                source_name="brew"
                return 0
            fi
        done <<< "$output"
        return 1
    }

    # Source 3: apt show (only on Debian-based systems)
    _info_try_apt() {
        is_debian_based || return 1
        command -v apt &>/dev/null || return 1

        local output
        output=$(apt show "$real_cmd" 2>/dev/null) || return 1

        local line
        while IFS= read -r line; do
            if [[ "$line" == "Description: "* ]]; then
                description="${line#Description: }"
                description="${(U)description[1]}${description[2,-1]}"
                source_name="apt"
                return 0
            fi
        done <<< "$output"
        return 1
    }

    # Source 4: tldr (fallback)
    _info_try_tldr() {
        command -v tldr &>/dev/null || return 1
        local output
        output=$(tldr "$real_cmd" 2>/dev/null) || return 1

        local line in_desc=0
        while IFS= read -r line; do
            line="${line#"${line%%[![:space:]]*}"}"
            [[ -z "$line" ]] && continue
            [[ "$line" == "$real_cmd" ]] && { in_desc=1; continue; }
            if (( in_desc )); then
                # Skip tldr disambiguation pages
                [[ "$line" == *"can refer to"* ]] && return 1
                description="${line%.}"
                source_name="tldr"
                return 0
            fi
        done <<< "$output"
        return 1
    }

    # Try sources in order: zconfig (local) → tldr (fast) → brew/apt (slow, fallback)
    if [[ "$mode" == "local" ]]; then
        _info_try_zconfig
    else
        _info_try_zconfig || _info_try_tldr || _info_try_brew || _info_try_apt
    fi

    if [[ -n "$description" ]]; then
        REPLY="$description"
        reply=("$source_name")
        print -r -- "$REPLY"
        return 0
    else
        REPLY="No description available"
        reply=("")
        print -r -- "$REPLY"
        return 1
    fi
}

# Shell files tracking
zfile_track_end ${0:A}
