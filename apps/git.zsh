#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License

# GitHub configuration integration

# Guard: exit immediately if GitHub directory does not exist
is_dir "$HOME/GitHub" || return

# Shell files tracking - keep at the top (after guards)
zfile_track_start ${0:A}

# Base GitHub configurations
export MYGH="https://raw.githubusercontent.com/barabasz"
export GHDIR="$HOME/GitHub"

# User GitHub repository directories
# Export variables only if their respective directories actually exist
[[ -d "$GHDIR/bin" ]] && export GHBINDIR="$GHDIR/bin"
[[ -d "$GHDIR/lib" ]] && export GHLIBDIR="$GHDIR/lib"
[[ -d "$GHDIR/config" ]] && export GHCONFDIR="$GHDIR/config"

# Shell files tracking - keep at the end
zfile_track_end ${0:A}