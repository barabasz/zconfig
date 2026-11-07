# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Regression tests for issues found in review (varia, compile, archive,
# hardware, plugins, fn)

local tmp=$(mktemp -d)

## source_zsh_dir follows symlinks to .zsh files
mkdir -p $tmp/src $tmp/real
print 'SRC_REAL=1' > $tmp/real/one.zsh
ln -s $tmp/real/one.zsh $tmp/src/linked.zsh
unset SRC_REAL
source_zsh_dir $tmp/src
assert_eq "${SRC_REAL:-}" 1 "symlinked file sourced"

## concatenate_zsh_dir keeps blank lines in here-documents, ignores here-strings
mkdir -p $tmp/cat
print -rl -- 'x=$(cat <<EOF' 'line1' '' 'line3' 'EOF' ')' '# comment' '' 'y=$(cat <<< word)' '# dropped' > $tmp/cat/a.zsh
concatenate_zsh_dir $tmp/cat $tmp/out.zsh >/dev/null
local -a got=("${(@f)$(<$tmp/out.zsh)}")
assert_eq "${got[(I)line1]}" "$(( ${got[(I)line3]} - 2 ))" "blank line inside here-document kept"
assert_eq "${got[(I)\# dropped]}" 0 "comment after here-string removed"

## clean_dir removes hidden .zwc files (e.g. .zshrc.zwc)
mkdir -p $tmp/zwc
: > $tmp/zwc/.zshrc.zwc
: > $tmp/zwc/a.zsh.zwc
clean_dir $tmp/zwc >/dev/null
local -a left=($tmp/zwc/*(ND))
assert_eq "${#left}" 0 "hidden .zwc removed"

## compress keeps the name of a symlinked source
mkdir -p $tmp/arch/target
print hi > $tmp/arch/target/f
ln -s $tmp/arch/target $tmp/arch/latest
( cd $tmp/arch && compress out latest >/dev/null )
local -a entries=("${(@f)$(tar -tzf $tmp/arch/out.tar.gz)}")
assert_eq "${#${(@)entries:#latest/*}}" 0 "archive entries use the symlink name"
assert_eq "$(( ${entries[(Ie)latest/f]} > 0 ))" 1 "archive contains latest/f"
mkdir -p $tmp/arch/y && tar -xzf $tmp/arch/out.tar.gz -C $tmp/arch/y
assert_fail test -L $tmp/arch/y/latest
assert_eq "$(<$tmp/arch/y/latest/f)" hi "top-level directory symlink is followed"
ln -s $tmp/arch/target/f $tmp/arch/flink
( cd $tmp/arch && compress out2 flink >/dev/null )
mkdir -p $tmp/arch/x && tar -xzf $tmp/arch/out2.tar.gz -C $tmp/arch/x
assert_fail test -L $tmp/arch/x/flink
assert_eq "$(<$tmp/arch/x/flink)" hi "top-level file symlink stores contents"

## _df_fields: mount points and file systems with spaces
mkdir -p $tmp/bin
print -rl -- '#!/bin/sh' 'echo "Filesystem 1024-blocks Used Available Capacity Mounted on"' \
    'echo "/dev/disk4s1 1000 400 600 40% /Volumes/My Disk"' > $tmp/bin/df
chmod +x $tmp/bin/df
path=($tmp/bin $path)
_df_fields /x
assert_eq "${reply[*]}" "1024000 409600 614400" "mount point with spaces"
print -rl -- '#!/bin/sh' 'echo "Filesystem 1024-blocks Used Available Capacity Mounted on"' \
    'echo "map auto home 10 4 6 40% /home"' > $tmp/bin/df
_df_fields /x
assert_eq "${reply[*]}" "10240 4096 6144" "file system name with spaces"
print -rl -- '#!/bin/sh' 'echo "Filesystem 1024-blocks Used Available Capacity Mounted on"' \
    'echo "/dev/disk5 1000 400 600 40% /Volumes/Backup 100%"' > $tmp/bin/df
_df_fields /x
assert_eq "${reply[*]}" "1024000 409600 614400" "percent sign inside mount point"
print -rl -- '#!/bin/sh' 'echo "Filesystem 1024-blocks Used Available Capacity Mounted on"' \
    'echo "devfs 0 0 0 - /dev"' > $tmp/bin/df
_df_fields /x
assert_eq "${reply[*]}" "0 0 0" "capacity reported as -"
print -rl -- '#!/bin/sh' 'echo "Filesystem 1024-blocks Used Available Capacity Mounted on"' \
    'echo "/dev/sda1 100 105 -5 105% /"' > $tmp/bin/df
_df_fields /x
assert_eq "${reply[*]}" "102400 107520 -5120" "negative available blocks"
path=(${path:#$tmp/bin})

## reinstall_plugin keeps a pinned tag
if (( ${+commands[git]} )); then
    local repo=$tmp/plugrepo
    git init -q $repo
    print 'V=1' > $repo/p.plugin.zsh
    git -C $repo add . && git -C $repo -c user.email=t@t -c user.name=t commit -qm one && git -C $repo tag v1
    print 'V=2' > $repo/p.plugin.zsh
    git -C $repo -c user.email=t@t -c user.name=t commit -qam two
    ZSH_PLUGINS_DIR=$tmp/plugins
    mkdir -p $ZSH_PLUGINS_DIR
    install_plugin -b v1 demo file://$repo >/dev/null 2>&1
    reinstall_plugin demo >/dev/null 2>&1
    assert_eq "$(git -C $ZSH_PLUGINS_DIR/demo describe --tags --exact-match HEAD 2>/dev/null)" v1 "tag kept after reinstall"
    reinstall_plugin demo >/dev/null 2>&1
    install_plugin demo2 file://$repo >/dev/null 2>&1
    reinstall_plugin demo2 >/dev/null 2>&1
    assert_eq "$(<$ZSH_PLUGINS_DIR/demo2/p.plugin.zsh)" "V=2" "default branch reinstall"
    # A branch tip that also has a tag stays on the branch
    git -C $repo tag v2
    install_plugin demo3 file://$repo >/dev/null 2>&1
    reinstall_plugin demo3 >/dev/null 2>&1
    assert_ok git -C $ZSH_PLUGINS_DIR/demo3 symbolic-ref -q HEAD
fi

## _fn_init accepts negative floats such as -.5 as positional values
fnneg() {
    local -A _fn=([info]="test")
    local -a _fn_args=("value|A number|r|float") _fn_opts=() _fn_commands=() _fn_examples=()
    local -A opts=() args=()
    _fn_init "$@" || return $REPLY
    print -r -- "${args[value]}"
}
assert_eq "$(fnneg -.5 2>&1)" -.5 "-.5 is a value"
assert_eq "$(fnneg -1.5 2>&1)" -1.5 "-1.5 is a value"

command rm -rf -- $tmp

## printc interprets escapes like print (zgit/zhelp pass "\n..."); lib refactor made it print -r
assert_eq "$(printc 'a\nb')" $'a\nb' "printc: \\n is a newline"
assert_eq "$(printkv 'k' 'a\tb')" $'k: a\tb' "printkv interprets escapes"
ICO_UL='\u2022'
assert_eq "$(printul 'a\u2022')" " • a•" "printul interprets escapes (item and bullet)"
assert_eq "${$(printh 'a\u2022')%%$'\n'*}" "a•" "printh interprets escapes"
assert_eq "${${(f)$(printt 'a\u2022')}[2]}" "│ a• │" "printt interprets escapes"

## functions/ must not declare locals that shadow zsh special hashes
## (zhelp had `local -A commands`, which hid $commands from is_installed/get_local_ip)
local -a shadow=()
local fnfile
for fnfile in $REPO_DIR/functions/*(.); do
    shadow+=(${(M)${(f)"$(<$fnfile)"}:#[[:space:]]#(local|typeset)*[[:space:]](commands|functions|aliases|options|parameters|builtins|modules)([[:space:]=]*|)})
done
assert_eq "${(j:|:)shadow}" "" "no local commands/functions/... in functions/"

## rmln

# A local variable named path used to empty PATH, so rm was not found
fpath=($REPO_DIR/functions $fpath)
autoload -Uz rmln
local rmln_dir=$(mktemp -d)
ln -s /etc/hosts $rmln_dir/link
assert_ok rmln $rmln_dir/link
assert_eq "$(print -r -- $rmln_dir/link(N@))" "" "rmln removes the symlink"
rm -rf $rmln_dir

## Test runner

# Exported colors from inc/colors.zsh must not leak into tests
assert_eq "$r$g$y$b$p$c$w$x" "" "color variables are empty in tests"
