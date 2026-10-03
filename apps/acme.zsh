#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License

# ACME Shell script: acme.sh integration

# Guard: exit immediately if acme.sh directory does not exist
is_dir "$HOME/.acme.sh" || return

# Shell files tracking - keep at the top (after guards)
zfile_track_start ${0:A}

source "$HOME/.acme.sh/acme.sh.env"

# Shell files tracking - keep at the end
zfile_track_end ${0:A}