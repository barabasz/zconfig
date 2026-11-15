# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Tests for race_first in lib/varia.zsh; the raced commands are local fakes,
# so no network is needed

local tmp=$(mktemp -d)
local -F start

## The fastest command wins and the slower one is killed
start=$EPOCHREALTIME
race_first -t 3 "slow|zsh -fc 'sleep 1; touch $tmp/slow; print slow'" \
    "fast|zsh -fc 'sleep 0.1; print fast'" >/dev/null
assert_eq "$status" 0 "race_first: success"
assert_eq "$REPLY" fast "race_first: fastest value"
assert_eq "${reply[*]}" "fast fast" "race_first: reply has value and label"
assert_eq $(( EPOCHREALTIME - start < 0.8 )) 1 "race_first: done in under 0.8 s"
sleep 1.2
assert_fail test -e $tmp/slow

## A filter rejects lines and normalizes the accepted value
_race_digits() { [[ ${1#v=} == <-> ]] && REPLY=${1#v=} }
race_first -f _race_digits "junk|zsh -fc 'print junk'" \
    "num|zsh -fc 'sleep 0.2; print v=42'" >/dev/null
assert_eq "${reply[*]}" "42 num" "race_first: filter skips junk and sets value"

## A last line without a newline is accepted
race_first "a|zsh -fc 'print -n 7'" >/dev/null
assert_eq "$REPLY" 7 "race_first: line without newline"

## A missing command fails quietly and does not stop the race
assert_eq "$(race_first "x|no_such_command_zconfig" "ok|zsh -fc 'sleep 0.1; print ok'" 2>&1)" ok \
    "race_first: missing command is ignored"

## Nothing accepted: 1 at the timeout, or as soon as all commands end
start=$EPOCHREALTIME
assert_fail race_first -t 0.3 "a|sleep 5"
assert_eq $(( EPOCHREALTIME - start < 1 )) 1 "race_first: done in under 1 s"
start=$EPOCHREALTIME
assert_fail race_first -t 5 "a|true" "b|false"
assert_eq $(( EPOCHREALTIME - start < 1 )) 1 "race_first: done in under 1 s"
assert_eq "${REPLY}|${#reply}" "|0" "race_first: empty REPLY and reply on failure"

## Invalid usage
assert_rc 2 race_first
assert_rc 2 race_first -t abc "a|true"
assert_rc 2 race_first -t 0 "a|true"
assert_rc 2 race_first -f no_such_filter "a|true"

command rm -rf -- $tmp
