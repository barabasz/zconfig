#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# Shell related functions
# Depends on: print.zsh (for output), system.zsh (for os detection)

# --- Information ---

# Get Zsh version
# Usage: shell_ver
# Returns: version number (e.g., "5.9")
shell_ver() {
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

# Get shell level (nesting depth)
# Usage: shell_level
# Returns: nesting level number (1 = top level)
shell_level() {
    print -- ${SHLVL:-1}
}

# Get parent process name
# Usage: parent_process
# Returns: name of parent process
parent_process() {
    # Method 1: Linux /proc (Fastest)
    if [[ -r "/proc/$PPID/comm" ]]; then
        cat "/proc/$PPID/comm"
        return
    fi
    
    # Method 2: ps command (Portable: macOS/BSD/Linux)
    # -p: pid, -o: output format (comm= removes header)
    command ps -p $PPID -o comm= 2>/dev/null
}

# --- State Checks ---

# Check if running in interactive shell
# Usage: is_interactive
is_interactive() {
    [[ -o interactive ]]
}

# Check if running in login shell
# Usage: is_login_shell
is_login_shell() {
    [[ -o login ]]
}

# Check if running inside a subshell
# Usage: is_subshell
is_subshell() {
    (( ZSH_SUBSHELL > 0 ))
}

# Check if script is being sourced (not executed directly)
# Usage: is_sourced
is_sourced() {
    # (%):-%N expands to the name of the script/function being executed.
    # $0 is the name of the shell or script.
    # If they differ, or if ZSH_EVAL_CONTEXT indicates sourcing, it's sourced.
    [[ "${(%):-%N}" != "$0" ]] || [[ "$ZSH_EVAL_CONTEXT" == *"file"* ]]
}

# Check if running as root
# Usage: is_root 
# Returns: 0 when root, 1 otherwise, 2 on invalid usage
is_root() {
    (( ARGC == 0 )) || return 2
    (( EUID == 0 ))
}

# Check if running under tmux
# Usage: is_tmux
# Returns: 0 when in tmux, 1 otherwise, 2 on invalid usage
is_tmux() {
    (( ARGC == 0 )) || return 2
    [[ -n "$TMUX" ]]
}

# Check if running under screen
# Usage: is_screen
is_screen() {
    [[ -n "$STY" ]]
}

# Check if running via SSH
# Usage: is_ssh
is_ssh() {
    [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" || -n "$SSH_CONNECTION" ]]
}

# --- Configuration & Management ---

# Get default shell for current user
# Usage: get_default_shell
# Returns: path to default shell
get_default_shell() {
    if is_macos; then
        # dscl is standard on macOS. Safer than parsing /etc/passwd directly.
        local record
        record=$(command dscl . -read /Users/$USER UserShell 2>/dev/null)
        # Output: "UserShell: /bin/zsh". We strip the key.
        print -- ${record##* }
    elif is_linux; then
        # getent respects LDAP/NIS/local
        local ent
        if ent=$(getent passwd "$USER"); then
            # Get last field (shell)
            print -- ${ent##*:}
        fi
    fi
}

# Set default shell for current user
# Usage: set_default_shell /path/to/shell
set_default_shell() {
    (( ARGC == 1 )) || return 1
    local new_shell="$1"

    # Validation
    if [[ ! -x "$new_shell" ]]; then
        printe "Shell '$new_shell' not executable or found."
        return 1
    fi

    # Check /etc/shells (Pure Zsh read)
    local -a valid_shells=("${(@f)$(</etc/shells)}")
    if (( ${valid_shells[(Ie)$new_shell]} == 0 )); then
        printe "Shell '$new_shell' is not listed in /etc/shells."
        printi "Add it to /etc/shells first (requires sudo)."
        return 1
    fi

    # Execute change
    if (( ${+commands[chsh]} )); then
        printi "Changing shell to $new_shell (password may be required)..."
        if chsh -s "$new_shell"; then
            prints "Default shell changed. Please re-login."
        else
            printe "Failed to change shell."
            return 1
        fi
    else
        printe "'chsh' command not found."
        return 1
    fi
}

# Get available shells from /etc/shells
# Usage: get_available_shells
get_available_shells() {
    [[ -f /etc/shells ]] || return 1
    local -a lines=("${(@f)$(</etc/shells)}")
    # Filter comments (#*) and empty lines via Zsh expansion
    print -l -- ${${lines:#\#*}:#^}
}

# Reload current shell configuration
# Usage: reload_shell
reload_shell() {
    printi "Reloading Zsh configuration..."
    # exec replaces current process. -l simulates login shell.
    exec zsh -l
}

# --- Terminal Info ---

# Get terminal type
# Usage: terminal_type
terminal_type() {
    print -- "${TERM:-unknown}"
}

# Check if terminal supports colors
# Usage: is_color_terminal
is_color_terminal() {
    [[ -t 1 && -n "$TERM" && "$TERM" != "dumb" ]]
}

# Get number of terminal columns
# Usage: terminal_columns
terminal_columns() {
    print -- ${COLUMNS:-80}
}

# Get number of terminal lines
# Usage: terminal_lines
terminal_lines() {
    print -- ${LINES:-24}
}

# Shell files tracking - keep at the end
zfile_track_end ${0:A}