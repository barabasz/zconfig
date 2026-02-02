#!/bin/zsh
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# String manipulation functions
# Uses native Zsh parameter expansion flags for performance

# --- Transformation ---

# Extract version number from a string
# Usage: get_version "zsh 5.9"
# Returns: 5.9
get_version() {
    local input=$1
    # Use -o to print only the matching part (extended globbing logic inside Zsh regex)
    if [[ $input =~ '[0-9]+(\.[0-9]+)+' ]]; then
        print -- $MATCH
        return 0
    fi
    return 1
}

# --- Extraction (from strings) ---

# Extract URL from a string
# Usage: extract_url "Check out https://example.com for more"
# Returns: https://example.com
extract_url() {
    (( ARGC == 1 )) || return 2
    if [[ $1 =~ '(https?://[^ ]+)' ]]; then
        print -r -- "$match[1]"
        return 0
    fi
    return 1
}

# Extract file path from a string
# Usage: extract_filepath "Error in /usr/local/bin/script.sh at line 5"
# Returns: /usr/local/bin/script.sh
extract_filepath() {
    (( ARGC == 1 )) || return 2
    if [[ $1 =~ '(/[[:alnum:]/._-]+)' ]]; then
        print -r -- "$match[1]"
        return 0
    fi
    return 1
}

# Extract version - alias for get_version (consistency with extract_* group)
functions[extract_version]=$functions[get_version]

# Trim whitespace from both ends of string
# Usage: trim "   hello world  "
# Returns: "hello world"
trim() {
    (( ARGC == 1 )) || return 1
    setopt local_options extended_glob
    print -- "${${1##[[:space:]]#}%%[[:space:]]#}"
}

# Trim whitespace from left side of string
# Usage: ltrim "  hello world"
# Returns: "hello world"
ltrim() {
    (( ARGC == 1 )) || return 1
    setopt local_options extended_glob
    print -- "${1##[[:space:]]#}"
}

# Trim whitespace from right side of string
# Usage: rtrim "hello world  "
# Returns: "hello world"
rtrim() {
    (( ARGC == 1 )) || return 1
    setopt local_options extended_glob
    print -- "${1%%[[:space:]]#}"
}

# Normalize whitespace (collapse multiple spaces/tabs/newlines into single space)
# Usage: clean_string "  hello    world  "
# Returns: "hello world"
clean_string() {
    (( ARGC == 1 )) || return 2
    print -r -- "${(j: :)${=1}}"
}

# Remove ANSI escape codes from string
# Usage: clean_ansi "$colored_text"
# Returns: plain text without color codes
clean_ansi() {
    (( ARGC == 1 )) || return 2
    # Use sed to remove ANSI escape sequences (more reliable)
    print -r -- "$1" | sed $'s/\x1b\\[[0-9;]*m//g'
}

# Convert string to lowercase
# Usage: lowercase "HELLO World"
# Returns: "hello world"
lowercase() {
    (( ARGC == 1 )) || return 1
    print -- "${1:l}"
}

# Convert string to uppercase
# Usage: uppercase "hello World"
# Returns: "HELLO WORLD"
uppercase() {
    (( ARGC == 1 )) || return 1
    print -- "${1:u}"
}

# Capitalize first letter of string (Sentence case)
# Usage: capitalize "hello WORLD"
# Returns: "Hello world"
capitalize() {
    (( ARGC == 1 )) || return 1
    # 1. Take 1st char and uppercase it: ${(U)1[1]}
    # 2. Take rest of string (2 to end) and lowercase it: ${1[2,-1]:l}
    print -- "${(U)1[1]}${1[2,-1]:l}"
}

# Convert string to title case (AP/Chicago style logic)
# Usage: title_case "nothing to be afraid of"
# Returns: "Nothing to Be Afraid Of"
titlecase() {
    (( ARGC == 1 )) || return 1
    local str="${1:l}"
    local -a words=(${(s: :)str})
    local -a result=()
    local i word len
    
    # Minor words list for English titles (defined once globally if possible, or static local)
    # Using 'state' variable to avoid redeclaring on every call if sourced multiple times
    local -a minor_words=(
        'a' 'an' 'the' 'to' 'at' 'by' 'down' 'for' 'from' 'in' 'into' 
        'like' 'near' 'of' 'off' 'on' 'onto' 'over' 'past' 'upon' 'with'
        'and' 'as' 'but' 'if' 'nor' 'once' 'or' 'so' 'than' 'that' 'till' 'when' 'yet'
    )
    
    for ((i=1; i<=${#words}; i++)); do
        word="${words[i]}"
        len=${#word}
        # First and last words are always capitalized
        if (( i == 1 || i == ${#words} )); then
            result+=("${(C)word}")
        # Words longer than 4 chars are capitalized
        elif (( len >= 5 )); then
            result+=("${(C)word}")
        # Check if it is a minor word (Reverse subscripting returns index or 0)
        elif (( ${minor_words[(I)$word]} > 0 )); then
            result+=("$word")
        else
            result+=("${(C)word}")
        fi
    done
    print -- "${(j: :)result}"
}

# Convert string to slug (URL-friendly)
# Usage: slugify "Hello World! 123"
# Returns: "hello-world-123"
slugify() {
    (( ARGC == 1 )) || return 1
    local str="${1:l}"              # Lowercase
    str=${str//[^a-z0-9]/-}         # Replace non-alnum with hyphen
    setopt local_options extended_glob
    str=${str//-(-)#/-}             # Squeeze multiple hyphens (zsh specific #)
    str=${str#-}                    # Trim leading hyphen
    str=${str%-}                    # Trim trailing hyphen
    print -- "$str"
}

# --- Inspection ---

# Check if string contains substring
# Usage: str_contains haystack needle
# Example: str_contains "hello world" "world"
# Returns: 0 (true) or 1 (false)
str_contains() {
    (( ARGC == 2 )) || return 2 # Invalid usage
    [[ "$1" == *"$2"* ]]
}

# Check if string starts with prefix
# Usage: str_starts_with text prefix
# Example: str_starts_with "hello world" "hello"
# Returns: 0 (true) or 1 (false)
str_starts_with() {
    (( ARGC == 2 )) || return 2 # Invalid usage
    [[ "$1" == "$2"* ]]
}

# Check if string ends with suffix
# Usage: str_ends_with text suffix
# Example: str_ends_with "hello world" "world"
# Returns: 0 (true) or 1 (false)
str_ends_with() {
    (( ARGC == 2 )) || return 2 # Invalid usage
    [[ "$1" == *"$2" ]]
}

# Get string length
# Usage: str_length "hello"
# Returns: 5
str_length() {
    (( ARGC == 1 )) || return 2 # Invalid usage
    print -- ${#1}
}

# Count occurrences of substring
# Usage: str_count "hello world" "l"
# Returns: 3
str_count() {
    (( ARGC == 2 )) || return 2 # Invalid usage
    local str=$1
    local sub=$2
    # Replace substring with empty, subtract lengths
    print -- $(( (${#str} - ${#${str//$sub/}}) / ${#sub} ))
}

# --- Formatting & Modification ---

# Repeat string N times
# Usage: str_repeat "-" 10
# Returns: "----------"
str_repeat() {
    (( ARGC == 2 )) || return 2 # Invalid usage
    local str=$1
    local count=$2
    (( count > 0 )) || return 2 # Non-positive count
    repeat $count print -n -- "$str"
    print  # Newline at the end
}

# Pad string to length
# Usage: str_pad <text> <len> [char] [left|right|center]
# Example: str_pad "Hello" 10 "-" "left" -> "-----Hello"
# Default char is space, default side is right
str_pad() {
    (( ARGC >= 2 )) || return 2
    local str="$1"
    local len=$2
    local char="${3:- }"
    local side="${4:-right}"
    local pad_len=$(( len - ${#str} ))

    # No padding needed
    (( pad_len <= 0 )) && { print -- "$str"; return 0; }

    # Build padding string
    local padding=""
    repeat $pad_len padding+="$char"

    case "$side" in
        left)   print -- "${padding}${str}" ;;
        right)  print -- "${str}${padding}" ;;
        center)
            local left_pad=$(( pad_len / 2 ))
            local right_pad=$(( pad_len - left_pad ))
            print -- "${padding:0:$left_pad}${str}${padding:0:$right_pad}"
            ;;
    esac
}

# Pad string on the left side
# Usage: str_pad_left "text" 10 [char]
# Example: str_pad_left "Hi" 10 "-" -> "--------Hi"
str_pad_left() {
    (( ARGC >= 2 )) && (( ARGC <= 3 )) || return 2
    str_pad "$1" "$2" "${3:- }" left
}

# Pad string on the right side
# Usage: str_pad_right "text" 10 [char]
# Example: str_pad_right "Hi" 10 "-" -> "Hi--------"
str_pad_right() {
    (( ARGC >= 2 )) && (( ARGC <= 3 )) || return 2
    str_pad "$1" "$2" "${3:- }" right
}

# Pad string on both sides (center)
# Usage: str_pad_center "text" 10 [char]
# Example: str_pad_center "Hi" 10 "-" -> "----Hi----"
str_pad_center() {
    (( ARGC >= 2 )) && (( ARGC <= 3 )) || return 2
    str_pad "$1" "$2" "${3:- }" center
}

# Reverse string
# Usage: str_reverse "hello"
# Returns: "olleh"
str_reverse() {
    (( ARGC == 1 )) || return 2
    local i result=""
    for (( i=${#1}; i>=1; i-- )); do
        result+="${1[i]}"
    done
    print -r -- "$result"
}

# Split string by delimiter into array
# Usage: str_split <string> <delimiter> <array_name>
# It handles multi-character delimiters
# Example: str_split "a:b:c" ":" arr -> arr=(a b c)
# Example: str_split "Ala, ma, kota" ", " arr -> arr=(Ala ma kota)
str_split() {
    (( ARGC == 3 )) || return 2
    local str="$1"
    local delim="$2"
    local arr_name="$3"
    local -a result=()

    # Handle multi-char delimiters with loop
    while [[ "$str" == *"$delim"* ]]; do
        result+=("${str%%$delim*}")
        str="${str#*$delim}"
    done
    result+=("$str")

    set -A $arr_name "${result[@]}"
}

# Join array elements with delimiter
# Usage: str_join <delimiter> <array_name>
# Example: str_join ":" arr -> "a:b:c" (where arr=(a b c))
str_join() {
    (( ARGC == 2 )) || return 2
    local delim="$1"
    local arr_name="$2"
    local -a arr=("${(@P)arr_name}")
    local result="" i

    for (( i=1; i<=${#arr}; i++ )); do
        (( i > 1 )) && result+="$delim"
        result+="${arr[i]}"
    done
    print -r -- "$result"
}

# Replace first occurrence of pattern with replacement
# Usage: str_replace "hello world" "world" "zsh"
# Returns: "hello zsh"
str_replace() {
    (( ARGC == 3 )) || return 1
    print -- "${1/$2/$3}"
}

# Replace all occurrences of pattern with replacement
# Usage: str_replace_all "hello world world" "world" "zsh"
# Returns: "hello zsh zsh"
str_replace_all() {
    (( ARGC == 3 )) || return 1
    print -- "${1//$2/$3}"
}

# --- Checks ---

# Check if string is empty
# Usage: is_empty "  "
# Returns: 0 (true) for empty/whitespace-only, 1 (false) otherwise
is_empty() {
    (( ARGC == 1 )) || return 1
    setopt local_options extended_glob
    [[ -z "${${1##[[:space:]]#}%%[[:space:]]#}" ]]
}

# Check if string is numeric (Integer or Float, +/-)
# Usage: is_numeric "3.14" -> 0
# Usage: is_numeric "-5"   -> 0
is_numeric() {
    (( ARGC == 1 )) || return 1
    # Regex for optional minus, digits, optional dot and decimal
    [[ "$1" =~ ^-?[0-9]+([.][0-9]+)?$ ]]
}
functions[is_number]=$functions[is_numeric]

# Check if string is strictly an integer
# Usage: is_integer "123" -> 0
# Usage: is_integer "3.14" -> 1
is_integer() {
    (( ARGC == 1 )) || return 1
    [[ "$1" =~ ^-?[0-9]+$ ]]
}

# Check if string is alphanumeric
# Usage: is_alphanumeric "abc123"
# Returns: 0 (true) or 1 (false)
is_alphanumeric() {
    (( ARGC == 1 )) || return 1
    [[ "$1" =~ ^[[:alnum:]]+$ ]]
}

# Get substring
# Usage: substring "hello world" 6 5
# Returns: "world" (start at position 6, length 5)
substring() {
    (( ARGC >= 2 && ARGC <= 3 )) || return 1
    local str="$1"
    local start=$2
    local length=${3:-${#str}}

    print -- "${str:$start:$length}"
}

# Shell files tracking - keep at the end
zfile_track_end ${0:A}