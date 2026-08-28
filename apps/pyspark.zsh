#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# PySpark configuration

# Guard: Fast check if pyspark is installed
(( ${+commands[pyspark]} )) || return

pyspark() {
    local startup_file="$CONFDIR/pyspark/startup.py"

    if [[ -r "$startup_file" ]]; then
        local -x PYTHONSTARTUP="$startup_file"
    fi

    command pyspark "$@"
}

# shell files tracking - keep at the end
zfile_track_end ${0:A}