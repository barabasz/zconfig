#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# String manipulation functions
# Uses native zsh parameter expansion flags (no external tools)
# Getters print the result and also set REPLY (use REPLY to avoid subshells)
# Indexes: substring is 0-based (like ${s:offset:len}); str_index_of is 1-based
##

## Extraction

# Extract version number from a string
# Usage: get_version <text>
# Example: get_version "zsh 5.9 (x86_64)" -> 5.9
# Output: version (stdout); also sets REPLY
# Returns: 0 found, 1 not found, 2 invalid usage
get_version() {
    (( ARGC == 1 )) || return 2
    REPLY=""
    [[ $1 =~ '[0-9]+(\.[0-9]+)+' ]] || return 1
    REPLY=$MATCH
    print -r -- "$REPLY"
}
# Alias: extract_version (consistency with extract_* group)
functions[extract_version]=$functions[get_version]

# Extract URL from a string
# Usage: extract_url <text>
# Example: extract_url "Check out https://example.com for more" -> https://example.com
# Output: URL (stdout); also sets REPLY
# Returns: 0 found, 1 not found, 2 invalid usage
extract_url() {
    (( ARGC == 1 )) || return 2
    REPLY=""
    [[ $1 =~ '(https?://[^[:space:]]+)' ]] || return 1
    REPLY=$match[1]
    print -r -- "$REPLY"
}

# Extract file path from a string
# Usage: extract_filepath <text>
# Example: extract_filepath "Error in /usr/local/bin/script.sh at line 5" -> /usr/local/bin/script.sh
# Output: path (stdout); also sets REPLY
# Returns: 0 found, 1 not found, 2 invalid usage
extract_filepath() {
    (( ARGC == 1 )) || return 2
    REPLY=""
    [[ $1 =~ '(/[[:alnum:]/._-]+)' ]] || return 1
    REPLY=$match[1]
    print -r -- "$REPLY"
}

## Whitespace

# Trim whitespace from both ends of string
# Usage: trim <text>
# Example: trim "   hello world  " -> "hello world"
# Output: trimmed text (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
trim() {
    (( ARGC == 1 )) || return 2
    setopt localoptions extendedglob
    REPLY="${${1##[[:space:]]#}%%[[:space:]]#}"
    print -r -- "$REPLY"
}

# Trim whitespace from left side of string
# Usage: ltrim <text>
# Output: trimmed text (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
ltrim() {
    (( ARGC == 1 )) || return 2
    setopt localoptions extendedglob
    REPLY="${1##[[:space:]]#}"
    print -r -- "$REPLY"
}

# Trim whitespace from right side of string
# Usage: rtrim <text>
# Output: trimmed text (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
rtrim() {
    (( ARGC == 1 )) || return 2
    setopt localoptions extendedglob
    REPLY="${1%%[[:space:]]#}"
    print -r -- "$REPLY"
}

# Normalize whitespace (collapse spaces/tabs/newlines into single space, trim ends)
# Usage: clean_string <text>
# Example: clean_string "  hello    world  " -> "hello world"
# Output: normalized text (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
clean_string() {
    (( ARGC == 1 )) || return 2
    REPLY="${(j: :)${=1}}"
    print -r -- "$REPLY"
}

# Remove ANSI escape sequences (colors, cursor codes) from string
# Usage: clean_ansi <text>
# Output: plain text (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
clean_ansi() {
    (( ARGC == 1 )) || return 2
    setopt localoptions extendedglob
    # CSI sequences: ESC [ params final-byte
    REPLY="${1//$'\e'\[[0-9;?]#[@-~]/}"
    print -r -- "$REPLY"
}

## Case conversion

# Convert string to lowercase
# Usage: lowercase <text>
# Output: text (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
lowercase() {
    (( ARGC == 1 )) || return 2
    REPLY="${1:l}"
    print -r -- "$REPLY"
}

# Convert string to uppercase
# Usage: uppercase <text>
# Output: text (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
uppercase() {
    (( ARGC == 1 )) || return 2
    REPLY="${1:u}"
    print -r -- "$REPLY"
}

# Capitalize first letter of string, lowercase the rest (Sentence case)
# Usage: capitalize <text>
# Example: capitalize "hello WORLD" -> "Hello world"
# Output: text (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
capitalize() {
    (( ARGC == 1 )) || return 2
    REPLY="${(U)1[1]}${1[2,-1]:l}"
    print -r -- "$REPLY"
}

# Convert string to title case (AP/Chicago style: minor words stay lowercase)
# Usage: titlecase <text>
# Example: titlecase "nothing to be afraid of" -> "Nothing to Be Afraid Of"
# Output: text (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
titlecase() {
    (( ARGC == 1 )) || return 2
    local -a words=(${(s: :)${1:l}})
    local -a result=()
    local -i i
    local word
    local -a minor_words=(
        a an the to at by down for from in into
        like near of off on onto over past upon with
        and as but if nor once or so than that till when yet
    )

    for (( i = 1; i <= ${#words}; i++ )); do
        word="${words[i]}"
        # First and last words, words of 5+ chars and non-minor words are capitalized
        if (( i == 1 || i == ${#words} || ${#word} >= 5 || ! ${minor_words[(Ie)$word]} )); then
            result+=("${(C)word}")
        else
            result+=("$word")
        fi
    done
    REPLY="${(j: :)result}"
    print -r -- "$REPLY"
}

# Split text into words for case conversion (internal)
# Splits on non-alphanumeric characters and on camelCase boundaries
# Usage: _str_words <text>
# Sets: reply to lowercase words
_str_words() {
    local text="$1" ch prev="" word=""
    reply=()
    for ch in ${(s::)text}; do
        if [[ $ch != [[:alnum:]] ]]; then
            [[ -n $word ]] && reply+=("${word:l}")
            word=""
        elif [[ $ch == [[:upper:]] && $prev == [[:lower:][:digit:]] && -n $word ]]; then
            reply+=("${word:l}")
            word=$ch
        else
            word+=$ch
        fi
        prev=$ch
    done
    [[ -n $word ]] && reply+=("${word:l}")
    return 0
}

# Convert string to snake_case
# Usage: to_snake_case <text>
# Example: to_snake_case "Hello worldFoo-bar" -> hello_world_foo_bar
# Output: text (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
to_snake_case() {
    (( ARGC == 1 )) || return 2
    _str_words "$1"
    REPLY="${(j:_:)reply}"
    print -r -- "$REPLY"
}

# Convert string to kebab-case
# Usage: to_kebab_case <text>
# Example: to_kebab_case "Hello worldFoo_bar" -> hello-world-foo-bar
# Output: text (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
to_kebab_case() {
    (( ARGC == 1 )) || return 2
    _str_words "$1"
    REPLY="${(j:-:)reply}"
    print -r -- "$REPLY"
}

# Convert string to camelCase
# Usage: to_camel_case <text>
# Example: to_camel_case "hello world-foo" -> helloWorldFoo
# Output: text (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
to_camel_case() {
    (( ARGC == 1 )) || return 2
    _str_words "$1"
    REPLY="${reply[1]}${(j::)${(@C)reply[2,-1]}}"
    print -r -- "$REPLY"
}

# Convert string to slug (URL-friendly, ASCII only)
# Common Latin diacritics (incl. Polish) are transliterated: "Zażółć" -> "zazolc"
# Usage: slugify <text>
# Example: slugify "Hello World! 123" -> "hello-world-123"
# Output: slug (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
slugify() {
    (( ARGC == 1 )) || return 2
    setopt localoptions extendedglob
    local -A translit=(
        ą a  ć c  ę e  ł l  ń n  ó o  ś s  ź z  ż z
        á a  à a  â a  ä a  ã a  å a  æ ae ç c  č c  ď d
        é e  è e  ê e  ë e  ě e  í i  ì i  î i  ï i  ñ n
        ň n  ò o  ô o  ö o  õ o  ø o  œ oe ř r  š s  ß ss
        ť t  ú u  ù u  û u  ü u  ů u  ý y  ÿ y  ž z
    )
    local str="${1:l}" out="" ch
    for ch in ${(s::)str}; do
        out+="${translit[$ch]:-$ch}"
    done
    out=${out//[^a-z0-9]##/-}   # Non-alnum runs -> single hyphen
    out=${out#-}                # Trim leading hyphen
    REPLY=${out%-}              # Trim trailing hyphen
    print -r -- "$REPLY"
}

## Inspection

# Check if string contains substring
# Usage: str_contains <haystack> <needle>
# Returns: 0 true, 1 false, 2 invalid usage
str_contains() {
    (( ARGC == 2 )) || return 2
    [[ "$1" == *"$2"* ]]
}

# Check if string starts with prefix
# Usage: str_starts_with <text> <prefix>
# Returns: 0 true, 1 false, 2 invalid usage
str_starts_with() {
    (( ARGC == 2 )) || return 2
    [[ "$1" == "$2"* ]]
}

# Check if string ends with suffix
# Usage: str_ends_with <text> <suffix>
# Returns: 0 true, 1 false, 2 invalid usage
str_ends_with() {
    (( ARGC == 2 )) || return 2
    [[ "$1" == *"$2" ]]
}

# Get string length (characters)
# Usage: str_length <text>
# Output: length (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
str_length() {
    (( ARGC == 1 )) || return 2
    REPLY=${#1}
    print -r -- "$REPLY"
}

# Count non-overlapping occurrences of substring
# Usage: str_count <text> <substring>
# Example: str_count "hello world" "l" -> 3
# Output: count (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage (incl. empty substring)
str_count() {
    (( ARGC == 2 )) && [[ -n $2 ]] || return 2
    # Splitting by the substring gives count+1 fields (empty fields kept)
    local -a parts=("${(@ps:$2:)1}")
    REPLY=$(( ${#parts} - 1 ))
    (( REPLY < 0 )) && REPLY=0
    print -r -- "$REPLY"
}

# Get position of first occurrence of substring (1-based)
# Usage: str_index_of <text> <substring>
# Example: str_index_of "hello world" "wor" -> 7
# Output: index, or -1 if not found (stdout); also sets REPLY
# Returns: 0 found, 1 not found, 2 invalid usage
str_index_of() {
    (( ARGC == 2 )) && [[ -n $2 ]] || return 2
    local prefix="${1%%"$2"*}"
    if [[ "$prefix" == "$1" ]]; then
        REPLY=-1
        print -r -- "$REPLY"
        return 1
    fi
    REPLY=$(( ${#prefix} + 1 ))
    print -r -- "$REPLY"
}

## Formatting and modification

# Remove one level of shell quoting
# Usage: str_unquote <text>
# Example: str_unquote '"hello world"' -> hello world
# Output: text (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
str_unquote() {
    (( ARGC == 1 )) || return 2
    REPLY="${(Q)1}"
    print -r -- "$REPLY"
}

# Decode a JSON string literal (with surrounding quotes)
# Usage: str_json_decode <json_string>
# Example: str_json_decode '"hello\nworld"' -> hello<newline>world
# Output: decoded text (stdout); also sets REPLY
# Returns: 0 success, 1 invalid JSON string, 2 invalid usage
str_json_decode() {
    (( ARGC == 1 )) || return 2

    local input="$1"
    local result="" char esc hex low_hex
    local -i i=2 len=${#input}
    local -i codepoint high low

    (( len >= 2 )) || return 1
    [[ "${input[1]}" == '"' && "${input[-1]}" == '"' ]] || return 1

    while (( i < len )); do
        char="${input[i]}"

        if [[ "$char" != '\' ]]; then
            result+="$char"
            (( i++ ))
            continue
        fi

        (( i + 1 < len )) || return 1
        esc="${input[i+1]}"

        case "$esc" in
            '"') result+='"';   (( i += 2 )) ;;
            '\') result+='\';   (( i += 2 )) ;;
            '/') result+='/';   (( i += 2 )) ;;
            'b') result+=$'\b'; (( i += 2 )) ;;
            'f') result+=$'\f'; (( i += 2 )) ;;
            'n') result+=$'\n'; (( i += 2 )) ;;
            'r') result+=$'\r'; (( i += 2 )) ;;
            't') result+=$'\t'; (( i += 2 )) ;;

            'u')
                (( i + 5 < len )) || return 1
                hex="${input[i+2,i+5]}"
                [[ "$hex" == [[:xdigit:]][[:xdigit:]][[:xdigit:]][[:xdigit:]] ]] || return 1

                codepoint=$(( 16#$hex ))
                (( i += 6 ))

                # UTF-16 surrogate pair
                if (( codepoint >= 0xD800 && codepoint <= 0xDBFF )); then
                    (( i + 5 < len )) || return 1
                    [[ "${input[i]}" == '\' && "${input[i+1]}" == 'u' ]] || return 1

                    low_hex="${input[i+2,i+5]}"
                    [[ "$low_hex" == [[:xdigit:]][[:xdigit:]][[:xdigit:]][[:xdigit:]] ]] || return 1

                    low=$(( 16#$low_hex ))
                    (( low >= 0xDC00 && low <= 0xDFFF )) || return 1

                    high=$codepoint
                    codepoint=$(( 0x10000 + ((high - 0xD800) << 10) + (low - 0xDC00) ))
                    (( i += 6 ))
                elif (( codepoint >= 0xDC00 && codepoint <= 0xDFFF )); then
                    return 1
                fi

                # (#) converts a character code to the character (no subshell)
                result+="${(#)codepoint}"
                ;;

            *)
                return 1
                ;;
        esac
    done

    REPLY="$result"
    print -r -- "$REPLY"
}

# Repeat string N times
# Usage: str_repeat <text> <count>
# Example: str_repeat "-" 10 -> "----------"
# Output: repeated text (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
str_repeat() {
    (( ARGC == 2 )) && [[ $2 == <-> ]] || return 2
    local -i total=$(( ${#1} * $2 ))
    REPLY="${(pr:total::$1:)}"
    print -r -- "$REPLY"
}

# Pad string to length
# Usage: str_pad <text> <length> [char] [left|right|center]
# Example: str_pad "Hello" 10 "-" left -> "-----Hello"
# Default char is space, default side is right (text aligned left)
# Output: padded text (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
str_pad() {
    (( ARGC >= 2 && ARGC <= 4 )) && [[ $2 == <-> ]] || return 2
    local str="$1"
    local char="${3:- }"
    local side="${4:-right}"
    local -i pad_len=$(( $2 - ${#str} ))
    local -i left_len right_len

    if (( pad_len <= 0 )); then
        REPLY="$str"
        print -r -- "$REPLY"
        return 0
    fi

    case "$side" in
        left)   left_len=$pad_len; right_len=0 ;;
        right)  left_len=0; right_len=$pad_len ;;
        center) left_len=$(( pad_len / 2 )); right_len=$(( pad_len - left_len )) ;;
        *)      return 2 ;;
    esac
    # (r) repeats a multi-character pad string and cuts it to the exact length
    REPLY="${(pr:left_len::$char:)}${str}${(pr:right_len::$char:)}"
    print -r -- "$REPLY"
}

# Pad string on the left side (text aligned right)
# Usage: str_pad_left <text> <length> [char]
# Example: str_pad_left "Hi" 10 "-" -> "--------Hi"
# Returns: 0 success, 2 invalid usage
str_pad_left() {
    (( ARGC >= 2 && ARGC <= 3 )) || return 2
    str_pad "$1" "$2" "${3:- }" left
}

# Pad string on the right side (text aligned left)
# Usage: str_pad_right <text> <length> [char]
# Example: str_pad_right "Hi" 10 "-" -> "Hi--------"
# Returns: 0 success, 2 invalid usage
str_pad_right() {
    (( ARGC >= 2 && ARGC <= 3 )) || return 2
    str_pad "$1" "$2" "${3:- }" right
}

# Pad string on both sides (center)
# Usage: str_pad_center <text> <length> [char]
# Example: str_pad_center "Hi" 10 "-" -> "----Hi----"
# Returns: 0 success, 2 invalid usage
str_pad_center() {
    (( ARGC >= 2 && ARGC <= 3 )) || return 2
    str_pad "$1" "$2" "${3:- }" center
}

# Truncate string to a maximum display width, appending an ellipsis
# Usage: str_truncate <text> <width> [ellipsis]
# Example: str_truncate "Hello world" 8 -> "Hello w…"
# Output: text (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
str_truncate() {
    (( ARGC >= 2 && ARGC <= 3 )) && [[ $2 == <-> ]] || return 2
    local str="$1" ellipsis="${3-…}"
    local -i width=$2
    if (( ${(m)#str} <= width )); then
        REPLY="$str"
    else
        # (m) = display width, so wide characters and emoji are handled correctly
        local -i room=$(( width - ${(m)#ellipsis} ))
        (( room < 0 )) && room=0
        while (( ${(m)#str} > room )); do
            str="${str[1,-2]}"
        done
        REPLY="${str}${ellipsis}"
    fi
    print -r -- "$REPLY"
}

# Wrap text to a given width (breaks on spaces, words longer than width are kept)
# Usage: str_wrap <text> [width]   (default width: $COLUMNS or 80)
# Output: wrapped lines (stdout); also sets reply to the lines
# Returns: 0 success, 2 invalid usage
str_wrap() {
    (( ARGC >= 1 && ARGC <= 2 )) || return 2
    local -i width=${2:-${COLUMNS:-80}}
    (( width > 0 )) || return 2
    local word line=""
    reply=()
    for word in ${=1}; do
        if [[ -z $line ]]; then
            line=$word
        elif (( ${(m)#line} + 1 + ${(m)#word} <= width )); then
            line+=" $word"
        else
            reply+=("$line")
            line=$word
        fi
    done
    [[ -n $line ]] && reply+=("$line")
    print -rl -- $reply
}

# Reverse string
# Usage: str_reverse <text>
# Example: str_reverse "hello" -> "olleh"
# Output: text (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
str_reverse() {
    (( ARGC == 1 )) || return 2
    # (s::) splits into characters, (Oa) reverses array order, (j::) joins
    REPLY="${(j::)${(@Oa)${(@s::)1}}}"
    print -r -- "$REPLY"
}

# Split string by delimiter (single or multi-character) into array
# Usage: str_split <text> <delimiter> <array_name>
# Example: str_split "a:b:c" ":" arr -> arr=(a b c)
# Example: str_split "Ala, ma, kota" ", " arr -> arr=(Ala ma kota)
# Empty fields are kept: str_split "a,,b" "," arr -> arr=(a "" b)
# Returns: 0 success, 2 invalid usage (incl. empty delimiter)
str_split() {
    (( ARGC == 3 )) && [[ -n $2 ]] || return 2
    set -A "$3" "${(@ps:$2:)1}"
}

# Join array elements with delimiter
# Usage: str_join <delimiter> <array_name>
# Example: str_join ":" arr -> "a:b:c" (where arr=(a b c))
# Output: joined text (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
str_join() {
    (( ARGC == 2 )) || return 2
    local sep="$1"
    # (p) allows a variable as the join separator
    REPLY="${(pj:$sep:)${(@P)2}}"
    print -r -- "$REPLY"
}

# Replace first occurrence of substring with replacement (literal, no patterns)
# Usage: str_replace <text> <search> <replacement>
# Example: str_replace "hello world" "world" "zsh" -> "hello zsh"
# Output: text (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
str_replace() {
    (( ARGC == 3 )) || return 2
    REPLY="${1/"$2"/$3}"
    print -r -- "$REPLY"
}

# Replace all occurrences of substring with replacement (literal, no patterns)
# Usage: str_replace_all <text> <search> <replacement>
# Example: str_replace_all "hello world world" "world" "zsh" -> "hello zsh zsh"
# Output: text (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
str_replace_all() {
    (( ARGC == 3 )) || return 2
    REPLY="${1//"$2"/$3}"
    print -r -- "$REPLY"
}

# Convert string to JSON-ready Unicode escape sequences
# Characters outside the BMP are encoded as UTF-16 surrogate pairs
# Usage: str_to_unicode <text> [text...]
# Example: str_to_unicode "⌘" -> ⌘, str_to_unicode "😀" -> 😀
# Output: escaped text (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
str_to_unicode() {
    (( ARGC >= 1 )) || return 2
    local input="$*" char out="" part
    local -i code
    for char in "${(@s::)input}"; do
        code=$(( #char ))
        if (( code > 0xFFFF )); then
            (( code -= 0x10000 ))
            printf -v part '\\u%04X\\u%04X' $(( 0xD800 + (code >> 10) )) $(( 0xDC00 + (code & 0x3FF) ))
        else
            printf -v part '\\u%04X' $code
        fi
        out+=$part
    done
    REPLY="$out"
    print -r -- "$REPLY"
}

# URL-encode a string (RFC 3986 unreserved characters are kept)
# Usage: url_encode <text>
# Example: url_encode "a b&ą" -> a%20b%26%C4%85
# Output: encoded text (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
url_encode() {
    (( ARGC == 1 )) || return 2
    # Byte-wise processing: C locale splits multibyte characters into bytes
    local LC_ALL=C
    local ch out="" part
    for ch in "${(@s::)1}"; do
        if [[ $ch == [A-Za-z0-9._~-] ]]; then
            out+=$ch
        else
            printf -v part '%%%02X' "'$ch"
            out+=$part
        fi
    done
    REPLY="$out"
    print -r -- "$REPLY"
}

# Decode a URL-encoded string (+ is decoded as space)
# Usage: url_decode <text>
# Example: url_decode "a%20b%26%C4%85" -> "a b&ą"
# Output: decoded text (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
url_decode() {
    (( ARGC == 1 )) || return 2
    setopt localoptions extendedglob
    local str="${1//+/ }"
    str="${str//\\/\\\\}"       # Protect literal backslashes from %b
    # Only valid %XX sequences are decoded; a lone "%" stays as it is
    str="${str//(#b)%([[:xdigit:]][[:xdigit:]])/\\x$match[1]}"
    printf -v REPLY '%b' "$str"
    print -r -- "$REPLY"
}

# Get substring (0-based offset, like ${text:offset:length})
# Usage: substring <text> <offset> [length]
# Example: substring "hello world" 6 5 -> "world"
# Output: text (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
substring() {
    (( ARGC >= 2 && ARGC <= 3 )) || return 2
    [[ $2 == (|-)<-> && ${3:-0} == (|-)<-> ]] || return 2
    local str="$1"
    local -i start=$2
    local -i length=${3:-${#str}}
    REPLY="${str:$start:$length}"
    print -r -- "$REPLY"
}

## Checks

# Check if string is empty or whitespace-only
# Usage: is_empty <text>
# Returns: 0 true, 1 false, 2 invalid usage
is_empty() {
    (( ARGC == 1 )) || return 2
    [[ $1 != *[^[:space:]]* ]]
}

# Check if string is numeric (integer or decimal, optional sign: 5, -5, +1.5, .5, 2.)
# Usage: is_numeric <text>
# Returns: 0 true, 1 false, 2 invalid usage
is_numeric() {
    (( ARGC == 1 )) || return 2
    [[ "$1" =~ '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$' ]]
}

# Check if string is strictly an integer (optional sign)
# Usage: is_integer <text>
# Example: is_integer "123" -> 0, is_integer "3.14" -> 1
# Returns: 0 true, 1 false, 2 invalid usage
is_integer() {
    (( ARGC == 1 )) || return 2
    [[ "$1" =~ '^[+-]?[0-9]+$' ]]
}

# Check if string is alphanumeric (letters and digits only, not empty)
# Usage: is_alphanumeric <text>
# Returns: 0 true, 1 false, 2 invalid usage
is_alphanumeric() {
    (( ARGC == 1 )) || return 2
    [[ -n $1 && $1 != *[^[:alnum:]]* ]]
}

# Check if string contains letters and none of them are lowercase
# Usage: is_upper <text>
# Returns: 0 true, 1 false, 2 invalid usage
is_upper() {
    (( ARGC == 1 )) || return 2
    [[ $1 == *[[:upper:]]* && $1 != *[[:lower:]]* ]]
}

# Check if string contains letters and none of them are uppercase
# Usage: is_lower <text>
# Returns: 0 true, 1 false, 2 invalid usage
is_lower() {
    (( ARGC == 1 )) || return 2
    [[ $1 == *[[:lower:]]* && $1 != *[[:upper:]]* ]]
}

# Shell files tracking - keep at the end
zfile_track_end ${0:A}
