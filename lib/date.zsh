#!/bin/zsh
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# Get current timestamp (Unix epoch)
# Usage: now_timestamp
# Returns: 1704556800
now_timestamp() {
    print -- $EPOCHSECONDS
}

# Get current date in ISO 8601 format
# Usage: now_iso
# Returns: 2024-01-06 (Keeps zeros as required by ISO)
now_iso() {
    strftime "%Y-%m-%d" $EPOCHSECONDS
}

# Get current date and time in ISO 8601 format
# Usage: now_iso_full
# Returns: 2024-01-06T15:30:45 (Keeps zeros as required by ISO)
now_iso_full() {
    strftime "%Y-%m-%dT%H:%M:%S" $EPOCHSECONDS
}

# Get current date in custom format
# Usage: now_format "%Y/%m/%d"
# Returns: 2024/01/06 (Format depends on user input)
now_format() {
    (( ARGC == 1 )) || return 1
    strftime "$1" $EPOCHSECONDS
}

# Get current year
# Usage: current_year
# Returns: 2024
current_year() {
    strftime "%Y" $EPOCHSECONDS
}

# Get current month (numeric)
# Usage: current_month
# Returns: 1-12 (no leading zeros)
current_month() {
    local val
    strftime -s val "%m" $EPOCHSECONDS
    # $(( val )) effectively strips leading zeros
    print -- $(( val ))
}

# Get current month (name)
# Usage: current_month_name
# Returns: January
current_month_name() {
    strftime "%B" $EPOCHSECONDS
}

# Get current day
# Usage: current_day
# Returns: 1-31 (no leading zeros)
current_day() {
    local val
    strftime -s val "%d" $EPOCHSECONDS
    print -- $(( val ))
}

# Get current day of week (name)
# Usage: current_weekday
# Returns: Saturday
current_weekday() {
    strftime "%A" $EPOCHSECONDS
}

# Get current hour (24h format)
# Usage: current_hour
# Returns: 0-23 (no leading zeros)
current_hour() {
    local val
    strftime -s val "%H" $EPOCHSECONDS
    print -- $(( val ))
}

# Get current minute
# Usage: current_minute
# Returns: 0-59 (no leading zeros)
current_minute() {
    local val
    strftime -s val "%M" $EPOCHSECONDS
    print -- $(( val ))
}

# Get current second
# Usage: current_second
# Returns: 0-59 (no leading zeros)
current_second() {
    local val
    strftime -s val "%S" $EPOCHSECONDS
    print -- $(( val ))
}

# Format timestamp to date string
# Usage: format_timestamp 1704556800 "%Y-%m-%d"
# Returns: 2024-01-06
format_timestamp() {
    (( ARGC == 2 )) || return 1
    strftime "$2" $1
}

# Get timestamp for specific date
# Usage: date_to_timestamp "2024-01-06"
# Returns: 1704556800
date_to_timestamp() {
    (( ARGC == 1 )) || return 1
    # Use built-in reverse strftime (-r) to parse date.
    strftime -r "%Y-%m-%d" "$1"
}

# Add days to current date
# Usage: add_days 7
# Returns: timestamp for 7 days from now
add_days() {
    (( ARGC == 1 )) || return 1
    print -- $(( EPOCHSECONDS + ($1 * 86400) ))
}

# Subtract days from current date
# Usage: sub_days 7
# Returns: timestamp for 7 days ago
sub_days() {
    (( ARGC == 1 )) || return 1
    print -- $(( EPOCHSECONDS - ($1 * 86400) ))
}

# Get difference between two timestamps in days
# Usage: days_between 1704556800 1704643200
# Returns: 1 (absolute value)
days_between() {
    (( ARGC == 2 )) || return 1
    local diff=$(( $2 - $1 ))
    # Mathematical absolute value
    (( diff = diff < 0 ? -diff : diff ))
    print -- $(( diff / 86400 ))
}

# Get difference between two timestamps in hours
# Usage: hours_between 1704556800 1704560400
# Returns: 1 (absolute value)
hours_between() {
    (( ARGC == 2 )) || return 1
    local diff=$(( $2 - $1 ))
    (( diff = diff < 0 ? -diff : diff ))
    print -- $(( diff / 3600 ))
}

# Get difference between two timestamps in minutes
# Usage: minutes_between 1704556800 1704556860
# Returns: 1 (absolute value)
minutes_between() {
    (( ARGC == 2 )) || return 1
    local diff=$(( $2 - $1 ))
    (( diff = diff < 0 ? -diff : diff ))
    print -- $(( diff / 60 ))
}

# Get difference between two timestamps in seconds
# Usage: seconds_between 1704556800 1704556801
# Returns: 1 (absolute value)
seconds_between() {
    (( ARGC == 2 )) || return 1
    local diff=$(( $2 - $1 ))
    (( diff = diff < 0 ? -diff : diff ))
    print -- $diff
}

# Check if year is leap year
# Usage: is_leap_year 2024
# Returns: 0 (true) or 1 (false)
is_leap_year() {
    (( ARGC == 1 )) || return 1
    local year=$1
    # Logic: divisible by 4 AND (not divisible by 100 OR divisible by 400)
    (( year % 4 == 0 && (year % 100 != 0 || year % 400 == 0) ))
}

# Get number of days in month
# Usage: days_in_month 2 2024
# Returns: 29 (February 2024 is a leap year)
days_in_month() {
    (( ARGC == 2 )) || return 1
    local month=$1
    local year=$2

    if (( month == 2 )); then
        is_leap_year $year && print 29 || print 28
    # Optimization: Use Zsh pattern matching instead of slow string manipulation
    elif [[ $month == (4|6|9|11) ]]; then
        print 30
    else
        print 31
    fi
}

# Get age from birthdate
# Usage: age_from_date "1990-01-06"
# Returns: 34
age_from_date() {
    (( ARGC == 1 )) || return 1
    local birth_date="$1"
    
    local now_ymd
    local birth_ymd
    
    # Get current YYYYMMDD
    strftime -s now_ymd "%Y%m%d" $EPOCHSECONDS
    
    # Remove dashes from input to get YYYYMMDD
    birth_ymd=${birth_date//-/}
    
    # Formula: (Current - Birth) / 10000 gives full years
    print -- $(( (now_ymd - birth_ymd) / 10000 ))
}

# Get start of day timestamp (00:00:00)
# Usage: start_of_day [timestamp]
# Returns: timestamp for start of day
start_of_day() {
    local ts=${1:-$EPOCHSECONDS}
    local date_str
    # Convert ts to YYYY-MM-DD
    strftime -s date_str "%Y-%m-%d" $ts
    # Convert YYYY-MM-DD back to timestamp (defaults to 00:00:00)
    strftime -r "%Y-%m-%d" "$date_str"
}

# Get end of day timestamp (23:59:59)
# Usage: end_of_day [timestamp]
# Returns: timestamp for end of day
end_of_day() {
    local ts=${1:-$EPOCHSECONDS}
    local date_str
    local start
    
    # Inlined start_of_day logic to avoid subshell $(...) overhead
    strftime -s date_str "%Y-%m-%d" $ts
    strftime -r -s start "%Y-%m-%d" "$date_str"
    
    print -- $(( start + 86399 ))
}

# Get start of week timestamp (Monday 00:00:00)
# Usage: start_of_week [timestamp]
# Returns: timestamp for start of week
start_of_week() {
    local ts=${1:-$EPOCHSECONDS}
    local dow
    local date_str
    local start_today
    
    strftime -s dow "%u" $ts  # 1=Monday, 7=Sunday
    local days_back=$(( dow - 1 ))
    
    # Inlined start_of_day logic to avoid subshell $(...) overhead
    strftime -s date_str "%Y-%m-%d" $ts
    strftime -r -s start_today "%Y-%m-%d" "$date_str"
    
    print -- $(( start_today - (days_back * 86400) ))
}

# Get start of month timestamp
# Usage: start_of_month [timestamp]
# Returns: timestamp for start of month
start_of_month() {
    local ts=${1:-$EPOCHSECONDS}
    local ym
    strftime -s ym "%Y-%m" $ts
    strftime -r "%Y-%m-%d" "${ym}-01"
}

# Get start of year timestamp
# Usage: start_of_year [timestamp]
# Returns: timestamp for start of year
start_of_year() {
    local ts=${1:-$EPOCHSECONDS}
    local y
    strftime -s y "%Y" $ts
    strftime -r "%Y-%m-%d" "${y}-01-01"
}

# Check if date is today
# Usage: is_today 1704556800
# Returns: 0 (true) or 1 (false)
is_today() {
    (( ARGC == 1 )) || return 1
    local input_date
    local today_date
    
    strftime -s input_date "%Y-%m-%d" $1
    strftime -s today_date "%Y-%m-%d" $EPOCHSECONDS
    
    [[ "$input_date" == "$today_date" ]]
}

# Check if date is in the past
# Usage: is_past 1704556800
# Returns: 0 (true) or 1 (false)
is_past() {
    (( ARGC == 1 )) || return 1
    (( $1 < EPOCHSECONDS ))
}

# Check if date is in the future
# Usage: is_future 1704556800
# Returns: 0 (true) or 1 (false)
is_future() {
    (( ARGC == 1 )) || return 1
    (( $1 > EPOCHSECONDS ))
}

# Get relative time description
# Usage: relative_time 1704556800
# Returns: "2 hours ago" or "in 3 days"
relative_time() {
    (( ARGC == 1 )) || return 1
    local ts=$1
    local now=$EPOCHSECONDS
    local diff=$(( now - ts ))
    # Calculate absolute difference
    local abs_diff
    (( abs_diff = diff < 0 ? -diff : diff ))
    
    local count unit result

    if (( abs_diff < 60 )); then
        result="just now"
    else
        if (( abs_diff < 3600 )); then
            count=$(( abs_diff / 60 ))
            unit="minute"
        elif (( abs_diff < 86400 )); then
            count=$(( abs_diff / 3600 ))
            unit="hour"
        elif (( abs_diff < 604800 )); then
            count=$(( abs_diff / 86400 ))
            unit="day"
        elif (( abs_diff < 2592000 )); then
            count=$(( abs_diff / 604800 ))
            unit="week"
        elif (( abs_diff < 31536000 )); then
            count=$(( abs_diff / 2592000 ))
            unit="month"
        else
            count=$(( abs_diff / 31536000 ))
            unit="year"
        fi

        (( count != 1 )) && unit="${unit}s"
        result="$count $unit"
        
        if (( diff < 0 )); then
            result="in $result"
        else
            result="$result ago"
        fi
    fi
    
    print -- "$result"
}

# Get quarter of year (1-4)
# Usage: get_quarter [timestamp]
# Returns: 1, 2, 3, or 4
get_quarter() {
    local ts=${1:-$EPOCHSECONDS}
    local month
    strftime -s month "%m" $ts
    # Integer math trick to calculate quarter: (month - 1) / 3 + 1
    print -- $(( (month - 1) / 3 + 1 ))
}

# Get week number of year
# Usage: get_week_number [timestamp]
# Returns: 1-53 (no leading zeros)
get_week_number() {
    local ts=${1:-$EPOCHSECONDS}
    local val
    strftime -s val "%V" $ts
    print -- $(( val ))
}

# Get day of year
# Usage: get_day_of_year [timestamp]
# Returns: 1-366 (no leading zeros)
get_day_of_year() {
    local ts=${1:-$EPOCHSECONDS}
    local val
    strftime -s val "%j" $ts
    print -- $(( val ))
}

# Format seconds (with sub-second precision) into human readable time
# Usage: format_time 0.0005    → "500 μs"
#        format_time 2.5       → "2.50 s"
format_time() {
    (( ARGC == 1 )) || return 1
    local -F val=$1

    if (( val < 0.001 )); then
        printf "%.0f μs" $(( val * 1000000 ))
    elif (( val < 1 )); then
        printf "%.1f ms" $(( val * 1000 ))
    else
        printf "%.2f s" $val
    fi
}

# Format seconds into human readable duration
# Usage: format_duration 3665
# Returns: "1.0 h" or "1 day 2h 30m"
format_duration() {
    (( ARGC == 1 )) || return 1
    local sec=$1
    local d h m

    if (( sec < 60 )); then
        print -- "${sec} sec"
    elif (( sec < 3600 )); then
        # Use printf for float precision
        printf "%.1f min\n" $(( sec / 60.0 ))
    elif (( sec < 86400 )); then
        printf "%.1f h\n" $(( sec / 3600.0 ))
    else
        d=$(( sec / 86400 ))
        h=$(( (sec % 86400) / 3600 ))
        m=$(( (sec % 3600) / 60 ))
        if (( d == 1 )); then
            print -- "${d} day ${h}h ${m}m"
        else
            print -- "${d} days ${h}h ${m}m"
        fi
    fi
}

# shell files tracking - keep at the end
zfile_track_end ${0:A}