#!/bin/zsh
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# Output and Logging helper functions
# Depends on colors and glyphs defined in inc/bootstrap.zsh
# (e.g. $r, $g, $x, $ICO_ERROR, $ICO_OK etc.)

# Print available print functions (for demo purposes)
# Usage: printdemo
printdemo() {
    typeset -A print_funcs=(
        printe Error
        printw Warning
        printi Info
        prints Success
        printd Debug
        printb Bell
    )
    local func desc
    for func desc in ${(kv)print_funcs}; do
        if (( ${+functions[$func]} )); then
            $func "This is a demo of $c$func$x function ($desc)."
        fi
    done
}

# Print error message to stderr
# Usage: printe "Error text" [text_color] [glyph] [ICO_color]
# Default glyph: $ICO_ERROR
printe() {
    local text="$1"
    local tc="${2:-$x}"              # Text Color (defaults to reset)
    local glyph="${3:-$ICO_ERROR}" # Glyph (defaults to global variable)
    local gc="${4:-$x}"              # Glyph Color (defaults to reset)
    
    print -u2 -- "${gc}${glyph}${x} ${tc}${text}${x}"
}

# Print warning message to stderr
# Usage: printw "Warning text" [text_color] [glyph] [ICO_color]
# Default glyph: $ICO_WARN
printw() {
    local text="$1"
    local tc="${2:-$x}"                # Text Color (defaults to reset)
    local glyph="${3:-$ICO_WARN}" # Glyph (defaults to global variable)
    local gc="${4:-$x}"                # Glyph Color (defaults to reset)

    print -u2 -- "${gc}${glyph}${x} ${tc}${text}${x}"
}

# Print bell message to stdout
# Usage: printb "Info text" [text_color] [glyph] [ICO_color]
# Default glyph: $ICO_INFO
printb() {
    local text="$1"
    local tc="${2:-$x}"
    local glyph="${3:-$ICO_BELL}"
    local gc="${4:-$x}"
    print -n -- "\a"  # Emit bell character
    print -- "${gc}${glyph}${x} ${tc}${text}${x}"
}

# Print info message to stdout
# Usage: printi "Info text" [text_color] [glyph] [ICO_color]
# Default glyph: $ICO_INFO
printi() {
    local text="$1"
    local tc="${2:-$x}"
    local glyph="${3:-$ICO_INFO}"
    local gc="${4:-$x}"

    print -- "${gc}${glyph}${x} ${tc}${text}${x}"
}

# Print success message to stdout
# Usage: prints "Success text" [text_color] [glyph] [ICO_color]
# Default glyph: $ICO_OK
prints() {
    local text="$1"
    local tc="${2:-$x}"
    local glyph="${3:-$ICO_OK}"
    local gc="${4:-$x}"

    print -- "${gc}${glyph}${x} ${tc}${text}${x}"
}
# Alias: printok
# Safe to copy now as the function body uses ASCII variable names, not raw Unicode
functions[printok]=$functions[prints]

# Print debug message (only if debug mode is on)
# Usage: printd "Debug text" [text_color] [glyph] [ICO_color]
# Default glyph: $ICO_DEBUG
# Returns: Prints to stderr if ZSH_DEBUG=1
printd() {
    # Uses is_debug from varia.zsh if available, otherwise manual check
    if (( ${+functions[is_debug]} )) && is_debug || [[ $ZSH_DEBUG == 1 ]]; then
        local text="$1"
        local tc="${2:-$x}"
        local glyph="${3:-$ICO_DEBUG}"
        local gc="${4:-$x}"
        
        print -u2 -- "${gc}${glyph}${x} ${tc}${text}${x}"
    fi
}

# Print a key-value pair
# Usage: printkv "Key" "Value" [key_color] [value_color]
# Example: printkv "IP Address" "192.168.1.1"
# Returns: Prints "Key: Value" with formatting to stdout
printkv() {
    (( ARGC >= 2 )) || return 1
    local key="$1"
    local val="$2"
    local kc="${3:-$b}" # Key Color (default: blue)
    local vc="${4:-$x}" # Value Color (default: reset)

    print -- "${kc}${key}${x}: ${vc}${val}${x}"
}

# Print all elements of an array (associative or indexed) using printkv
# Usage: printa array_name [key_color] [value_color]
# Example: printa sys_info
# Returns: Prints list of key-values to stdout
printa() {
    (( ARGC >= 1 )) || return 1
    local arr_name="$1"
    local kc="${2:-$b}" # Key Color (default: blue)
    local vc="${3:-$x}" # Value Color (default: reset)
    
    # Get variable type using Zsh flag (t) and pointer (P)
    local type="${(tP)arr_name}"

    if [[ "$type" == *"association"* ]]; then
        # Associative array
        local key param val
        # Iterate over keys sorted alphabetically (@okP)
        for key in "${(@okP)arr_name}"; do
            # Construct indirect reference to get value
            param="${arr_name}[$key]"
            val="${(P)param}"
            printkv "$key" "$val" "$kc" "$vc"
        done
    elif [[ "$type" == *"array"* ]]; then
        # Indexed array
        local i param val
        # Get array length
        local len="${#${(P)arr_name}}"
        for ((i=1; i<=len; i++)); do
            param="${arr_name}[$i]"
            val="${(P)param}"
            printkv "$i" "$val" "$kc" "$vc"
        done
    else
        printe "'$arr_name' is not a valid array (Type: $type)"
        return 1
    fi
}

# Print text in a specific color
# Usage: printc "Text" [color]
# Example: printc "Done" $g
# Returns: Prints colored text to stdout
printc() {
    local text="$1"
    local color="${2:-$x}"
    print -- "${color}${text}${x}"
}

# Print an unordered list of items
# Usage: printul "Item 1" "Item 2" "Item 3"
# Returns: Prints bulleted list to stdout
printul() {
    (( ARGC >= 1 )) || return 1
    local item
    local bullet="•" 
    
    for item in $@; do
        print -- " ${b}${bullet}${x} ${item}"
    done
}

# Ask user for input with default value
# Usage: printq "Enter name" "DefaultName"
# Returns: The user input or default
printq() {
    local prompt_text="$1"
    local default_val="$2"
    local input
    
    # Print prompt with default in brackets
    # -n prevents newline
    print -n -- "${y}${prompt_text}${x} [${default_val}]: "
    read -r input
    
    # Return input or default if empty
    print -- "${input:-$default_val}"
}

# Print text surrounded by a border (Title Box)
# Usage: printt "Text" [text_color] [border_color]
# Example: printt "Alert" $r $y
# Returns: Prints formatted box to stdout
printt() {
    (( ARGC >= 1 )) || return 1
    local text="$1"
    local ct="${2:-$x}" # Color Text (defaults to $x)
    local cb="${3:-$x}" # Color Border (defaults to $x)

    # Calculate border width (text + 2 spaces padding)
    local width=$(( ${#text} + 2 ))
    
    # Generate horizontal bar using Zsh padding flag (l:length::char:)
    # Creates an empty string of length $width filled with ─
    local bar="${(l:width::─:)}"

    # Draw the box
    print -- "${cb}┌${bar}┐${x}"
    print -- "${cb}│${x} ${ct}${text}${x} ${cb}│${x}"
    print -- "${cb}└${bar}┘${x}"
}

# Print a separator line with custom width
# Usage: printl [color] [char] [width]
# width: can be integer (e.g. 50) or percentage (e.g. 50%)
# Example: printl $r "*" 50%
# Returns: Prints line to stdout
printl() {
    local color="${1:-$x}"       # Default color: reset ($x)
    local char="${2:-─}"         # Default char: horizontal line (─)
    local width_arg="${3:-100%}" # Default width: full screen

    # Get max terminal width
    local max_cols=${COLUMNS:-$(tput cols 2>/dev/null || print 80)}
    local cols

    # Calculate target width based on argument type
    if [[ "$width_arg" == *% ]]; then
        # Percentage calculation: remove '%' suffix and multiply
        # Using Zsh arithmetic expansion for integer math
        cols=$(( max_cols * ${width_arg%\%} / 100 ))
    else
        # Fixed integer width
        cols=$width_arg
    fi

    # Safety check: ensure width is essentially non-negative integer
    (( cols < 0 )) && cols=0

    # Step 1: Generate a line of spaces of length 'cols'
    local line="${(l:cols:: :):-}"

    # Step 2: Replace spaces with the requested char
    line="${line// /${char}}"

    # Print with color
    print -- "${color}${line}${x}"
}

# Print a header with an underline of the same length
# Usage: printh "Text" [text_color] [line_color] [line_char]
# Example: printh "Title" $r $g "="
# Returns: Prints text and underline to stdout
printh() {
    (( ARGC >= 1 )) || return 1
    local text="$1"
    local tc="${2:-$x}"   # Text Color (defaults to reset)
    local lc="${3:-$x}"   # Line Color (defaults to reset)
    local char="${4:-‾}"  # Line Char (defaults to overline)

    # Print the text
    print -- "${tc}${text}${x}"

    # Print the underline using printl with specific width
    # This leverages the integer width logic in printl
    # ${#text} gets the length of the string
    printl "$lc" "$char" "${#text}"
}

# shell files tracking - keep at the end
zfile_track_end ${0:A}