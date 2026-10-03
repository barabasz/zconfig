#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

## ACME Shell script: acme.sh

# Guard: Check if the directory exists.
if ! is_dir "$HOME/.acme.sh"; then
    zfile_track_end ${0:A}
    return
fi

source "$HOME/.acme.sh/acme.sh.env"

# shell files tracking - keep at the end
zfile_track_end ${0:A}