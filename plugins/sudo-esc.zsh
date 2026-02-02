#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# sudo-esc: adds 'sudo' before the last command after pressing 'Esc Esc' in Zsh
# https://github.com/barabasz/zconfig/blob/main/plugins/sudo-esc.zsh

sudo-esc() {
    # Ensure standard Zsh behavior inside the widget
    emulate -L zsh
    setopt extended_glob

    # If the buffer is empty, retrieve the last command from history
    if [[ -z $BUFFER ]]; then
        LBUFFER="${history[$((HISTCMD-1))]}"
    fi

    # Preserve leading whitespace using Zsh pattern matching
    # (#b) enables backreferences ($match)
    # ([[:space:]]*) matches leading spaces
    # (*) matches the rest
    local prefix=""
    if [[ $BUFFER == (#b)([[:space:]]#)(*) ]]; then
        prefix="$match[1]"
        BUFFER="$match[2]"
    fi

    # Determine the target editor
    # Uses parameter expansion to default to VISUAL or EDITOR
    local target_editor="${SUDO_EDITOR:-${VISUAL:-$EDITOR}}"
    
    # Get the first word of the command (the executable)
    local -a words
    words=(${(z)BUFFER})
    local cmd="$words[1]"
    
    # Resolve the command to its absolute path/real command to compare with editor
    local alias_expanded="${aliases[$cmd]}"
    local resolved_cmd="${${${(z)alias_expanded}[1]:-$cmd}:c:P}"
    local resolved_editor="${target_editor:c:P}"

    # Check logic and toggle
    if [[ $cmd == "sudo" ]]; then
        # Case 1: Already has sudo (or sudo -e)
        if [[ $words[2] == "-e" ]]; then
            # 'sudo -e' -> strip it, optionally restore editor name if we were editing
            if [[ -n $target_editor ]]; then
                BUFFER="$target_editor ${BUFFER#sudo -e }"
            else
                BUFFER="${BUFFER#sudo -e }"
            fi
        else
            # 'sudo cmd' -> strip sudo
            BUFFER="${BUFFER#sudo }"
        fi
    elif [[ -n $target_editor && $resolved_cmd -ef $resolved_editor ]]; then
        # Case 2: The command IS the editor (checking file identity via -ef)
        # 'vim file' -> 'sudo -e file'
        BUFFER="sudo -e ${BUFFER#$cmd }"
    else
        # Case 3: Regular command
        # 'cmd args' -> 'sudo cmd args'
        BUFFER="sudo $BUFFER"
    fi

    # Restore leading whitespace
    BUFFER="${prefix}${BUFFER}"

    # Move cursor to the end of the line (optional, but usually expected)
    CURSOR=$#BUFFER
}

zle -N sudo-esc

# Bindings
bindkey -M emacs '\e\e' sudo-esc
bindkey -M vicmd '\e\e' sudo-esc
bindkey -M viins '\e\e' sudo-esc
