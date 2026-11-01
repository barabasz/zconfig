#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# Output, logging and interactive prompt helper functions
# Depends on: inc/colors.zsh ($r $g $y $b $c $p $x), inc/icons.zsh ($ICO_*)
# Note: message and display functions (printe, printw, printc, printkv, printul,
# printh, printt, ...) interpret print escape sequences in their text arguments,
# like the print builtin does (callers pass "\n...", icons are "\uXXXX" strings).
##

typeset -g PRINT_ICON_SPACE="  "  # Space between icon and text

## Internal helpers

# Print usage line for an invalid call and return 2
# Usage: _lib_usage "name <arg> [opt]"
# Output: "Usage: ..." on stderr
# Returns: always 2 (invalid usage), so callers can do: || { _lib_usage "..."; return }
_lib_usage() {
    printe "Usage: $1"
    return 2
}

## Demo

# Print demo of available print functions (for testing and demonstration)
# Usage: printdemo
# Returns: 0 success, 2 invalid usage
printdemo() {
    (( ARGC == 0 )) || {
        printe "${g}printdemo$x does not take any arguments."
        return 2
    }
    # Ordered list of function/description pairs (assoc arrays have no order)
    local -a print_funcs=(
        printe Error
        printw Warning
        printi Info
        prints Success
        printd Debug
        printb Bell
    )
    printh "print* demo" $y $r
    local func desc
    for func desc in $print_funcs; do
        if (( ${+functions[$func]} )); then
            $func "This is a demo of $c$func$x function ($desc)."
        fi
    done
}

## Standard logging

# Print error message to stderr
# Usage: printe <text> [text_color] [glyph] [glyph_color]
# Returns: 0 success, 2 invalid usage
printe() {
    (( ARGC >= 1 && ARGC <= 4 )) || return 2
    local text="$1"
    local tc="${2:-$x}"              # Text color
    local glyph="${3:-$ICO_ERROR}"   # Glyph (from global vars)
    local gc="${4:-$x}"              # Glyph color

    print -u2 -- "${gc}${glyph}${x}${PRINT_ICON_SPACE}${tc}${text}${x}"
}

# Print warning message to stderr
# Usage: printw <text> [text_color] [glyph] [glyph_color]
# Returns: 0 success, 2 invalid usage
printw() {
    (( ARGC >= 1 && ARGC <= 4 )) || return 2
    local text="$1"
    local tc="${2:-$x}"
    local glyph="${3:-$ICO_WARN}"
    local gc="${4:-$x}"

    print -u2 -- "${gc}${glyph}${x}${PRINT_ICON_SPACE}${tc}${text}${x}"
}

# Print bell message to stdout (with sound)
# Usage: printb <text> [text_color] [glyph] [glyph_color]
# Returns: 0 success, 2 invalid usage
printb() {
    (( ARGC >= 1 && ARGC <= 4 )) || return 2
    local text="$1"
    local tc="${2:-$x}"
    local glyph="${3:-$ICO_BELL}"
    local gc="${4:-$x}"

    # \a is the bell character
    print -n -- "\a"
    print -- "${gc}${glyph}${x}${PRINT_ICON_SPACE}${tc}${text}${x}"
}

# Print info message to stdout
# Usage: printi <text> [text_color] [glyph] [glyph_color]
# Returns: 0 success, 2 invalid usage
printi() {
    (( ARGC >= 1 && ARGC <= 4 )) || return 2
    local text="$1"
    local tc="${2:-$x}"
    local glyph="${3:-$ICO_INFO}"
    local gc="${4:-$x}"

    print -- "${gc}${glyph}${x}${PRINT_ICON_SPACE}${tc}${text}${x}"
}

# Print success message to stdout
# Usage: prints <text> [text_color] [glyph] [glyph_color]
# Returns: 0 success, 2 invalid usage
prints() {
    (( ARGC >= 1 && ARGC <= 4 )) || return 2
    local text="$1"
    local tc="${2:-$x}"
    local glyph="${3:-$ICO_OK}"
    local gc="${4:-$x}"

    print -- "${gc}${glyph}${x}${PRINT_ICON_SPACE}${tc}${text}${x}"
}
# Alias: printok
functions[printok]=$functions[prints]

# Print debug message to stderr (only if debug mode is on)
# Usage: printd <text> [text_color] [glyph] [glyph_color]
# Returns: 0 success, 2 invalid usage
printd() {
    (( ARGC >= 1 && ARGC <= 4 )) || return 2
    # Prefer is_debug (varia.zsh); fall back to ZSH_DEBUG if it is not loaded yet
    if (( ${+functions[is_debug]} )) && is_debug || (( ${ZSH_DEBUG:-0} == 1 )); then
        local text="$1"
        local tc="${2:-$x}"
        local glyph="${3:-$ICO_DEBUG}"
        local gc="${4:-$x}"

        print -u2 -- "${gc}${glyph}${x}${PRINT_ICON_SPACE}${tc}${text}${x}"
    fi
}

## Data presentation

# Print a key-value pair
# Usage: printkv <key> <value> [key_color] [value_color]
# Returns: 0 success, 2 invalid usage
printkv() {
    (( ARGC >= 2 && ARGC <= 4 )) || return 2
    local key="$1"
    local val="$2"
    local kc="${3:-$b}" # Blue default
    local vc="${4:-$x}" # Reset default

    print -- "${kc}${key}${x}: ${vc}${val}${x}"
}

# Print all elements of an array (associative or indexed)
# Usage: printa <array_name> [key_color] [value_color]
# Returns: 0 success, 1 not an array, 2 invalid usage
printa() {
    (( ARGC >= 1 && ARGC <= 3 )) || return 2
    local arr_name="$1"
    local kc="${2:-$b}"
    local vc="${3:-$x}"

    # Get variable type
    local type="${(tP)arr_name}"

    if [[ "$type" == *association* ]]; then
        local -A ref=("${(@Pkv)arr_name}")
        local key
        # Iterate over keys sorted alphabetically
        for key in "${(@ok)ref}"; do
            printkv "$key" "$ref[$key]" "$kc" "$vc"
        done
    elif [[ "$type" == *array* ]]; then
        local -a ref=("${(@P)arr_name}")
        local i
        for (( i = 1; i <= ${#ref}; i++ )); do
            printkv "$i" "$ref[i]" "$kc" "$vc"
        done
    else
        printe "'$arr_name' is not a valid array (Type: ${type:-unset})"
        return 1
    fi
}

# Print arguments in columns (like ls)
# Usage: printcol <item> [item...]
# Returns: 0 success, 2 invalid usage
printcol() {
    (( ARGC >= 1 )) || return 2
    # -c: print in columns sorted vertically (auto-width based on terminal size)
    print -rc -- "$@"
}

# Print unordered list
# Usage: printul <item> [item...]
# Returns: 0 success, 2 invalid usage
printul() {
    (( ARGC >= 1 )) || return 2
    local item
    local bullet="$ICO_UL"

    for item in "$@"; do
        print -- " ${b}${bullet}${x} ${item}"
    done
}

# Print colored text (simple wrapper)
# Escape sequences in text are interpreted, like print (e.g. "\nTitle")
# Usage: printc <text> [color]
# Returns: 0 success, 2 invalid usage
printc() {
    (( ARGC >= 1 && ARGC <= 2 )) || return 2
    local text="$1"
    local color="${2:-$x}"
    print -- "${color}${text}${x}"
}

# Print text with a status label right-aligned to the terminal width
# Usage: printr <text> <status> [status_color]
# Example: printr "Checking network" "OK" $g  ->  Checking network ......... [ OK ]
# Returns: 0 success, 2 invalid usage
printr() {
    (( ARGC >= 2 && ARGC <= 3 )) || return 2
    local text="$1"
    local label="[ $2 ]"
    local sc="${3:-$x}"
    local cols=${COLUMNS:-80}
    # (m) counts display width (wide chars, emoji); dots fill the gap
    local -i fill=$(( cols - ${(m)#text} - ${(m)#label} - 2 ))
    (( fill < 1 )) && fill=1
    print -r -- "${text} ${(l:fill::.:)} ${sc}${label}${x}"
}

# Print a progress bar
# Usage: printp <current> <total> [width] [color]
# Example: printp 30 100 20  ->  [██████--------------]  30%
# Output: progress bar on the current line (no newline, uses \r);
#         a newline is printed when current reaches total
# Returns: 0 success, 2 invalid usage
printp() {
    (( ARGC >= 2 && ARGC <= 4 )) || return 2
    [[ $1 == <-> && $2 == <-> ]] || return 2
    local -i current=$1 total=$2 width=${3:-30}
    local color="${4:-$g}"
    (( total > 0 && width > 0 )) || return 2
    (( current > total )) && current=total

    local -i pct=$(( current * 100 / total ))
    local -i done_len=$(( current * width / total ))
    local -i todo_len=$(( width - done_len ))
    local bar_done="${(l:done_len::█:)}" bar_todo="${(l:todo_len::-:)}"

    printf '\r[%s%s%s%s] %3d%%' "$color" "$bar_done" "$x" "$bar_todo" $pct
    (( current == total )) && print
    return 0
}

## Interactive

# Ask user for input with default value
# Usage: printq <prompt> [default_value]
# Output: user input or default (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
printq() {
    (( ARGC >= 1 && ARGC <= 2 )) || return 2
    local prompt_text="$1"
    local default_val="$2"
    local input

    # Zsh 'read' handles prompt natively with '?prompt' (printed to stderr)
    if read -r "input?${y}${prompt_text}${x} [${default_val}]: "; then
        REPLY="${input:-$default_val}"
    else
        # Use default if read fails (e.g. Ctrl+D)
        REPLY="$default_val"
    fi
    print -r -- "$REPLY"
}

# Ask user a yes/no question (default: No)
# Usage: yesno <question>
# Returns: 0 yes, 1 no, 2 invalid usage
yesno() {
    (( ARGC == 1 )) || return 2
    # -q: read single char, y/Y returns 0, anything else returns 1
    if read -q "?${y}${1}${x} [y/N] "; then
        print # Newline after single char input
        return 0
    fi
    print
    return 1
}

## Formatting and UI

# Print a separator line
# Usage: printl [color] [char] [width]
# Example: printl $r "=" 50%
# Returns: 0 success, 2 invalid usage
printl() {
    (( ARGC <= 3 )) || return 2
    local color="${1:-$x}"
    local char="${2:-─}"
    local width_arg="${3:-100%}"

    local -i max_cols=${COLUMNS:-80}
    local -i cols

    # Calculate width
    if [[ "$width_arg" == <->% ]]; then
        cols=$(( max_cols * ${width_arg%\%} / 100 ))
    elif [[ "$width_arg" == <-> ]]; then
        cols=$width_arg
    else
        return 2
    fi

    # (pl:n::str:) repeats str to fill n characters
    print -r -- "${color}${(pl:cols::$char:)}${x}"
}

# Print a header with an underline
# Usage: printh <text> [text_color] [line_color] [line_char]
# Returns: 0 success, 2 invalid usage
printh() {
    (( ARGC >= 1 && ARGC <= 4 )) || return 2
    local text="$1"
    local tc="${2:-$x}"
    local lc="${3:-$x}"
    local char="${4:-‾}"

    print -- "${tc}${text}${x}"
    # (m) = display width, correct for wide characters and emoji
    printl "$lc" "$char" "${(m)#text}"
}

# Print text surrounded by a border
# Usage: printt <text> [text_color] [border_color]
# Returns: 0 success, 2 invalid usage
printt() {
    (( ARGC >= 1 && ARGC <= 3 )) || return 2
    local text="$1"
    local ct="${2:-$x}"
    local cb="${3:-$x}"

    local -i width=$(( ${(m)#text} + 2 ))
    local bar="${(l:width::─:)}"

    print -- "${cb}┌${bar}┐${x}"
    print -- "${cb}│${x} ${ct}${text}${x} ${cb}│${x}"
    print -- "${cb}└${bar}┘${x}"
}

# Execute command with animated spinner
# Usage: execs <message> <command> [args...]
# Output: command output is captured and printed after it finishes
# Returns: exit code of the executed command, 2 invalid usage, 127 command not found
# Customizable via: EXECS_SPINNER_FRAMES (array), EXECS_SPINNER_DELAY (seconds, float)
execs() {
    (( ARGC >= 2 )) || { _lib_usage 'execs "Message" command [args...]'; return }

    # Suppress job control messages
    setopt localoptions nomonitor nonotify
    zmodload zsh/zselect 2>/dev/null

    local -a frames
    if (( ${#EXECS_SPINNER_FRAMES} )); then
        frames=("${EXECS_SPINNER_FRAMES[@]}")
    else
        frames=('|' '/' '-' '\')
    fi
    local -F delay=${EXECS_SPINNER_DELAY:-0.16}
    local -i delay_cs=$(( delay * 100 ))   # zselect timeout is in 1/100 s

    local message="${1:-Processing...}"
    shift

    if ! whence -- "$1" >/dev/null 2>&1; then
        printe "Command not found: $1"
        return 127
    fi

    local tmpfile="${TMPDIR:-/tmp}/execs.$$.$EPOCHREALTIME"
    local -i pid exit_code=0
    local frame

    {
        "$@" >| "$tmpfile" 2>&1 &
        pid=$!

        echotc vi 2>/dev/null   # hide cursor

        while kill -0 $pid 2>/dev/null; do
            for frame in $frames; do
                printf '\r\033[K%s%s%s %s' "$y" "$frame" "$x" "$message"
                zselect -t $delay_cs 2>/dev/null || sleep $delay
                kill -0 $pid 2>/dev/null || break
            done
        done

        wait $pid
        exit_code=$status
    } always {
        # Runs also on Ctrl+C: clear line, restore cursor, show output, clean up
        printf '\r\033[K'
        echotc ve 2>/dev/null
        if [[ -s "$tmpfile" ]]; then
            print -rn -- "$(<$tmpfile)"
            print
        fi
        rm -f -- "$tmpfile"
    }

    return $exit_code
}

# Shell files tracking - keep at the end
zfile_track_end ${0:A}
