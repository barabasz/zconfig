#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# zoxide shell integration

# Guard: check if zoxide is installed
if ! is_installed zoxide; then
    zfile_track_end ${0:A}
    return
fi

eval "$(zoxide init zsh)"

# shell files tracking - keep at the end
zfile_track_end ${0:A}