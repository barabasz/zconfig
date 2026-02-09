#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Command information helper functions
# Used by zinfo, zwhere, zver

# Shell files tracking
zfile_track_start ${0:A}

# =============================================================================
# get_cmd_path - Get command path (resolves aliases)
# =============================================================================
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
            if [[ -f "$zsh_dir/functions/$cmd" ]]; then
                REPLY="$zsh_dir/functions/$cmd"
                print -r -- "$REPLY"
                return 0
            fi
            # Search in fpath
            local dir
            for dir in $fpath; do
                if [[ -f "$dir/$cmd" ]]; then
                    REPLY="$dir/$cmd"
                    print -r -- "$REPLY"
                    return 0
                fi
            done
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

# =============================================================================
# get_cmd_version - Get command version number
# =============================================================================
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

# =============================================================================
# get_cmd_info - Get one-line description of a command
# =============================================================================
# Usage: get_cmd_info <command>
# Returns: description string or "No description available"
# Sets: $REPLY with description, $reply[1] with source name
get_cmd_info() {
    local cmd="$1"
    [[ -z "$cmd" ]] && { REPLY="No description available"; reply=(""); return 1; }

    local zsh_dir="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
    local description="" source_name=""

    # Resolve alias for external lookups
    local real_cmd="$cmd"
    if (( ${+aliases[$cmd]} )); then
        real_cmd="${aliases[$cmd]%% *}"
    fi

    # Source 1: zconfig functions
    _info_try_zconfig() {
        local func_dir="$zsh_dir/functions"
        local lib_dir="$zsh_dir/lib"

        if [[ -f "$func_dir/$cmd" ]]; then
            local content=$(<"$func_dir/$cmd")
            if [[ "$content" =~ '\[info\]="([^"]+)"' ]]; then
                description="${match[1]}"
                source_name="zconfig"
                return 0
            fi
        fi

        local file line
        local -a comment_block=()
        for file in "$lib_dir"/*.zsh(.N); do
            comment_block=()
            while IFS= read -r line; do
                if [[ "$line" =~ "^${cmd}\\s*\\(\\)" ]]; then
                    for cmt in "${comment_block[@]}"; do
                        cmt="${cmt#\#}"
                        cmt="${cmt# }"
                        if [[ -n "$cmt" ]]; then
                            description="$cmt"
                            source_name="zconfig"
                            return 0
                        fi
                    done
                elif [[ "$line" == \#* ]]; then
                    comment_block+=("$line")
                else
                    comment_block=()
                fi
            done < "$file"
        done
        return 1
    }

    # Source 2: tldr
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
                description="${line%.}"
                source_name="tldr"
                return 0
            fi
        done <<< "$output"
        return 1
    }

    # Source 3: whatis
    _info_try_whatis() {
        command -v whatis &>/dev/null || return 1
        local output
        output=$(whatis "$real_cmd" 2>/dev/null) || return 1

        local line
        while IFS= read -r line; do
            if [[ "$line" =~ "^${real_cmd}[,(]" || "$line" =~ "^${real_cmd} " ]]; then
                if [[ "$line" == *" - "* ]]; then
                    description="${line#* - }"
                    description="${(U)description[1]}${description[2,-1]}"
                    source_name="whatis"
                    return 0
                fi
            fi
        done <<< "$output"
        return 1
    }

    # Source 4: brew info
    _info_try_brew() {
        command -v brew &>/dev/null || return 1
        local output
        output=$(brew info "$real_cmd" 2>/dev/null) || return 1

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

    # Source 5: apt show
    _info_try_apt() {
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

    # Try sources in order
    _info_try_zconfig || _info_try_tldr || _info_try_whatis || _info_try_brew || _info_try_apt

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
