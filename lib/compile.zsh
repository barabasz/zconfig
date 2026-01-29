#!/bin/zsh
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# Zsh file compilation functions
# Compiles .zsh files to .zwc bytecode for faster loading

# =============================================================================
# Low-level functions
# =============================================================================

# Check if a .zsh file needs (re)compilation
# Usage: needs_compile <file.zsh>
# Returns: 0 if needs compile, 1 if up-to-date
needs_compile() {
    (( ARGC == 1 )) || return 1
    local src=$1 zwc=$1.zwc

    # No .zwc exists → needs compile
    [[ -f $zwc ]] || return 0

    # Compare modification times using zstat
    local src_mtime zwc_mtime
    zstat -A src_mtime +mtime "$src" 2>/dev/null || return 1
    zstat -A zwc_mtime +mtime "$zwc" 2>/dev/null || return 0

    # Source newer than compiled → needs recompile
    (( src_mtime > zwc_mtime ))
}

# Compile a single .zsh file
# Usage: compile_file <file.zsh>
# Returns: 0 on success, 1 on failure
compile_file() {
    (( ARGC == 1 )) || return 1
    [[ -f $1 && $1 == *.zsh ]] || return 1
    zcompile "$1" 2>/dev/null
}

# =============================================================================
# Directory-level functions
# =============================================================================

# Compile all .zsh files in a directory
# Usage: compile_dir <dir> [quiet]
# Arguments:
#   dir    Directory to compile
#   quiet  If 1, suppress output
# Returns: 0 on success, 1 on failure
compile_dir() {
    (( ARGC >= 1 && ARGC <= 2 )) || {
        print -u2 "Usage: compile_dir <dir> [quiet]"
        return 1
    }
    local dir=$1
    local quiet=${2:-0}
    local file compiled=0 failed=0

    [[ -d $dir ]] || {
        print -u2 "compile_dir: directory not found: $dir"
        return 1
    }

    for file in $dir/*.zsh(N.); do
        if needs_compile "$file"; then
            if compile_file "$file"; then
                (( compiled++ ))
            else
                (( failed++ ))
            fi
        fi
    done

    if (( ! quiet )); then
        (( compiled > 0 )) && printd "Compiled $compiled file(s) in ${dir:t}"
        (( failed > 0 )) && printw "$failed file(s) failed to compile in ${dir:t}"
    fi
    (( failed == 0 ))
}

# Remove all .zwc files from a directory
# Usage: clean_dir <dir>
# Returns: 0 on success, 1 on failure
clean_dir() {
    (( ARGC == 1 )) || {
        print -u2 "Usage: clean_dir <dir>"
        return 1
    }
    local dir=$1
    local -a zwc_files

    [[ -d $dir ]] || {
        print -u2 "clean_dir: directory not found: $dir"
        return 1
    }

    zwc_files=($dir/*.zwc(N.))
    (( ${#zwc_files} > 0 )) && {
        rm -f $zwc_files
        printd "Cleaned ${#zwc_files} compiled file(s) from ${dir:t}"
    }
}

# =============================================================================
# Config-level functions
# =============================================================================

# Compile entire zsh configuration (lib/, inc/, apps/)
# Usage: compile_zsh_config [-q|--quiet]
# Options:
#   -q, --quiet    Suppress output (for use at shell startup)
compile_zsh_config() {
    local -A opts
    zparseopts -D -A opts q -quiet

    local quiet=0
    (( ${+opts[-q]} + ${+opts[--quiet]} )) && quiet=1

    local failed=0

    (( quiet )) || printi "Compiling zsh configuration..."

    compile_dir "$ZSH_LIB_DIR" $quiet || (( failed++ ))
    compile_dir "$ZSH_INC_DIR" $quiet || (( failed++ ))
    compile_dir "$ZSH_APPS_DIR" $quiet || (( failed++ ))

    if (( failed == 0 )); then
        (( quiet )) || prints "Zsh configuration compiled successfully"
    else
        printw "Some directories failed to compile"
    fi

    (( failed == 0 ))
}

# Clean .zwc files from entire zsh configuration
# Usage: clean_zsh_config
clean_zsh_config() {
    printi "Cleaning compiled zsh files..."

    clean_dir "$ZSH_LIB_DIR"
    clean_dir "$ZSH_INC_DIR"
    clean_dir "$ZSH_APPS_DIR"

    prints "Compiled files cleaned"
}

# shell files tracking - keep at the end
zfile_track_end ${0:A}
