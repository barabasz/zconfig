#!/bin/zsh
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# Check if array contains element (exact match)
# Usage: array_contains arr_name "element"
# Returns: 0 (true) or 1 (false)
array_contains() {
    (( ARGC == 2 )) || return 1
    # (Ie) flag: I=Reverse scan returning index, e=exact matching
    # If index is non-zero, element exists
    (( ${${(P)1}[(Ie)$2]} ))
}

# Get unique elements from array
# Usage: array_unique arr_name result_arr_name
# Sets result_arr to unique elements
array_unique() {
    (( ARGC == 2 )) || return 1
    # (u) flag: unique elements
    set -A $2 "${(u)${(P)1}}"
}

# Get array length
# Usage: array_length arr_name
# Returns: number of elements
array_length() {
    (( ARGC == 1 )) || return 1
    print -- ${#${(P)1}}
}

# Check if array is empty
# Usage: array_is_empty arr_name
# Returns: 0 (true) or 1 (false)
array_is_empty() {
    (( ARGC == 1 )) || return 1
    (( ${#${(P)1}} == 0 ))
}

# Check if array/variable is initialized
# Usage: is_array_initialized arr_name
# Returns: 0 (true) if initialized, 1 (false) otherwise
is_array_initialized() {
    (( ARGC == 1 )) || return 1
    # Check if parameter is set
    (( ${+parameters[$1]} ))
}

# Get first element of array
# Usage: array_first arr_name
# Returns: first element
array_first() {
    (( ARGC == 1 )) || return 1
    # Zsh arrays are 1-based
    print -- "${${(P)1}[1]}"
}

# Get last element of array
# Usage: array_last arr_name
# Returns: last element
array_last() {
    (( ARGC == 1 )) || return 1
    # Negative index accesses from end
    print -- "${${(P)1}[-1]}"
}

# Append element to array
# Usage: array_push arr_name "element"
# Returns: 0 on success (modifies array)
array_push() {
    (( ARGC == 2 )) || return 1
    # Ordinary assignment works by appending to name
    eval "$1+=('$2')"
}

# Remove and return last element from array
# Usage: array_pop arr_name
# Returns: last element and modifies array
array_pop() {
    (( ARGC == 1 )) || return 1
    local name=$1
    local val="${${(P)name}[-1]}"
    
    [[ -n $val ]] || return 1
    
    print -- "$val"
    # Remove last element by setting it to empty list
    eval "$name[-1]=()"
    return 0
}

# Remove and return first element from array
# Usage: array_shift arr_name
# Returns: first element and modifies array
array_shift() {
    (( ARGC == 1 )) || return 1
    local name=$1
    local val="${${(P)name}[1]}"
    
    [[ -n $val ]] || return 1
    
    print -- "$val"
    # Remove first element
    eval "$name[1]=()"
    return 0
}

# Add element to beginning of array
# Usage: array_unshift arr_name "element"
# Returns: 0 on success (modifies array)
array_unshift() {
    (( ARGC == 2 )) || return 1
    local name=$1
    local val=$2
    # Prepend to array
    eval "$name=('$val' \"\${(@P)name}\")"
}

# Reverse array
# Usage: array_reverse arr_name result_arr_name
# Sets result_arr to reversed array
array_reverse() {
    (( ARGC == 2 )) || return 1
    # (Oa) flag: reverse array order
    set -A $2 "${(Oa)${(P)1}}"
}

# Sort array
# Usage: array_sort arr_name result_arr_name
# Sets result_arr to sorted array
array_sort() {
    (( ARGC == 2 )) || return 1
    # (o) flag: sort ascending
    set -A $2 "${(o)${(P)1}}"
}

# Sort array in reverse order
# Usage: array_sort_reverse arr_name result_arr_name
# Sets result_arr to reverse sorted array
array_sort_reverse() {
    (( ARGC == 2 )) || return 1
    # (O) flag: sort descending
    set -A $2 "${(O)${(P)1}}"
}

# Get index of element in array
# Usage: array_index_of arr_name "element"
# Returns: index (1-based) or -1 if not found
array_index_of() {
    (( ARGC == 2 )) || return 1
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
array_slice() {
    (( ARGC >= 3 && ARGC <= 4 )) || return 1
    local source=$1
    local start=$2
    local len=$3
    local target=${4:-$3}
    
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
array_filter() {
    (( ARGC == 3 )) || return 1
    # (M) flag: Match - keep elements matching pattern
    set -A $3 "${(M)${(P)1}:#${~2}}"
}

# Map array through function
# Usage: array_map arr_name function_name result_arr_name
# Sets result_arr to transformed elements
array_map() {
    (( ARGC == 3 )) || return 1
    local src=$1
    local func=$2
    local target=$3
    local -a output=()
    local item

    # Loop is unavoidable here if calling external function/command
    for item in "${(@P)src}"; do
        output+=("$($func "$item")")
    done
    set -A $target "${output[@]}"
}

# Join array with separator
# Usage: array_join arr_name ","
# Returns: joined string
array_join() {
    (( ARGC == 2 )) || return 1
    # (j) flag: join with separator
    # Fixed syntax: use ${(P)var} to dereference array content first
    print -- "${(j[$2])${(P)1}}"
}

# Remove element from array by value
# Usage: array_remove arr_name "element"
# Modifies array by removing all occurrences
array_remove() {
    (( ARGC == 2 )) || return 1
    # :# pattern removal operator (empty replacement removes element)
    # (@) flag preserves array structure
    set -A $1 "${(@)${(P)1}:#$2}"
}

# Remove element from array by index
# Usage: array_remove_at arr_name index
# Modifies array by removing element at index
array_remove_at() {
    (( ARGC == 2 )) || return 1
    local idx=$2
    # Setting an element to empty list () removes it in Zsh
    eval "$1[$idx]=()"
}

# Flatten nested arrays
# Note: Zsh arrays are naturally 1D. This function assumes 
# the goal is to split string elements containing spaces.
# Usage: array_flatten arr_name result_arr_name
array_flatten() {
    (( ARGC == 2 )) || return 1
    # ${=var} performs word splitting on expansion
    # Fixed syntax: use ${(P)var} for reliable indirect expansion
    set -A $2 ${=${(P)1}}
}

# Concatenate multiple arrays
# Usage: array_concat arr1 arr2 [arr3...] result_arr_name
array_concat() {
    (( ARGC >= 3 )) || return 1
    local -a arrays=("${@:1:ARGC-1}")
    local target="${@: -1}"
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
array_every() {
    (( ARGC == 2 )) || return 1
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
array_some() {
    (( ARGC == 2 )) || return 1
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
array_intersect() {
    (( ARGC == 3 )) || return 1
    # :* is the array intersection operator in Zsh
    set -A $3 "${(@)${(P)1}:*${(P)2}}"
}

# Get array difference (elements in arr1 but not in arr2)
# Usage: array_diff arr1_name arr2_name result_arr_name
# Sets result_arr to difference (subtracts arr2 from arr1)
array_diff() {
    (( ARGC == 3 )) || return 1
    # :| is the array difference operator in Zsh
    set -A $3 "${(@)${(P)1}:|${(P)2}}"
}

# Print array elements (for debugging)
# Usage: array_print arr_name
array_print() {
    (( ARGC == 1 )) || return 1
    # print -l prints elements on separate lines
    print -l -- "${(@P)1}"
}

# shell files tracking - keep at the end
zfile_track_end ${0:A}