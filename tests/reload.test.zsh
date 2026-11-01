# Tests for reload_zconfig (lib/shell.zsh) and the reload step of zupdate
# Uses a throw-away lib/ and functions/ in a temp directory

local tmp=${TMPDIR:-/tmp}/zconfig-reload-test.$$
rm -rf $tmp && mkdir -p $tmp/lib $tmp/functions
local saved_lib_dir=$ZSH_LIB_DIR saved_funcs_dir=$ZSH_FUNCS_DIR
typeset -g ZSH_LIB_DIR=$tmp/lib ZSH_FUNCS_DIR=$tmp/functions
typeset -g ZSH_LOAD_LIB=1 ZSH_LOAD_USER_FUNCS=1 ZSH_AUTOCOMPILE=0
fpath=($tmp/functions $fpath)

## Invalid usage
assert_rc 2 reload_zconfig extra

## An already loaded autoloaded function gets its new body
print -r -- 'print v1' > $tmp/functions/rlfunc
autoload -Uz rlfunc
# $(...) runs in a subshell, so call each function once directly to load it here
rlfunc >/dev/null
assert_eq "$(rlfunc)" v1 "initial body"
print -r -- 'print v2' > $tmp/functions/rlfunc
assert_eq "$(rlfunc)" v1 "loaded function keeps old body without reload"
reload_zconfig -q
assert_eq "$(rlfunc)" v2 "function reloaded"

## New functions become available, private and hidden files are skipped
print -r -- 'print new' > $tmp/functions/rlnew
print -r -- 'print private' > $tmp/functions/_rlprivate
reload_zconfig -q
assert_eq "$(rlnew)" new "new function autoloaded"
assert_eq "${+functions[_rlprivate]}" 0 "private function not autoloaded"

## lib/ files are sourced again
print -r -- 'rl_lib() { print lib1 }' > $tmp/lib/rl.zsh
reload_zconfig -q
assert_eq "$(rl_lib)" lib1 "lib function defined"
print -r -- 'rl_lib() { print lib2 }' > $tmp/lib/rl.zsh
reload_zconfig -q
assert_eq "$(rl_lib)" lib2 "lib function redefined"

## Aliases do not expand in re-sourced definitions
alias -g RLG='| tr a-z A-Z'
print -r -- 'rl_alias() { print RLG }' > $tmp/lib/rl.zsh
reload_zconfig -q
assert_eq "$(rl_alias)" 'RLG' "global alias not expanded"
unalias 'RLG'

## A failing lib file is reported
print -r -- 'return 1' > $tmp/lib/zz-bad.zsh
assert_fail reload_zconfig -q
rm -f $tmp/lib/zz-bad.zsh

## Flags disable each part
rlfunc >/dev/null
typeset -g ZSH_LOAD_LIB=0 ZSH_LOAD_USER_FUNCS=0
print -r -- 'rl_lib() { print lib3 }' > $tmp/lib/rl.zsh
print -r -- 'print v3' > $tmp/functions/rlfunc
reload_zconfig -q
assert_eq "$(rl_lib)" lib2 "lib not reloaded when ZSH_LOAD_LIB=0"
assert_eq "$(rlfunc)" v2 "functions not reloaded when ZSH_LOAD_USER_FUNCS=0"
typeset -g ZSH_LOAD_LIB=1 ZSH_LOAD_USER_FUNCS=1

## The running function may reload itself and finishes with its old body
# The function rewrites its own file, then reloads from inside itself
print -rl -- 'print -r -- "print new" > $ZSH_FUNCS_DIR/rlself' 'reload_zconfig -q' 'print old' > $tmp/functions/rlself
autoload -Uz rlself
assert_eq "$(rlself; rlself)" $'old\nnew' "running function finishes, next call uses new body"

## zupdate reloads functions after pulling changes
if (( $+commands[git] )); then
    export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com
    export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com
    export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
    git init -q --bare -b main $tmp/remote.git
    git clone -q $tmp/remote.git $tmp/work 2>/dev/null
    git -C $tmp/work checkout -q -b main 2>/dev/null
    mkdir -p $tmp/work/functions $tmp/work/inc
    print -r -- 'print up1' > $tmp/work/functions/rlup
    print -r -- '# inc' > $tmp/work/inc/x.zsh
    git -C $tmp/work add -A && git -C $tmp/work commit -qm init
    git -C $tmp/work push -q origin main 2>/dev/null
    git clone -q $tmp/remote.git $tmp/zdot

    local saved_zdotdir=$ZDOTDIR
    typeset -g ZDOTDIR=$tmp/zdot ZSH_LIB_DIR=$tmp/zdot/lib ZSH_FUNCS_DIR=$tmp/zdot/functions
    fpath=($tmp/zdot/functions $fpath)
    autoload -Uz rlup
    rlup >/dev/null
    fpath=($saved_funcs_dir $fpath)
    autoload -Uz zupdate

    print -r -- 'print up2' > $tmp/work/functions/rlup
    print -r -- '# inc changed' > $tmp/work/inc/x.zsh
    git -C $tmp/work commit -qam change && git -C $tmp/work push -q origin main 2>/dev/null
    # Run in this shell (not in $(...)), so the reload affects it
    zupdate >$tmp/out 2>&1
    local out=$(<$tmp/out)
    assert_eq "$(rlup)" up2 "function reloaded after zupdate"
    assert_eq "${${out:#*Startup files changed: inc/x.zsh*}:-match}" match "startup file change reported"
    assert_eq "${${out:#*zconfig reloaded*}:-match}" match "reload reported"

    # Nothing pulled: no reload
    zupdate >$tmp/out 2>&1
    out=$(<$tmp/out)
    assert_eq "${${out:#*already up to date*}:-match}" match "already up to date reported"
    assert_eq "${(M)out:#*reloaded*}" "" "no reload when already up to date"

    # --no-reload keeps the loaded body
    print -r -- 'print up4' > $tmp/work/functions/rlup
    git -C $tmp/work commit -qam change2 && git -C $tmp/work push -q origin main 2>/dev/null
    rlup >/dev/null
    zupdate --no-reload >/dev/null 2>&1
    assert_eq "$(rlup)" up2 "--no-reload keeps the old body"

    typeset -g ZDOTDIR=$saved_zdotdir
fi

typeset -g ZSH_LIB_DIR=$saved_lib_dir ZSH_FUNCS_DIR=$saved_funcs_dir
rm -rf $tmp
