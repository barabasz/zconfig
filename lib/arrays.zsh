#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# Array manipulation utilities
# Arrays are passed by name. Results go to a named result array, or (for
# scalar results) are printed and also stored in REPLY. Indexes are 1-based.
##

# Check that a name is a valid parameter name (internal)
# Usage: _array_name_ok <name>
# Returns: 0 valid, 1 invalid
_array_name_ok() {
    [[ $1 =~ '^[[:alpha:]_][[:alnum:]_]*$' ]]
}

## Inspection

# Check if array contains element (exact match)
# Usage: array_contains <arr_name> <element>
# Returns: 0 true, 1 false, 2 invalid usage
array_contains() {
    (( ARGC == 2 )) || return 2
    # (Ie): reverse search returning index, exact match; 0 means not found
    (( ${${(P)1}[(Ie)$2]} ))
}

# Count occurrences of element in array (exact match)
# Usage: array_count <arr_name> <element>
# Output: count (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
array_count() {
    (( ARGC == 2 )) || return 2
    local -a _src=("${(@P)1}")
    # (M) keeps only matching elements; ${(b)2} quotes pattern characters
    local -a _hits=("${(@M)_src:#${(b)2}}")
    REPLY=${#_hits}
    print -r -- "$REPLY"
}

# Get array length (for a scalar: string length)
# Usage: array_length <arr_name>
# Output: number of elements (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
array_length() {
    (( ARGC == 1 )) || return 2
    REPLY=${#${(P)1}}
    print -r -- "$REPLY"
}

# Check if array is empty
# Usage: array_is_empty <arr_name>
# Returns: 0 true (empty), 1 false, 2 invalid usage
array_is_empty() {
    (( ARGC == 1 )) || return 2
    (( ${#${(P)1}} == 0 ))
}

# Check if array/variable is initialized (set)
# Usage: is_array_initialized <arr_name>
# Returns: 0 true, 1 false, 2 invalid usage
is_array_initialized() {
    (( ARGC == 1 )) || return 2
    (( ${+parameters[$1]} ))
}

# Get first element of an array
# Usage: array_first <arr_name>
# Output: first element (stdout); also sets REPLY
# Returns: 0 success, 1 empty array, 2 invalid usage
array_first() {
    (( ARGC == 1 )) || return 2
    (( ${#${(P)1}} )) || { REPLY=""; return 1 }
    REPLY="${${(P)1}[1]}"
    print -r -- "$REPLY"
}

# Get last element of an array
# Usage: array_last <arr_name>
# Output: last element (stdout); also sets REPLY
# Returns: 0 success, 1 empty array, 2 invalid usage
array_last() {
    (( ARGC == 1 )) || return 2
    (( ${#${(P)1}} )) || { REPLY=""; return 1 }
    REPLY="${${(P)1}[-1]}"
    print -r -- "$REPLY"
}

# Get index of first occurrence of element in array (exact match)
# Usage: array_index_of <arr_name> <element>
# Output: index (1-based) or -1 if not found (stdout); also sets REPLY
# Returns: 0 found, 1 not found, 2 invalid usage
array_index_of() {
    (( ARGC == 2 )) || return 2
    local -a _src=("${(@P)1}")
    # (ie): index of exact match, or length+1 if not found
    local -i _idx=${_src[(ie)$2]}
    if (( _idx <= ${#_src} )); then
        REPLY=$_idx
        print -r -- "$REPLY"
        return 0
    fi
    REPLY=-1
    print -r -- "$REPLY"
    return 1
}

# Get minimum numeric value of array
# Usage: array_min <arr_name>
# Output: minimum (stdout); also sets REPLY
# Returns: 0 success, 1 empty array, 2 invalid usage
array_min() {
    (( ARGC == 1 )) || return 2
    local -a _src=("${(@P)1}")
    (( ${#_src} )) || return 1
    local _v _m=${_src[1]}
    for _v in $_src; do (( _v < _m )) && _m=$_v; done
    REPLY=$_m
    print -r -- "$REPLY"
}

# Get maximum numeric value of array
# Usage: array_max <arr_name>
# Output: maximum (stdout); also sets REPLY
# Returns: 0 success, 1 empty array, 2 invalid usage
array_max() {
    (( ARGC == 1 )) || return 2
    local -a _src=("${(@P)1}")
    (( ${#_src} )) || return 1
    local _v _m=${_src[1]}
    for _v in $_src; do (( _v > _m )) && _m=$_v; done
    REPLY=$_m
    print -r -- "$REPLY"
}

## Modification (in place)

# Append element(s) to array
# Usage: array_push <arr_name> <element> [element...]
# Returns: 0 success, 2 invalid usage
array_push() {
    (( ARGC >= 2 )) && _array_name_ok "$1" || return 2
    local _name=$1
    shift
    set -A $_name "${(@P)_name}" "$@"
}

# Add element(s) to beginning of array
# Usage: array_unshift <arr_name> <element> [element...]
# Returns: 0 success, 2 invalid usage
array_unshift() {
    (( ARGC >= 2 )) && _array_name_ok "$1" || return 2
    local _name=$1
    shift
    set -A $_name "$@" "${(@P)_name}"
}

# Remove and return last element from array
# Usage: array_pop <arr_name>
# Sets: REPLY to the removed element (no subshell, so the array is really modified)
# Returns: 0 success, 1 empty array, 2 invalid usage
array_pop() {
    (( ARGC == 1 )) && _array_name_ok "$1" || return 2
    local _name=$1
    local -a _src=("${(@P)_name}")
    (( ${#_src} > 0 )) || return 1
    REPLY="${_src[-1]}"
    set -A $_name "${(@)_src[1,-2]}"
}

# Remove and return first element from array
# Usage: array_shift <arr_name>
# Sets: REPLY to the removed element (no subshell, so the array is really modified)
# Returns: 0 success, 1 empty array, 2 invalid usage
array_shift() {
    (( ARGC == 1 )) && _array_name_ok "$1" || return 2
    local _name=$1
    local -a _src=("${(@P)_name}")
    (( ${#_src} > 0 )) || return 1
    REPLY="${_src[1]}"
    set -A $_name "${(@)_src[2,-1]}"
}

# Insert element(s) at index (1-based; index length+1 appends)
# Usage: array_insert_at <arr_name> <index> <element> [element...]
# Returns: 0 success, 1 index out of range, 2 invalid usage
array_insert_at() {
    (( ARGC >= 3 )) && _array_name_ok "$1" && [[ $2 == <1-> ]] || return 2
    local _name=$1
    local -i _idx=$2
    shift 2
    local -a _src=("${(@P)_name}")
    (( _idx <= ${#_src} + 1 )) || return 1
    set -A $_name "${(@)_src[1,_idx-1]}" "$@" "${(@)_src[_idx,-1]}"
}

# Remove all occurrences of element from array (exact match)
# Usage: array_remove <arr_name> <element>
# Returns: 0 success, 2 invalid usage
array_remove() {
    (( ARGC == 2 )) && _array_name_ok "$1" || return 2
    # :# removes matching elements; ${(b)2} makes the element a literal pattern
    set -A $1 "${(@)${(@P)1}:#${(b)2}}"
}

# Remove element from array by index (1-based, negative counts from end)
# Usage: array_remove_at <arr_name> <index>
# Returns: 0 success, 1 index out of range, 2 invalid usage
array_remove_at() {
    (( ARGC == 2 )) && _array_name_ok "$1" && [[ $2 == (|-)<1-> ]] || return 2
    local _name=$1
    local -a _src=("${(@P)_name}")
    local -i _idx=$2
    (( _idx < 0 )) && (( _idx = ${#_src} + _idx + 1 ))
    (( _idx >= 1 && _idx <= ${#_src} )) || return 1
    _src[_idx]=()
    set -A $_name "${(@)_src}"
}

## Transformation (into a result array)

# Get unique elements from array (first occurrence order is kept)
# Usage: array_unique <arr_name> <result_arr_name>
# Returns: 0 success, 2 invalid usage
array_unique() {
    (( ARGC == 2 )) && _array_name_ok "$2" || return 2
    local -a _src=("${(@P)1}")
    set -A $2 "${(@u)_src}"
}

# Reverse array
# Usage: array_reverse <arr_name> <result_arr_name>
# Returns: 0 success, 2 invalid usage
array_reverse() {
    (( ARGC == 2 )) && _array_name_ok "$2" || return 2
    local -a _src=("${(@P)1}")
    set -A $2 "${(@Oa)_src}"
}

# Sort array (lexicographic, or numeric with -n)
# Usage: array_sort [-n] <arr_name> <result_arr_name>
# Note: -n sorts integers correctly, including negative numbers
# Returns: 0 success, 2 invalid usage
array_sort() {
    local _numeric=0
    [[ $1 == -n ]] && { _numeric=1; shift }
    (( ARGC == 2 )) && _array_name_ok "$2" || return 2
    local -a _src=("${(@P)1}")
    if (( _numeric )); then
        set -A $2 "${(@o-)_src}"
    else
        set -A $2 "${(@o)_src}"
    fi
}

# Sort array in reverse order (lexicographic, or numeric with -n)
# Usage: array_sort_reverse [-n] <arr_name> <result_arr_name>
# Returns: 0 success, 2 invalid usage
array_sort_reverse() {
    local _numeric=0
    [[ $1 == -n ]] && { _numeric=1; shift }
    (( ARGC == 2 )) && _array_name_ok "$2" || return 2
    local -a _src=("${(@P)1}")
    if (( _numeric )); then
        set -A $2 "${(@O-)_src}"
    else
        set -A $2 "${(@O)_src}"
    fi
}

# Slice array (1-based start)
# Usage: array_slice <arr_name> <start> [length] <result_arr_name>
# If length is omitted, slices from start to end
# Returns: 0 success, 2 invalid usage
array_slice() {
    (( ARGC >= 3 && ARGC <= 4 )) || return 2
    local _source=$1
    local -i _start=$2
    local _target=${argv[-1]}
    _array_name_ok "$_target" || return 2

    if (( ARGC == 3 )); then
        set -A $_target "${(@)${(@P)_source}[_start,-1]}"
    else
        [[ $3 == <-> ]] || return 2
        local -i _len=$3
        set -A $_target "${(@)${(@P)_source}[_start,_start+_len-1]}"
    fi
}

# Filter array by glob pattern
# Usage: array_filter <arr_name> <pattern> <result_arr_name>
# Example: array_filter files "*.zsh" zsh_files
# Returns: 0 success, 2 invalid usage
array_filter() {
    (( ARGC == 3 )) && _array_name_ok "$3" || return 2
    local -a _src=("${(@P)1}")
    local _pattern="$2"
    set -A $3 "${(@M)_src:#${~_pattern}}"
}

# Map array through function
# Usage: array_map <arr_name> <function_name> <result_arr_name>
# Note: the mapped function must set REPLY instead of printing
# Returns: 0 success, 2 invalid usage, 127 function not found
array_map() {
    (( ARGC == 3 )) && _array_name_ok "$3" || return 2
    local _func=$2
    (( ${+functions[$_func]} || ${+commands[$_func]} )) || return 127
    local -a _result=()
    local _item
    for _item in "${(@P)1}"; do
        $_func "$_item" >/dev/null
        _result+=("$REPLY")
    done
    set -A $3 "${_result[@]}"
}

# Flatten array (split elements on whitespace)
# Usage: array_flatten <arr_name> <result_arr_name>
# Returns: 0 success, 2 invalid usage
array_flatten() {
    (( ARGC == 2 )) && _array_name_ok "$2" || return 2
    # ${=var} performs word splitting on expansion
    set -A $2 ${=${(@P)1}}
}

# Concatenate multiple arrays
# Usage: array_concat <arr1> <arr2> [arr3...] <result_arr_name>
# Returns: 0 success, 2 invalid usage
array_concat() {
    (( ARGC >= 3 )) || return 2
    local _target="${argv[-1]}"
    _array_name_ok "$_target" || return 2
    local -a _result=()
    local _arr
    for _arr in ${argv[1,-2]}; do
        _result+=("${(@P)_arr}")
    done
    set -A $_target "${_result[@]}"
}

# Zip two arrays into one with alternating elements (a1 b1 a2 b2 ...)
# Handy for building associative arrays: typeset -A map=("${zipped[@]}")
# Usage: array_zip <arr1_name> <arr2_name> <result_arr_name>
# Note: the result is as long as the shorter array allows (pairs only)
# Returns: 0 success, 2 invalid usage
array_zip() {
    (( ARGC == 3 )) && _array_name_ok "$3" || return 2
    local -a _a=("${(@P)1}") _b=("${(@P)2}") _result=()
    local -i _i _n=$(( ${#_a} < ${#_b} ? ${#_a} : ${#_b} ))
    for (( _i = 1; _i <= _n; _i++ )); do
        _result+=("$_a[_i]" "$_b[_i]")
    done
    set -A $3 "${_result[@]}"
}

# Get array intersection (common elements, order of arr1)
# Usage: array_intersect <arr1_name> <arr2_name> <result_arr_name>
# Returns: 0 success, 2 invalid usage
array_intersect() {
    (( ARGC == 3 )) && _array_name_ok "$3" || return 2
    local -a _src1=("${(@P)1}") _src2=("${(@P)2}") _result=()
    local _item
    for _item in "${_src1[@]}"; do
        (( ${_src2[(Ie)$_item]} )) && _result+=("$_item")
    done
    set -A $3 "${_result[@]}"
}

# Get array difference (elements in arr1 but not in arr2)
# Usage: array_diff <arr1_name> <arr2_name> <result_arr_name>
# Returns: 0 success, 2 invalid usage
array_diff() {
    (( ARGC == 3 )) && _array_name_ok "$3" || return 2
    local -a _src1=("${(@P)1}") _src2=("${(@P)2}") _result=()
    local _item
    for _item in "${_src1[@]}"; do
        (( ${_src2[(Ie)$_item]} )) || _result+=("$_item")
    done
    set -A $3 "${_result[@]}"
}

## Predicates over elements

# Check if all elements match predicate function
# Usage: array_every <arr_name> <function_name>
# Returns: 0 true (all match), 1 false, 2 invalid usage
array_every() {
    (( ARGC == 2 )) || return 2
    local _item
    for _item in "${(@P)1}"; do
        $2 "$_item" || return 1
    done
    return 0
}

# Check if any element matches predicate function
# Usage: array_some <arr_name> <function_name>
# Returns: 0 true (any match), 1 false, 2 invalid usage
array_some() {
    (( ARGC == 2 )) || return 2
    local _item
    for _item in "${(@P)1}"; do
        $2 "$_item" && return 0
    done
    return 1
}

## Output

# Join array with separator
# Usage: array_join <arr_name> <separator>
# Note: same as str_join with arguments swapped
# Output: joined string (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
array_join() {
    (( ARGC == 2 )) || return 2
    local _sep="$2"
    REPLY="${(pj:$_sep:)${(@P)1}}"
    print -r -- "$REPLY"
}

# Print array elements, one per line (for debugging)
# Usage: array_print <arr_name>
# Returns: 0 success, 2 invalid usage
array_print() {
    (( ARGC == 1 )) || return 2
    print -rl -- "${(@P)1}"
}

# Shell files tracking - keep at the end
zfile_track_end ${0:A}
