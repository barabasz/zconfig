# Tests for lib/date.zsh (runner sets TZ=UTC)

## days_in_month handles leading zeros from strftime (audit bug #8)
assert_eq "$(days_in_month 04 2024)" 30 "April with leading zero"
assert_eq "$(days_in_month 2 2024)" 29 "leap February"
assert_eq "$(days_in_month 2 2023)" 28 "February"
assert_rc 2 days_in_month 13 2024
assert_ok is_leap_year 2000
assert_fail is_leap_year 1900

## conversions (2024-03-15 00:00:00 UTC = 1710460800)
assert_eq "$(date_to_timestamp 2024-03-15)" 1710460800 "date_to_timestamp"
assert_eq "$(format_timestamp 1710460800 %Y-%m-%d)" 2024-03-15 "format_timestamp"
assert_eq "$(add_days 1 1710460800)" 1710547200 "add_days"
assert_eq "$(format_timestamp $(add_months 1 $(date_to_timestamp 2024-01-31)) %Y-%m-%d)" 2024-02-29 "add_months clamps to month end"
assert_eq "$(days_between 1710460800 1710547200)" 1 "days_between"
assert_eq "$(time_between hours 1710460800 1710547200)" 24 "time_between hours"

## calendar helpers
assert_eq "$(get_quarter 1710460800)" 1 "quarter"
assert_eq "$(weekday_number 1710460800)" 5 "weekday_number (Friday, ISO)"
assert_fail is_weekend 1710460800
assert_ok is_weekend $(add_days 1 1710460800)
assert_eq "$(format_timestamp $(start_of_month 1710460800) %d)" 01 "start_of_month"

## durations
assert_eq "$(format_duration 93784)" "1d 2h 3m" "format_duration days"
assert_eq "$(format_duration 65)" "1m 5s" "format_duration minutes"
assert_rc 2 format_duration abc
