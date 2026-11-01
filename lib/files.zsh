#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# Filesystem helper functions
# Depends on: zsh/stat (zstat), math.zsh (format_bytes, used by format_size)
# Getters print the result and also set REPLY (use REPLY to avoid subshells)
##

## Type and permission checks

# Check if path exists and is a regular file
# Usage: is_file <path>
# Returns: 0 true, 1 false, 2 invalid usage
is_file() {
    (( ARGC == 1 )) || return 2
    [[ -f $1 ]]
}

# Check if path exists and is a directory
# Usage: is_dir <path>
# Returns: 0 true, 1 false, 2 invalid usage
is_dir() {
    (( ARGC == 1 )) || return 2
    [[ -d $1 ]]
}
# Alias: is_folder
functions[is_folder]=$functions[is_dir]

# Check if path is a symbolic link (also a broken one)
# Usage: is_link <path>
# Returns: 0 true, 1 false, 2 invalid usage
is_link() {
    (( ARGC == 1 )) || return 2
    [[ -L $1 ]]
}
# Alias: is_symlink
functions[is_symlink]=$functions[is_link]

# Check if file is a hard link (link count > 1)
# Usage: is_hardlink <file>
# Returns: 0 true, 1 false, 2 invalid usage
is_hardlink() {
    (( ARGC == 1 )) || return 2
    [[ -f $1 ]] || return 1
    local -a stats
    zstat -A stats +nlink -- "$1" 2>/dev/null || return 1
    (( stats[1] > 1 ))
}

# Check if file is executable
# Usage: is_executable <path>
# Returns: 0 true, 1 false, 2 invalid usage
is_executable() {
    (( ARGC == 1 )) || return 2
    [[ -x $1 ]]
}

# Check if file/dir is writable
# Usage: is_writable <path>
# Returns: 0 true, 1 false, 2 invalid usage
is_writable() {
    (( ARGC == 1 )) || return 2
    [[ -w $1 ]]
}

# Check if file/dir is readable
# Usage: is_readable <path>
# Returns: 0 true, 1 false, 2 invalid usage
is_readable() {
    (( ARGC == 1 )) || return 2
    [[ -r $1 ]]
}

# Check if directory is empty (hidden files count as content)
# Usage: is_empty_dir <dir>
# Returns: 0 true, 1 false (or not a directory), 2 invalid usage
is_empty_dir() {
    (( ARGC == 1 )) || return 2
    [[ -d $1 ]] || return 1
    # D: dotfiles, N: nullglob, [1]: stop after first match (fast)
    local -a files=("$1"/*(DN[1]))
    (( ${#files} == 0 ))
}

# Check if regular file is empty (size 0)
# Usage: is_empty_file <file>
# Returns: 0 true, 1 false (or not a regular file), 2 invalid usage
is_empty_file() {
    (( ARGC == 1 )) || return 2
    [[ -f $1 && ! -s $1 ]]
}

# Check if directory has at least one non-hidden entry
# Usage: has_visible_files <dir>
# Returns: 0 true, 1 false (or not a directory), 2 invalid usage
has_visible_files() {
    (( ARGC == 1 )) || return 2
    [[ -d $1 ]] || return 1
    local -a files=("$1"/*(N[1]))
    (( ${#files} > 0 ))
}

# Check if first file is newer than second (by modification time)
# Usage: is_newer <file1> <file2>
# Returns: 0 true (file1 newer, or file2 missing), 1 false, 2 invalid usage
is_newer() {
    (( ARGC == 2 )) || return 2
    [[ $1 -nt $2 ]]
}

# Check if two paths point to the same file (same device and inode)
# Usage: is_same_file <path1> <path2>
# Returns: 0 true, 1 false, 2 invalid usage
is_same_file() {
    (( ARGC == 2 )) || return 2
    [[ $1 -ef $2 ]]
}

## Statistics and info (zstat, no subshells)

# Get file size in bytes
# Usage: get_file_size <file>
# Output: size in bytes (stdout); also sets REPLY
# Returns: 0 success, 1 not a regular file, 2 invalid usage
get_file_size() {
    (( ARGC == 1 )) || return 2
    [[ -f $1 ]] || return 1
    local -a stats
    zstat -A stats +size -- "$1" 2>/dev/null || return 1
    REPLY=$stats[1]
    print -r -- "$REPLY"
}

# Get file permissions in octal format (special bits included when set)
# Usage: get_file_mode <path>
# Example: get_file_mode /etc/hosts -> 644, get_file_mode /usr/bin/sudo -> 4755
# Output: octal mode (stdout); also sets REPLY
# Returns: 0 success, 1 not found, 2 invalid usage
get_file_mode() {
    (( ARGC == 1 )) || return 2
    [[ -e $1 || -L $1 ]] || return 1
    local -a mode
    zstat -A mode +mode -- "$1" 2>/dev/null || return 1
    # Keep permission and special bits (setuid/setgid/sticky), drop file type
    local -i perm=$(( mode[1] & 8#7777 ))
    local oct=$(( [##8] perm ))
    # (l:3::0:) would truncate 4-digit modes, so pad only when shorter
    REPLY=$oct
    (( ${#oct} < 3 )) && REPLY=${(l:3::0:)oct}
    print -r -- "$REPLY"
}

# Get file owner (user name)
# Usage: get_file_owner <path>
# Output: user name (stdout); also sets REPLY
# Returns: 0 success, 1 not found, 2 invalid usage
get_file_owner() {
    (( ARGC == 1 )) || return 2
    [[ -e $1 || -L $1 ]] || return 1
    local -a stats
    # -s: return names instead of numeric ids
    zstat -s -A stats +uid -- "$1" 2>/dev/null || return 1
    REPLY=$stats[1]
    print -r -- "$REPLY"
}

# Get file group (group name)
# Usage: get_file_group <path>
# Output: group name (stdout); also sets REPLY
# Returns: 0 success, 1 not found, 2 invalid usage
get_file_group() {
    (( ARGC == 1 )) || return 2
    [[ -e $1 || -L $1 ]] || return 1
    local -a stats
    zstat -s -A stats +gid -- "$1" 2>/dev/null || return 1
    REPLY=$stats[1]
    print -r -- "$REPLY"
}

# Resolve symbolic link target, one level (readlink equivalent)
# Usage: resolve_link <symlink>
# Output: target path (stdout); also sets REPLY
# Returns: 0 success, 1 not a symlink, 2 invalid usage
resolve_link() {
    (( ARGC == 1 )) || return 2
    [[ -L $1 ]] || return 1
    local -a stats
    zstat -A stats +link -- "$1" 2>/dev/null || return 1
    REPLY=$stats[1]
    print -r -- "$REPLY"
}

# Get absolute path with all symlinks resolved (realpath equivalent)
# Usage: get_realpath <path>
# Output: absolute path (stdout); also sets REPLY
# Returns: 0 success, 1 not found, 2 invalid usage
get_realpath() {
    (( ARGC == 1 )) || return 2
    [[ -e $1 ]] || return 1
    REPLY=${1:A}
    print -r -- "$REPLY"
}

# Get modification time (epoch)
# Usage: get_file_mtime <path>
# Output: seconds since epoch (stdout); also sets REPLY
# Returns: 0 success, 1 not found, 2 invalid usage
get_file_mtime() {
    (( ARGC == 1 )) || return 2
    [[ -e $1 ]] || return 1
    local -a stats
    zstat -A stats +mtime -- "$1" 2>/dev/null || return 1
    REPLY=$stats[1]
    print -r -- "$REPLY"
}

# Get last access time (epoch)
# Usage: get_file_atime <path>
# Output: seconds since epoch (stdout); also sets REPLY
# Returns: 0 success, 1 not found, 2 invalid usage
get_file_atime() {
    (( ARGC == 1 )) || return 2
    [[ -e $1 ]] || return 1
    local -a stats
    zstat -A stats +atime -- "$1" 2>/dev/null || return 1
    REPLY=$stats[1]
    print -r -- "$REPLY"
}

# Get inode change time (epoch)
# Usage: get_file_ctime <path>
# Output: seconds since epoch (stdout); also sets REPLY
# Returns: 0 success, 1 not found, 2 invalid usage
get_file_ctime() {
    (( ARGC == 1 )) || return 2
    [[ -e $1 ]] || return 1
    local -a stats
    zstat -A stats +ctime -- "$1" 2>/dev/null || return 1
    REPLY=$stats[1]
    print -r -- "$REPLY"
}

# Get file age in seconds (time since last modification)
# Usage: file_age <path>
# Output: seconds (stdout); also sets REPLY
# Returns: 0 success, 1 not found, 2 invalid usage
file_age() {
    (( ARGC == 1 )) || return 2
    get_file_mtime "$1" >/dev/null || return
    REPLY=$(( EPOCHSECONDS - REPLY ))
    print -r -- "$REPLY"
}

## Path manipulation (wrappers around zsh modifiers)
# In loops use the modifiers directly (${var:t}), or REPLY instead of $(...)

# Get filename from path (basename equivalent)
# Usage: get_filename <path>
# Example: get_filename "/path/to/file.txt" -> file.txt
# Output: filename (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
get_filename() {
    (( ARGC == 1 )) || return 2
    REPLY="${1:t}"
    print -r -- "$REPLY"
}

# Get directory from path (dirname equivalent)
# Usage: get_dirname <path>
# Example: get_dirname "/path/to/file.txt" -> /path/to
# Output: directory (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
get_dirname() {
    (( ARGC == 1 )) || return 2
    REPLY="${1:h}"
    print -r -- "$REPLY"
}

# Get file extension (without dot)
# Usage: get_extension <path>
# Example: get_extension "image.jpg" -> jpg
# Output: extension (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
get_extension() {
    (( ARGC == 1 )) || return 2
    REPLY="${1:e}"
    print -r -- "$REPLY"
}

# Get filename without extension
# Usage: get_filename_no_ext <path>
# Example: get_filename_no_ext "/tmp/image.jpg" -> image
# Output: filename (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
get_filename_no_ext() {
    (( ARGC == 1 )) || return 2
    REPLY="${1:t:r}"
    print -r -- "$REPLY"
}

## Utilities

# Count regular files in directory (non-recursive)
# Usage: count_files [dir] [pattern]   (defaults: current dir, *)
# Output: number of files (stdout); also sets REPLY
# Returns: 0 success, 1 not a directory, 2 invalid usage
count_files() {
    (( ARGC <= 2 )) || return 2
    local dir=${1:-.}
    local pattern=${2:-*}
    [[ -d $dir ]] || return 1
    # (.): regular files only, (N): nullglob
    local -a files=($dir/$~pattern(N.))
    REPLY=${#files}
    print -r -- "$REPLY"
}

# Count directories in directory (non-recursive)
# Usage: count_dirs [dir] [pattern]   (defaults: current dir, *)
# Output: number of directories (stdout); also sets REPLY
# Returns: 0 success, 1 not a directory, 2 invalid usage
count_dirs() {
    (( ARGC <= 2 )) || return 2
    local dir=${1:-.}
    local pattern=${2:-*}
    [[ -d $dir ]] || return 1
    # (/): directories only, (N): nullglob
    local -a dirs=($dir/$~pattern(N/))
    REPLY=${#dirs}
    print -r -- "$REPLY"
}

# Create directory (with parents) and change into it
# Usage: mkcd <dir>
# Returns: 0 success, 1 mkdir/cd failure, 2 invalid usage
mkcd() {
    (( ARGC == 1 )) || return 2
    mkdir -p -- "$1" && cd -- "$1"
}

# Create a file and its parent directories if they don't exist
# Usage: mkfile <path>
# Returns: 0 success, 1 failure, 2 invalid usage
mkfile() {
    (( ARGC == 1 )) || return 2
    local dir=${1:h}
    [[ -d $dir ]] || mkdir -p -- "$dir" || return 1
    touch -- "$1"
}

# Format bytes into human readable size (alias for format_bytes, IEC units)
# Usage: format_size <bytes>
# Example: format_size 12345678 -> 11.77 MiB
# Output: formatted size (stdout); also sets REPLY
# Returns: 0 success, 2 invalid usage
format_size() {
    (( ARGC == 1 )) || return 2
    format_bytes "$1"
}

# Shell files tracking - keep at the end
zfile_track_end ${0:A}
