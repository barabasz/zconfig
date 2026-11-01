#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# Date and time helper functions
# Depends on: zsh/datetime (strftime, EPOCHSECONDS, EPOCHREALTIME)
# All getters print the result and also set REPLY. Timestamps are Unix epoch
# seconds in local time unless the function name says UTC/ISO with "Z".
# Day boundaries are computed from calendar dates, so they are DST-safe.
##

# Check that all arguments are integers (internal)
# Usage: _date_int_ok <arg> [arg...]
# Returns: 0 all integers, 1 otherwise
_date_int_ok() {
    local n
    for n in "$@"; do
        [[ $n =~ '^[+-]?[0-9]+$' ]] || return 1
    done
    return 0
}

# Set REPLY and print it (internal)
# Usage: _date_out <value>
_date_out() {
    REPLY="$1"
    print -r -- "$REPLY"
}

# Get local midnight timestamp of the day containing ts (internal, DST-safe)
# Usage: _date_midnight <timestamp>
# Sets: REPLY
_date_midnight() {
    local day
    strftime -s day "%Y-%m-%d" $1
    strftime -r -s REPLY "%Y-%m-%d" "$day"
}

## Current date and time

# Get current timestamp (Unix epoch)
# Usage: now_timestamp
# Output: e.g. 1704556800 (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
now_timestamp() {
    (( ARGC == 0 )) || return 2
    _date_out $EPOCHSECONDS
}

# Get current date in ISO 8601 format
# Usage: now_iso
# Output: e.g. 2024-01-06 (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
now_iso() {
    (( ARGC == 0 )) || return 2
    strftime -s REPLY "%Y-%m-%d" $EPOCHSECONDS
    print -r -- "$REPLY"
}

# Get current local date and time in ISO 8601 format
# Usage: now_iso_full
# Output: e.g. 2024-01-06T15:30:45 (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
now_iso_full() {
    (( ARGC == 0 )) || return 2
    strftime -s REPLY "%Y-%m-%dT%H:%M:%S" $EPOCHSECONDS
    print -r -- "$REPLY"
}

# Get current date in custom strftime format
# Usage: now_format <format>
# Example: now_format "%Y/%m/%d" -> 2024/01/06
# Output: formatted date (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
now_format() {
    (( ARGC == 1 )) || return 2
    strftime -s REPLY "$1" $EPOCHSECONDS
    print -r -- "$REPLY"
}

# Get current year
# Usage: current_year
# Output: e.g. 2024 (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
current_year() {
    (( ARGC == 0 )) || return 2
    strftime -s REPLY "%Y" $EPOCHSECONDS
    print -r -- "$REPLY"
}

# Get current month (numeric, no leading zero)
# Usage: current_month
# Output: 1-12 (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
current_month() {
    (( ARGC == 0 )) || return 2
    local val
    strftime -s val "%m" $EPOCHSECONDS
    _date_out $(( 10#$val ))
}

# Get current month name (locale dependent)
# Usage: current_month_name
# Output: e.g. January (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
current_month_name() {
    (( ARGC == 0 )) || return 2
    strftime -s REPLY "%B" $EPOCHSECONDS
    print -r -- "$REPLY"
}

# Get current day of month (no leading zero)
# Usage: current_day
# Output: 1-31 (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
current_day() {
    (( ARGC == 0 )) || return 2
    local val
    strftime -s val "%d" $EPOCHSECONDS
    _date_out $(( 10#$val ))
}

# Get current day of week name (locale dependent)
# Usage: current_weekday
# Output: e.g. Saturday (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
current_weekday() {
    (( ARGC == 0 )) || return 2
    strftime -s REPLY "%A" $EPOCHSECONDS
    print -r -- "$REPLY"
}

# Get current hour (24h format, no leading zero)
# Usage: current_hour
# Output: 0-23 (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
current_hour() {
    (( ARGC == 0 )) || return 2
    local val
    strftime -s val "%H" $EPOCHSECONDS
    _date_out $(( 10#$val ))
}

# Get current minute (no leading zero)
# Usage: current_minute
# Output: 0-59 (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
current_minute() {
    (( ARGC == 0 )) || return 2
    local val
    strftime -s val "%M" $EPOCHSECONDS
    _date_out $(( 10#$val ))
}

# Get current second (no leading zero)
# Usage: current_second
# Output: 0-59 (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
current_second() {
    (( ARGC == 0 )) || return 2
    local val
    strftime -s val "%S" $EPOCHSECONDS
    _date_out $(( 10#$val ))
}

## Conversion

# Format timestamp to date string
# Usage: format_timestamp <timestamp> <format>
# Example: format_timestamp 1704556800 "%Y-%m-%d" -> 2024-01-06
# Output: formatted date (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
format_timestamp() {
    (( ARGC == 2 )) && _date_int_ok "$1" || return 2
    strftime -s REPLY "$2" $1
    print -r -- "$REPLY"
}

# Get timestamp for a date string (local time)
# Usage: date_to_timestamp <date> [format]   (default format: %Y-%m-%d)
# Example: date_to_timestamp "2024-01-06" -> local midnight timestamp
# Example: date_to_timestamp "06.01.2024 12:30" "%d.%m.%Y %H:%M"
# Output: timestamp (stdout); also sets REPLY
# Returns: 0 success, 1 date does not match format, 2 invalid usage
date_to_timestamp() {
    (( ARGC >= 1 && ARGC <= 2 )) || return 2
    strftime -r -s REPLY "${2:-%Y-%m-%d}" "$1" 2>/dev/null || return 1
    print -r -- "$REPLY"
}

# Convert unix timestamp to ISO 8601 date (UTC)
# Usage: utime2iso <timestamp>
# Example: utime2iso 1704556800 -> 2024-01-06T16:00:00Z
# Output: ISO date (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
utime2iso() {
    (( ARGC == 1 )) || { _lib_usage "utime2iso <timestamp>"; return }
    [[ $1 == <-> ]] || { printe "utime2iso: argument must be a non-negative integer"; return 2 }
    TZ=UTC strftime -s REPLY "%Y-%m-%dT%H:%M:%SZ" "$1"
    print -r -- "$REPLY"
}

# Convert ISO 8601 date (UTC) to unix timestamp
# Usage: iso2utime <YYYY-MM-DDTHH:MM:SSZ>
# Example: iso2utime "2024-01-06T16:00:00Z" -> 1704556800
# Output: timestamp (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
iso2utime() {
    (( ARGC == 1 )) || { _lib_usage "iso2utime <YYYY-MM-DDTHH:MM:SSZ>"; return }
    [[ $1 =~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$' ]] || {
        printe "iso2utime: argument must be ISO 8601 format (YYYY-MM-DDTHH:MM:SSZ)"
        return 2
    }
    TZ=UTC strftime -r -s REPLY "%Y-%m-%dT%H:%M:%SZ" "$1"
    print -r -- "$REPLY"
}

## Arithmetic

# Add days to a timestamp (default: now)
# Usage: add_days <days> [timestamp]
# Example: add_days 7 -> timestamp 7 days from now
# Output: timestamp (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
add_days() {
    (( ARGC >= 1 && ARGC <= 2 )) && _date_int_ok "$@" || return 2
    _date_out $(( ${2:-$EPOCHSECONDS} + $1 * 86400 ))
}

# Subtract days from a timestamp (default: now)
# Usage: sub_days <days> [timestamp]
# Example: sub_days 7 -> timestamp 7 days ago
# Output: timestamp (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
sub_days() {
    (( ARGC >= 1 && ARGC <= 2 )) && _date_int_ok "$@" || return 2
    _date_out $(( ${2:-$EPOCHSECONDS} - $1 * 86400 ))
}

# Add calendar months to a timestamp (default: now); day is clamped to month end
# Usage: add_months <months> [timestamp]
# Example: add_months 1 for 2024-01-31 -> 2024-02-29 (same time of day)
# Output: timestamp (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
add_months() {
    (( ARGC >= 1 && ARGC <= 2 )) && _date_int_ok "$@" || return 2
    local -i ts=${2:-$EPOCHSECONDS}
    local y m d hms
    strftime -s y "%Y" $ts
    strftime -s m "%m" $ts
    strftime -s d "%d" $ts
    strftime -s hms "%H:%M:%S" $ts
    local -i total=$(( 10#$y * 12 + 10#$m - 1 + $1 ))
    local -i ny=$(( total / 12 )) nm=$(( total % 12 + 1 ))
    days_in_month $nm $ny >/dev/null
    local -i nd=$(( 10#$d > REPLY ? REPLY : 10#$d ))
    local date_str
    printf -v date_str "%04d-%02d-%02d %s" $ny $nm $nd $hms
    strftime -r -s REPLY "%Y-%m-%d %H:%M:%S" "$date_str"
    print -r -- "$REPLY"
}

# Get difference between two timestamps in a given unit (absolute value)
# Usage: time_between <seconds|minutes|hours|days|weeks> <timestamp1> <timestamp2>
# Example: time_between hours 1704556800 1704560400 -> 1
# Output: integer (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
time_between() {
    (( ARGC == 3 )) && _date_int_ok "$2" "$3" || return 2
    local -i diff=$(( $3 - $2 )) div
    (( diff < 0 )) && (( diff = -diff ))
    case $1 in
        s|sec|second|seconds) div=1 ;;
        m|min|minute|minutes) div=60 ;;
        h|hour|hours)         div=3600 ;;
        d|day|days)           div=86400 ;;
        w|week|weeks)         div=604800 ;;
        *)                    return 2 ;;
    esac
    _date_out $(( diff / div ))
}

# Get difference between two timestamps in days (absolute value)
# Usage: days_between <timestamp1> <timestamp2>
# Output: integer (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
days_between() {
    (( ARGC == 2 )) || return 2
    time_between days "$@"
}

# Get difference between two timestamps in hours (absolute value)
# Usage: hours_between <timestamp1> <timestamp2>
# Output: integer (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
hours_between() {
    (( ARGC == 2 )) || return 2
    time_between hours "$@"
}

# Get difference between two timestamps in minutes (absolute value)
# Usage: minutes_between <timestamp1> <timestamp2>
# Output: integer (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
minutes_between() {
    (( ARGC == 2 )) || return 2
    time_between minutes "$@"
}

# Get difference between two timestamps in seconds (absolute value)
# Usage: seconds_between <timestamp1> <timestamp2>
# Output: integer (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
seconds_between() {
    (( ARGC == 2 )) || return 2
    time_between seconds "$@"
}

# Get number of whole days from today until a date (negative if in the past)
# Usage: days_until <YYYY-MM-DD>
# Example: days_until 2026-12-24
# Output: integer (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
days_until() {
    (( ARGC == 1 )) || return 2
    local target today
    strftime -r -s target "%Y-%m-%d" "$1" 2>/dev/null || return 2
    _date_midnight $EPOCHSECONDS
    today=$REPLY
    # Round to whole days (DST days are 23 or 25 hours long)
    _date_out $(( int(rint((target - today) / 86400.0)) ))
}

## Calendar

# Check if year is a leap year
# Usage: is_leap_year <year>
# Returns: 0 true, 1 false, 2 invalid usage
is_leap_year() {
    (( ARGC == 1 )) && [[ $1 == <-> ]] || return 2
    local -i year=$1
    # Divisible by 4 AND (not divisible by 100 OR divisible by 400)
    (( year % 4 == 0 && (year % 100 != 0 || year % 400 == 0) ))
}

# Get number of days in month
# Usage: days_in_month <month> <year>
# Example: days_in_month 2 2024 -> 29, days_in_month 04 2024 -> 30
# Output: integer (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
days_in_month() {
    (( ARGC == 2 )) && [[ $1 == <-> && $2 == <-> ]] || return 2
    # 10# forces base 10, so leading zeros ("04", "09") work
    local -i month=$(( 10#$1 )) year=$(( 10#$2 ))
    (( month >= 1 && month <= 12 )) || return 2

    if (( month == 2 )); then
        is_leap_year $year && _date_out 29 || _date_out 28
    elif (( month == 4 || month == 6 || month == 9 || month == 11 )); then
        _date_out 30
    else
        _date_out 31
    fi
}

# Get age in full years from birthdate
# Usage: age_from_date <YYYY-MM-DD>
# Example: age_from_date "1990-01-06" -> 34
# Output: integer (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
age_from_date() {
    (( ARGC == 1 )) && [[ $1 =~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' ]] || return 2
    local now_ymd
    strftime -s now_ymd "%Y%m%d" $EPOCHSECONDS
    # (YYYYMMDD now - YYYYMMDD birth) / 10000 gives full years
    _date_out $(( (10#$now_ymd - 10#${1//-/}) / 10000 ))
}

# Get start of day timestamp (00:00:00)
# Usage: start_of_day [timestamp]
# Output: timestamp (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
start_of_day() {
    (( ARGC <= 1 )) && _date_int_ok ${1:-0} || return 2
    _date_midnight ${1:-$EPOCHSECONDS}
    print -r -- "$REPLY"
}

# Get end of day timestamp (23:59:59)
# Usage: end_of_day [timestamp]
# Output: timestamp (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
end_of_day() {
    (( ARGC <= 1 )) && _date_int_ok ${1:-0} || return 2
    _date_midnight ${1:-$EPOCHSECONDS}
    # Noon of the next day is always in the next day, even on DST days
    _date_midnight $(( REPLY + 86400 + 43200 ))
    _date_out $(( REPLY - 1 ))
}

# Get start of week timestamp (Monday 00:00:00)
# Usage: start_of_week [timestamp]
# Output: timestamp (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
start_of_week() {
    (( ARGC <= 1 )) && _date_int_ok ${1:-0} || return 2
    local -i ts=${1:-$EPOCHSECONDS}
    local dow
    strftime -s dow "%u" $ts  # 1=Monday, 7=Sunday
    _date_midnight $ts
    # Go back from noon so DST changes cannot move us into the wrong day
    _date_midnight $(( REPLY + 43200 - (dow - 1) * 86400 ))
    print -r -- "$REPLY"
}

# Get start of month timestamp
# Usage: start_of_month [timestamp]
# Output: timestamp (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
start_of_month() {
    (( ARGC <= 1 )) && _date_int_ok ${1:-0} || return 2
    local ym
    strftime -s ym "%Y-%m" ${1:-$EPOCHSECONDS}
    strftime -r -s REPLY "%Y-%m-%d" "${ym}-01"
    print -r -- "$REPLY"
}

# Get start of year timestamp
# Usage: start_of_year [timestamp]
# Output: timestamp (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
start_of_year() {
    (( ARGC <= 1 )) && _date_int_ok ${1:-0} || return 2
    local yr
    strftime -s yr "%Y" ${1:-$EPOCHSECONDS}
    strftime -r -s REPLY "%Y-%m-%d" "${yr}-01-01"
    print -r -- "$REPLY"
}

# Get quarter of year
# Usage: get_quarter [timestamp]
# Output: 1-4 (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
get_quarter() {
    (( ARGC <= 1 )) && _date_int_ok ${1:-0} || return 2
    local month
    strftime -s month "%m" ${1:-$EPOCHSECONDS}
    _date_out $(( (10#$month - 1) / 3 + 1 ))
}

# Get ISO week number of year
# Usage: get_week_number [timestamp]
# Output: 1-53 (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
get_week_number() {
    (( ARGC <= 1 )) && _date_int_ok ${1:-0} || return 2
    local val
    strftime -s val "%V" ${1:-$EPOCHSECONDS}
    _date_out $(( 10#$val ))
}

# Get day of year
# Usage: get_day_of_year [timestamp]
# Output: 1-366 (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
get_day_of_year() {
    (( ARGC <= 1 )) && _date_int_ok ${1:-0} || return 2
    local val
    strftime -s val "%j" ${1:-$EPOCHSECONDS}
    _date_out $(( 10#$val ))
}

# Get ISO weekday number
# Usage: weekday_number [timestamp]
# Output: 1 (Monday) - 7 (Sunday) (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
weekday_number() {
    (( ARGC <= 1 )) && _date_int_ok ${1:-0} || return 2
    strftime -s REPLY "%u" ${1:-$EPOCHSECONDS}
    print -r -- "$REPLY"
}

## Checks

# Check if timestamp is on a weekend (Saturday or Sunday)
# Usage: is_weekend [timestamp]
# Returns: 0 true, 1 false, 2 invalid usage
is_weekend() {
    (( ARGC <= 1 )) && _date_int_ok ${1:-0} || return 2
    local dow
    strftime -s dow "%u" ${1:-$EPOCHSECONDS}
    (( dow >= 6 ))
}

# Check if timestamp is today
# Usage: is_today <timestamp>
# Returns: 0 true, 1 false, 2 invalid usage
is_today() {
    (( ARGC == 1 )) && _date_int_ok "$1" || return 2
    local input_date today_date
    strftime -s input_date "%Y-%m-%d" $1
    strftime -s today_date "%Y-%m-%d" $EPOCHSECONDS
    [[ "$input_date" == "$today_date" ]]
}

# Check if timestamp is in the past
# Usage: is_past <timestamp>
# Returns: 0 true, 1 false, 2 invalid usage
is_past() {
    (( ARGC == 1 )) && _date_int_ok "$1" || return 2
    (( $1 < EPOCHSECONDS ))
}

# Check if timestamp is in the future
# Usage: is_future <timestamp>
# Returns: 0 true, 1 false, 2 invalid usage
is_future() {
    (( ARGC == 1 )) && _date_int_ok "$1" || return 2
    (( $1 > EPOCHSECONDS ))
}

## Formatting

# Get relative time description
# Usage: relative_time <timestamp>
# Example: relative_time $(( EPOCHSECONDS - 7200 )) -> "2 hours ago"
# Output: description, e.g. "2 hours ago", "in 3 days", "just now" (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
relative_time() {
    (( ARGC == 1 )) && _date_int_ok "$1" || return 2
    local -i diff=$(( EPOCHSECONDS - $1 ))
    local -i abs_diff=$(( diff < 0 ? -diff : diff ))
    local -i count
    local unit result

    if (( abs_diff < 60 )); then
        result="just now"
    else
        if (( abs_diff < 3600 )); then
            count=$(( abs_diff / 60 )); unit="minute"
        elif (( abs_diff < 86400 )); then
            count=$(( abs_diff / 3600 )); unit="hour"
        elif (( abs_diff < 604800 )); then
            count=$(( abs_diff / 86400 )); unit="day"
        elif (( abs_diff < 2592000 )); then
            count=$(( abs_diff / 604800 )); unit="week"
        elif (( abs_diff < 31536000 )); then
            count=$(( abs_diff / 2592000 )); unit="month"
        else
            count=$(( abs_diff / 31536000 )); unit="year"
        fi

        (( count != 1 )) && unit+="s"
        if (( diff < 0 )); then
            result="in $count $unit"
        else
            result="$count $unit ago"
        fi
    fi
    _date_out "$result"
}

# Format seconds (with sub-second precision) into human readable time
# Usage: format_time <seconds>
# Example: format_time 0.0005 -> "500 μs", format_time 2.5 -> "2.50 s"
# Output: formatted time (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
format_time() {
    (( ARGC == 1 )) && [[ $1 =~ '^[0-9]*[.]?[0-9]+$' ]] || return 2
    local -F val=$1
    local out

    if (( val < 0.001 )); then
        LC_NUMERIC=C printf -v out "%.0f μs" $(( val * 1000000 ))
    elif (( val < 1 )); then
        LC_NUMERIC=C printf -v out "%.1f ms" $(( val * 1000 ))
    else
        LC_NUMERIC=C printf -v out "%.2f s" $val
    fi
    _date_out "$out"
}

# Format seconds into human readable duration
# Usage: format_duration <seconds>
# Example: format_duration 45 -> "45s", 3665 -> "1h 1m", 93784 -> "1d 2h 3m"
# Output: duration (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
format_duration() {
    (( ARGC == 1 )) && [[ $1 == <-> ]] || return 2
    local -i sec=$1
    local -i d=$(( sec / 86400 )) h=$(( (sec % 86400) / 3600 ))
    local -i m=$(( (sec % 3600) / 60 )) s=$(( sec % 60 ))

    if (( sec < 60 )); then
        _date_out "${s}s"
    elif (( sec < 3600 )); then
        _date_out "${m}m ${s}s"
    elif (( sec < 86400 )); then
        _date_out "${h}h ${m}m"
    else
        _date_out "${d}d ${h}h ${m}m"
    fi
}

# Shell files tracking - keep at the end
zfile_track_end ${0:A}
