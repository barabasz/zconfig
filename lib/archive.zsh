#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# Archive and compression helper functions
# Depends on: print.zsh (output)
##

## Internal helpers

# Check that all required commands exist (internal)
# Usage: _archive_need <command>...
# Returns: 0 all found, 127 at least one missing (error printed)
_archive_need() {
    local cmd
    for cmd in "$@"; do
        if (( ! ${+commands[$cmd]} )); then
            printe "'$cmd' is required but not installed."
            return 127
        fi
    done
}

## Extraction

# Extract an archive based on its extension
# Usage: extract <archive> [target_dir]   (default: current directory)
# Returns: 0 success, 1 failure, 2 invalid usage, 127 required tool missing
extract() {
    (( ARGC >= 1 && ARGC <= 2 )) || { _lib_usage "extract <archive> [target_dir]"; return }
    local file=$1 dest=${2:-.}

    if [[ ! -f $file ]]; then
        printe "'$file' is not a valid file."
        return 1
    fi
    if [[ ! -d $dest ]]; then
        command mkdir -p -- "$dest" || return 1
    fi
    # Single-file decompressors write next to the source; use an absolute path
    # so the result can be placed in the target directory
    local abs=${file:A} out="$dest/${${file:t}%.*}"

    # :l lowercases, so the match is case-insensitive
    case ${file:l} in
        *.tar.bz2|*.tbz|*.tbz2)  _archive_need tar   && tar -xjf "$abs" -C "$dest" ;;
        *.tar.gz|*.tgz)          _archive_need tar   && tar -xzf "$abs" -C "$dest" ;;
        *.tar.xz|*.txz)          _archive_need tar   && tar -xJf "$abs" -C "$dest" ;;
        *.tar.zst|*.tzst)        _archive_need tar   && tar --zstd -xf "$abs" -C "$dest" ;;
        *.tar.lz4)               _archive_need tar lz4 && lz4 -dc "$abs" | tar -xf - -C "$dest" ;;
        *.tar)                   _archive_need tar   && tar -xf "$abs" -C "$dest" ;;
        *.bz2)                   _archive_need bzip2 && bzip2 -dc "$abs" > "$out" ;;
        *.gz)                    _archive_need gzip  && gzip -dc "$abs" > "$out" ;;
        *.xz)                    _archive_need xz    && xz -dc "$abs" > "$out" ;;
        *.lzma)                  _archive_need xz    && xz --format=lzma -dc "$abs" > "$out" ;;
        *.zst)                   _archive_need zstd  && zstd -qdc "$abs" > "$out" ;;
        *.lz4)                   _archive_need lz4   && lz4 -qdc "$abs" > "$out" ;;
        *.z)                     _archive_need uncompress && uncompress -c "$abs" > "$out" ;;
        *.zip|*.jar)             _archive_need unzip && unzip -q "$abs" -d "$dest" ;;
        *.rar)                   _archive_need unrar && unrar x -inul "$abs" "$dest/" ;;
        *.7z)                    _archive_need 7z    && 7z x -bd -y "-o$dest" "$abs" >/dev/null ;;
        *.dmg)                   _archive_need hdiutil && hdiutil mount "$abs" ;;
        *)
            printe "'$file' cannot be extracted (unknown format)."
            return 1
            ;;
    esac
}

# List the contents of an archive without extracting it
# Usage: list_archive <archive>
# Output: file list (stdout)
# Returns: 0 success, 1 failure, 2 invalid usage, 127 required tool missing
list_archive() {
    (( ARGC == 1 )) || { _lib_usage "list_archive <archive>"; return }
    local file=$1
    [[ -f $file ]] || { printe "'$file' is not a valid file."; return 1 }
    case ${file:l} in
        *.tar.lz4)                         _archive_need tar lz4 && lz4 -dc "$file" | tar -tf - ;;
        *.tar.zst|*.tzst)                  _archive_need tar && tar --zstd -tf "$file" ;;
        *.tar|*.tar.*|*.tgz|*.tbz|*.tbz2|*.txz) _archive_need tar && tar -tf "$file" ;;
        *.zip|*.jar)                       _archive_need unzip && unzip -Z1 "$file" ;;
        *.rar)                             _archive_need unrar && unrar lb "$file" ;;
        *.7z)                              _archive_need 7z && 7z l -ba "$file" ;;
        *)
            printe "'$file' cannot be listed (unknown format)."
            return 1
            ;;
    esac
}

## Compression

# Compress a file or directory into a .tar.gz (uses pigz if available)
# Usage: compress <archive_name> <source>
# Returns: 0 success, 1 failure, 2 invalid usage, 127 tar not found
compress() {
    (( ARGC == 2 )) || { _lib_usage "compress <archive_name> <source>"; return }
    local target=$1 source=$2
    [[ $target == *.tar.gz ]] || target+=.tar.gz

    if [[ ! -e $source ]]; then
        printe "Source '$source' does not exist."
        return 1
    fi
    _archive_need tar || return

    # -C parent: store a relative path in the archive
    local tool=gzip
    if (( ${+commands[pigz]} )); then
        tool=pigz
        tar -cf - -C "${source:A:h}" "${source:A:t}" | pigz > "$target"
        # pipestatus: fail if either tar or pigz failed
        (( ${pipestatus[1]} == 0 && ${pipestatus[2]} == 0 ))
    else
        tar -czf "$target" -C "${source:A:h}" "${source:A:t}"
    fi || {
        printe "Failed to compress '$source'."
        command rm -f -- "$target"
        return 1
    }
    prints "Compressed '${source:t}' to '$target' using $tool."
}

# Create a zip archive of a folder (ignoring common junk files)
# Usage: zip_folder <archive_name> <folder>
# Returns: 0 success, 1 failure, 2 invalid usage, 127 zip not found
zip_folder() {
    (( ARGC == 2 )) || { _lib_usage "zip_folder <archive_name> <folder>"; return }
    local target=$1 source=$2
    [[ $target == *.zip ]] || target+=.zip

    if [[ ! -d $source ]]; then
        printe "Directory '$source' does not exist."
        return 1
    fi
    _archive_need zip || return

    # Run from the parent directory, so the archive holds a relative path;
    # target is made absolute first because the subshell changes directory
    target=${target:a}
    if ! ( builtin cd -q -- "${source:A:h}" &&
           zip -r -9 -q "$target" "${source:A:t}" -x "*.DS_Store" "*/.git/*" "*/.svn/*" ); then
        printe "Failed to zip '$source'."
        return 1
    fi
    prints "Zipped '$source' to '$target'."
}

# Shell files tracking - keep at the end
zfile_track_end ${0:A}
