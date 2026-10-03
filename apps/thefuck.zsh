#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# The Fuck integration

# Guard: check if thefuck is installed
if ! is_installed thefuck; then
    zfile_track_end ${0:A}
    return
fi

fuck() {
    unfunction fuck
    eval $(thefuck --alias)
    fuck $@
}

# shell files tracking - keep at the end
zfile_track_end ${0:A}