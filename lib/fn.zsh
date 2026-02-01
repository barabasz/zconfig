#!/bin/zsh
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# Function metadata and argument parsing library
# Provides standardized help generation, option parsing, argument validation, and type checking.
#
# Dependencies: printe (from out.zsh), color variables ($r, $g, $y, $c, $m, $x)
#
# Usage example in user function:
#
#   local -A _fn=(
#       [version]="1.0.0"                   # enables -v/--version
#       [info]="Short info"                 # one-liner shown in help header
#       [desc]="Full description"           # shown in Description section
#       [author]="Author Name"              # shown in footer
#       # [name] is auto-detected from function name
#   )
#
#   local -a _fn_args=(
#       "input|Input file path"             # name|description (required, string)
#       "output|Output file|o"              # name|description|o (optional, string)
#       "count|Number of items|r|integer"   # name|description|r|type (required, typed)
#   )
#
#   local -a _fn_opts=(
#       "force|f|Force overwrite"           # long|short|description (flag)
#       "cycles|c|Number of cycles|n"       # long|short|description|arg_name (takes value)
#       "count|n|Count|n|integer"           # long|short|description|arg_name|type (typed)
#       "test||Test mode"                   # long||description (no short form)
#   )
#
#   local -a _fn_examples=(
#       "myfunc input.txt"                          # example only
#       "myfunc -c 8 input.txt|Process with 8 cycles"  # example|description
#   )
#
#   # Auto-added options (unless already defined):
#   # -v/--version: added if _fn[version] is set
#   # -h/--help: added if any of: version, info, desc, opts, args, or examples exist
#
#   local -A opts=() args=()
#   _fn_init "$@" || return $REPLY
#
#   # Now available:
#   # ${opts[cycles]}  - option value (by long name)
#   # ${args[input]}   - argument value (by name)
#   # (( ${+opts[force]} )) - check if flag is set
#
# Supported types: string, char, digit, integer, float, date, time, datetime, bool, ipv4, ipv6, email, domain, url
# Ranged types with interval notation (for integer, float, string):
#   [a;b] = inclusive (a <= x <= b), (a;b) = exclusive (a < x < b)
#   [a;b) = left-inclusive, (a;b] = right-inclusive
#   Examples: integer[1;10], float(0;1], string[1;255], string(;100]
#   For string, range applies to length: string(;20] = non-empty string up to 20 chars
# URL with schema restrictions: url[http,https] or url[http,https,ftp]
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
    [email]='^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    [domain]='^([a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$'
    [url]='^[a-zA-Z][a-zA-Z0-9+.-]*://[^\s]+$'
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
    [email]="email address"
    [domain]="domain name"
    [url]="URL"
    [datetime]="datetime (YYYY-MM-DDTHH:MM:SS)"
    [ipv4]="IPv4 address (e.g., 192.168.1.1)"
    [ipv6]="IPv6 address (e.g., 2001:db8::1)"
    [bool]="boolean (true/false, yes/no, 1/0)"
)

# _fn_section - Print section header
# Usage: _fn_section "Section Title"
# Prints a formatted section header
_fn_section() {
    print "\n${y}$1:${x}"
}

# _fn_description - Print function description
# Usage: _fn_description "Description text"
# Normalizes whitespace (2+ spaces → 1), trims leading spaces, adds 2-space indent
_fn_description() {
    print "$1" | sed 's/  */ /g; s/^ //; s/^/  /'
}

# _fn_parse_url_schemas - Parse url type with optional schema list
# Usage: _fn_parse_url_schemas "url[http,https,ftp]"
# Sets: REPLY_BASE ("url"), REPLY_SCHEMAS (comma-separated list or empty)
_fn_parse_url_schemas() {
    local type="$1"
    REPLY_BASE="" REPLY_SCHEMAS=""

    if [[ "$type" =~ '^(url)\[([a-zA-Z0-9,+-]+)\]$' ]]; then
        REPLY_BASE="${match[1]}"
        REPLY_SCHEMAS="${match[2]}"
    elif [[ "$type" == "url" ]]; then
        REPLY_BASE="url"
    fi
}

# _fn_parse_ranged_type - Parse type with optional range
# Usage: _fn_parse_ranged_type "integer[3;9]" or "float(0;1]"
# Sets: REPLY_BASE (base type), REPLY_MIN, REPLY_MAX, REPLY_MIN_INC, REPLY_MAX_INC
# REPLY_MIN_INC/REPLY_MAX_INC: 1 if inclusive ([ or ]), 0 if exclusive (( or ))
_fn_parse_ranged_type() {
    local type="$1"
    REPLY_BASE="" REPLY_MIN="" REPLY_MAX="" REPLY_MIN_INC=1 REPLY_MAX_INC=1

    # Match: type + bracket + number ; number + bracket
    # Using alternation instead of character class for brackets
    if [[ "$type" =~ '^([a-z]+)(\[|\()(-?[0-9]*\.?[0-9]*);(-?[0-9]*\.?[0-9]*)(\]|\))$' ]]; then
        REPLY_BASE="${match[1]}"
        [[ "${match[2]}" == "[" ]] && REPLY_MIN_INC=1 || REPLY_MIN_INC=0
        REPLY_MIN="${match[3]}"
        REPLY_MAX="${match[4]}"
        [[ "${match[5]}" == "]" ]] && REPLY_MAX_INC=1 || REPLY_MAX_INC=0
    else
        REPLY_BASE="$type"
    fi
}

# _fn_validate_type - Validate value against type
# Usage: _fn_validate_type "value" "type"
# Supports ranged types: integer[min;max], float(min;max), string[min;max], url[schemas]
# Returns: 0 if valid, 1 if invalid
_fn_validate_type() {
    local value="$1" type="${2:-string}"

    # Check for URL with schema restrictions first
    if [[ "$type" == url* ]]; then
        _fn_parse_url_schemas "$type"
        if [[ "$REPLY_BASE" == "url" ]]; then
            local url_pattern="${_FN_TYPES[url]}"
            [[ -z "$value" ]] && return 1
            [[ "$value" =~ $url_pattern ]] || return 1

            # If schemas specified, check if URL uses allowed schema
            if [[ -n "$REPLY_SCHEMAS" ]]; then
                local url_schema="${value%%://*}"
                local allowed_schemas=",${REPLY_SCHEMAS},"
                [[ "$allowed_schemas" == *",${url_schema},"* ]] || return 1
            fi
            return 0
        fi
    fi

    # Parse type for range specifier
    _fn_parse_ranged_type "$type"
    local base_type="$REPLY_BASE" min_val="$REPLY_MIN" max_val="$REPLY_MAX"
    local min_inc="$REPLY_MIN_INC" max_inc="$REPLY_MAX_INC"

    local pattern="${_FN_TYPES[$base_type]}"

    # Unknown type - treat as string (always valid)
    [[ -z "$pattern" ]] && return 0

    # Empty value is invalid for typed fields (except string without range)
    if [[ -z "$value" && "$base_type" != "string" ]]; then
        return 1
    fi

    # Match against base type pattern
    [[ "$value" =~ $pattern ]] || return 1

    # Check range constraints (also when exclusive brackets used with empty value)
    if [[ -n "$min_val" || -n "$max_val" ]] || (( !min_inc || !max_inc )); then
        local check_val
        if [[ "$base_type" == "string" ]]; then
            # For string, check length
            check_val=${#value}
        elif [[ "$base_type" == "integer" || "$base_type" == "float" ]]; then
            # For numeric types, check value
            check_val=$value
        else
            return 0  # Other types don't support ranges
        fi

        # Check minimum
        # Empty min with exclusive bracket ( means > 0
        if [[ -n "$min_val" ]]; then
            if (( min_inc )); then
                (( check_val < min_val )) && return 1
            else
                (( check_val <= min_val )) && return 1
            fi
        elif (( ! min_inc )); then
            # ( with empty min means > 0
            (( check_val <= 0 )) && return 1
        fi
        # Check maximum
        if [[ -n "$max_val" ]]; then
            if (( max_inc )); then
                (( check_val > max_val )) && return 1
            else
                (( check_val >= max_val )) && return 1
            fi
        fi
    fi

    return 0
}

# _fn_type_error - Print type validation error
# Usage: _fn_type_error "name" "value" "type" ["option"]
_fn_type_error() {
    local name="$1" value="$2" type="$3" is_option="$4"
    local desc=""

    # Check for URL with schema restrictions first
    if [[ "$type" == url* ]]; then
        _fn_parse_url_schemas "$type"
        if [[ "$REPLY_BASE" == "url" ]]; then
            if [[ -n "$REPLY_SCHEMAS" ]]; then
                local schemas_readable="${REPLY_SCHEMAS//,/, }"
                desc="URL with schema: ${schemas_readable}"
            else
                desc="URL"
            fi
            if [[ -n "$is_option" ]]; then
                printe "Invalid value for --${name}: '${value}' is not ${desc}." >&2
            else
                printe "Invalid value for <${name}>: '${value}' is not ${desc}." >&2
            fi
            return
        fi
    fi

    # Parse type for range specifier
    _fn_parse_ranged_type "$type"
    local base_type="$REPLY_BASE" min_val="$REPLY_MIN" max_val="$REPLY_MAX"
    local min_inc="$REPLY_MIN_INC" max_inc="$REPLY_MAX_INC"

    desc="${_FN_TYPE_DESC[$base_type]:-$base_type}"

    # Add range info to description in user-friendly format
    if [[ -n "$min_val" || -n "$max_val" ]] || (( !min_inc || !max_inc )); then
        # Effective min: if empty but exclusive, treat as 0
        local eff_min="${min_val:-0}"
        [[ -z "$min_val" ]] && (( min_inc )) && eff_min=""

        # Build constraint description
        local min_op max_op constraint=""
        (( min_inc )) && min_op="≥" || min_op=">"
        (( max_inc )) && max_op="≤" || max_op="<"

        if [[ -n "$eff_min" && -n "$max_val" ]]; then
            constraint="${min_op} ${eff_min} and ${max_op} ${max_val}"
        elif [[ -n "$eff_min" ]]; then
            constraint="${min_op} ${eff_min}"
        elif [[ -n "$max_val" ]]; then
            constraint="${max_op} ${max_val}"
        fi

        # For string, describe length constraint
        if [[ "$base_type" == "string" ]]; then
            if [[ -n "$constraint" ]]; then
                desc="string with length ${constraint}"
            fi
        else
            # For numeric types
            if [[ -n "$constraint" ]]; then
                desc+=" ${constraint}"
            fi
        fi
    fi

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
# Supports ranged types: integer[min;max], float(min;max), string[min;max], url[schemas]
# Returns: 0 if valid, 1 if invalid
_fn_validate_type_name() {
    [[ -z "$1" ]] && return 0  # empty = default (string)

    # Check for URL with schema restrictions
    if [[ "$1" == url* ]]; then
        _fn_parse_url_schemas "$1"
        [[ "$REPLY_BASE" == "url" ]] && return 0
        return 1
    fi

    # Parse for range specifier
    _fn_parse_ranged_type "$1"
    local base_type="$REPLY_BASE" min_val="$REPLY_MIN" max_val="$REPLY_MAX"

    # Check if base type exists
    (( ${+_FN_TYPES[$base_type]} )) || return 1

    # If range specified, check it's valid
    if [[ -n "$min_val" || -n "$max_val" ]]; then
        # Only integer, float, and string support ranges
        [[ "$base_type" != "integer" && "$base_type" != "float" && "$base_type" != "string" ]] && return 1
        # If both specified, min must be <= max
        if [[ -n "$min_val" && -n "$max_val" ]]; then
            (( min_val <= max_val )) || return 1
        fi
        # For string, range values must be non-negative (length can't be negative)
        if [[ "$base_type" == "string" ]]; then
            [[ -n "$min_val" ]] && (( min_val < 0 )) && return 1
            [[ -n "$max_val" ]] && (( max_val < 0 )) && return 1
        fi
    fi

    return 0
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
    local name=${_fn[name]}
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
    local name=${_fn[name]}
    local usage="${y}Usage: ${g}${name}${x}"

    _fn_has_opts && usage+=" ${c}[options]${x}"

    if _fn_has_args; then
        local arg_spec
        for arg_spec in "${_fn_args[@]}"; do
            [[ -z "$arg_spec" ]] && continue
            local arg_name="${arg_spec%%|*}"
            if _fn_is_arg_optional "$arg_spec"; then
                usage+=" ${c}[${arg_name}]${x}"
            else
                usage+=" ${c}<${arg_name}>${x}"
            fi
        done
    fi

    print "$usage"
}

# _fn_usage_short - Print short usage (for errors)
_fn_usage_short() {
    local name=${_fn[name]}

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
    local name=${_fn[name]}
    local version=${_fn[version]:-""}
    local author=${_fn[author]:-""}

    # Short description if available
    if [[ -n "${_fn[info]}" ]]; then
        print "$g$name$x - ${_fn[info]}"
    fi

    # Usage line
    _fn_usage_line

    # Long description
    if [[ -n "${_fn[desc]}" ]]; then
        _fn_section "Description"
        _fn_description "${_fn[desc]}"
    fi

    # Calculate max width for left column (arguments + options)
    local _max_width=0 _len _label _spec
    local -a _fld=()

    # Check argument widths
    if _fn_has_args; then
        for _spec in "${_fn_args[@]}"; do
            [[ -z "$_spec" ]] && continue
            _fld=( "${(@s:|:)_spec}" )
            _label="[${_fld[1]}]"  # [name] or <name> - same length
            _len=${#_label}
            (( _len > _max_width )) && _max_width=$_len
        done
    fi

    # Check option widths
    if _fn_has_opts; then
        for _spec in "${_fn_opts[@]}"; do
            [[ -z "$_spec" ]] && continue
            _fld=( "${(@s:|:)_spec}" )
            if [[ -n "${_fld[2]}" ]]; then
                _label="-${_fld[2]}, --${_fld[1]}"
            else
                _label="    --${_fld[1]}"
            fi
            [[ -n "${_fld[4]}" ]] && _label+=" <${_fld[4]}>"
            _len=${#_label}
            (( _len > _max_width )) && _max_width=$_len
        done
    fi

    # Add 2 spaces padding
    (( _max_width += 2 ))

    # Arguments section
    if _fn_has_args; then
        _fn_section "Arguments"
        local _arg_spec _arg_name _arg_desc _arg_type _arg_meta _arg_label _arg_is_req
        local -a _arg_fld=()
        for _arg_spec in "${_fn_args[@]}"; do
            [[ -z "$_arg_spec" ]] && continue
            _arg_fld=( "${(@s:|:)_arg_spec}" )
            _arg_name="${_arg_fld[1]}"
            _arg_desc="${_arg_fld[2]:-}"
            _arg_type="${_arg_fld[4]:-}"

            # Check if required
            _arg_is_req=1
            _fn_is_arg_optional "$_arg_spec" && _arg_is_req=0

            # Build metadata suffix: [required, type] or [type]
            _arg_meta=""
            if (( _arg_is_req )); then
                _arg_meta=" ${y}[${r}required${y}, ${c}${_arg_type:-string}${y}]${x}"
            else
                _arg_meta=" ${y}[${c}${_arg_type:-string}${y}]${x}"
            fi

            if (( _arg_is_req )); then
                _arg_label="<${_arg_name}>"
            else
                _arg_label="[${_arg_name}]"
            fi
            printf "  ${c}%-${_max_width}s${x}%s%s\n" "$_arg_label" "$_arg_desc" "$_arg_meta"
        done
    fi

    # Options section
    if _fn_has_opts; then
        _fn_section "Options"
        local _opt_spec _opt_long _opt_short _opt_desc _opt_arg _opt_type _opt_disp _opt_disp_colored _opt_meta _opt_pad
        local -a _opt_fld=()
        for _opt_spec in "${_fn_opts[@]}"; do
            [[ -z "$_opt_spec" ]] && continue
            _opt_fld=( "${(@s:|:)_opt_spec}" )
            _opt_long="${_opt_fld[1]}"
            _opt_short="${_opt_fld[2]:-}"
            _opt_desc="${_opt_fld[3]:-}"
            _opt_arg="${_opt_fld[4]:-}"
            _opt_type="${_opt_fld[5]:-}"

            # Build display string (plain, for width calculation)
            if [[ -n "$_opt_short" ]]; then
                _opt_disp="-${_opt_short}, --${_opt_long}"
            else
                _opt_disp="    --${_opt_long}"
            fi
            [[ -n "$_opt_arg" ]] && _opt_disp+=" <${_opt_arg}>"

            # Build colored display string
            if [[ -n "$_opt_short" ]]; then
                _opt_disp_colored="${c}-${_opt_short}, --${_opt_long}${x}"
            else
                _opt_disp_colored="    ${c}--${_opt_long}${x}"
            fi
            [[ -n "$_opt_arg" ]] && _opt_disp_colored+=" ${p}<${_opt_arg}>${x}"

            # Build metadata suffix: [type] for options that take a value
            _opt_meta=""
            if [[ -n "$_opt_arg" ]]; then
                _opt_meta=" ${y}[${c}${_opt_type:-string}${y}]${x}"
            fi

            # Calculate padding (max_width - actual length)
            _opt_pad=$(( _max_width - ${#_opt_disp} ))
            printf "  %s%*s%s%s\n" "$_opt_disp_colored" "$_opt_pad" "" "$_opt_desc" "$_opt_meta"
        done
    fi

    # Examples section
    if (( ${+_fn_examples} && ${#_fn_examples} > 0 )); then
        _fn_section "Examples"
        local _ex_entry _ex_cmd _ex_desc _ex_cmd_colored _ex_rest
        for _ex_entry in "${_fn_examples[@]}"; do
            _ex_cmd="${_ex_entry%%|*}"
            _ex_desc="${_ex_entry#*|}"
            # Color function name green, rest cyan
            if [[ "$_ex_cmd" == "${name} "* ]]; then
                _ex_rest="${_ex_cmd#${name} }"
                _ex_cmd_colored="${g}${name}${x} ${c}${_ex_rest}${x}"
            elif [[ "$_ex_cmd" == "${name}" ]]; then
                _ex_cmd_colored="${g}${name}${x}"
            else
                _ex_cmd_colored="${c}${_ex_cmd}${x}"
            fi
            # If no separator found, _ex_desc equals _ex_cmd
            if [[ "$_ex_desc" == "$_ex_cmd" ]]; then
                print "  ${_ex_cmd_colored}"
            else
                print "  ${_ex_cmd_colored} - ${_ex_desc}"
            fi
        done
    fi

    # Footer: version, author, file location
    print
    local footer=""
    [[ -n "$version" ]] && footer+="${g}${name}${x} ver. ${c}${version}${x}"
    [[ -n "$author" ]] && footer+=" by ${c}${author}${x}"
    [[ -n "$footer" ]] && print "$footer"

    local file=$(_fn_get_file)
    [[ -n "$file" ]] && print "This function is defined in ${c}${file}${x}"
}

# _fn_version - Print version string
_fn_version() {
    if [[ -n "${_fn[version]}" ]]; then
        print "$g${_fn[name]}$x ${_fn[version]}"
    else
        print "$g${_fn[name]}$x: version not set"
    fi
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

    # Ensure _fn exists and has defaults
    # Use funcstack[2] to get the caller's function name (funcstack[1] is _fn_init)
    if (( ! ${+_fn} )); then
        # _fn not defined at all - create it in caller's scope
        typeset -gA _fn=()
    fi
    : ${_fn[name]:=${funcstack[2]:-unknown}}
    if (( ${_fn[info]+1} )) && [[ -z $_fn[info] ]]; then
        unset "_fn[info]"
    fi

    # Auto-add -v/--version and -h/--help options
    local _has_version_val=0 _has_info=0 _has_desc=0
    local _orig_has_opts=0 _orig_has_args=0 _orig_has_examples=0
    [[ -n "${_fn[version]}" ]] && _has_version_val=1
    [[ -n "${_fn[info]}" ]] && _has_info=1
    [[ -n "${_fn[desc]}" ]] && _has_desc=1
    (( ${+_fn_opts} && ${#_fn_opts} > 0 )) && _orig_has_opts=1
    (( ${+_fn_args} && ${#_fn_args} > 0 )) && _orig_has_args=1
    (( ${+_fn_examples} && ${#_fn_examples} > 0 )) && _orig_has_examples=1

    # Check for conflicts with user-defined options
    local _has_v=0 _has_version=0 _has_h=0 _has_help=0
    if (( _orig_has_opts )); then
        local _chk_spec
        local -a _chk_fld=()
        for _chk_spec in "${_fn_opts[@]}"; do
            [[ -z "$_chk_spec" ]] && continue
            _chk_fld=( "${(@s:|:)_chk_spec}" )
            [[ "${_chk_fld[1]}" == "version" ]] && _has_version=1
            [[ "${_chk_fld[2]}" == "v" ]] && _has_v=1
            [[ "${_chk_fld[1]}" == "help" ]] && _has_help=1
            [[ "${_chk_fld[2]}" == "h" ]] && _has_h=1
        done
    fi

    # Ensure _fn_opts exists
    (( ${+_fn_opts} )) || typeset -ga _fn_opts=()

    # Auto-add version option if version is set and no conflict
    if (( _has_version_val && !_has_v && !_has_version )); then
        _fn_opts=( "version|v|Show version" "${_fn_opts[@]}" )
    fi

    # Auto-add help option if there's reason to show help and no conflict
    local _needs_help=$(( _has_version_val || _has_info || _has_desc || _orig_has_opts || _orig_has_args || _orig_has_examples ))
    if (( _needs_help && !_has_h && !_has_help )); then
        _fn_opts=( "help|h|Show this help message" "${_fn_opts[@]}" )
    fi

    # Validate definitions before processing
    _fn_validate_args || { REPLY=3; return 3; }
    _fn_validate_opts || { REPLY=3; return 3; }

    local -A parsed_opts=()
    local -a remaining_args=()

    # Build option info from _fn_opts
    # Format: long|short|description|arg_name|type
    local -a zparse_spec=()
    local -A needs_value=()     # short -> 1 if requires value
    local -A is_known_short=()  # short -> 1
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
        [[ -n "$short_part" ]] && is_known_short[$short_part]=1
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