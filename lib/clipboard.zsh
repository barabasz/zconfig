#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# Clipboard abstraction layer and helper functions
# Supported backends: pbcopy/pbpaste (macOS), wl-copy/wl-paste (Wayland),
# xclip/xsel (X11), clip.exe/powershell.exe (WSL) and OSC 52 terminal
# escape sequence (copy only; works over SSH and in tmux with set-clipboard on).
# Depends on: print.zsh (output), system.zsh (is_wsl)
##

## Backend detection

# Detected copy/paste commands (filled on first use, so DISPLAY/WAYLAND_DISPLAY
# set after shell start are respected)
typeset -ga _CLIP_COPY_CMD=() _CLIP_PASTE_CMD=()

# Detect clipboard backend (internal)
# Usage: _clip_detect [--force]
# Returns: 0 a backend was found (OSC 52 counts for copy), 1 none
_clip_detect() {
    [[ $1 != --force ]] && (( ${#_CLIP_COPY_CMD} )) && return 0
    _CLIP_COPY_CMD=() _CLIP_PASTE_CMD=()
    if [[ $OSTYPE == darwin* ]]; then
        _CLIP_COPY_CMD=(pbcopy)
        _CLIP_PASTE_CMD=(pbpaste)
    elif [[ -n $WAYLAND_DISPLAY ]] && (( ${+commands[wl-copy]} )); then
        _CLIP_COPY_CMD=(wl-copy)
        _CLIP_PASTE_CMD=(wl-paste --no-newline)
    elif [[ -n $DISPLAY ]] && (( ${+commands[xclip]} )); then
        _CLIP_COPY_CMD=(xclip -selection clipboard -in)
        _CLIP_PASTE_CMD=(xclip -selection clipboard -out)
    elif [[ -n $DISPLAY ]] && (( ${+commands[xsel]} )); then
        _CLIP_COPY_CMD=(xsel --clipboard --input)
        _CLIP_PASTE_CMD=(xsel --clipboard --output)
    elif (( ${+commands[clip.exe]} )); then
        # WSL: Windows clipboard
        _CLIP_COPY_CMD=(clip.exe)
        (( ${+commands[powershell.exe]} )) &&
            _CLIP_PASTE_CMD=(powershell.exe -NoProfile -Command Get-Clipboard)
    elif [[ -t 1 || -w /dev/tty ]]; then
        # Fallback: OSC 52 escape sequence understood by most modern terminals
        _CLIP_COPY_CMD=(_clip_osc52)
    fi
    (( ${#_CLIP_COPY_CMD} ))
}

# Copy stdin to the terminal clipboard using the OSC 52 escape sequence (internal)
# Inside tmux the sequence is wrapped in a DCS passthrough.
# Usage: print -n text | _clip_osc52
# Returns: 0 success, 1 failure
_clip_osc52() {
    local data
    data=$(command base64 | tr -d '\n') || return 1
    local seq=$'\e]52;c;'"$data"$'\a'
    [[ -n $TMUX ]] && seq=$'\ePtmux;\e'"$seq"$'\e\\'
    print -rn -- "$seq" > /dev/tty
}

## Core functions

# Copy input to the system clipboard
# Arguments are copied as text; use -f to copy the contents of a file.
# Usage: clip_copy [-f file | text...]   or   command | clip_copy
# Example: print hello | clip_copy; clip_copy "some text"; clip_copy -f notes.txt
# Returns: 0 success, 1 failure, 2 invalid usage
clip_copy() {
    if ! _clip_detect; then
        printe "No clipboard utility found (pbcopy/wl-copy/xclip/xsel/clip.exe)."
        return 1
    fi
    if [[ $1 == -f ]]; then
        (( ARGC == 2 )) || { _lib_usage "clip_copy -f <file>"; return }
        [[ -f $2 && -r $2 ]] || { printe "'$2' is not a readable file."; return 1 }
        $_CLIP_COPY_CMD < "$2"
    elif (( ARGC )); then
        print -rn -- "$*" | $_CLIP_COPY_CMD
    elif [[ -t 0 ]]; then
        # Nothing piped in: do not wait for keyboard input
        _lib_usage "clip_copy [-f file | text...]  or  command | clip_copy"
    else
        $_CLIP_COPY_CMD
    fi
}

# Paste from the system clipboard to stdout
# Usage: clip_paste
# Output: clipboard content (stdout)
# Returns: 0 success, 1 no paste backend, 2 invalid usage
clip_paste() {
    (( ARGC == 0 )) || return 2
    _clip_detect
    if (( ! ${#_CLIP_PASTE_CMD} )); then
        printe "No clipboard paste utility found."
        return 1
    fi
    $_CLIP_PASTE_CMD
}

## Aliases

# Short names; "copy" is defined only when no command of that name exists
functions[clipcopy]=$functions[clip_copy]
functions[cb]=$functions[clip_copy]
functions[clippaste]=$functions[clip_paste]
functions[cv]=$functions[clip_paste]
(( ${+commands[copy]} )) || functions[copy]=$functions[clip_copy]

## Helpers

# Copy the absolute path of a file or directory to the clipboard
# Usage: copypath [file_or_dir]   (default: current directory)
# Returns: 0 success, 1 failure, 2 invalid usage
copypath() {
    (( ARGC <= 1 )) || { _lib_usage "copypath [file_or_dir]"; return }
    local file=${1:-.}
    if [[ ! -e $file && ! -L $file ]]; then
        printe "Path does not exist: $file"
        return 1
    fi
    # :A absolute path with symlinks resolved
    local abs_path=${file:A}
    clip_copy "$abs_path" || return 1
    prints "${c}${abs_path}${x} copied to clipboard."
}

# Copy the contents of a file to the clipboard
# Usage: copyfile <file>
# Returns: 0 success, 1 failure, 2 invalid usage
copyfile() {
    (( ARGC == 1 )) || { _lib_usage "copyfile <file>"; return }
    clip_copy -f "$1" || return 1
    prints "Contents of ${c}$1${x} copied to clipboard."
}

# Shell files tracking - keep at the end
zfile_track_end ${0:A}
