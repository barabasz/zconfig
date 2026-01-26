#!/bin/zsh
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# Shell related functions
# Depends on: print.zsh (for output), system.zsh (for os detection)

# Get Zsh version
# Usage: shell_ver
# Returns: version number (e.g., "5.9")
shell_ver() {
    # Use internal variable instead of spawning a process
    print -- $ZSH_VERSION
}

# Get current shell name
# Usage: shell_name
# Returns: shell name (e.g., "zsh")
shell_name() {
    print -- $ZSH_NAME
}

# Get full shell path (environment variable)
# Usage: shell_path
# Returns: full path to current shell
shell_path() {
    print -- $SHELL
}

# Get default shell for current user
# Usage: get_default_shell
# Returns: path to default shell
get_default_shell() {
    if is_macos; then
        # dscl is unavoidable on macOS
        # specific path /Users/$USER is safer than ~/ expansion here
        local record
        record=$(dscl . -read /Users/$USER UserShell 2>/dev/null)
        # Parse output "UserShell: /bin/zsh" using Zsh expansion
        print -- ${record##* }
    elif is_linux; then
        # Use getent, but parse with Zsh expansion instead of cut
        local ent
        if ent=$(getent passwd "$USER"); then
            # Get everything after the last colon
            print -- ${ent##*:}
        fi
    fi
}

# Set default shell for current user
# Usage: set_default_shell /path/to/shell
# Returns: 0 on success, 1 on failure
set_default_shell() {
    (( ARGC == 1 )) || return 1
    local new_shell="$1"

    # Check executable permissions
    if [[ ! -x "$new_shell" ]]; then
        printe "Shell '$new_shell' does not exist or is not executable"
        return 1
    fi

    # Check if shell is in /etc/shells using pure Zsh reading
    # (f) splits by line, check if new_shell is in the array
    local -a valid_shells=("${(@f)$(</etc/shells)}")
    if (( ${valid_shells[(Ie)$new_shell]} == 0 )); then
        printe "Shell '$new_shell' is not in /etc/shells"
        return 1
    fi

    # Change shell
    if command -v chsh >/dev/null; then
        if chsh -s "$new_shell"; then
            prints "Default shell changed to: $new_shell"
        else
            printe "Failed to change shell"
            return 1
        fi
    else
        printe "'chsh' command not found."
        return 1
    fi
}

# Check if running in interactive shell
# Usage: is_interactive
# Returns: 0 (true) or 1 (false)
is_interactive() {
    [[ -o interactive ]]
}

# Check if running in login shell
# Usage: is_login_shell
# Returns: 0 (true) or 1 (false)
is_login_shell() {
    [[ -o login ]]
}

# Check if running inside a subshell
# Usage: is_subshell
# Returns: 0 (true) or 1 (false)
is_subshell() {
    (( ZSH_SUBSHELL > 0 ))
}

# Check if script is being sourced (not executed directly)
# Usage: is_sourced
# Returns: 0 (true) or 1 (false)
is_sourced() {
    # If the name of the script ($0) is the same as zsh, it's likely sourced inside interactive
    # Or check zsh_eval_context
    [[ "$ZSH_EVAL_CONTEXT" == *"file"* || "$ZSH_EVAL_CONTEXT" == *"toplevel"* ]] && [[ "${0:t}" == "zsh" || "${0:t}" == "zsh-session" ]]
}

# Get shell level (nesting depth)
# Usage: shell_level
# Returns: nesting level number
shell_level() {
    print -- ${SHLVL:-1}
}
# Measure shell startup times
# Usage: shell_speed
# Returns: time taken to start a shell
shell_speed() {
    print -n "${y}Non-interactive:${x} "
    etime zsh -c exit
    print -n "${y}Interactive:${x}     "
    etime zsh -i -c exit
}

# Get terminal type
# Usage: terminal_type
# Returns: terminal type (e.g., "xterm-256color")
terminal_type() {
    print -- "${TERM:-unknown}"
}

# Check if terminal supports colors
# Usage: is_color_terminal
# Returns: 0 (true) or 1 (false)
is_color_terminal() {
    # Check if stdout is a terminal AND TERM is set and not "dumb"
    [[ -t 1 && -n "$TERM" && "$TERM" != "dumb" ]]
}

# Get number of terminal columns
# Usage: terminal_columns
# Returns: number of columns
terminal_columns() {
    # Zsh maintains COLUMNS automatically
    print -- ${COLUMNS:-80}
}

# Get number of terminal lines
# Usage: terminal_lines
# Returns: number of lines
terminal_lines() {
    # Zsh maintains LINES automatically
    print -- ${LINES:-24}
}

# Get available shells from /etc/shells
# Usage: get_available_shells
# Returns: list of available shells
get_available_shells() {
    [[ -f /etc/shells ]] || return 1
    
    local -a lines=("${(@f)$(</etc/shells)}")
    # Filter out comments (#*) and empty lines. 
    # :#^ matches lines that DO NOT match empty string (removes empty lines)
    print -l -- ${${lines:#\#*}:#^}
}

# Check if running under tmux
# Usage: is_tmux
# Returns: 0 (true) or 1 (false)
is_tmux() {
    [[ -n "$TMUX" ]]
}

# Check if running under screen
# Usage: is_screen
# Returns: 0 (true) or 1 (false)
is_screen() {
    [[ -n "$STY" ]]
}

# Get parent process name
# Usage: parent_process
# Returns: name of parent process
parent_process() {
    # Attempt to read from /proc (Linux - fast)
    if [[ -r "/proc/$PPID/comm" ]]; then
        cat "/proc/$PPID/comm"
    else
        # Fallback to ps (portable but slower)
        ps -p $PPID -o comm= 2>/dev/null || print "unknown"
    fi
}

# Reload current shell configuration
# Usage: reload_shell
reload_shell() {
    printi "Reloading zsh configuration..."
    # exec replaces the current process with a new one.
    # This forces a reload of .zshenv AND .zshrc, and clears old state.
    exec zsh
}

# shell files tracking - keep at the end
zfile_track_end ${0:A}