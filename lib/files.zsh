#!/bin/zsh
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# Load Zsh stat module for cross-platform file statistics without external 'stat' command
zmodload zsh/stat

# Filesystem related functions
# zsh-specific functions - requires zsh, will not work in bash

# Check if path exists and is a regular file
# Usage: is_file "/path/to/file"
# Returns: 0 (true) or 1 (false)
is_file() {
    (( ARGC == 1 )) && [[ -f $1 ]]
}

# Check if path exists and is a directory
# Usage: is_dir "/path/to/dir"
# Returns: 0 (true) or 1 (false)
is_dir() {
    (( ARGC == 1 )) && [[ -d $1 ]]
}
functions[is_folder]=$functions[is_dir]

# Check if path exists and is a symbolic link
# Usage: is_link "/path/to/symlink"
# Returns: 0 (true) or 1 (false)
is_link() {
    (( ARGC == 1 )) && [[ -L $1 ]]
}

# Alias for is_link
# Usage: is_symlink "/path/to/symlink"
# Returns: 0 (true) or 1 (false)
is_symlink() {
    is_link $@
}

# Check if file is a hard link (has link count > 1)
# Uses built-in zstat for portability (Linux/macOS)
# Usage: is_hardlink "/path/to/file"
# Returns: 0 (true) or 1 (false)
is_hardlink() {
    (( ARGC == 1 )) && [[ -f $1 ]] || return 1
    # +nlink retrieves the number of hard links
    local links
    zstat -A links +nlink "$1" 2>/dev/null
    (( links > 1 ))
}

# Check if path exists (any type)
# Usage: is_exists "/path/to/anything"
# Returns: 0 (true) or 1 (false)
is_exists() {
    (( ARGC == 1 )) && [[ -e $1 ]]
}

# Check if path is a block device
# Usage: is_block_device "/dev/sda"
# Returns: 0 (true) or 1 (false)
is_block_device() {
    (( ARGC == 1 )) && [[ -b $1 ]]
}

# Check if path is a character device
# Usage: is_char_device "/dev/tty"
# Returns: 0 (true) or 1 (false)
is_char_device() {
    (( ARGC == 1 )) && [[ -c $1 ]]
}

# Check if path is a named pipe (FIFO)
# Usage: is_pipe "/path/to/pipe"
# Returns: 0 (true) or 1 (false)
is_pipe() {
    (( ARGC == 1 )) && [[ -p $1 ]]
}

# Check if path is a socket
# Usage: is_socket "/path/to/socket.sock"
# Returns: 0 (true) or 1 (false)
is_socket() {
    (( ARGC == 1 )) && [[ -S $1 ]]
}

# --- Permissions Checks ---

# Check if path is readable
# Usage: is_readable "/path/to/file"
# Returns: 0 (true) or 1 (false)
is_readable() {
    (( ARGC == 1 )) && [[ -r $1 ]]
}

# Check if path is writable
# Usage: is_writable "/path/to/file"
# Returns: 0 (true) or 1 (false)
is_writable() {
    (( ARGC == 1 )) && [[ -w $1 ]]
}

# Check if path is executable
# Usage: is_executable "/path/to/script.sh"
# Returns: 0 (true) or 1 (false)
is_executable() {
    (( ARGC == 1 )) && [[ -x $1 ]]
}

# --- Content/Metadata Checks ---

# Check if file has zero size
# Usage: is_zero_size "/path/to/file"
# Returns: 0 (true) if empty, 1 (false) otherwise
is_zero_size() {
    # -s returns true if size > 0, so we invert logic
    (( ARGC == 1 )) && [[ -s $1 ]] && return 1
    return 0
}

# Check if directory is empty
# Usage: is_dir_empty "/path/to/dir"
# Returns: 0 (true) if empty, 1 (false) otherwise
is_dir_empty() {
    (( ARGC == 1 )) && [[ -d $1 ]] || return 1
    # Check if there is at least one file inside
    # Uses Zsh glob qualifiers: D (dotfiles), N (nullglob), [1] (stop after 1 match)
    local -a files=("$1"/*(DN[1]))
    (( ${#files} == 0 ))
}

# Get file size in bytes
# Usage: get_file_size "file.txt"
# Returns: file size in bytes (e.g., 1024)
get_file_size() {
    (( ARGC == 1 )) && [[ -f $1 ]] || return 1
    zstat +size "$1"
}

# --- Path Manipulation (Pure Zsh Modifiers) ---

# Get filename from path (basename equivalent)
# Usage: get_filename "/path/to/file.txt"
# Returns: "file.txt"
get_filename() {
    (( ARGC == 1 )) || return 1
    print -- "${1:t}"
}

# Get directory from path (dirname equivalent)
# Usage: get_dirname "/path/to/file.txt"
# Returns: "/path/to"
get_dirname() {
    (( ARGC == 1 )) || return 1
    print -- "${1:h}"
}

# Get file extension (without dot)
# Usage: get_extension "image.jpg"
# Returns: "jpg"
get_extension() {
    (( ARGC == 1 )) || return 1
    print -- "${1:e}"
}

# Get filename without extension
# Usage: get_filename_no_ext "image.jpg"
# Returns: "image"
get_filename_no_ext() {
    (( ARGC == 1 )) || return 1
    print -- "${1:t:r}"
}

# Get absolute path (resolving symlinks)
# Usage: get_abs_path "../file.txt"
# Returns: "/full/path/to/file.txt"
get_abs_path() {
    (( ARGC == 1 )) || return 1
    # :A modifier resolves absolute path with symlinks
    print -- "${1:A}"
}

# shell files tracking - keep at the end
zfile_track_end ${0:A}