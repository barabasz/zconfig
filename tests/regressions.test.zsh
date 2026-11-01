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
assert_eq "$(tar -tzf $tmp/arch/out.tar.gz | head -1)" latest "archive entry uses the symlink name"

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
