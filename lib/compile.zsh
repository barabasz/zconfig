#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

##
# Zsh file compilation functions
# Compiles .zsh files to .zwc bytecode for faster loading.
# zsh always loads the newest of file and file.zwc, so a stale .zwc is never used.
# Depends on: print.zsh (output), zsh/stat (zstat)
##

## Low-level functions

# Check if a file needs (re)compilation
# Usage: needs_compile <file>
# Returns: 0 needs compile, 1 up to date, 2 invalid usage
needs_compile() {
    (( ARGC == 1 )) || return 2
    # zsh's -nt is false when the second file is missing, so test existence first
    [[ ! -f $1.zwc || $1 -nt $1.zwc ]]
}

# Compile a single zsh file
# Usage: compile_file <file>
# Returns: 0 success, 1 failure, 2 invalid usage
compile_file() {
    (( ARGC == 1 )) || return 2
    [[ -f $1 ]] || return 1

    # Disable aliases for this scope (global alias G='| grep' breaks files containing 'G')
    # LC_ALL=C prevents locale-related parsing issues
    setopt localoptions noaliases
    if (( ZSH_DEBUG )); then
        LC_ALL=C zcompile "$1"
    else
        LC_ALL=C zcompile "$1" 2>/dev/null
    fi
}

## Directory-level functions

# Compile all .zsh files in a directory
# Usage: compile_dir <dir> [quiet]   (quiet: 1 suppresses output)
# Returns: 0 success, 1 at least one file failed or directory missing, 2 invalid usage
compile_dir() {
    (( ARGC >= 1 && ARGC <= 2 )) || { _lib_usage "compile_dir <dir> [quiet]"; return }
    local dir=$1 file
    local -i quiet=${2:-0} compiled=0 failed=0
    local -a failed_files=()

    if [[ ! -d $dir ]]; then
        (( ZSH_DEBUG )) && printe "compile_dir: directory not found: ${c}$dir${x}"
        return 1
    fi

    for file in $dir/*.zsh(N.); do
        needs_compile "$file" || continue
        if compile_file "$file"; then
            (( compiled++ ))
            (( ZSH_DEBUG && ! quiet )) && printd "Compiled: ${file:t}"
        else
            (( failed++ ))
            failed_files+=("${file:t}")
            (( ZSH_DEBUG )) && printe "Failed to compile: ${c}${file:t}${x}"
        fi
    done

    if (( ! quiet )); then
        (( compiled )) && printd "Compiled $compiled file(s) in ${dir:t}"
        (( failed )) && printw "$failed file(s) failed to compile in ${dir:t}: ${failed_files[*]}"
    elif (( failed && ZSH_DEBUG )); then
        # Even in quiet mode, show failures when debugging
        printw "$failed file(s) failed in ${c}${dir:t}${x}: ${failed_files[*]}"
    fi
    (( failed == 0 ))
}

# Compile all autoload functions of a directory into one digest file (<dir>.zwc)
# zsh uses <dir>.zwc automatically for functions autoloaded from <dir>,
# unless a function file is newer than the digest.
# Usage: compile_functions_dir <dir> [quiet]   (quiet: 1 suppresses output)
# Returns: 0 success or up to date, 1 failure, 2 invalid usage
compile_functions_dir() {
    (( ARGC >= 1 && ARGC <= 2 )) || { _lib_usage "compile_functions_dir <dir> [quiet]"; return }
    local dir=${1%/} file
    local -i quiet=${2:-0}
    [[ -d $dir ]] || return 1
    # Same selection as the autoload in .zshrc: not hidden, not private (_*)
    local -a files=($dir/[^_.]*(N.))
    files=(${files:#*.zwc})
    (( ${#files} )) || return 0
    local digest=$dir.zwc
    local -i stale=0
    if [[ ! -f $digest ]]; then
        stale=1
    else
        for file in $files; do
            [[ $file -nt $digest ]] && { stale=1; break }
        done
    fi
    (( stale )) || return 0
    setopt localoptions noaliases
    # -U: no alias expansion, -z: zsh-style autoload
    LC_ALL=C zcompile -Uz "$digest" $files 2>/dev/null || {
        (( ZSH_DEBUG )) && printe "Failed to compile functions digest: ${c}$digest${x}"
        return 1
    }
    (( ZSH_DEBUG && ! quiet )) && printd "Compiled ${#files} function(s) into ${digest:t}"
    return 0
}

# Remove all .zwc files from a directory
# Usage: clean_dir <dir>
# Returns: 0 success (also when nothing to remove), 1 failure, 2 invalid usage
clean_dir() {
    (( ARGC == 1 )) || { _lib_usage "clean_dir <dir>"; return }
    local dir=$1
    if [[ ! -d $dir ]]; then
        printe "clean_dir: directory not found: $dir"
        return 1
    fi
    local -a zwc_files=($dir/*.zwc(N.))
    (( ${#zwc_files} )) || return 0
    command rm -f -- $zwc_files || return 1
    printd "Cleaned ${#zwc_files} compiled file(s) from ${dir:t}"
}

## Config-level functions

# Compile entire zsh configuration: lib/, inc/, apps/, startup files and
# the functions/ digest
# Usage: compile_zsh_config [-q|--quiet]   (quiet is meant for shell startup)
# Returns: 0 success, 1 at least one part failed
compile_zsh_config() {
    local -a quiet_opt
    zparseopts -D q=quiet_opt -quiet=quiet_opt
    local -i quiet=${#quiet_opt}
    local -a failed_parts=()
    local dir file

    (( quiet )) || printi "Compiling zsh configuration..."

    for dir in $ZSH_LIB_DIR $ZSH_INC_DIR $ZSH_APPS_DIR; do
        compile_dir "$dir" $quiet || failed_parts+=(${dir:t})
    done

    # Startup files (zsh loads e.g. .zshrc.zwc automatically when it is newer)
    for file in $ZDOTDIR/.z(shenv|profile|shrc|login|logout)(N.); do
        needs_compile "$file" || continue
        compile_file "$file" || failed_parts+=(${file:t})
    done

    compile_functions_dir "$ZSH_FUNCS_DIR" $quiet || failed_parts+=(functions)

    if (( ! ${#failed_parts} )); then
        (( quiet )) || prints "Zsh configuration compiled successfully."
        return 0
    fi
    printw "Failed to compile: ${failed_parts[*]}"
    return 1
}

# Remove .zwc files from the entire zsh configuration
# Usage: clean_zsh_config
# Returns: 0 success, 1 at least one part failed, 2 invalid usage
clean_zsh_config() {
    (( ARGC == 0 )) || return 2
    local -i failed=0
    local dir
    printi "Cleaning compiled zsh files..."
    for dir in $ZSH_LIB_DIR $ZSH_INC_DIR $ZSH_APPS_DIR $ZDOTDIR; do
        clean_dir "$dir" || (( failed++ ))
    done
    command rm -f -- $ZSH_FUNCS_DIR.zwc(N) || (( failed++ ))
    if (( failed )); then
        printw "Some compiled files could not be removed."
        return 1
    fi
    prints "Compiled files cleaned."
}

# Shell files tracking - keep at the end
zfile_track_end ${0:A}
