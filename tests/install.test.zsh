# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Tests for replacing an existing installation in install.sh
# Runs the real functions in bash, with a throw-away HOME and a local repository

local sandbox=$(mktemp -d)
local origin=$sandbox/origin
git init -q $origin
print new > $origin/.zshenv
git -C $origin add -A
git -C $origin -c user.name=t -c user.email=t@t commit -qm init

# The functions under test, taken from the real installer
local install_funcs=$(sed -n -e '/^clone_repository() {/,/^}/p' -e '/^activate_repository() {/,/^}/p' \
                             -e '/^handle_existing() {/,/^}/p' $REPO_DIR/install.sh)

# Usage: _install_run <repo> <answer to the confirmation>
# Runs from inside the installation directory, like `bash ./install.sh` there
_install_run() {
    local home=$sandbox/home
    rm -rf $home
    mkdir -p $home/.config/zsh
    print old > $home/.config/zsh/.zshenv
    print history > $home/.config/zsh/.zsh_history
    ln -s $home/.config/zsh/.zshenv $home/.zshenv
    ( cd $home/.config/zsh && HOME=$home REPO=$1 ANSWER=$2 FUNCS=$install_funcs bash -c '
        eval "$FUNCS"
        print_header() { :; }; print_success() { :; }; print_info() { :; }
        print_warning() { :; }; print_error() { :; }
        spin() { shift; "$@"; }
        confirm_no() { [[ $ANSWER == yes ]]; }
        ZCONFIG_DIR=$HOME/.config/zsh ZCONFIG_STAGING=$HOME/.config/zsh.new
        ZSHENV_LINK=$HOME/.zshenv ZCONFIG_REPO=$REPO
        cd "$HOME" || exit 1
        clone_repository && handle_existing && activate_repository
    ' ) >/dev/null 2>&1
}

## A failed clone leaves the existing installation untouched
_install_run $sandbox/missing no
assert_eq "$status" 1 "failed clone is reported"
assert_eq "$(cat $sandbox/home/.config/zsh/.zshenv)" "old" "failed clone keeps the installation"
assert_ok test -L $sandbox/home/.zshenv
assert_fail test -e $sandbox/home/.config/zsh.new

## A successful clone replaces the installation and keeps the history
_install_run $origin no
assert_eq "$status" 0 "replacing the installation succeeds"
assert_eq "$(cat $sandbox/home/.config/zsh/.zshenv)" "new" "installation is replaced"
assert_eq "$(cat $sandbox/home/.config/zsh/.zsh_history)" "history" "history is kept"
assert_fail test -e $sandbox/home/.config/zsh.new

## A backup keeps the old installation aside
_install_run $origin yes
assert_eq "$(cat $sandbox/home/.config/zsh/.zshenv)" "new" "installation is replaced after backup"
local -a backups=($sandbox/home/.config/zsh.bak.*(N/))
assert_eq "${#backups}" 1 "backup is created"

## dasel reports its version through a subcommand only
local stubs=$sandbox/stubs
mkdir -p $stubs
print -l '#!/bin/sh' '[ "$1" = version ] && echo 3.11.2 || exit 80' > $stubs/dasel
chmod +x $stubs/dasel
local version_funcs=$(sed -n -e '/^cmd_exists() {/,/^}/p' -e '/^get_version() {/,/^}/p' $REPO_DIR/install.sh)
assert_eq "$(PATH=$stubs:$PATH FUNCS=$version_funcs bash -c 'eval "$FUNCS"; get_version dasel')" "3.11.2" "dasel version"

## The timezone is optional: a default, an override, or none at all
local timezone_code=$(sed -n -e '/^ZCONFIG_TIMEZONE=/p' -e '/^configure_timezone() {/,/^}/p' $REPO_DIR/install.sh)

# Usage: _timezone_run [VAR=value]
# Prints the arguments of the privileged call, if there is one
_timezone_run() {
    env -u ZCONFIG_TIMEZONE "$@" FUNCS=$timezone_code bash -c '
        eval "$FUNCS"
        print_info() { :; }; print_warning() { :; }
        do_sudo() { echo "$*"; }
        configure_timezone
    '
}
assert_eq "$(_timezone_run)" "timedatectl set-timezone Europe/Warsaw" "default timezone"
assert_eq "$(_timezone_run ZCONFIG_TIMEZONE=Asia/Tokyo)" "timedatectl set-timezone Asia/Tokyo" "chosen timezone"
assert_eq "$(_timezone_run ZCONFIG_TIMEZONE=)" "" "empty value keeps the system timezone"

## The locale is checked before anything is installed
local locale_code=$(sed -n -e '/^DEFAULT_LOCALE=/p' -e '/^ZCONFIG_LOCALE=/p' -e '/^check_locale() {/,/^}/p' \
                           -e '/^save_locale() {/,/^}/p' $REPO_DIR/install.sh)

# Usage: _locale_run <function> [VAR=value]
_locale_run() {
    env -u ZCONFIG_LOCALE "${@:2}" HOME=$sandbox/locale FUNCS=$locale_code FN=$1 bash -c '
        eval "$FUNCS"
        print_info() { :; }; print_warning() { :; }; print_error() { :; }
        ZCONFIG_DIR=$HOME
        $FN
    ' >/dev/null 2>&1
}
mkdir -p $sandbox/locale
assert_ok _locale_run check_locale
assert_ok _locale_run check_locale ZCONFIG_LOCALE=de_DE.UTF-8
assert_fail _locale_run check_locale ZCONFIG_LOCALE=de_DE
assert_fail _locale_run check_locale 'ZCONFIG_LOCALE=de_DE.UTF-8/; rm -rf x'

## Only a non-default locale is saved, and later shells read it
_locale_run save_locale
assert_fail test -e $sandbox/locale/local.zsh
_locale_run save_locale ZCONFIG_LOCALE=de_DE.UTF-8
mkdir -p $sandbox/shell/.config/zsh $sandbox/shell-default $sandbox/stubs-sudo
mv $sandbox/locale/local.zsh $sandbox/shell/.config/zsh/
# No passwordless sudo here, so that inc/locales.zsh leaves the system alone
print -l '#!/bin/sh' 'exit 1' > $sandbox/stubs-sudo/sudo
chmod +x $sandbox/stubs-sudo/sudo

# Usage: _locale_shell <home>
_locale_shell() {
    env -u ZSH_LOCALE -u ZDOTDIR HOME=$1 PATH=$sandbox/stubs-sudo:$PATH INC=$REPO_DIR/inc zsh -fc '
        source $INC/zfiles.zsh; source $INC/env.zsh; source $INC/locales.zsh
        print -r -- "$LC_TIME $LC_MESSAGES"
    '
}
assert_eq "$(_locale_shell $sandbox/shell)" "de_DE.UTF-8 en_US.UTF-8" "saved locale reaches the shell"
assert_eq "$(_locale_shell $sandbox/shell-default)" "pl_PL.UTF-8 en_US.UTF-8" "default locale"

## A failed su explains that the root account may have no password
local bootstrap_code=$(sed -n '/^bootstrap_sudo() {/,/^}/p' $REPO_DIR/install.sh)

# Usage: _bootstrap_run <message of su>
_bootstrap_run() {
    : > $sandbox/bootstrap.log
    env MSG=$1 FUNCS=$bootstrap_code DEBUGLOG=$sandbox/bootstrap.log bash -c '
        eval "$FUNCS"
        print_info() { printf "info: %s\n" "$1"; }; print_error() { :; }; print_log() { :; }
        su() { printf "%s\n" "$MSG" >&2; return 1; }
        g= x=
        bootstrap_sudo
    ' 2>/dev/null
}
out=$(_bootstrap_run "su: Authentication failure")
assert_eq "${#${(@M)${(@f)out}:#info: The root account may have no password*}}" 1 "root password hint"
assert_eq "${#${(@M)${(@f)out}:#info:   sudo usermod -aG sudo *}}" 1 "usermod hint"
out=$(_bootstrap_run "visudo: syntax error")
assert_eq "${#${(@M)${(@f)out}:#info: The root account*}}" 0 "no root hint for other errors"

## The clock is synchronized again instead of trusting a stale status
local clock_code=$(sed -n -e '/^sync_clock() {/,/^}/p' -e '/^clock_resync() {/,/^}/p' -e '/^uptime_seconds() {/,/^}/p' \
                          -e '/^explain_apt_error() {/,/^}/p' $REPO_DIR/install.sh)

# Usage: _clock_run <function> [VAR=value]...
# Stubs print every privileged call and every message, one per line
_clock_run() {
    env "${@:2}" FUNCS=$clock_code FN=$1 DEBUGLOG=$sandbox/clock.log bash -c '
        eval "$FUNCS"
        print_info() { echo "info: $1"; }; print_warning() { echo "warning: $1"; }
        spin() { shift; "$@"; }
        do_sudo() { echo "run: $*"; }
        systemctl() { [[ "$3" == "$ACTIVE" ]]; }
        chronyc() { echo "run: chronyc $*"; [[ -z "$CHRONY_FAIL" ]]; }
        timedatectl() { echo "{ Leap=0 }"; }
        c= g= x=
        $FN
    ' 2>&1
}

# Usage: _has_line <text> <line>
_has_line() { (( ${${(@f)1}[(Ie)$2]} )) }

out=$(_clock_run sync_clock ACTIVE=chrony)
assert_ok _has_line "$out" "run: timedatectl set-ntp true"
assert_ok _has_line "$out" "run: systemctl restart chrony"
assert_ok _has_line "$out" "run: chronyc waitsync 30 1 0 1"
assert_ok _has_line "$out" "info: System clock is synchronized"
out=$(_clock_run sync_clock ACTIVE=systemd-timesyncd)
assert_ok _has_line "$out" "run: systemctl restart systemd-timesyncd"
assert_ok _has_line "$out" "info: System clock is synchronized"
out=$(_clock_run sync_clock ACTIVE=chrony CHRONY_FAIL=1)
assert_ok _has_line "$out" "warning: Could not confirm clock synchronization (see $sandbox/clock.log)"
out=$(_clock_run sync_clock ACTIVE=none)
assert_eq "${#${(@M)${(@f)out}:#warning: Neither chrony*}}" 1 "no NTP service is reported"
assert_eq "${#${(@M)${(@f)out}:#run: systemctl restart*}}" 0 "nothing is restarted without an NTP service"

## A clock step is reported and kept out of the elapsed time
out=$(env FUNCS=$clock_code bash -c '
    eval "$FUNCS"
    print_info() { echo "info: $1"; }; print_warning() { :; }; do_sudo() { :; }
    systemctl() { [[ "$3" == chrony ]]; }
    spin() { shift; "$@"; }
    NOW=1000 START_TIME=5
    date() { echo $NOW; }
    uptime_seconds() { echo 50; }
    clock_resync() { NOW=$((NOW + 3600)); }
    c= x=
    sync_clock
    printf "start: %s\n" "$START_TIME"
' 2>&1)
assert_ok _has_line "$out" "info: System clock corrected by 3600s"
assert_ok _has_line "$out" "start: 3605"
assert_eq "$(bash -c "$(sed -n '/^uptime_seconds() {/,/^}/p' $REPO_DIR/install.sh); [[ -r /proc/uptime ]] || exit 0; uptime_seconds" | tr -d '0-9')" "" "uptime is whole seconds"

## A failed package list update explains a clock that is behind
print "E: Release file for http://example/InRelease is not valid yet (invalid for another 1h)." > $sandbox/clock.log
assert_eq "${#${(@M)${(@f)$(_clock_run explain_apt_error)}:#warning: The system clock is behind*}}" 1 "clock hint"
print "E: Failed to fetch http://example/InRelease" > $sandbox/clock.log
assert_eq "$(_clock_run explain_apt_error)" "" "no clock hint for other errors"
print -l "E: Could not get lock /var/lib/apt/lists/lock. It is held by process 1 (apt-get)" "█ Command FAILED" > $sandbox/clock.log
assert_eq "${#${(@M)${(@f)$(_clock_run explain_apt_error)}:#warning: Another apt process*}}" 1 "lock hint"

## apt waits for a lock held by another apt, but not for other errors
local apt_code=$(sed -n '/^apt_run() {/,/^}/p' $REPO_DIR/install.sh)

# Usage: _apt_run <attempts that find the lock taken> [<exit code after them>]
# Prints the exit code and the number of attempts
_apt_run() {
    : > $sandbox/apt.log
    env LOCKED=$1 RC=${2:-0} FUNCS=$apt_code DEBUGLOG=$sandbox/apt.log bash -c '
        eval "$FUNCS"
        print_log() { :; }; sleep() { :; }
        calls=0
        do_sudo() {
            calls=$((calls + 1))
            if (( calls <= LOCKED )); then
                printf "%s\n" "E: Could not get lock /var/lib/apt/lists/lock" >> "$DEBUGLOG"
                return 100
            fi
            (( RC )) && printf "%s\n" "E: Some other error" >> "$DEBUGLOG"
            return "$RC"
        }
        apt_run update
        printf "%s %s\n" "${PIPESTATUS[0]}" "$calls"
    '
}
assert_eq "$(_apt_run 0)" "0 1" "apt without a lock"
assert_eq "$(_apt_run 3)" "0 4" "apt waits for the lock"
assert_eq "$(_apt_run 0 100)" "100 1" "other apt errors are not retried"
assert_eq "$(_apt_run 2 100)" "100 3" "an error after the lock is not retried"
assert_eq "$(_apt_run 99)" "100 60" "apt gives up after 60 attempts"

rm -rf $sandbox
