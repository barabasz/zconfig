#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# Shell and terminal related functions
# Depends on: print.zsh (output), system.zsh (OS detection), zsh/terminfo
##

## Information

# Get zsh version
# Usage: shell_version
# Output: version number, e.g. "5.9" (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
shell_version() {
    (( ARGC == 0 )) || return 2
    REPLY=$ZSH_VERSION
    print -r -- "$REPLY"
}
# Alias: shell_ver (old name)
functions[shell_ver]=$functions[shell_version]

# Get current shell name
# Usage: shell_name
# Output: shell name, e.g. "zsh" (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
shell_name() {
    (( ARGC == 0 )) || return 2
    REPLY=$ZSH_NAME
    print -r -- "$REPLY"
}

# Get login shell path ($SHELL environment variable)
# Usage: shell_path
# Output: full path (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
shell_path() {
    (( ARGC == 0 )) || return 2
    REPLY=$SHELL
    print -r -- "$REPLY"
}

# Get shell level (nesting depth)
# Usage: shell_level
# Output: nesting level, 1 = top level (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
shell_level() {
    (( ARGC == 0 )) || return 2
    REPLY=${SHLVL:-1}
    print -r -- "$REPLY"
}

# Get parent process name
# Usage: parent_process
# Output: process name (stdout); also sets REPLY
# Returns: 0 success, 1 unknown, 2 invalid usage
parent_process() {
    (( ARGC == 0 )) || return 2
    if [[ -r /proc/$PPID/comm ]]; then
        # Linux: read /proc directly (no fork)
        REPLY=$(</proc/$PPID/comm)
    else
        # macOS/BSD: ps (comm= removes the header)
        REPLY=$(command ps -p $PPID -o comm= 2>/dev/null)
        REPLY=${REPLY:t}
    fi
    [[ -n $REPLY ]] || return 1
    print -r -- "$REPLY"
}

## State checks

# Check if running in interactive shell
# Usage: is_interactive
# Returns: 0 true, 1 false, 2 invalid usage
is_interactive() {
    (( ARGC == 0 )) || return 2
    [[ -o interactive ]]
}

# Check if running in login shell
# Usage: is_login_shell
# Returns: 0 true, 1 false, 2 invalid usage
is_login_shell() {
    (( ARGC == 0 )) || return 2
    [[ -o login ]]
}

# Check if running inside a subshell
# Usage: is_subshell
# Returns: 0 true, 1 false, 2 invalid usage
is_subshell() {
    (( ARGC == 0 )) || return 2
    (( ZSH_SUBSHELL > 0 ))
}

# Check if the calling code is being sourced (not executed directly)
# ZSH_EVAL_CONTEXT lists the evaluation stack, e.g. "toplevel:file:shfunc"
# when a function is called from a sourced file.
# Usage: is_sourced
# Returns: 0 true, 1 false, 2 invalid usage
is_sourced() {
    (( ARGC == 0 )) || return 2
    [[ $ZSH_EVAL_CONTEXT == *:file* ]]
}

# Check if running as root
# Usage: is_root
# Returns: 0 true, 1 false, 2 invalid usage
is_root() {
    (( ARGC == 0 )) || return 2
    (( EUID == 0 ))
}

# Check if running under tmux
# Usage: is_tmux
# Returns: 0 true, 1 false, 2 invalid usage
is_tmux() {
    (( ARGC == 0 )) || return 2
    [[ -n $TMUX ]]
}

# Check if running under GNU screen
# Usage: is_screen
# Returns: 0 true, 1 false, 2 invalid usage
is_screen() {
    (( ARGC == 0 )) || return 2
    [[ -n $STY ]]
}

# Check if running via SSH
# Usage: is_ssh
# Returns: 0 true, 1 false, 2 invalid usage
is_ssh() {
    (( ARGC == 0 )) || return 2
    [[ -n $SSH_CLIENT || -n $SSH_TTY || -n $SSH_CONNECTION ]]
}

## Configuration and management

# Get default (login) shell for current user
# Usage: get_default_shell
# Output: path to default shell (stdout); also sets REPLY
# Returns: 0 success, 1 unknown, 2 invalid usage
get_default_shell() {
    (( ARGC == 0 )) || return 2
    REPLY=""
    if is_macos; then
        # dscl output: "UserShell: /bin/zsh"
        local record
        record=$(command dscl . -read /Users/$USER UserShell 2>/dev/null)
        REPLY=${record##* }
    elif (( ${+commands[getent]} )); then
        # getent respects LDAP/NIS/local; shell is the last field
        local ent
        ent=$(getent passwd "$USER" 2>/dev/null) && REPLY=${ent##*:}
    fi
    [[ -n $REPLY ]] || return 1
    print -r -- "$REPLY"
}

# Set default shell for current user
# Usage: set_default_shell <path/to/shell>
# Returns: 0 success, 1 failure, 2 invalid usage, 127 chsh not found
set_default_shell() {
    (( ARGC == 1 )) || { _lib_usage "set_default_shell /path/to/shell"; return }
    local new_shell="$1"

    if [[ ! -x "$new_shell" ]]; then
        printe "Shell '$new_shell' not executable or found."
        return 1
    fi

    get_available_shells >/dev/null
    if (( ! ${reply[(Ie)$new_shell]} )); then
        printe "Shell '$new_shell' is not listed in /etc/shells."
        printi "Add it to /etc/shells first (requires sudo)."
        return 1
    fi

    if (( ! ${+commands[chsh]} )); then
        printe "'chsh' command not found."
        return 127
    fi

    printi "Changing shell to $new_shell (password may be required)..."
    if chsh -s "$new_shell"; then
        prints "Default shell changed. Please re-login."
    else
        printe "Failed to change shell."
        return 1
    fi
}

# Get available shells from /etc/shells
# Usage: get_available_shells
# Output: shells, one per line (stdout); also sets reply
# Returns: 0 success, 1 /etc/shells not readable, 2 invalid usage
get_available_shells() {
    (( ARGC == 0 )) || return 2
    reply=()
    [[ -r /etc/shells ]] || return 1
    local -a lines=("${(@f)$(</etc/shells)}")
    # Drop comments and empty lines
    reply=(${${lines:#\#*}:#})
    print -rl -- $reply
}

# Reload shell configuration by replacing the current shell with a login shell
# Background jobs would be lost, so the reload is refused while jobs exist
# Usage: reload_shell [-f|--force]
# Returns: 1 refused because of running jobs, 2 invalid usage (on success it does not return)
reload_shell() {
    local -a force
    zparseopts -D f=force -force=force
    (( ARGC == 0 )) || return 2
    if (( ${#jobstates} && ! ${#force} )); then
        printw "There are ${#jobstates} background job(s); they would be lost."
        printi "Finish them first or use: reload_shell --force"
        return 1
    fi
    printi "Reloading Zsh configuration..."
    exec zsh -l
}

## Terminal info

# Get terminal type
# Usage: terminal_type
# Output: $TERM or "unknown" (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
terminal_type() {
    (( ARGC == 0 )) || return 2
    REPLY=${TERM:-unknown}
    print -r -- "$REPLY"
}

# Check if stdout is a terminal that supports at least 8 colors (terminfo)
# Usage: is_color_terminal
# Returns: 0 true, 1 false, 2 invalid usage
is_color_terminal() {
    (( ARGC == 0 )) || return 2
    [[ -t 1 ]] || return 1
    (( ${terminfo[colors]:-0} >= 8 ))
}

# Get number of terminal columns
# Usage: terminal_columns
# Output: columns (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
terminal_columns() {
    (( ARGC == 0 )) || return 2
    REPLY=${COLUMNS:-80}
    print -r -- "$REPLY"
}

# Get number of terminal lines
# Usage: terminal_lines
# Output: lines (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
terminal_lines() {
    (( ARGC == 0 )) || return 2
    REPLY=${LINES:-24}
    print -r -- "$REPLY"
}

# Shell files tracking - keep at the end
zfile_track_end ${0:A}
