#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# Array manipulation utilities
##

# Check if array contains element (exact match)
# Usage: array_contains arr_name "element"
# Returns: 0 on success, 1 on failure, 2 on invalid usage
array_contains() {
    (( ARGC == 2 )) || return 2
    # (Ie) flag: I=Reverse scan returning index, e=exact matching
    # If index is non-zero, element exists
    (( ${${(P)1}[(Ie)$2]} ))
}

# Get unique elements from array
# Usage: array_unique arr_name result_arr_name
# Sets result_arr to unique elements
array_unique() {
    (( ARGC == 2 )) || return 2
    local -a src=("${(@P)1}")
    set -A $2 "${(u)src[@]}"
}

# Get array length
# Usage: array_length arr_name | array_length str_name
# Returns: number of elements | length of string
# Returns error code 2 on invalid usage
# (for zsh strings are treated as single-element arrays)
array_length() {
    (( ARGC == 1 )) || return 2
    print -- ${#${(P)1}}
}

# Check if array is empty
# Usage: array_is_empty arr_name
# Returns: 0 on success, 1 on failure, 2 on invalid usage
array_is_empty() {
    (( ARGC == 1 )) || return 2
    (( ${#${(P)1}} == 0 ))
}

# Check if array/variable is initialized
# Usage: is_array_initialized arr_name
# Returns: 0 on success, 1 on failure, 2 on invalid usage
is_array_initialized() {
    (( ARGC == 1 )) || return 2
    # Check if parameter is set
    (( ${+parameters[$1]} ))
}

# Get first element of an array
# Usage: array_first arr_name
# Returns: first element or error code 2 on invalid usage
# Note: Zsh arrays are 1-based
array_first() {
    (( ARGC == 1 )) || return 2
    # Zsh arrays are 1-based
    print -- "${${(P)1}[1]}"
}

# Get last element of array
# Usage: array_last arr_name
# Returns: last element or error code 2 on invalid usage
array_last() {
    (( ARGC == 1 )) || return 2
    # Negative index accesses from end
    print -- "${${(P)1}[-1]}"
}

# Append element(s) to array
# Usage: array_push arr_name "element" [element2...]
# Returns: 0 on success, 1 on failure, 2 on invalid usage
array_push() {
    (( ARGC >= 2 )) || return 2
    local name=$1
    shift
    # Safe eval with quoting (q) to handle spaces/special chars
    eval "$name+=(${(q)argv})"
}

# Remove and return last element from array
# Usage: array_pop arr_name
# Sets REPLY to last element and modifies array
# Note: Use REPLY instead of $() to avoid subshell issues
# Returns: 0 on success, 1 if array is empty, 2 on invalid usage
array_pop() {
    (( ARGC == 1 )) || return 2
    local name=$1
    local -a src=("${(@P)name}")

    (( ${#src} > 0 )) || return 1

    REPLY="${src[-1]}"
    # Remove last element
    eval "$name=(\"\${src[@]:0:\${#src}-1}\")"
    return 0
}

# Remove and return first element from array
# Usage: array_shift arr_name
# Sets REPLY to first element and modifies array
# Note: Use REPLY instead of $() to avoid subshell issues
# Returns: 0 on success, 1 if array is empty, 2 on invalid usage
array_shift() {
    (( ARGC == 1 )) || return 2
    local name=$1
    local -a src=("${(@P)name}")

    (( ${#src} > 0 )) || return 1

    REPLY="${src[1]}"
    # Remove first element
    eval "$name=(\"\${src[@]:1}\")"
    return 0
}

# Add element(s) to beginning of array
# Usage: array_unshift arr_name "element" [element2...]
# Returns: 0 on success (modifies array), 1 on failure, 2 on invalid usage
array_unshift() {
    (( ARGC >= 2 )) || return 1
    local name=$1
    shift
    # Prepend to array using safe quoting
    eval "$name=(${(q)argv} \${(@P)name})"
}

# Reverse array
# Usage: array_reverse arr_name result_arr_name
# Sets result_arr to reversed array
# Returns error code 2 on invalid usage
array_reverse() {
    (( ARGC == 2 )) || return 2
    local -a src=("${(@P)1}")
    set -A $2 "${(Oa)src[@]}"
}

# Sort array
# Usage: array_sort arr_name result_arr_name
# Sets result_arr to sorted array
# Returns error code 2 on invalid usage
array_sort() {
    (( ARGC == 2 )) || return 2
    local -a src=("${(@P)1}")
    set -A $2 "${(o)src[@]}"
}

# Sort array in reverse order
# Usage: array_sort_reverse arr_name result_arr_name
# Sets result_arr to reverse sorted array
# Returns error code 2 on invalid usage
array_sort_reverse() {
    (( ARGC == 2 )) || return 2
    local -a src=("${(@P)1}")
    set -A $2 "${(O)src[@]}"
}

# Get index of element in array
# Usage: array_index_of arr_name "element"
# Returns: index (1-based) or -1 if not found
# Returns error code 2 on invalid usage
array_index_of() {
    (( ARGC == 2 )) || return 2
    local idx
    # (ie) flag: returns index of exact match, or length+1 if not found
    idx=${${(P)1}[(ie)$2]}
    
    if (( idx <= ${#${(P)1}} )); then
        print -- $idx
        return 0
    fi
    print "-1"
    return 1
}

# Slice array
# Usage: array_slice arr_name start [length] result_arr_name
# Sets result_arr to sliced array
# If length is omitted, slices from start to end
# Returns error code 2 on invalid usage
array_slice() {
    (( ARGC >= 3 && ARGC <= 4 )) || return 2
    local source=$1
    local start=$2
    local len=$3
    local target=${4:-$3} # Default to overwriting source if no target provided
    
    # Handling optional length argument logic
    if (( ARGC == 3 )); then
        target=$3
        # Slice from start to end
        set -A $target "${(@)${(P)source}[$start,-1]}"
    else
        # Slice specific range
        set -A $target "${(@)${(P)source}[$start,$start+$len-1]}"
    fi
}

# Filter array by pattern
# Usage: array_filter arr_name "pattern" result_arr_name
# Sets result_arr to elements matching pattern
# Returns error code 2 on invalid usage
array_filter() {
    (( ARGC == 3 )) || return 2
    local -a src=("${(@P)1}")
    local pattern="$2"
    set -A $3 "${(M)src[@]:#${~pattern}}"
}

# Map array through function
# Usage: array_map arr_name function_name result_arr_name
# Note: The mapped function MUST set the variable $REPLY instead of printing
# Returns error code 2 on invalid usage
array_map() {
    (( ARGC == 3 )) || return 2
    local src=$1
    local func=$2
    local target=$3
    local -a result
    local item

    for item in "${(@P)src}"; do
        # Call function, expect result in REPLY (avoids subshell)
        $func "$item"
        result+=("$REPLY")
    done
    set -A $target "${result[@]}"
}

# Join array with separator
# Usage: array_join arr_name ","
# Returns: joined string
# Returns error code 2 on invalid usage
array_join() {
    (( ARGC == 2 )) || return 2
    local -a src=("${(@P)1}")
    local sep="$2"
    local result="" i

    for (( i=1; i<=${#src}; i++ )); do
        (( i > 1 )) && result+="$sep"
        result+="${src[i]}"
    done
    print -r -- "$result"
}

# Remove element from array by value
# Usage: array_remove arr_name "element"
# Modifies array by removing all occurrences
# Returns error code 2 on invalid usage
array_remove() {
    (( ARGC == 2 )) || return 2
    # :# pattern removal operator
    set -A $1 "${(@)${(P)1}:#$2}"
}

# Remove element from array by index
# Usage: array_remove_at arr_name index
# Modifies array by removing element at index
# Returns error code 2 on invalid usage
array_remove_at() {
    (( ARGC == 2 )) || return 2
    local idx=$2
    # Setting an element to empty list () removes it in Zsh
    eval "$1[$idx]=()"
}

# Flatten nested arrays (split string elements by space)
# Usage: array_flatten arr_name result_arr_name
# Sets result_arr to flattened array
# Returns error code 2 on invalid usage
array_flatten() {
    (( ARGC == 2 )) || return 2
    # ${=var} performs word splitting on expansion
    set -A $2 ${=${(P)1}}
}

# Concatenate multiple arrays
# Usage: array_concat arr1 arr2 [arr3...] result_arr_name
# Sets result_arr to concatenated arrays
# Returns error code 2 on invalid usage
array_concat() {
    (( ARGC >= 3 )) || return 2
    # Zsh slicing [1,-2] to get all but last arg
    local -a arrays=( $argv[1,-2] )
    local target="${argv[-1]}"
    local -a result=()
    local arr

    for arr in $arrays; do
        result+=("${(@P)arr}")
    done
    set -A $target "${result[@]}"
}

# Check if all elements match predicate
# Usage: array_every arr_name function_name
# Returns: 0 (true) if all match, 1 (false) otherwise
# Returns error code 2 on invalid usage
array_every() {
    (( ARGC == 2 )) || return 2
    local func=$2
    local item
    for item in "${(@P)1}"; do
        $func "$item" || return 1
    done
    return 0
}

# Check if any element matches predicate
# Usage: array_some arr_name function_name
# Returns: 0 (true) if any match, 1 (false) otherwise
# Returns error code 2 on invalid usage
array_some() {
    (( ARGC == 2 )) || return 2
    local func=$2
    local item
    for item in "${(@P)1}"; do
        $func "$item" && return 0
    done
    return 1
}

# Get array intersection (common elements)
# Usage: array_intersect arr1_name arr2_name result_arr_name
# Sets result_arr to common elements
# Returns error code 2 on invalid usage
array_intersect() {
    (( ARGC == 3 )) || return 2
    local -a src1=("${(@P)1}")
    local -a src2=("${(@P)2}")
    local -a result=()
    local item

    for item in "${src1[@]}"; do
        # Check if item exists in src2
        (( ${src2[(Ie)$item]} )) && result+=("$item")
    done
    set -A $3 "${result[@]}"
}

# Get array difference (elements in arr1 but not in arr2)
# Usage: array_diff arr1_name arr2_name result_arr_name
# Sets result_arr to difference (subtracts arr2 from arr1)
# Returns error code 2 on invalid usage
array_diff() {
    (( ARGC == 3 )) || return 2
    local -a src1=("${(@P)1}")
    local -a src2=("${(@P)2}")
    local -a result=()
    local item

    for item in "${src1[@]}"; do
        # Check if item does NOT exist in src2
        (( ${src2[(Ie)$item]} )) || result+=("$item")
    done
    set -A $3 "${result[@]}"
}

# Print array elements (for debugging)
# Usage: array_print arr_name
# Prints each element on a new line
# Returns error code 2 on invalid usage
array_print() {
    (( ARGC == 1 )) || return 2
    # print -l prints elements on separate lines
    print -l -- "${(@P)1}"
}

# shell files tracking - keep at the end
zfile_track_end ${0:A}