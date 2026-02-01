#!/bin/zsh
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# Function metadata and argument parsing library
# Provides standardized help generation, option parsing, argument validation, and type checking.
#
# Dependencies: printe (from out.zsh), color variables ($r, $g, $y, $c, $m, $x)
#
# Usage in your function:
#
#   local -A _fn=(
#       [name]=${0:t}
#       [version]="1.0.0"
#       [author]="Author Name"
#       [desc]="Short description"
#       [long]="Optional longer description shown in help"
#   )
#
#   local -a _fn_args=(
#       "input|Input file path"             # name|description (required, string)
#       "output|Output file|o"              # name|description|o (optional, string)
#       "count|Number of items|r|integer"   # name|description|r|type (required, typed)
#       "ratio|Ratio value|o|float"         # name|description|o|type (optional, typed)
#   )
#
#   local -a _fn_opts=(
#       "help|h|Show this help"             # long|short|description (flag)
#       "version|v|Show version"            # long|short|description (flag)
#       "cycles|c|Number of cycles|n"       # long|short|description|arg_name (takes value)
#       "count|n|Count|n|integer"           # long|short|description|arg_name|type (typed value)
#       "test||Test mode"                   # long||description (no short form)
#   )
#
#   local -a _fn_examples=(
#       "myfunc input.txt"
#       "myfunc -c 8 input.txt"
#   )
#
#   local -A opts=() args=()
#   _fn_init "$@" || return $REPLY
#
#   # Now available:
#   # ${opts[cycles]}  - option value (by long name)
#   # ${args[input]}   - argument value (by name)
#   # (( ${+opts[force]} )) - check if flag is set
#
# Supported types: string, char, digit, integer, float, date, time, datetime, bool, ipv4, ipv6
# Add custom types by extending _FN_TYPES and _FN_TYPE_DESC associative arrays.

# Type validation patterns (extensible - add custom types here)
# Each key is a type name, value is an extended regex pattern
typeset -gA _FN_TYPES=(
    [string]='^.*$'
    [char]='^.$'
    [digit]='^[0-9]$'
    [integer]='^-?[0-9]+$'
    [float]='^-?[0-9]+(\.[0-9]+)?$'
    [date]='^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$'
    [time]='^([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$'
    [datetime]='^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])T([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$'
    [bool]='^(true|false|yes|no|1|0)$'
    [ipv4]='^((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$'
    [ipv6]='^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$|^::$|^([0-9a-fA-F]{1,4}:){1,7}:$|^:(:([0-9a-fA-F]{1,4})){1,7}$|^([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}$|^([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}$|^([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}$|^([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}$|^([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}$|^[0-9a-fA-F]{1,4}:(:[0-9a-fA-F]{1,4}){1,6}$'
)

# Human-readable type descriptions for error messages
typeset -gA _FN_TYPE_DESC=(
    [string]="any text"
    [char]="single character"
    [digit]="single digit (0-9)"
    [integer]="integer number"
    [float]="decimal number"
    [date]="date (YYYY-MM-DD)"
    [time]="time (HH:MM:SS)"
    [datetime]="datetime (YYYY-MM-DDTHH:MM:SS)"
    [ipv4]="IPv4 address (e.g., 192.168.1.1)"
    [ipv6]="IPv6 address (e.g., 2001:db8::1)"
    [bool]="boolean (true/false, yes/no, 1/0)"
)

# _fn_validate_type - Validate value against type
# Usage: _fn_validate_type "value" "type"
# Returns: 0 if valid, 1 if invalid
_fn_validate_type() {
    local value="$1" type="${2:-string}"
    local pattern="${_FN_TYPES[$type]}"

    # Unknown type - treat as string (always valid)
    [[ -z "$pattern" ]] && return 0

    # Empty value is invalid for typed fields (except string)
    [[ -z "$value" && "$type" != "string" ]] && return 1

    # Match against pattern
    [[ "$value" =~ $pattern ]] && return 0
    return 1
}

# _fn_type_error - Print type validation error
# Usage: _fn_type_error "name" "value" "type" ["option"]
_fn_type_error() {
    local name="$1" value="$2" type="$3" is_option="$4"
    local desc="${_FN_TYPE_DESC[$type]:-$type}"

    if [[ -n "$is_option" ]]; then
        printe "Invalid value for --${name}: '${value}' is not ${desc}." >&2
    else
        printe "Invalid value for <${name}>: '${value}' is not ${desc}." >&2
    fi
}

# _fn_has_args - Check if _fn_args is defined and non-empty
# Returns: 0 if has arguments, 1 otherwise
_fn_has_args() {
    (( ${+_fn_args} && ${#_fn_args} > 0 ))
}

# _fn_has_opts - Check if _fn_opts is defined and non-empty
# Returns: 0 if has options, 1 otherwise
_fn_has_opts() {
    (( ${+_fn_opts} && ${#_fn_opts} > 0 ))
}

# _fn_is_arg_optional - Check if argument spec is optional
# Usage: _fn_is_arg_optional "spec"
# Returns: 0 if optional, 1 if required
_fn_is_arg_optional() {
    local -a fld=( "${(@s:|:)1}" )
    [[ "${fld[3]:-r}" == "o" ]]
}

# _fn_def_error - Print definition error message
# Usage: _fn_def_error "array_name" "index" "message" ["spec"]
_fn_def_error() {
    local array="$1" idx="$2" msg="$3" spec="$4"
    printe "Definition error in ${array}[${idx}]: ${msg}" >&2
    [[ -n "$spec" ]] && print "  → \"${spec}\"" >&2
}

# _fn_validate_type_name - Check if type name is valid
# Usage: _fn_validate_type_name "type"
# Returns: 0 if valid, 1 if invalid
_fn_validate_type_name() {
    [[ -z "$1" ]] && return 0  # empty = default (string)
    (( ${+_FN_TYPES[$1]} ))
}

# _fn_validate_args - Validate _fn_args definitions
# Returns: 0 if valid, 1 if errors found
_fn_validate_args() {
    _fn_has_args || return 0

    local idx=1 spec
    local -a fld=()
    local name ro_marker type_name
    local -A seen_names=()

    for spec in "${_fn_args[@]}"; do
        [[ -z "$spec" ]] && { ((idx++)); continue }

        fld=( "${(@s:|:)spec}" )
        local field_count=${#fld}

        # Check: too many fields (max 4: name|desc|r/o|type)
        if (( field_count > 4 )); then
            _fn_def_error "_fn_args" $idx "too many fields (max 4)" "$spec"
            return 1
        fi

        name="${fld[1]}"
        ro_marker="${fld[3]:-}"
        type_name="${fld[4]:-}"

        # Check: name is required and non-empty
        if [[ -z "$name" ]]; then
            _fn_def_error "_fn_args" $idx "argument name is required" "$spec"
            return 1
        fi

        # Check: name should be valid identifier (alphanumeric, underscore, hyphen)
        if [[ ! "$name" =~ ^[a-zA-Z_][a-zA-Z0-9_-]*$ ]]; then
            _fn_def_error "_fn_args" $idx "invalid argument name '${name}'" "$spec"
            return 1
        fi

        # Check: duplicate names
        if (( ${+seen_names[$name]} )); then
            _fn_def_error "_fn_args" $idx "duplicate argument name '${name}'" "$spec"
            return 1
        fi
        seen_names[$name]=1

        # Check: r/o marker must be empty, 'r', or 'o'
        if [[ -n "$ro_marker" && "$ro_marker" != "r" && "$ro_marker" != "o" ]]; then
            _fn_def_error "_fn_args" $idx "invalid required/optional marker '${ro_marker}' (use 'r' or 'o')" "$spec"
            return 1
        fi

        # Check: type must be valid if specified
        if [[ -n "$type_name" ]] && ! _fn_validate_type_name "$type_name"; then
            _fn_def_error "_fn_args" $idx "unknown type '${type_name}'" "$spec"
            return 1
        fi

        ((idx++))
    done

    return 0
}

# _fn_validate_opts - Validate _fn_opts definitions
# Returns: 0 if valid, 1 if errors found
_fn_validate_opts() {
    _fn_has_opts || return 0

    local idx=1 spec
    local -a fld=()
    local long_name short_name arg_name type_name
    local -A seen_long=() seen_short=()

    for spec in "${_fn_opts[@]}"; do
        [[ -z "$spec" ]] && { ((idx++)); continue }

        fld=( "${(@s:|:)spec}" )
        local field_count=${#fld}

        # Check: too many fields (max 5: long|short|desc|arg|type)
        if (( field_count > 5 )); then
            _fn_def_error "_fn_opts" $idx "too many fields (max 5)" "$spec"
            return 1
        fi

        long_name="${fld[1]}"
        short_name="${fld[2]:-}"
        arg_name="${fld[4]:-}"
        type_name="${fld[5]:-}"

        # Check: long name is required and non-empty
        if [[ -z "$long_name" ]]; then
            _fn_def_error "_fn_opts" $idx "long option name is required" "$spec"
            return 1
        fi

        # Check: long name should be valid (alphanumeric, hyphen, no leading hyphen)
        if [[ ! "$long_name" =~ ^[a-zA-Z][a-zA-Z0-9-]*$ ]]; then
            _fn_def_error "_fn_opts" $idx "invalid long option name '${long_name}'" "$spec"
            return 1
        fi

        # Check: duplicate long names
        if (( ${+seen_long[$long_name]} )); then
            _fn_def_error "_fn_opts" $idx "duplicate long option name '${long_name}'" "$spec"
            return 1
        fi
        seen_long[$long_name]=1

        # Check: short name must be single alphanumeric character if specified
        if [[ -n "$short_name" ]]; then
            if [[ ! "$short_name" =~ ^[a-zA-Z0-9]$ ]]; then
                _fn_def_error "_fn_opts" $idx "short option must be single character, got '${short_name}'" "$spec"
                return 1
            fi

            # Check: duplicate short names
            if (( ${+seen_short[$short_name]} )); then
                _fn_def_error "_fn_opts" $idx "duplicate short option '${short_name}'" "$spec"
                return 1
            fi
            seen_short[$short_name]=1
        fi

        # Check: type without arg_name is invalid (flags don't have types)
        if [[ -n "$type_name" && -z "$arg_name" ]]; then
            _fn_def_error "_fn_opts" $idx "type '${type_name}' specified but no argument name (flags don't have types)" "$spec"
            return 1
        fi

        # Check: type must be valid if specified
        if [[ -n "$type_name" ]] && ! _fn_validate_type_name "$type_name"; then
            _fn_def_error "_fn_opts" $idx "unknown type '${type_name}'" "$spec"
            return 1
        fi

        ((idx++))
    done

    return 0
}

# _fn_get_file - Get function source file path
# Returns path via stdout
_fn_get_file() {
    local name=${_fn[name]:-${0:t}}
    local file=""

    # Try whence first
    file=$(whence -v "$name" 2>/dev/null | grep -o '/.*')
    [[ -n "$file" ]] && { print "$file"; return 0 }

    # Try fpath
    for dir in $fpath; do
        [[ -f "$dir/$name" ]] && { print "$dir/$name"; return 0 }
    done

    return 1
}

# _fn_count_required_args - Count required arguments
# Returns count via stdout
_fn_count_required_args() {
    local count=0 arg_spec
    _fn_has_args || { print 0; return }
    for arg_spec in "${_fn_args[@]}"; do
        [[ -z "$arg_spec" ]] && continue
        _fn_is_arg_optional "$arg_spec" || (( count++ ))
    done
    print $count
}

# _fn_args_range_str - Generate human-readable argument range description
# Usage: _fn_args_range_str <min> <max>
# Returns description via stdout
_fn_args_range_str() {
    local min=$1 max=$2

    if (( max == 0 )); then
        print "no arguments"
    elif (( min == max )); then
        if (( min == 1 )); then
            print "exactly 1 argument"
        else
            print "exactly $min arguments"
        fi
    else
        print "$min to $max arguments"
    fi
}

# _fn_has_help - Check if help option is defined
# Returns: 0 if help option exists, 1 otherwise
_fn_has_help() {
    _fn_has_opts || return 1
    local opt_spec
    for opt_spec in "${_fn_opts[@]}"; do
        # Check first field (long name) for "help"
        [[ "${opt_spec%%|*}" == "help" ]] && return 0
    done
    return 1
}

# _fn_usage_line - Build usage line string
# Returns usage line via stdout
_fn_usage_line() {
    local name=${_fn[name]:-${0:t}}
    local usage="Usage: ${g}${name}${x}"

    _fn_has_opts && usage+=" [options]"

    if _fn_has_args; then
        local arg_spec
        for arg_spec in "${_fn_args[@]}"; do
            [[ -z "$arg_spec" ]] && continue
            local arg_name="${arg_spec%%|*}"
            if _fn_is_arg_optional "$arg_spec"; then
                usage+=" [${arg_name}]"
            else
                usage+=" <${arg_name}>"
            fi
        done
    fi

    print "$usage"
}

# _fn_usage_short - Print short usage (for errors)
_fn_usage_short() {
    local name=${_fn[name]:-${0:t}}

    # Show usage line if we have any args or opts defined
    if _fn_has_opts || _fn_has_args; then
        _fn_usage_line
    fi

    if _fn_has_help; then
        print "For more information use \`${g}${name} --help${x}\`"
    else
        local file=$(_fn_get_file)
        print "For more information check source code:"
        print "${c}${file:-unknown}${x}"
    fi
}

# _fn_usage - Generate and print full usage/help message
# Reads: _fn, _fn_args, _fn_opts, _fn_examples
_fn_usage() {
    local name=${_fn[name]:-${0:t}}
    local desc=${_fn[desc]:-"No description"}
    local version=${_fn[version]:-""}
    local author=${_fn[author]:-""}

    _fn_usage_line
    print
    print "$desc"

    # Long description
    [[ -n "${_fn[long]}" ]] && print "\n${_fn[long]}"

    # Arguments section
    if _fn_has_args; then
        print "\n${y}Arguments:${x}"
        local _arg_spec _arg_name _arg_desc _arg_type _arg_tsuf
        local -a _arg_fld=()
        for _arg_spec in "${_fn_args[@]}"; do
            [[ -z "$_arg_spec" ]] && continue
            _arg_fld=( "${(@s:|:)_arg_spec}" )
            _arg_name="${_arg_fld[1]}"
            _arg_desc="${_arg_fld[2]:-}"
            _arg_type="${_arg_fld[4]:-}"

            # Build type suffix (show only for non-string types)
            _arg_tsuf=""
            [[ -n "$_arg_type" && "$_arg_type" != "string" ]] && _arg_tsuf=" ${m}(${_arg_type})${x}"

            if _fn_is_arg_optional "$_arg_spec"; then
                printf "  ${c}%-20s${x}  %s%s\n" "[${_arg_name}]" "$_arg_desc" "$_arg_tsuf"
            else
                printf "  ${c}%-20s${x}  %s ${r}(required)${x}%s\n" "<${_arg_name}>" "$_arg_desc" "$_arg_tsuf"
            fi
        done
    fi

    # Options section
    if _fn_has_opts; then
        print "\n${y}Options:${x}"
        local _opt_spec _opt_long _opt_short _opt_desc _opt_arg _opt_type _opt_disp _opt_tsuf
        local -a _opt_fld=()
        for _opt_spec in "${_fn_opts[@]}"; do
            [[ -z "$_opt_spec" ]] && continue
            _opt_fld=( "${(@s:|:)_opt_spec}" )
            _opt_long="${_opt_fld[1]}"
            _opt_short="${_opt_fld[2]:-}"
            _opt_desc="${_opt_fld[3]:-}"
            _opt_arg="${_opt_fld[4]:-}"
            _opt_type="${_opt_fld[5]:-}"

            # Build display string: -s, --long <arg>
            if [[ -n "$_opt_short" ]]; then
                _opt_disp="-${_opt_short}, --${_opt_long}"
            else
                _opt_disp="    --${_opt_long}"
            fi
            [[ -n "$_opt_arg" ]] && _opt_disp+=" <${_opt_arg}>"

            # Build type suffix (show only for non-string types)
            _opt_tsuf=""
            [[ -n "$_opt_type" && "$_opt_type" != "string" ]] && _opt_tsuf=" ${m}(${_opt_type})${x}"

            printf "  ${c}%-24s${x}  %s%s\n" "$_opt_disp" "$_opt_desc" "$_opt_tsuf"
        done
    fi

    # Examples section
    if (( ${+_fn_examples} && ${#_fn_examples} > 0 )); then
        print "\n${y}Examples:${x}"
        local example
        for example in "${_fn_examples[@]}"; do
            print "  ${c}${example}${x}"
        done
    fi

    # Footer: version, author, file location
    print
    local footer=""
    [[ -n "$version" ]] && footer+="${name} ver. ${version}"
    [[ -n "$author" ]] && footer+=" by ${author}"
    [[ -n "$footer" ]] && print "$footer"

    local file=$(_fn_get_file)
    [[ -n "$file" ]] && print "This function is defined in ${c}${file}${x}"
}

# _fn_version - Print version string
_fn_version() {
    print "${_fn[name]:-${0:t}} ${_fn[version]:-unknown}"
}

# _fn_init - Parse options, handle -h/-v, validate args
# Usage:
#   local -A opts=()
#   local -A args=()
#   _fn_init "$@" || return $REPLY
#
# Return codes (via $REPLY when _fn_init returns non-zero):
#   0 - clean exit (help/version was shown)
#   2 - user input error (invalid option, missing argument, wrong type)
#   3 - definition error (invalid _fn_args or _fn_opts specification)
#
# Modifies caller's: opts (assoc array), args (assoc array)
_fn_init() {
    # Clear caller's variables
    opts=()
    args=()

    # Validate definitions before processing
    _fn_validate_args || { REPLY=3; return 3; }
    _fn_validate_opts || { REPLY=3; return 3; }

    local -A parsed_opts=()
    local -a remaining_args=()

    # Build option info from _fn_opts
    # Format: long|short|description|arg_name|type
    local -a zparse_spec=()
    local -A long_names=()      # short -> long mapping
    local -A needs_value=()     # short -> 1 if requires value
    local -A is_known_short=()  # short -> 1
    local -A is_known_long=()   # long -> 1
    local -A opt_types=()       # long_name -> type
    local -a opt_fields=()
    local opt_spec short_part long_part arg_part type_part

    for opt_spec in "${_fn_opts[@]}"; do
        [[ -z "$opt_spec" ]] && continue
        opt_fields=( "${(@s:|:)opt_spec}" )
        long_part="${opt_fields[1]}"
        short_part="${opt_fields[2]:-}"
        arg_part="${opt_fields[4]:-}"
        type_part="${opt_fields[5]:-string}"

        # Track known options
        is_known_long[$long_part]=1
        [[ -n "$short_part" ]] && {
            is_known_short[$short_part]=1
            long_names[$short_part]="$long_part"
        }
        [[ -n "$arg_part" && -n "$short_part" ]] && needs_value[$short_part]=1
        [[ -n "$arg_part" ]] && opt_types[$long_part]="$type_part"

        # Build zparseopts spec
        if [[ -n "$arg_part" ]]; then
            [[ -n "$short_part" ]] && zparse_spec+=( "${short_part}:" )
            zparse_spec+=( "-${long_part}:" )
        else
            [[ -n "$short_part" ]] && zparse_spec+=( "${short_part}" )
            zparse_spec+=( "-${long_part}" )
        fi
    done

    # Preprocess arguments: expand grouped flags, handle -opt=value
    local -a processed_args=()
    local arg char rest skip_next=0

    for arg in "$@"; do
        if (( skip_next )); then
            processed_args+=( "$arg" )
            skip_next=0
            continue
        fi

        # Long option
        if [[ "$arg" == --* ]]; then
            if ! _fn_has_opts; then
                printe "This function does not accept any options." >&2
                _fn_usage_short >&2
                REPLY=2; return 2
            fi

            if [[ "$arg" == *=* ]]; then
                # --opt=value -> --opt value
                processed_args+=( "${arg%%=*}" "${arg#*=}" )
            else
                processed_args+=( "$arg" )
            fi
            continue
        fi

        # Short option(s)
        if [[ "$arg" == -? || "$arg" == -??* ]] && [[ "$arg" != -[0-9]* ]]; then
            if ! _fn_has_opts; then
                printe "This function does not accept any options." >&2
                _fn_usage_short >&2
                REPLY=2; return 2
            fi

            rest="${arg#-}"

            while [[ -n "$rest" ]]; do
                char="${rest:0:1}"
                rest="${rest:1}"

                # Check if known option
                if (( ! ${+is_known_short[$char]} )); then
                    printe "Unknown option: -${char}" >&2
                    _fn_usage_short >&2
                    REPLY=2; return 2
                fi

                # Option needs value?
                if (( ${+needs_value[$char]} )); then
                    processed_args+=( "-${char}" )
                    if [[ -n "$rest" ]]; then
                        # -c=value or -cvalue format
                        if [[ "$rest" == "="* ]]; then
                            processed_args+=( "${rest:1}" )
                        else
                            processed_args+=( "$rest" )
                        fi
                        rest=""
                    fi
                    # Value will be next argument (handled by zparseopts)
                else
                    # Flag - add and continue with rest
                    processed_args+=( "-${char}" )
                fi
            done
            continue
        fi

        # Not an option
        processed_args+=( "$arg" )
    done

    # Parse preprocessed options with zparseopts
    local -A raw_opts=()
    local zparse_err_file="${TMPDIR:-/tmp}/fn_init_err.$$"
    set -- "${processed_args[@]}"
    zparseopts -D -E -A raw_opts -- "${zparse_spec[@]}" 2>"$zparse_err_file"
    local zparse_status=$?
    local zparse_err=""
    [[ -f "$zparse_err_file" ]] && { zparse_err=$(<"$zparse_err_file"); rm -f "$zparse_err_file" }

    if (( zparse_status != 0 )); then
        if [[ "$zparse_err" =~ "missing argument for option: (-[a-zA-Z0-9-]+)" ]]; then
            printe "Option ${match[1]} requires a value." >&2
        else
            printe "Invalid option." >&2
        fi
        _fn_usage_short >&2
        REPLY=2; return 2
    fi

    remaining_args=( "$@" )

    # Remove -- separator and check for any remaining unknown options
    local -a clean_args=()
    local found_separator=0
    for arg in "${remaining_args[@]}"; do
        if [[ "$arg" == "--" ]]; then
            found_separator=1
            continue
        fi
        if (( found_separator )); then
            clean_args+=( "$arg" )
        elif [[ "$arg" == --* ]]; then
            # Unknown long option (short ones caught in preprocessor)
            printe "Unknown option: ${arg}" >&2
            _fn_usage_short >&2
            REPLY=2; return 2
        else
            clean_args+=( "$arg" )
        fi
    done
    remaining_args=( "${clean_args[@]}" )

    # Normalize to long names (long is always the key in $opts)
    # Format: long|short|description|arg_name|type
    for opt_spec in "${_fn_opts[@]}"; do
        [[ -z "$opt_spec" ]] && continue
        opt_fields=( "${(@s:|:)opt_spec}" )
        long_part="${opt_fields[1]}"
        short_part="${opt_fields[2]:-}"

        # Check long form (--option)
        if (( ${+raw_opts[--${long_part}]} )); then
            parsed_opts[$long_part]="${raw_opts[--${long_part}]}"
        fi
        # Check short form (-o) if exists
        if [[ -n "$short_part" ]] && (( ${+raw_opts[-${short_part}]} )); then
            parsed_opts[$long_part]="${raw_opts[-${short_part}]}"
        fi
    done

    # Validate option types
    local opt_value opt_type
    for long_part in ${(k)parsed_opts}; do
        # Skip flags (no type validation needed)
        (( ! ${+opt_types[$long_part]} )) && continue
        opt_value="${parsed_opts[$long_part]}"
        opt_type="${opt_types[$long_part]}"
        if ! _fn_validate_type "$opt_value" "$opt_type"; then
            _fn_type_error "$long_part" "$opt_value" "$opt_type" "option"
            _fn_usage_short >&2
            REPLY=2; return 2
        fi
    done

    # Handle -h/--help
    if (( ${+parsed_opts[help]} )); then
        _fn_usage >&2
        REPLY=0; return 1
    fi

    # Handle -v/--version
    if (( ${+parsed_opts[version]} )); then
        _fn_version >&2
        REPLY=0; return 1
    fi

    # Calculate argument counts
    local min_args=$(_fn_count_required_args)
    local max_args=${#_fn_args}
    local got_args=${#remaining_args}
    local range_str=$(_fn_args_range_str $min_args $max_args)

    # Check: no arguments expected but some given
    if (( max_args == 0 && got_args > 0 )); then
        printe "This function does not accept any arguments." >&2
        _fn_usage_short >&2
        REPLY=2; return 2
    fi

    # Check: not enough arguments
    if (( got_args < min_args )); then
        if (( min_args == 1 && got_args == 0 )); then
            # Special case: single missing required argument - show its name
            local missing_name arg_spec
            for arg_spec in "${_fn_args[@]}"; do
                if ! _fn_is_arg_optional "$arg_spec"; then
                    missing_name="${arg_spec%%|*}"
                    break
                fi
            done
            printe "Missing argument: <${missing_name}>" >&2
        else
            printe "Not enough arguments. Expected ${range_str}, got ${got_args}." >&2
        fi
        _fn_usage_short >&2
        REPLY=2; return 2
    fi

    # Check: too many arguments
    if (( got_args > max_args )); then
        printe "Too many arguments. Expected ${range_str}, got ${got_args}." >&2
        _fn_usage_short >&2
        REPLY=2; return 2
    fi

    # Validate argument types and build args associative array
    local -A parsed_args=()
    local -a arg_fields=()
    local arg_idx=1 arg_name arg_value arg_type
    for arg_spec in "${_fn_args[@]}"; do
        [[ -z "$arg_spec" ]] && continue
        (( arg_idx > got_args )) && break  # no more provided args

        arg_fields=( "${(@s:|:)arg_spec}" )
        arg_name="${arg_fields[1]}"
        arg_type="${arg_fields[4]:-string}"
        arg_value="${remaining_args[$arg_idx]}"

        if ! _fn_validate_type "$arg_value" "$arg_type"; then
            _fn_type_error "$arg_name" "$arg_value" "$arg_type" ""
            _fn_usage_short >&2
            REPLY=2; return 2
        fi

        parsed_args[$arg_name]="$arg_value"
        (( arg_idx++ ))
    done

    # Success - set caller's variables directly
    local k
    for k in ${(k)parsed_opts}; do
        opts[$k]="${parsed_opts[$k]}"
    done
    for k in ${(k)parsed_args}; do
        args[$k]="${parsed_args[$k]}"
    done
}

zfile_track_end ${0:A}