#!/usr/bin/env zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Minimal test runner for lib/ (no external framework)
# Usage: zsh tests/run.zsh [pattern]   e.g. zsh tests/run.zsh math
# Each tests/*.test.zsh file is sourced in a clean `zsh -f` with all lib/ files
# loaded. Assertions: assert_eq, assert_ok, assert_fail, assert_rc.

typeset -g TESTS_DIR=${${(%):-%x}:A:h}
typeset -g REPO_DIR=${TESTS_DIR:h}
typeset -gi T_PASS=0 T_FAIL=0
typeset -g T_FILE=""

## Assertions

# Compare two strings
# Usage: assert_eq <actual> <expected> [description]
assert_eq() {
    if [[ $1 == "$2" ]]; then
        (( T_PASS++ ))
    else
        (( T_FAIL++ ))
        print -r -- "FAIL [$T_FILE] ${3:-assert_eq}: expected '${2}', got '${1}'"
    fi
    # Always 0, so the status of a test file reflects only real errors
    return 0
}

# Check exit status of a command
# Usage: assert_rc <expected_rc> <command> [args...]
assert_rc() {
    local -i expected=$1
    shift
    "$@" >/dev/null 2>&1
    local -i rc=$status
    if (( rc == expected )); then
        (( T_PASS++ ))
    else
        (( T_FAIL++ ))
        print -r -- "FAIL [$T_FILE] $*: expected rc=$expected, got rc=$rc"
    fi
    return 0
}

# Shorthands for rc 0 and rc 1
assert_ok()   { assert_rc 0 "$@" }
assert_fail() { assert_rc 1 "$@" }

## Environment

# Load all lib/ files the same way .zshrc does (alphabetical order)
_tests_load_lib() {
    zfile_track_start() { : }
    zfile_track_end() { : }
    zmodload zsh/datetime zsh/mathfunc zsh/net/tcp zsh/parameter zsh/regex \
             zsh/system zsh/terminfo zsh/zselect
    zmodload -F zsh/stat b:zstat
    zmodload zsh/random 2>/dev/null
    typeset -g ZDOTDIR=$REPO_DIR ZSH_DEBUG=0
    typeset -g ZSH_LIB_DIR=$REPO_DIR/lib ZSH_FUNCS_DIR=$REPO_DIR/functions
    # Color variables used by print.zsh are empty, so output is plain text;
    # explicit assignment, because a bare typeset keeps values inherited from
    # the environment (inc/colors.zsh exports them)
    typeset -g r= g= y= b= p= c= w= x=
    local file
    for file in $ZSH_LIB_DIR/*.zsh(N.on); do
        if ! source $file; then
            print -r -- "FAIL [lib] error loading ${file:t}"
            (( T_FAIL++ ))
        fi
    done
}

## Main

# Sourced by a test shell: only provide assertions and load the library
if [[ ${1:-} == --lib-only ]]; then
    _tests_load_lib
    return 0
fi

local pattern=${1:-}
local -a files=($TESTS_DIR/*${pattern}*.test.zsh(N.on))
(( ${#files} )) || { print "No test files found."; exit 2 }

# A UTF-8 locale is needed for multibyte tests; macOS has no C.UTF-8
local test_locale=C.UTF-8
[[ $OSTYPE == darwin* ]] && test_locale=en_US.UTF-8

local file out
local -i total_fail=0 total_pass=0
for file in $files; do
    # Each file runs in its own clean shell, so tests cannot affect each other
    out=$(LANG=$test_locale LC_ALL=$test_locale TZ=UTC zsh -f -c "
        source ${(q)TESTS_DIR}/run.zsh --lib-only
        T_FILE=${(q)file:t}
        # A test file that stops early (syntax error, failed command at the end)
        # counts as a failure even if all assertions run so far passed
        if ! source ${(q)file}; then
            print -r -- \"FAIL [\$T_FILE] test file returned non-zero or aborted\"
            (( T_FAIL++ ))
        fi
        print -r -- \"__RESULT__ \$T_PASS \$T_FAIL\"
    " 2>&1)
    local -a lines=("${(@f)out}")
    local -a results=(${(M)lines:#__RESULT__*})
    local result=${results[-1]:-}
    # Print failures and other output (everything except the result line)
    lines=(${lines:#__RESULT__*})
    (( ${#lines} )) && print -rl -- $lines
    if [[ -z $result ]]; then
        print -r -- "FAIL [${file:t}] did not finish"
        (( total_fail++ ))
        continue
    fi
    local -a counts=(${=result#__RESULT__ })
    (( total_pass += counts[1], total_fail += counts[2] ))
    printf '%-28s %4d passed, %d failed\n' "${file:t}" $counts[1] $counts[2]
done

print -r -- "----"
print -r -- "Total: $total_pass passed, $total_fail failed"
(( total_fail == 0 ))
