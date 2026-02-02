#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#

##
# Shell files tracking infrastructure
##

zmodload zsh/datetime
typeset -A ZFILES
typeset -A ZFILES_TIME
typeset -A ZFILES_START
typeset -a ZFILES_ORDER

# Start tracking a sourced file
zfile_track_start() {
    local filepath=$1
    this_file=${filepath:t}
    ZFILES[$filepath]=0
    ZFILES_ORDER+=($filepath)
    ZFILES_START[$filepath]=$EPOCHREALTIME
}

# Track this file
zfile_track_start ${0:A}

# End tracking a sourced file
zfile_track_end() {
    local filepath=$1
    ZFILES[$filepath]=1
    ZFILES_TIME[$filepath]=$(( (EPOCHREALTIME - ZFILES_START[$filepath]) * 1000 ))
    (( ZSH_ZFILE_DEBUG == 1 )) && zfile_source_time ${filepath:t} $ZFILES_TIME[$filepath] || return 0
}

# Print source time for a file
zfile_source_time() {
    local file_name="$1"
    local file_time="$2"
    printf "%-15s — %8.2f ms\n" "$file_name" "$file_time"
}

# Source all .zsh files in a directory
# Needed to be defined here to be available in .zshenv
# (will be overridden in lib/varia.zsh)
source_zsh_dir() {
    local f
    for f in $1/*.zsh(N); do
        source "$f"
    done
}

# shell files tracking - keep at the end
zfile_track_end ${0:A}