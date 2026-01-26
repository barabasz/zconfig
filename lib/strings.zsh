#!/bin/zsh
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# String manipulation functions
# Uses native Zsh parameter expansion flags for performance

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
title_case() {
    (( ARGC == 1 )) || return 1
    local str="${1:l}"
    local -a words=(${(s: :)str})
    local -a result=()
    local i word len
    # Minor words list for English titles
    local -a minor_words=(
        'a' 'an' 'the' 'to'
        'at' 'by' 'down' 'for' 'from' 'in' 'into' 'like' 'near' 'of' 'off' 'on' 'onto' 'over' 'past' 'upon' 'with'
        'and' 'as' 'but' 'if' 'nor' 'once' 'or' 'so' 'than' 'that' 'till' 'when' 'yet'
    )
    for ((i=1; i<=${#words}; i++)); do
        word="${words[i]}"
        len=${#word}
        if (( i == 1 || i == ${#words} )); then
            result+=("${(C)word}")
        elif (( len >= 5 )); then
            result+=("${(C)word}")
        elif (( ${minor_words[(I)$word]} > 0 )); then
            result+=("$word")
        else
            result+=("${(C)word}")
        fi
    done
    print -- "${(j: :)result}"
}

# Check if string contains substring
# Usage: str_contains "hello world" "world"
# Returns: 0 (true) or 1 (false)
str_contains() {
    (( ARGC == 2 )) || return 1
    # Using Zsh pattern matching
    [[ "$1" == *"$2"* ]]
}

# Check if string starts with prefix
# Usage: str_starts_with "hello world" "hello"
# Returns: 0 (true) or 1 (false)
str_starts_with() {
    (( ARGC == 2 )) || return 1
    [[ "$1" == "$2"* ]]
}

# Check if string ends with suffix
# Usage: str_ends_with "hello world" "world"
# Returns: 0 (true) or 1 (false)
str_ends_with() {
    (( ARGC == 2 )) || return 1
    [[ "$1" == *"$2" ]]
}

# Get string length
# Usage: str_length "hello"
# Returns: 5
str_length() {
    (( ARGC == 1 )) || return 1
    print -- ${#1}
}

# Repeat string N times
# Usage: str_repeat "-" 10
# Returns: "----------"
str_repeat() {
    (( ARGC == 2 )) || return 1
    local str="$1"
    local count=$2

    (( count > 0 )) || return 1
    
    # 'repeat' is a Zsh builtin, much faster than a for loop
    repeat $count print -n -- "$str"
    print "" # Newline at the end
}

# Reverse string
# Usage: str_reverse "hello"
# Returns: "olleh"
str_reverse() {
    (( ARGC == 1 )) || return 1
    # Zsh magic:
    # (s::) - split string into characters (empty separator)
    # (Oa)  - reverse array order
    # (j::) - join array back into string
    print -- "${(j::)${(Oa)${(s::)1}}}"
}

# Split string by delimiter into array
# Usage: str_split "a:b:c" ":" arr
# Sets array variable arr=(a b c)
str_split() {
    (( ARGC == 3 )) || return 1
    local str="$1"
    local delim="$2"
    local arr_name="$3"

    # 'set -A' is the standard Zsh way to assign arrays by name
    # (@s[$delim]) splits the string based on delimiter
    set -A $arr_name "${(@s[$delim])str}"
}

# Join array elements with delimiter
# Usage: str_join ":" arr
# Returns: "a:b:c" (where arr=(a b c))
str_join() {
    (( ARGC == 2 )) || return 1
    local delim="$1"
    local arr_name="$2"

    # Fixed syntax: use ${(P)var} to dereference array content first, then join
    print -- "${(j[$delim])${(P)arr_name}}"
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

# Check if string is empty
# Usage: is_empty "  "
# Returns: 0 (true) for empty/whitespace-only, 1 (false) otherwise
is_empty() {
    (( ARGC == 1 )) || return 1
    setopt local_options extended_glob
    [[ -z "${${1##[[:space:]]#}%%[[:space:]]#}" ]]
}

# Check if string is numeric
# Usage: is_numeric "123"
# Returns: 0 (true) or 1 (false)
is_numeric() {
    (( ARGC == 1 )) || return 1
    # <-> matches any range of numbers in Zsh globbing (if extended_glob is on),
    # but regex is safer for strict numeric check including negatives
    [[ "$1" =~ '^-?[0-9]+$' ]]
}

# Check if string is alphanumeric
# Usage: is_alphanumeric "abc123"
# Returns: 0 (true) or 1 (false)
is_alphanumeric() {
    (( ARGC == 1 )) || return 1
    [[ "$1" =~ '^[[:alnum:]]+$' ]]
}

# Get substring
# Usage: substring "hello world" 6 5
# Returns: "world" (start at position 6, length 5)
# Note: Zsh variable slicing ${var:offset:length} is 0-based
substring() {
    (( ARGC >= 2 && ARGC <= 3 )) || return 1
    local str="$1"
    local start=$2
    local length=${3:-${#str}}

    print -- "${str:$start:$length}"
}

# shell files tracking - keep at the end
zfile_track_end ${0:A}