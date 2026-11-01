# Tests for lib/files.zsh and lib/path.zsh

local tmp=$(mktemp -d)
print -n x > $tmp/one
: > $tmp/empty
ln -s $tmp/one $tmp/link
mkdir $tmp/dir

## files
assert_ok is_file $tmp/one
assert_ok is_dir $tmp/dir
assert_ok is_link $tmp/link
assert_ok is_empty_file $tmp/empty
assert_fail is_empty_file $tmp/one
assert_ok is_empty_dir $tmp/dir
assert_ok is_same_file $tmp/link $tmp/one
assert_eq "$(get_file_size $tmp/one)" 1 "get_file_size"
assert_eq "$(get_extension archive.tar.gz)" gz "get_extension"
assert_eq "$(get_filename_no_ext /a/b/report.pdf)" report "get_filename_no_ext"
assert_rc 2 get_file_size

## get_file_mode keeps special bits (audit bug #22)
chmod 4755 $tmp/one
assert_eq "$(get_file_mode $tmp/one)" 4755 "setuid bit"
chmod 600 $tmp/one
assert_eq "$(get_file_mode $tmp/one)" 600 "plain mode"

## path arrays
path=(/usr/bin /bin)
path_prepend /bin/
assert_eq "${path[*]}" "/bin /usr/bin" "prepend moves existing entry, trims slash"
path_append /usr/bin
assert_eq "${path[*]}" "/bin /usr/bin" "append keeps unique"
assert_fail path_append $tmp/nonexistent
path_remove /bin
assert_eq "${path[*]}" "/usr/bin" "remove"
fpath_append $tmp/dir
assert_eq "${fpath[-1]}" "$tmp/dir" "fpath_append"
assert_rc 2 path_print nosuch

command rm -r -- $tmp
