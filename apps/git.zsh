#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# Github configuration

export MYGH="https://raw.githubusercontent.com/barabasz"

# Guard
is_dir "$HOME/GitHub" || return

export GHDIR=$HOME/GitHub
is_folder "$GHDIR/bin" && export GHBINDIR=$GHDIR/bin
is_folder "$GHDIR/lib" && export GHLIBDIR=$GHDIR/lib
is_folder "$GHDIR/config" && export GHCONFDIR=$GHDIR/config
is_folder "$GHDIR/priv" && export GHPRIVDIR=$GHDIR/priv

# shell files tracking - keep at the end
zfile_track_end ${0:A}