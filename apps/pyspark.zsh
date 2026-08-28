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
    local log4j_file="$CONFDIR/pyspark/log4j2.properties"

    # Custom Python startup
    if [[ -r "$startup_file" ]]; then
        local -x PYTHONSTARTUP="$startup_file"
    fi

    # Suppress standard Python REPL banner
    local -x PYSPARK_DRIVER_PYTHON_OPTS="-q"

    # Custom Spark logging
    if [[ -r "$log4j_file" ]]; then
        command pyspark \
            --driver-java-options "-Dlog4j.configurationFile=file:$log4j_file" \
            "$@"
    else
        command pyspark "$@"
    fi
}

# shell files tracking - keep at the end
zfile_track_end ${0:A}