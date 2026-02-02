#!/bin/zsh
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# Filesystem related functions
# zsh-specific functions - requires zsh, will not work in bash
# Uses built-in zsh/stat module as `zstat` command

# Check if path exists and is a regular file
# Usage: is_file "/path/to/file"
# Returns: 0 (true), 1 (false), 2 (invalid usage)
is_file() {
    (( ARGC == 1 )) || return 2
    [[ -f $1 ]]
}

# Check if path exists and is a directory
# Usage: is_dir "/path/to/dir"
# Returns: 0 (true), 1 (false), 2 (invalid usage)
is_dir() {
    (( ARGC == 1 )) || return 2
    [[ -d $1 ]]
}
functions[is_folder]=$functions[is_dir]

# Check if path exists and is a symbolic link
# Usage: is_link "/path/to/symlink"
# Returns: 0 (true), 1 (false), 2 (invalid usage)
is_link() {
    (( ARGC == 1 )) || return 2
    [[ -L $1 ]]
}
functions[is_symlink]=$functions[is_link]

# Check if file is a hard link (has link count > 1)
# Uses built-in zstat with array storage to avoid subshells
# Usage: is_hardlink "/path/to/file"
# Returns: 0 (true), 1 (false), 2 (invalid usage)
is_hardlink() {
    (( ARGC == 1 )) || return 2
    [[ -f $1 ]] || return 1

    local -a stats
    # -A: load into array, +nlink: get hardlink count
    zstat -A stats +nlink "$1" 2>/dev/null || return 1

    (( stats[1] > 1 ))
}

# Check if file is executable
# Usage: is_executable "/path/to/file"
# Returns: 0 (true), 1 (false), 2 (invalid usage)
is_executable() {
    (( ARGC == 1 )) || return 2
    [[ -x $1 ]]
}

# Check if file/dir is writable
# Usage: is_writable "/path/to/file"
# Returns: 0 (true), 1 (false), 2 (invalid usage)
is_writable() {
    (( ARGC == 1 )) || return 2
    [[ -w $1 ]]
}

# Check if file/dir is readable
# Usage: is_readable "/path/to/file"
# Returns: 0 (true), 1 (false), 2 (invalid usage)
is_readable() {
    (( ARGC == 1 )) || return 2
    [[ -r $1 ]]
}

# Check if directory is empty
# Usage: is_empty_dir "/path/to/dir"
# Returns: 0 (true), 1 (false), 2 (invalid usage)
is_empty_dir() {
    (( ARGC == 1 )) || return 2
    [[ -d $1 ]] || return 1
    # Check if there is at least one file inside
    # Uses Zsh glob qualifiers: D (dotfiles), N (nullglob), [1] (stop after 1 match)
    # This is extremely fast as it stops scanning immediately upon finding anything
    local -a files=("$1"/*(DN[1]))
    (( ${#files} == 0 ))
}

# Check if directory has at least one non-hidden file
# Usage: has_visible_files "/path/to/dir"
# Returns: 0 (true), 1 (false), 2 (invalid usage)
has_visible_files() {
    (( ARGC == 1 )) || return 2
    [[ -d $1 ]] || return 1
    # Uses N (nullglob), [1] (stop after 1 match) - no D flag = excludes dotfiles
    local -a files=("$1"/*(N[1]))
    (( ${#files} > 0 ))
}

# --- Statistics & Info (No Subshells) ---

# Get file size in bytes
# Usage: get_file_size "file.txt"
# Returns: file size in bytes (e.g., 1024)
get_file_size() {
    (( ARGC == 1 )) || return 2
    [[ -f $1 ]] || return 1
    local -a stats
    zstat -A stats +size "$1" 2>/dev/null && print -- $stats[1]
}

# Get file permissions in octal format
# Usage: get_file_mode "file.txt"
# Returns: 644, 755, etc.
get_file_mode() {
    (( ARGC == 1 )) || return 2
    [[ -e $1 ]] || return 1
    local mode
    # -o flag outputs octal format (0100644), extract last 3 digits
    zstat -o -A mode +mode "$1" 2>/dev/null && print -- ${mode[1]: -3}
}

# Get file owner name
# Usage: get_file_owner "file.txt"
# Returns: user name
get_file_owner() {
    (( ARGC == 1 )) || return 2
    [[ -e $1 ]] || return 1
    local -a stats
    # +uid is numeric, but we want name. zstat doesn't resolve names by default easily via +flags alone
    # in pure zstat without external 'id' command, sticking to ls -ld or zstat +uid is safer.
    # However, zsh/stat can return user name if configured, but typically returns uid.
    # Let's return UID to be safe and pure, or use stat's string output mode.
    zstat -s +uid "$1" 2>/dev/null
}

# Resolve symbolic link target (readlink equivalent)
# Usage: resolve_link "symlink"
# Returns: target path
resolve_link() {
    (( ARGC == 1 )) || return 2
    [[ -L $1 ]] || return 1
    local -a stats
    zstat -A stats +link "$1" 2>/dev/null && print -- $stats[1]
}

# Get modification time (epoch)
# Usage: get_file_mtime "file.txt"
# Returns: modification time in seconds since epoch
get_file_mtime() {
    (( ARGC == 1 )) || return 2
    [[ -e $1 ]] || return 1
    local -a stats
    zstat -A stats +mtime "$1" 2>/dev/null && print -- $stats[1]
}

# --- Path Manipulation (Pure Zsh Modifiers) ---
# Note: These are wrappers around native modifiers. 
# In performance-critical loops, use ${var:t} directly instead of $(get_filename $var)

# Get filename from path (basename equivalent)
# Usage: get_filename "/path/to/file.txt" -> "file.txt"
# Returns: filename
get_filename() {
    (( ARGC == 1 )) || return 2
    print -- "${1:t}"
}

# Get directory from path (dirname equivalent)
# Usage: get_dirname "/path/to/file.txt" -> "/path/to"
# Returns: directory path
get_dirname() {
    (( ARGC == 1 )) || return 2
    print -- "${1:h}"
}

# Get file extension (without dot)
# Usage: get_extension "image.jpg" -> "jpg"
# Returns: extension
get_extension() {
    (( ARGC == 1 )) || return 2
    print -- "${1:e}"
}

# Get filename without extension
# Usage: get_filename_no_ext "image.jpg" -> "image"
# Returns: filename without extension
get_filename_no_ext() {
    (( ARGC == 1 )) || return 2
    print -- "${1:t:r}"
}

# --- Advanced Utilities ---

# Count files in directory (non-recursive)
# Usage: count_files ["/path/to/dir"] ["pattern"]
# Returns: number of files
count_files() {
    # Defaults to current directory if no path provided.
    local dir=${1:-.}
    local pattern=${2:-*}
    
    [[ -d $dir ]] || return 1
    
    # Glob qualifier (.): regular files only, (N): nullglob
    local -a files=($dir/$~pattern(N.))
    print -- ${#files}
}

# Count directories in directory (non-recursive)
# Usage: count_dirs ["/path/to/dir"] ["pattern"]
# Returns: number of directories
count_dirs() {
    # Defaults to current directory if no path provided.
    local dir=${1:-.}
    local pattern=${2:-*}
    
    [[ -d $dir ]] || return 1
    
    # Glob qualifier (/): directories only, (N): nullglob
    local -a dirs=($dir/$~pattern(N/))
    print -- ${#dirs}
}

# Create a file and its parent directories if they don't exist
# Usage: mkfile "path/to/deep/file.txt"
# Returns: 0 on success, 1 on failure, 2 on invalid usage
mkfile() {
    (( ARGC == 1 )) || return 2
    local dir=${1:h}
    [[ -d $dir ]] || mkdir -p "$dir" || return 1
    touch "$1"
}

# Format bytes into human readable size
# Usage: format_size 12345678
# Returns: 11.77 MB
format_size() {
    (( ARGC == 1 )) || return 2
    local bytes=$1
    local -a units=(B KB MB GB TB PB)
    local i=1
    local -F size=$bytes

    while (( size >= 1024 && i < 6 )); do
        (( size /= 1024.0 ))
        (( i++ ))
    done

    # No decimals for bytes, 2 decimals for larger units
    if (( i == 1 )); then
        LC_NUMERIC=C printf "%.0f %s\n" $size $units[$i]
    else
        LC_NUMERIC=C printf "%.2f %s\n" $size $units[$i]
    fi
}

# Shell files tracking - keep at the end
zfile_track_end ${0:A}