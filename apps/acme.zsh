#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

## ACME Shell script: acme.sh

# Guard
is_dir "$HOME/.acme.sh" || return

source "$HOME/.acme.sh/acme.sh.env"

# shell files tracking - keep at the end
zfile_track_end ${0:A}