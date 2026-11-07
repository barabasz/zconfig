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

rm -rf $sandbox
