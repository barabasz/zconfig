#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License

# The Fuck integration

# Guard: exit immediately if thefuck is not installed
is_installed thefuck || return

# Shell files tracking - keep at the top (after guards)
zfile_track_start ${0:A}

fuck() {
    unfunction fuck
    eval $(thefuck --alias)
    fuck $@
}

# Shell files tracking - keep at the end
zfile_track_end ${0:A}