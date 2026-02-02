#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# Archive and Compression helper functions
##

# Extract any archive format based on extension
# Usage: extract archive.tar.gz
# Returns: 0 on success, 1 on failure, 2 on invalid usage
extract() {
    (( ARGC == 1 )) || return 2 # Invalid usage
    local file="$1"

    if [[ ! -f "$file" ]]; then
        printe "'$file' is not a valid file"
        return 1
    fi

    # Determine extraction method based on extension (case-insensitive with :l)
    case "${file:l}" in
        *.tar.bz2)   tar xjf "$file"    ;;
        *.tar.gz)    tar xzf "$file"    ;;
        *.tar.xz)    tar xf "$file"     ;;
        *.tar.zst)   tar --zstd -xf "$file" ;;
        *.bz2)       bunzip2 "$file"    ;;
        *.rar)       unrar x "$file"    ;;
        *.gz)        gunzip "$file"     ;;
        *.tar)       tar xf "$file"     ;;
        *.tbz2)      tar xjf "$file"    ;;
        *.tgz)       tar xzf "$file"    ;;
        *.zip)       unzip "$file"      ;;
        *.z)         uncompress "$file" ;;
        *.7z)        7z x "$file"       ;;
        *.dmg)       hdiutil mount "$file" ;; # macOS specific
        *)           
            printe "'$file' cannot be extracted via extract()" 
            return 1 
            ;;
    esac
}

# Compress a file or directory into a .tar.gz (uses pigz if available)
# Usage: compress target_name source_file_or_dir
# Returns: 0 on success, 1 on failure, 2 on invalid usage
compress() {
    (( ARGC == 2 )) || return 2 # Invalid usage
    local target="$1"
    local source="$2"

    # Add .tar.gz extension if missing
    [[ "$target" != *.tar.gz ]] && target="${target}.tar.gz"

    if [[ -e "$source" ]]; then
        # Use -C to change directory to parent to avoid absolute paths in archive
        # Use pigz for parallel compression if available (via pipe for bsdtar compat)
        if (( ${+commands[pigz]} )); then
            tar cf - -C "${source:h}" "${source:t}" | pigz > "$target"
            prints "Compressed '${source:t}' to '$target' using pigz"
        else
            tar -czf "$target" -C "${source:h}" "${source:t}"
            prints "Compressed '${source:t}' to '$target' using gzip"
        fi
    else
        printe "Source '$source' does not exist"
        return 1
    fi
}

# Create a zip archive of a folder (ignoring common junk)
# Usage: zip_folder archive_name source_folder
# Returns: 0 on success, 1 on failure, 2 on invalid usage
zip_folder() {
    (( ARGC == 2 )) || return 2 # Invalid usage
    local target="$1"
    local source="$2"

    # Add .zip extension if missing
    [[ "$target" != *.zip ]] && target="${target}.zip"

    if [[ -d "$source" ]]; then
        # -r: recursive, -9: max compression, -q: quiet
        # -x: exclude common system files/git
        zip -r -9 -q "$target" "$source" -x "*.DS_Store" "*.git/*" "*.svn/*"
        
        prints "Zipped '$source' to '$target'"
    else
        printe "Directory '$source' does not exist"
        return 1
    fi
}

# shell files tracking - keep at the end
zfile_track_end ${0:A}