#!/bin/zsh
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# Clipboard abstraction layer and helper functions
# Depends on: print.zsh (for printe, prints, printi)

# --- Initialization & Detection ---

# Define global variables for copy/paste commands to avoid detecting them on every call
typeset -g _CLIP_COPY_CMD=""
typeset -g _CLIP_PASTE_CMD=""

# Detect clipboard tool once at load time
if [[ $OSTYPE == darwin* ]]; then
    _CLIP_COPY_CMD="pbcopy"
    _CLIP_PASTE_CMD="pbpaste"
elif [[ -n $WAYLAND_DISPLAY ]] && (( ${+commands[wl-copy]} )); then
    _CLIP_COPY_CMD="wl-copy"
    _CLIP_PASTE_CMD="wl-paste"
elif [[ -n $DISPLAY ]]; then
    if (( ${+commands[xclip]} )); then
        _CLIP_COPY_CMD="xclip -selection clipboard -in"
        _CLIP_PASTE_CMD="xclip -selection clipboard -out"
    elif (( ${+commands[xsel]} )); then
        _CLIP_COPY_CMD="xsel --clipboard --input"
        _CLIP_PASTE_CMD="xsel --clipboard --output"
    fi
fi

# --- Core Functions ---

# Copy input to system clipboard
# Usage: echo "hello" | clip_copy OR clip_copy file.txt OR clip_copy "some string"
# Returns: 0 on success, 1 on failure
clip_copy() {
    if [[ -z "$_CLIP_COPY_CMD" ]]; then
        printe "No clipboard utility found (pbcopy/wl-copy/xclip/xsel)."
        return 1
    fi

    # Fix: remove parentheses around variable name inside expansion
    # ${=VAR} performs word splitting on the variable content
    local -a cmd=( ${=_CLIP_COPY_CMD} )

    if (( ARGC == 0 )); then
        # Case 1: Read from Stdin (pipe)
        # Usage: echo "foo" | clip_copy
        "${cmd[@]}"
    elif [[ -f "$1" ]]; then
        # Case 2: Read from File
        # Usage: clip_copy file.txt
        # Redirect file to command stdin
        "${cmd[@]}" < "$1"
    else
        # Case 3: Copy Arguments string
        # Usage: clip_copy "foo bar"
        # -n prevents trailing newline usually added by print
        print -n -- "$*" | "${cmd[@]}"
    fi
}

# Paste from system clipboard to stdout
# Usage: clip_paste
# Returns: clipboard content
clip_paste() {
    if [[ -z "$_CLIP_PASTE_CMD" ]]; then
        printe "No clipboard utility found."
        return 1
    fi
    
    # Execute the paste command
    local -a cmd=( ${=_CLIP_PASTE_CMD} )
    "${cmd[@]}"
}

# --- Aliases ---

# Standardize aliases for ease of use
functions[clipcopy]=$functions[clip_copy]
functions[copy]=$functions[clip_copy]
functions[cb]=$functions[clip_copy]      # generic shorthand
functions[clippaste]=$functions[clip_paste]
functions[cv]=$functions[clip_paste]     # generic shorthand

# --- Helpers ---

# Copy the absolute path of a file or directory to clipboard
# Usage: copypath [file_or_dir] (defaults to current dir)
# Returns: 0 on success, 1 on failure
copypath() {
    # Default to current directory if no argument
    local file="${1:-.}"

    # Use Zsh modifier :A (absolute path, resolving symlinks)
    local abs_path="${file:A}"
    
    if [[ -z "$abs_path" ]]; then
        printe "Could not resolve path: $file"
        return 1
    fi

    local abs_pathc="${c}${abs_path}${x}" # colored for output

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
        printi "Usage: copyfile <file>"
        return 1
    fi

    local file="$1"
    local filec="${c}${file}${x}"

    if [[ ! -f "$file" ]]; then
        printe "'$filec' is not a valid file."
        return 1
    fi

    # Reuse clip_copy's file handling logic
    clip_copy "$file" || return 1
    
    prints "Contents of $filec copied to clipboard."
}

# shell files tracking - keep at the end
zfile_track_end ${0:A}