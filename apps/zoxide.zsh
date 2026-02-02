#!/bin/zsh
# Part of zconfig · https://github.com/barabasz/zconfig · MIT License
#
# Shell files tracking - keep at the top
zfile_track_start ${0:A}

# zoxide shell integration

# Guard
is_installed zoxide || return

eval "$(zoxide init zsh)"

# shell files tracking - keep at the end
zfile_track_end ${0:A}