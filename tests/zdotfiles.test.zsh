# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Tests for functions/zdotfiles
# Runs with a throw-away HOME, a local repository and stubs of git and gh

if ! (( $+commands[git] )); then
    print -r -- "SKIP [$T_FILE] git not installed"
    return 0
fi

local sandbox=$(mktemp -d)
local origin=$sandbox/origin
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
git init -q $origin
print content > $origin/file
git -C $origin add -A
git -C $origin -c user.name=t -c user.email=t@t commit -qm init

fpath=($REPO_DIR/functions $fpath)
autoload -Uz zdotfiles
ZSH_APPS_DIR=$REPO_DIR/apps

# Usage: _dotfiles_run <home> <repo>
# Prints the resulting $GHCONFDIR, to check it reaches the calling shell
_dotfiles_run() {
    HOME=$1
    unset GHDIR GHCONFDIR
    zdotfiles $2 || return
    print -r -- "conf=$GHCONFDIR"
}

## A plain clone lands in ~/GitHub/config and sets $GHCONFDIR
local home=$sandbox/plain out
mkdir -p $home
out=$(_dotfiles_run $home $origin 2>&1)
assert_eq "$status" 0 "clone succeeds"
assert_eq "$(cat $home/GitHub/config/file)" "content" "repository is cloned"
assert_eq "${#${(@M)${(@f)out}:#conf=$home/GitHub/config}}" 1 "GHCONFDIR is set in this shell"

## An existing clone is left untouched
print local > $home/GitHub/config/mine
out=$(_dotfiles_run $home $sandbox/missing 2>&1)
assert_eq "$status" 0 "existing clone is not an error"
assert_eq "$(cat $home/GitHub/config/mine)" "local" "existing clone is kept"

## Something else in that place is never replaced
home=$sandbox/occupied
mkdir -p $home/GitHub/config
print local > $home/GitHub/config/mine
out=$(_dotfiles_run $home $origin 2>&1)
assert_eq "$status" 1 "plain directory is refused"
assert_eq "$(cat $home/GitHub/config/mine)" "local" "plain directory is kept"

## A failed clone outside GitHub reports an error and leaves nothing
home=$sandbox/failed
mkdir -p $home
out=$(_dotfiles_run $home $sandbox/missing 2>&1)
assert_eq "$status" 1 "failed clone is reported"
assert_fail test -e $home/GitHub/config

## A private GitHub repository falls back to gh, with a login if needed
local stubs=$sandbox/stubs log=$sandbox/log
mkdir -p $stubs
print -l '#!/bin/sh' "echo \"git \$*\" >> $log" 'exit 1' > $stubs/git
print -l '#!/bin/sh' "echo \"gh \$*\" >> $log" \
    'case "$1 $2" in' \
    '    "auth status") exit 1 ;;' \
    '    "repo clone") mkdir -p "$4/.git" ;;' \
    'esac' > $stubs/gh
chmod +x $stubs/git $stubs/gh
home=$sandbox/private
mkdir -p $home
out=$(PATH=$stubs:$PATH; _dotfiles_run $home owner/config 2>&1)
assert_eq "$status" 0 "clone through gh succeeds"
local -a calls=("${(@f)$(cat $log)}")
assert_eq "${calls[1]}" "git clone --quiet https://github.com/owner/config.git $home/GitHub/config" "shorthand becomes a URL"
assert_eq "${calls[3]}" "gh auth login --hostname github.com --git-protocol https --web" "gh logs in when needed"
assert_eq "${calls[4]}" "gh repo clone https://github.com/owner/config.git $home/GitHub/config" "gh repeats the clone"

## A failed login stops before cloning
print -l '#!/bin/sh' "echo \"gh \$*\" >> $log" 'exit 1' > $stubs/gh
rm -f $log
home=$sandbox/nologin
mkdir -p $home
out=$(PATH=$stubs:$PATH; _dotfiles_run $home owner/config 2>&1)
assert_eq "$status" 1 "failed login is reported"
assert_eq "${#${(@M)${(@f)$(cat $log)}:#gh repo clone*}}" 0 "no clone without a login"

unset GIT_CONFIG_GLOBAL GIT_CONFIG_NOSYSTEM
rm -rf $sandbox
