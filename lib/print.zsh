#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# Output and Logging helper functions
# Depends on colors and glyphs defined in inc/bootstrap.zsh
# (e.g. $r, $g, $x, $ICO_ERROR, $ICO_OK etc.)

# --- Standard Logging ---

# Print error message to stderr
# Usage: printe "Error text" [text_color] [glyph] [ICO_color]
# Returns: 0 on success, 2 on invalid usage
printe() {
    (( ARGC >= 1 && ARGC <= 4 )) || return 2
    local text="$1"
    local tc="${2:-$x}"              # Text Color
    local glyph="${3:-$ICO_ERROR}"   # Glyph (from global vars)
    local gc="${4:-$x}"              # Glyph Color
    
    print -u2 -- "${gc}${glyph}${x} ${tc}${text}${x}"
}

# Print warning message to stderr
# Usage: printw "Warning text" [text_color] [glyph] [ICO_color]
# Returns: 0 on success, 2 on invalid usage
printw() {
    (( ARGC >= 1 && ARGC <= 4 )) || return 2
    local text="$1"
    local tc="${2:-$x}"
    local glyph="${3:-$ICO_WARN}"
    local gc="${4:-$x}"

    print -u2 -- "${gc}${glyph}${x} ${tc}${text}${x}"
}

# Print bell message to stdout (with sound)
# Usage: printb "Info text" [text_color] [glyph] [ICO_color]
# Returns: 0 on success, 2 on invalid usage
printb() {
    (( ARGC >= 1 && ARGC <= 4 )) || return 2
    local text="$1"
    local tc="${2:-$x}"
    local glyph="${3:-$ICO_BELL}"
    local gc="${4:-$x}"
    
    # \a is the bell character
    print -n -- "\a"
    print -- "${gc}${glyph}${x} ${tc}${text}${x}"
}

# Print info message to stdout
# Usage: printi "Info text" [text_color] [glyph] [ICO_color]
# Returns: 0 on success, 2 on invalid usage
printi() {
    (( ARGC >= 1 && ARGC <= 4 )) || return 2
    local text="$1"
    local tc="${2:-$x}"
    local glyph="${3:-$ICO_INFO}"
    local gc="${4:-$x}"

    print -- "${gc}${glyph}${x} ${tc}${text}${x}"
}

# Print success message to stdout
# Usage: prints "Success text" [text_color] [glyph] [ICO_color]
# Returns: 0 on success, 2 on invalid usage
prints() {
    (( ARGC >= 1 && ARGC <= 4 )) || return 2
    local text="$1"
    local tc="${2:-$x}"
    local glyph="${3:-$ICO_OK}"
    local gc="${4:-$x}"

    print -- "${gc}${glyph}${x} ${tc}${text}${x}"
}
# Alias: printok
functions[printok]=$functions[prints]

# Print debug message (only if debug mode is on)
# Usage: printd "Debug text" [text_color] [glyph] [ICO_color]
# Returns: 0 on success, 2 on invalid usage
printd() {
    (( ARGC >= 1 && ARGC <= 4 )) || return 2
    # Check for is_debug function or ZSH_DEBUG variable
    if (( ${+functions[is_debug]} )) && is_debug || [[ $ZSH_DEBUG == 1 ]]; then
        local text="$1"
        local tc="${2:-$x}"
        local glyph="${3:-$ICO_DEBUG}"
        local gc="${4:-$x}"
        
        print -u2 -- "${gc}${glyph}${x} ${tc}${text}${x}"
    fi
}

# --- Data Presentation ---

# Print a key-value pair
# Usage: printkv "Key" "Value" [key_color] [value_color]
# Returns: 0 on success, 2 on invalid usage
printkv() {
    (( ARGC >= 2 && ARGC <= 4 )) || return 2
    local key="$1"
    local val="$2"
    local kc="${3:-$b}" # Blue default
    local vc="${4:-$x}" # Reset default

    print -- "${kc}${key}${x}: ${vc}${val}${x}"
}

# Print all elements of an array (associative or indexed)
# Usage: printa array_name [key_color] [value_color]
# Returns: 0 on success, 1 if not an array, 2 on invalid usage
printa() {
    (( ARGC >= 1 && ARGC <= 3 )) || return 2
    local arr_name="$1"
    local kc="${2:-$b}"
    local vc="${3:-$x}"
    
    # Get variable type
    local type="${(tP)arr_name}"

    if [[ "$type" == *"association"* ]]; then
        # Copy to local ref using (@Pkv) expansion for safety and ease
        local -A ref=("${(@Pkv)arr_name}")
        local key val
        # Iterate over keys sorted alphabetically (ok)
        for key val in "${(@ok)ref}"; do
             printkv "$key" "$val" "$kc" "$vc"
        done
    elif [[ "$type" == *"array"* ]]; then
        # Indexed array
        local -a ref=("${(@P)arr_name}")
        local i
        for ((i=1; i<=${#ref}; i++)); do
            printkv "$i" "$ref[i]" "$kc" "$vc"
        done
    else
        printe "'$arr_name' is not a valid array (Type: $type)"
        return 1
    fi
}

# Print arguments in columns (like ls)
# Usage: printcol "Item 1" "Item 2" "Item 3"...
# Returns: 0 on success, 2 on invalid usage
printcol() {
    (( ARGC >= 1 )) || return 2
    # -c: print in columns sorted vertically (auto-width based on terminal size)
    print -c -- "$@"
}

# Print unordered list
# Usage: printul "Item 1" "Item 2"...
# Returns: 0 on success, 2 on invalid usage
printul() {
    (( ARGC >= 1 )) || return 2
    local item
    local bullet="•" 
    
    for item in "$@"; do
        print -- " ${b}${bullet}${x} ${item}"
    done
}

# Print colored text (simple wrapper)
# Usage: printc "Text" [color]
# Returns: 0 on success, 2 on invalid usage
printc() {
    (( ARGC >= 1 && ARGC <= 2 )) || return 2
    local text="$1"
    local color="${2:-$x}"
    print -- "${color}${text}${x}"
}

# --- Interactive ---

# Ask user for input with default value
# Usage: printq "Enter name" [default_value]
# Returns: 0 on success (prints user input or default), 2 on invalid usage
printq() {
    (( ARGC >= 1 && ARGC <= 2 )) || return 2
    local prompt_text="$1"
    local default_val="$2"
    local input
    
    # Zsh 'read' handles prompt natively with '?prompt'
    # -r: raw mode (no backslash escape)
    if read -r "input?${y}${prompt_text}${x} [${default_val}]: "; then
        print -- "${input:-$default_val}"
    else
        # Return default if read fails (e.g. Ctrl+D)
        print -- "$default_val"
    fi
}

# Ask user a yes/no question
# Usage: yesno "Do you want to proceed?"
# Returns: 0 (true) for Yes, 1 (false) for No, 2 on invalid usage
yesno() {
    (( ARGC == 1 )) || return 2
    local prompt_text="$1"
    # -q: read single char, y/Y returns 0, n/N returns 1
    # ?...: prompt string
    if read -q "?${y}${prompt_text}${x} [y/N] "; then
        print # Print newline after single char input
        return 0
    else
        print # Print newline
        return 1
    fi
}

# --- Formatting & UI ---

# Print a separator line
# Usage: printl [color] [char] [width]
# Example: printl $r "=" 50%
# Returns: 0 on success, 2 on invalid usage
printl() {
    (( ARGC <= 3 )) || return 2
    local color="${1:-$x}"
    local char="${2:-─}"
    local width_arg="${3:-100%}"

    local max_cols=${COLUMNS:-$(tput cols 2>/dev/null || print 80)}
    local cols

    # Calculate width
    if [[ "$width_arg" == *% ]]; then
        cols=$(( max_cols * ${width_arg%\%} / 100 ))
    else
        cols=$width_arg
    fi
    (( cols < 0 )) && cols=0

    # Method: Generate a string of spaces of length 'cols', then replace spaces with char.
    # This is safer than nested variable expansion inside padding flags.
    local line="${(l:cols:: :)}"
    
    # Print with color, replacing spaces with the target char
    print -- "${color}${line// /${char}}${x}"
}

# Print a header with an underline
# Usage: printh "Text" [text_color] [line_color] [line_char]
# Returns: 0 on success, 2 on invalid usage
printh() {
    (( ARGC >= 1 && ARGC <= 4 )) || return 2
    local text="$1"
    local tc="${2:-$x}"
    local lc="${3:-$x}"
    local char="${4:-‾}"

    print -- "${tc}${text}${x}"
    printl "$lc" "$char" "${#text}"
}

# Print text surrounded by a border
# Usage: printt "Text" [text_color] [border_color]
# Returns: 0 on success, 2 on invalid usage
printt() {
    (( ARGC >= 1 && ARGC <= 3 )) || return 2
    local text="$1"
    local ct="${2:-$x}"
    local cb="${3:-$x}"

    local width=$(( ${#text} + 2 ))

    # Use expansion padding for the bar
    local bar="${(l:width::─:):-}"

    print -- "${cb}┌${bar}┐${x}"
    print -- "${cb}│${x} ${ct}${text}${x} ${cb}│${x}"
    print -- "${cb}└${bar}┘${x}"
}

# Execute command with animated spinner
# Usage: execs "Message text" command [args...]
# Returns: exit code of the executed command
# Customizable via: EXECS_SPINNER_FRAMES (array), EXECS_SPINNER_DELAY (float)
execs() {
    (( ARGC >= 2 )) || { printe "Usage: execs \"Message\" command [args...]"; return 2 }

    # Suppress job control messages
    setopt LOCAL_OPTIONS NO_MONITOR NO_NOTIFY

    local -a frames=( "${(@)EXECS_SPINNER_FRAMES:-${(@s: :):-| / - \\}}" )
    local delay=${EXECS_SPINNER_DELAY:-0.16}

    local message="$1" && shift
    [[ -z "$message" ]] && message="Processing..."

    # Check if command exists
    if ! whence "$1" >/dev/null 2>&1; then
        printe "Command not found: $1"
        return 127
    fi

    # Create temporary file for capturing output
    local tmpfile=${TMPDIR:-/tmp}/execs.$$.$RANDOM

    # Execute command in background
    "$@" > "$tmpfile" 2>&1 &
    local pid=$!

    # Hide cursor
    echotc vi 2>/dev/null

    # Animate spinner while process is running
    while kill -0 $pid 2>/dev/null; do
        for frame in "${frames[@]}"; do
            printf "\r\033[K${by}${frame}${x} ${message}"
            sleep $delay
            kill -0 $pid 2>/dev/null || break
        done
    done

    # Wait for process and capture exit code
    wait $pid
    local exit_code=$?

    # Clear spinner line and restore cursor
    printf "\r\033[K"
    echotc ve 2>/dev/null

    # Display captured output
    [[ -s "$tmpfile" ]] && cat "$tmpfile"

    # Cleanup
    rm -f "$tmpfile"

    return $exit_code
}

# shell files tracking - keep at the end
zfile_track_end ${0:A}