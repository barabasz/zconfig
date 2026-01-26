#!/bin/zsh
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# Clipboard abstraction layer and helper functions
# Depends on: print.zsh (for printe, prints, printi)

# Copy input to system clipboard
# Usage: echo "hello" | clip_copy
# Usage: clip_copy file.txt
# Returns: 0 on success, 1 on failure
clip_copy() {
    local cmd=""
    # Detect platform specific clipboard utility
    if [[ $OSTYPE == darwin* ]]; then
        cmd="pbcopy"
    elif [[ -n $WAYLAND_DISPLAY ]] && (( ${+commands[wl-copy]} )); then
        cmd="wl-copy"
    elif [[ -n $DISPLAY ]] && (( ${+commands[xclip]} )); then
        cmd="xclip -selection clipboard"
    elif (( ${+commands[xsel]} )); then
        cmd="xsel --clipboard --input"
    fi

    if [[ -n "$cmd" ]]; then
        if (( ARGC == 0 )); then
            # Read from stdin
            cat | eval "$cmd"
        elif [[ -f "$1" ]]; then
            # Read from file
            cat "$1" | eval "$cmd"
        else
            # Copy string argument
            print -n -- "$*" | eval "$cmd"
        fi
    else
        # Error: System tool missing
        printe "No clipboard utility found"
        return 1
    fi
}
# Aliases
functions[clipcopy]=$functions[clip_copy]
functions[copy]=$functions[clip_copy]
functions[cb]=$functions[clip_copy]

# Paste from system clipboard to stdout
# Usage: clip_paste
# Returns: clipboard content
clip_paste() {
    if [[ $OSTYPE == darwin* ]]; then
        pbpaste
    elif [[ -n $WAYLAND_DISPLAY ]] && (( ${+commands[wl-paste]} )); then
        wl-paste
    elif [[ -n $DISPLAY ]] && (( ${+commands[xclip]} )); then
        xclip -selection clipboard -o
    elif (( ${+commands[xsel]} )); then
        xsel --clipboard --output
    else
        printe "No clipboard utility found"
        return 1
    fi
}
# Aliases
functions[clippaste]=$functions[clip_paste]
functions[cv]=$functions[clip_paste]

# Copy the absolute path of a file or directory to clipboard
# Usage: copypath [file_or_dir] (defaults to current dir)
# Returns: 0 on success, 1 on failure
copypath() {
    # If no argument passed, use current directory
    local file="${1:-.}"

    # Use Zsh modifier :a to convert to absolute path
    local abs_path="${file:a}"
    local abs_pathc="$c$abs_path$x"  # colored path for messages

    # Pass to clip_copy
    print -n -- "$abs_path" | clip_copy || return 1

    # Confirm success
    prints "$abs_pathc copied to clipboard."
}

# Copy the contents of a file to clipboard
# Usage: copyfile file.txt
# Returns: 0 on success, 1 on failure
copyfile() {
    if (( ARGC != 1 )); then
        # Info: Usage hint
        printi "Usage: copyfile <file>"
        return 1
    fi

    local file="$1"
    local filec="$c$file$x"  # colored file name for messages

    if [[ ! -f "$file" ]]; then
        # Error: Invalid file
        printe "'$filec' is not a valid file."
        return 1
    fi

    clip_copy "$file" || return 1
    
    # Confirm success
    prints "$filec copied to clipboard."
}

# shell files tracking - keep at the end
zfile_track_end ${0:A}